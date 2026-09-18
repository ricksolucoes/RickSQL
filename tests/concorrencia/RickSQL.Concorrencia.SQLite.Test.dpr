program RickSQL.Concorrencia.SQLite.Test;

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

procedure ExecutarComando(const AConnection: TRickSQLConnectionOptions;
  const ASQL: string);
var
  LResult: TRickSQLExecutionResult;
begin
  LResult := TRickSQL.Execute(TRickSQL.Command(AConnection, ASQL));
  TRickSQLConcurrencyTestHelper.Check(LResult.Success, LResult.Error.Message);
end;

procedure ExecutarConsulta(const AConnection: TRickSQLConnectionOptions);
var
  LError: TRickSQLError;
  LDataSet: TDataSet;
begin
  LDataSet := TRickSQL.Open(TRickSQL.Command(AConnection,
    'select id, nome from concorrencia'), LError);
  try
    TRickSQLConcurrencyTestHelper.Check(not LError.HasError, LError.Message);
    TRickSQLConcurrencyTestHelper.Check(Assigned(LDataSet), 'Dataset não retornado.');
  finally
    TRickSQLConcurrencyTestHelper.FreeDataSet(LDataSet);
  end;
end;

procedure PrepararBanco(const ADatabase: string);
var
  LConnection: TRickSQLConnectionOptions;
begin
  LConnection := TRickSQLConcurrencyTestHelper.SQLiteConnection(ADatabase);
  ExecutarComando(LConnection,
    'create table concorrencia (id integer primary key, nome varchar(40))');
  ExecutarComando(LConnection,
    'insert into concorrencia (id, nome) values (1, ''Teste'')');
end;

procedure ExecutarTarefaConsulta(const ADatabase: string);
var
  LConnection: TRickSQLConnectionOptions;
  LIndex: Integer;
begin
  LConnection := TRickSQLConcurrencyTestHelper.SQLiteConnection(ADatabase);
  for LIndex := 1 to 30 do
    ExecutarConsulta(LConnection);
end;

procedure ExecutarTarefaComando(const ADatabase: string);
var
  LConnection: TRickSQLConnectionOptions;
  LIndex: Integer;
begin
  LConnection := TRickSQLConcurrencyTestHelper.SQLiteConnection(ADatabase);
  for LIndex := 1 to 30 do
    ExecutarComando(LConnection, 'update concorrencia set nome = ''Teste''');
end;

procedure ExecutarTeste;
var
  LDatabase: string;
  LTasks: array [0 .. 1] of ITask;
begin
  LDatabase := TRickSQLConcurrencyTestHelper.TempDatabaseName('ricksql_concorrencia');
  try
    PrepararBanco(LDatabase);
    LTasks[0] := TTask.Run(procedure begin ExecutarTarefaConsulta(LDatabase); end);
    LTasks[1] := TTask.Run(procedure begin ExecutarTarefaComando(LDatabase); end);
    TTask.WaitForAll(LTasks);
  finally
    TRickSQLConcurrencyTestHelper.DeleteFileIfExists(LDatabase);
  end;
end;

begin
  ReportMemoryLeaksOnShutdown := True;

  try
    ExecutarTeste;
    Writeln('Teste de concorrência SQLite concluído com sucesso.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
