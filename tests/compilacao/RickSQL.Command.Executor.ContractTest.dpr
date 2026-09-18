program RickSQL.Command.Executor.ContractTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Execution.Result,
  Rick.SQL.Core.Command.Executor;

procedure ValidarSQLVazio;
var
  LConnection: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
  LResult: TRickSQLExecutionResult;
begin
  LConnection := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.SQLite);
  LCommand := TRickSQLCommand.Create(LConnection, '');
  LResult := TRickSQLCoreCommandExecutor.Execute(LCommand);

  if LResult.Success then
    raise Exception.Create('O executor aceitou um comando SQL vazio.');
end;

begin
  try
    ValidarSQLVazio;
    Writeln('Contrato do executor de comandos validado.');
  except
    on E: Exception do
      begin
        Writeln(E.Message);
        Halt(1);
      end;
  end;
end.
