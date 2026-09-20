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
    procedure CheckDefinition(const AEngine: TRickSQLDatabaseEngine;
      const ADriverID: string; const ADefaultPort: Integer);
    procedure CheckOperationalProvider(const AEngine: TRickSQLDatabaseEngine;
      const ADriverID: string);
    procedure CheckDriverLinkCreation(const AEngine: TRickSQLDatabaseEngine);
    function CompleteInformixOptions: TRickSQLConnectionOptions;
{$IFNDEF FULL_EDITION}
    procedure CheckFallbackRejects(const AEngine: TRickSQLDatabaseEngine);
{$ENDIF}
  published
    procedure Factory_Unknown_ReturnsNil;
    procedure Factory_SupportedEngines_ResolveProviders;
    procedure Definitions_AllEngines_ExposeExpectedContract;
    procedure Providers_OperationalBranch_AppliesExpectedDriverID;
    procedure OperationalDrivers_CreateDriverLinkOwnedByCaller;
    procedure Informix_Definition_ExposesExpectedContract;
{$IFDEF FULL_EDITION}
    procedure ODBC_FullEdition_DataSource_AppliesExpectedParameter;
    procedure Informix_FullEdition_CompleteOptionsValidate;
    procedure Informix_FullEdition_CreateDriverLinkReturnsComponent;
{$ELSE}
    procedure Informix_Fallback_ValidateOptionsRejectsUse;
    procedure FallbackDrivers_WithoutFullEdition_RejectFunctionalUse;
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

procedure TRickSQLDriverContractTests.CheckDefinition(
  const AEngine: TRickSQLDatabaseEngine; const ADriverID: string;
  const ADefaultPort: Integer);
var
  LDefinition: TRickSQLDriverDefinition;
  LProvider: IRickSQLDriverProvider;
begin
  LProvider := TRickSQLCoreDriverFactory.Resolve(AEngine);
  Check(LProvider <> nil);
  LDefinition := LProvider.Definition;
  CheckEquals(ADriverID, LDefinition.DriverID);
  CheckEquals(ADefaultPort, LDefinition.DefaultPort);
end;

procedure TRickSQLDriverContractTests.CheckOperationalProvider(
  const AEngine: TRickSQLDatabaseEngine; const ADriverID: string);
var
  LError: string;
  LOptions: TRickSQLConnectionOptions;
  LParameters: TStringList;
  LProvider: IRickSQLDriverProvider;
begin
  LOptions := TRickSQLConnectionOptions.Create(AEngine);
  LOptions.Server := 'localhost';
  LOptions.Database := 'database';
  LOptions.UserName := 'user';
  LOptions.Password := 'password';
  LParameters := TStringList.Create;
  try
    LProvider := TRickSQLCoreDriverFactory.Resolve(AEngine);
    Check(LProvider.ValidateOptions(LOptions, LError), LError);
    LProvider.ApplyConnectionOptions(LOptions, LParameters);
    CheckEquals(ADriverID, LParameters.Values['DriverID']);
  finally
    LParameters.Free;
  end;
end;

procedure TRickSQLDriverContractTests.CheckDriverLinkCreation(
  const AEngine: TRickSQLDatabaseEngine);
var
  LDriverLink: TComponent;
  LOwner: TComponent;
  LProvider: IRickSQLDriverProvider;
begin
  LOwner := TComponent.Create(nil);
  try
    LProvider := TRickSQLCoreDriverFactory.Resolve(AEngine);
    LDriverLink := LProvider.CreateDriverLink(LOwner);
    Check(Assigned(LDriverLink));
    Check(LDriverLink.Owner = LOwner);
  finally
    LOwner.Free;
  end;
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

{$IFNDEF FULL_EDITION}
procedure TRickSQLDriverContractTests.CheckFallbackRejects(
  const AEngine: TRickSQLDatabaseEngine);
var
  LError: string;
  LOptions: TRickSQLConnectionOptions;
  LProvider: IRickSQLDriverProvider;
begin
  LOptions := TRickSQLConnectionOptions.Create(AEngine);
  LProvider := TRickSQLCoreDriverFactory.Resolve(AEngine);
  Check(Assigned(LProvider));
  Check(not LProvider.ValidateOptions(LOptions, LError));
  Check(Pos('FULL_EDITION', LError) > 0);
end;
{$ENDIF}

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

procedure TRickSQLDriverContractTests.Definitions_AllEngines_ExposeExpectedContract;
begin
  CheckDefinition(TRickSQLDatabaseEngine.Firebird, 'FB', 3050);
  CheckDefinition(TRickSQLDatabaseEngine.InterBase, 'IB', 3050);
  CheckDefinition(TRickSQLDatabaseEngine.PostgreSQL, 'PG', 5432);
  CheckDefinition(TRickSQLDatabaseEngine.SQLServer, 'MSSQL', 1433);
  CheckDefinition(TRickSQLDatabaseEngine.MySQL, 'MySQL', 3306);
  CheckDefinition(TRickSQLDatabaseEngine.SQLite, 'SQLite', 0);
  CheckDefinition(TRickSQLDatabaseEngine.Oracle, 'Ora', 1521);
  CheckDefinition(TRickSQLDatabaseEngine.DB2, 'DB2', 50000);
  CheckDefinition(TRickSQLDatabaseEngine.SQLAnywhere, 'ASA', 2638);
  CheckDefinition(TRickSQLDatabaseEngine.Informix, 'Infx', 9088);
  CheckDefinition(TRickSQLDatabaseEngine.Advantage, 'ADS', 6262);
  CheckDefinition(TRickSQLDatabaseEngine.Access, 'MSAcc', 0);
  CheckDefinition(TRickSQLDatabaseEngine.ODBC, 'ODBC', 0);
end;

procedure TRickSQLDriverContractTests.Providers_OperationalBranch_AppliesExpectedDriverID;
begin
  CheckOperationalProvider(TRickSQLDatabaseEngine.Firebird, 'FB');
  CheckOperationalProvider(TRickSQLDatabaseEngine.InterBase, 'IB');
  CheckOperationalProvider(TRickSQLDatabaseEngine.PostgreSQL, 'PG');
  CheckOperationalProvider(TRickSQLDatabaseEngine.MySQL, 'MySQL');
  CheckOperationalProvider(TRickSQLDatabaseEngine.SQLite, 'SQLite');
  CheckOperationalProvider(TRickSQLDatabaseEngine.Advantage, 'ADS');
  CheckOperationalProvider(TRickSQLDatabaseEngine.Access, 'MSAcc');
{$IFDEF FULL_EDITION}
  CheckOperationalProvider(TRickSQLDatabaseEngine.SQLServer, 'MSSQL');
  CheckOperationalProvider(TRickSQLDatabaseEngine.Oracle, 'Ora');
  CheckOperationalProvider(TRickSQLDatabaseEngine.DB2, 'DB2');
  CheckOperationalProvider(TRickSQLDatabaseEngine.SQLAnywhere, 'ASA');
  CheckOperationalProvider(TRickSQLDatabaseEngine.Informix, 'Infx');
  CheckOperationalProvider(TRickSQLDatabaseEngine.ODBC, 'ODBC');
{$ENDIF}
end;

procedure TRickSQLDriverContractTests.OperationalDrivers_CreateDriverLinkOwnedByCaller;
begin
  CheckDriverLinkCreation(TRickSQLDatabaseEngine.Firebird);
  CheckDriverLinkCreation(TRickSQLDatabaseEngine.InterBase);
  CheckDriverLinkCreation(TRickSQLDatabaseEngine.PostgreSQL);
  CheckDriverLinkCreation(TRickSQLDatabaseEngine.MySQL);
  CheckDriverLinkCreation(TRickSQLDatabaseEngine.SQLite);
  CheckDriverLinkCreation(TRickSQLDatabaseEngine.Advantage);
  CheckDriverLinkCreation(TRickSQLDatabaseEngine.Access);
{$IFDEF FULL_EDITION}
  CheckDriverLinkCreation(TRickSQLDatabaseEngine.SQLServer);
  CheckDriverLinkCreation(TRickSQLDatabaseEngine.Oracle);
  CheckDriverLinkCreation(TRickSQLDatabaseEngine.DB2);
  CheckDriverLinkCreation(TRickSQLDatabaseEngine.SQLAnywhere);
  CheckDriverLinkCreation(TRickSQLDatabaseEngine.Informix);
  CheckDriverLinkCreation(TRickSQLDatabaseEngine.ODBC);
{$ENDIF}
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
procedure TRickSQLDriverContractTests.ODBC_FullEdition_DataSource_AppliesExpectedParameter;
var
  LError: string;
  LOptions: TRickSQLConnectionOptions;
  LParameters: TStringList;
  LProvider: IRickSQLDriverProvider;
begin
  LOptions := TRickSQLConnectionOptions.Create(TRickSQLDatabaseEngine.ODBC);
  LOptions.Database := 'RickSQLTestDSN';
  LParameters := TStringList.Create;
  try
    LProvider := TRickSQLCoreDriverFactory.Resolve(TRickSQLDatabaseEngine.ODBC);
    Check(LProvider.ValidateOptions(LOptions, LError), LError);
    LProvider.ApplyConnectionOptions(LOptions, LParameters);
    CheckEquals('RickSQLTestDSN', LParameters.Values['DataSource']);
  finally
    LParameters.Free;
  end;
end;

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
  FallbackDrivers_WithoutFullEdition_RejectFunctionalUse;
begin
  CheckFallbackRejects(TRickSQLDatabaseEngine.DB2);
  CheckFallbackRejects(TRickSQLDatabaseEngine.Informix);
  CheckFallbackRejects(TRickSQLDatabaseEngine.SQLServer);
  CheckFallbackRejects(TRickSQLDatabaseEngine.ODBC);
  CheckFallbackRejects(TRickSQLDatabaseEngine.Oracle);
  CheckFallbackRejects(TRickSQLDatabaseEngine.SQLAnywhere);
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
