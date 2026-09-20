unit Rick.SQL.Tests.Command.Connection.Validator;

interface

uses
  TestFramework,
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Connection.Options;

type
  TRickSQLCommandConnectionValidatorTests = class(TTestCase)
  private
    function SQLiteOptions: TRickSQLConnectionOptions;
    function SQLiteCommand: TRickSQLCommand;
    procedure CheckConnectionFails(const AOptions: TRickSQLConnectionOptions);
    procedure CheckCommandFails(const ACommand: TRickSQLCommand);
  published
    procedure Connection_SQLiteConfigured_IsValid;
    procedure Connection_WithoutData_Fails;
    procedure Connection_NegativeTimeout_Fails;
    procedure Connection_InvalidPort_Fails;
    procedure Connection_ReservedExtraParameter_Fails;
    procedure Connection_DuplicateExtraParameter_Fails;
    procedure Connection_WildcardClientLibrary_Fails;
    procedure Command_Configured_IsValid;
    procedure Command_EmptySQL_Fails;
    procedure Command_NegativeTimeout_Fails;
    procedure Command_NegativeMaxRecords_Fails;
  end;

implementation

uses
  Rick.SQL,
  Rick.SQL.Core.Command.Validator,
  Rick.SQL.Core.Connection.Validator,
  Rick.SQL.Model.Error,
  Rick.SQL.Model.Types;

function TRickSQLCommandConnectionValidatorTests.SQLiteOptions
  : TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  Result.Database := ':memory:';
end;

function TRickSQLCommandConnectionValidatorTests.SQLiteCommand: TRickSQLCommand;
begin
  Result := TRickSQL.Command(SQLiteOptions, 'select 1 as ID');
end;

procedure TRickSQLCommandConnectionValidatorTests.CheckConnectionFails(
  const AOptions: TRickSQLConnectionOptions);
var
  LError: TRickSQLError;
begin
  Check(not TRickSQLCoreConnectionValidator.Validate(AOptions, LError));
  Check(LError.HasError);
  Check(LError.Kind = TRickSQLErrorKind.Validation);
end;

procedure TRickSQLCommandConnectionValidatorTests.CheckCommandFails(
  const ACommand: TRickSQLCommand);
var
  LError: TRickSQLError;
begin
  Check(not TRickSQLCoreCommandValidator.Validate(ACommand, LError));
  Check(LError.HasError);
  Check(LError.Kind = TRickSQLErrorKind.Validation);
end;

procedure TRickSQLCommandConnectionValidatorTests.Connection_SQLiteConfigured_IsValid;
var
  LError: TRickSQLError;
begin
  Check(TRickSQLCoreConnectionValidator.Validate(SQLiteOptions, LError),
    LError.Message);
  Check(not LError.HasError);
end;

procedure TRickSQLCommandConnectionValidatorTests.Connection_WithoutData_Fails;
var
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  CheckConnectionFails(LOptions);
end;

procedure TRickSQLCommandConnectionValidatorTests.Connection_NegativeTimeout_Fails;
var
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := SQLiteOptions;
  LOptions.ConnectTimeout := -1;
  CheckConnectionFails(LOptions);
end;

procedure TRickSQLCommandConnectionValidatorTests.Connection_InvalidPort_Fails;
var
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := SQLiteOptions;
  LOptions.Port := 65536;
  CheckConnectionFails(LOptions);
end;

procedure TRickSQLCommandConnectionValidatorTests.Connection_ReservedExtraParameter_Fails;
var
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := SQLiteOptions;
  LOptions.AddExtraParameter('DriverID', 'SQLite');
  CheckConnectionFails(LOptions);
end;

procedure TRickSQLCommandConnectionValidatorTests.Connection_DuplicateExtraParameter_Fails;
var
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := SQLiteOptions;
  SetLength(LOptions.ExtraParameters, 2);
  LOptions.ExtraParameters[0] := TRickSQLConnectionParameter.Create('Mode', 'ReadWrite');
  LOptions.ExtraParameters[1] := TRickSQLConnectionParameter.Create('mode', 'ReadOnly');
  CheckConnectionFails(LOptions);
end;

procedure TRickSQLCommandConnectionValidatorTests.Connection_WildcardClientLibrary_Fails;
var
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := SQLiteOptions;
  LOptions.ClientLibraryPath := 'C:\RickSQL\*.dll';
  CheckConnectionFails(LOptions);
end;

procedure TRickSQLCommandConnectionValidatorTests.Command_Configured_IsValid;
var
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
begin
  LCommand := SQLiteCommand;
  Check(TRickSQLCoreCommandValidator.Validate(LCommand, LError), LError.Message);
  Check(not LError.HasError);
end;

procedure TRickSQLCommandConnectionValidatorTests.Command_EmptySQL_Fails;
var
  LCommand: TRickSQLCommand;
begin
  LCommand := SQLiteCommand;
  LCommand.Text := '';
  CheckCommandFails(LCommand);
end;

procedure TRickSQLCommandConnectionValidatorTests.Command_NegativeTimeout_Fails;
var
  LCommand: TRickSQLCommand;
begin
  LCommand := SQLiteCommand;
  LCommand.Options.CommandTimeout := -1;
  CheckCommandFails(LCommand);
end;

procedure TRickSQLCommandConnectionValidatorTests.Command_NegativeMaxRecords_Fails;
var
  LCommand: TRickSQLCommand;
begin
  LCommand := SQLiteCommand;
  LCommand.Options.MaxRecords := -1;
  CheckCommandFails(LCommand);
end;

initialization
  RegisterTest(TRickSQLCommandConnectionValidatorTests.Suite);

end.
