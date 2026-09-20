unit Rick.SQL.Tests.Concurrency;

interface

uses
  TestFramework;

type
  TRickSQLConcurrencyTests = class(TTestCase)
  published
    procedure Concurrent_IndependentSQLiteOperations_BothSucceed;
    procedure Concurrent_SQLiteAndPostgreSQL_WhenConfigured_BothSucceed;
    procedure Concurrent_SameSQLiteReaders_RepeatedOperationsComplete;
    procedure Concurrent_SQLiteWriteContention_ReturnsBusyAndRecovers;
    procedure Concurrent_SuccessAndFailure_RemainIsolated;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.SyncObjs,
  System.Threading,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteWrapper.Stat,
  Rick.SQL;

function NewTempDatabase: string;
begin
  Result := TPath.GetTempFileName;
  TFile.Delete(Result);
end;

function SQLiteConnection(const ADatabase: string): TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  Result.Database := ADatabase;
  Result.AddExtraParameter('LockingMode', 'Normal');
  Result.AddExtraParameter('Synchronous', 'Normal');
  Result.AddExtraParameter('SharedCache', 'False');
end;

function ErrorDetail(const AError: TRickSQLError): string;
begin
  Result := AError.Message;
  if Trim(AError.TechnicalDetail) <> '' then
    Result := Result + ' Detalhe: ' + AError.TechnicalDetail;
  if AError.DBMSCode <> 0 then
    Result := Result + Format(' DBMSCode: %d.', [AError.DBMSCode]);
end;

procedure DeleteDatabase(const ADatabase: string);
begin
  if TFile.Exists(ADatabase) then
    TFile.Delete(ADatabase);
  if TFile.Exists(ADatabase + '-journal') then
    TFile.Delete(ADatabase + '-journal');
  if TFile.Exists(ADatabase + '-wal') then
    TFile.Delete(ADatabase + '-wal');
  if TFile.Exists(ADatabase + '-shm') then
    TFile.Delete(ADatabase + '-shm');
end;

procedure ExecuteIndependentSQLite(const ADatabase: string; var AOK: Integer);
var
  LConnection: TRickSQLConnectionOptions;
  LResult: TRickSQLExecutionResult;
begin
  LConnection := SQLiteConnection(ADatabase);
  LResult := TRickSQL.Execute(TRickSQL.Command(LConnection,
    'create table T (ID integer)'));
  if LResult.Success then
    TInterlocked.Exchange(AOK, 1);
end;

function PostgreSQLEnv(const ACurrentName, ALegacyName: string): string;
begin
  Result := GetEnvironmentVariable(ACurrentName);
  if Trim(Result) = '' then
    Result := GetEnvironmentVariable(ALegacyName);
end;

function PostgreSQLConnection: TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.PostgreSQL);
  Result.Server := PostgreSQLEnv('RICKSQL_POSTGRESQL_SERVER', 'RICKSQL_PG_SERVER');
  Result.Port := StrToIntDef(PostgreSQLEnv(
    'RICKSQL_POSTGRESQL_PORT', 'RICKSQL_PG_PORT'), 0);
  Result.Database := PostgreSQLEnv(
    'RICKSQL_POSTGRESQL_DATABASE', 'RICKSQL_PG_DATABASE');
  Result.UserName := PostgreSQLEnv(
    'RICKSQL_POSTGRESQL_USERNAME', 'RICKSQL_PG_USER');
  Result.Password := PostgreSQLEnv(
    'RICKSQL_POSTGRESQL_PASSWORD', 'RICKSQL_PG_PASSWORD');
  Result.ClientLibraryPath := GetEnvironmentVariable(
    'RICKSQL_POSTGRESQL_CLIENT_LIBRARY');
end;

procedure ExecutePostgreSQLQuery(var AOK: Integer);
var
  LDataSet: TDataSet;
  LError: TRickSQLError;
begin
  LDataSet := TRickSQL.Open(TRickSQL.Command(PostgreSQLConnection,
    'select 1 as ID'), LError);
  try
    if Assigned(LDataSet) and not LError.HasError then
      TInterlocked.Exchange(AOK, 1);
  finally
    LDataSet.Free;
  end;
end;

procedure ExecuteReadLoop(const ADatabase: string; var AOK: Integer;
  var AError: string);
var
  LDataSet: TDataSet;
  LError: TRickSQLError;
  LIndex: Integer;
begin
  for LIndex := 1 to 30 do
  begin
    LDataSet := TRickSQL.Open(TRickSQL.Command(SQLiteConnection(ADatabase),
      'select ID, NAME from T'), LError);
    try
      if LError.HasError then
      begin
        AError := ErrorDetail(LError);
        Exit;
      end;
      if not Assigned(LDataSet) then
      begin
        AError := 'Dataset não retornado.';
        Exit;
      end;
    finally
      LDataSet.Free;
    end;
  end;
  TInterlocked.Exchange(AOK, 1);
end;

function CreateSQLiteWriteBlocker(const ADatabase: string): TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  Result.LoginPrompt := False;
  Result.Params.DriverID := 'SQLite';
  Result.Params.Database := ADatabase;
  Result.Params.Values['LockingMode'] := 'Normal';
  Result.Params.Values['SharedCache'] := 'False';
  Result.Open;
  Result.StartTransaction;
  Result.ExecSQL('update T set NAME = ''Blocked'' where ID = 1');
end;

procedure ReleaseSQLiteWriteBlocker(var AConnection: TFDConnection);
begin
  if not Assigned(AConnection) then
    Exit;
  if AConnection.InTransaction then
    AConnection.Rollback;
  FreeAndNil(AConnection);
end;

function ExecuteSQLiteUpdate(const ADatabase: string): TRickSQLExecutionResult;
begin
  Result := TRickSQL.Execute(TRickSQL.Command(SQLiteConnection(ADatabase),
    'update T set NAME = ''Test'' where ID = 1'));
end;

function ExecuteSQLiteUpdateInTask(
  const ADatabase: string): TRickSQLExecutionResult;
var
  LResult: TRickSQLExecutionResult;
  LTasks: array [0 .. 0] of ITask;
begin
  LResult := TRickSQLExecutionResult.Default;
  LTasks[0] := TTask.Run(procedure begin
    LResult := ExecuteSQLiteUpdate(ADatabase);
  end);
  TTask.WaitForAll(LTasks);
  Result := LResult;
end;

function IsSQLiteBusyCode(const ACode: Integer): Boolean;
begin
  Result := (ACode and $FF) = 5;
end;

procedure ExecuteValidQuery(const ADatabase: string; var AOK: Integer);
var
  LDataSet: TDataSet;
  LError: TRickSQLError;
begin
  LDataSet := TRickSQL.Open(TRickSQL.Command(SQLiteConnection(ADatabase),
    'select ID from T'), LError);
  try
    if Assigned(LDataSet) and not LError.HasError then
      TInterlocked.Exchange(AOK, 1);
  finally
    LDataSet.Free;
  end;
end;

procedure ExecuteInvalidQuery(const ADatabase: string; var AOK: Integer);
var
  LDataSet: TDataSet;
  LError: TRickSQLError;
begin
  LDataSet := TRickSQL.Open(TRickSQL.Command(SQLiteConnection(ADatabase),
    'select missing from missing_table'), LError);
  try
    if not Assigned(LDataSet) and LError.HasError then
      TInterlocked.Exchange(AOK, 1);
  finally
    LDataSet.Free;
  end;
end;

function PrepareReadWriteDatabase(const ADatabase: string): Boolean;
var
  LResult: TRickSQLExecutionResult;
begin
  LResult := TRickSQL.Execute(TRickSQL.Command(SQLiteConnection(ADatabase),
    'create table T (ID integer primary key, NAME varchar(20))'));
  if not LResult.Success then
    Exit(False);
  LResult := TRickSQL.Execute(TRickSQL.Command(SQLiteConnection(ADatabase),
    'insert into T (ID, NAME) values (1, ''Test'')'));
  Result := LResult.Success;
end;

function PrepareIsolationDatabase(const ADatabase: string): Boolean;
var
  LResult: TRickSQLExecutionResult;
begin
  LResult := TRickSQL.Execute(TRickSQL.Command(SQLiteConnection(ADatabase),
    'create table T (ID integer)'));
  Result := LResult.Success;
end;

procedure TRickSQLConcurrencyTests.Concurrent_IndependentSQLiteOperations_BothSucceed;
var
  LDatabase1, LDatabase2: string;
  LOK1, LOK2: Integer;
  LTasks: array [0 .. 1] of ITask;
begin
  LDatabase1 := NewTempDatabase;
  LDatabase2 := NewTempDatabase;
  LOK1 := 0;
  LOK2 := 0;
  try
    LTasks[0] := TTask.Run(procedure begin ExecuteIndependentSQLite(LDatabase1, LOK1); end);
    LTasks[1] := TTask.Run(procedure begin ExecuteIndependentSQLite(LDatabase2, LOK2); end);
    TTask.WaitForAll(LTasks);
    CheckEquals(1, LOK1);
    CheckEquals(1, LOK2);
  finally
    DeleteDatabase(LDatabase1);
    DeleteDatabase(LDatabase2);
  end;
end;

procedure TRickSQLConcurrencyTests.Concurrent_SQLiteAndPostgreSQL_WhenConfigured_BothSucceed;
var
  LDatabase: string;
  LPostgreSQLOK, LSQLiteOK: Integer;
  LTasks: array [0 .. 1] of ITask;
begin
  if Trim(PostgreSQLEnv(
    'RICKSQL_POSTGRESQL_DATABASE', 'RICKSQL_PG_DATABASE')) = '' then
    Exit;
  LDatabase := NewTempDatabase;
  LPostgreSQLOK := 0;
  LSQLiteOK := 0;
  try
    LTasks[0] := TTask.Run(procedure begin ExecuteIndependentSQLite(LDatabase, LSQLiteOK); end);
    LTasks[1] := TTask.Run(procedure begin ExecutePostgreSQLQuery(LPostgreSQLOK); end);
    TTask.WaitForAll(LTasks);
    CheckEquals(1, LSQLiteOK);
    CheckEquals(1, LPostgreSQLOK);
  finally
    DeleteDatabase(LDatabase);
  end;
end;

procedure TRickSQLConcurrencyTests.Concurrent_SameSQLiteReaders_RepeatedOperationsComplete;
var
  LDatabase: string;
  LError1, LError2: string;
  LOK1, LOK2: Integer;
  LTasks: array [0 .. 1] of ITask;
begin
  LDatabase := NewTempDatabase;
  LOK1 := 0;
  LOK2 := 0;
  LError1 := '';
  LError2 := '';
  try
    Check(PrepareReadWriteDatabase(LDatabase),
      'Não foi possível preparar o banco SQLite concorrente.');
    LTasks[0] := TTask.Run(procedure begin ExecuteReadLoop(
      LDatabase, LOK1, LError1); end);
    LTasks[1] := TTask.Run(procedure begin ExecuteReadLoop(
      LDatabase, LOK2, LError2); end);
    TTask.WaitForAll(LTasks);
    CheckEquals(1, LOK1, 'Primeira leitura não concluiu. ' + LError1);
    CheckEquals(1, LOK2, 'Segunda leitura não concluiu. ' + LError2);
  finally
    DeleteDatabase(LDatabase);
  end;
end;

procedure TRickSQLConcurrencyTests.Concurrent_SQLiteWriteContention_ReturnsBusyAndRecovers;
var
  LBlocker: TFDConnection;
  LContended, LRecovered: TRickSQLExecutionResult;
  LDatabase: string;
begin
  LDatabase := NewTempDatabase;
  LBlocker := nil;
  try
    Check(PrepareReadWriteDatabase(LDatabase),
      'Não foi possível preparar o banco SQLite de contenção.');
    LBlocker := CreateSQLiteWriteBlocker(LDatabase);
    LContended := ExecuteSQLiteUpdateInTask(LDatabase);
    Check(not LContended.Success,
      'A escrita concorrente deveria reportar contenção SQLite.');
    Check(IsSQLiteBusyCode(LContended.Error.DBMSCode),
      'Esperado SQLITE_BUSY. ' + ErrorDetail(LContended.Error));
    ReleaseSQLiteWriteBlocker(LBlocker);
    LRecovered := ExecuteSQLiteUpdate(LDatabase);
    Check(LRecovered.Success,
      'A escrita não recuperou após liberar o lock. ' + ErrorDetail(LRecovered.Error));
  finally
    ReleaseSQLiteWriteBlocker(LBlocker);
    DeleteDatabase(LDatabase);
  end;
end;

procedure TRickSQLConcurrencyTests.Concurrent_SuccessAndFailure_RemainIsolated;
var
  LDatabase: string;
  LSuccessOK, LFailureOK: Integer;
  LTasks: array [0 .. 1] of ITask;
begin
  LDatabase := NewTempDatabase;
  LSuccessOK := 0;
  LFailureOK := 0;
  try
    Check(PrepareIsolationDatabase(LDatabase),
      'Não foi possível preparar o banco SQLite de isolamento.');
    LTasks[0] := TTask.Run(procedure begin ExecuteValidQuery(LDatabase, LSuccessOK); end);
    LTasks[1] := TTask.Run(procedure begin ExecuteInvalidQuery(LDatabase, LFailureOK); end);
    TTask.WaitForAll(LTasks);
    CheckEquals(1, LSuccessOK);
    CheckEquals(1, LFailureOK);
  finally
    DeleteDatabase(LDatabase);
  end;
end;

initialization
  RegisterTest(TRickSQLConcurrencyTests.Suite);

end.
