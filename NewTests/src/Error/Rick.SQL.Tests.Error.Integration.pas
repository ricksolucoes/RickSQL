unit Rick.SQL.Tests.Error.Integration;

interface

uses
  TestFramework,
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Error;

type
  TRickSQLErrorIntegrationTests = class(TTestCase)
  private
    procedure CheckSanitizedError(const AError: TRickSQLError;
      const AExpectedKind: TRickSQLErrorKind;
      const AExpectedOperation: string);
  published
    procedure DriverContext_Exception_UsesSharedNormalization;
    procedure Connection_Exception_UsesSharedNormalization;
    procedure QueryPrepare_Exception_UsesSharedNormalization;
    procedure Session_InvalidContext_UsesSharedNormalization;
    procedure ParameterBinder_InvalidSetup_UsesSharedNormalization;
    procedure Transaction_MissingConnection_UsesSharedNormalization;
    procedure DataSetMaterializer_Exception_UsesSharedNormalization;
    procedure ClientLibraryResolver_SanitizesPublicErrorSurfaces;
  end;

implementation

uses
  // RTL
  System.Classes,
  System.SysUtils,

  // Data
  Data.DB,

  // FireDAC
  FireDAC.Comp.Client,

  // RickSQL
  Rick.SQL.Model.Contracts,
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Driver.Definition,
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Command.Options,
  Rick.SQL.Service.FireDAC.Driver.Context,
  Rick.SQL.Service.FireDAC.Connection,
  Rick.SQL.Service.FireDAC.Query,
  Rick.SQL.Service.FireDAC.Session,
  Rick.SQL.Service.FireDAC.Parameter.Binder,
  Rick.SQL.Service.FireDAC.Transaction,
  Rick.SQL.Core.DataSet.Materializer,
  Rick.SQL.Core.ClientLibrary.Resolver;

type
  TRickSQLTestFailurePoint = (rfpCreateDriverLink, rfpApplyConnectionOptions);

  TRickSQLRaisingDriverProvider = class(TInterfacedObject,
    IRickSQLDriverProvider)
  private
    FFailurePoint: TRickSQLTestFailurePoint;
  public
    constructor Create(const AFailurePoint: TRickSQLTestFailurePoint);
    function Engine: TRickSQLDatabaseEngine;
    function Definition: TRickSQLDriverDefinition;
    function CreateDriverLink(const AOwner: TComponent): TComponent;
    procedure ApplyConnectionOptions(const AOptions: TRickSQLConnectionOptions;
      const AParameters: TStrings);
    function ValidateOptions(const AOptions: TRickSQLConnectionOptions;
      out AError: string): Boolean;
  end;

  TRickSQLRaisingMemTable = class(TFDMemTable)
  private
    FRaiseOnFirst: Boolean;
  protected
    procedure InternalFirst; override;
  public
    property RaiseOnFirst: Boolean read FRaiseOnFirst write FRaiseOnFirst;
  end;

const
  _SECRET_ = 'integration-secret-value';
  _EXCEPTION_DETAIL_ = 'Password=' + _SECRET_ + ';Failure=controlled';

procedure TRickSQLErrorIntegrationTests.CheckSanitizedError(
  const AError: TRickSQLError; const AExpectedKind: TRickSQLErrorKind;
  const AExpectedOperation: string);
begin
  Check(AError.HasError, 'O componente deveria retornar erro.');
  Check(AError.Kind = AExpectedKind, 'Kind do erro está incorreto.');
  CheckEquals(AExpectedOperation, AError.Operation,
    'Operation do erro está incorreta.');
  Check(Pos(_SECRET_, AError.Message) = 0,
    'Message expôs valor sensível.');
  Check(Pos(_SECRET_, AError.TechnicalDetail) = 0,
    'TechnicalDetail expôs valor sensível.');
end;

constructor TRickSQLRaisingDriverProvider.Create(
  const AFailurePoint: TRickSQLTestFailurePoint);
begin
  inherited Create;
  FFailurePoint := AFailurePoint;
end;

function TRickSQLRaisingDriverProvider.Engine: TRickSQLDatabaseEngine;
begin
  Result := TRickSQLDatabaseEngine.SQLite;
end;

function TRickSQLRaisingDriverProvider.Definition: TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(TRickSQLDatabaseEngine.SQLite,
    'TestDriver');
end;

function TRickSQLRaisingDriverProvider.CreateDriverLink(
  const AOwner: TComponent): TComponent;
begin
  if FFailurePoint = rfpCreateDriverLink then
    raise Exception.Create(_EXCEPTION_DETAIL_);
  Result := TComponent.Create(AOwner);
end;

procedure TRickSQLRaisingDriverProvider.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions; const AParameters: TStrings);
begin
  if FFailurePoint = rfpApplyConnectionOptions then
    raise Exception.Create(_EXCEPTION_DETAIL_);
end;

function TRickSQLRaisingDriverProvider.ValidateOptions(
  const AOptions: TRickSQLConnectionOptions; out AError: string): Boolean;
begin
  AError := '';
  Result := True;
end;

procedure TRickSQLRaisingMemTable.InternalFirst;
begin
  if FRaiseOnFirst then
    raise Exception.Create(_EXCEPTION_DETAIL_);
  inherited InternalFirst;
end;

procedure TRickSQLErrorIntegrationTests.DriverContext_Exception_UsesSharedNormalization;
var
  LProvider: IRickSQLDriverProvider;
  LContext: TRickSQLServiceFireDACDriverContext;
begin
  LProvider := TRickSQLRaisingDriverProvider.Create(
    rfpCreateDriverLink);
  LContext := TRickSQLServiceFireDACDriverContext.Create(LProvider, '');
  try
    Check(not LContext.Configured,
      'O contexto não deveria ser configurado após a exception.');
    CheckSanitizedError(LContext.Error, TRickSQLErrorKind.Driver,
      'Criação do contexto do driver FireDAC');
  finally
    LContext.Free;
  end;
end;

procedure TRickSQLErrorIntegrationTests.Connection_Exception_UsesSharedNormalization;
var
  LProvider: IRickSQLDriverProvider;
  LContext: TRickSQLServiceFireDACDriverContext;
  LConnection: TFDConnection;
  LOptions: TRickSQLConnectionOptions;
  LError: TRickSQLError;
begin
  LProvider := TRickSQLRaisingDriverProvider.Create(
    rfpApplyConnectionOptions);
  LContext := TRickSQLServiceFireDACDriverContext.Create(LProvider, '');
  LConnection := TFDConnection.Create(nil);
  try
    Check(LContext.Configured, 'O contexto de teste deveria estar configurado.');
    LOptions := TRickSQLConnectionOptions.Create(TRickSQLDatabaseEngine.SQLite);
    Check(not TRickSQLServiceFireDACConnection.Configure(
      TRickSQLFireDACConnectionSetup.Create(LConnection, LContext, LOptions),
      LError), 'A configuração deveria capturar a exception do provider.');
    CheckSanitizedError(LError, TRickSQLErrorKind.Connection,
      'Configuração da conexão FireDAC');
  finally
    LConnection.Free;
    LContext.Free;
  end;
end;

procedure TRickSQLErrorIntegrationTests.QueryPrepare_Exception_UsesSharedNormalization;
var
  LQuery: TFDQuery;
  LError: TRickSQLError;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.SQL.Text := 'select 1';
    Check(not TRickSQLServiceFireDACQuery.Prepare(LQuery, LError),
      'Prepare sem conexão deveria produzir erro controlado.');
    Check(LError.HasError, 'Prepare deveria retornar TRickSQLError.');
    Check(LError.Kind = TRickSQLErrorKind.Command, 'Kind de Prepare incorreto.');
    CheckEquals('Preparação da query FireDAC', LError.Operation,
      'Operation de Prepare incorreta.');
    Check(LError.TechnicalDetail <> '',
      'Prepare deveria preservar o detalhe técnico da exception.');
  finally
    LQuery.Free;
  end;
end;

procedure TRickSQLErrorIntegrationTests.Session_InvalidContext_UsesSharedNormalization;
var
  LSession: TRickSQLServiceFireDACSession;
begin
  LSession := TRickSQLServiceFireDACSession.Create(nil);
  try
    Check(not LSession.Ready, 'Sessão sem contexto não deveria ficar pronta.');
    CheckSanitizedError(LSession.Error, TRickSQLErrorKind.Connection,
      'Criação da sessão FireDAC');
  finally
    LSession.Free;
  end;
end;

procedure TRickSQLErrorIntegrationTests.ParameterBinder_InvalidSetup_UsesSharedNormalization;
var
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
begin
  LCommand := TRickSQLCommand.Create(
    TRickSQLConnectionOptions.Create(TRickSQLDatabaseEngine.SQLite),
    'select :P');
  Check(not TRickSQLServiceFireDACParameterBinder.Bind(
    TRickSQLFireDACParameterBindSetup.Create(nil, LCommand), LError),
    'Binder sem query deveria retornar erro controlado.');
  CheckSanitizedError(LError, TRickSQLErrorKind.Parameter,
    'Aplicação de parâmetros FireDAC');
end;

procedure TRickSQLErrorIntegrationTests.Transaction_MissingConnection_UsesSharedNormalization;
var
  LError: TRickSQLError;
begin
  Check(not TRickSQLServiceFireDACTransaction.Start(nil, LError),
    'Transação sem conexão deveria retornar erro controlado.');
  CheckSanitizedError(LError, TRickSQLErrorKind.Transaction,
    'Início da transação FireDAC');
end;

procedure TRickSQLErrorIntegrationTests.DataSetMaterializer_Exception_UsesSharedNormalization;
var
  LSource: TRickSQLRaisingMemTable;
  LTarget: TDataSet;
  LOptions: TRickSQLCommandOptions;
  LError: TRickSQLError;
begin
  LSource := TRickSQLRaisingMemTable.Create(nil);
  try
    LSource.FieldDefs.Add('ID', ftInteger);
    LSource.CreateDataSet;
    LSource.AppendRecord([1]);
    LOptions := TRickSQLCommandOptions.CreateDefault;
    LOptions.FetchAll := False;
    LSource.RaiseOnFirst := True;

    LTarget := TRickSQLCoreDataSetMaterializer.Materialize(
      TRickSQLDataSetMaterializationSetup.Create(LSource, LOptions), LError);
    try
      Check(not Assigned(LTarget),
        'A materialização deveria falhar no cenário controlado.');
      CheckSanitizedError(LError, TRickSQLErrorKind.DataSet,
        'Materialização do dataset');
    finally
      LTarget.Free;
    end;
  finally
    LSource.Free;
  end;
end;

procedure TRickSQLErrorIntegrationTests.ClientLibraryResolver_SanitizesPublicErrorSurfaces;
var
  LOptions: TRickSQLConnectionOptions;
  LResolution: TRickSQLClientLibraryResolution;
  LError: TRickSQLError;
begin
  LOptions := TRickSQLConnectionOptions.Create(TRickSQLDatabaseEngine.Firebird);
  LOptions.ClientLibraryPath := 'Password=' + _SECRET_;
  LResolution := TRickSQLCoreClientLibraryResolver.Resolve(LOptions, LError);

  Check(not LResolution.Success,
    'O caminho inexistente deveria falhar na resolução da biblioteca.');
  CheckSanitizedError(LError, TRickSQLErrorKind.ClientLibrary,
    'Resolução da biblioteca cliente');
end;

initialization
  RegisterTest(TRickSQLErrorIntegrationTests.Suite);

end.
