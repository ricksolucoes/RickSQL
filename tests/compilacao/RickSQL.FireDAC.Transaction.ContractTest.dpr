program RickSQLFireDACTransactionContractTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,

  // FireDAC
  FireDAC.Comp.Client,

  // RickSQL
  Rick.SQL.Model.Error,
  Rick.SQL.Model.Types,
  Rick.SQL.Service.FireDAC.Transaction;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure TestActiveWithNilConnection;
begin
  Check(not TRickSQLServiceFireDACTransaction.Active(nil),
    'A transação não pode estar ativa sem conexão.');
end;

procedure TestStartWithoutConnection;
var
  LError: TRickSQLError;
begin
  Check(not TRickSQLServiceFireDACTransaction.Start(nil, LError),
    'A transação não pode iniciar sem conexão.');
  Check(LError.Kind = TRickSQLErrorKind.Transaction,
    'O erro de início da transação não foi estruturado corretamente.');
end;

procedure TestRollbackWithoutConnection;
var
  LError: TRickSQLError;
begin
  Check(not TRickSQLServiceFireDACTransaction.Rollback(nil, LError),
    'O rollback não pode ser confirmado sem conexão.');
  Check(LError.Kind = TRickSQLErrorKind.Transaction,
    'O erro de rollback não foi estruturado corretamente.');
end;

procedure TestRollbackAfterFailureWithoutActiveTransaction;
var
  LError: TRickSQLError;
begin
  LError := TRickSQLError.Create(TRickSQLErrorKind.Command,
    'Falha original preservada.');
  Check(TRickSQLServiceFireDACTransaction.RollbackAfterFailure(nil, LError),
    'Rollback sem transação ativa deve ser considerado resolvido.');
  Check(LError.Kind = TRickSQLErrorKind.Command,
    'A falha original não deveria ser substituída.');
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  TestActiveWithNilConnection;
  TestStartWithoutConnection;
  TestRollbackWithoutConnection;
  TestRollbackAfterFailureWithoutActiveTransaction;
end.
