unit Rick.SQL.Tests.Fluent.Lifecycle;

interface

uses
  // RTL
  System.Classes,

  // Data
  Data.DB,

  // DUnit
  TestFramework,

  // RickSQL
  Rick.SQL.Interf;

type
  TDataSetReleaseProbe = class(TComponent)
  private
    FReleased: Boolean;
    FWatched: TComponent;
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    destructor Destroy; override;
    procedure Watch(const ADataSet: TDataSet);
    property Released: Boolean read FReleased;
  end;

  TRickSQLFluentLifecycleTests = class(TTestCase)
  private
    function NewSQLiteRick: IRickSQL;
    procedure CheckSuccess(const ARick: IRickSQL);
    procedure OpenSQL(const ARick: IRickSQL; const ASQL: string);
    procedure ExecuteSQL(const ARick: IRickSQL; const ASQL: string);
    procedure OpenOwnedDataSetAndReleaseFacade(
      const AProbe: TDataSetReleaseProbe);
    function OpenExternalDataSetAndReleaseFacade(
      const AProbe: TDataSetReleaseProbe): TDataSet;
  published
    procedure EstadoInicial_DeveExporResultadoNeutro;
    procedure EstadoInicial_OpenDeveUsarDefaultsDeMaterializacao;
    procedure SQL_NaoDeveLimparParametrosConsolidados;
    procedure Clear_DeveRemoverParametrosConsolidados;
    procedure Clear_NaoDeveResetarParametroEmConstrucao;
    procedure CommandOptions_DevemPersistirEntreOpen;
    procedure MaterializationOptions_DevemPersistirEntreOpen;
    procedure Error_DeveSerReiniciadoAntesDaProximaOperacao;
    procedure OpenOpen_OwnerTrue_DeveLiberarDataSetAnterior;
    procedure OpenOpen_OwnerFalse_DevePreservarDataSetAnterior;
    procedure OpenExecute_OwnerTrue_DeveInvalidarDataSetAnterior;
    procedure OpenExecute_OwnerFalse_DeveManterDataSetAnteriorReferenciado;
    procedure ExecuteExecute_DeveManterDataSetNil;
    procedure ExecuteOpen_DeveProduzirNovoDataSet;
    procedure Destructor_OwnerTrue_DeveLiberarDataSet;
    procedure Destructor_OwnerFalse_NaoDeveLiberarDataSet;
    procedure NovaInstancia_NaoDeveCompartilharParametros;
  end;

implementation

uses
  // RTL
  System.SysUtils,

  // FireDAC SQLite estático para fixture determinística e sem servidor externo
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteWrapper.Stat,

  // RickSQL
  Rick.SQL.Model.Types;

{ TDataSetReleaseProbe }

destructor TDataSetReleaseProbe.Destroy;
begin
  if Assigned(FWatched) then
    FWatched.RemoveFreeNotification(Self);
  inherited;
end;

procedure TDataSetReleaseProbe.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FWatched) then
  begin
    FWatched := nil;
    FReleased := True;
  end;
end;

procedure TDataSetReleaseProbe.Watch(const ADataSet: TDataSet);
begin
  FReleased := False;
  FWatched := ADataSet;
  if Assigned(FWatched) then
    FWatched.FreeNotification(Self);
end;

{ TRickSQLFluentLifecycleTests }

function TRickSQLFluentLifecycleTests.NewSQLiteRick: IRickSQL;
begin
  Result := TRickSQLInterf.New
    .ConnectionOptions
      .Engine(TRickSQLDatabaseEngine.SQLite)
      .Database(':memory:')
    .Back;
end;

procedure TRickSQLFluentLifecycleTests.CheckSuccess(const ARick: IRickSQL);
begin
  CheckEquals('', ARick.Result.Error,
    'A operação fluent deveria terminar sem mensagem de erro.');
  Check(ARick.Result.ErrorFull.Success,
    'ErrorFull deveria representar uma operação bem-sucedida.');
end;

procedure TRickSQLFluentLifecycleTests.OpenSQL(const ARick: IRickSQL;
  const ASQL: string);
begin
  ARick.Command.SQL(ASQL).Back.Cursor.Open;
end;

procedure TRickSQLFluentLifecycleTests.ExecuteSQL(const ARick: IRickSQL;
  const ASQL: string);
begin
  ARick.Command.SQL(ASQL).Back.Cursor.Execute;
end;

procedure TRickSQLFluentLifecycleTests.OpenOwnedDataSetAndReleaseFacade(
  const AProbe: TDataSetReleaseProbe);
var
  LRick: IRickSQL;
begin
  LRick := NewSQLiteRick;
  OpenSQL(LRick, 'select 1 as V');
  CheckSuccess(LRick);
  AProbe.Watch(LRick.Result.DataSet);
end;

function TRickSQLFluentLifecycleTests.OpenExternalDataSetAndReleaseFacade(
  const AProbe: TDataSetReleaseProbe): TDataSet;
var
  LRick: IRickSQL;
begin
  LRick := NewSQLiteRick.Owner(False);
  OpenSQL(LRick, 'select 1 as V');
  CheckSuccess(LRick);
  Result := LRick.Result.DataSet;
  AProbe.Watch(Result);
end;

procedure TRickSQLFluentLifecycleTests.EstadoInicial_DeveExporResultadoNeutro;
var
  LRick: IRickSQL;
begin
  LRick := TRickSQLInterf.New;
  CheckEquals('', LRick.Result.Error);
  Check(not Assigned(LRick.Result.DataSet));
  Check(not LRick.Result.ErrorFull.Success);
  CheckEquals(0, LRick.Result.ErrorFull.RowsAffected);
  Check(not LRick.Result.ErrorFull.Error.HasError);
end;

procedure TRickSQLFluentLifecycleTests.EstadoInicial_OpenDeveUsarDefaultsDeMaterializacao;
var
  LRick: IRickSQL;
begin
  LRick := NewSQLiteRick;
  OpenSQL(LRick, 'select 1 as V union all select 2 as V');
  CheckSuccess(LRick);
  CheckEquals(2, LRick.Result.DataSet.RecordCount,
    'MaxRecords default deveria ser zero, sem limitar as linhas.');
  CheckEquals(1, LRick.Result.DataSet.RecNo,
    'PositionAtFirstRecord default deveria posicionar no primeiro registro.');
end;

procedure TRickSQLFluentLifecycleTests.SQL_NaoDeveLimparParametrosConsolidados;
var
  LRick: IRickSQL;
begin
  LRick := NewSQLiteRick;
  LRick.Command.SQL('select :P as V').Parameter
    .Name('P').Value(7).Add.Return.Back.Cursor.Open;
  CheckSuccess(LRick);
  CheckEquals(7, LRick.Result.DataSet.FieldByName('V').AsInteger);

  OpenSQL(LRick, 'select :P + 1 as V');
  CheckSuccess(LRick);
  CheckEquals(8, LRick.Result.DataSet.FieldByName('V').AsInteger,
    'SQL deveria trocar apenas o texto e preservar parâmetros consolidados.');
end;

procedure TRickSQLFluentLifecycleTests.Clear_DeveRemoverParametrosConsolidados;
var
  LRick: IRickSQL;
begin
  LRick := NewSQLiteRick;
  LRick.Command.SQL('select :P as V').Parameter
    .Name('P').Value(7).Add.Clear.Return.Back.Cursor.Open;
  Check(LRick.Result.ErrorFull.Error.Kind = TRickSQLErrorKind.Validation);
  Check(Pos('P', LRick.Result.Error) > 0,
    'Clear deveria remover P da lista consolidada de parâmetros.');
end;

procedure TRickSQLFluentLifecycleTests.Clear_NaoDeveResetarParametroEmConstrucao;
var
  LRick: IRickSQL;
begin
  LRick := NewSQLiteRick;
  LRick.Command.Parameter.Name('P').Value(9).Clear.AddVariant
    .Return.SQL('select :P as V').Back.Cursor.Open;
  CheckSuccess(LRick);
  CheckEquals(9, LRick.Result.DataSet.FieldByName('V').AsInteger,
    'Clear não deveria alterar Name/Value do parâmetro ainda em construção.');
end;

procedure TRickSQLFluentLifecycleTests.CommandOptions_DevemPersistirEntreOpen;
var
  LRick: IRickSQL;
begin
  LRick := NewSQLiteRick;
  LRick.Command.SQL('select 1 as V union all select 2 as V')
    .Option.MaxRedord(1).Back.Cursor.Open;
  CheckSuccess(LRick);
  CheckEquals(1, LRick.Result.DataSet.RecordCount);

  LRick.Command.Parameter.Clear;
  OpenSQL(LRick, 'select 10 as V union all select 20 as V union all select 30 as V');
  CheckSuccess(LRick);
  CheckEquals(1, LRick.Result.DataSet.RecordCount,
    'MaxRecords deveria permanecer configurado na instância fluent.');
end;

procedure TRickSQLFluentLifecycleTests.MaterializationOptions_DevemPersistirEntreOpen;
var
  LRick: IRickSQL;
begin
  LRick := NewSQLiteRick;
  LRick.Command.SQL('select 1 as V union all select 2 as V').Option
    .Materialization.Position(False).ToBack.Return.Back.Cursor.Open;
  CheckSuccess(LRick);
  CheckEquals(2, LRick.Result.DataSet.RecNo);

  OpenSQL(LRick, 'select 10 as V union all select 20 as V');
  CheckSuccess(LRick);
  CheckEquals(2, LRick.Result.DataSet.RecNo,
    'Position(False) deveria persistir na instância entre comandos.');
end;

procedure TRickSQLFluentLifecycleTests.Error_DeveSerReiniciadoAntesDaProximaOperacao;
var
  LRick: IRickSQL;
begin
  LRick := NewSQLiteRick;
  ExecuteSQL(LRick, '');
  Check(LRick.Result.Error <> '',
    'A primeira execução deveria produzir erro de validação.');

  OpenSQL(LRick, 'select 1 as V');
  CheckSuccess(LRick);
  CheckEquals('', LRick.Result.Error,
    'O erro anterior não deveria sobreviver à operação seguinte bem-sucedida.');
end;

procedure TRickSQLFluentLifecycleTests.OpenOpen_OwnerTrue_DeveLiberarDataSetAnterior;
var
  LRick: IRickSQL;
  LProbe: TDataSetReleaseProbe;
begin
  LRick := NewSQLiteRick;
  OpenSQL(LRick, 'select 1 as V');
  CheckSuccess(LRick);
  LProbe := TDataSetReleaseProbe.Create(nil);
  try
    LProbe.Watch(LRick.Result.DataSet);
    OpenSQL(LRick, 'select 2 as V');
    Check(LProbe.Released,
      'Owner(True) deveria liberar o dataset anterior antes do novo Open.');
  finally
    LProbe.Free;
  end;
end;

procedure TRickSQLFluentLifecycleTests.OpenOpen_OwnerFalse_DevePreservarDataSetAnterior;
var
  LRick: IRickSQL;
  LOldDataSet: TDataSet;
  LNewDataSet: TDataSet;
  LProbe: TDataSetReleaseProbe;
begin
  LRick := NewSQLiteRick.Owner(False);
  LOldDataSet := nil;
  LNewDataSet := nil;
  LProbe := TDataSetReleaseProbe.Create(nil);
  try
    OpenSQL(LRick, 'select 1 as V');
    LOldDataSet := LRick.Result.DataSet;
    CheckSuccess(LRick);
    LProbe.Watch(LOldDataSet);
    OpenSQL(LRick, 'select 2 as V');
    LNewDataSet := LRick.Result.DataSet;
    CheckSuccess(LRick);
    Check(not LProbe.Released,
      'Owner(False) não deveria liberar o dataset anterior no novo Open.');
    Check(LNewDataSet <> LOldDataSet,
      'O novo Open deveria substituir a referência interna pelo novo dataset.');
  finally
    LRick := nil;
    LNewDataSet.Free;
    LOldDataSet.Free;
    LProbe.Free;
  end;
end;

procedure TRickSQLFluentLifecycleTests.OpenExecute_OwnerTrue_DeveInvalidarDataSetAnterior;
var
  LRick: IRickSQL;
  LProbe: TDataSetReleaseProbe;
begin
  LRick := NewSQLiteRick;
  OpenSQL(LRick, 'select 1 as V');
  CheckSuccess(LRick);
  LProbe := TDataSetReleaseProbe.Create(nil);
  try
    LProbe.Watch(LRick.Result.DataSet);
    ExecuteSQL(LRick, 'create table T (ID integer)');
    CheckSuccess(LRick);
    Check(LProbe.Released,
      'Execute deveria liberar o dataset anterior quando Owner=True.');
    Check(not Assigned(LRick.Result.DataSet));
  finally
    LProbe.Free;
  end;
end;

procedure TRickSQLFluentLifecycleTests.OpenExecute_OwnerFalse_DeveManterDataSetAnteriorReferenciado;
var
  LRick: IRickSQL;
  LDataSet: TDataSet;
  LProbe: TDataSetReleaseProbe;
begin
  LRick := NewSQLiteRick.Owner(False);
  LDataSet := nil;
  LProbe := TDataSetReleaseProbe.Create(nil);
  try
    OpenSQL(LRick, 'select 1 as V');
    LDataSet := LRick.Result.DataSet;
    CheckSuccess(LRick);
    LProbe.Watch(LDataSet);
    ExecuteSQL(LRick, 'create table T (ID integer)');
    CheckSuccess(LRick);
    Check(not LProbe.Released);
    Check(LRick.Result.DataSet = LDataSet,
      'Execute não substitui FDataSet quando Owner=False.');
  finally
    LRick := nil;
    LDataSet.Free;
    LProbe.Free;
  end;
end;

procedure TRickSQLFluentLifecycleTests.ExecuteExecute_DeveManterDataSetNil;
var
  LRick: IRickSQL;
begin
  LRick := NewSQLiteRick;
  ExecuteSQL(LRick, 'create table T1 (ID integer)');
  CheckSuccess(LRick);
  Check(not Assigned(LRick.Result.DataSet));

  ExecuteSQL(LRick, 'create table T2 (ID integer)');
  CheckSuccess(LRick);
  Check(not Assigned(LRick.Result.DataSet));
end;

procedure TRickSQLFluentLifecycleTests.ExecuteOpen_DeveProduzirNovoDataSet;
var
  LRick: IRickSQL;
begin
  LRick := NewSQLiteRick;
  ExecuteSQL(LRick, 'create table T (ID integer)');
  CheckSuccess(LRick);
  Check(not Assigned(LRick.Result.DataSet));

  OpenSQL(LRick, 'select 1 as V');
  CheckSuccess(LRick);
  Check(Assigned(LRick.Result.DataSet));
  CheckEquals(1, LRick.Result.DataSet.FieldByName('V').AsInteger);
end;

procedure TRickSQLFluentLifecycleTests.Destructor_OwnerTrue_DeveLiberarDataSet;
var
  LProbe: TDataSetReleaseProbe;
begin
  LProbe := TDataSetReleaseProbe.Create(nil);
  try
    OpenOwnedDataSetAndReleaseFacade(LProbe);
    Check(LProbe.Released,
      'O destrutor deveria liberar o dataset atual quando Owner=True.');
  finally
    LProbe.Free;
  end;
end;

procedure TRickSQLFluentLifecycleTests.Destructor_OwnerFalse_NaoDeveLiberarDataSet;
var
  LDataSet: TDataSet;
  LProbe: TDataSetReleaseProbe;
begin
  LDataSet := nil;
  LProbe := TDataSetReleaseProbe.Create(nil);
  try
    LDataSet := OpenExternalDataSetAndReleaseFacade(LProbe);
    Check(not LProbe.Released,
      'O destrutor não deveria liberar o dataset quando Owner=False.');
    LDataSet.Free;
    Check(LProbe.Released,
      'O consumidor deveria conseguir liberar o dataset uma única vez.');
  finally
    if Assigned(LDataSet) and not LProbe.Released then
      LDataSet.Free;
    LProbe.Free;
  end;
end;

procedure TRickSQLFluentLifecycleTests.NovaInstancia_NaoDeveCompartilharParametros;
var
  LFirst: IRickSQL;
  LSecond: IRickSQL;
begin
  LFirst := NewSQLiteRick;
  LSecond := NewSQLiteRick;
  LFirst.Command.Parameter.Name('P').Value(11).Add.Return
    .SQL('select :P as V').Back.Cursor.Open;
  CheckSuccess(LFirst);

  OpenSQL(LSecond, 'select :P as V');
  Check(LSecond.Result.ErrorFull.Error.Kind = TRickSQLErrorKind.Validation);
  Check(Pos('P', LSecond.Result.Error) > 0,
    'Uma nova instância não deveria herdar parâmetros de outra instância.');
end;

initialization
  RegisterTest(TRickSQLFluentLifecycleTests.Suite);

end.
