unit Rick.SQL.Core.DataSet.Materializer;

// Responsabilidade: materializar resultados conectados em um dataset independente.
// NAO abre conexões, resolve drivers ou conhece interface visual.

interface

uses
  // Data
  Data.DB,

  // FireDAC
  FireDAC.Comp.Client,

  // RickSQL
  Rick.SQL.Model.Command.Options,
  Rick.SQL.Model.Error;

type
  TRickSQLDataSetMaterializationSetup = record
    Query: TDataSet;
    Options: TRickSQLCommandOptions;
    class function Create(const AQuery: TDataSet;
      const AOptions: TRickSQLCommandOptions)
      : TRickSQLDataSetMaterializationSetup; static;
  end;

  TRickSQLCoreDataSetMaterializer = class
  private
    class function CreateDataSetError(const AMessage: string;
      const ADetail: string): TRickSQLError; static;
    class function ValidateSetup(
      const ASetup: TRickSQLDataSetMaterializationSetup;
      out AError: TRickSQLError): Boolean; static;
    class function CreateMemoryDataSet(const ASource: TDataSet;
      const AOptions: TRickSQLCommandOptions): TFDMemTable; static;
    class procedure PrepareWritableFields(
      const ADataSet: TFDMemTable); static;
    class procedure CopyRows(const ASource: TDataSet;
      const ATarget: TFDMemTable;
      const AOptions: TRickSQLCommandOptions); static;
    class procedure CopyRowsInternal(const ASource: TDataSet;
      const ATarget: TFDMemTable;
      const AOptions: TRickSQLCommandOptions); static;
    class procedure CopyCurrentRecord(const ASource: TDataSet;
      const ATarget: TFDMemTable); static;
    class procedure CopyField(const ASource: TDataSet;
      const ATarget: TFDMemTable; const AIndex: Integer); static;
    class function ShouldStopCopy(const ACopied: Integer;
      const AOptions: TRickSQLCommandOptions): Boolean; static;
    class procedure FinishPosition(const ADataSet: TDataSet;
      const AOptions: TRickSQLCommandOptions); static;
    class procedure CancelPendingChanges(const ADataSet: TDataSet); static;
    class procedure ReleaseOnFailure(var ADataSet: TDataSet); static;
  public
    class function Materialize(
      const ASetup: TRickSQLDataSetMaterializationSetup;
      out AError: TRickSQLError): TDataSet; static;
  end;

implementation

uses
  // RTL
  System.Rtti,
  System.SysUtils,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Error.Normalizer;

const
  _OPERATION_ = 'Materialização do dataset';
  _ERROR_QUERY_NOT_ASSIGNED_ =
    'A query de origem não foi informada. Execute a consulta antes de materializar o resultado.';
  _ERROR_QUERY_NOT_OPEN_ =
    'A query de origem não está aberta. Chame Open antes de solicitar o dataset independente.';
  _ERROR_QUERY_WITHOUT_FIELDS_ =
    'A query de origem não possui campos para materialização. Revise o SQL informado para retornar colunas.';
  _ERROR_MATERIALIZE_DATASET_ =
    'Não foi possível materializar o conjunto de dados da consulta. Verifique os campos retornados e tente novamente.';

class function TRickSQLDataSetMaterializationSetup.Create(
  const AQuery: TDataSet; const AOptions: TRickSQLCommandOptions)
  : TRickSQLDataSetMaterializationSetup;
begin
  Result.Query := AQuery;
  Result.Options := AOptions;
end;

class function TRickSQLCoreDataSetMaterializer.Materialize(
  const ASetup: TRickSQLDataSetMaterializationSetup;
  out AError: TRickSQLError): TDataSet;
begin
  AError := TRickSQLError.Empty;
  Result := nil;

  if not ValidateSetup(ASetup, AError) then
    Exit;

  try
    Result := CreateMemoryDataSet(ASetup.Query, ASetup.Options);
    CopyRows(ASetup.Query, TFDMemTable(Result), ASetup.Options);
    FinishPosition(Result, ASetup.Options);
  except
    on E: Exception do
    begin
      ReleaseOnFailure(Result);
      AError := TRickSQLErrorNormalizer.FromException(E,
        TRickSQLErrorKind.DataSet, _ERROR_MATERIALIZE_DATASET_, _OPERATION_);
    end;
  end;
end;

class function TRickSQLCoreDataSetMaterializer.CreateDataSetError(
  const AMessage: string; const ADetail: string): TRickSQLError;
begin
  Result := TRickSQLErrorNormalizer.FromDetail(TRickSQLErrorKind.DataSet,
    AMessage, ADetail, _OPERATION_);
end;

class function TRickSQLCoreDataSetMaterializer.ValidateSetup(
  const ASetup: TRickSQLDataSetMaterializationSetup;
  out AError: TRickSQLError): Boolean;
begin
  if not Assigned(ASetup.Query) then
  begin
    AError := CreateDataSetError(_ERROR_QUERY_NOT_ASSIGNED_, '');
    Exit(False);
  end;

  if not ASetup.Query.Active then
  begin
    AError := CreateDataSetError(_ERROR_QUERY_NOT_OPEN_, '');
    Exit(False);
  end;

  Result := ASetup.Query.FieldCount > 0;
  if not Result then
    AError := CreateDataSetError(_ERROR_QUERY_WITHOUT_FIELDS_, '');
end;

class function TRickSQLCoreDataSetMaterializer.CreateMemoryDataSet(
  const ASource: TDataSet; const AOptions: TRickSQLCommandOptions): TFDMemTable;
var
  LReady: Boolean;
  LIndex: Integer;
begin
  Result := TFDMemTable.Create(nil);
  LReady := False;
  try
    ASource.FieldDefs.Update;
    Result.FieldDefs.Assign(ASource.FieldDefs);
    Result.CreateDataSet;

    // A lógica executa isolada aqui, mantendo o método Materialize limpo
    if AOptions.Materialization.PreserveFieldMetadata and (Result.FieldCount = ASource.FieldCount) then
    begin
      for LIndex := 0 to ASource.FieldCount - 1 do
      begin
        Result.Fields[LIndex].Alignment    := ASource.Fields[LIndex].Alignment;
        Result.Fields[LIndex].DisplayLabel := ASource.Fields[LIndex].DisplayLabel;
        Result.Fields[LIndex].DisplayWidth := ASource.Fields[LIndex].DisplayWidth;
        Result.Fields[LIndex].Visible      := ASource.Fields[LIndex].Visible;
        Result.Fields[LIndex].EditMask     := ASource.Fields[LIndex].EditMask;
        Result.Fields[LIndex].Required     := ASource.Fields[LIndex].Required;

        if ASource.Fields[LIndex] is TNumericField then
          TNumericField(Result.Fields[LIndex]).DisplayFormat := TNumericField(ASource.Fields[LIndex]).DisplayFormat;
      end;
    end;

    PrepareWritableFields(Result);
    LReady := True;
  finally
    if not LReady then
      FreeAndNil(Result);
  end;
end;

class procedure TRickSQLCoreDataSetMaterializer.PrepareWritableFields(
  const ADataSet: TFDMemTable);
var
  LIndex: Integer;
begin
  if not Assigned(ADataSet) then
    Exit;

  for LIndex := 0 to ADataSet.FieldCount - 1 do
    ADataSet.Fields[LIndex].ReadOnly := False;
end;

class procedure TRickSQLCoreDataSetMaterializer.CopyRows(
  const ASource: TDataSet; const ATarget: TFDMemTable;
  const AOptions: TRickSQLCommandOptions);
var
  LContext: TRttiContext;
  LType: TRttiType;
  LMethod: TRttiMethod;
begin
  ASource.DisableControls;
  ATarget.DisableControls;

  try
    // Verifica se a opção foi explicitamente ligada E se não há limite de registros imposto
    if AOptions.FetchAll and (AOptions.MaxRecords <= 0) then
    begin
      LContext := TRttiContext.Create;
      try
        LType := LContext.GetType(ASource.ClassType);
        LMethod := LType.GetMethod('FetchAll');

        // Executa apenas se o DataSet enviado possuir o método FetchAll (como o FireDAC)
        if Assigned(LMethod) then
          LMethod.Invoke(ASource, []);
      finally
        // RTTI Context não precisa de Free em versões modernas do Delphi (record),
        // mas colocar um try/finally garante compatibilidade e intenção limpa.
      end;
    end;


    CopyRowsInternal(ASource, ATarget, AOptions);
  finally
    ATarget.EnableControls;
    ASource.EnableControls;
  end;
end;

class procedure TRickSQLCoreDataSetMaterializer.CopyRowsInternal(
  const ASource: TDataSet; const ATarget: TFDMemTable;
  const AOptions: TRickSQLCommandOptions);
var
  LCopied: Integer;
begin
  LCopied := 0;
  ASource.First;

  while not ASource.Eof do
  begin
    if ShouldStopCopy(LCopied, AOptions) then
      Break;

    CopyCurrentRecord(ASource, ATarget);
    Inc(LCopied);
    ASource.Next;
  end;
end;

class procedure TRickSQLCoreDataSetMaterializer.CopyCurrentRecord(
  const ASource: TDataSet; const ATarget: TFDMemTable);
var
  LIndex: Integer;
  LPosted: Boolean;
begin
  LPosted := False;
  ATarget.Append;

  try
    for LIndex := 0 to ASource.FieldCount - 1 do
      CopyField(ASource, ATarget, LIndex);

    ATarget.Post;
    LPosted := True;
  finally
    if not LPosted then
      CancelPendingChanges(ATarget);
  end;
end;

class procedure TRickSQLCoreDataSetMaterializer.CopyField(
  const ASource: TDataSet; const ATarget: TFDMemTable;
  const AIndex: Integer);
begin
  if ASource.Fields[AIndex].IsNull then
  begin
    ATarget.Fields[AIndex].Clear;
    Exit;
  end;

  ATarget.Fields[AIndex].Assign(ASource.Fields[AIndex]);
end;

class function TRickSQLCoreDataSetMaterializer.ShouldStopCopy(
  const ACopied: Integer; const AOptions: TRickSQLCommandOptions): Boolean;
begin
  Result := (AOptions.MaxRecords > 0) and (ACopied >= AOptions.MaxRecords);
end;

class procedure TRickSQLCoreDataSetMaterializer.FinishPosition(
  const ADataSet: TDataSet; const AOptions: TRickSQLCommandOptions);
begin
  if not AOptions.Materialization.PositionAtFirstRecord then
    Exit;

  ADataSet.First;
end;

class procedure TRickSQLCoreDataSetMaterializer.CancelPendingChanges(
  const ADataSet: TDataSet);
begin
  if ADataSet.State in dsEditModes then
    ADataSet.Cancel;
end;

class procedure TRickSQLCoreDataSetMaterializer.ReleaseOnFailure(
  var ADataSet: TDataSet);
begin
  FreeAndNil(ADataSet);
end;

end.
