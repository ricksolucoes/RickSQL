unit Rick.SQL.Core.Parameter.Validator;

// Responsabilidade: validar os parâmetros informados para um comando SQL.
// NAO aplica parâmetros em queries, executa SQL ou conhece componentes FireDAC.

interface

uses
  // RickSQL
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Error;

type
  TRickSQLCoreParameterValidator = class
  private
    class function Fail(const AMessage: string;
      out AError: TRickSQLError): Boolean; static;
    class function ValidateParameterNames(const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
    class function ValidateParameterValues(const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
    class function ValidateRequiredParameters(const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
  public
    class function Validate(const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
  end;

implementation

uses
  // RTL
  System.Classes,
  System.SysUtils,
  System.Variants,

  // Data
  Data.DB,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Parameter;

{$SCOPEDENUMS ON}

type
  TRickSQLParameterScanMode = (
    Normal,
    SingleQuote,
    DoubleQuote,
    LineComment,
    BlockComment
  );

  TRickSQLParameterScanContext = record
    SQL: string;
    Names: TStrings;
    Index: Integer;
    Mode: TRickSQLParameterScanMode;
  end;

  TRickSQLCoreParameterScanner = class
  private
    class function CurrentChar(
      const AContext: TRickSQLParameterScanContext): Char; static;
    class function NextChar(
      const AContext: TRickSQLParameterScanContext): Char; static;
    class function IsNameStart(const AChar: Char): Boolean; static;
    class function IsNamePart(const AChar: Char): Boolean; static;
    class function CanReadParameter(
      const AContext: TRickSQLParameterScanContext): Boolean; static;
    class function TryStartComment(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class function TryStartQuote(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class function TrySkipTypeCast(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class procedure ProcessNormal(
      var AContext: TRickSQLParameterScanContext); static;
    class procedure ProcessSingleQuote(
      var AContext: TRickSQLParameterScanContext); static;
    class procedure ProcessDoubleQuote(
      var AContext: TRickSQLParameterScanContext); static;
    class procedure ProcessLineComment(
      var AContext: TRickSQLParameterScanContext); static;
    class procedure ProcessBlockComment(
      var AContext: TRickSQLParameterScanContext); static;
    class procedure ReadParameter(
      var AContext: TRickSQLParameterScanContext); static;
    class procedure Process(
      var AContext: TRickSQLParameterScanContext); static;
  public
    class procedure Extract(const ASQL: string;
      const ANames: TStrings); static;
  end;

const
  _OPERATION_ = 'Validação dos parâmetros SQL';
  _ERROR_NAME_EMPTY_ = 'O nome de um parâmetro SQL não foi informado. Informe o nome ou remova o parâmetro vazio.';
  _ERROR_NAME_INVALID_ =
    'O nome do parâmetro SQL "%s" não é válido. Use letras, números, sublinhado ou cifrão.';
  _ERROR_NAME_DUPLICATE_ =
    'O parâmetro SQL "%s" foi informado mais de uma vez. Mantenha apenas uma ocorrência.';
  _ERROR_SIZE_INVALID_ =
    'O tamanho do parâmetro SQL "%s" não pode ser negativo. Informe zero ou um tamanho positivo.';
  _ERROR_SIZE_UNSUPPORTED_ =
    'O parâmetro SQL "%s" possui tamanho para um tipo que não aceita essa configuração. Remova o tamanho ou altere o tipo.';
  _ERROR_DIRECTION_UNSUPPORTED_ =
    'O parâmetro SQL "%s" utiliza uma direção ainda não suportada. Utilize parâmetros de entrada.';
  _ERROR_TYPE_UNSUPPORTED_ =
    'O parâmetro SQL "%s" utiliza um tipo de campo não suportado. Escolha um TFieldType compatível.';
  _ERROR_NULL_TYPE_REQUIRED_ =
    'O parâmetro SQL nulo "%s" deve possuir um tipo de campo definido. Informe o DataType do parâmetro.';
  _ERROR_NULL_INCONSISTENT_ =
    'O parâmetro SQL "%s" possui valor nulo sem a indicação IsNull. Marque IsNull ou informe um valor.';
  _ERROR_VALUE_INCOMPATIBLE_ =
    'O valor do parâmetro SQL "%s" não é compatível com o tipo informado. Ajuste o valor ou o DataType.';
  _ERROR_REQUIRED_MISSING_ =
    'O parâmetro SQL obrigatório "%s" não foi informado. Adicione o parâmetro com o mesmo nome usado no SQL.';

class function TRickSQLCoreParameterScanner.CurrentChar(
  const AContext: TRickSQLParameterScanContext): Char;
begin
  Result := #0;
  if AContext.Index <= Length(AContext.SQL) then
    Result := AContext.SQL[AContext.Index];
end;

class function TRickSQLCoreParameterScanner.NextChar(
  const AContext: TRickSQLParameterScanContext): Char;
begin
  Result := #0;
  if AContext.Index < Length(AContext.SQL) then
    Result := AContext.SQL[AContext.Index + 1];
end;

class function TRickSQLCoreParameterScanner.IsNameStart(
  const AChar: Char): Boolean;
begin
  Result := CharInSet(AChar, ['A'..'Z', 'a'..'z', '_']);
end;

class function TRickSQLCoreParameterScanner.IsNamePart(
  const AChar: Char): Boolean;
begin
  Result := IsNameStart(AChar) or CharInSet(AChar, ['0'..'9', '$']);
end;

class function TRickSQLCoreParameterScanner.CanReadParameter(
  const AContext: TRickSQLParameterScanContext): Boolean;
begin
  Result := (NextChar(AContext) <> '=') and IsNameStart(NextChar(AContext));
end;

class function TRickSQLCoreParameterScanner.TryStartComment(
  var AContext: TRickSQLParameterScanContext): Boolean;
begin
  Result := True;
  if (CurrentChar(AContext) = '-') and (NextChar(AContext) = '-') then
    AContext.Mode := TRickSQLParameterScanMode.LineComment
  else if (CurrentChar(AContext) = '/') and (NextChar(AContext) = '*') then
    AContext.Mode := TRickSQLParameterScanMode.BlockComment
  else
    Exit(False);
  Inc(AContext.Index, 2);
end;

class function TRickSQLCoreParameterScanner.TryStartQuote(
  var AContext: TRickSQLParameterScanContext): Boolean;
begin
  Result := True;
  if CurrentChar(AContext) = '''' then
    AContext.Mode := TRickSQLParameterScanMode.SingleQuote
  else if CurrentChar(AContext) = '"' then
    AContext.Mode := TRickSQLParameterScanMode.DoubleQuote
  else
    Exit(False);
  Inc(AContext.Index);
end;

class function TRickSQLCoreParameterScanner.TrySkipTypeCast(
  var AContext: TRickSQLParameterScanContext): Boolean;
begin
  Result := (CurrentChar(AContext) = ':') and (NextChar(AContext) = ':');
  if Result then
    Inc(AContext.Index, 2);
end;

class procedure TRickSQLCoreParameterScanner.ReadParameter(
  var AContext: TRickSQLParameterScanContext);
var
  LStart: Integer;
  LName: string;
begin
  if not CanReadParameter(AContext) then
  begin
    Inc(AContext.Index);
    Exit;
  end;
  LStart := AContext.Index + 1;
  AContext.Index := LStart;
  while IsNamePart(CurrentChar(AContext)) do
    Inc(AContext.Index);
  LName := Copy(AContext.SQL, LStart, AContext.Index - LStart);
  if AContext.Names.IndexOf(LName) < 0 then
    AContext.Names.Add(LName);
end;

class procedure TRickSQLCoreParameterScanner.ProcessNormal(
  var AContext: TRickSQLParameterScanContext);
begin
  if TryStartComment(AContext) then
    Exit;
  if TryStartQuote(AContext) then
    Exit;
  if TrySkipTypeCast(AContext) then
    Exit;
  if CurrentChar(AContext) = ':' then
  begin
    ReadParameter(AContext);
    Exit;
  end;
  Inc(AContext.Index);
end;

class procedure TRickSQLCoreParameterScanner.ProcessSingleQuote(
  var AContext: TRickSQLParameterScanContext);
begin
  if (CurrentChar(AContext) = '''') and (NextChar(AContext) = '''') then
  begin
    Inc(AContext.Index, 2);
    Exit;
  end;
  if CurrentChar(AContext) = '''' then
    AContext.Mode := TRickSQLParameterScanMode.Normal;
  Inc(AContext.Index);
end;

class procedure TRickSQLCoreParameterScanner.ProcessDoubleQuote(
  var AContext: TRickSQLParameterScanContext);
begin
  if (CurrentChar(AContext) = '"') and (NextChar(AContext) = '"') then
  begin
    Inc(AContext.Index, 2);
    Exit;
  end;
  if CurrentChar(AContext) = '"' then
    AContext.Mode := TRickSQLParameterScanMode.Normal;
  Inc(AContext.Index);
end;

class procedure TRickSQLCoreParameterScanner.ProcessLineComment(
  var AContext: TRickSQLParameterScanContext);
begin
  if CharInSet(CurrentChar(AContext), [#10, #13]) then
    AContext.Mode := TRickSQLParameterScanMode.Normal;
  Inc(AContext.Index);
end;

class procedure TRickSQLCoreParameterScanner.ProcessBlockComment(
  var AContext: TRickSQLParameterScanContext);
begin
  if (CurrentChar(AContext) = '*') and (NextChar(AContext) = '/') then
  begin
    AContext.Mode := TRickSQLParameterScanMode.Normal;
    Inc(AContext.Index, 2);
    Exit;
  end;
  Inc(AContext.Index);
end;

class procedure TRickSQLCoreParameterScanner.Process(
  var AContext: TRickSQLParameterScanContext);
begin
  case AContext.Mode of
    TRickSQLParameterScanMode.Normal: ProcessNormal(AContext);
    TRickSQLParameterScanMode.SingleQuote: ProcessSingleQuote(AContext);
    TRickSQLParameterScanMode.DoubleQuote: ProcessDoubleQuote(AContext);
    TRickSQLParameterScanMode.LineComment: ProcessLineComment(AContext);
    TRickSQLParameterScanMode.BlockComment: ProcessBlockComment(AContext);
  end;
end;

class procedure TRickSQLCoreParameterScanner.Extract(const ASQL: string;
  const ANames: TStrings);
var
  LContext: TRickSQLParameterScanContext;
begin
  if not Assigned(ANames) then
    Exit;

  ANames.Clear;
  LContext.SQL := ASQL;
  LContext.Names := ANames;
  LContext.Index := 1;
  LContext.Mode := TRickSQLParameterScanMode.Normal;
  while LContext.Index <= Length(LContext.SQL) do
    Process(LContext);
end;

class function TRickSQLCoreParameterValidator.Fail(
  const AMessage: string; out AError: TRickSQLError): Boolean;
begin
  AError := TRickSQLError.Create(TRickSQLErrorKind.Validation, AMessage);
  AError.Operation := _OPERATION_;
  Result := False;
end;

function IsValidParameterName(const AName: string): Boolean;
var
  LIndex: Integer;
begin
  Result := AName <> '';
  if not Result then
    Exit;
  if not TRickSQLCoreParameterScanner.IsNameStart(AName[1]) then
    Exit(False);
  for LIndex := 2 to Length(AName) do
    if not TRickSQLCoreParameterScanner.IsNamePart(AName[LIndex]) then
      Exit(False);
end;

function SupportsSize(const ADataType: TFieldType): Boolean;
begin
  Result := ADataType in [ftString, ftBytes, ftVarBytes, ftBlob, ftMemo,
    ftGraphic, ftFmtMemo, ftFixedChar, ftWideString, ftOraBlob, ftOraClob,
    ftFixedWideChar, ftWideMemo];
end;

function IsSupportedDataType(const ADataType: TFieldType): Boolean;
begin
  Result := not (ADataType in [ftCursor, ftADT, ftArray, ftReference,
    ftDataSet, ftInterface, ftIDispatch, ftConnection, ftParams]);
end;

function IsStringDataType(const ADataType: TFieldType): Boolean;
begin
  Result := ADataType in [ftString, ftMemo, ftFmtMemo, ftFixedChar,
    ftWideString, ftOraClob, ftFixedWideChar, ftWideMemo, ftGuid];
end;

function IsNumericDataType(const ADataType: TFieldType): Boolean;
begin
  Result := ADataType in [ftSmallint, ftInteger, ftWord, ftFloat,
    ftCurrency, ftBCD, ftAutoInc, ftLargeint, ftFMTBcd, ftLongWord,
    ftShortint, ftByte, ftExtended];
end;

function IsDateDataType(const ADataType: TFieldType): Boolean;
begin
  Result := ADataType in [ftDate, ftTime, ftDateTime, ftTimeStamp,
    ftOraTimeStamp];
end;

function IsValueCompatible(const AParameter: TRickSQLParameter): Boolean;
begin
  if AParameter.IsNull or (AParameter.DataType = ftUnknown) then
    Exit(True);
  if IsStringDataType(AParameter.DataType) then
    Exit(VarIsStr(AParameter.Value));
  if IsNumericDataType(AParameter.DataType) then
    Exit(VarIsNumeric(AParameter.Value));
  if AParameter.DataType = ftBoolean then
    Exit((VarType(AParameter.Value) and varTypeMask) = varBoolean);
  if IsDateDataType(AParameter.DataType) then
    Exit((VarType(AParameter.Value) and varTypeMask) = varDate);
  Result := True;
end;

function FindParameterIndex(const ACommand: TRickSQLCommand;
  const AName: string): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  for LIndex := 0 to Length(ACommand.Parameters) - 1 do
    if SameText(Trim(ACommand.Parameters[LIndex].Name), AName) then
      Exit(LIndex);
end;

function HasDuplicateParameter(const ACommand: TRickSQLCommand;
  const AIndex: Integer): Boolean;
var
  LPrevious: Integer;
  LName: string;
begin
  Result := False;
  LName := Trim(ACommand.Parameters[AIndex].Name);
  for LPrevious := 0 to AIndex - 1 do
    if SameText(LName, Trim(ACommand.Parameters[LPrevious].Name)) then
      Exit(True);
end;

function ValidateSize(const AParameter: TRickSQLParameter;
  var AMessage: string): Boolean;
begin
  Result := True;
  if AParameter.Size < 0 then
  begin
    AMessage := Format(_ERROR_SIZE_INVALID_, [AParameter.Name]);
    Exit(False);
  end;
  if (AParameter.Size > 0) and not SupportsSize(AParameter.DataType) then
  begin
    AMessage := Format(_ERROR_SIZE_UNSUPPORTED_, [AParameter.Name]);
    Exit(False);
  end;
end;

function ValidateDirection(const AParameter: TRickSQLParameter;
  var AMessage: string): Boolean;
begin
  Result := True;
  if AParameter.Direction <> ptInput then
  begin
    AMessage := Format(_ERROR_DIRECTION_UNSUPPORTED_, [AParameter.Name]);
    Exit(False);
  end;
end;

function ValidateDataType(const AParameter: TRickSQLParameter;
  var AMessage: string): Boolean;
begin
  Result := True;
  if not IsSupportedDataType(AParameter.DataType) then
  begin
    AMessage := Format(_ERROR_TYPE_UNSUPPORTED_, [AParameter.Name]);
    Exit(False);
  end;
end;

function ValidateNullConsistency(const AParameter: TRickSQLParameter;
  var AMessage: string): Boolean;
begin
  Result := True;
  if AParameter.IsNull and (AParameter.DataType = ftUnknown) then
  begin
    AMessage := Format(_ERROR_NULL_TYPE_REQUIRED_, [AParameter.Name]);
    Exit(False);
  end;
  if not AParameter.IsNull and
    (VarIsNull(AParameter.Value) or VarIsEmpty(AParameter.Value)) then
  begin
    AMessage := Format(_ERROR_NULL_INCONSISTENT_, [AParameter.Name]);
    Exit(False);
  end;
end;

function ValidateParameterDefinition(const AParameter: TRickSQLParameter;
  out AMessage: string): Boolean;
begin
  AMessage := '';
  Result :=
    ValidateSize(AParameter, AMessage) and
    ValidateDirection(AParameter, AMessage) and
    ValidateDataType(AParameter, AMessage) and
    ValidateNullConsistency(AParameter, AMessage);
end;

class function TRickSQLCoreParameterValidator.ValidateParameterNames(
  const ACommand: TRickSQLCommand;
  out AError: TRickSQLError): Boolean;
var
  LIndex: Integer;
  LName: string;
begin
  for LIndex := 0 to Length(ACommand.Parameters) - 1 do
  begin
    LName := Trim(ACommand.Parameters[LIndex].Name);
    if LName = '' then
      Exit(Fail(_ERROR_NAME_EMPTY_, AError));
    if not IsValidParameterName(LName) then
      Exit(Fail(Format(_ERROR_NAME_INVALID_, [LName]), AError));
    if HasDuplicateParameter(ACommand, LIndex) then
      Exit(Fail(Format(_ERROR_NAME_DUPLICATE_, [LName]), AError));
  end;
  Result := True;
end;

class function TRickSQLCoreParameterValidator.ValidateParameterValues(
  const ACommand: TRickSQLCommand;
  out AError: TRickSQLError): Boolean;
var
  LParameter: TRickSQLParameter;
  LMessage: string;
begin
  for LParameter in ACommand.Parameters do
  begin
    if not ValidateParameterDefinition(LParameter, LMessage) then
      Exit(Fail(LMessage, AError));
    if not IsValueCompatible(LParameter) then
      Exit(Fail(Format(_ERROR_VALUE_INCOMPATIBLE_,
        [LParameter.Name]), AError));
  end;
  Result := True;
end;

class function TRickSQLCoreParameterValidator.ValidateRequiredParameters(
  const ACommand: TRickSQLCommand;
  out AError: TRickSQLError): Boolean;
var
  LNames: TStringList;
  LName: string;
begin
  LNames := TStringList.Create;
  try
    LNames.CaseSensitive := False;
    TRickSQLCoreParameterScanner.Extract(ACommand.Text, LNames);
    for LName in LNames do
      if FindParameterIndex(ACommand, LName) < 0 then
        Exit(Fail(Format(_ERROR_REQUIRED_MISSING_, [LName]), AError));
    Result := True;
  finally
    LNames.Free;
  end;
end;

class function TRickSQLCoreParameterValidator.Validate(
  const ACommand: TRickSQLCommand;
  out AError: TRickSQLError): Boolean;
begin
  AError := TRickSQLError.Empty;
  if not ValidateParameterNames(ACommand, AError) then
    Exit(False);
  if not ValidateParameterValues(ACommand, AError) then
    Exit(False);
  Result := ValidateRequiredParameters(ACommand, AError);
end;

end.
