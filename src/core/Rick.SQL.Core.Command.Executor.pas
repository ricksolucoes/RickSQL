unit Rick.SQL.Core.Command.Executor;

// Responsabilidade: orquestrar a execução de comandos SQL sem conjunto de dados.
// NAO exibe mensagens, mantém conexões globais ou conhece interface visual.

interface

uses
  // RickSQL
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Contracts,
  Rick.SQL.Model.Error,
  Rick.SQL.Model.Execution.Result,
  Rick.SQL.Service.FireDAC.Session;

type
  TRickSQLCoreCommandExecutor = class
  private
    class function CreateSession(const ACommand: TRickSQLCommand;
      const AProvider: IRickSQLDriverProvider;
      out AError: TRickSQLError): TRickSQLServiceFireDACSession; static;
    class function ExecuteWithSession(
      const ASession: TRickSQLServiceFireDACSession;
      const ACommand: TRickSQLCommand)
      : TRickSQLExecutionResult; static;
    class function PrepareSession(
      const ASession: TRickSQLServiceFireDACSession;
      const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
    class function ConfigureConnection(
      const ASession: TRickSQLServiceFireDACSession;
      const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
    class function ConfigureQuery(
      const ASession: TRickSQLServiceFireDACSession;
      const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
    class function BindParameters(
      const ASession: TRickSQLServiceFireDACSession;
      const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
    class function StartConfiguredTransaction(
      const ASession: TRickSQLServiceFireDACSession;
      const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
    class function CommitConfiguredTransaction(
      const ASession: TRickSQLServiceFireDACSession;
      const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
    class function ExecutePrepared(
      const ASession: TRickSQLServiceFireDACSession;
      const ACommand: TRickSQLCommand;
      out ARowsAffected: Integer;
      out AError: TRickSQLError): Boolean; static;
    class function ExecuteSQL(
      const ASession: TRickSQLServiceFireDACSession;
      out ARowsAffected: Integer;
      out AError: TRickSQLError): Boolean; static;
    class procedure RollbackConfigured(
      const ASession: TRickSQLServiceFireDACSession;
      const ACommand: TRickSQLCommand;
      var AError: TRickSQLError); static;
  public
    class function Execute(const ACommand: TRickSQLCommand)
      : TRickSQLExecutionResult; static;
  end;

implementation

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL.Core.Command.Validator,
  Rick.SQL.Core.Driver.Context.Factory,
  Rick.SQL.Core.Error.Parser,
  Rick.SQL.Service.FireDAC.Driver.Context,
  Rick.SQL.Model.Types,
  Rick.SQL.Service.FireDAC.Connection,
  Rick.SQL.Service.FireDAC.Parameter.Binder,
  Rick.SQL.Service.FireDAC.Query,
  Rick.SQL.Service.FireDAC.Transaction;

const
  _OPERATION_EXECUTE_COMMAND_ = 'Execução do comando SQL FireDAC';
  _ERROR_SESSION_NOT_READY_ =
    'A sessão FireDAC não foi preparada. Verifique o driver e tente novamente.';

class function TRickSQLCoreCommandExecutor.Execute(
  const ACommand: TRickSQLCommand): TRickSQLExecutionResult;
var
  LSession: TRickSQLServiceFireDACSession;
  LProvider: IRickSQLDriverProvider;
  LError: TRickSQLError;
begin
  if not TRickSQLCoreCommandValidator.Validate(
    ACommand, LProvider, LError) then
    Exit(TRickSQLExecutionResult.Failed(LError));
  LSession := CreateSession(ACommand, LProvider, LError);
  try
    if not Assigned(LSession) then
      Exit(TRickSQLExecutionResult.Failed(LError));
    Result := ExecuteWithSession(LSession, ACommand);
  finally
    LSession.Free;
  end;
end;

class function TRickSQLCoreCommandExecutor.ExecuteWithSession(
  const ASession: TRickSQLServiceFireDACSession;
  const ACommand: TRickSQLCommand): TRickSQLExecutionResult;
var
  LError: TRickSQLError;
  LRowsAffected: Integer;
begin
  if not PrepareSession(ASession, ACommand, LError) then
    Exit(TRickSQLExecutionResult.Failed(LError));
  if not ExecutePrepared(ASession, ACommand, LRowsAffected, LError) then
    Exit(TRickSQLExecutionResult.Failed(LError));
  Result := TRickSQLExecutionResult.Succeeded(LRowsAffected);
end;

class function TRickSQLCoreCommandExecutor.CreateSession(
  const ACommand: TRickSQLCommand; const AProvider: IRickSQLDriverProvider;
  out AError: TRickSQLError): TRickSQLServiceFireDACSession;
var
  LContext: TRickSQLServiceFireDACDriverContext;
begin
  LContext := TRickSQLCoreDriverContextFactory.Create(
    ACommand.Connection, _OPERATION_EXECUTE_COMMAND_, AProvider, AError);
  if not Assigned(LContext) then
    Exit(nil);
  Result := TRickSQLServiceFireDACSession.Create(LContext);
  if Result.Ready then
    Exit;
  AError := Result.Error;
  if not AError.HasError then
    AError := TRickSQLCoreErrorParser.FromMessage(
      TRickSQLErrorKind.Connection, _ERROR_SESSION_NOT_READY_,
      _OPERATION_EXECUTE_COMMAND_);
  FreeAndNil(Result);
end;

class function TRickSQLCoreCommandExecutor.PrepareSession(
  const ASession: TRickSQLServiceFireDACSession;
  const ACommand: TRickSQLCommand; out AError: TRickSQLError): Boolean;
begin
  if not ConfigureConnection(ASession, ACommand, AError) then
    Exit(False);

  if not TRickSQLServiceFireDACConnection.Open(
    ASession.Connection, AError) then
    Exit(False);

  if not ConfigureQuery(ASession, ACommand, AError) then
    Exit(False);

  if not BindParameters(ASession, ACommand, AError) then
    Exit(False);

  Result := TRickSQLServiceFireDACQuery.Prepare(ASession.Query, AError);
end;

class function TRickSQLCoreCommandExecutor.ConfigureConnection(
  const ASession: TRickSQLServiceFireDACSession;
  const ACommand: TRickSQLCommand; out AError: TRickSQLError): Boolean;
var
  LSetup: TRickSQLFireDACConnectionSetup;
begin
  LSetup := TRickSQLFireDACConnectionSetup.Create(ASession.Connection,
    ASession.DriverContext, ACommand.Connection);
  Result := TRickSQLServiceFireDACConnection.Configure(LSetup, AError);
end;

class function TRickSQLCoreCommandExecutor.ConfigureQuery(
  const ASession: TRickSQLServiceFireDACSession;
  const ACommand: TRickSQLCommand; out AError: TRickSQLError): Boolean;
var
  LSetup: TRickSQLFireDACQuerySetup;
begin
  LSetup := TRickSQLFireDACQuerySetup.Create(ASession.Query,
    ASession.Connection, ACommand);
  Result := TRickSQLServiceFireDACQuery.Configure(LSetup, AError);
end;

class function TRickSQLCoreCommandExecutor.BindParameters(
  const ASession: TRickSQLServiceFireDACSession;
  const ACommand: TRickSQLCommand; out AError: TRickSQLError): Boolean;
var
  LSetup: TRickSQLFireDACParameterBindSetup;
begin
  LSetup := TRickSQLFireDACParameterBindSetup.Create(
    ASession.Query, ACommand);
  Result := TRickSQLServiceFireDACParameterBinder.Bind(LSetup, AError);
end;

class function TRickSQLCoreCommandExecutor.StartConfiguredTransaction(
  const ASession: TRickSQLServiceFireDACSession;
  const ACommand: TRickSQLCommand; out AError: TRickSQLError): Boolean;
begin
  if not ACommand.Options.UseTransaction then
    Exit(True);

  Result := TRickSQLServiceFireDACTransaction.Start(
    ASession.Connection, AError);
end;

class function TRickSQLCoreCommandExecutor.CommitConfiguredTransaction(
  const ASession: TRickSQLServiceFireDACSession;
  const ACommand: TRickSQLCommand; out AError: TRickSQLError): Boolean;
begin
  if not ACommand.Options.UseTransaction then
    Exit(True);

  Result := TRickSQLServiceFireDACTransaction.Commit(
    ASession.Connection, AError);
end;

class function TRickSQLCoreCommandExecutor.ExecutePrepared(
  const ASession: TRickSQLServiceFireDACSession;
  const ACommand: TRickSQLCommand; out ARowsAffected: Integer;
  out AError: TRickSQLError): Boolean;
begin
  ARowsAffected := 0;
  if not StartConfiguredTransaction(ASession, ACommand, AError) then
    Exit(False);
  if not ExecuteSQL(ASession, ARowsAffected, AError) then
  begin
    RollbackConfigured(ASession, ACommand, AError);
    Exit(False);
  end;
  Result := CommitConfiguredTransaction(ASession, ACommand, AError);
  if not Result then
    RollbackConfigured(ASession, ACommand, AError);
end;

class function TRickSQLCoreCommandExecutor.ExecuteSQL(
  const ASession: TRickSQLServiceFireDACSession;
  out ARowsAffected: Integer; out AError: TRickSQLError): Boolean;
begin
  AError := TRickSQLError.Empty;
  try
    ASession.Query.ExecSQL;
    ARowsAffected := ASession.Query.RowsAffected;
    Result := True;
  except
    on E: Exception do
      begin
        AError := TRickSQLCoreErrorParser.FromException(E,
          TRickSQLErrorKind.Command, _OPERATION_EXECUTE_COMMAND_);
        Result := False;
      end;
  end;
end;

class procedure TRickSQLCoreCommandExecutor.RollbackConfigured(
  const ASession: TRickSQLServiceFireDACSession;
  const ACommand: TRickSQLCommand; var AError: TRickSQLError);
begin
  if not ACommand.Options.UseTransaction then
    Exit;

  TRickSQLServiceFireDACTransaction.RollbackAfterFailure(
    ASession.Connection, AError);
end;

end.
