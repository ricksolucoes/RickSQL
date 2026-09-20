unit Rick.SQL.Tests.SQLite.Integration;

interface

uses
  TestFramework,
  Rick.SQL;

type
  TRickSQLSQLiteIntegrationTests = class(TTestCase)
  private
    FDatabase: string;
    FConnection: TRickSQLConnectionOptions;
    procedure DeleteDatabaseFiles;
    procedure ExecuteSuccess(const ASQL: string);
    procedure InsertMixedRow;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Execute_InsertUpdateDelete_ReportsRowsAffected;
    procedure Execute_ZeroRowsAffected_ReturnsZero;
    procedure Open_WithParameter_ReturnsMaterializedRow;
    procedure Open_MixedTypes_ExposesExpectedFields;
    procedure Open_EmptyResult_ReturnsActiveEmptyDataSet;
    procedure Open_MissingParameter_ReturnsValidationError;
    procedure Execute_EmptySQL_ReturnsValidationError;
    procedure Open_EmptySQL_ReturnsValidationError;
    procedure Execute_InvalidSQL_ReturnsStructuredError;
    procedure Execute_MissingDirectory_ReturnsStructuredError;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  Data.DB,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteWrapper.Stat;

procedure TRickSQLSQLiteIntegrationTests.SetUp;
begin
  inherited;
  FDatabase := TPath.GetTempFileName;
  TFile.Delete(FDatabase);
  FConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  FConnection.Database := FDatabase;
end;

procedure TRickSQLSQLiteIntegrationTests.DeleteDatabaseFiles;
begin
  if TFile.Exists(FDatabase) then
    TFile.Delete(FDatabase);
  if TFile.Exists(FDatabase + '-journal') then
    TFile.Delete(FDatabase + '-journal');
  if TFile.Exists(FDatabase + '-wal') then
    TFile.Delete(FDatabase + '-wal');
  if TFile.Exists(FDatabase + '-shm') then
    TFile.Delete(FDatabase + '-shm');
end;

procedure TRickSQLSQLiteIntegrationTests.TearDown;
begin
  DeleteDatabaseFiles;
  inherited;
end;

procedure TRickSQLSQLiteIntegrationTests.ExecuteSuccess(const ASQL: string);
var
  LResult: TRickSQLExecutionResult;
begin
  LResult := TRickSQL.Execute(TRickSQL.Command(FConnection, ASQL));
  Check(LResult.Success, LResult.Error.Message);
  Check(not LResult.Error.HasError);
end;

procedure TRickSQLSQLiteIntegrationTests.InsertMixedRow;
var
  LCommand: TRickSQLCommand;
  LResult: TRickSQLExecutionResult;
begin
  LCommand := TRickSQL.Command(FConnection,
    'insert into MIXED (ID, NAME, VALUE_NUM, ACTIVE, NOTE, NULL_VALUE) ' +
    'values (:ID, :NAME, :VALUE_NUM, :ACTIVE, :NOTE, :NULL_VALUE)');
  LCommand.AddParameter(TRickSQLParameter.Create('ID', 1));
  LCommand.AddParameter(TRickSQLParameter.Create('NAME', 'Mixed'));
  LCommand.AddParameter(TRickSQLParameter.Create('VALUE_NUM', 12.5));
  LCommand.AddParameter(TRickSQLParameter.Create('ACTIVE', 1));
  LCommand.AddParameter(TRickSQLParameter.Create('NOTE', 'blob'));
  LCommand.AddParameter(TRickSQLParameter.CreateNull('NULL_VALUE', ftString));
  LResult := TRickSQL.Execute(LCommand);
  Check(LResult.Success, LResult.Error.Message);
end;

procedure TRickSQLSQLiteIntegrationTests.Execute_InsertUpdateDelete_ReportsRowsAffected;
var
  LResult: TRickSQLExecutionResult;
begin
  ExecuteSuccess('create table T (ID integer primary key, NAME varchar(20))');
  LResult := TRickSQL.Execute(TRickSQL.Command(FConnection,
    'insert into T (ID, NAME) values (1, ''One'')'));
  Check(LResult.Success, LResult.Error.Message);
  CheckEquals(1, LResult.RowsAffected);
  LResult := TRickSQL.Execute(TRickSQL.Command(FConnection,
    'update T set NAME = ''Two'' where ID = 1'));
  Check(LResult.Success, LResult.Error.Message);
  CheckEquals(1, LResult.RowsAffected);
  LResult := TRickSQL.Execute(TRickSQL.Command(FConnection,
    'delete from T where ID = 1'));
  Check(LResult.Success, LResult.Error.Message);
  CheckEquals(1, LResult.RowsAffected);
end;

procedure TRickSQLSQLiteIntegrationTests.Execute_ZeroRowsAffected_ReturnsZero;
var
  LResult: TRickSQLExecutionResult;
begin
  ExecuteSuccess('create table T (ID integer primary key, NAME varchar(20))');
  LResult := TRickSQL.Execute(TRickSQL.Command(FConnection,
    'update T set NAME = ''None'' where ID = 777'));
  Check(LResult.Success, LResult.Error.Message);
  CheckEquals(0, LResult.RowsAffected);
end;

procedure TRickSQLSQLiteIntegrationTests.Open_WithParameter_ReturnsMaterializedRow;
var
  LCommand: TRickSQLCommand;
  LDataSet: TDataSet;
  LError: TRickSQLError;
begin
  ExecuteSuccess('create table T (ID integer primary key, NAME varchar(20))');
  ExecuteSuccess('insert into T (ID, NAME) values (1, ''One'')');
  LCommand := TRickSQL.Command(FConnection,
    'select ID, NAME from T where ID = :ID');
  LCommand.AddParameter(TRickSQLParameter.Create('ID', 1));
  LDataSet := TRickSQL.Open(LCommand, LError);
  try
    Check(Assigned(LDataSet), LError.Message);
    Check(not LError.HasError);
    CheckEquals(1, LDataSet.FieldByName('ID').AsInteger);
    CheckEquals('One', LDataSet.FieldByName('NAME').AsString);
  finally
    LDataSet.Free;
  end;
end;

procedure TRickSQLSQLiteIntegrationTests.Open_MixedTypes_ExposesExpectedFields;
var
  LDataSet: TDataSet;
  LError: TRickSQLError;
begin
  ExecuteSuccess('create table MIXED (ID integer primary key, NAME varchar(20), ' +
    'VALUE_NUM numeric(15,2), ACTIVE integer, NOTE blob, NULL_VALUE varchar(20))');
  InsertMixedRow;
  LDataSet := TRickSQL.Open(TRickSQL.Command(FConnection,
    'select NAME, NOTE, NULL_VALUE, VALUE_NUM + 1 as CALCULATED from MIXED'), LError);
  try
    Check(Assigned(LDataSet), LError.Message);
    Check(not LError.HasError);
    CheckEquals('Mixed', LDataSet.FieldByName('NAME').AsString);
    Check(Assigned(LDataSet.FindField('NOTE')));
    Check(Assigned(LDataSet.FindField('NULL_VALUE')));
    Check(Assigned(LDataSet.FindField('CALCULATED')));
  finally
    LDataSet.Free;
  end;
end;

procedure TRickSQLSQLiteIntegrationTests.Open_EmptyResult_ReturnsActiveEmptyDataSet;
var
  LDataSet: TDataSet;
  LError: TRickSQLError;
begin
  ExecuteSuccess('create table T (ID integer primary key)');
  LDataSet := TRickSQL.Open(TRickSQL.Command(FConnection,
    'select ID from T where ID = -1'), LError);
  try
    Check(Assigned(LDataSet), LError.Message);
    Check(not LError.HasError);
    Check(LDataSet.Active);
    Check(LDataSet.IsEmpty);
  finally
    LDataSet.Free;
  end;
end;

procedure TRickSQLSQLiteIntegrationTests.Open_MissingParameter_ReturnsValidationError;
var
  LDataSet: TDataSet;
  LError: TRickSQLError;
begin
  LDataSet := TRickSQL.Open(TRickSQL.Command(FConnection,
    'select :ID as ID'), LError);
  try
    Check(not Assigned(LDataSet));
    Check(LError.HasError);
    Check(LError.Kind = TRickSQLErrorKind.Validation);
  finally
    LDataSet.Free;
  end;
end;

procedure TRickSQLSQLiteIntegrationTests.Execute_EmptySQL_ReturnsValidationError;
var
  LResult: TRickSQLExecutionResult;
begin
  LResult := TRickSQL.Execute(TRickSQL.Command(FConnection, ''));
  Check(not LResult.Success);
  Check(LResult.Error.HasError);
  Check(LResult.Error.Kind = TRickSQLErrorKind.Validation);
end;

procedure TRickSQLSQLiteIntegrationTests.Open_EmptySQL_ReturnsValidationError;
var
  LDataSet: TDataSet;
  LError: TRickSQLError;
begin
  LDataSet := TRickSQL.Open(TRickSQL.Command(FConnection, ''), LError);
  try
    Check(not Assigned(LDataSet));
    Check(LError.HasError);
    Check(LError.Kind = TRickSQLErrorKind.Validation);
  finally
    LDataSet.Free;
  end;
end;

procedure TRickSQLSQLiteIntegrationTests.Execute_InvalidSQL_ReturnsStructuredError;
var
  LResult: TRickSQLExecutionResult;
begin
  LResult := TRickSQL.Execute(TRickSQL.Command(FConnection, 'select * from'));
  Check(not LResult.Success);
  Check(LResult.Error.HasError);
  Check(LResult.Error.Kind = TRickSQLErrorKind.Command);
end;

procedure TRickSQLSQLiteIntegrationTests.Execute_MissingDirectory_ReturnsStructuredError;
var
  LConnection: TRickSQLConnectionOptions;
  LDirectory: string;
  LResult: TRickSQLExecutionResult;
begin
  LDirectory := TPath.Combine(TPath.GetTempPath, TPath.GetRandomFileName);
  Check(not TDirectory.Exists(LDirectory));
  LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  LConnection.Database := TPath.Combine(LDirectory, 'base.sqlite');
  LResult := TRickSQL.Execute(TRickSQL.Command(LConnection,
    'create table T (ID integer)'));
  Check(not LResult.Success);
  Check(LResult.Error.HasError);
end;

initialization
  RegisterTest(TRickSQLSQLiteIntegrationTests.Suite);

end.
