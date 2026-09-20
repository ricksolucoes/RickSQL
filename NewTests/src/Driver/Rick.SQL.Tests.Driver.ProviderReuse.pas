unit Rick.SQL.Tests.Driver.ProviderReuse;

interface

uses
  // DUnit
  TestFramework;

type
  TRickSQLDriverProviderReuseTests = class(TTestCase)
  published
    procedure Factory_SQLite_ProviderAndDefinitionCorrespond;
    procedure ConnectionValidator_Compatibility_ValidatesSQLite;
    procedure ConnectionValidator_ProviderOverload_ReturnsResolvedProvider;
    procedure CommandValidator_ProviderOverload_ReturnsResolvedProvider;
    procedure ClientLibraryResolver_Compatibility_SQLiteDoesNotRequireLibrary;
    procedure ClientLibraryResolver_ProvidedProvider_ObtainsDefinitionOnce;
    procedure DriverContextFactory_Compatibility_CreatesSQLiteContext;
    procedure DriverContextFactory_ProvidedProvider_ReusesSameInstance;
    procedure IndependentOperations_ResolveDistinctProviders;
    procedure Execute_SQLite_TemporaryDatabase_Succeeds;
    procedure Open_SQLite_TemporaryDatabase_ReturnsDataset;
  end;

implementation

uses
  // RTL
  System.Classes,
  System.IOUtils,

  // Data
  Data.DB,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Core.ClientLibrary.Resolver,
  Rick.SQL.Core.Command.Validator,
  Rick.SQL.Core.Connection.Validator,
  Rick.SQL.Core.Driver.Context.Factory,
  Rick.SQL.Core.Driver.Factory,
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Contracts,
  Rick.SQL.Model.Driver.Definition,
  Rick.SQL.Model.Error,
  Rick.SQL.Model.Execution.Result,
  Rick.SQL.Model.Types,
  Rick.SQL.Service.FireDAC.Driver.Context;

type
  TRickSQLControlledProvider = class(TInterfacedObject, IRickSQLDriverProvider)
  private
    FDefinitionCalls: Integer;
    FCreateDriverLinkCalls: Integer;
  public
    function Engine: TRickSQLDatabaseEngine;
    function Definition: TRickSQLDriverDefinition;
    function CreateDriverLink(const AOwner: TComponent): TComponent;
    procedure ApplyConnectionOptions(const AOptions: TRickSQLConnectionOptions;
      const AParameters: TStrings);
    function ValidateOptions(const AOptions: TRickSQLConnectionOptions;
      out AError: string): Boolean;
    property DefinitionCalls: Integer read FDefinitionCalls;
    property CreateDriverLinkCalls: Integer read FCreateDriverLinkCalls;
  end;

function SQLiteOptions: TRickSQLConnectionOptions;
begin
  Result := TRickSQLConnectionOptions.Create(TRickSQLDatabaseEngine.SQLite);
  Result.Database := ':memory:';
end;

function TRickSQLControlledProvider.Engine: TRickSQLDatabaseEngine;
begin
  Result := TRickSQLDatabaseEngine.SQLite;
end;

function TRickSQLControlledProvider.Definition: TRickSQLDriverDefinition;
begin
  Inc(FDefinitionCalls);
  Result := TRickSQLDriverDefinition.Create(TRickSQLDatabaseEngine.SQLite,
    'ControlledSQLite');
end;

function TRickSQLControlledProvider.CreateDriverLink(
  const AOwner: TComponent): TComponent;
begin
  Inc(FCreateDriverLinkCalls);
  Result := TComponent.Create(AOwner);
end;

procedure TRickSQLControlledProvider.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions; const AParameters: TStrings);
begin
end;

function TRickSQLControlledProvider.ValidateOptions(
  const AOptions: TRickSQLConnectionOptions; out AError: string): Boolean;
begin
  AError := '';
  Result := True;
end;

procedure TRickSQLDriverProviderReuseTests.Factory_SQLite_ProviderAndDefinitionCorrespond;
var
  LProvider: IRickSQLDriverProvider;
  LDefinition: TRickSQLDriverDefinition;
begin
  LProvider := TRickSQLCoreDriverFactory.Resolve(TRickSQLDatabaseEngine.SQLite);
  Check(LProvider <> nil, 'A factory deveria resolver o provider SQLite.');
  LDefinition := LProvider.Definition;
  Check(LProvider.Engine = TRickSQLDatabaseEngine.SQLite,
    'O provider resolvido deveria corresponder ao engine SQLite.');
  Check(LDefinition.Engine = TRickSQLDatabaseEngine.SQLite,
    'A Definition deveria corresponder ao engine do provider.');
end;

procedure TRickSQLDriverProviderReuseTests.ConnectionValidator_Compatibility_ValidatesSQLite;
var
  LError: TRickSQLError;
begin
  Check(TRickSQLCoreConnectionValidator.Validate(SQLiteOptions, LError),
    LError.Message);
  Check(not LError.HasError,
    'O wrapper de compatibilidade deveria preservar validação sem erro.');
end;

procedure TRickSQLDriverProviderReuseTests.ConnectionValidator_ProviderOverload_ReturnsResolvedProvider;
var
  LProvider: IRickSQLDriverProvider;
  LError: TRickSQLError;
begin
  Check(TRickSQLCoreConnectionValidator.Validate(
    SQLiteOptions, LProvider, LError), LError.Message);
  Check(LProvider <> nil,
    'A validação deveria devolver o provider já resolvido.');
  Check(LProvider.Engine = TRickSQLDatabaseEngine.SQLite,
    'O provider devolvido deveria corresponder às opções validadas.');
end;

procedure TRickSQLDriverProviderReuseTests.CommandValidator_ProviderOverload_ReturnsResolvedProvider;
var
  LCommand: TRickSQLCommand;
  LProvider: IRickSQLDriverProvider;
  LError: TRickSQLError;
begin
  LCommand := TRickSQLCommand.Create(SQLiteOptions, 'select 1');
  Check(TRickSQLCoreCommandValidator.Validate(
    LCommand, LProvider, LError), LError.Message);
  Check(LProvider <> nil,
    'A validação do comando deveria propagar o provider resolvido.');
  Check(LProvider.Engine = TRickSQLDatabaseEngine.SQLite,
    'O provider propagado deveria corresponder ao comando validado.');
end;

procedure TRickSQLDriverProviderReuseTests.ClientLibraryResolver_Compatibility_SQLiteDoesNotRequireLibrary;
var
  LError: TRickSQLError;
  LResolution: TRickSQLClientLibraryResolution;
begin
  LResolution := TRickSQLCoreClientLibraryResolver.Resolve(SQLiteOptions, LError);
  Check(LResolution.Success, LError.Message);
  Check(not LResolution.Required,
    'SQLite não deveria exigir biblioteca cliente externa.');
  Check(not LError.HasError,
    'A resolução sem biblioteca obrigatória deveria permanecer sem erro.');
end;

procedure TRickSQLDriverProviderReuseTests.ClientLibraryResolver_ProvidedProvider_ObtainsDefinitionOnce;
var
  LConcrete: TRickSQLControlledProvider;
  LProvider: IRickSQLDriverProvider;
  LResolution: TRickSQLClientLibraryResolution;
  LError: TRickSQLError;
begin
  LConcrete := TRickSQLControlledProvider.Create;
  LProvider := LConcrete;
  LResolution := TRickSQLCoreClientLibraryResolver.Resolve(
    SQLiteOptions, LProvider, LError);
  Check(LResolution.Success, LError.Message);
  CheckEquals(1, LConcrete.DefinitionCalls,
    'O resolver deveria obter a Definition uma única vez do provider recebido.');
end;

procedure TRickSQLDriverProviderReuseTests.DriverContextFactory_Compatibility_CreatesSQLiteContext;
var
  LContext: TRickSQLServiceFireDACDriverContext;
  LError: TRickSQLError;
begin
  LContext := TRickSQLCoreDriverContextFactory.Create(
    SQLiteOptions, 'Teste de caracterização do provider', LError);
  try
    Check(Assigned(LContext), LError.Message);
    Check(LContext.Configured, LContext.Error.Message);
    Check(LContext.Provider.Engine = TRickSQLDatabaseEngine.SQLite,
      'O contexto deveria manter o provider SQLite.');
  finally
    LContext.Free;
  end;
end;

procedure TRickSQLDriverProviderReuseTests.DriverContextFactory_ProvidedProvider_ReusesSameInstance;
var
  LConcrete: TRickSQLControlledProvider;
  LProvider: IRickSQLDriverProvider;
  LContext: TRickSQLServiceFireDACDriverContext;
  LError: TRickSQLError;
begin
  LConcrete := TRickSQLControlledProvider.Create;
  LProvider := LConcrete;
  LContext := TRickSQLCoreDriverContextFactory.Create(
    SQLiteOptions, 'Teste de reutilização do provider', LProvider, LError);
  try
    Check(Assigned(LContext), LError.Message);
    Check(LContext.Configured, LContext.Error.Message);
    Check(LContext.Provider = LProvider,
      'A factory deveria manter exatamente o provider recebido.');
    CheckEquals(1, LConcrete.DefinitionCalls,
      'A Definition deveria ser obtida uma única vez no pipeline da factory.');
    CheckEquals(1, LConcrete.CreateDriverLinkCalls,
      'O DriverLink deveria ser criado pelo mesmo provider recebido.');
  finally
    LContext.Free;
  end;
end;


procedure TRickSQLDriverProviderReuseTests.IndependentOperations_ResolveDistinctProviders;
var
  LFirst: IRickSQLDriverProvider;
  LSecond: IRickSQLDriverProvider;
  LError: TRickSQLError;
begin
  Check(TRickSQLCoreConnectionValidator.Validate(
    SQLiteOptions, LFirst, LError), LError.Message);
  Check(TRickSQLCoreConnectionValidator.Validate(
    SQLiteOptions, LSecond, LError), LError.Message);
  Check(LFirst <> LSecond,
    'Operações independentes não deveriam compartilhar provider global.');
end;

procedure TRickSQLDriverProviderReuseTests.Execute_SQLite_TemporaryDatabase_Succeeds;
var
  LOptions: TRickSQLConnectionOptions;
  LDatabase: string;
  LResult: TRickSQLExecutionResult;
begin
  LDatabase := TPath.GetTempFileName;
  TFile.Delete(LDatabase);
  try
    LOptions := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
    LOptions.Database := LDatabase;
    LResult := TRickSQL.Execute(TRickSQL.Command(LOptions,
      'CREATE TABLE PROVIDER_REUSE_TEST (ID INTEGER)'));
    Check(LResult.Success, LResult.Error.Message);
    Check(not LResult.Error.HasError,
      'Execute não deveria alterar o comportamento funcional do pipeline.');
  finally
    if TFile.Exists(LDatabase) then
      TFile.Delete(LDatabase);
  end;
end;

procedure TRickSQLDriverProviderReuseTests.Open_SQLite_TemporaryDatabase_ReturnsDataset;
var
  LOptions: TRickSQLConnectionOptions;
  LDatabase: string;
  LDataSet: TDataSet;
  LError: TRickSQLError;
begin
  LDatabase := TPath.GetTempFileName;
  TFile.Delete(LDatabase);
  try
    LOptions := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
    LOptions.Database := LDatabase;
    LDataSet := TRickSQL.Open(TRickSQL.Command(LOptions,
      'SELECT 1 AS VALUE'), LError);
    try
      Check(Assigned(LDataSet), LError.Message);
      Check(not LError.HasError,
        'Open não deveria alterar o comportamento funcional do pipeline.');
      CheckEquals(1, LDataSet.FieldByName('VALUE').AsInteger,
        'Open deveria preservar o resultado materializado da consulta.');
    finally
      LDataSet.Free;
    end;
  finally
    if TFile.Exists(LDatabase) then
      TFile.Delete(LDatabase);
  end;
end;

initialization
  RegisterTest(TRickSQLDriverProviderReuseTests.Suite);

end.
