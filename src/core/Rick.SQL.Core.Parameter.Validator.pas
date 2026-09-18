unit Rick.SQL.Core.Parameter.Validator;

// Responsabilidade: validar os parâmetros e identificá-los conforme o engine do comando SQL.
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
  System.StrUtils,
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
    Delimited,
    LineComment,
    BlockComment
  );

  TRickSQLJSONObjectScanState = record
    Depth: Integer;
    SeparatorRead: Boolean;
  end;

  TRickSQLJSONObjectScanStates = array of TRickSQLJSONObjectScanState;

  TRickSQLParameterScanContext = record
    SQL: string;
    Names: TStrings;
    Engine: TRickSQLDatabaseEngine;
    Index: Integer;
    Mode: TRickSQLParameterScanMode;
    Delimiter: string;
    EscapeDoubled: Boolean;
    EscapeBackslash: Boolean;
    BlockDepth: Integer;
    BracketDepth: Integer;
    ParenthesisDepth: Integer;
    JSONObjects: TRickSQLJSONObjectScanStates;
    JSONObjectPending: Boolean;
    PSQLBlockBody: Boolean;
  end;

  TRickSQLCoreParameterScanner = class
  private
    class function CharacterAt(const AContext: TRickSQLParameterScanContext;
      const AOffset: Integer): Char; static;
    class function CurrentChar(
      const AContext: TRickSQLParameterScanContext): Char; static;
    class function NextChar(
      const AContext: TRickSQLParameterScanContext): Char; static;
    class function PreviousSignificantChar(
      const AContext: TRickSQLParameterScanContext): Char; static;
    class function IsNameStart(const AChar: Char): Boolean; static;
    class function IsNamePart(const AChar: Char): Boolean; static;
    class function StartsAt(const AContext: TRickSQLParameterScanContext;
      const AText: string): Boolean; static;
    class function StartsKeyword(const AContext: TRickSQLParameterScanContext;
      const AKeyword: string): Boolean; static;
    class function CanReadParameter(
      const AContext: TRickSQLParameterScanContext): Boolean; static;
    class function SupportsBracketIdentifier(
      const AEngine: TRickSQLDatabaseEngine): Boolean; static;
    class function SupportsBacktickIdentifier(
      const AEngine: TRickSQLDatabaseEngine): Boolean; static;
    class function SupportsAlternativeQuote(
      const AEngine: TRickSQLDatabaseEngine): Boolean; static;
    class function AlternativeQuoteClosing(
      const AOpening: Char): Char; static;
    class function SupportsArraySlice(
      const AEngine: TRickSQLDatabaseEngine): Boolean; static;
    class function SupportsJSONColon(
      const AEngine: TRickSQLDatabaseEngine): Boolean; static;
    class function SupportsNestedBlockComment(
      const AEngine: TRickSQLDatabaseEngine): Boolean; static;
    class function NextSignificantWord(
      const AContext: TRickSQLParameterScanContext): string; static;
    class function TokenStartBeforeColon(
      const AContext: TRickSQLParameterScanContext): Integer; static;
    class function PreviousWordBeforeToken(
      const AContext: TRickSQLParameterScanContext): string; static;
    class function IsSQLServerLabelColon(
      const AContext: TRickSQLParameterScanContext): Boolean; static;
    class function IsStructuredLabelColon(
      const AContext: TRickSQLParameterScanContext): Boolean; static;
    class function IsLabelColon(
      const AContext: TRickSQLParameterScanContext): Boolean; static;
    class function IsInformixCatalogColon(
      const AContext: TRickSQLParameterScanContext): Boolean; static;
    class function IsQualifiedToken(
      const AContext: TRickSQLParameterScanContext;
      const AToken: string): Boolean; static;
    class function IsOraclePseudoRecord(
      const AContext: TRickSQLParameterScanContext): Boolean; static;
    class function IsArraySliceColon(
      const AContext: TRickSQLParameterScanContext): Boolean; static;
    class function IsJSONObjectSeparator(
      const AContext: TRickSQLParameterScanContext): Boolean; static;
    class procedure MarkJSONObjectSeparator(
      var AContext: TRickSQLParameterScanContext); static;
    class procedure PushJSONObject(
      var AContext: TRickSQLParameterScanContext); static;
    class procedure PopJSONObject(
      var AContext: TRickSQLParameterScanContext); static;
    class function TryTrackJSONObjectComma(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class function IsMySQLDashComment(
      const AContext: TRickSQLParameterScanContext): Boolean; static;
    class procedure BeginDelimited(var AContext: TRickSQLParameterScanContext;
      const ADelimiter: string; const AOpeningLength: Integer;
      const AEscapeDoubled, AEscapeBackslash: Boolean); static;
    class procedure StartLineComment(var AContext: TRickSQLParameterScanContext;
      const AOpeningLength: Integer); static;
    class function TryStartLineComment(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class function TryStartComment(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class function AlternativeQuoteOpeningOffset(
      const AContext: TRickSQLParameterScanContext): Integer; static;
    class function TryStartAlternativeQuote(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class function TryStartPostgreSQLEscapeString(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class function FindDollarQuoteEnd(
      const AContext: TRickSQLParameterScanContext): Integer; static;
    class function IsDollarQuoteTagValid(
      const AContext: TRickSQLParameterScanContext;
      const AEndIndex: Integer): Boolean; static;
    class function TryStartDollarQuote(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class function TryStartQuoteOrIdentifier(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class function TryStartDelimitedSyntax(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class function TryStartJSONObject(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class function TryTrackParenthesis(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class function TryTrackArrayBracket(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class function TryTrackStructure(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class function TryEnterPSQLBlockBody(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class function TrySkipDialectColon(
      var AContext: TRickSQLParameterScanContext): Boolean; static;
    class procedure ProcessColon(
      var AContext: TRickSQLParameterScanContext); static;
    class procedure ProcessNormal(
      var AContext: TRickSQLParameterScanContext); static;
    class procedure ProcessDelimited(
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
    class procedure Extract(const AEngine: TRickSQLDatabaseEngine;
      const ASQL: string; const ANames: TStrings); static;
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

class function TRickSQLCoreParameterScanner.CharacterAt(
  const AContext: TRickSQLParameterScanContext;
  const AOffset: Integer): Char;
var
  LIndex: Integer;
begin
  Result := #0;
  LIndex := AContext.Index + AOffset;
  if (LIndex >= 1) and (LIndex <= Length(AContext.SQL)) then
    Result := AContext.SQL[LIndex];
end;

class function TRickSQLCoreParameterScanner.CurrentChar(
  const AContext: TRickSQLParameterScanContext): Char;
begin
  Result := CharacterAt(AContext, 0);
end;

class function TRickSQLCoreParameterScanner.NextChar(
  const AContext: TRickSQLParameterScanContext): Char;
begin
  Result := CharacterAt(AContext, 1);
end;

class function TRickSQLCoreParameterScanner.PreviousSignificantChar(
  const AContext: TRickSQLParameterScanContext): Char;
var
  LOffset: Integer;
begin
  LOffset := -1;
  Result := CharacterAt(AContext, LOffset);
  while (Result <> #0) and (Ord(Result) <= 32) do
  begin
    Dec(LOffset);
    Result := CharacterAt(AContext, LOffset);
  end;
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

class function TRickSQLCoreParameterScanner.StartsAt(
  const AContext: TRickSQLParameterScanContext;
  const AText: string): Boolean;
begin
  Result := (AText <> '') and
    (Copy(AContext.SQL, AContext.Index, Length(AText)) = AText);
end;

class function TRickSQLCoreParameterScanner.StartsKeyword(
  const AContext: TRickSQLParameterScanContext;
  const AKeyword: string): Boolean;
begin
  Result := SameText(Copy(AContext.SQL, AContext.Index, Length(AKeyword)),
    AKeyword);
  if not Result then
    Exit;
  Result := not IsNamePart(CharacterAt(AContext, -1)) and
    not IsNamePart(CharacterAt(AContext, Length(AKeyword)));
end;

class function TRickSQLCoreParameterScanner.CanReadParameter(
  const AContext: TRickSQLParameterScanContext): Boolean;
begin
  Result := (NextChar(AContext) <> '=') and IsNameStart(NextChar(AContext));
end;

class function TRickSQLCoreParameterScanner.SupportsBracketIdentifier(
  const AEngine: TRickSQLDatabaseEngine): Boolean;
begin
  Result := AEngine in [TRickSQLDatabaseEngine.SQLServer,
    TRickSQLDatabaseEngine.SQLite, TRickSQLDatabaseEngine.SQLAnywhere,
    TRickSQLDatabaseEngine.Access];
end;

class function TRickSQLCoreParameterScanner.SupportsBacktickIdentifier(
  const AEngine: TRickSQLDatabaseEngine): Boolean;
begin
  Result := AEngine in [TRickSQLDatabaseEngine.MySQL,
    TRickSQLDatabaseEngine.SQLite, TRickSQLDatabaseEngine.SQLAnywhere];
end;

class function TRickSQLCoreParameterScanner.SupportsAlternativeQuote(
  const AEngine: TRickSQLDatabaseEngine): Boolean;
begin
  Result := AEngine in [TRickSQLDatabaseEngine.Firebird,
    TRickSQLDatabaseEngine.Oracle];
end;

class function TRickSQLCoreParameterScanner.AlternativeQuoteClosing(
  const AOpening: Char): Char;
const
  _OPENING_DELIMITERS_ = '[{(<';
  _CLOSING_DELIMITERS_ = ']})>';
var
  LIndex: Integer;
begin
  LIndex := Pos(AOpening, _OPENING_DELIMITERS_);
  if LIndex > 0 then
    Exit(_CLOSING_DELIMITERS_[LIndex]);
  Result := AOpening;
end;

class function TRickSQLCoreParameterScanner.SupportsArraySlice(
  const AEngine: TRickSQLDatabaseEngine): Boolean;
begin
  Result := AEngine in [TRickSQLDatabaseEngine.Firebird,
    TRickSQLDatabaseEngine.InterBase, TRickSQLDatabaseEngine.PostgreSQL];
end;

class function TRickSQLCoreParameterScanner.SupportsJSONColon(
  const AEngine: TRickSQLDatabaseEngine): Boolean;
begin
  Result := AEngine in [TRickSQLDatabaseEngine.SQLServer,
    TRickSQLDatabaseEngine.Oracle];
end;

class function TRickSQLCoreParameterScanner.SupportsNestedBlockComment(
  const AEngine: TRickSQLDatabaseEngine): Boolean;
begin
  Result := AEngine in [TRickSQLDatabaseEngine.PostgreSQL,
    TRickSQLDatabaseEngine.SQLServer, TRickSQLDatabaseEngine.SQLAnywhere];
end;

class function TRickSQLCoreParameterScanner.NextSignificantWord(
  const AContext: TRickSQLParameterScanContext): string;
var
  LIndex: Integer;
  LStart: Integer;
begin
  LIndex := AContext.Index + 1;
  while (LIndex <= Length(AContext.SQL)) and
    (Ord(AContext.SQL[LIndex]) <= 32) do
    Inc(LIndex);
  LStart := LIndex;
  while (LIndex <= Length(AContext.SQL)) and
    IsNamePart(AContext.SQL[LIndex]) do
    Inc(LIndex);
  Result := Copy(AContext.SQL, LStart, LIndex - LStart);
end;

class function TRickSQLCoreParameterScanner.TokenStartBeforeColon(
  const AContext: TRickSQLParameterScanContext): Integer;
begin
  Result := AContext.Index - 1;
  while (Result > 0) and IsNamePart(AContext.SQL[Result]) do
    Dec(Result);
  Inc(Result);
end;

class function TRickSQLCoreParameterScanner.PreviousWordBeforeToken(
  const AContext: TRickSQLParameterScanContext): string;
var
  LIndex: Integer;
  LEnd: Integer;
begin
  LIndex := TokenStartBeforeColon(AContext) - 1;
  while (LIndex > 0) and (Ord(AContext.SQL[LIndex]) <= 32) do
    Dec(LIndex);
  LEnd := LIndex;
  while (LIndex > 0) and IsNamePart(AContext.SQL[LIndex]) do
    Dec(LIndex);
  Result := Copy(AContext.SQL, LIndex + 1, LEnd - LIndex);
end;

class function TRickSQLCoreParameterScanner.IsSQLServerLabelColon(
  const AContext: TRickSQLParameterScanContext): Boolean;
var
  LIndex: Integer;
  LPreviousWord: string;
begin
  LIndex := TokenStartBeforeColon(AContext) - 1;
  while (LIndex > 0) and CharInSet(AContext.SQL[LIndex], [' ', #9]) do
    Dec(LIndex);
  if (LIndex = 0) or CharInSet(AContext.SQL[LIndex], [';', #10, #13]) then
    Exit(True);
  LPreviousWord := PreviousWordBeforeToken(AContext);
  Result := MatchText(LPreviousWord, ['BEGIN', 'ELSE']);
end;

class function TRickSQLCoreParameterScanner.IsStructuredLabelColon(
  const AContext: TRickSQLParameterScanContext): Boolean;
var
  LNextWord: string;
begin
  LNextWord := NextSignificantWord(AContext);
  case AContext.Engine of
    TRickSQLDatabaseEngine.MySQL:
      Result := MatchText(LNextWord, ['BEGIN', 'LOOP', 'REPEAT', 'WHILE']);
    TRickSQLDatabaseEngine.DB2:
      Result := MatchText(LNextWord, ['BEGIN', 'FOR', 'IF', 'LOOP', 'REPEAT',
        'WHILE', 'SET', 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'MERGE',
        'SIGNAL', 'RESIGNAL', 'RETURN', 'CALL']);
    TRickSQLDatabaseEngine.SQLAnywhere:
      Result := MatchText(LNextWord,
        ['BEGIN', 'FOR', 'IF', 'CASE', 'LOOP', 'WHILE', 'TRY']);
  else
    Result := False;
  end;
end;

class function TRickSQLCoreParameterScanner.IsLabelColon(
  const AContext: TRickSQLParameterScanContext): Boolean;
begin
  Result := IsNamePart(CharacterAt(AContext, -1));
  if not Result then
    Exit;
  if AContext.Engine = TRickSQLDatabaseEngine.SQLServer then
    Exit(IsSQLServerLabelColon(AContext));
  Result := IsStructuredLabelColon(AContext);
end;

class function TRickSQLCoreParameterScanner.IsInformixCatalogColon(
  const AContext: TRickSQLParameterScanContext): Boolean;
var
  LIndex: Integer;
  LPreviousWord: string;
begin
  Result := AContext.Engine = TRickSQLDatabaseEngine.Informix;
  Result := Result and IsNamePart(CharacterAt(AContext, -1)) and
    IsNameStart(NextChar(AContext));
  if not Result then
    Exit;
  LIndex := AContext.Index + 1;
  while (LIndex <= Length(AContext.SQL)) and IsNamePart(AContext.SQL[LIndex]) do
    Inc(LIndex);
  if (LIndex <= Length(AContext.SQL)) and (AContext.SQL[LIndex] = '.') then
    Exit(True);
  LIndex := TokenStartBeforeColon(AContext) - 1;
  while (LIndex > 0) and (Ord(AContext.SQL[LIndex]) <= 32) do
    Dec(LIndex);
  if (LIndex > 0) and CharInSet(AContext.SQL[LIndex], ['@', ',']) then
    Exit(True);
  LPreviousWord := PreviousWordBeforeToken(AContext);
  Result := MatchText(LPreviousWord, ['FROM', 'JOIN', 'INTO', 'UPDATE',
    'TABLE', 'REFERENCES', 'USING', 'PROCEDURE', 'FUNCTION', 'SYNONYM',
    'VIEW']);
end;

class function TRickSQLCoreParameterScanner.IsQualifiedToken(
  const AContext: TRickSQLParameterScanContext;
  const AToken: string): Boolean;
begin
  Result := SameText(Copy(AContext.SQL, AContext.Index + 1, Length(AToken)),
    AToken) and (CharacterAt(AContext, Length(AToken) + 1) = '.');
end;

class function TRickSQLCoreParameterScanner.IsOraclePseudoRecord(
  const AContext: TRickSQLParameterScanContext): Boolean;
begin
  Result := AContext.Engine = TRickSQLDatabaseEngine.Oracle;
  if not Result then
    Exit;
  if IsQualifiedToken(AContext, 'NEW') then
    Exit(True);
  if IsQualifiedToken(AContext, 'OLD') then
    Exit(True);
  Result := IsQualifiedToken(AContext, 'PARENT');
end;

class function TRickSQLCoreParameterScanner.IsArraySliceColon(
  const AContext: TRickSQLParameterScanContext): Boolean;
var
  LPrevious: Char;
begin
  Result := SupportsArraySlice(AContext.Engine) and
    (AContext.BracketDepth > 0);
  if not Result then
    Exit;
  LPrevious := PreviousSignificantChar(AContext);
  if LPrevious = '[' then
    Exit(AContext.Engine = TRickSQLDatabaseEngine.PostgreSQL);
  Result := IsNamePart(LPrevious) or CharInSet(LPrevious,
    ['''', '"', ')', ']']);
end;

class function TRickSQLCoreParameterScanner.IsJSONObjectSeparator(
  const AContext: TRickSQLParameterScanContext): Boolean;
var
  LCount: Integer;
  LPrevious: Char;
begin
  LCount := Length(AContext.JSONObjects);
  Result := SupportsJSONColon(AContext.Engine) and (LCount > 0);
  if not Result then
    Exit;
  Result := AContext.JSONObjects[LCount - 1].Depth = AContext.ParenthesisDepth;
  Result := Result and not AContext.JSONObjects[LCount - 1].SeparatorRead;
  if not Result then
    Exit;
  LPrevious := PreviousSignificantChar(AContext);
  Result := IsNamePart(LPrevious) or CharInSet(LPrevious,
    ['''', '"', ')', ']']);
end;

class procedure TRickSQLCoreParameterScanner.MarkJSONObjectSeparator(
  var AContext: TRickSQLParameterScanContext);
var
  LIndex: Integer;
begin
  LIndex := Length(AContext.JSONObjects) - 1;
  if LIndex >= 0 then
    AContext.JSONObjects[LIndex].SeparatorRead := True;
end;

class procedure TRickSQLCoreParameterScanner.PushJSONObject(
  var AContext: TRickSQLParameterScanContext);
var
  LIndex: Integer;
begin
  LIndex := Length(AContext.JSONObjects);
  SetLength(AContext.JSONObjects, LIndex + 1);
  AContext.JSONObjects[LIndex].Depth := AContext.ParenthesisDepth;
  AContext.JSONObjects[LIndex].SeparatorRead := False;
end;

class procedure TRickSQLCoreParameterScanner.PopJSONObject(
  var AContext: TRickSQLParameterScanContext);
var
  LCount: Integer;
begin
  LCount := Length(AContext.JSONObjects);
  if (LCount > 0) and
    (AContext.JSONObjects[LCount - 1].Depth = AContext.ParenthesisDepth) then
    SetLength(AContext.JSONObjects, LCount - 1);
end;

class function TRickSQLCoreParameterScanner.TryTrackJSONObjectComma(
  var AContext: TRickSQLParameterScanContext): Boolean;
var
  LIndex: Integer;
begin
  Result := CurrentChar(AContext) = ',';
  LIndex := Length(AContext.JSONObjects) - 1;
  Result := Result and (LIndex >= 0);
  if not Result then
    Exit;
  Result := AContext.JSONObjects[LIndex].Depth = AContext.ParenthesisDepth;
  if not Result then
    Exit;
  AContext.JSONObjects[LIndex].SeparatorRead := False;
  Inc(AContext.Index);
end;

class function TRickSQLCoreParameterScanner.IsMySQLDashComment(
  const AContext: TRickSQLParameterScanContext): Boolean;
var
  LAfterDash: Char;
begin
  if AContext.Engine <> TRickSQLDatabaseEngine.MySQL then
    Exit(True);
  LAfterDash := CharacterAt(AContext, 2);
  Result := (LAfterDash = #0) or (Ord(LAfterDash) <= 32);
end;

class procedure TRickSQLCoreParameterScanner.BeginDelimited(
  var AContext: TRickSQLParameterScanContext; const ADelimiter: string;
  const AOpeningLength: Integer;
  const AEscapeDoubled, AEscapeBackslash: Boolean);
begin
  AContext.Mode := TRickSQLParameterScanMode.Delimited;
  AContext.Delimiter := ADelimiter;
  AContext.EscapeDoubled := AEscapeDoubled;
  AContext.EscapeBackslash := AEscapeBackslash;
  Inc(AContext.Index, AOpeningLength);
end;

class procedure TRickSQLCoreParameterScanner.StartLineComment(
  var AContext: TRickSQLParameterScanContext; const AOpeningLength: Integer);
begin
  AContext.Mode := TRickSQLParameterScanMode.LineComment;
  Inc(AContext.Index, AOpeningLength);
end;

class function TRickSQLCoreParameterScanner.TryStartLineComment(
  var AContext: TRickSQLParameterScanContext): Boolean;
begin
  if StartsAt(AContext, '--') and IsMySQLDashComment(AContext) then
  begin
    StartLineComment(AContext, 2);
    Exit(True);
  end;
  if (AContext.Engine = TRickSQLDatabaseEngine.MySQL) and
    (CurrentChar(AContext) = '#') then
  begin
    StartLineComment(AContext, 1);
    Exit(True);
  end;
  Result := (AContext.Engine = TRickSQLDatabaseEngine.SQLAnywhere) and
    StartsAt(AContext, '//');
  if Result then
    StartLineComment(AContext, 2);
end;

class function TRickSQLCoreParameterScanner.TryStartComment(
  var AContext: TRickSQLParameterScanContext): Boolean;
begin
  if TryStartLineComment(AContext) then
    Exit(True);
  Result := StartsAt(AContext, '/*');
  if not Result then
    Exit;
  AContext.Mode := TRickSQLParameterScanMode.BlockComment;
  AContext.BlockDepth := 1;
  Inc(AContext.Index, 2);
end;

class function TRickSQLCoreParameterScanner.AlternativeQuoteOpeningOffset(
  const AContext: TRickSQLParameterScanContext): Integer;
begin
  Result := 0;
  if CharInSet(CurrentChar(AContext), ['q', 'Q']) and
    (NextChar(AContext) = '''') then
    Exit(2);
  if (AContext.Engine = TRickSQLDatabaseEngine.Oracle) and
    CharInSet(CurrentChar(AContext), ['n', 'N']) and
    CharInSet(NextChar(AContext), ['q', 'Q']) and
    (CharacterAt(AContext, 2) = '''') then
    Result := 3;
end;

class function TRickSQLCoreParameterScanner.TryStartAlternativeQuote(
  var AContext: TRickSQLParameterScanContext): Boolean;
var
  LOpeningOffset: Integer;
  LOpening: Char;
begin
  Result := SupportsAlternativeQuote(AContext.Engine) and
    not IsNamePart(CharacterAt(AContext, -1));
  if not Result then
    Exit;
  LOpeningOffset := AlternativeQuoteOpeningOffset(AContext);
  Result := LOpeningOffset > 0;
  if not Result then
    Exit;
  LOpening := CharacterAt(AContext, LOpeningOffset);
  if LOpening = #0 then
    Exit(False);
  BeginDelimited(AContext, AlternativeQuoteClosing(LOpening) + '''',
    LOpeningOffset + 1, False, False);
end;

class function TRickSQLCoreParameterScanner.TryStartPostgreSQLEscapeString(
  var AContext: TRickSQLParameterScanContext): Boolean;
begin
  Result := AContext.Engine = TRickSQLDatabaseEngine.PostgreSQL;
  Result := Result and CharInSet(CurrentChar(AContext), ['e', 'E']);
  Result := Result and (NextChar(AContext) = '''');
  Result := Result and not IsNamePart(CharacterAt(AContext, -1));
  if Result then
    BeginDelimited(AContext, '''', 2, True, True);
end;

class function TRickSQLCoreParameterScanner.FindDollarQuoteEnd(
  const AContext: TRickSQLParameterScanContext): Integer;
begin
  Result := AContext.Index + 1;
  while (Result <= Length(AContext.SQL)) and (AContext.SQL[Result] <> '$') do
    Inc(Result);
  if Result > Length(AContext.SQL) then
    Result := 0;
end;

class function TRickSQLCoreParameterScanner.IsDollarQuoteTagValid(
  const AContext: TRickSQLParameterScanContext;
  const AEndIndex: Integer): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := AContext.Index + 1 to AEndIndex - 1 do
  begin
    if (LIndex = AContext.Index + 1) and
      not IsNameStart(AContext.SQL[LIndex]) then
      Exit(False);
    if (LIndex > AContext.Index + 1) and
      not CharInSet(AContext.SQL[LIndex], ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
      Exit(False);
  end;
end;

class function TRickSQLCoreParameterScanner.TryStartDollarQuote(
  var AContext: TRickSQLParameterScanContext): Boolean;
var
  LEnd: Integer;
  LDelimiter: string;
begin
  Result := (AContext.Engine = TRickSQLDatabaseEngine.PostgreSQL) and
    (CurrentChar(AContext) = '$') and not IsNamePart(CharacterAt(AContext, -1));
  if not Result then
    Exit;
  LEnd := FindDollarQuoteEnd(AContext);
  Result := (LEnd > 0) and IsDollarQuoteTagValid(AContext, LEnd);
  if not Result then
    Exit;
  LDelimiter := Copy(AContext.SQL, AContext.Index,
    LEnd - AContext.Index + 1);
  BeginDelimited(AContext, LDelimiter, Length(LDelimiter), False, False);
end;

class function TRickSQLCoreParameterScanner.TryStartQuoteOrIdentifier(
  var AContext: TRickSQLParameterScanContext): Boolean;
var
  LChar: Char;
begin
  LChar := CurrentChar(AContext);
  if LChar = '''' then
    BeginDelimited(AContext, '''', 1, True,
      AContext.Engine = TRickSQLDatabaseEngine.MySQL)
  else if LChar = '"' then
    BeginDelimited(AContext, '"', 1, True,
      AContext.Engine = TRickSQLDatabaseEngine.MySQL)
  else if (LChar = '[') and SupportsBracketIdentifier(AContext.Engine) then
    BeginDelimited(AContext, ']', 1, True, False)
  else if (LChar = '`') and SupportsBacktickIdentifier(AContext.Engine) then
    BeginDelimited(AContext, '`', 1, True, False)
  else
    Exit(False);
  Result := True;
end;

class function TRickSQLCoreParameterScanner.TryStartDelimitedSyntax(
  var AContext: TRickSQLParameterScanContext): Boolean;
begin
  if TryStartAlternativeQuote(AContext) then
    Exit(True);
  if TryStartPostgreSQLEscapeString(AContext) then
    Exit(True);
  if TryStartDollarQuote(AContext) then
    Exit(True);
  Result := TryStartQuoteOrIdentifier(AContext);
end;

class function TRickSQLCoreParameterScanner.TryStartJSONObject(
  var AContext: TRickSQLParameterScanContext): Boolean;
const
  _JSON_OBJECT_ = 'JSON_OBJECT';
begin
  Result := SupportsJSONColon(AContext.Engine) and
    StartsKeyword(AContext, _JSON_OBJECT_);
  if not Result then
    Exit;
  AContext.JSONObjectPending := True;
  Inc(AContext.Index, Length(_JSON_OBJECT_));
end;

class function TRickSQLCoreParameterScanner.TryTrackParenthesis(
  var AContext: TRickSQLParameterScanContext): Boolean;
begin
  // Alterado de: CurrentChar(AContext) in ['(', ')']
  Result := CharInSet(CurrentChar(AContext), ['(', ')']);

  if not Result then
    Exit;

  if CurrentChar(AContext) = '(' then
  begin
    Inc(AContext.ParenthesisDepth);
    if AContext.JSONObjectPending then
      PushJSONObject(AContext);
  end
  else
  begin
    PopJSONObject(AContext);
    if AContext.ParenthesisDepth > 0 then
      Dec(AContext.ParenthesisDepth);
  end;

  AContext.JSONObjectPending := False;
  Inc(AContext.Index);
end;

class function TRickSQLCoreParameterScanner.TryTrackArrayBracket(
  var AContext: TRickSQLParameterScanContext): Boolean;
begin
  Result := SupportsArraySlice(AContext.Engine);
  if not Result then
    Exit;
  if CurrentChar(AContext) = '[' then
    Inc(AContext.BracketDepth)
  else if (CurrentChar(AContext) = ']') and (AContext.BracketDepth > 0) then
    Dec(AContext.BracketDepth)
  else
    Exit(False);
  Inc(AContext.Index);
end;

class function TRickSQLCoreParameterScanner.TryTrackStructure(
  var AContext: TRickSQLParameterScanContext): Boolean;
begin
  if AContext.JSONObjectPending and (Ord(CurrentChar(AContext)) <= 32) then
  begin
    Inc(AContext.Index);
    Exit(True);
  end;
  if TryTrackParenthesis(AContext) then
    Exit(True);
  if TryTrackJSONObjectComma(AContext) then
    Exit(True);
  AContext.JSONObjectPending := False;
  Result := TryTrackArrayBracket(AContext);
end;

class function TRickSQLCoreParameterScanner.TryEnterPSQLBlockBody(
  var AContext: TRickSQLParameterScanContext): Boolean;
begin
  Result := AContext.Engine in [TRickSQLDatabaseEngine.Firebird,
    TRickSQLDatabaseEngine.InterBase];
  Result := Result and not AContext.PSQLBlockBody and
    StartsKeyword(AContext, 'BEGIN');
  if not Result then
    Exit;
  AContext.PSQLBlockBody := True;
  Inc(AContext.Index, Length('BEGIN'));
end;

class function TRickSQLCoreParameterScanner.TrySkipDialectColon(
  var AContext: TRickSQLParameterScanContext): Boolean;
begin
  Result := CurrentChar(AContext) = ':';
  if not Result then
    Exit;
  if NextChar(AContext) = ':' then
  begin
    Inc(AContext.Index, 2);
    Exit;
  end;
  if IsJSONObjectSeparator(AContext) then
  begin
    MarkJSONObjectSeparator(AContext);
    Inc(AContext.Index);
    Exit(True);
  end;
  Result := AContext.PSQLBlockBody or IsOraclePseudoRecord(AContext) or
    IsArraySliceColon(AContext) or IsLabelColon(AContext) or
    IsInformixCatalogColon(AContext);
  if Result then
    Inc(AContext.Index);
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

class procedure TRickSQLCoreParameterScanner.ProcessColon(
  var AContext: TRickSQLParameterScanContext);
begin
  if CurrentChar(AContext) <> ':' then
  begin
    Inc(AContext.Index);
    Exit;
  end;
  if TrySkipDialectColon(AContext) then
    Exit;
  ReadParameter(AContext);
end;

class procedure TRickSQLCoreParameterScanner.ProcessNormal(
  var AContext: TRickSQLParameterScanContext);
begin
  if TryStartComment(AContext) then
    Exit;
  if TryStartDelimitedSyntax(AContext) then
    Exit;
  if TryStartJSONObject(AContext) then
    Exit;
  if TryTrackStructure(AContext) then
    Exit;
  if TryEnterPSQLBlockBody(AContext) then
    Exit;
  ProcessColon(AContext);
end;

class procedure TRickSQLCoreParameterScanner.ProcessDelimited(
  var AContext: TRickSQLParameterScanContext);
begin
  if AContext.EscapeBackslash and (CurrentChar(AContext) = '\') then
  begin
    Inc(AContext.Index, 2);
    Exit;
  end;
  if AContext.EscapeDoubled and StartsAt(AContext,
    AContext.Delimiter + AContext.Delimiter) then
  begin
    Inc(AContext.Index, Length(AContext.Delimiter) * 2);
    Exit;
  end;
  if StartsAt(AContext, AContext.Delimiter) then
  begin
    Inc(AContext.Index, Length(AContext.Delimiter));
    AContext.Mode := TRickSQLParameterScanMode.Normal;
    Exit;
  end;
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
  if SupportsNestedBlockComment(AContext.Engine) and
    StartsAt(AContext, '/*') then
  begin
    Inc(AContext.BlockDepth);
    Inc(AContext.Index, 2);
    Exit;
  end;
  if StartsAt(AContext, '*/') then
  begin
    Dec(AContext.BlockDepth);
    Inc(AContext.Index, 2);
    if AContext.BlockDepth = 0 then
      AContext.Mode := TRickSQLParameterScanMode.Normal;
    Exit;
  end;
  Inc(AContext.Index);
end;

class procedure TRickSQLCoreParameterScanner.Process(
  var AContext: TRickSQLParameterScanContext);
begin
  case AContext.Mode of
    TRickSQLParameterScanMode.Normal: ProcessNormal(AContext);
    TRickSQLParameterScanMode.Delimited: ProcessDelimited(AContext);
    TRickSQLParameterScanMode.LineComment: ProcessLineComment(AContext);
    TRickSQLParameterScanMode.BlockComment: ProcessBlockComment(AContext);
  end;
end;

class procedure TRickSQLCoreParameterScanner.Extract(
  const AEngine: TRickSQLDatabaseEngine; const ASQL: string;
  const ANames: TStrings);
var
  LContext: TRickSQLParameterScanContext;
begin
  if not Assigned(ANames) then
    Exit;

  ANames.Clear;
  LContext.SQL := ASQL;
  LContext.Names := ANames;
  LContext.Engine := AEngine;
  LContext.Index := 1;
  LContext.Mode := TRickSQLParameterScanMode.Normal;
  LContext.Delimiter := '';
  LContext.EscapeDoubled := False;
  LContext.EscapeBackslash := False;
  LContext.BlockDepth := 0;
  LContext.BracketDepth := 0;
  LContext.ParenthesisDepth := 0;
  SetLength(LContext.JSONObjects, 0);
  LContext.JSONObjectPending := False;
  LContext.PSQLBlockBody := False;
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
    TRickSQLCoreParameterScanner.Extract(ACommand.Connection.Engine,
      ACommand.Text, LNames);
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
