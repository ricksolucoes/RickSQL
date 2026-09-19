unit Rick.SQL.Service.FireDAC.Driver.Context;

// Responsabilidade: manter vivo o driver link necessário durante uma sessão FireDAC.
// NAO resolve providers, executa comandos SQL, materializa datasets ou conhece interface visual.

interface

uses
  // RTL
  System.Classes,

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
  Rick.SQL.Error.Normalizer,
  Rick.SQL.Service.FireDAC.Driver.VendorLibrary;

const
  _OPERATION_ = 'Criação do contexto do driver FireDAC';
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

function VendorLibraryError(
  const AApplication: TRickSQLVendorLibraryApplyResult): TRickSQLError;
begin
  case AApplication.Status of
    TRickSQLVendorLibraryApplyStatus.DriverLinkRequired:
      Exit(TRickSQLServiceFireDACDriverContext.CreateDriverError(
        _ERROR_DRIVER_LINK_NOT_CREATED_, ''));
    TRickSQLVendorLibraryApplyStatus.PropertyUnavailable:
      Exit(TRickSQLServiceFireDACDriverContext.CreateDriverError(
        _ERROR_VENDOR_LIB_UNAVAILABLE_, ''));
  end;
  Result := AApplication.Error;
  Result.Kind := TRickSQLErrorKind.Driver;
  if AApplication.Status = TRickSQLVendorLibraryApplyStatus.InspectionFailed then
    Result.Message := _ERROR_UNEXPECTED_
  else
    Result.Message := _ERROR_VENDOR_LIB_CONFIGURE_;
  Result.Operation := _OPERATION_;
  Result.HasError := True;
end;

function TRickSQLServiceFireDACDriverContext.ConfigureVendorLibrary(
  const AVendorLibraryPath: string): Boolean;
var
  LApplication: TRickSQLVendorLibraryApplyResult;
begin
  LApplication := TRickSQLServiceFireDACDriverVendorLibrary.TryApply(
    FDriverLink, AVendorLibraryPath);
  Result := LApplication.Succeeded;
  if not Result then
    FError := VendorLibraryError(LApplication);
end;

procedure TRickSQLServiceFireDACDriverContext.MarkConfigured;
begin
  FConfigured := True;
end;

end.
