unit Rick.SQL.Tests.ClientLibrary.VendorLibrary;

interface

uses
  // DUnit
  TestFramework;

type
  TRickSQLVendorLibraryTests = class(TTestCase)
  published
    procedure Canonical_CompatibleDriverLink_AssignsVendorLib;
    procedure Canonical_EmptyPath_PreservesExistingVendorLib;
    procedure Canonical_MissingVendorLib_ReportsUnavailable;
    procedure Canonical_SetterFailure_ReportsFailure;
    procedure Configure_ExplicitPath_AssignsResolvedVendorLib;
    procedure Configure_NotRequired_DoesNotRequireVendorLib;
    procedure Configure_SetterFailure_PreservesClientLibraryError;
    procedure DriverContext_ResolvedPath_AssignsVendorLib;
    procedure DriverContextFactory_ExplicitPath_AssignsVendorLib;
    procedure DriverContext_EmptyPath_PreservesExistingVendorLib;
    procedure DriverContext_SetterFailure_PreservesDriverError;
    procedure Configure_MissingVendorLib_PreservesClientLibraryError;
    procedure DriverContext_MissingVendorLib_PreservesDriverError;
    procedure ConfigureAndContext_SamePath_ProduceSameVendorLib;
    procedure ProviderDefault_InterBase_PreservesVendorLib;
  end;

implementation

uses
  // RTL
  System.Classes,
  System.IOUtils,
  System.SysUtils,

  // FireDAC
  FireDAC.Phys.FB,
  FireDAC.Phys.IB,

  // RickSQL
  Rick.SQL.Core.ClientLibrary.Resolver,
  Rick.SQL.Core.Driver.Context.Factory,
  Rick.SQL.Core.Driver.Factory,
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Contracts,
  Rick.SQL.Model.Driver.Definition,
  Rick.SQL.Model.Error,
  Rick.SQL.Model.Types,
  Rick.SQL.Service.FireDAC.Driver.Context,
  Rick.SQL.Service.FireDAC.Driver.VendorLibrary;

type
  TRickSQLTestDriverLink = class(TComponent)
  private
    FVendorLib: string;
  published
    property VendorLib: string read FVendorLib write FVendorLib;
  end;

  TRickSQLTestDriverLinkMode = (
    WithVendorLib,
    WithoutVendorLib,
    FailingVendorLib
  );

  TRickSQLFailingDriverLink = class(TComponent)
  private
    FVendorLib: string;
    procedure SetVendorLib(const AValue: string);
  published
    property VendorLib: string read FVendorLib write SetVendorLib;
  end;

  TRickSQLTestDriverProvider = class(TInterfacedObject, IRickSQLDriverProvider)
  private
    FMode: TRickSQLTestDriverLinkMode;
    FInitialVendorLib: string;
  public
    constructor Create(const AMode: TRickSQLTestDriverLinkMode;
      const AInitialVendorLib: string = '');
    function Engine: TRickSQLDatabaseEngine;
    function Definition: TRickSQLDriverDefinition;
    function CreateDriverLink(const AOwner: TComponent): TComponent;
    procedure ApplyConnectionOptions(const AOptions: TRickSQLConnectionOptions;
      const AParameters: TStrings);
    function ValidateOptions(const AOptions: TRickSQLConnectionOptions;
      out AError: string): Boolean;
  end;

constructor TRickSQLTestDriverProvider.Create(
  const AMode: TRickSQLTestDriverLinkMode; const AInitialVendorLib: string);
begin
  inherited Create;
  FMode := AMode;
  FInitialVendorLib := AInitialVendorLib;
end;

function TRickSQLTestDriverProvider.Engine: TRickSQLDatabaseEngine;
begin
  Result := TRickSQLDatabaseEngine.SQLite;
end;

function TRickSQLTestDriverProvider.Definition: TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(TRickSQLDatabaseEngine.SQLite,
    'VendorLibTest');
end;

function TRickSQLTestDriverProvider.CreateDriverLink(
  const AOwner: TComponent): TComponent;
var
  LDriverLink: TRickSQLTestDriverLink;
begin
  if FMode = TRickSQLTestDriverLinkMode.WithoutVendorLib then
    Exit(TComponent.Create(AOwner));
  if FMode = TRickSQLTestDriverLinkMode.FailingVendorLib then
    Exit(TRickSQLFailingDriverLink.Create(AOwner));

  LDriverLink := TRickSQLTestDriverLink.Create(AOwner);
  LDriverLink.VendorLib := FInitialVendorLib;
  Result := LDriverLink;
end;

procedure TRickSQLTestDriverProvider.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions; const AParameters: TStrings);
begin
end;

function TRickSQLTestDriverProvider.ValidateOptions(
  const AOptions: TRickSQLConnectionOptions; out AError: string): Boolean;
begin
  AError := '';
  Result := True;
end;

function FirebirdOptions(const APath: string): TRickSQLConnectionOptions;
begin
  Result := TRickSQLConnectionOptions.Create(TRickSQLDatabaseEngine.Firebird);
  Result.ClientLibraryPath := APath;
end;

procedure TRickSQLFailingDriverLink.SetVendorLib(const AValue: string);
begin
  raise Exception.Create('falha-controlada-vendorlib');
end;

procedure TRickSQLVendorLibraryTests.Canonical_CompatibleDriverLink_AssignsVendorLib;
const
  _PATH_ = 'C:\RickSQL\canonical-client.dll';
var
  LLink: TRickSQLTestDriverLink;
  LApplication: TRickSQLVendorLibraryApplyResult;
begin
  LLink := TRickSQLTestDriverLink.Create(nil);
  try
    LApplication := TRickSQLServiceFireDACDriverVendorLibrary.TryApply(
      LLink, _PATH_);
    Check(LApplication.Status = TRickSQLVendorLibraryApplyStatus.Applied,
      'A implementação canônica deveria aplicar VendorLib.');
    CheckEquals(_PATH_, LLink.VendorLib);
  finally
    LLink.Free;
  end;
end;

procedure TRickSQLVendorLibraryTests.Canonical_EmptyPath_PreservesExistingVendorLib;
const
  _EXISTING_ = 'provider-default.dll';
var
  LLink: TRickSQLTestDriverLink;
  LApplication: TRickSQLVendorLibraryApplyResult;
begin
  LLink := TRickSQLTestDriverLink.Create(nil);
  try
    LLink.VendorLib := _EXISTING_;
    LApplication := TRickSQLServiceFireDACDriverVendorLibrary.TryApply(LLink, '');
    Check(LApplication.Status = TRickSQLVendorLibraryApplyStatus.Skipped,
      'Path vazio deveria ser ignorado pela implementação canônica.');
    CheckEquals(_EXISTING_, LLink.VendorLib);
  finally
    LLink.Free;
  end;
end;

procedure TRickSQLVendorLibraryTests.Canonical_MissingVendorLib_ReportsUnavailable;
var
  LLink: TComponent;
  LApplication: TRickSQLVendorLibraryApplyResult;
begin
  LLink := TComponent.Create(nil);
  try
    LApplication := TRickSQLServiceFireDACDriverVendorLibrary.TryApply(
      LLink, 'client.dll');
    Check(LApplication.Status = TRickSQLVendorLibraryApplyStatus.PropertyUnavailable,
      'DriverLink sem VendorLib deveria ser distinguido de falha de atribuição.');
  finally
    LLink.Free;
  end;
end;

procedure TRickSQLVendorLibraryTests.Canonical_SetterFailure_ReportsFailure;
var
  LLink: TRickSQLFailingDriverLink;
  LApplication: TRickSQLVendorLibraryApplyResult;
begin
  LLink := TRickSQLFailingDriverLink.Create(nil);
  try
    LApplication := TRickSQLServiceFireDACDriverVendorLibrary.TryApply(
      LLink, 'client.dll');
    Check(LApplication.Status = TRickSQLVendorLibraryApplyStatus.Failed,
      'Exception no setter deveria produzir falha estruturada.');
    Check(Pos('falha-controlada-vendorlib', LApplication.Error.TechnicalDetail) > 0,
      'O detalhe técnico da falha deveria ser preservado.');
  finally
    LLink.Free;
  end;
end;

procedure TRickSQLVendorLibraryTests.Configure_ExplicitPath_AssignsResolvedVendorLib;
var
  LPath: string;
  LLink: TRickSQLTestDriverLink;
  LError: TRickSQLError;
begin
  LPath := TPath.GetTempFileName;
  LLink := TRickSQLTestDriverLink.Create(nil);
  try
    Check(TRickSQLCoreClientLibraryResolver.Configure(
      TRickSQLClientLibraryConfiguration.Create(FirebirdOptions(LPath), LLink),
      LError), LError.Message);
    CheckEquals(ExpandFileName(LPath), LLink.VendorLib,
      'Configure deve aplicar exatamente o caminho resolvido em VendorLib.');
  finally
    LLink.Free;
    TFile.Delete(LPath);
  end;
end;


procedure TRickSQLVendorLibraryTests.Configure_NotRequired_DoesNotRequireVendorLib;
var
  LOptions: TRickSQLConnectionOptions;
  LLink: TComponent;
  LError: TRickSQLError;
begin
  LOptions := TRickSQLConnectionOptions.Create(TRickSQLDatabaseEngine.SQLite);
  LLink := TComponent.Create(nil);
  try
    Check(TRickSQLCoreClientLibraryResolver.Configure(
      TRickSQLClientLibraryConfiguration.Create(LOptions, LLink), LError),
      LError.Message);
    Check(not LError.HasError,
      'Driver sem client library obrigatória não deveria exigir VendorLib.');
  finally
    LLink.Free;
  end;
end;

procedure TRickSQLVendorLibraryTests.Configure_SetterFailure_PreservesClientLibraryError;
var
  LPath: string;
  LLink: TRickSQLFailingDriverLink;
  LError: TRickSQLError;
begin
  LPath := TPath.GetTempFileName;
  LLink := TRickSQLFailingDriverLink.Create(nil);
  try
    Check(not TRickSQLCoreClientLibraryResolver.Configure(
      TRickSQLClientLibraryConfiguration.Create(FirebirdOptions(LPath), LLink),
      LError), 'Configure deveria falhar quando o setter de VendorLib falha.');
    Check(LError.Kind = TRickSQLErrorKind.ClientLibrary,
      'Configure deve preservar a classificação ClientLibrary.');
    Check(Pos('falha-controlada-vendorlib', LError.TechnicalDetail) > 0,
      'Configure deve preservar o detalhe técnico da falha de atribuição.');
  finally
    LLink.Free;
    TFile.Delete(LPath);
  end;
end;

procedure TRickSQLVendorLibraryTests.DriverContext_ResolvedPath_AssignsVendorLib;
const
  _PATH_ = 'C:\RickSQL\client-test.dll';
var
  LProvider: IRickSQLDriverProvider;
  LContext: TRickSQLServiceFireDACDriverContext;
begin
  LProvider := TRickSQLTestDriverProvider.Create(
    TRickSQLTestDriverLinkMode.WithVendorLib);
  LContext := TRickSQLServiceFireDACDriverContext.Create(LProvider, _PATH_);
  try
    Check(LContext.Configured, LContext.Error.Message);
    CheckEquals(_PATH_, TRickSQLTestDriverLink(LContext.DriverLink).VendorLib,
      'Driver.Context deve aplicar o path recebido em VendorLib.');
  finally
    LContext.Free;
  end;
end;


procedure TRickSQLVendorLibraryTests.DriverContextFactory_ExplicitPath_AssignsVendorLib;
var
  LPath: string;
  LOptions: TRickSQLConnectionOptions;
  LContext: TRickSQLServiceFireDACDriverContext;
  LError: TRickSQLError;
begin
  LPath := TPath.GetTempFileName;
  try
    LOptions := FirebirdOptions(LPath);
    LContext := TRickSQLCoreDriverContextFactory.Create(
      LOptions, 'Teste de VendorLib', LError);
    try
      Check(Assigned(LContext), LError.Message);
      Check(LContext.Configured, LContext.Error.Message);
      Check(LContext.DriverLink is TFDPhysFBDriverLink,
        'O fluxo principal deveria criar o DriverLink do Firebird.');
      CheckEquals(ExpandFileName(LPath),
        TFDPhysFBDriverLink(LContext.DriverLink).VendorLib,
        'O fluxo principal deve aplicar o caminho resolvido em VendorLib.');
    finally
      LContext.Free;
    end;
  finally
    TFile.Delete(LPath);
  end;
end;

procedure TRickSQLVendorLibraryTests.DriverContext_EmptyPath_PreservesExistingVendorLib;
const
  _EXISTING_ = 'provider-default.dll';
var
  LProvider: IRickSQLDriverProvider;
  LContext: TRickSQLServiceFireDACDriverContext;
begin
  LProvider := TRickSQLTestDriverProvider.Create(
    TRickSQLTestDriverLinkMode.WithVendorLib, _EXISTING_);
  LContext := TRickSQLServiceFireDACDriverContext.Create(LProvider, '');
  try
    Check(LContext.Configured, LContext.Error.Message);
    CheckEquals(_EXISTING_,
      TRickSQLTestDriverLink(LContext.DriverLink).VendorLib,
      'Path vazio não deve sobrescrever VendorLib já configurado pelo provider.');
  finally
    LContext.Free;
  end;
end;


procedure TRickSQLVendorLibraryTests.DriverContext_SetterFailure_PreservesDriverError;
var
  LProvider: IRickSQLDriverProvider;
  LContext: TRickSQLServiceFireDACDriverContext;
begin
  LProvider := TRickSQLTestDriverProvider.Create(
    TRickSQLTestDriverLinkMode.FailingVendorLib);
  LContext := TRickSQLServiceFireDACDriverContext.Create(
    LProvider, 'client.dll');
  try
    Check(not LContext.Configured,
      'Driver.Context deveria falhar quando o setter de VendorLib falha.');
    Check(LContext.Error.Kind = TRickSQLErrorKind.Driver,
      'Driver.Context deve preservar a classificação Driver.');
    Check(Pos('falha-controlada-vendorlib', LContext.Error.TechnicalDetail) > 0,
      'Driver.Context deve preservar o detalhe técnico da falha.');
  finally
    LContext.Free;
  end;
end;

procedure TRickSQLVendorLibraryTests.Configure_MissingVendorLib_PreservesClientLibraryError;
var
  LPath: string;
  LLink: TComponent;
  LError: TRickSQLError;
begin
  LPath := TPath.GetTempFileName;
  LLink := TComponent.Create(nil);
  try
    Check(not TRickSQLCoreClientLibraryResolver.Configure(
      TRickSQLClientLibraryConfiguration.Create(FirebirdOptions(LPath), LLink),
      LError), 'Configure deveria falhar quando VendorLib não existe.');
    Check(LError.Kind = TRickSQLErrorKind.ClientLibrary,
      'Configure deve preservar a classificação ClientLibrary.');
  finally
    LLink.Free;
    TFile.Delete(LPath);
  end;
end;

procedure TRickSQLVendorLibraryTests.DriverContext_MissingVendorLib_PreservesDriverError;
const
  _PATH_ = 'C:\RickSQL\client-test.dll';
var
  LProvider: IRickSQLDriverProvider;
  LContext: TRickSQLServiceFireDACDriverContext;
begin
  LProvider := TRickSQLTestDriverProvider.Create(
    TRickSQLTestDriverLinkMode.WithoutVendorLib);
  LContext := TRickSQLServiceFireDACDriverContext.Create(LProvider, _PATH_);
  try
    Check(not LContext.Configured,
      'Driver.Context deveria falhar quando VendorLib não existe.');
    Check(LContext.Error.Kind = TRickSQLErrorKind.Driver,
      'Driver.Context deve preservar a classificação Driver.');
  finally
    LContext.Free;
  end;
end;

procedure TRickSQLVendorLibraryTests.ConfigureAndContext_SamePath_ProduceSameVendorLib;
var
  LPath: string;
  LLink: TRickSQLTestDriverLink;
  LProvider: IRickSQLDriverProvider;
  LContext: TRickSQLServiceFireDACDriverContext;
  LError: TRickSQLError;
  LConfiguredPath: string;
begin
  LPath := TPath.GetTempFileName;
  LLink := TRickSQLTestDriverLink.Create(nil);
  try
    Check(TRickSQLCoreClientLibraryResolver.Configure(
      TRickSQLClientLibraryConfiguration.Create(FirebirdOptions(LPath), LLink),
      LError), LError.Message);
    LConfiguredPath := LLink.VendorLib;
  finally
    LLink.Free;
  end;

  LProvider := TRickSQLTestDriverProvider.Create(
    TRickSQLTestDriverLinkMode.WithVendorLib);
  LContext := TRickSQLServiceFireDACDriverContext.Create(
    LProvider, ExpandFileName(LPath));
  try
    Check(LContext.Configured, LContext.Error.Message);
    CheckEquals(LConfiguredPath,
      TRickSQLTestDriverLink(LContext.DriverLink).VendorLib,
      'Os dois caminhos devem produzir o mesmo VendorLib observável.');
  finally
    LContext.Free;
    TFile.Delete(LPath);
  end;
end;


procedure TRickSQLVendorLibraryTests.ProviderDefault_InterBase_PreservesVendorLib;
const
  _DEFAULT_LIBRARY_ = 'gds32.dll';
var
  LOwner: TComponent;
  LProvider: IRickSQLDriverProvider;
  LDriverLink: TComponent;
begin
  LOwner := TComponent.Create(nil);
  try
    LProvider := TRickSQLCoreDriverFactory.Resolve(TRickSQLDatabaseEngine.InterBase);
    Check(Assigned(LProvider), 'O provider InterBase deveria estar disponível.');
    LDriverLink := LProvider.CreateDriverLink(LOwner);
    Check(LDriverLink is TFDPhysIBDriverLink,
      'O provider InterBase deveria criar TFDPhysIBDriverLink.');
    CheckEquals(_DEFAULT_LIBRARY_, TFDPhysIBDriverLink(LDriverLink).VendorLib,
      'O default VendorLib do provider InterBase deve ser preservado.');
  finally
    LOwner.Free;
  end;
end;

initialization
  RegisterTest(TRickSQLVendorLibraryTests.Suite);

end.
