unit Rick.SQL.Service.FireDAC.Driver.Context;

// Responsabilidade: manter vivo o driver link necessário durante uma sessão FireDAC.
// NAO resolve providers, executa comandos SQL, materializa datasets ou conhece interface visual.

interface

uses
  // RTL
  System.Classes,
  System.TypInfo,

  // RickSQL
  Rick.SQL.Model.Contracts,
  Rick.SQL.Model.Error;

type
  TRickSQLServiceFireDACDriverContext = class(TComponent)
  private
    FProvider: IRickSQLDriverProvider;
    FDriverLink: TComponent;
    FError: TRickSQLError;
    FConfigured: Boolean;
    class function CreateDriverError(const AMessage: string;
      const ADetail: string): TRickSQLError; static;
    function ValidateProvider(const AProvider: IRickSQLDriverProvider): Boolean;
    function CreateDriverLink: Boolean;
    function ConfigureVendorLibrary(const AVendorLibraryPath: string): Boolean;
    function VendorProperty: PPropInfo;
    function CanConfigureVendorLibrary(
      const AVendorLibraryPath: string; out AProperty: PPropInfo): Boolean;
    function ApplyVendorLibrary(const AVendorLibraryPath: string;
      const AProperty: PPropInfo): Boolean;
    procedure MarkConfigured;
  public
    constructor Create(const AProvider: IRickSQLDriverProvider;
      const AVendorLibraryPath: string); reintroduce;
    destructor Destroy; override;
    property Provider: IRickSQLDriverProvider read FProvider;
    property DriverLink: TComponent read FDriverLink;
    property Error: TRickSQLError read FError;
    property Configured: Boolean read FConfigured;
  end;

implementation

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Error.Normalizer;

const
  _OPERATION_ = 'Criação do contexto do driver FireDAC';
  _PROPERTY_VENDOR_LIB_ = 'VendorLib';
  _ERROR_PROVIDER_NOT_FOUND_ =
    'Não foi possível resolver o driver do banco de dados informado. ' +
    'Informe um mecanismo de banco válido antes de criar a sessão.';
  _ERROR_DRIVER_LINK_NOT_CREATED_ =
    'Não foi possível criar o driver link necessário para o banco de dados informado. ' +
    'Verifique se o driver FireDAC correspondente está disponível.';
  _ERROR_VENDOR_LIB_UNAVAILABLE_ =
    'O driver selecionado não permite configurar a biblioteca cliente automaticamente. ' +
    'Configure a biblioteca cliente pelo mecanismo padrão do fornecedor.';
  _ERROR_VENDOR_LIB_CONFIGURE_ =
    'Não foi possível configurar a biblioteca cliente no driver selecionado. ' +
    'Verifique se o caminho informado é compatível com a aplicação.';
  _ERROR_UNEXPECTED_ =
    'Não foi possível preparar o contexto do driver FireDAC. ' +
    'Verifique o driver selecionado e a biblioteca cliente informada.';

constructor TRickSQLServiceFireDACDriverContext.Create(
  const AProvider: IRickSQLDriverProvider;
  const AVendorLibraryPath: string);
begin
  inherited Create(nil);
  FError := TRickSQLError.Empty;
  FConfigured := False;
  try
    if not ValidateProvider(AProvider) then
      Exit;
    if not CreateDriverLink then
      Exit;
    if not ConfigureVendorLibrary(AVendorLibraryPath) then
      Exit;
    MarkConfigured;
  except
    on E: Exception do
      FError := TRickSQLErrorNormalizer.FromException(E,
        TRickSQLErrorKind.Driver, _ERROR_UNEXPECTED_, _OPERATION_);
  end;
end;

destructor TRickSQLServiceFireDACDriverContext.Destroy;
begin
  FreeAndNil(FDriverLink);
  FProvider := nil;
  FError := TRickSQLError.Empty;
  FConfigured := False;
  inherited Destroy;
end;

class function TRickSQLServiceFireDACDriverContext.CreateDriverError(
  const AMessage: string; const ADetail: string): TRickSQLError;
begin
  Result := TRickSQLErrorNormalizer.FromDetail(TRickSQLErrorKind.Driver,
    AMessage, ADetail, _OPERATION_);
end;

function TRickSQLServiceFireDACDriverContext.ValidateProvider(
  const AProvider: IRickSQLDriverProvider): Boolean;
begin
  FProvider := AProvider;
  Result := FProvider <> nil;
  if not Result then
    FError := CreateDriverError(_ERROR_PROVIDER_NOT_FOUND_, '');
end;

function TRickSQLServiceFireDACDriverContext.CreateDriverLink: Boolean;
begin
  FDriverLink := FProvider.CreateDriverLink(Self);
  Result := Assigned(FDriverLink);
  if not Result then
    FError := CreateDriverError(_ERROR_DRIVER_LINK_NOT_CREATED_, '');
end;

function TRickSQLServiceFireDACDriverContext.VendorProperty: PPropInfo;
begin
  Result := nil;
  if Assigned(FDriverLink) then
    Result := GetPropInfo(FDriverLink.ClassInfo, _PROPERTY_VENDOR_LIB_);
end;

function TRickSQLServiceFireDACDriverContext.ConfigureVendorLibrary(
  const AVendorLibraryPath: string): Boolean;
var
  LProperty: PPropInfo;
begin
  if not CanConfigureVendorLibrary(AVendorLibraryPath, LProperty) then
    Exit(False);
  if not Assigned(LProperty) then
    Exit(True);
  Result := ApplyVendorLibrary(AVendorLibraryPath, LProperty);
end;

function TRickSQLServiceFireDACDriverContext.CanConfigureVendorLibrary(
  const AVendorLibraryPath: string; out AProperty: PPropInfo): Boolean;
begin
  AProperty := nil;
  Result := True;
  if Trim(AVendorLibraryPath) = '' then
    Exit;
  AProperty := VendorProperty;
  if Assigned(AProperty) then
    Exit;
  FError := CreateDriverError(_ERROR_VENDOR_LIB_UNAVAILABLE_, '');
  Result := False;
end;

function TRickSQLServiceFireDACDriverContext.ApplyVendorLibrary(
  const AVendorLibraryPath: string; const AProperty: PPropInfo): Boolean;
begin
  try
    SetStrProp(FDriverLink, AProperty, AVendorLibraryPath);
    Result := True;
  except
    on E: Exception do
    begin
      FError := TRickSQLErrorNormalizer.FromException(E,
        TRickSQLErrorKind.Driver, _ERROR_VENDOR_LIB_CONFIGURE_, _OPERATION_);
      Result := False;
    end;
  end;
end;

procedure TRickSQLServiceFireDACDriverContext.MarkConfigured;
begin
  FConfigured := True;
end;

end.
