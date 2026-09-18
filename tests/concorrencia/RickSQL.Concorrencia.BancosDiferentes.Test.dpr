program RickSQL.Concorrencia.BancosDiferentes.Test;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,
  System.Threading,
  System.SyncObjs,

  // Data
  Data.DB,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Concurrency.Test.Helper;

function PostgreSQLConfigurado: Boolean;
begin
  Result := TRickSQLConcurrencyTestHelper.HasEnv('RICKSQL_PG_DATABASE');
end;

function PostgreSQLConnection: TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.PostgreSQL);
  Result.Server := TRickSQLConcurrencyTestHelper.Env('RICKSQL_PG_SERVER');
  Result.Port := StrToIntDef(TRickSQLConcurrencyTestHelper.Env('RICKSQL_PG_PORT'), 0);
  Result.Database := TRickSQLConcurrencyTestHelper.Env('RICKSQL_PG_DATABASE');
  Result.UserName := TRickSQLConcurrencyTestHelper.Env('RICKSQL_PG_USER');
  Result.Password := TRickSQLConcurrencyTestHelper.Env('RICKSQL_PG_PASSWORD');
end;

procedure ExecutarConsulta(const AConnection: TRickSQLConnectionOptions;
  const ASQL: string; var AOk: Integer);
var
  LError: TRickSQLError;
  LDataSet: TDataSet;
begin
  LDataSet := TRickSQL.Open(TRickSQL.Command(AConnection, ASQL), LError);
  try
    if Assigned(LDataSet) and not LError.HasError then
      TInterlocked.Exchange(AOk, 1);
  finally
    TRickSQLConcurrencyTestHelper.FreeDataSet(LDataSet);
  end;
end;

procedure ExecutarSQLite(const ADatabase: string; var AOk: Integer);
var
  LConnection: TRickSQLConnectionOptions;
begin
  LConnection := TRickSQLConcurrencyTestHelper.SQLiteConnection(ADatabase);
  TRickSQL.Execute(TRickSQL.Command(LConnection, 'create table teste (id integer)'));
  TRickSQL.Execute(TRickSQL.Command(LConnection, 'insert into teste (id) values (1)'));
  ExecutarConsulta(LConnection, 'select id from teste', AOk);
end;

procedure ExecutarPostgreSQL(var AOk: Integer);
begin
  ExecutarConsulta(PostgreSQLConnection, 'select 1 as id', AOk);
end;

procedure ExecutarTeste;
var
  LDatabase: string;
  LSQLiteOK: Integer;
  LPGOK: Integer;
  LTasks: array [0 .. 1] of ITask;
begin
  if not PostgreSQLConfigurado then
  begin
    Writeln('Teste ignorado: PostgreSQL não configurado.');
    Exit;
  end;

  LSQLiteOK := 0;
  LPGOK := 0;
  LDatabase := TRickSQLConcurrencyTestHelper.TempDatabaseName('ricksql_multi_banco');
  try
    LTasks[0] := TTask.Run(procedure begin ExecutarSQLite(LDatabase, LSQLiteOK); end);
    LTasks[1] := TTask.Run(procedure begin ExecutarPostgreSQL(LPGOK); end);
    TTask.WaitForAll(LTasks);
    TRickSQLConcurrencyTestHelper.Check(LSQLiteOK = 1, 'SQLite não concluiu.');
    TRickSQLConcurrencyTestHelper.Check(LPGOK = 1, 'PostgreSQL não concluiu.');
  finally
    TRickSQLConcurrencyTestHelper.DeleteFileIfExists(LDatabase);
  end;
end;

begin
  ReportMemoryLeaksOnShutdown := True;

  try
    ExecutarTeste;
    Writeln('Teste de bancos diferentes concluído com sucesso.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
