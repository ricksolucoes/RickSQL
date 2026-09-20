unit Rick.SQL.Tests.External.Integration;

interface

uses
  TestFramework,
  Rick.SQL;

type
  TRickSQLExternalIntegrationTests = class(TTestCase)
  private
    function Env(const AName: string): string;
    function HasEnv(const AName: string): Boolean;
    function FirebirdConnection: TRickSQLConnectionOptions;
    function PostgreSQLConnection: TRickSQLConnectionOptions;
{$IFDEF FULL_EDITION}
    function SQLServerConnection: TRickSQLConnectionOptions;
    function ODBCConnection: TRickSQLConnectionOptions;
{$ENDIF}
    procedure ExecuteSuccess(const AConnection: TRickSQLConnectionOptions;
      const ASQL: string);
    procedure DropTable(const AConnection: TRickSQLConnectionOptions);
    procedure InsertRow(const AConnection: TRickSQLConnectionOptions);
    procedure OpenRow(const AConnection: TRickSQLConnectionOptions);
    procedure UpdateDeleteRow(const AConnection: TRickSQLConnectionOptions);
    procedure RunCRUD(const AConnection: TRickSQLConnectionOptions;
      const ACreateSQL: string);
  published
    procedure Firebird_WhenConfigured_CRUDAndOpenSucceed;
    procedure PostgreSQL_WhenConfigured_CRUDAndOpenSucceed;
    procedure PostgreSQL_WhenConfigured_InvalidCredentialReturnsError;
{$IFDEF FULL_EDITION}
    procedure SQLServer_WhenConfigured_CRUDAndOpenSucceed;
    procedure ODBC_WhenConfigured_OpenReturnsDataSet;
{$ENDIF}
  end;

implementation

uses
  System.SysUtils,
  Data.DB;

const
  _TABLE_ = 'ricksql_dunit_integration';

function TRickSQLExternalIntegrationTests.Env(const AName: string): string;
begin
  Result := Trim(GetEnvironmentVariable(AName));
end;

function TRickSQLExternalIntegrationTests.HasEnv(const AName: string): Boolean;
begin
  Result := Env(AName) <> '';
end;

function TRickSQLExternalIntegrationTests.FirebirdConnection
  : TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.Firebird);
  Result.Server := Env('RICKSQL_FIREBIRD_SERVER');
  Result.Database := Env('RICKSQL_FIREBIRD_DATABASE');
  Result.UserName := Env('RICKSQL_FIREBIRD_USERNAME');
  Result.Password := Env('RICKSQL_FIREBIRD_PASSWORD');
  Result.ClientLibraryPath := Env('RICKSQL_FIREBIRD_CLIENT_LIBRARY');
end;

function TRickSQLExternalIntegrationTests.PostgreSQLConnection
  : TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.PostgreSQL);
  Result.Server := Env('RICKSQL_POSTGRESQL_SERVER');
  Result.Database := Env('RICKSQL_POSTGRESQL_DATABASE');
  Result.UserName := Env('RICKSQL_POSTGRESQL_USERNAME');
  Result.Password := Env('RICKSQL_POSTGRESQL_PASSWORD');
  Result.ClientLibraryPath := Env('RICKSQL_POSTGRESQL_CLIENT_LIBRARY');
end;

{$IFDEF FULL_EDITION}
function TRickSQLExternalIntegrationTests.SQLServerConnection
  : TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLServer);
  Result.Server := Env('RICKSQL_SQLSERVER_SERVER');
  Result.Database := Env('RICKSQL_SQLSERVER_DATABASE');
  Result.UserName := Env('RICKSQL_SQLSERVER_USERNAME');
  Result.Password := Env('RICKSQL_SQLSERVER_PASSWORD');
end;

function TRickSQLExternalIntegrationTests.ODBCConnection
  : TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.ODBC);
  Result.Database := Env('RICKSQL_ODBC_DATASOURCE');
  Result.UserName := Env('RICKSQL_ODBC_USERNAME');
  Result.Password := Env('RICKSQL_ODBC_PASSWORD');
end;
{$ENDIF}

procedure TRickSQLExternalIntegrationTests.ExecuteSuccess(
  const AConnection: TRickSQLConnectionOptions; const ASQL: string);
var
  LResult: TRickSQLExecutionResult;
begin
  LResult := TRickSQL.Execute(TRickSQL.Command(AConnection, ASQL));
  Check(LResult.Success, LResult.Error.Message);
end;

procedure TRickSQLExternalIntegrationTests.DropTable(
  const AConnection: TRickSQLConnectionOptions);
begin
  TRickSQL.Execute(TRickSQL.Command(AConnection, 'drop table ' + _TABLE_));
end;

procedure TRickSQLExternalIntegrationTests.InsertRow(
  const AConnection: TRickSQLConnectionOptions);
var
  LCommand: TRickSQLCommand;
  LResult: TRickSQLExecutionResult;
begin
  LCommand := TRickSQL.Command(AConnection,
    'insert into ' + _TABLE_ + ' (id, name) values (:ID, :NAME)');
  LCommand.AddParameter(TRickSQLParameter.Create('ID', 1));
  LCommand.AddParameter(TRickSQLParameter.Create('NAME', 'RickSQL'));
  LResult := TRickSQL.Execute(LCommand);
  Check(LResult.Success, LResult.Error.Message);
  CheckEquals(1, LResult.RowsAffected);
end;

procedure TRickSQLExternalIntegrationTests.OpenRow(
  const AConnection: TRickSQLConnectionOptions);
var
  LCommand: TRickSQLCommand;
  LDataSet: TDataSet;
  LError: TRickSQLError;
begin
  LCommand := TRickSQL.Command(AConnection,
    'select id, name from ' + _TABLE_ + ' where id = :ID');
  LCommand.AddParameter(TRickSQLParameter.Create('ID', 1));
  LDataSet := TRickSQL.Open(LCommand, LError);
  try
    Check(Assigned(LDataSet), LError.Message);
    Check(not LError.HasError);
    CheckEquals('RickSQL', LDataSet.FieldByName('name').AsString);
  finally
    LDataSet.Free;
  end;
end;

procedure TRickSQLExternalIntegrationTests.UpdateDeleteRow(
  const AConnection: TRickSQLConnectionOptions);
var
  LResult: TRickSQLExecutionResult;
begin
  LResult := TRickSQL.Execute(TRickSQL.Command(AConnection,
    'update ' + _TABLE_ + ' set name = ''Updated'' where id = 1'));
  Check(LResult.Success, LResult.Error.Message);
  CheckEquals(1, LResult.RowsAffected);
  LResult := TRickSQL.Execute(TRickSQL.Command(AConnection,
    'delete from ' + _TABLE_ + ' where id = 1'));
  Check(LResult.Success, LResult.Error.Message);
  CheckEquals(1, LResult.RowsAffected);
end;

procedure TRickSQLExternalIntegrationTests.RunCRUD(
  const AConnection: TRickSQLConnectionOptions; const ACreateSQL: string);
begin
  DropTable(AConnection);
  try
    ExecuteSuccess(AConnection, ACreateSQL);
    InsertRow(AConnection);
    OpenRow(AConnection);
    UpdateDeleteRow(AConnection);
  finally
    DropTable(AConnection);
  end;
end;

procedure TRickSQLExternalIntegrationTests.Firebird_WhenConfigured_CRUDAndOpenSucceed;
begin
  if not HasEnv('RICKSQL_FIREBIRD_DATABASE') then
    Exit;
  RunCRUD(FirebirdConnection, 'create table ' + _TABLE_ +
    ' (id integer not null primary key, name varchar(40))');
end;

procedure TRickSQLExternalIntegrationTests.PostgreSQL_WhenConfigured_CRUDAndOpenSucceed;
begin
  if not HasEnv('RICKSQL_POSTGRESQL_DATABASE') then
    Exit;
  RunCRUD(PostgreSQLConnection, 'create table ' + _TABLE_ +
    ' (id integer primary key, name varchar(40))');
end;

procedure TRickSQLExternalIntegrationTests.
  PostgreSQL_WhenConfigured_InvalidCredentialReturnsError;
var
  LConnection: TRickSQLConnectionOptions;
  LResult: TRickSQLExecutionResult;
begin
  if not HasEnv('RICKSQL_POSTGRESQL_DATABASE') then
    Exit;
  LConnection := PostgreSQLConnection;
  LConnection.Password := 'ricksql_invalid_password';
  LResult := TRickSQL.Execute(TRickSQL.Command(LConnection, 'select 1'));
  Check(not LResult.Success);
  Check(LResult.Error.HasError);
end;

{$IFDEF FULL_EDITION}
procedure TRickSQLExternalIntegrationTests.SQLServer_WhenConfigured_CRUDAndOpenSucceed;
begin
  if not HasEnv('RICKSQL_SQLSERVER_DATABASE') then
    Exit;
  RunCRUD(SQLServerConnection, 'create table ' + _TABLE_ +
    ' (id int not null primary key, name varchar(40))');
end;

procedure TRickSQLExternalIntegrationTests.ODBC_WhenConfigured_OpenReturnsDataSet;
var
  LDataSet: TDataSet;
  LError: TRickSQLError;
  LSQL: string;
begin
  if not HasEnv('RICKSQL_ODBC_DATASOURCE') then
    Exit;
  LSQL := Env('RICKSQL_ODBC_SELECT_SQL');
  if LSQL = '' then
    LSQL := 'select 1 as codigo';
  LDataSet := TRickSQL.Open(TRickSQL.Command(ODBCConnection, LSQL), LError);
  try
    Check(Assigned(LDataSet), LError.Message);
    Check(not LError.HasError);
  finally
    LDataSet.Free;
  end;
end;
{$ENDIF}

initialization
  RegisterTest(TRickSQLExternalIntegrationTests.Suite);

end.
