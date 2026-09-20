unit Rick.SQL.Tests.Models;

interface

uses
  TestFramework;

type
  TRickSQLModelTests = class(TTestCase)
  published
    procedure ConnectionOptions_Defaults_AreStable;
    procedure ConnectionOptions_AddExtraParameter_AddsValue;
    procedure ConnectionOptions_DuplicateExtraParameter_ReplacesValue;
    procedure CommandOptions_Defaults_AreStable;
    procedure MaterializationOptions_Defaults_AreStable;
    procedure Parameter_Create_PreservesValueContract;
    procedure Parameter_CreateNull_PreservesNullContract;
    procedure Command_AddParameter_AppendsParameter;
    procedure Command_ManyParameters_PreservesArray;
    procedure Error_EmptyAndCreate_PreserveContract;
    procedure ExecutionResult_SuccessAndFailure_PreserveContract;
    procedure DriverDefinition_AddLibraryAndRequires_PreserveContract;
  end;

implementation

uses
  System.SysUtils,
  System.Variants,
  Data.DB,
  Rick.SQL,
  Rick.SQL.Model.Driver.Definition;

procedure TRickSQLModelTests.ConnectionOptions_Defaults_AreStable;
var
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  Check(LOptions.Engine = TRickSQLDatabaseEngine.SQLite);
  CheckEquals(0, LOptions.Port);
  CheckEquals(0, LOptions.ConnectTimeout);
  CheckEquals(0, Length(LOptions.ExtraParameters));
end;

procedure TRickSQLModelTests.ConnectionOptions_AddExtraParameter_AddsValue;
var
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  LOptions.AddExtraParameter('LockingMode', 'Normal');
  CheckEquals(1, Length(LOptions.ExtraParameters));
  CheckEquals('LockingMode', LOptions.ExtraParameters[0].Name);
  CheckEquals('Normal', LOptions.ExtraParameters[0].Value);
end;

procedure TRickSQLModelTests.ConnectionOptions_DuplicateExtraParameter_ReplacesValue;
var
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  LOptions.AddExtraParameter('LockingMode', 'Normal');
  LOptions.AddExtraParameter('lockingmode', 'Exclusive');
  CheckEquals(1, Length(LOptions.ExtraParameters));
  CheckEquals('Exclusive', LOptions.ExtraParameters[0].Value);
end;

procedure TRickSQLModelTests.CommandOptions_Defaults_AreStable;
var
  LOptions: TRickSQLCommandOptions;
begin
  LOptions := TRickSQLCommandOptions.CreateDefault;
  CheckEquals(0, LOptions.CommandTimeout);
  Check(LOptions.UseTransaction);
  Check(LOptions.FetchAll);
  CheckEquals(0, LOptions.MaxRecords);
end;

procedure TRickSQLModelTests.MaterializationOptions_Defaults_AreStable;
var
  LOptions: TRickSQLMaterializationOptions;
begin
  LOptions := TRickSQLMaterializationOptions.CreateDefault;
  Check(LOptions.PositionAtFirstRecord);
  Check(LOptions.PreserveFieldMetadata);
end;

procedure TRickSQLModelTests.Parameter_Create_PreservesValueContract;
var
  LParameter: TRickSQLParameter;
begin
  LParameter := TRickSQLParameter.Create('ID', 10);
  CheckEquals('ID', LParameter.Name);
  CheckEquals(10, Integer(LParameter.Value));
  Check(LParameter.DataType = ftUnknown);
  Check(LParameter.Direction = ptInput);
  Check(not LParameter.IsNull);
end;

procedure TRickSQLModelTests.Parameter_CreateNull_PreservesNullContract;
var
  LParameter: TRickSQLParameter;
begin
  LParameter := TRickSQLParameter.CreateNull('NAME', ftString);
  CheckEquals('NAME', LParameter.Name);
  Check(VarIsNull(LParameter.Value));
  Check(LParameter.DataType = ftString);
  Check(LParameter.Direction = ptInput);
  Check(LParameter.IsNull);
end;

procedure TRickSQLModelTests.Command_AddParameter_AppendsParameter;
var
  LCommand: TRickSQLCommand;
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  LCommand := TRickSQL.Command(LOptions, 'select :ID as ID');
  LCommand.AddParameter(TRickSQLParameter.Create('ID', 7));
  CheckEquals(1, Length(LCommand.Parameters));
  CheckEquals('ID', LCommand.Parameters[0].Name);
  CheckEquals(7, Integer(LCommand.Parameters[0].Value));
end;

procedure TRickSQLModelTests.Command_ManyParameters_PreservesArray;
var
  LCommand: TRickSQLCommand;
  LIndex: Integer;
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  LCommand := TRickSQL.Command(LOptions, 'select 1');
  for LIndex := 1 to 250 do
    LCommand.AddParameter(TRickSQLParameter.Create('P' + IntToStr(LIndex), LIndex));
  CheckEquals(250, Length(LCommand.Parameters));
  CheckEquals('P250', LCommand.Parameters[249].Name);
end;

procedure TRickSQLModelTests.Error_EmptyAndCreate_PreserveContract;
var
  LError: TRickSQLError;
begin
  LError := TRickSQLError.Empty;
  Check(not LError.HasError);
  Check(LError.Kind = TRickSQLErrorKind.None);
  LError := TRickSQLError.Create(TRickSQLErrorKind.Validation, 'Falha');
  Check(LError.HasError);
  Check(LError.Kind = TRickSQLErrorKind.Validation);
  CheckEquals('Falha', LError.Message);
end;

procedure TRickSQLModelTests.ExecutionResult_SuccessAndFailure_PreserveContract;
var
  LError: TRickSQLError;
  LResult: TRickSQLExecutionResult;
begin
  LResult := TRickSQLExecutionResult.Succeeded(3);
  Check(LResult.Success);
  CheckEquals(3, LResult.RowsAffected);
  LError := TRickSQLError.Create(TRickSQLErrorKind.Command, 'Falha');
  LResult := TRickSQLExecutionResult.Failed(LError);
  Check(not LResult.Success);
  CheckEquals(0, LResult.RowsAffected);
  Check(LResult.Error.Kind = TRickSQLErrorKind.Command);
end;

procedure TRickSQLModelTests.DriverDefinition_AddLibraryAndRequires_PreserveContract;
var
  LDefinition: TRickSQLDriverDefinition;
begin
  LDefinition := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.PostgreSQL, 'PG');
  LDefinition.RequiredConnectionOptions := [TRickSQLConnectionRequirement.Server];
  LDefinition.AddClientLibrary('libpq.dll');
  CheckEquals('PG', LDefinition.DriverID);
  CheckEquals(1, Length(LDefinition.ClientLibraries));
  Check(LDefinition.Requires(TRickSQLConnectionRequirement.Server));
  Check(not LDefinition.Requires(TRickSQLConnectionRequirement.Password));
end;

initialization
  RegisterTest(TRickSQLModelTests.Suite);

end.
