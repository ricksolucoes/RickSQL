unit Rick.SQL.Core.Connection.Validator;

// Responsabilidade: validar as opções necessárias para estabelecer uma conexão.
// NAO abre conexões, cria driver links ou executa comandos SQL.

interface

uses
  // RickSQL
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Contracts,
  Rick.SQL.Model.Error;

type
  TRickSQLCoreConnectionValidator = class
  private
    class function Fail(const AMessage: string;
      out AError: TRickSQLError): Boolean; static;
    class function HasConnectionData(
      const AOptions: TRickSQLConnectionOptions): Boolean; static;
    class function ValidateEngine(const AOptions: TRickSQLConnectionOptions;
      out AError: TRickSQLError): Boolean; static;
    class function ValidatePort(const AOptions: TRickSQLConnectionOptions;
      out AError: TRickSQLError): Boolean; static;
    class function ValidateTimeout(const AOptions: TRickSQLConnectionOptions;
      out AError: TRickSQLError): Boolean; static;
    class function ValidateClientLibraryPath(
      const AOptions: TRickSQLConnectionOptions;
      out AError: TRickSQLError): Boolean; static;
    class function HasDuplicateExtraParameter(
      const AOptions: TRickSQLConnectionOptions;
      const AIndex: Integer): Boolean; static;
    class function ExtraParameterError(
      const AOptions: TRickSQLConnectionOptions;
      const AIndex: Integer): string; static;
    class function ValidateExtraParameters(
      const AOptions: TRickSQLConnectionOptions;
      out AError: TRickSQLError): Boolean; static;
    class function ValidateGeneralOptions(
      const AOptions: TRickSQLConnectionOptions;
      out AError: TRickSQLError): Boolean; static;
    class function ValidateProvider(const AOptions: TRickSQLConnectionOptions;
      out AProvider: IRickSQLDriverProvider;
      out AError: TRickSQLError): Boolean; static;
  public
    class function Validate(const AOptions: TRickSQLConnectionOptions;
      out AError: TRickSQLError): Boolean; overload; static;
    class function Validate(const AOptions: TRickSQLConnectionOptions;
      out AProvider: IRickSQLDriverProvider;
      out AError: TRickSQLError): Boolean; overload; static;
  end;

implementation

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Core.Driver.Factory;

const
  _PARAM_DRIVER_ID_ = 'DriverID';
  _OPERATION_ = 'Validação da conexão';
  _ERROR_CONNECTION_NOT_CONFIGURED_ =
    'As opções de conexão não foram configuradas. Informe banco, arquivo, servidor ou credenciais conforme o mecanismo escolhido.';
  _ERROR_ENGINE_INVALID_ =
    'O mecanismo de banco de dados informado não é válido. Selecione um valor de TRickSQLDatabaseEngine suportado.';
  _ERROR_ENGINE_UNSUPPORTED_ =
    'O mecanismo de banco de dados informado não possui um driver registrado. Revise o mecanismo escolhido antes de conectar.';
  _ERROR_PORT_INVALID_ =
    'A porta deve estar entre 1 e 65535 ou permanecer com o valor zero. Corrija a porta da conexão.';
  _ERROR_TIMEOUT_INVALID_ =
    'O tempo limite da conexão não pode ser negativo. Informe zero para usar o padrão ou um valor positivo.';
  _ERROR_LIBRARY_PATH_INVALID_ =
    'O caminho da biblioteca cliente deve identificar um arquivo ou diretório válido. Remova caracteres inválidos de ClientLibraryPath.';
  _ERROR_EXTRA_NAME_EMPTY_ =
    'O nome de um parâmetro adicional da conexão não foi informado. Informe o nome ou remova o parâmetro vazio.';
  _ERROR_EXTRA_NAME_INVALID_ =
    'O nome do parâmetro adicional "%s" contém caracteres inválidos. Remova quebras de linha e o caractere igual.';
  _ERROR_EXTRA_VALUE_EMPTY_ =
    'O valor do parâmetro adicional "%s" não foi informado. Informe o valor ou remova o parâmetro.';
  _ERROR_EXTRA_RESERVED_ =
    'O parâmetro adicional "DriverID" é reservado para uso interno. Selecione o banco pelo enum TRickSQLDatabaseEngine.';
  _ERROR_EXTRA_DUPLICATE_ =
    'O parâmetro adicional "%s" foi informado mais de uma vez. Mantenha apenas uma ocorrência.';

class function TRickSQLCoreConnectionValidator.Fail(
  const AMessage: string; out AError: TRickSQLError): Boolean;
begin
  AError := TRickSQLError.Create(TRickSQLErrorKind.Validation, AMessage);
  AError.Operation := _OPERATION_;
  Result := False;
end;

class function TRickSQLCoreConnectionValidator.HasConnectionData(
  const AOptions: TRickSQLConnectionOptions): Boolean;
begin
  Result := (Trim(AOptions.Server) <> '') or
    (Trim(AOptions.Database) <> '') or
    (Trim(AOptions.UserName) <> '') or
    (AOptions.Password <> '') or
    (AOptions.Port <> 0) or
    (Length(AOptions.ExtraParameters) > 0);
end;

class function TRickSQLCoreConnectionValidator.ValidateEngine(
  const AOptions: TRickSQLConnectionOptions;
  out AError: TRickSQLError): Boolean;
var
  LValue: Integer;
begin
  LValue := Ord(AOptions.Engine);
  Result := (LValue >= Ord(Low(TRickSQLDatabaseEngine))) and
    (LValue <= Ord(High(TRickSQLDatabaseEngine)));
  if not Result then
    Exit(Fail(_ERROR_ENGINE_INVALID_, AError));
end;

class function TRickSQLCoreConnectionValidator.ValidatePort(
  const AOptions: TRickSQLConnectionOptions;
  out AError: TRickSQLError): Boolean;
begin
  Result := (AOptions.Port >= 0) and (AOptions.Port <= 65535);
  if not Result then
    Exit(Fail(_ERROR_PORT_INVALID_, AError));
end;

class function TRickSQLCoreConnectionValidator.ValidateTimeout(
  const AOptions: TRickSQLConnectionOptions;
  out AError: TRickSQLError): Boolean;
begin
  Result := AOptions.ConnectTimeout >= 0;
  if not Result then
    Exit(Fail(_ERROR_TIMEOUT_INVALID_, AError));
end;

class function TRickSQLCoreConnectionValidator.ValidateClientLibraryPath(
  const AOptions: TRickSQLConnectionOptions;
  out AError: TRickSQLError): Boolean;
var
  LPath: string;
begin
  LPath := Trim(AOptions.ClientLibraryPath);
  if LPath = '' then
    Exit(True);
  Result := (Pos('*', LPath) = 0) and (Pos('?', LPath) = 0) and
    (Pos(#13, LPath) = 0) and (Pos(#10, LPath) = 0);
  if not Result then
    Exit(Fail(_ERROR_LIBRARY_PATH_INVALID_, AError));
end;

class function TRickSQLCoreConnectionValidator.HasDuplicateExtraParameter(
  const AOptions: TRickSQLConnectionOptions;
  const AIndex: Integer): Boolean;
var
  LPrevious: Integer;
  LName: string;
begin
  Result := False;
  LName := Trim(AOptions.ExtraParameters[AIndex].Name);
  for LPrevious := 0 to AIndex - 1 do
    if SameText(LName, Trim(AOptions.ExtraParameters[LPrevious].Name)) then
      Exit(True);
end;

class function TRickSQLCoreConnectionValidator.ExtraParameterError(
  const AOptions: TRickSQLConnectionOptions;
  const AIndex: Integer): string;
var
  LName: string;
begin
  Result := '';
  LName := Trim(AOptions.ExtraParameters[AIndex].Name);
  if LName = '' then
    Exit(_ERROR_EXTRA_NAME_EMPTY_);
  if (Pos('=', LName) > 0) or (Pos(#13, LName) > 0) or
    (Pos(#10, LName) > 0) then
    Exit(Format(_ERROR_EXTRA_NAME_INVALID_, [LName]));
  if Trim(AOptions.ExtraParameters[AIndex].Value) = '' then
    Exit(Format(_ERROR_EXTRA_VALUE_EMPTY_, [LName]));
  if SameText(LName, _PARAM_DRIVER_ID_) then
    Exit(_ERROR_EXTRA_RESERVED_);
  if HasDuplicateExtraParameter(AOptions, AIndex) then
    Result := Format(_ERROR_EXTRA_DUPLICATE_, [LName]);
end;

class function TRickSQLCoreConnectionValidator.ValidateExtraParameters(
  const AOptions: TRickSQLConnectionOptions;
  out AError: TRickSQLError): Boolean;
var
  LIndex: Integer;
  LMessage: string;
begin
  for LIndex := 0 to Length(AOptions.ExtraParameters) - 1 do
  begin
    LMessage := ExtraParameterError(AOptions, LIndex);
    if LMessage <> '' then
      Exit(Fail(LMessage, AError));
  end;
  Result := True;
end;

class function TRickSQLCoreConnectionValidator.ValidateGeneralOptions(
  const AOptions: TRickSQLConnectionOptions;
  out AError: TRickSQLError): Boolean;
begin
  if not ValidatePort(AOptions, AError) then
    Exit(False);
  if not ValidateTimeout(AOptions, AError) then
    Exit(False);
  if not ValidateClientLibraryPath(AOptions, AError) then
    Exit(False);
  Result := ValidateExtraParameters(AOptions, AError);
end;

class function TRickSQLCoreConnectionValidator.ValidateProvider(
  const AOptions: TRickSQLConnectionOptions;
  out AProvider: IRickSQLDriverProvider;
  out AError: TRickSQLError): Boolean;
var
  LProvider: IRickSQLDriverProvider;
  LMessage: string;
begin
  LProvider := TRickSQLCoreDriverFactory.Resolve(AOptions.Engine);
  if LProvider = nil then
    Exit(Fail(_ERROR_ENGINE_UNSUPPORTED_, AError));
  LMessage := '';
  Result := LProvider.ValidateOptions(AOptions, LMessage);
  if not Result then
    Exit(Fail(LMessage, AError));
  AProvider := LProvider;
end;

class function TRickSQLCoreConnectionValidator.Validate(
  const AOptions: TRickSQLConnectionOptions;
  out AError: TRickSQLError): Boolean;
var
  LProvider: IRickSQLDriverProvider;
begin
  Result := Validate(AOptions, LProvider, AError);
end;

class function TRickSQLCoreConnectionValidator.Validate(
  const AOptions: TRickSQLConnectionOptions;
  out AProvider: IRickSQLDriverProvider;
  out AError: TRickSQLError): Boolean;
begin
  AProvider := nil;
  AError := TRickSQLError.Empty;
  if not ValidateEngine(AOptions, AError) then
    Exit(False);
  if not HasConnectionData(AOptions) then
    Exit(Fail(_ERROR_CONNECTION_NOT_CONFIGURED_, AError));
  if not ValidateGeneralOptions(AOptions, AError) then
    Exit(False);
  Result := ValidateProvider(AOptions, AProvider, AError);
end;

end.
