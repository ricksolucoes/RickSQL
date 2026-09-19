unit Rick.SQL.Tests.Transaction;

interface

uses
  // DUnit
  TestFramework,

  // FireDAC
  FireDAC.Comp.Client,
  FireDAC.Phys.Intf,

  // RickSQL
  Rick.SQL.Model.Error;

type
  TRickSQLTransactionTests = class(TTestCase)
  private
    FConnection: TFDConnection;
    FPhysConnection: IFDPhysConnection;
    FOriginalTransaction: IFDPhysTransaction;
    procedure StartPhysicalTransaction;
    procedure ForceActiveInspectionFailure;
    procedure RestorePhysicalTransaction;
    procedure ReleaseFireDACFixture;
    procedure ArmActiveInspectionFailure(Sender: TObject);
    procedure RaiseStartFailure(Sender: TObject);
    procedure RaiseCommitFailure(Sender: TObject);
    procedure RaiseRollbackFailure(Sender: TObject);
    procedure CheckTransactionError(const AError: TRickSQLError;
      const AExpectedDetail: string);
    procedure CheckInspectionError(const AError: TRickSQLError);
    procedure CheckPrimaryErrorPreserved(const AError: TRickSQLError;
      const ASecondaryDetail: string);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Active_TransacaoAtiva_DeveRetornarTrue;
    procedure Active_TransacaoInativa_DeveRetornarFalse;
    procedure Active_ConexaoNil_DevePreservarContratoFalse;
    procedure Active_FalhaDeInspecao_DevePreservarContratoFalse;
    procedure Start_TransacaoAtiva_DevePreservarComportamentoAtual;
    procedure Start_TransacaoInativa_DeveIniciar;
    procedure Start_FalhaAoConsultarEstado_NaoDeveRetornarSucesso;
    procedure Start_FalhaNaInspecaoAposInicio_DeveReportarErro;
    procedure Start_ExceptionDuranteStart_DeveReportarErro;
    procedure Commit_TransacaoAtiva_DeveFinalizar;
    procedure Commit_TransacaoInativa_DevePreservarComportamentoAtual;
    procedure Commit_FalhaAoConsultarEstado_NaoDeveRetornarSucesso;
    procedure Commit_FalhaNaInspecaoAposCommit_DeveReportarErro;
    procedure Commit_ExceptionDuranteCommit_DeveReportarErro;
    procedure Rollback_TransacaoAtiva_DeveFinalizar;
    procedure Rollback_TransacaoInativa_DevePreservarComportamentoAtual;
    procedure Rollback_FalhaAoConsultarEstado_NaoDeveRetornarSucesso;
    procedure Rollback_FalhaNaInspecaoAposRollback_DeveReportarErro;
    procedure Rollback_ExceptionDuranteRollback_DeveReportarErro;
    procedure RollbackAfterFailure_TransacaoAtiva_DevePreservarErroPrimario;
    procedure RollbackAfterFailure_TransacaoInativa_DevePreservarErroPrimario;
    procedure RollbackAfterFailure_FalhaNaInspecao_NaoDeveDescartarDiagnostico;
    procedure RollbackAfterFailure_FalhaNoRollback_NaoDeveDescartarDiagnostico;
    procedure UseTransactionFalse_NaoDeveIntroduzirErroTransacional;
  end;

implementation

uses
  // RTL
  System.SysUtils,
  System.IOUtils,

  // FireDAC
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteWrapper.Stat,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Model.Types,
  Rick.SQL.Service.FireDAC.Transaction;

const
  _INSPECTION_DETAIL_PREFIX_ = 'Falha ao consultar InTransaction:';
  _CONTROLLED_START_FAILURE_ = 'falha-controlada-start';
  _CONTROLLED_COMMIT_FAILURE_ = 'falha-controlada-commit';
  _CONTROLLED_ROLLBACK_FAILURE_ = 'falha-controlada-rollback';
  _INSPECTION_ERROR_MESSAGE_ =
    'Não foi possível determinar o estado da transação do banco de dados.';
  _PRIMARY_MESSAGE_ = 'Falha primária controlada.';
  _PRIMARY_OPERATION_ = 'Execução primária controlada';
  _PRIMARY_DETAIL_ = 'detalhe-primario-controlado';

procedure TRickSQLTransactionTests.SetUp;
begin
  inherited;
  FConnection := TFDConnection.Create(nil);
  FConnection.LoginPrompt := False;
  FConnection.DriverName := 'SQLite';
  FConnection.Params.Database := ':memory:';
  FConnection.Connected := True;
  FPhysConnection := FConnection.ConnectionIntf;
  FOriginalTransaction := FPhysConnection.Transaction;
  Check(Assigned(FOriginalTransaction),
    'O FireDAC deveria fornecer a transação física padrão do SQLite.');
end;

procedure TRickSQLTransactionTests.TearDown;
begin
  ReleaseFireDACFixture;
  inherited;
end;

procedure TRickSQLTransactionTests.StartPhysicalTransaction;
begin
  FConnection.StartTransaction;
  Check(FConnection.InTransaction,
    'O cenário de teste deveria iniciar uma transação real no SQLite.');
end;

procedure TRickSQLTransactionTests.ForceActiveInspectionFailure;
begin
  // TFDCustomConnection.InTransaction acessa ConnectionIntf.Transaction.Active.
  // Remover temporariamente a transação física mantém a conexão aberta e força
  // uma exception determinística na inspeção, sem substituir a implementação
  // interna do FireDAC por um double incompatível com seu setter físico.
  FPhysConnection.Transaction := nil;
end;

procedure TRickSQLTransactionTests.RestorePhysicalTransaction;
begin
  if Assigned(FPhysConnection) and Assigned(FOriginalTransaction) and
    not Assigned(FPhysConnection.Transaction) then
    FPhysConnection.Transaction := FOriginalTransaction;
end;

procedure TRickSQLTransactionTests.ReleaseFireDACFixture;
begin
  if Assigned(FConnection) then
  begin
    FConnection.BeforeStartTransaction := nil;
    FConnection.AfterStartTransaction := nil;
    FConnection.BeforeCommit := nil;
    FConnection.AfterCommit := nil;
    FConnection.BeforeRollback := nil;
    FConnection.AfterRollback := nil;
  end;

  RestorePhysicalTransaction;
  if Assigned(FConnection) and FConnection.InTransaction then
    FConnection.Rollback;

  FOriginalTransaction := nil;
  FPhysConnection := nil;
  FreeAndNil(FConnection);
end;

procedure TRickSQLTransactionTests.ArmActiveInspectionFailure(Sender: TObject);
begin
  ForceActiveInspectionFailure;
end;

procedure TRickSQLTransactionTests.RaiseStartFailure(Sender: TObject);
begin
  raise Exception.Create(_CONTROLLED_START_FAILURE_);
end;

procedure TRickSQLTransactionTests.RaiseCommitFailure(Sender: TObject);
begin
  raise Exception.Create(_CONTROLLED_COMMIT_FAILURE_);
end;

procedure TRickSQLTransactionTests.RaiseRollbackFailure(Sender: TObject);
begin
  raise Exception.Create(_CONTROLLED_ROLLBACK_FAILURE_);
end;

procedure TRickSQLTransactionTests.CheckTransactionError(
  const AError: TRickSQLError; const AExpectedDetail: string);
begin
  Check(AError.HasError, 'A operação deveria produzir TRickSQLError.');
  Check(AError.Kind = TRickSQLErrorKind.Transaction,
    'O erro deveria ser classificado como Transaction.');
  Check(Pos(AExpectedDetail, AError.TechnicalDetail) > 0,
    'O detalhe técnico da falha controlada deveria ser preservado.');
end;

procedure TRickSQLTransactionTests.CheckInspectionError(
  const AError: TRickSQLError);
begin
  CheckTransactionError(AError, _INSPECTION_DETAIL_PREFIX_);
  CheckEquals(_INSPECTION_ERROR_MESSAGE_, AError.Message,
    'Falha de inspeção deve ser distinguida de transação inativa.');
end;

procedure TRickSQLTransactionTests.CheckPrimaryErrorPreserved(
  const AError: TRickSQLError; const ASecondaryDetail: string);
begin
  Check(AError.Kind = TRickSQLErrorKind.Command,
    'A falha secundária não deve substituir o Kind do erro primário.');
  CheckEquals(_PRIMARY_MESSAGE_, AError.Message,
    'A falha secundária não deve substituir a mensagem primária.');
  CheckEquals(_PRIMARY_OPERATION_, AError.Operation,
    'A falha secundária não deve substituir a operação primária.');
  Check(Pos(_PRIMARY_DETAIL_, AError.TechnicalDetail) > 0,
    'O detalhe primário deve ser preservado.');
  Check(Pos(ASecondaryDetail, AError.TechnicalDetail) > 0,
    'A falha secundária deve permanecer diagnosticável.');
end;

procedure TRickSQLTransactionTests.Active_TransacaoAtiva_DeveRetornarTrue;
begin
  StartPhysicalTransaction;
  Check(TRickSQLServiceFireDACTransaction.Active(FConnection),
    'Active deveria retornar True para transação ativa.');
end;

procedure TRickSQLTransactionTests.Active_TransacaoInativa_DeveRetornarFalse;
begin
  Check(not TRickSQLServiceFireDACTransaction.Active(FConnection),
    'Active deveria retornar False sem transação ativa.');
end;

procedure TRickSQLTransactionTests.Active_ConexaoNil_DevePreservarContratoFalse;
begin
  Check(not TRickSQLServiceFireDACTransaction.Active(nil),
    'Active(nil) deve continuar retornando False por compatibilidade.');
end;

procedure TRickSQLTransactionTests.Active_FalhaDeInspecao_DevePreservarContratoFalse;
begin
  StartPhysicalTransaction;
  ForceActiveInspectionFailure;
  Check(not TRickSQLServiceFireDACTransaction.Active(FConnection),
    'O contrato público histórico de Active deve continuar retornando False.');
  RestorePhysicalTransaction;
  Check(FConnection.InTransaction,
    'A transação real continua ativa apesar do False compatível de Active.');
end;

procedure TRickSQLTransactionTests.Start_TransacaoAtiva_DevePreservarComportamentoAtual;
var
  LError: TRickSQLError;
begin
  StartPhysicalTransaction;
  Check(TRickSQLServiceFireDACTransaction.Start(FConnection, LError),
    'Start com transação ativa deve continuar sendo bem-sucedido.');
  Check(not LError.HasError, 'Start ativo não deveria retornar erro.');
  Check(FConnection.InTransaction, 'A transação existente deve continuar ativa.');
end;

procedure TRickSQLTransactionTests.Start_TransacaoInativa_DeveIniciar;
var
  LError: TRickSQLError;
begin
  Check(TRickSQLServiceFireDACTransaction.Start(FConnection, LError),
    'Start deveria iniciar uma transação inativa.');
  Check(not LError.HasError, 'Start bem-sucedido não deveria retornar erro.');
  Check(FConnection.InTransaction, 'A transação deveria estar ativa.');
end;

procedure TRickSQLTransactionTests.Start_FalhaAoConsultarEstado_NaoDeveRetornarSucesso;
var
  LError: TRickSQLError;
begin
  ForceActiveInspectionFailure;
  Check(not TRickSQLServiceFireDACTransaction.Start(FConnection, LError),
    'Falha ao inspecionar o estado antes de Start não pode virar sucesso.');
  CheckInspectionError(LError);
  RestorePhysicalTransaction;
  Check(not FConnection.InTransaction,
    'Start não deveria iniciar transação após falha na inspeção prévia.');
end;

procedure TRickSQLTransactionTests.Start_FalhaNaInspecaoAposInicio_DeveReportarErro;
var
  LError: TRickSQLError;
begin
  FConnection.AfterStartTransaction := ArmActiveInspectionFailure;
  Check(not TRickSQLServiceFireDACTransaction.Start(FConnection, LError),
    'Falha ao inspecionar o estado após Start não pode ser sucesso.');
  CheckInspectionError(LError);
  RestorePhysicalTransaction;
  Check(FConnection.InTransaction,
    'A falha de inspeção não deve ser confundida com transação inativa.');
end;

procedure TRickSQLTransactionTests.Start_ExceptionDuranteStart_DeveReportarErro;
var
  LError: TRickSQLError;
begin
  FConnection.BeforeStartTransaction := RaiseStartFailure;
  Check(not TRickSQLServiceFireDACTransaction.Start(FConnection, LError),
    'Exception durante StartTransaction deve ser reportada.');
  CheckTransactionError(LError, _CONTROLLED_START_FAILURE_);
end;

procedure TRickSQLTransactionTests.Commit_TransacaoAtiva_DeveFinalizar;
var
  LError: TRickSQLError;
begin
  StartPhysicalTransaction;
  Check(TRickSQLServiceFireDACTransaction.Commit(FConnection, LError),
    'Commit deveria concluir a transação ativa.');
  Check(not LError.HasError, 'Commit bem-sucedido não deveria retornar erro.');
  Check(not FConnection.InTransaction, 'A transação deveria estar inativa.');
end;

procedure TRickSQLTransactionTests.Commit_TransacaoInativa_DevePreservarComportamentoAtual;
var
  LError: TRickSQLError;
begin
  Check(TRickSQLServiceFireDACTransaction.Commit(FConnection, LError),
    'Commit sem transação ativa deve continuar sendo no-op bem-sucedido.');
  Check(not LError.HasError, 'No-op de Commit não deveria retornar erro.');
end;

procedure TRickSQLTransactionTests.Commit_FalhaAoConsultarEstado_NaoDeveRetornarSucesso;
var
  LError: TRickSQLError;
begin
  StartPhysicalTransaction;
  ForceActiveInspectionFailure;
  Check(not TRickSQLServiceFireDACTransaction.Commit(FConnection, LError),
    'Falha de inspeção antes do Commit não pode virar sucesso.');
  CheckInspectionError(LError);
  RestorePhysicalTransaction;
  Check(FConnection.InTransaction,
    'Commit não deve ocorrer quando o estado não pôde ser determinado.');
end;

procedure TRickSQLTransactionTests.Commit_FalhaNaInspecaoAposCommit_DeveReportarErro;
var
  LError: TRickSQLError;
begin
  StartPhysicalTransaction;
  FConnection.AfterCommit := ArmActiveInspectionFailure;
  Check(not TRickSQLServiceFireDACTransaction.Commit(FConnection, LError),
    'Falha de inspeção após Commit não pode virar sucesso.');
  CheckInspectionError(LError);
  RestorePhysicalTransaction;
  Check(not FConnection.InTransaction,
    'O Commit ocorreu, mas sua validação de estado falhou.');
end;

procedure TRickSQLTransactionTests.Commit_ExceptionDuranteCommit_DeveReportarErro;
var
  LError: TRickSQLError;
begin
  StartPhysicalTransaction;
  FConnection.BeforeCommit := RaiseCommitFailure;
  Check(not TRickSQLServiceFireDACTransaction.Commit(FConnection, LError),
    'Exception durante Commit deve ser reportada.');
  CheckTransactionError(LError, _CONTROLLED_COMMIT_FAILURE_);
end;

procedure TRickSQLTransactionTests.Rollback_TransacaoAtiva_DeveFinalizar;
var
  LError: TRickSQLError;
begin
  StartPhysicalTransaction;
  Check(TRickSQLServiceFireDACTransaction.Rollback(FConnection, LError),
    'Rollback deveria concluir a transação ativa.');
  Check(not LError.HasError, 'Rollback bem-sucedido não deveria retornar erro.');
  Check(not FConnection.InTransaction, 'A transação deveria estar inativa.');
end;

procedure TRickSQLTransactionTests.Rollback_TransacaoInativa_DevePreservarComportamentoAtual;
var
  LError: TRickSQLError;
begin
  Check(TRickSQLServiceFireDACTransaction.Rollback(FConnection, LError),
    'Rollback sem transação ativa deve continuar sendo no-op bem-sucedido.');
  Check(not LError.HasError, 'No-op de Rollback não deveria retornar erro.');
end;

procedure TRickSQLTransactionTests.Rollback_FalhaAoConsultarEstado_NaoDeveRetornarSucesso;
var
  LError: TRickSQLError;
begin
  StartPhysicalTransaction;
  ForceActiveInspectionFailure;
  Check(not TRickSQLServiceFireDACTransaction.Rollback(FConnection, LError),
    'Falha de inspeção antes do Rollback não pode virar sucesso.');
  CheckInspectionError(LError);
  RestorePhysicalTransaction;
  Check(FConnection.InTransaction,
    'Rollback não deve ocorrer quando o estado não pôde ser determinado.');
end;

procedure TRickSQLTransactionTests.Rollback_FalhaNaInspecaoAposRollback_DeveReportarErro;
var
  LError: TRickSQLError;
begin
  StartPhysicalTransaction;
  FConnection.AfterRollback := ArmActiveInspectionFailure;
  Check(not TRickSQLServiceFireDACTransaction.Rollback(FConnection, LError),
    'Falha de inspeção após Rollback não pode virar sucesso.');
  CheckInspectionError(LError);
  RestorePhysicalTransaction;
  Check(not FConnection.InTransaction,
    'O Rollback ocorreu, mas sua validação de estado falhou.');
end;

procedure TRickSQLTransactionTests.Rollback_ExceptionDuranteRollback_DeveReportarErro;
var
  LError: TRickSQLError;
begin
  StartPhysicalTransaction;
  FConnection.BeforeRollback := RaiseRollbackFailure;
  Check(not TRickSQLServiceFireDACTransaction.Rollback(FConnection, LError),
    'Exception durante Rollback deve ser reportada.');
  CheckTransactionError(LError, _CONTROLLED_ROLLBACK_FAILURE_);
end;

procedure TRickSQLTransactionTests.RollbackAfterFailure_TransacaoAtiva_DevePreservarErroPrimario;
var
  LError: TRickSQLError;
begin
  StartPhysicalTransaction;
  LError := TRickSQLError.Create(TRickSQLErrorKind.Command, _PRIMARY_MESSAGE_);
  LError.Operation := _PRIMARY_OPERATION_;
  LError.TechnicalDetail := _PRIMARY_DETAIL_;

  Check(TRickSQLServiceFireDACTransaction.RollbackAfterFailure(
    FConnection, LError), 'O cleanup deveria concluir o rollback ativo.');
  CheckEquals(_PRIMARY_DETAIL_, LError.TechnicalDetail,
    'Rollback bem-sucedido não deve alterar o diagnóstico primário.');
  Check(not FConnection.InTransaction,
    'O rollback de cleanup deveria encerrar a transação.');
end;

procedure TRickSQLTransactionTests.RollbackAfterFailure_TransacaoInativa_DevePreservarErroPrimario;
var
  LError: TRickSQLError;
begin
  LError := TRickSQLError.Create(TRickSQLErrorKind.Command, _PRIMARY_MESSAGE_);
  LError.Operation := _PRIMARY_OPERATION_;
  LError.TechnicalDetail := _PRIMARY_DETAIL_;

  Check(TRickSQLServiceFireDACTransaction.RollbackAfterFailure(
    FConnection, LError), 'Cleanup sem transação deve preservar o no-op histórico.');
  CheckEquals(_PRIMARY_DETAIL_, LError.TechnicalDetail,
    'No-op de cleanup não deve alterar o diagnóstico primário.');
end;

procedure TRickSQLTransactionTests.RollbackAfterFailure_FalhaNaInspecao_NaoDeveDescartarDiagnostico;
var
  LError: TRickSQLError;
begin
  StartPhysicalTransaction;
  ForceActiveInspectionFailure;
  LError := TRickSQLError.Create(TRickSQLErrorKind.Command, _PRIMARY_MESSAGE_);
  LError.Operation := _PRIMARY_OPERATION_;
  LError.TechnicalDetail := _PRIMARY_DETAIL_;

  Check(not TRickSQLServiceFireDACTransaction.RollbackAfterFailure(
    FConnection, LError),
    'Falha de inspeção durante cleanup deve ser reportada.');
  CheckPrimaryErrorPreserved(LError, _INSPECTION_DETAIL_PREFIX_);
end;

procedure TRickSQLTransactionTests.RollbackAfterFailure_FalhaNoRollback_NaoDeveDescartarDiagnostico;
var
  LError: TRickSQLError;
begin
  StartPhysicalTransaction;
  FConnection.BeforeRollback := RaiseRollbackFailure;
  LError := TRickSQLError.Create(TRickSQLErrorKind.Command, _PRIMARY_MESSAGE_);
  LError.Operation := _PRIMARY_OPERATION_;
  LError.TechnicalDetail := _PRIMARY_DETAIL_;

  Check(not TRickSQLServiceFireDACTransaction.RollbackAfterFailure(
    FConnection, LError),
    'Falha do rollback de cleanup deve ser reportada.');
  CheckPrimaryErrorPreserved(LError, _CONTROLLED_ROLLBACK_FAILURE_);
end;

procedure TRickSQLTransactionTests.UseTransactionFalse_NaoDeveIntroduzirErroTransacional;
var
  LConnectionOptions: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
  LDatabase: string;
  LResult: TRickSQLExecutionResult;
  LFailureDetail: string;
begin
  // Este cenário usa a façade completa. A fixture FireDAC dos demais testes
  // deve estar encerrada para não interferir no ciclo de vida do driver link
  // criado internamente pelo RickSQL.
  ReleaseFireDACFixture;

  LDatabase := TPath.GetTempFileName;
  TFile.Delete(LDatabase);
  try
    LConnectionOptions := TRickSQL.ConnectionOptions(
      TRickSQLDatabaseEngine.SQLite);
    LConnectionOptions.Database := LDatabase;
    LCommand := TRickSQL.Command(LConnectionOptions,
      'CREATE TABLE RICKSQL_USE_TRANSACTION_FALSE_TEST (ID INTEGER)');
    LCommand.Options.UseTransaction := False;

    LResult := TRickSQL.Execute(LCommand);
    LFailureDetail := Format(
      ' Mensagem: %s | Operação: %s | Detalhe: %s',
      [LResult.Error.Message, LResult.Error.Operation,
       LResult.Error.TechnicalDetail]);

    Check(LResult.Success,
      'UseTransaction=False deve executar comando válido sem controle ' +
      'transacional explícito do RickSQL.' + LFailureDetail);
    Check(not LResult.Error.HasError,
      'UseTransaction=False não deveria introduzir erro transacional.' +
      LFailureDetail);
  finally
    if TFile.Exists(LDatabase) then
      TFile.Delete(LDatabase);
  end;
end;

initialization
  RegisterTest(TRickSQLTransactionTests.Suite);

end.
