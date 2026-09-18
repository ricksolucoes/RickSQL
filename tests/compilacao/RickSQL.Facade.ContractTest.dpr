program RickSQL.Facade.ContractTest;

{$APPTYPE CONSOLE}

uses
  Rick.SQL;

procedure TestPublicFacade;
var
  LConnection: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
  LResult: TRickSQLExecutionResult;
begin
  LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  LCommand := TRickSQL.Command(LConnection, 'select 1 as id');
  TRickSQL.Open(LCommand, LError).Free;
  LResult := TRickSQL.Execute(LCommand);
  if LResult.Success then
    Exit;
end;

begin
end.
