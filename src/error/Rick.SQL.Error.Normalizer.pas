unit Rick.SQL.Error.Normalizer;

// Responsabilidade: aplicar a política compartilhada de normalização de erros do RickSQL.
// NAO conhece operações de negócio, services específicos ou interface visual.

interface

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Error;

type
  TRickSQLErrorNormalizer = class
  private
    class function FireDACDetail(const AException: Exception): string; static;
    class function ExtractDBMSCode(const AException: Exception): Integer; static;
    class function ExtractSQLState(const AException: Exception): string; static;
    class function SanitizeText(const AText: string): string; static;
    class function MaskSensitiveKeys(const AText: string): string; static;
    class function MaskSensitiveValue(const AText: string;
      const AKey: string): string; static;
    class function SensitiveValueEnd(const AText: string;
      const AStart: Integer): Integer; static;
    class function IsValueDelimiter(const AChar: Char): Boolean; static;
  public
    class function TechnicalDetail(const AException: Exception): string; static;
    class function FromException(const AException: Exception;
      const AKind: TRickSQLErrorKind; const AMessage: string;
      const AOperation: string): TRickSQLError; static;
    class function FromDetail(const AKind: TRickSQLErrorKind;
      const AMessage: string; const ADetail: string;
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
  _DETAIL_NOT_AVAILABLE_ = 'Nenhum detalhe técnico foi informado.';
  _KEY_PASSWORD_ = 'Password=';
  _KEY_PWD_ = 'PWD=';
  _KEY_PASS_ = 'Pass=';
  _KEY_SENHA_ = 'Senha=';
  _KEY_USER_PASSWORD_ = 'User Password=';
  _KEY_USER_PASSWORD_UNDERSCORE_ = 'User_Password=';

class function TRickSQLErrorNormalizer.FireDACDetail(
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

class function TRickSQLErrorNormalizer.ExtractDBMSCode(
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

class function TRickSQLErrorNormalizer.ExtractSQLState(
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

class function TRickSQLErrorNormalizer.SanitizeText(
  const AText: string): string;
begin
  Result := MaskSensitiveKeys(AText);
end;

class function TRickSQLErrorNormalizer.MaskSensitiveKeys(
  const AText: string): string;
begin
  Result := MaskSensitiveValue(AText, _KEY_USER_PASSWORD_);
  Result := MaskSensitiveValue(Result, _KEY_USER_PASSWORD_UNDERSCORE_);
  Result := MaskSensitiveValue(Result, _KEY_PASSWORD_);
  Result := MaskSensitiveValue(Result, _KEY_PWD_);
  Result := MaskSensitiveValue(Result, _KEY_PASS_);
  Result := MaskSensitiveValue(Result, _KEY_SENHA_);
end;

class function TRickSQLErrorNormalizer.MaskSensitiveValue(
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

class function TRickSQLErrorNormalizer.SensitiveValueEnd(
  const AText: string; const AStart: Integer): Integer;
begin
  Result := AStart;
  while (Result <= Length(AText)) and
    not IsValueDelimiter(AText[Result]) do
    Inc(Result);
end;

class function TRickSQLErrorNormalizer.IsValueDelimiter(
  const AChar: Char): Boolean;
begin
  Result := CharInSet(AChar, [';', ',', #13, #10]);
end;

class function TRickSQLErrorNormalizer.TechnicalDetail(
  const AException: Exception): string;
begin
  if not Assigned(AException) then
    Exit(_DETAIL_NOT_AVAILABLE_);

  Result := FireDACDetail(AException);
  if Result = '' then
    Result := AException.Message;

  Result := Trim(Result);
  if Result = '' then
    Result := _DETAIL_NOT_AVAILABLE_;
  Result := SanitizeText(Result);
end;

class function TRickSQLErrorNormalizer.FromException(
  const AException: Exception; const AKind: TRickSQLErrorKind;
  const AMessage: string; const AOperation: string): TRickSQLError;
begin
  Result := FromDetail(AKind, AMessage, TechnicalDetail(AException), AOperation);
  if not Assigned(AException) then
    Exit;

  Result.DBMSCode := ExtractDBMSCode(AException);
  Result.SQLState := ExtractSQLState(AException);
end;

class function TRickSQLErrorNormalizer.FromDetail(
  const AKind: TRickSQLErrorKind; const AMessage: string;
  const ADetail: string; const AOperation: string): TRickSQLError;
begin
  Result := TRickSQLError.Create(AKind, SanitizeText(AMessage));
  Result.TechnicalDetail := SanitizeText(ADetail);
  Result.Operation := AOperation;
end;

end.
