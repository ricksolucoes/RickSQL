unit Rick.SQL.Tests.Driver.Contracts;

interface

uses
  // DUnit
  TestFramework,

  // RickSQL
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Types;

type
  TRickSQLDriverContractTests = class(TTestCase)
  private
    procedure CheckResolvedProvider(const AEngine: TRickSQLDatabaseEngine);
    function CompleteInformixOptions: TRickSQLConnectionOptions;
  published
    procedure Factory_Unknown_ReturnsNil;
    procedure Factory_SupportedEngines_ResolveProviders;
    procedure Informix_Definition_ExposesExpectedContract;
{$IFDEF FULL_EDITION}
    procedure Informix_FullEdition_CompleteOptionsValidate;
    procedure Informix_FullEdition_CreateDriverLinkReturnsComponent;
{$ELSE}
    procedure Informix_Fallback_ValidateOptionsRejectsUse;
    procedure Informix_Fallback_CreateDriverLinkRaisesFullEditionRequired;
{$ENDIF}
  end;

implementation

uses
  // RTL
  System.Classes,
  System.SysUtils,

  // RickSQL
  Rick.SQL.Core.Driver.Factory,
  Rick.SQL.Model.Contracts,
  Rick.SQL.Model.Driver.Definition;

procedure TRickSQLDriverContractTests.CheckResolvedProvider(
  const AEngine: TRickSQLDatabaseEngine);
var
  LDefinition: TRickSQLDriverDefinition;
  LProvider: IRickSQLDriverProvider;
begin
  LProvider := TRickSQLCoreDriverFactory.Resolve(AEngine);
  Check(LProvider <> nil, 'Todo engine suportado deve resolver um provider.');
  Check(LProvider.Engine = AEngine,
    'O provider resolvido deve corresponder ao engine solicitado.');

  LDefinition := LProvider.Definition;
  Check(LDefinition.Engine = AEngine,
    'A Definition deve corresponder ao engine solicitado.');
  Check(Trim(LDefinition.DriverID) <> '',
    'Todo engine suportado deve expor DriverID não vazio.');
end;

function TRickSQLDriverContractTests.CompleteInformixOptions
  : TRickSQLConnectionOptions;
begin
  Result := TRickSQLConnectionOptions.Create(TRickSQLDatabaseEngine.Informix);
  Result.Server := 'localhost';
  Result.Database := 'database';
  Result.UserName := 'user';
  Result.Password := 'password';
end;

procedure TRickSQLDriverContractTests.Factory_Unknown_ReturnsNil;
var
  LProvider: IRickSQLDriverProvider;
begin
  LProvider := TRickSQLCoreDriverFactory.Resolve(TRickSQLDatabaseEngine.Unknown);
  Check(LProvider = nil,
    'Unknown representa ausência de engine operacional e não deve resolver provider.');
end;

procedure TRickSQLDriverContractTests.Factory_SupportedEngines_ResolveProviders;
begin
  CheckResolvedProvider(TRickSQLDatabaseEngine.Firebird);
  CheckResolvedProvider(TRickSQLDatabaseEngine.InterBase);
  CheckResolvedProvider(TRickSQLDatabaseEngine.PostgreSQL);
  CheckResolvedProvider(TRickSQLDatabaseEngine.SQLServer);
  CheckResolvedProvider(TRickSQLDatabaseEngine.MySQL);
  CheckResolvedProvider(TRickSQLDatabaseEngine.SQLite);
  CheckResolvedProvider(TRickSQLDatabaseEngine.Oracle);
  CheckResolvedProvider(TRickSQLDatabaseEngine.DB2);
  CheckResolvedProvider(TRickSQLDatabaseEngine.SQLAnywhere);
  CheckResolvedProvider(TRickSQLDatabaseEngine.Informix);
  CheckResolvedProvider(TRickSQLDatabaseEngine.Advantage);
  CheckResolvedProvider(TRickSQLDatabaseEngine.Access);
  CheckResolvedProvider(TRickSQLDatabaseEngine.ODBC);
end;

procedure TRickSQLDriverContractTests.Informix_Definition_ExposesExpectedContract;
var
  LDefinition: TRickSQLDriverDefinition;
  LProvider: IRickSQLDriverProvider;
begin
  LProvider := TRickSQLCoreDriverFactory.Resolve(TRickSQLDatabaseEngine.Informix);
  Check(LProvider <> nil, 'A factory deve registrar o provider Informix.');

  LDefinition := LProvider.Definition;
  Check(LDefinition.Engine = TRickSQLDatabaseEngine.Informix,
    'A Definition do Informix deve expor o engine Informix.');
  CheckEquals('Infx', LDefinition.DriverID,
    'A Definition do Informix deve expor o DriverID Infx.');
  CheckEquals(9088, LDefinition.DefaultPort,
    'A Definition do Informix deve expor DefaultPort 9088.');
end;

{$IFDEF FULL_EDITION}
procedure TRickSQLDriverContractTests.Informix_FullEdition_CompleteOptionsValidate;
var
  LError: string;
  LProvider: IRickSQLDriverProvider;
begin
  LProvider := TRickSQLCoreDriverFactory.Resolve(TRickSQLDatabaseEngine.Informix);
  Check(LProvider.ValidateOptions(CompleteInformixOptions, LError), LError);
end;

procedure TRickSQLDriverContractTests.
  Informix_FullEdition_CreateDriverLinkReturnsComponent;
var
  LDriverLink: TComponent;
  LOwner: TComponent;
  LProvider: IRickSQLDriverProvider;
begin
  LOwner := TComponent.Create(nil);
  try
    LProvider := TRickSQLCoreDriverFactory.Resolve(TRickSQLDatabaseEngine.Informix);
    LDriverLink := LProvider.CreateDriverLink(LOwner);
    Check(LDriverLink <> nil,
      'Com FULL_EDITION, Informix deve criar o DriverLink para owner válido.');
    Check(LDriverLink.Owner = LOwner,
      'O DriverLink Informix deve pertencer ao owner informado.');
  finally
    LOwner.Free;
  end;
end;
{$ELSE}
procedure TRickSQLDriverContractTests.Informix_Fallback_ValidateOptionsRejectsUse;
var
  LError: string;
  LProvider: IRickSQLDriverProvider;
begin
  LProvider := TRickSQLCoreDriverFactory.Resolve(TRickSQLDatabaseEngine.Informix);
  Check(not LProvider.ValidateOptions(CompleteInformixOptions, LError),
    'Sem FULL_EDITION, Informix deve rejeitar validação funcional.');
  Check(Pos('FULL_EDITION', LError) > 0,
    'A rejeição do Informix fallback deve informar FULL_EDITION.');
end;

procedure TRickSQLDriverContractTests.
  Informix_Fallback_CreateDriverLinkRaisesFullEditionRequired;
var
  LOwner: TComponent;
  LProvider: IRickSQLDriverProvider;
  LRaised: Boolean;
begin
  LOwner := TComponent.Create(nil);
  try
    LProvider := TRickSQLCoreDriverFactory.Resolve(TRickSQLDatabaseEngine.Informix);
    LRaised := False;
    try
      LProvider.CreateDriverLink(LOwner);
    except
      on E: Exception do
      begin
        LRaised := True;
        Check(Pos('FULL_EDITION', E.Message) > 0,
          'A exception do Informix fallback deve informar FULL_EDITION.');
      end;
    end;
    Check(LRaised,
      'Sem FULL_EDITION, CreateDriverLink do Informix deve falhar explicitamente.');
  finally
    LOwner.Free;
  end;
end;
{$ENDIF}

initialization
  RegisterTest(TRickSQLDriverContractTests.Suite);

end.
