unit Rick.SQL.Core.Open.Executor;

// Responsabilidade: orquestrar a abertura de consultas e o retorno de datasets independentes.
// NAO exibe mensagens, mantém conexões globais ou conhece interface visual.

interface

uses
  // Data
  Data.DB,

  // FireDAC
  FireDAC.Comp.Client,

  // RickSQL
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Error,
  Rick.SQL.Service.FireDAC.Session;

type
  TRickSQLCoreOpenExecutor = class
  private
    class function CreateSession(const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): TRickSQLServiceFireDACSession; static;
    class function ConfigureConnection(
      const ASession: TRickSQLServiceFireDACSession;
      const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
    class function OpenConnection(
      const ASession: TRickSQLServiceFireDACSession;
      out AError: TRickSQLError): Boolean; static;
    class function ConfigureQuery(
      const ASession: TRickSQLServiceFireDACSession;
      const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
    class function PrepareQuery(
      const ASession: TRickSQLServiceFireDACSession;
      out AError: TRickSQLError): Boolean; static;
    class function BindParameters(
      const ASession: TRickSQLServiceFireDACSession;
      const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
    class function OpenQuery(const AQuery: TFDQuery;
      out AError: TRickSQLError): Boolean; static;
    class function MaterializeQuery(const ASession: TRickSQLServiceFireDACSession;
      const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): TDataSet; static;
    class function PrepareSession(
      const ASession: TRickSQLServiceFireDACSession;
      const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): Boolean; static;
  public
    class function Open(const ACommand: TRickSQLCommand;
      out AError: TRickSQLError): TDataSet; static;
  end;

implementation

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL.Core.Command.Validator,
  Rick.SQL.Core.DataSet.Materializer,
  Rick.SQL.Core.Driver.Context.Factory,
  Rick.SQL.Core.Error.Parser,
  Rick.SQL.Service.FireDAC.Driver.Context,
  Rick.SQL.Model.Types,
  Rick.SQL.Service.FireDAC.Connection,
  Rick.SQL.Service.FireDAC.Parameter.Binder,
  Rick.SQL.Service.FireDAC.Query;

const
  _OPERATION_OPEN_QUERY_ = 'Abertura da consulta FireDAC';
  _ERROR_SESSION_NOT_READY_ =
    'A sessão FireDAC não foi preparada. Verifique o driver e tente novamente.';

class function TRickSQLCoreOpenExecutor.Open(
  const ACommand: TRickSQLCommand; out AError: TRickSQLError): TDataSet;
var
  LSession: TRickSQLServiceFireDACSession;
begin
  AError := TRickSQLError.Empty;
  Result := nil;
  if not TRickSQLCoreCommandValidator.Validate(ACommand, AError) then
    Exit;
  LSession := CreateSession(ACommand, AError);
  try
    if not Assigned(LSession) then
      Exit;
    if not PrepareSession(LSession, ACommand, AError) then
      Exit;
    Result := MaterializeQuery(LSession, ACommand, AError);
  finally
    LSession.Free;
  end;
end;

class function TRickSQLCoreOpenExecutor.CreateSession(
  const ACommand: TRickSQLCommand;
  out AError: TRickSQLError): TRickSQLServiceFireDACSession;
var
  LContext: TRickSQLServiceFireDACDriverContext;
begin
  LContext := TRickSQLCoreDriverContextFactory.Create(
    ACommand.Connection, _OPERATION_OPEN_QUERY_, AError);
  if not Assigned(LContext) then
    Exit(nil);
  Result := TRickSQLServiceFireDACSession.Create(LContext);
  if Result.Ready then
    Exit;
  AError := Result.Error;
  if not AError.HasError then
    AError := TRickSQLCoreErrorParser.FromMessage(
      TRickSQLErrorKind.Connection, _ERROR_SESSION_NOT_READY_,
      _OPERATION_OPEN_QUERY_);
  FreeAndNil(Result);
end;

class function TRickSQLCoreOpenExecutor.PrepareSession(
  const ASession: TRickSQLServiceFireDACSession;
  const ACommand: TRickSQLCommand; out AError: TRickSQLError): Boolean;
begin
  if not ConfigureConnection(ASession, ACommand, AError) then
    Exit(False);

  if not OpenConnection(ASession, AError) then
    Exit(False);

  if not ConfigureQuery(ASession, ACommand, AError) then
    Exit(False);

  if not BindParameters(ASession, ACommand, AError) then
    Exit(False);

  Result := PrepareQuery(ASession, AError);
end;

class function TRickSQLCoreOpenExecutor.ConfigureConnection(
  const ASession: TRickSQLServiceFireDACSession;
  const ACommand: TRickSQLCommand; out AError: TRickSQLError): Boolean;
var
  LSetup: TRickSQLFireDACConnectionSetup;
begin
  LSetup := TRickSQLFireDACConnectionSetup.Create(ASession.Connection,
    ASession.DriverContext, ACommand.Connection);
  Result := TRickSQLServiceFireDACConnection.Configure(LSetup, AError);
end;

class function TRickSQLCoreOpenExecutor.OpenConnection(
  const ASession: TRickSQLServiceFireDACSession;
  out AError: TRickSQLError): Boolean;
begin
  Result := TRickSQLServiceFireDACConnection.Open(
    ASession.Connection, AError);
end;

class function TRickSQLCoreOpenExecutor.ConfigureQuery(
  const ASession: TRickSQLServiceFireDACSession;
  const ACommand: TRickSQLCommand; out AError: TRickSQLError): Boolean;
var
  LSetup: TRickSQLFireDACQuerySetup;
begin
  LSetup := TRickSQLFireDACQuerySetup.Create(ASession.Query,
    ASession.Connection, ACommand);
  Result := TRickSQLServiceFireDACQuery.Configure(LSetup, AError);
end;

class function TRickSQLCoreOpenExecutor.PrepareQuery(
  const ASession: TRickSQLServiceFireDACSession;
  out AError: TRickSQLError): Boolean;
begin
  Result := TRickSQLServiceFireDACQuery.Prepare(ASession.Query, AError);
end;

class function TRickSQLCoreOpenExecutor.BindParameters(
  const ASession: TRickSQLServiceFireDACSession;
  const ACommand: TRickSQLCommand; out AError: TRickSQLError): Boolean;
var
  LSetup: TRickSQLFireDACParameterBindSetup;
begin
  LSetup := TRickSQLFireDACParameterBindSetup.Create(
    ASession.Query, ACommand);
  Result := TRickSQLServiceFireDACParameterBinder.Bind(LSetup, AError);
end;

class function TRickSQLCoreOpenExecutor.OpenQuery(const AQuery: TFDQuery;
  out AError: TRickSQLError): Boolean;
begin
  AError := TRickSQLError.Empty;
  try
    AQuery.Open;
    Result := AQuery.Active;
  except
    on E: Exception do
      begin
        AError := TRickSQLCoreErrorParser.FromException(E,
          TRickSQLErrorKind.Command, _OPERATION_OPEN_QUERY_);
        Result := False;
      end;
  end;
end;

class function TRickSQLCoreOpenExecutor.MaterializeQuery(
  const ASession: TRickSQLServiceFireDACSession;
  const ACommand: TRickSQLCommand; out AError: TRickSQLError): TDataSet;
var
  LSetup: TRickSQLDataSetMaterializationSetup;
begin
  Result := nil;
  if not OpenQuery(ASession.Query, AError) then
    Exit;

  LSetup := TRickSQLDataSetMaterializationSetup.Create(
    ASession.Query, ACommand.Options);
  Result := TRickSQLCoreDataSetMaterializer.Materialize(LSetup, AError);
end;

end.
