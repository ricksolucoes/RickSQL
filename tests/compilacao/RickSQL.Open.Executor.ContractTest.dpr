program RickSQL.Open.Executor.ContractTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,

  // Data
  Data.DB,

  // RickSQL
  Rick.SQL.Core.Open.Executor,
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Error,
  Rick.SQL.Model.Types;

procedure AssertCondition(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure TestEmptySQLDoesNotOpenConnection;
var
  LConnection: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
  LDataSet: TDataSet;
begin
  LConnection := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.SQLite);
  LConnection.Database := ':memory:';
  LCommand := TRickSQLCommand.Create(LConnection, '');

  LDataSet := TRickSQLCoreOpenExecutor.Open(LCommand, LError);
  AssertCondition(not Assigned(LDataSet), 'Dataset inválido retornado.');
  AssertCondition(LError.HasError, 'Erro de validação não retornado.');
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  TestEmptySQLDoesNotOpenConnection;
  Writeln('Contrato do executor de consulta validado.');
end.
