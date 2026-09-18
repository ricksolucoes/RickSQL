program RickSQL.Error.Parser.ContractTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Error,
  Rick.SQL.Core.Error.Parser;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure TestConnectionError;
var
  LException: Exception;
  LError: TRickSQLError;
begin
  LException := Exception.Create('Falha: Password=segredo;Database=teste');
  try
    LError := TRickSQLCoreErrorParser.FromException(
      LException, TRickSQLErrorKind.Connection, 'Teste de conexão');
  finally
    LException.Free;
  end;

  Check(LError.HasError, 'O erro deveria estar marcado.');
  Check(LError.Kind = TRickSQLErrorKind.Connection, 'Categoria incorreta.');
  Check(LError.Operation = 'Teste de conexão', 'Operação incorreta.');
  Check(Pos('segredo', LError.TechnicalDetail) = 0, 'Senha exposta.');
end;

procedure TestMessageError;
var
  LError: TRickSQLError;
begin
  LError := TRickSQLCoreErrorParser.FromMessage(
    TRickSQLErrorKind.Parameter, 'Parâmetro ausente.', 'Teste');

  Check(LError.HasError, 'O erro deveria estar marcado.');
  Check(LError.Kind = TRickSQLErrorKind.Parameter, 'Categoria incorreta.');
  Check(LError.TechnicalDetail = 'Parâmetro ausente.', 'Detalhe incorreto.');
end;

begin
  try
    TestConnectionError;
    TestMessageError;
    Writeln('Contrato do parser de erros validado.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
