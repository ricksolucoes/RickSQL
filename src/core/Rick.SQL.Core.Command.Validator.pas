unit Rick.SQL.Core.Command.Validator;

// Responsabilidade: validar os dados necessários para executar um comando SQL.
// NAO cria conexões, executa SQL ou conhece interface visual.

interface

uses
  // RickSQL
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Error;

type
  TRickSQLCoreCommandValidator = class
  private
    class function Fail(const AMessage: string;
      out AError: TRickSQLError): Boolean; static;
    class function ValidateSQL(const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
    class function ValidateOptions(const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
  public
    class function Validate(const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
  end;

implementation

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Core.Connection.Validator,
  Rick.SQL.Core.Parameter.Validator;

const
  _OPERATION_ = 'Validação do comando SQL';
  _ERROR_SQL_EMPTY_ =
    'O comando SQL não foi informado. Informe um comando SQL válido antes de chamar Open ou Execute.';
  _ERROR_TIMEOUT_INVALID_ =
    'O tempo limite do comando SQL não pode ser negativo. Informe zero para usar o padrão ou um valor positivo.';
  _ERROR_MAX_RECORDS_INVALID_ =
    'A quantidade máxima de registros não pode ser negativa. Informe zero para não limitar ou um valor positivo.';

class function TRickSQLCoreCommandValidator.Fail(const AMessage: string;
  out AError: TRickSQLError): Boolean;
begin
  AError := TRickSQLError.Create(TRickSQLErrorKind.Validation, AMessage);
  AError.Operation := _OPERATION_;
  Result := False;
end;

class function TRickSQLCoreCommandValidator.ValidateSQL(
  const ACommand: TRickSQLCommand;
  out AError: TRickSQLError): Boolean;
begin
  Result := Trim(ACommand.Text) <> '';

  if not Result then
    Exit(Fail(_ERROR_SQL_EMPTY_, AError));
end;

class function TRickSQLCoreCommandValidator.ValidateOptions(
  const ACommand: TRickSQLCommand;
  out AError: TRickSQLError): Boolean;
begin
  if ACommand.Options.CommandTimeout < 0 then
    Exit(Fail(_ERROR_TIMEOUT_INVALID_, AError));

  Result := ACommand.Options.MaxRecords >= 0;
  if not Result then
    Exit(Fail(_ERROR_MAX_RECORDS_INVALID_, AError));
end;

class function TRickSQLCoreCommandValidator.Validate(
  const ACommand: TRickSQLCommand;
  out AError: TRickSQLError): Boolean;
begin
  AError := TRickSQLError.Empty;
  if not ValidateSQL(ACommand, AError) then
    Exit(False);
  if not TRickSQLCoreConnectionValidator.Validate(
    ACommand.Connection, AError) then
    Exit(False);
  if not ValidateOptions(ACommand, AError) then
    Exit(False);
  Result := TRickSQLCoreParameterValidator.Validate(ACommand, AError);
end;

end.
