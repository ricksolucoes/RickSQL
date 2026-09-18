unit Rick.SQL.Service.FireDAC.Transaction;

// Responsabilidade: controlar início, confirmação e reversão de transações FireDAC.
// NAO prepara queries, materializa datasets ou exibe mensagens.

interface

uses
  // FireDAC
  FireDAC.Comp.Client,

  // RickSQL
  Rick.SQL.Model.Error;

type
  TRickSQLServiceFireDACTransaction = class
  private
    class function CreateTransactionError(const AMessage: string;
      const ADetail: string; const AOperation: string): TRickSQLError; static;
    class function ValidateAssigned(const AConnection: TFDConnection;
      out AError: TRickSQLError; const AOperation: string): Boolean; static;
    class function ValidateConnection(const AConnection: TFDConnection;
      out AError: TRickSQLError; const AOperation: string): Boolean; static;
    class function StartTransaction(const AConnection: TFDConnection;
      out AError: TRickSQLError): Boolean; static;
    class function FinishTransaction(const AConnection: TFDConnection;
      out AError: TRickSQLError; const AOperation: string;
      const AMessage: string; const ACommit: Boolean): Boolean; static;
    class procedure AppendRollbackDetail(var AError: TRickSQLError;
      const ARollbackError: TRickSQLError); static;
  public
    class function Start(const AConnection: TFDConnection;
      out AError: TRickSQLError): Boolean; static;
    class function Commit(const AConnection: TFDConnection;
      out AError: TRickSQLError): Boolean; static;
    class function Rollback(const AConnection: TFDConnection;
      out AError: TRickSQLError): Boolean; static;
    class function RollbackAfterFailure(const AConnection: TFDConnection;
      var AError: TRickSQLError): Boolean; static;
    class function Active(const AConnection: TFDConnection): Boolean; static;
  end;

implementation

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Error.Normalizer;

const
  _OPERATION_START_ = 'Início da transação FireDAC';
  _OPERATION_COMMIT_ = 'Confirmação da transação FireDAC';
  _OPERATION_ROLLBACK_ = 'Reversão da transação FireDAC';
  _ERROR_CONNECTION_NOT_ASSIGNED_ =
    'A conexão FireDAC não foi criada para controlar a transação. Crie e abra a sessão antes da transação.';
  _ERROR_CONNECTION_CLOSED_ =
    'A conexão FireDAC precisa estar aberta para iniciar a transação. Abra a conexão antes de executar o comando.';
  _ERROR_START_ =
    'Não foi possível iniciar a transação do banco de dados. Verifique o estado da conexão.';
  _ERROR_COMMIT_ =
    'Não foi possível confirmar a transação do banco de dados. Verifique o estado da conexão e tente novamente.';
  _ERROR_ROLLBACK_ =
    'Não foi possível desfazer a transação do banco de dados. Verifique o estado da conexão.';
  _DETAIL_TRANSACTION_NOT_ACTIVE_ =
    'A transação não ficou ativa após a solicitação.';
  _DETAIL_TRANSACTION_STILL_ACTIVE_ =
    'A transação permaneceu ativa após a solicitação.';
  _ROLLBACK_DETAIL_PREFIX_ = 'Falha adicional ao desfazer a transação: ';

class function TRickSQLServiceFireDACTransaction.Start(
  const AConnection: TFDConnection; out AError: TRickSQLError): Boolean;
begin
  AError := TRickSQLError.Empty;

  if not ValidateConnection(AConnection, AError, _OPERATION_START_) then
    Exit(False);

  if Active(AConnection) then
    Exit(True);

  Result := StartTransaction(AConnection, AError);
end;

class function TRickSQLServiceFireDACTransaction.Commit(
  const AConnection: TFDConnection; out AError: TRickSQLError): Boolean;
begin
  AError := TRickSQLError.Empty;

  if not ValidateAssigned(AConnection, AError, _OPERATION_COMMIT_) then
    Exit(False);

  if not Active(AConnection) then
    Exit(True);

  Result := FinishTransaction(AConnection, AError, _OPERATION_COMMIT_,
    _ERROR_COMMIT_, True);
end;

class function TRickSQLServiceFireDACTransaction.Rollback(
  const AConnection: TFDConnection; out AError: TRickSQLError): Boolean;
begin
  AError := TRickSQLError.Empty;

  if not ValidateAssigned(AConnection, AError, _OPERATION_ROLLBACK_) then
    Exit(False);

  if not Active(AConnection) then
    Exit(True);

  Result := FinishTransaction(AConnection, AError, _OPERATION_ROLLBACK_,
    _ERROR_ROLLBACK_, False);
end;

class function TRickSQLServiceFireDACTransaction.RollbackAfterFailure(
  const AConnection: TFDConnection; var AError: TRickSQLError): Boolean;
var
  LRollbackError: TRickSQLError;
begin
  Result := True;

  if not Active(AConnection) then
    Exit;

  Result := Rollback(AConnection, LRollbackError);
  if not Result then
    AppendRollbackDetail(AError, LRollbackError);
end;

class function TRickSQLServiceFireDACTransaction.Active(
  const AConnection: TFDConnection): Boolean;
begin
  Result := False;

  if not Assigned(AConnection) then
    Exit;

  try
    Result := AConnection.InTransaction;
  except
    Result := False;
  end;
end;

class function TRickSQLServiceFireDACTransaction.CreateTransactionError(
  const AMessage: string; const ADetail: string;
  const AOperation: string): TRickSQLError;
begin
  Result := TRickSQLErrorNormalizer.FromDetail(TRickSQLErrorKind.Transaction,
    AMessage, ADetail, AOperation);
end;

class function TRickSQLServiceFireDACTransaction.ValidateAssigned(
  const AConnection: TFDConnection; out AError: TRickSQLError;
  const AOperation: string): Boolean;
begin
  Result := Assigned(AConnection);

  if not Result then
    AError := CreateTransactionError(_ERROR_CONNECTION_NOT_ASSIGNED_, '',
      AOperation);
end;

class function TRickSQLServiceFireDACTransaction.ValidateConnection(
  const AConnection: TFDConnection; out AError: TRickSQLError;
  const AOperation: string): Boolean;
begin
  if not ValidateAssigned(AConnection, AError, AOperation) then
    Exit(False);

  Result := AConnection.Connected;
  if not Result then
    AError := CreateTransactionError(_ERROR_CONNECTION_CLOSED_, '',
      AOperation);
end;

class function TRickSQLServiceFireDACTransaction.StartTransaction(
  const AConnection: TFDConnection; out AError: TRickSQLError): Boolean;
begin
  Result := False;
  try
    AConnection.StartTransaction;
    Result := Active(AConnection);
    if not Result then
      AError := CreateTransactionError(_ERROR_START_,
        _DETAIL_TRANSACTION_NOT_ACTIVE_, _OPERATION_START_);
  except
    on E: Exception do
      AError := TRickSQLErrorNormalizer.FromException(E,
        TRickSQLErrorKind.Transaction, _ERROR_START_, _OPERATION_START_);
  end;
end;

class function TRickSQLServiceFireDACTransaction.FinishTransaction(
  const AConnection: TFDConnection; out AError: TRickSQLError;
  const AOperation: string; const AMessage: string;
  const ACommit: Boolean): Boolean;
begin
  Result := False;

  try
    if ACommit then
      AConnection.Commit
    else
      AConnection.Rollback;
    Result := not Active(AConnection);
    if not Result then
      AError := CreateTransactionError(AMessage,
        _DETAIL_TRANSACTION_STILL_ACTIVE_, AOperation);
  except
    on E: Exception do
      AError := TRickSQLErrorNormalizer.FromException(E,
        TRickSQLErrorKind.Transaction, AMessage, AOperation);
  end;
end;

class procedure TRickSQLServiceFireDACTransaction.AppendRollbackDetail(
  var AError: TRickSQLError; const ARollbackError: TRickSQLError);
var
  LDetail: string;
begin
  if not ARollbackError.HasError then
    Exit;

  LDetail := _ROLLBACK_DETAIL_PREFIX_ + ARollbackError.TechnicalDetail;
  if Trim(AError.TechnicalDetail) = '' then
    AError.TechnicalDetail := LDetail
  else
    AError.TechnicalDetail := AError.TechnicalDetail + sLineBreak + LDetail;
end;

end.
