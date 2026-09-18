program RickSQLDataSetMaterializerContractTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,

  // Data
  Data.DB,

  // FireDAC
  FireDAC.Comp.Client,

  // RickSQL
  Rick.SQL.Model.Command.Options,
  Rick.SQL.Model.Error,
  Rick.SQL.Model.Types,
  Rick.SQL.Core.DataSet.Materializer;

procedure Require(const ACondition: Boolean; const ACode: Integer);
begin
  if not ACondition then
    Halt(ACode);
end;

function CreateSourceDataSet: TFDMemTable;
begin
  Result := TFDMemTable.Create(nil);
  Result.FieldDefs.Add('ID', ftInteger);
  Result.FieldDefs.Add('NOME', ftString, 80);
  Result.CreateDataSet;
  Result.AppendRecord([1, 'RickSQL']);
  Result.AppendRecord([2, 'FireDAC']);
  Result.First;
end;

function MaterializeSource(const ASource: TDataSet;
  const AOptions: TRickSQLCommandOptions; out AError: TRickSQLError)
  : TDataSet;
begin
  Result := TRickSQLCoreDataSetMaterializer.Materialize(
    TRickSQLDataSetMaterializationSetup.Create(ASource, AOptions), AError);
end;

procedure TestMaterializeWithRecords;
var
  LSource: TFDMemTable;
  LTarget: TDataSet;
  LError: TRickSQLError;
  LOptions: TRickSQLCommandOptions;
begin
  LSource := CreateSourceDataSet;
  try
    LOptions := TRickSQLCommandOptions.CreateDefault;
    LTarget := MaterializeSource(LSource, LOptions, LError);
    try
      Require(Assigned(LTarget), 10);
      Require(LTarget.Active, 11);
      Require(LTarget.RecordCount = 2, 12);
      Require(LTarget.FieldByName('NOME').AsString = 'RickSQL', 13);
      Require(not LError.HasError, 14);
    finally
      LTarget.Free;
    end;
  finally
    LSource.Free;
  end;
end;

procedure TestMaterializeEmptyDataSet;
var
  LSource: TFDMemTable;
  LTarget: TDataSet;
  LError: TRickSQLError;
  LOptions: TRickSQLCommandOptions;
begin
  LSource := CreateSourceDataSet;
  try
    LSource.EmptyDataSet;
    LOptions := TRickSQLCommandOptions.CreateDefault;
    LTarget := MaterializeSource(LSource, LOptions, LError);
    try
      Require(Assigned(LTarget), 20);
      Require(LTarget.Active, 21);
      Require(LTarget.RecordCount = 0, 22);
      Require(not LError.HasError, 23);
    finally
      LTarget.Free;
    end;
  finally
    LSource.Free;
  end;
end;

procedure TestMaterializeWithRecordLimit;
var
  LSource: TFDMemTable;
  LTarget: TDataSet;
  LError: TRickSQLError;
  LOptions: TRickSQLCommandOptions;
begin
  LSource := CreateSourceDataSet;
  try
    LOptions := TRickSQLCommandOptions.CreateDefault;
    LOptions.MaxRecords := 1;
    LTarget := MaterializeSource(LSource, LOptions, LError);
    try
      Require(Assigned(LTarget), 30);
      Require(LTarget.RecordCount = 1, 31);
      Require(not LError.HasError, 32);
    finally
      LTarget.Free;
    end;
  finally
    LSource.Free;
  end;
end;

procedure TestMaterializeInvalidSource;
var
  LTarget: TDataSet;
  LError: TRickSQLError;
  LOptions: TRickSQLCommandOptions;
begin
  LOptions := TRickSQLCommandOptions.CreateDefault;
  LTarget := MaterializeSource(nil, LOptions, LError);
  Require(not Assigned(LTarget), 40);
  Require(LError.Kind = TRickSQLErrorKind.DataSet, 41);
  Require(LError.HasError, 42);
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  TestMaterializeWithRecords;
  TestMaterializeEmptyDataSet;
  TestMaterializeWithRecordLimit;
  TestMaterializeInvalidSource;
  Writeln('Materialização de dataset verificada com sucesso.');
end.
