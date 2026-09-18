program RickSQLModelsCompilationTest;

{$APPTYPE CONSOLE}

uses
  Rick.SQL;

var
  LConnection: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
  LParameter: TRickSQLParameter;
  LError: TRickSQLError;
  LResult: TRickSQLExecutionResult;
begin
  LConnection := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.SQLite);
  LConnection.Database := 'teste.db';
  LConnection.AddExtraParameter('LockingMode', 'Normal');

  LCommand := TRickSQLCommand.Create(LConnection,
    'select * from exemplo where id = :ID');
  LParameter := TRickSQLParameter.Create('ID', 1);
  LCommand.AddParameter(LParameter);

  LError := TRickSQLError.Empty;
  LResult := TRickSQLExecutionResult.Succeeded(0);

  if LError.HasError or not LResult.Success then
    Halt(1);
end.
