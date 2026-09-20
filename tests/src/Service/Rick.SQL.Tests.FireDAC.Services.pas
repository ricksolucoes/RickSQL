unit Rick.SQL.Tests.FireDAC.Services;

interface

uses
  TestFramework;

type
  TRickSQLFireDACServiceTests = class(TTestCase)
  published
    procedure Session_SQLiteContext_CreatesReadyResources;
    procedure Session_NilContext_ReportsStructuredError;
    procedure Connection_ConfigureSQLite_AppliesExpectedParameters;
    procedure Connection_OpenAndCloseSQLite_ChangesConnectedState;
    procedure Query_Configure_AssignsConnectionSQLAndTimeout;
    procedure Query_PrepareSQLite_Succeeds;
    procedure ParameterBinder_Value_AppliesMetadataAndValue;
    procedure ParameterBinder_MissingParameter_ReportsError;
  end;

implementation

uses
  System.SysUtils,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteWrapper.Stat,
  Rick.SQL,
  Rick.SQL.Core.Driver.Context.Factory,
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Error,
  Rick.SQL.Model.Parameter,
  Rick.SQL.Model.Types,
  Rick.SQL.Service.FireDAC.Connection,
  Rick.SQL.Service.FireDAC.Driver.Context,
  Rick.SQL.Service.FireDAC.Parameter.Binder,
  Rick.SQL.Service.FireDAC.Query,
  Rick.SQL.Service.FireDAC.Session;

function SQLiteOptions: TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  Result.Database := ':memory:';
end;

function CreateSQLiteSession(out AOptions: TRickSQLConnectionOptions;
  out AError: TRickSQLError): TRickSQLServiceFireDACSession;
var
  LContext: TRickSQLServiceFireDACDriverContext;
begin
  AOptions := SQLiteOptions;
  LContext := TRickSQLCoreDriverContextFactory.Create(AOptions,
    'Teste de serviço FireDAC', AError);
  Result := TRickSQLServiceFireDACSession.Create(LContext);
end;

function ConfigureSession(const ASession: TRickSQLServiceFireDACSession;
  const AOptions: TRickSQLConnectionOptions; out AError: TRickSQLError): Boolean;
var
  LSetup: TRickSQLFireDACConnectionSetup;
begin
  LSetup := TRickSQLFireDACConnectionSetup.Create(ASession.Connection,
    ASession.DriverContext, AOptions);
  Result := TRickSQLServiceFireDACConnection.Configure(LSetup, AError);
end;

procedure TRickSQLFireDACServiceTests.Session_SQLiteContext_CreatesReadyResources;
var
  LError: TRickSQLError;
  LOptions: TRickSQLConnectionOptions;
  LSession: TRickSQLServiceFireDACSession;
begin
  LSession := CreateSQLiteSession(LOptions, LError);
  try
    Check(LSession.Ready, LSession.Error.Message);
    Check(Assigned(LSession.DriverContext));
    Check(Assigned(LSession.Connection));
    Check(Assigned(LSession.Query));
  finally
    LSession.Free;
  end;
end;

procedure TRickSQLFireDACServiceTests.Session_NilContext_ReportsStructuredError;
var
  LSession: TRickSQLServiceFireDACSession;
begin
  LSession := TRickSQLServiceFireDACSession.Create(nil);
  try
    Check(not LSession.Ready);
    Check(LSession.Error.HasError);
    Check(LSession.Error.Kind = TRickSQLErrorKind.Connection);
  finally
    LSession.Free;
  end;
end;

procedure TRickSQLFireDACServiceTests.Connection_ConfigureSQLite_AppliesExpectedParameters;
var
  LError: TRickSQLError;
  LOptions: TRickSQLConnectionOptions;
  LSession: TRickSQLServiceFireDACSession;
begin
  LSession := CreateSQLiteSession(LOptions, LError);
  try
    Check(LSession.Ready, LSession.Error.Message);
    Check(ConfigureSession(LSession, LOptions, LError), LError.Message);
    CheckEquals('SQLite', LSession.Connection.Params.Values['DriverID']);
    CheckEquals(':memory:', LSession.Connection.Params.Values['Database']);
    Check(not LSession.Connection.LoginPrompt);
  finally
    LSession.Free;
  end;
end;

procedure TRickSQLFireDACServiceTests.Connection_OpenAndCloseSQLite_ChangesConnectedState;
var
  LError: TRickSQLError;
  LOptions: TRickSQLConnectionOptions;
  LSession: TRickSQLServiceFireDACSession;
begin
  LSession := CreateSQLiteSession(LOptions, LError);
  try
    Check(ConfigureSession(LSession, LOptions, LError), LError.Message);
    Check(TRickSQLServiceFireDACConnection.Open(LSession.Connection, LError),
      LError.Message);
    Check(LSession.Connection.Connected);
    TRickSQLServiceFireDACConnection.Close(LSession.Connection);
    Check(not LSession.Connection.Connected);
  finally
    LSession.Free;
  end;
end;

procedure TRickSQLFireDACServiceTests.Query_Configure_AssignsConnectionSQLAndTimeout;
var
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
  LQuery: TFDQuery;
  LConnection: TFDConnection;
begin
  LConnection := TFDConnection.Create(nil);
  LQuery := TFDQuery.Create(nil);
  try
    LCommand := TRickSQL.Command(SQLiteOptions, 'select 1 as ID');
    LCommand.Options.CommandTimeout := 2500;
    Check(TRickSQLServiceFireDACQuery.Configure(
      TRickSQLFireDACQuerySetup.Create(LQuery, LConnection, LCommand), LError),
      LError.Message);
    Check(LQuery.Connection = LConnection);
    CheckEquals(LCommand.Text, Trim(LQuery.SQL.Text));
    CheckEquals(2500, Integer(LQuery.ResourceOptions.CmdExecTimeout));
  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

procedure TRickSQLFireDACServiceTests.Query_PrepareSQLite_Succeeds;
var
  LError: TRickSQLError;
  LOptions: TRickSQLConnectionOptions;
  LSession: TRickSQLServiceFireDACSession;
  LCommand: TRickSQLCommand;
begin
  LSession := CreateSQLiteSession(LOptions, LError);
  try
    Check(ConfigureSession(LSession, LOptions, LError), LError.Message);
    Check(TRickSQLServiceFireDACConnection.Open(LSession.Connection, LError), LError.Message);
    LCommand := TRickSQL.Command(LOptions, 'select 1 as ID');
    Check(TRickSQLServiceFireDACQuery.Configure(
      TRickSQLFireDACQuerySetup.Create(LSession.Query, LSession.Connection, LCommand), LError), LError.Message);
    Check(TRickSQLServiceFireDACQuery.Prepare(LSession.Query, LError), LError.Message);
    Check(LSession.Query.Prepared);
  finally
    LSession.Free;
  end;
end;

procedure TRickSQLFireDACServiceTests.ParameterBinder_Value_AppliesMetadataAndValue;
var
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
  LParameter: TRickSQLParameter;
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.SQL.Text := 'select :P as V';
    LCommand := TRickSQL.Command(SQLiteOptions, LQuery.SQL.Text);
    LParameter := TRickSQLParameter.Create('P', 'abc');
    LParameter.DataType := ftString;
    LParameter.Size := 12;
    LCommand.AddParameter(LParameter);
    Check(TRickSQLServiceFireDACParameterBinder.Bind(
      TRickSQLFireDACParameterBindSetup.Create(LQuery, LCommand), LError), LError.Message);
    Check(LQuery.ParamByName('P').DataType = ftString);
    CheckEquals(12, LQuery.ParamByName('P').Size);
    CheckEquals('abc', LQuery.ParamByName('P').AsString);
  finally
    LQuery.Free;
  end;
end;

procedure TRickSQLFireDACServiceTests.ParameterBinder_MissingParameter_ReportsError;
var
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.SQL.Text := 'select 1 as V';
    LCommand := TRickSQL.Command(SQLiteOptions, LQuery.SQL.Text);
    LCommand.AddParameter(TRickSQLParameter.Create('P', 1));
    Check(not TRickSQLServiceFireDACParameterBinder.Bind(
      TRickSQLFireDACParameterBindSetup.Create(LQuery, LCommand), LError));
    Check(LError.HasError);
    Check(LError.Kind = TRickSQLErrorKind.Parameter);
  finally
    LQuery.Free;
  end;
end;

initialization
  RegisterTest(TRickSQLFireDACServiceTests.Suite);

end.
