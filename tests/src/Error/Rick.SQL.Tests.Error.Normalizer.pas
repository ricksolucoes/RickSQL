unit Rick.SQL.Tests.Error.Normalizer;

interface

uses
  TestFramework,
  FireDAC.Comp.Client,
  Rick.SQL.Model.Error,
  System.SysUtils;

type
  TRickSQLErrorNormalizerTests = class(TTestCase)
  private
    procedure CheckSecretIsHidden(const AText: string; const AContext: string);
    function FireDACDBMSCode(const AException: Exception): Integer;
    procedure ConfigureSQLiteFailureScenario(const AConnection: TFDConnection;
      const AQuery: TFDQuery);
    function CaptureSQLiteDatabaseError(
      out ASourceDBMSCode: Integer): TRickSQLError;
  published
    procedure GenericException_PreservesContextAndSanitizesTechnicalDetail;
    procedure SensitiveKeys_AreMaskedInMessageAndTechnicalDetail;
    procedure CoreParser_UsesSharedNormalizationPolicy;
    procedure CoreParser_FromMessage_PreservesLegacyContract;
    procedure FireDACException_PreservesStructuredDBMSInformation;
    procedure SQLiteException_PreservesDBMSCodeProvidedByFireDAC;
  end;

implementation

uses
  // RTL
  FireDAC.Stan.Error,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteWrapper.Stat,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Error.Normalizer,
  Rick.SQL.Core.Error.Parser;

const
  _SECRET_ = 'unit-secret-value';
  _OPERATION_ = 'Teste de normalização';
  _MESSAGE_ = 'Falha contextual controlada.';
  _DBMS_CODE_ = 12345;

procedure TRickSQLErrorNormalizerTests.CheckSecretIsHidden(
  const AText: string; const AContext: string);
begin
  Check(Pos(_SECRET_, AText) = 0,
    AContext + ' expôs o valor sensível.');
end;


function TRickSQLErrorNormalizerTests.FireDACDBMSCode(
  const AException: Exception): Integer;
var
  LFDError: EFDDBEngineException;
begin
  Result := 0;
  if not (AException is EFDDBEngineException) then
    Exit;

  LFDError := EFDDBEngineException(AException);
  if LFDError.ErrorCount > 0 then
    Result := LFDError.Errors[0].ErrorCode;
end;


procedure TRickSQLErrorNormalizerTests.ConfigureSQLiteFailureScenario(
  const AConnection: TFDConnection; const AQuery: TFDQuery);
begin
  AConnection.DriverName := 'SQLite';
  AConnection.Params.Database := ':memory:';
  AConnection.Connected := True;
  AQuery.Connection := AConnection;
  AQuery.SQL.Text := 'select * from RICKSQL_TABLE_THAT_DOES_NOT_EXIST';
end;

function TRickSQLErrorNormalizerTests.CaptureSQLiteDatabaseError(
  out ASourceDBMSCode: Integer): TRickSQLError;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
  Result := TRickSQLError.Empty;
  ASourceDBMSCode := 0;
  LConnection := TFDConnection.Create(nil);
  LQuery := TFDQuery.Create(nil);
  try
    ConfigureSQLiteFailureScenario(LConnection, LQuery);
    try
      LQuery.Open;
    except
      on E: Exception do
      begin
        ASourceDBMSCode := FireDACDBMSCode(E);
        Result := TRickSQLErrorNormalizer.FromException(E,
          TRickSQLErrorKind.Command, _MESSAGE_, _OPERATION_);
      end;
    end;
    Check(Result.HasError, 'O cenário FireDAC deveria produzir exception.');
  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

procedure TRickSQLErrorNormalizerTests.GenericException_PreservesContextAndSanitizesTechnicalDetail;
var
  LException: Exception;
  LError: TRickSQLError;
begin
  LException := Exception.Create('Falha técnica Password=' + _SECRET_ +
    ';Database=teste');
  try
    LError := TRickSQLErrorNormalizer.FromException(LException,
      TRickSQLErrorKind.Connection, _MESSAGE_, _OPERATION_);
  finally
    LException.Free;
  end;

  Check(LError.HasError, 'A falha deveria estar marcada como erro.');
  Check(LError.Kind = TRickSQLErrorKind.Connection, 'Kind foi alterado.');
  CheckEquals(_MESSAGE_, LError.Message, 'Message contextual foi alterada.');
  CheckEquals(_OPERATION_, LError.Operation, 'Operation foi alterada.');
  Check(LError.Message <> LError.TechnicalDetail,
    'Message e TechnicalDetail não devem representar a mesma informação.');
  CheckSecretIsHidden(LError.TechnicalDetail, 'TechnicalDetail');
  Check(Pos('***', LError.TechnicalDetail) > 0,
    'TechnicalDetail deveria conter a máscara de segurança.');
  CheckEquals(0, LError.DBMSCode,
    'Exception genérica não deve receber DBMSCode inventado.');
  CheckEquals('', LError.SQLState,
    'Exception genérica não deve receber SQLState inventado.');
end;

procedure TRickSQLErrorNormalizerTests.SensitiveKeys_AreMaskedInMessageAndTechnicalDetail;
var
  LError: TRickSQLError;
  LText: string;
begin
  LText := 'Password=' + _SECRET_ + ';PWD=' + _SECRET_ + ';Pass=' + _SECRET_ +
    ';Senha=' + _SECRET_ + ';User Password=' + _SECRET_ +
    ';User_Password=' + _SECRET_;

  LError := TRickSQLErrorNormalizer.FromDetail(TRickSQLErrorKind.Connection,
    LText, LText, _OPERATION_);

  CheckSecretIsHidden(LError.Message, 'Message');
  CheckSecretIsHidden(LError.TechnicalDetail, 'TechnicalDetail');
  Check(Pos('***', LError.Message) > 0, 'Message deveria ser sanitizada.');
  Check(Pos('***', LError.TechnicalDetail) > 0,
    'TechnicalDetail deveria ser sanitizado.');
end;

procedure TRickSQLErrorNormalizerTests.CoreParser_UsesSharedNormalizationPolicy;
var
  LException: Exception;
  LError: TRickSQLError;
begin
  LException := Exception.Create('PWD=' + _SECRET_ + ';Falha controlada');
  try
    LError := TRickSQLCoreErrorParser.FromException(LException,
      TRickSQLErrorKind.Command, _OPERATION_);
  finally
    LException.Free;
  end;

  Check(LError.HasError, 'O parser deveria produzir erro.');
  Check(LError.Kind = TRickSQLErrorKind.Command, 'Kind incorreto no parser.');
  CheckEquals(_OPERATION_, LError.Operation, 'Operation incorreta no parser.');
  Check(LError.Message <> LError.TechnicalDetail,
    'O parser deve manter mensagem funcional separada do detalhe técnico.');
  CheckSecretIsHidden(LError.TechnicalDetail, 'Parser TechnicalDetail');
end;

procedure TRickSQLErrorNormalizerTests.CoreParser_FromMessage_PreservesLegacyContract;
var
  LError: TRickSQLError;
begin
  LError := TRickSQLCoreErrorParser.FromMessage(TRickSQLErrorKind.Connection,
    'Password=' + _SECRET_ + ';Database=teste', _OPERATION_);

  Check(LError.HasError, 'FromMessage deveria produzir erro.');
  Check(LError.Kind = TRickSQLErrorKind.Connection, 'Kind incorreto.');
  CheckEquals(_OPERATION_, LError.Operation, 'Operation incorreta.');
  Check(LError.Message <> LError.TechnicalDetail,
    'Mensagem funcional e detalhe técnico devem permanecer separados.');
  CheckSecretIsHidden(LError.TechnicalDetail, 'FromMessage TechnicalDetail');
end;

procedure TRickSQLErrorNormalizerTests.FireDACException_PreservesStructuredDBMSInformation;
var
  LException: EFDDBEngineException;
  LError: TRickSQLError;
begin
  LException := EFDDBEngineException.Create;
  try
    LException.Append(TFDDBError.Create(1, _DBMS_CODE_,
      'Falha FireDAC Password=' + _SECRET_, '', ekOther, -1, -1));
    LError := TRickSQLErrorNormalizer.FromException(LException,
      TRickSQLErrorKind.Command, _MESSAGE_, _OPERATION_);
  finally
    LException.Free;
  end;

  Check(LError.HasError, 'A exception FireDAC deveria produzir erro.');
  CheckEquals(_DBMS_CODE_, LError.DBMSCode,
    'DBMSCode informado pelo FireDAC não foi preservado.');
  CheckSecretIsHidden(LError.TechnicalDetail, 'FireDAC TechnicalDetail');
  CheckEquals('', LError.SQLState,
    'TFDDBError genérico não deve receber SQLState inventado.');
end;

procedure TRickSQLErrorNormalizerTests.SQLiteException_PreservesDBMSCodeProvidedByFireDAC;
var
  LSourceDBMSCode: Integer;
  LError: TRickSQLError;
begin
  LError := CaptureSQLiteDatabaseError(LSourceDBMSCode);

  Check(LError.HasError, 'A exception SQLite deveria produzir erro.');
  CheckEquals(LSourceDBMSCode, LError.DBMSCode,
    'O DBMSCode normalizado difere do valor fornecido pelo FireDAC.');
  CheckEquals('', LError.SQLState,
    'SQLite não deve receber SQLState inventado pelo normalizador.');
end;

initialization
  RegisterTest(TRickSQLErrorNormalizerTests.Suite);

end.
