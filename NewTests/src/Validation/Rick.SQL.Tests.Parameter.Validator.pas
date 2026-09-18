unit Rick.SQL.Tests.Parameter.Validator;

interface

uses
  TestFramework,
  Rick.SQL.Model.Types;

type
  TRickSQLParameterValidatorTests = class(TTestCase)
  private
    procedure CheckValid(const AEngine: TRickSQLDatabaseEngine;
      const ASQL: string; const AParameterNames: array of string);
    procedure CheckMissing(const AEngine: TRickSQLDatabaseEngine;
      const ASQL: string; const AMissingName: string);
    procedure CheckMissingWithParameters(const AEngine: TRickSQLDatabaseEngine;
      const ASQL, AMissingName: string;
      const AParameterNames: array of string);
  published
    procedure TodosEngines_ParametroSimples_DeveSerReconhecido;
    procedure TodosEngines_ParametroAposKeyword_DeveSerReconhecido;
    procedure ParametroSimplesAusente_DeveFalhar;
    procedure MultiplosParametros_DevemSerReconhecidos;
    procedure ParametroRepetido_DeveAceitarUmaUnicaDefinicao;
    procedure NomeDeParametro_DeveSerCaseInsensitive;
    procedure ParametroExtra_DevePreservarContratoDoValidadorCore;
    procedure StringComDoisPontos_NaoDeveCriarParametro;
    procedure StringComAspasEscapadas_NaoDeveCriarParametro;
    procedure IdentificadorComAspasDuplas_NaoDeveCriarParametro;
    procedure ComentarioDeLinha_NaoDeveCriarParametro;
    procedure ComentarioDeBloco_NaoDeveCriarParametro;
    procedure PostgreSQL_TypeCast_NaoDeveCriarParametro;
    procedure PostgreSQL_DollarQuote_NaoDeveCriarParametro;
    procedure PostgreSQL_DollarQuoteSemTag_NaoDeveCriarParametro;
    procedure PostgreSQL_EscapeString_NaoDeveCriarParametro;
    procedure PostgreSQL_ComentarioDeBlocoAninhado_NaoDeveCriarParametro;
    procedure PostgreSQL_DollarQuote_DevePreservarParametroRealExterno;
    procedure PostgreSQL_ArraySlice_NaoDeveOcultarParametroReal;
    procedure PostgreSQL_ArraySliceSemLimiteInferior_NaoDeveCriarParametro;
    procedure PostgreSQL_ParametroEmSubscrito_DeveSerReconhecido;
    procedure PostgreSQL_ParametroAposEspaco_DeveSerReconhecido;
    procedure Firebird_QQuote_NaoDeveCriarParametro;
    procedure Firebird_ArrayComLimitesExplicitos_NaoDeveCriarParametro;
    procedure Firebird_ArrayElement_ComParametro_DeveReconhecerParametro;
    procedure Firebird_LabelPSQL_NaoDeveCriarParametro;
    procedure Firebird_ExecuteBlock_VariavelPSQL_NaoDeveCriarParametro;
    procedure Firebird_ExecuteBlock_ParametroExterno_DeveSerReconhecido;
    procedure Firebird_StoredProcedure_VariavelPSQL_NaoDeveCriarParametro;
    procedure InterBase_StoredProcedure_VariavelPSQL_NaoDeveCriarParametro;
    procedure InterBase_ArraySlice_NaoDeveCriarParametro;
    procedure SQLServer_IdentificadorComColchetes_NaoDeveCriarParametro;
    procedure SQLServer_Label_NaoDeveCriarParametro;
    procedure SQLServer_ParametroAdjacenteAKeyword_DeveSerReconhecido;
    procedure SQLServer_JSONObject_SeparadorColon_NaoDeveCriarParametro;
    procedure SQLServer_JSONObject_ParametroNoValor_DeveSerReconhecido;
    procedure SQLServer_JSONObject_ParametroEmExpressao_DeveSerReconhecido;
    procedure SQLServer_JSONObject_Aninhado_NaoDeveCriarParametro;
    procedure SQLServer_JSONObject_Aninhado_DevePreservarParametroReal;
    procedure SQLServer_ComentarioDeBlocoAninhado_NaoDeveCriarParametro;
    procedure MySQL_IdentificadorComBacktick_NaoDeveCriarParametro;
    procedure MySQL_StringComEscapeBackslash_NaoDeveCriarParametro;
    procedure MySQL_ComentarioHash_NaoDeveCriarParametro;
    procedure MySQL_DoisHifensSemEspaco_NaoDevemOcultarParametroReal;
    procedure MySQL_DoisHifensComEspaco_DevemIniciarComentario;
    procedure MySQL_Label_NaoDeveCriarParametro;
    procedure MySQL_ParametroAdjacenteAKeyword_DeveSerReconhecido;
    procedure SQLite_IdentificadorComColchetes_NaoDeveCriarParametro;
    procedure SQLite_IdentificadorComBacktick_NaoDeveCriarParametro;
    procedure Oracle_QQuote_NaoDeveCriarParametro;
    procedure Oracle_NQQuote_NaoDeveCriarParametro;
    procedure Oracle_AtribuicaoPLSQL_NaoDeveCriarParametro;
    procedure Oracle_JSONObject_SeparadorColon_NaoDeveOcultarParametroReal;
    procedure Oracle_JSONObject_ParametroNoValor_DeveSerReconhecido;
    procedure Oracle_JSONObject_ParametrosNaChaveEValor_DevemSerReconhecidos;
    procedure Oracle_JSONObject_ParametroEmExpressao_DeveSerReconhecido;
    procedure Oracle_Trigger_Pseudoregistros_NaoDevemCriarParametros;
    procedure DB2_Label_NaoDeveCriarParametro;
    procedure DB2_ParametroAdjacenteAKeyword_DeveSerReconhecido;
    procedure SQLAnywhere_IdentificadorComColchetes_NaoDeveCriarParametro;
    procedure SQLAnywhere_Label_NaoDeveCriarParametro;
    procedure SQLAnywhere_ParametroAdjacenteAKeyword_DeveSerReconhecido;
    procedure SQLAnywhere_ComentarioDeBlocoAninhado_NaoDeveCriarParametro;
    procedure SQLAnywhere_ComentarioDoubleSlash_NaoDeveCriarParametro;
    procedure Informix_SeparadorDeCatalogo_NaoDeveCriarParametro;
    procedure Informix_SeparadorDeCatalogoRemoto_NaoDeveCriarParametro;
    procedure Informix_QualificacaoDeColuna_NaoDeveCriarParametro;
    procedure Informix_ParametroAdjacenteAKeyword_DeveSerReconhecido;
    procedure Access_IdentificadorComColchetes_NaoDeveCriarParametro;
    procedure Access_LiteralDataHora_NaoDeveCriarParametro;
  end;

implementation

uses
  System.SysUtils,
  Rick.SQL.Core.Parameter.Validator,
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Error,
  Rick.SQL.Model.Parameter;

procedure TRickSQLParameterValidatorTests.CheckValid(
  const AEngine: TRickSQLDatabaseEngine; const ASQL: string;
  const AParameterNames: array of string);
var
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
  LName: string;
begin
  LCommand := TRickSQLCommand.Create(
    TRickSQLConnectionOptions.Create(AEngine), ASQL);
  for LName in AParameterNames do
    LCommand.AddParameter(TRickSQLParameter.Create(LName, 1));

  Check(TRickSQLCoreParameterValidator.Validate(LCommand, LError),
    LError.Message);
end;

procedure TRickSQLParameterValidatorTests.CheckMissing(
  const AEngine: TRickSQLDatabaseEngine; const ASQL: string;
  const AMissingName: string);
begin
  CheckMissingWithParameters(AEngine, ASQL, AMissingName, []);
end;

procedure TRickSQLParameterValidatorTests.CheckMissingWithParameters(
  const AEngine: TRickSQLDatabaseEngine; const ASQL, AMissingName: string;
  const AParameterNames: array of string);
var
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
  LName: string;
begin
  LCommand := TRickSQLCommand.Create(
    TRickSQLConnectionOptions.Create(AEngine), ASQL);
  for LName in AParameterNames do
    LCommand.AddParameter(TRickSQLParameter.Create(LName, 1));
  Check(not TRickSQLCoreParameterValidator.Validate(LCommand, LError),
    'A validação deveria identificar o parâmetro SQL ausente.');
  Check(LError.Kind = TRickSQLErrorKind.Validation,
    'O parâmetro ausente deveria produzir erro de validação.');
  Check(Pos(AMissingName, LError.Message) > 0,
    'A mensagem deveria identificar o parâmetro SQL ausente.');
end;

procedure TRickSQLParameterValidatorTests.TodosEngines_ParametroSimples_DeveSerReconhecido;
var
  LEngine: TRickSQLDatabaseEngine;
begin
  for LEngine := TRickSQLDatabaseEngine.Firebird to TRickSQLDatabaseEngine.ODBC do
    CheckValid(LEngine, 'SELECT * FROM T WHERE ID = :ID', ['ID']);
end;

procedure TRickSQLParameterValidatorTests.TodosEngines_ParametroAposKeyword_DeveSerReconhecido;
var
  LEngine: TRickSQLDatabaseEngine;
begin
  for LEngine := TRickSQLDatabaseEngine.Firebird to TRickSQLDatabaseEngine.ODBC do
    CheckMissing(LEngine, 'SELECT :ID', 'ID');
end;

procedure TRickSQLParameterValidatorTests.ParametroSimplesAusente_DeveFalhar;
begin
  CheckMissing(TRickSQLDatabaseEngine.SQLite,
    'SELECT * FROM T WHERE ID = :ID', 'ID');
end;

procedure TRickSQLParameterValidatorTests.MultiplosParametros_DevemSerReconhecidos;
begin
  CheckMissingWithParameters(TRickSQLDatabaseEngine.SQLite,
    'SELECT * FROM T WHERE ID = :ID AND STATUS = :STATUS',
    'STATUS', ['ID']);
  CheckValid(TRickSQLDatabaseEngine.SQLite,
    'SELECT * FROM T WHERE ID = :ID AND STATUS = :STATUS',
    ['ID', 'STATUS']);
end;

procedure TRickSQLParameterValidatorTests.ParametroRepetido_DeveAceitarUmaUnicaDefinicao;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLite,
    'SELECT * FROM T WHERE ID = :ID OR PARENT_ID = :ID', ['ID']);
end;

procedure TRickSQLParameterValidatorTests.NomeDeParametro_DeveSerCaseInsensitive;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLite,
    'SELECT * FROM T WHERE ID = :Id', ['id']);
end;

procedure TRickSQLParameterValidatorTests.ParametroExtra_DevePreservarContratoDoValidadorCore;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLite, 'SELECT 1', ['EXTRA']);
end;

procedure TRickSQLParameterValidatorTests.StringComDoisPontos_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLite,
    'SELECT '':NOT_A_PARAMETER''', []);
end;

procedure TRickSQLParameterValidatorTests.StringComAspasEscapadas_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLite,
    'SELECT ''It''''s :NOT_A_PARAMETER''', []);
end;

procedure TRickSQLParameterValidatorTests.IdentificadorComAspasDuplas_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLite,
    'SELECT "FIELD:NAME" FROM T', []);
end;

procedure TRickSQLParameterValidatorTests.ComentarioDeLinha_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLite,
    'SELECT 1 -- :NOT_A_PARAMETER' + sLineBreak + 'FROM T', []);
end;

procedure TRickSQLParameterValidatorTests.ComentarioDeBloco_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLite,
    'SELECT /* :NOT_A_PARAMETER */ 1 FROM T', []);
end;

procedure TRickSQLParameterValidatorTests.PostgreSQL_TypeCast_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.PostgreSQL,
    'SELECT CURRENT_TIMESTAMP::timestamp', []);
end;

procedure TRickSQLParameterValidatorTests.PostgreSQL_DollarQuote_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.PostgreSQL,
    'SELECT $rick$texto :NOT_A_PARAMETER '' interno$rick$', []);
end;

procedure TRickSQLParameterValidatorTests.PostgreSQL_DollarQuoteSemTag_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.PostgreSQL,
    'SELECT $$texto :NOT_A_PARAMETER$$', []);
end;

procedure TRickSQLParameterValidatorTests.PostgreSQL_EscapeString_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.PostgreSQL,
    'SELECT E''It\''s :NOT_A_PARAMETER''', []);
end;

procedure TRickSQLParameterValidatorTests.PostgreSQL_ComentarioDeBlocoAninhado_NaoDeveCriarParametro;
begin
  CheckMissing(TRickSQLDatabaseEngine.PostgreSQL,
    'SELECT /* outer /* inner */ :NOT_A_PARAMETER */ :ID', 'ID');
end;

procedure TRickSQLParameterValidatorTests.PostgreSQL_DollarQuote_DevePreservarParametroRealExterno;
begin
  CheckMissing(TRickSQLDatabaseEngine.PostgreSQL,
    'SELECT $rick$:NOT_A_PARAMETER$rick$, :ID', 'ID');
end;

procedure TRickSQLParameterValidatorTests.PostgreSQL_ArraySlice_NaoDeveOcultarParametroReal;
begin
  CheckMissing(TRickSQLDatabaseEngine.PostgreSQL,
    'SELECT schedule[1:array_length(schedule, 1)] FROM sal_emp WHERE ID = :ID', 'ID');
end;

procedure TRickSQLParameterValidatorTests.PostgreSQL_ArraySliceSemLimiteInferior_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.PostgreSQL,
    'SELECT schedule[:array_length(schedule, 1)] FROM sal_emp', []);
end;

procedure TRickSQLParameterValidatorTests.PostgreSQL_ParametroEmSubscrito_DeveSerReconhecido;
begin
  CheckMissing(TRickSQLDatabaseEngine.PostgreSQL,
    'SELECT schedule[(:IDX)] FROM sal_emp', 'IDX');
end;

procedure TRickSQLParameterValidatorTests.PostgreSQL_ParametroAposEspaco_DeveSerReconhecido;
begin
  CheckMissing(TRickSQLDatabaseEngine.PostgreSQL, 'SELECT :ID', 'ID');
end;

procedure TRickSQLParameterValidatorTests.Firebird_QQuote_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.Firebird,
    'SELECT q''[It''s :NOT_A_PARAMETER]'' FROM RDB$DATABASE', []);
end;

procedure TRickSQLParameterValidatorTests.Firebird_ArrayComLimitesExplicitos_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.Firebird,
    'CREATE TABLE T (ID INTEGER, VALUES_ARRAY INTEGER[0:3])', []);
end;

procedure TRickSQLParameterValidatorTests.Firebird_ArrayElement_ComParametro_DeveReconhecerParametro;
begin
  CheckMissing(TRickSQLDatabaseEngine.Firebird,
    'SELECT VALUES_ARRAY[:IDX] FROM T', 'IDX');
end;

procedure TRickSQLParameterValidatorTests.Firebird_LabelPSQL_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.Firebird,
    'EXECUTE BLOCK AS BEGIN LOOP_A:WHILE (1 = 0) DO BEGIN END END', []);
end;

procedure TRickSQLParameterValidatorTests.Firebird_ExecuteBlock_VariavelPSQL_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.Firebird,
    'EXECUTE BLOCK AS DECLARE VARIABLE V INTEGER; BEGIN V = 1; ' +
    'IF (:V = 1) THEN V = V + 1; END', []);
end;

procedure TRickSQLParameterValidatorTests.Firebird_ExecuteBlock_ParametroExterno_DeveSerReconhecido;
begin
  CheckMissing(TRickSQLDatabaseEngine.Firebird,
    'EXECUTE BLOCK (P INTEGER = :INPUT) AS BEGIN P = P + 1; END', 'INPUT');
end;

procedure TRickSQLParameterValidatorTests.Firebird_StoredProcedure_VariavelPSQL_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.Firebird,
    'CREATE PROCEDURE P (P_ID INTEGER) AS BEGIN ' +
    'UPDATE T SET X = 1 WHERE ID = :P_ID; END', []);
end;

procedure TRickSQLParameterValidatorTests.InterBase_StoredProcedure_VariavelPSQL_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.InterBase,
    'CREATE PROCEDURE P (P_ID INTEGER) AS BEGIN ' +
    'UPDATE T SET X = 1 WHERE ID = :P_ID; END', []);
end;

procedure TRickSQLParameterValidatorTests.InterBase_ArraySlice_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.InterBase,
    'SELECT JOB_TITLE[2:4] FROM EMPLOYEE', []);
end;

procedure TRickSQLParameterValidatorTests.SQLServer_IdentificadorComColchetes_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLServer,
    'SELECT [FIELD:NAME] FROM T', []);
end;

procedure TRickSQLParameterValidatorTests.SQLServer_Label_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLServer,
    'RetryLabel:SELECT 1', []);
end;

procedure TRickSQLParameterValidatorTests.SQLServer_ParametroAdjacenteAKeyword_DeveSerReconhecido;
begin
  CheckMissing(TRickSQLDatabaseEngine.SQLServer,
    'SELECT CASE WHEN 1 = 1 THEN:ID ELSE 0 END', 'ID');
end;

procedure TRickSQLParameterValidatorTests.SQLServer_JSONObject_SeparadorColon_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLServer,
    'SELECT JSON_OBJECT(''name'':FIRST_NAME)', []);
end;

procedure TRickSQLParameterValidatorTests.SQLServer_JSONObject_ParametroEmExpressao_DeveSerReconhecido;
begin
  CheckMissing(TRickSQLDatabaseEngine.SQLServer,
    'SELECT JSON_OBJECT(''id'': CASE WHEN 1 = 1 THEN:ID ELSE 0 END)', 'ID');
end;

procedure TRickSQLParameterValidatorTests.SQLServer_JSONObject_Aninhado_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLServer,
    'SELECT JSON_OBJECT(''outer'': JSON_OBJECT(''inner'':1))', []);
end;

procedure TRickSQLParameterValidatorTests.SQLServer_JSONObject_Aninhado_DevePreservarParametroReal;
begin
  CheckMissing(TRickSQLDatabaseEngine.SQLServer,
    'SELECT JSON_OBJECT(''outer'': JSON_OBJECT(''inner'': :ID))', 'ID');
end;

procedure TRickSQLParameterValidatorTests.SQLServer_ComentarioDeBlocoAninhado_NaoDeveCriarParametro;
begin
  CheckMissing(TRickSQLDatabaseEngine.SQLServer,
    'SELECT /* outer /* inner */ :NOT_A_PARAMETER */ :ID', 'ID');
end;

procedure TRickSQLParameterValidatorTests.SQLServer_JSONObject_ParametroNoValor_DeveSerReconhecido;
begin
  CheckMissing(TRickSQLDatabaseEngine.SQLServer,
    'SELECT JSON_OBJECT(''id'': :ID)', 'ID');
end;

procedure TRickSQLParameterValidatorTests.MySQL_IdentificadorComBacktick_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.MySQL,
    'SELECT `FIELD:NAME` FROM T', []);
end;

procedure TRickSQLParameterValidatorTests.MySQL_StringComEscapeBackslash_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.MySQL,
    'SELECT ''It\''s :NOT_A_PARAMETER''', []);
end;

procedure TRickSQLParameterValidatorTests.MySQL_ComentarioHash_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.MySQL,
    'SELECT 1 # :NOT_A_PARAMETER' + sLineBreak + 'FROM T', []);
end;

procedure TRickSQLParameterValidatorTests.MySQL_DoisHifensSemEspaco_NaoDevemOcultarParametroReal;
begin
  CheckMissing(TRickSQLDatabaseEngine.MySQL,
    'SELECT BALANCE--1, :ID FROM ACCOUNT', 'ID');
end;

procedure TRickSQLParameterValidatorTests.MySQL_DoisHifensComEspaco_DevemIniciarComentario;
begin
  CheckValid(TRickSQLDatabaseEngine.MySQL,
    'SELECT 1 -- :NOT_A_PARAMETER' + sLineBreak + 'FROM T', []);
end;

procedure TRickSQLParameterValidatorTests.MySQL_Label_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.MySQL,
    'CREATE PROCEDURE P() label1:BEGIN SELECT 1; END label1', []);
end;

procedure TRickSQLParameterValidatorTests.MySQL_ParametroAdjacenteAKeyword_DeveSerReconhecido;
begin
  CheckMissing(TRickSQLDatabaseEngine.MySQL,
    'SELECT CASE WHEN 1 = 1 THEN:ID ELSE 0 END', 'ID');
end;

procedure TRickSQLParameterValidatorTests.SQLite_IdentificadorComColchetes_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLite,
    'SELECT [FIELD:NAME] FROM T', []);
end;

procedure TRickSQLParameterValidatorTests.SQLite_IdentificadorComBacktick_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLite,
    'SELECT `FIELD:NAME` FROM T', []);
end;

procedure TRickSQLParameterValidatorTests.Oracle_QQuote_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.Oracle,
    'SELECT q''[It''s :NOT_A_PARAMETER]'' FROM dual', []);
end;

procedure TRickSQLParameterValidatorTests.Oracle_NQQuote_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.Oracle,
    'SELECT nq''[It''s :NOT_A_PARAMETER]'' FROM dual', []);
end;

procedure TRickSQLParameterValidatorTests.Oracle_AtribuicaoPLSQL_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.Oracle,
    'DECLARE V NUMBER; BEGIN V := 1; END;', []);
end;

procedure TRickSQLParameterValidatorTests.Oracle_JSONObject_SeparadorColon_NaoDeveOcultarParametroReal;
begin
  CheckMissing(TRickSQLDatabaseEngine.Oracle,
    'SELECT JSON_OBJECT(''name'':FIRST_NAME) FROM EMPLOYEES WHERE ID = :ID',
    'ID');
end;

procedure TRickSQLParameterValidatorTests.Oracle_JSONObject_ParametroNoValor_DeveSerReconhecido;
begin
  CheckMissing(TRickSQLDatabaseEngine.Oracle,
    'SELECT JSON_OBJECT(''id'': :ID) FROM dual', 'ID');
end;

procedure TRickSQLParameterValidatorTests.Oracle_JSONObject_ParametrosNaChaveEValor_DevemSerReconhecidos;
begin
  CheckMissingWithParameters(TRickSQLDatabaseEngine.Oracle,
    'SELECT JSON_OBJECT(:KEY_NAME: :VALUE) FROM dual', 'KEY_NAME', ['VALUE']);
  CheckMissingWithParameters(TRickSQLDatabaseEngine.Oracle,
    'SELECT JSON_OBJECT(:KEY_NAME: :VALUE) FROM dual', 'VALUE', ['KEY_NAME']);
end;

procedure TRickSQLParameterValidatorTests.Oracle_JSONObject_ParametroEmExpressao_DeveSerReconhecido;
begin
  CheckMissing(TRickSQLDatabaseEngine.Oracle,
    'SELECT JSON_OBJECT(''id'': CASE WHEN 1 = 1 THEN:ID ELSE 0 END) FROM dual',
    'ID');
end;

procedure TRickSQLParameterValidatorTests.Oracle_Trigger_Pseudoregistros_NaoDevemCriarParametros;
begin
  CheckValid(TRickSQLDatabaseEngine.Oracle,
    'CREATE OR REPLACE TRIGGER T_BIU BEFORE UPDATE ON T FOR EACH ROW ' +
    'BEGIN :NEW.UPDATED_AT := SYSTIMESTAMP; ' +
    'IF :OLD.ID <> :NEW.ID THEN NULL; END IF; END;', []);
end;

procedure TRickSQLParameterValidatorTests.DB2_Label_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.DB2,
    'CREATE PROCEDURE RICKSQL_P() LANGUAGE SQL L1:BEGIN ATOMIC ' +
    'SIGNAL SQLSTATE ''70000''; END L1', []);
end;

procedure TRickSQLParameterValidatorTests.DB2_ParametroAdjacenteAKeyword_DeveSerReconhecido;
begin
  CheckMissing(TRickSQLDatabaseEngine.DB2,
    'VALUES CASE WHEN 1 = 1 THEN:ID ELSE 0 END', 'ID');
end;

procedure TRickSQLParameterValidatorTests.SQLAnywhere_IdentificadorComColchetes_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLAnywhere,
    'SELECT [FIELD:NAME] FROM T', []);
end;

procedure TRickSQLParameterValidatorTests.SQLAnywhere_Label_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.SQLAnywhere,
    'L1:BEGIN SELECT 1; END L1', []);
end;

procedure TRickSQLParameterValidatorTests.SQLAnywhere_ParametroAdjacenteAKeyword_DeveSerReconhecido;
begin
  CheckMissing(TRickSQLDatabaseEngine.SQLAnywhere,
    'SELECT CASE WHEN 1 = 1 THEN:ID ELSE 0 END', 'ID');
end;

procedure TRickSQLParameterValidatorTests.SQLAnywhere_ComentarioDeBlocoAninhado_NaoDeveCriarParametro;
begin
  CheckMissing(TRickSQLDatabaseEngine.SQLAnywhere,
    'SELECT /* outer /* inner */ :NOT_A_PARAMETER */ :ID', 'ID');
end;

procedure TRickSQLParameterValidatorTests.SQLAnywhere_ComentarioDoubleSlash_NaoDeveCriarParametro;
begin
  CheckMissing(TRickSQLDatabaseEngine.SQLAnywhere,
    'SELECT 1 // :NOT_A_PARAMETER' + sLineBreak + 'WHERE ID = :ID', 'ID');
end;

procedure TRickSQLParameterValidatorTests.Informix_SeparadorDeCatalogo_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.Informix,
    'SELECT name FROM salesdb:contacts', []);
end;

procedure TRickSQLParameterValidatorTests.Informix_SeparadorDeCatalogoRemoto_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.Informix,
    'SELECT name FROM salesdb@distantserver:contacts', []);
end;

procedure TRickSQLParameterValidatorTests.Informix_QualificacaoDeColuna_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.Informix,
    'SELECT salesdb:contacts.name FROM salesdb:contacts', []);
end;

procedure TRickSQLParameterValidatorTests.Informix_ParametroAdjacenteAKeyword_DeveSerReconhecido;
begin
  CheckMissing(TRickSQLDatabaseEngine.Informix,
    'SELECT CASE WHEN 1 = 1 THEN:ID ELSE 0 END', 'ID');
end;

procedure TRickSQLParameterValidatorTests.Access_IdentificadorComColchetes_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.Access,
    'SELECT [FIELD:NAME] FROM T', []);
end;

procedure TRickSQLParameterValidatorTests.Access_LiteralDataHora_NaoDeveCriarParametro;
begin
  CheckValid(TRickSQLDatabaseEngine.Access,
    'SELECT * FROM T WHERE CREATED_AT >= #9/18/2026 12:30:00 PM# ' +
    'AND ID = :ID', ['ID']);
end;

initialization
  RegisterTest(TRickSQLParameterValidatorTests.Suite);

end.
