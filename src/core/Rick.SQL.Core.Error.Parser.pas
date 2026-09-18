unit Rick.SQL.Core.Error.Parser;

// Responsabilidade: converter falhas internas em erros estruturados do RickSQL.
// NAO exibe mensagens, registra logs ou expõe credenciais.

interface

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Error;

type
  TRickSQLCoreErrorParser = class
  private
    class function FriendlyMessage(
      const AKind: TRickSQLErrorKind): string; static;
    class function CreateError(const AKind: TRickSQLErrorKind;
      const ADetail: string; const AOperation: string): TRickSQLError; static;
    class function TechnicalDetail(const AException: Exception): string; static;
    class function FireDACDetail(const AException: Exception): string; static;
    class function ExtractDBMSCode(const AException: Exception): Integer; static;
    class function ExtractSQLState(const AException: Exception): string; static;
    class function SanitizeDetail(const ADetail: string): string; static;
    class function MaskSensitiveKeys(const AText: string): string; static;
    class function MaskSensitiveValue(const AText: string;
      const AKey: string): string; static;
    class function SensitiveValueEnd(const AText: string;
      const AStart: Integer): Integer; static;
    class function IsValueDelimiter(const AChar: Char): Boolean; static;
  public
    class function FromException(const AException: Exception;
      const AKind: TRickSQLErrorKind;
      const AOperation: string): TRickSQLError; static;
    class function FromMessage(const AKind: TRickSQLErrorKind;
      const AMessage: string;
      const AOperation: string): TRickSQLError; static;
    class function Unexpected(const AException: Exception;
      const AOperation: string): TRickSQLError; static;
  end;

implementation

uses
  // RTL
  System.StrUtils,

  // FireDAC
{$IFDEF FULL_EDITION}
  FireDAC.Phys.ODBCWrapper,
{$ENDIF}
  FireDAC.Stan.Error,
  FireDAC.Phys.IBWrapper,
  FireDAC.Phys.MySQLWrapper;



const
  _MASK_ = '***';
  _MESSAGE_VALIDATION_ =
    'Os dados informados para a operação SQL são inválidos. Revise as opções, o SQL e os parâmetros.';
  _MESSAGE_UNSUPPORTED_DATABASE_ =
    'O banco de dados informado não é suportado pelo RickSQL. Selecione um mecanismo disponível no enum.';
  _MESSAGE_DRIVER_ =
    'Não foi possível configurar o driver do banco de dados. Verifique o mecanismo e a biblioteca cliente.';
  _MESSAGE_CLIENT_LIBRARY_ =
    'A biblioteca cliente necessária para o banco de dados não foi localizada. Informe ClientLibraryPath ou coloque a biblioteca no diretório da aplicação.';
  _MESSAGE_CONNECTION_ =
    'Não foi possível estabelecer conexão com o banco de dados. ' +
    'Verifique o servidor, a porta, o banco informado e as credenciais de acesso.';
  _MESSAGE_COMMAND_ =
    'Não foi possível executar o comando SQL informado. Verifique a sintaxe e os parâmetros.';
  _MESSAGE_PARAMETER_ =
    'Não foi possível aplicar os parâmetros do comando SQL. Verifique nomes, tipos e valores informados.';
  _MESSAGE_TRANSACTION_ =
    'Não foi possível concluir a transação do banco de dados. Verifique o estado da conexão e tente novamente.';
  _MESSAGE_DATASET_ =
    'Não foi possível preparar o conjunto de dados retornado pela consulta. Verifique os campos retornados pelo SQL.';
  _MESSAGE_UNEXPECTED_ =
    'Ocorreu uma falha inesperada durante a operação SQL. Verifique o detalhe técnico e tente novamente.';
  _DETAIL_NOT_AVAILABLE_ = 'Nenhum detalhe técnico foi informado.';
  _KEY_PASSWORD_ = 'Password=';
  _KEY_PWD_ = 'PWD=';
  _KEY_PASS_ = 'Pass=';
  _KEY_SENHA_ = 'Senha=';
  _KEY_USER_PASSWORD_ = 'User Password=';
  _KEY_USER_PASSWORD_UNDERSCORE_ = 'User_Password=';

class function TRickSQLCoreErrorParser.FriendlyMessage(
  const AKind: TRickSQLErrorKind): string;
const
  _MAP_ERROR_MESSAGES: array[TRickSQLErrorKind] of string = (
    _MESSAGE_UNEXPECTED_,          // None
    _MESSAGE_VALIDATION_,          // Validation
    _MESSAGE_UNSUPPORTED_DATABASE_,// UnsupportedDatabase
    _MESSAGE_DRIVER_,              // Driver
    _MESSAGE_CLIENT_LIBRARY_,      // ClientLibrary
    _MESSAGE_CONNECTION_,          // Connection
    _MESSAGE_COMMAND_,             // Command
    _MESSAGE_PARAMETER_,           // Parameter
    _MESSAGE_TRANSACTION_,         // Transaction
    _MESSAGE_DATASET_,             // DataSet
    _MESSAGE_UNEXPECTED_           // Unexpected
  );
begin
  Result := _MAP_ERROR_MESSAGES[AKind];
end;

class function TRickSQLCoreErrorParser.CreateError(
  const AKind: TRickSQLErrorKind; const ADetail: string;
  const AOperation: string): TRickSQLError;
begin
  Result := TRickSQLError.Create(AKind, FriendlyMessage(AKind));
  Result.TechnicalDetail := SanitizeDetail(ADetail);
  Result.Operation := AOperation;
end;

class function TRickSQLCoreErrorParser.TechnicalDetail(
  const AException: Exception): string;
begin
  Result := FireDACDetail(AException);

  if Result = '' then
    Result := AException.Message;
end;

class function TRickSQLCoreErrorParser.FireDACDetail(
  const AException: Exception): string;
var
  LFDError: EFDDBEngineException;
begin
  Result := '';

  if not (AException is EFDDBEngineException) then
    Exit;

  LFDError := EFDDBEngineException(AException);
  if LFDError.ErrorCount > 0 then
    Result := LFDError.Errors[0].Message;
end;

class function TRickSQLCoreErrorParser.ExtractDBMSCode(
  const AException: Exception): Integer;
var
  LFDError: EFDDBEngineException;
begin
  Result := 0;

  if not (AException is EFDDBEngineException) then
    Exit;

  LFDError := EFDDBEngineException(AException);
  if LFDError.ErrorCount > 0 then
    Result := LFDError.Errors[0].ErrorCode;
end;

class function TRickSQLCoreErrorParser.ExtractSQLState(
  const AException: Exception): string;
var
  LFDError: EFDDBEngineException;
  LDBError: TFDDBError;
begin
  Result := '';

  if not (AException is EFDDBEngineException) then
    Exit;

  LFDError := EFDDBEngineException(AException);

  if LFDError.ErrorCount = 0 then
    Exit;

  LDBError := LFDError.Errors[0];

  if LDBError is TFDIBError then
    Exit(TFDIBError(LDBError).SQLState);

  if LDBError is TFDMySQLError then
    Exit(TFDMySQLError(LDBError).SQLState);

{$IFDEF FULL_EDITION}
  if LDBError is TFDODBCNativeError then
    Exit(TFDODBCNativeError(LDBError).SQLState);
{$ENDIF}
end;

class function TRickSQLCoreErrorParser.SanitizeDetail(
  const ADetail: string): string;
begin
  Result := Trim(ADetail);

  if Result = '' then
    Exit(_DETAIL_NOT_AVAILABLE_);

  Result := MaskSensitiveKeys(Result);
end;

class function TRickSQLCoreErrorParser.MaskSensitiveKeys(
  const AText: string): string;
begin
  Result := MaskSensitiveValue(AText, _KEY_USER_PASSWORD_);
  Result := MaskSensitiveValue(Result, _KEY_USER_PASSWORD_UNDERSCORE_);
  Result := MaskSensitiveValue(Result, _KEY_PASSWORD_);
  Result := MaskSensitiveValue(Result, _KEY_PWD_);
  Result := MaskSensitiveValue(Result, _KEY_PASS_);
  Result := MaskSensitiveValue(Result, _KEY_SENHA_);
end;

class function TRickSQLCoreErrorParser.MaskSensitiveValue(
  const AText: string; const AKey: string): string;
var
  LPosition: Integer;
  LStart: Integer;
begin
  Result := AText;
  LPosition := Pos(UpperCase(AKey), UpperCase(Result));
  while LPosition > 0 do
  begin
    LStart := LPosition + Length(AKey);
    Delete(Result, LStart, SensitiveValueEnd(Result, LStart) - LStart);
    Insert(_MASK_, Result, LStart);
    LPosition := PosEx(UpperCase(AKey), UpperCase(Result), LStart + 1);
  end;
end;

class function TRickSQLCoreErrorParser.SensitiveValueEnd(
  const AText: string; const AStart: Integer): Integer;
begin
  Result := AStart;
  while (Result <= Length(AText)) and
    not IsValueDelimiter(AText[Result]) do
    Inc(Result);
end;

class function TRickSQLCoreErrorParser.IsValueDelimiter(
  const AChar: Char): Boolean;
begin
  Result := CharInSet(AChar, [';', ',', #13, #10]);
end;

class function TRickSQLCoreErrorParser.FromException(
  const AException: Exception; const AKind: TRickSQLErrorKind;
  const AOperation: string): TRickSQLError;
begin
  if not Assigned(AException) then
    Exit(FromMessage(AKind, _DETAIL_NOT_AVAILABLE_, AOperation));

  Result := CreateError(AKind, TechnicalDetail(AException), AOperation);
  Result.DBMSCode := ExtractDBMSCode(AException);
  Result.SQLState := ExtractSQLState(AException);
end;

class function TRickSQLCoreErrorParser.FromMessage(
  const AKind: TRickSQLErrorKind; const AMessage: string;
  const AOperation: string): TRickSQLError;
begin
  Result := CreateError(AKind, AMessage, AOperation);
end;

class function TRickSQLCoreErrorParser.Unexpected(
  const AException: Exception; const AOperation: string): TRickSQLError;
begin
  Result := FromException(AException, TRickSQLErrorKind.Unexpected, AOperation);
end;

end.
