program RickSQL.Concorrencia.FalhaIsolada.Test;

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

procedure PrepararBanco(const ADatabase: string);
var
  LConnection: TRickSQLConnectionOptions;
begin
  LConnection := TRickSQLConcurrencyTestHelper.SQLiteConnection(ADatabase);
  ExecutarComando(LConnection, 'create table isolamento (id integer)');
  ExecutarComando(LConnection, 'insert into isolamento (id) values (1)');
end;

procedure ExecutarConsultaValida(const ADatabase: string;
  var AOk: Integer);
var
  LError: TRickSQLError;
  LDataSet: TDataSet;
  LConnection: TRickSQLConnectionOptions;
begin
  LConnection := TRickSQLConcurrencyTestHelper.SQLiteConnection(ADatabase);
  LDataSet := TRickSQL.Open(TRickSQL.Command(LConnection,
    'select id from isolamento'), LError);
  try
    if Assigned(LDataSet) and not LError.HasError then
      TInterlocked.Exchange(AOk, 1);
  finally
    TRickSQLConcurrencyTestHelper.FreeDataSet(LDataSet);
  end;
end;

procedure ExecutarConsultaComFalha(const ADatabase: string;
  var AOk: Integer);
var
  LError: TRickSQLError;
  LDataSet: TDataSet;
  LConnection: TRickSQLConnectionOptions;
begin
  LConnection := TRickSQLConcurrencyTestHelper.SQLiteConnection(ADatabase);
  LDataSet := TRickSQL.Open(TRickSQL.Command(LConnection,
    'select campo_inexistente from tabela_inexistente'), LError);
  try
    if not Assigned(LDataSet) and LError.HasError then
      TInterlocked.Exchange(AOk, 1);
  finally
    TRickSQLConcurrencyTestHelper.FreeDataSet(LDataSet);
  end;
end;

procedure ExecutarTeste;
var
  LDatabase: string;
  LSuccessOK: Integer;
  LFailureOK: Integer;
  LTasks: array [0 .. 1] of ITask;
begin
  LSuccessOK := 0;
  LFailureOK := 0;
  LDatabase := TRickSQLConcurrencyTestHelper.TempDatabaseName('ricksql_isolamento');
  try
    PrepararBanco(LDatabase);
    LTasks[0] := TTask.Run(procedure begin ExecutarConsultaValida(LDatabase, LSuccessOK); end);
    LTasks[1] := TTask.Run(procedure begin ExecutarConsultaComFalha(LDatabase, LFailureOK); end);
    TTask.WaitForAll(LTasks);
    TRickSQLConcurrencyTestHelper.Check(LSuccessOK = 1, 'A consulta válida falhou.');
    TRickSQLConcurrencyTestHelper.Check(LFailureOK = 1, 'A falha não foi isolada.');
  finally
    TRickSQLConcurrencyTestHelper.DeleteFileIfExists(LDatabase);
  end;
end;

begin
  ReportMemoryLeaksOnShutdown := True;

  try
    ExecutarTeste;
    Writeln('Teste de falha isolada concluído com sucesso.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
