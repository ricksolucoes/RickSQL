unit Rick.SQL.Tests.DataSet.Materializer;

interface

uses
  // DUnit
  TestFramework;

type
  TRickSQLDataSetMaterializerTests = class(TTestCase)
  published
    procedure CommandOptions_DefaultFetchAll_DeveSerTrue;
    procedure FetchAllTrue_MaxRecordsZero_DeveExecutarPrefetchEMaterializarTodos;
    procedure FetchAllFalse_MaxRecordsZero_DeveOmitirPrefetchEMaterializarTodos;
    procedure FetchAllTrue_MaxRecordsLimitado_DeveOmitirPrefetchERespeitarLimite;
    procedure FetchAllFalse_MaxRecordsLimitado_DeveOmitirPrefetchERespeitarLimite;
    procedure Open_DeveRetornarDataSetUtilAposLiberacaoDaSessaoInterna;
  end;

implementation

uses
  // Data
  Data.DB,

  // FireDAC
  FireDAC.Comp.Client,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteWrapper.Stat,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Model.Command.Options,
  Rick.SQL.Model.Error,
  Rick.SQL.Core.DataSet.Materializer;

type
  TRickSQLFetchProbeMemTable = class(TFDMemTable)
  private
    FFetchAllCallCount: Integer;
  published
    procedure FetchAll; reintroduce;
  public
    property FetchAllCallCount: Integer read FFetchAllCallCount;
  end;

procedure TRickSQLFetchProbeMemTable.FetchAll;
begin
  Inc(FFetchAllCallCount);
end;

function CreateSourceDataSet: TRickSQLFetchProbeMemTable;
begin
  Result := TRickSQLFetchProbeMemTable.Create(nil);
  Result.FieldDefs.Add('ID', ftInteger);
  Result.FieldDefs.Add('NAME', ftString, 20);
  Result.CreateDataSet;
  Result.AppendRecord([1, 'One']);
  Result.AppendRecord([2, 'Two']);
  Result.AppendRecord([3, 'Three']);
  Result.First;
end;

function MaterializeSource(const ASource: TDataSet;
  const AOptions: TRickSQLCommandOptions; out AError: TRickSQLError): TDataSet;
begin
  Result := TRickSQLCoreDataSetMaterializer.Materialize(
    TRickSQLDataSetMaterializationSetup.Create(ASource, AOptions), AError);
end;

procedure TRickSQLDataSetMaterializerTests.CommandOptions_DefaultFetchAll_DeveSerTrue;
var
  LOptions: TRickSQLCommandOptions;
begin
  LOptions := TRickSQLCommandOptions.CreateDefault;
  Check(LOptions.FetchAll, 'FetchAll default deveria ser True.');
  CheckEquals(0, LOptions.MaxRecords,
    'MaxRecords default deveria ser zero (sem limite de materialização).');
end;

procedure TRickSQLDataSetMaterializerTests.FetchAllTrue_MaxRecordsZero_DeveExecutarPrefetchEMaterializarTodos;
var
  LSource: TRickSQLFetchProbeMemTable;
  LTarget: TDataSet;
  LOptions: TRickSQLCommandOptions;
  LError: TRickSQLError;
begin
  LSource := CreateSourceDataSet;
  try
    LOptions := TRickSQLCommandOptions.CreateDefault;
    LOptions.FetchAll := True;
    LOptions.MaxRecords := 0;

    LTarget := MaterializeSource(LSource, LOptions, LError);
    try
      Check(Assigned(LTarget), 'A materialização deveria retornar um dataset.');
      Check(not LError.HasError, 'A materialização não deveria retornar erro.');
      CheckEquals(1, LSource.FetchAllCallCount,
        'FetchAll=True e MaxRecords=0 deveria executar o prefetch explícito uma vez.');
      CheckEquals(3, LTarget.RecordCount,
        'Sem MaxRecords, todos os registros deveriam ser materializados.');
    finally
      LTarget.Free;
    end;
  finally
    LSource.Free;
  end;
end;

procedure TRickSQLDataSetMaterializerTests.FetchAllFalse_MaxRecordsZero_DeveOmitirPrefetchEMaterializarTodos;
var
  LSource: TRickSQLFetchProbeMemTable;
  LTarget: TDataSet;
  LOptions: TRickSQLCommandOptions;
  LError: TRickSQLError;
begin
  LSource := CreateSourceDataSet;
  try
    LOptions := TRickSQLCommandOptions.CreateDefault;
    LOptions.FetchAll := False;
    LOptions.MaxRecords := 0;

    LTarget := MaterializeSource(LSource, LOptions, LError);
    try
      Check(Assigned(LTarget), 'A materialização deveria retornar um dataset.');
      Check(not LError.HasError, 'A materialização não deveria retornar erro.');
      CheckEquals(0, LSource.FetchAllCallCount,
        'FetchAll=False deveria omitir o prefetch explícito.');
      CheckEquals(3, LTarget.RecordCount,
        'FetchAll=False não deveria limitar a quantidade de registros materializados.');
    finally
      LTarget.Free;
    end;
  finally
    LSource.Free;
  end;
end;

procedure TRickSQLDataSetMaterializerTests.FetchAllTrue_MaxRecordsLimitado_DeveOmitirPrefetchERespeitarLimite;
var
  LSource: TRickSQLFetchProbeMemTable;
  LTarget: TDataSet;
  LOptions: TRickSQLCommandOptions;
  LError: TRickSQLError;
begin
  LSource := CreateSourceDataSet;
  try
    LOptions := TRickSQLCommandOptions.CreateDefault;
    LOptions.FetchAll := True;
    LOptions.MaxRecords := 2;

    LTarget := MaterializeSource(LSource, LOptions, LError);
    try
      Check(Assigned(LTarget), 'A materialização deveria retornar um dataset.');
      Check(not LError.HasError, 'A materialização não deveria retornar erro.');
      CheckEquals(0, LSource.FetchAllCallCount,
        'Com MaxRecords positivo, o prefetch explícito não deveria ser executado.');
      CheckEquals(2, LTarget.RecordCount,
        'MaxRecords deveria limitar a quantidade de registros materializados.');
    finally
      LTarget.Free;
    end;
  finally
    LSource.Free;
  end;
end;

procedure TRickSQLDataSetMaterializerTests.FetchAllFalse_MaxRecordsLimitado_DeveOmitirPrefetchERespeitarLimite;
var
  LSource: TRickSQLFetchProbeMemTable;
  LTarget: TDataSet;
  LOptions: TRickSQLCommandOptions;
  LError: TRickSQLError;
begin
  LSource := CreateSourceDataSet;
  try
    LOptions := TRickSQLCommandOptions.CreateDefault;
    LOptions.FetchAll := False;
    LOptions.MaxRecords := 2;

    LTarget := MaterializeSource(LSource, LOptions, LError);
    try
      Check(Assigned(LTarget), 'A materialização deveria retornar um dataset.');
      Check(not LError.HasError, 'A materialização não deveria retornar erro.');
      CheckEquals(0, LSource.FetchAllCallCount,
        'FetchAll=False deveria manter o prefetch explícito desabilitado.');
      CheckEquals(2, LTarget.RecordCount,
        'MaxRecords deveria limitar a materialização independentemente de FetchAll.');
    finally
      LTarget.Free;
    end;
  finally
    LSource.Free;
  end;
end;

procedure TRickSQLDataSetMaterializerTests.Open_DeveRetornarDataSetUtilAposLiberacaoDaSessaoInterna;
var
  LConnection: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
  LTarget: TDataSet;
  LError: TRickSQLError;
begin
  LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  LConnection.Database := ':memory:';
  LCommand := TRickSQL.Command(LConnection,
    'select 1 as ID union all select 2 as ID');

  LTarget := TRickSQL.Open(LCommand, LError);
  try
    Check(Assigned(LTarget), 'Open deveria retornar um dataset materializado.');
    Check(not LError.HasError, 'Open não deveria retornar erro no fixture SQLite.');
    Check(LTarget.Active, 'O dataset retornado deveria permanecer ativo.');
    CheckEquals(2, LTarget.RecordCount,
      'O dataset deveria permanecer utilizável após o retorno de Open.');
    LTarget.First;
    CheckEquals(1, LTarget.FieldByName('ID').AsInteger);
    LTarget.Next;
    CheckEquals(2, LTarget.FieldByName('ID').AsInteger);
  finally
    LTarget.Free;
  end;
end;

initialization
  RegisterTest(TRickSQLDataSetMaterializerTests.Suite);

end.
