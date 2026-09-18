unit Rick.SQL.Model.Execution.Result;

// Responsabilidade: representar o resultado da execução de comandos sem conjunto de dados.
// NAO executa comandos, controla transações ou apresenta mensagens.

interface

uses
  // RickSQL
  Rick.SQL.Model.Error;

type
  TRickSQLExecutionResult = record
    Success: Boolean;
    RowsAffected: Integer;
    Error: TRickSQLError;
    class function Succeeded(const ARowsAffected: Integer)
      : TRickSQLExecutionResult; static;
    class function Failed(const AError: TRickSQLError)
      : TRickSQLExecutionResult; static;

    class function Default: TRickSQLExecutionResult; static;
  end;

implementation

class function TRickSQLExecutionResult.Succeeded(
  const ARowsAffected: Integer): TRickSQLExecutionResult;
begin
  Result.Success := True;
  Result.RowsAffected := ARowsAffected;
  Result.Error := TRickSQLError.Empty;
end;

class function TRickSQLExecutionResult.Default: TRickSQLExecutionResult;
begin
  Result.Success := False;
  Result.RowsAffected := 0;
  Result.Error := TRickSQLError.Empty;
end;

class function TRickSQLExecutionResult.Failed(
  const AError: TRickSQLError): TRickSQLExecutionResult;
begin
  Result.Success := False;
  Result.RowsAffected := 0;
  Result.Error := AError;

end;

end.
