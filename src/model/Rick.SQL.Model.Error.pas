unit Rick.SQL.Model.Error;

// Responsabilidade: representar erros estruturados produzidos pelo RickSQL.
// NAO captura exceções, exibe mensagens ou conhece interface visual.

interface

uses
  // RickSQL
  Rick.SQL.Model.Types;

type
  TRickSQLError = record
    Kind: TRickSQLErrorKind;
    Message: string;
    TechnicalDetail: string;
    DBMSCode: Integer;
    SQLState: string;
    Operation: string;
    HasError: Boolean;
    class function Empty: TRickSQLError; static;
    class function Create(const AKind: TRickSQLErrorKind;
      const AMessage: string): TRickSQLError; static;
  end;

implementation

class function TRickSQLError.Empty: TRickSQLError;
begin
  Result.Kind := TRickSQLErrorKind.None;
  Result.Message := '';
  Result.TechnicalDetail := '';
  Result.DBMSCode := 0;
  Result.SQLState := '';
  Result.Operation := '';
  Result.HasError := False;
end;

class function TRickSQLError.Create(const AKind: TRickSQLErrorKind;
  const AMessage: string): TRickSQLError;
begin
  Result := Empty;
  Result.Kind := AKind;
  Result.Message := AMessage;
  Result.HasError := AKind <> TRickSQLErrorKind.None;
end;

end.
