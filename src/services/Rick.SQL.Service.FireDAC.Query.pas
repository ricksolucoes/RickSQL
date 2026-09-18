unit Rick.SQL.Service.FireDAC.Query;

// Responsabilidade: preparar queries FireDAC para as operações do RickSQL.
// NAO abre conexões, controla transações ou materializa datasets.

interface

uses
  // FireDAC
  FireDAC.Comp.Client,

  // RickSQL
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Error;

type
  TRickSQLFireDACQuerySetup = record
    Query: TFDQuery;
    Connection: TFDConnection;
    Command: TRickSQLCommand;
    class function Create(const AQuery: TFDQuery;
      const AConnection: TFDConnection;
      const ACommand: TRickSQLCommand): TRickSQLFireDACQuerySetup; static;
  end;

  TRickSQLServiceFireDACQuery = class
  private
    class function CreateQueryError(const AMessage: string;
      const ADetail: string): TRickSQLError; static;
    class function ValidateSetup(const ASetup: TRickSQLFireDACQuerySetup;
      out AError: TRickSQLError): Boolean; static;
    class procedure AssignConnection(
      const ASetup: TRickSQLFireDACQuerySetup); static;
    class procedure AssignSQL(const ASetup: TRickSQLFireDACQuerySetup); static;
    class procedure ApplyTimeout(const ASetup: TRickSQLFireDACQuerySetup); static;
    class function ValidatePrepare(const AQuery: TFDQuery;
      out AError: TRickSQLError): Boolean; static;
    class function ExecutePrepare(const AQuery: TFDQuery;
      out AError: TRickSQLError): Boolean; static;
  public
    class function Configure(const ASetup: TRickSQLFireDACQuerySetup;
      out AError: TRickSQLError): Boolean; static;
    class function Prepare(const AQuery: TFDQuery;
      out AError: TRickSQLError): Boolean; static;
  end;

implementation

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Error.Normalizer;

const
  _OPERATION_CONFIGURE_ = 'Configuração da query FireDAC';
  _OPERATION_PREPARE_ = 'Preparação da query FireDAC';
  _ERROR_QUERY_NOT_ASSIGNED_ =
    'A query FireDAC não foi criada. Crie a sessão antes de configurar ou preparar a query.';
  _ERROR_CONNECTION_NOT_ASSIGNED_ =
    'A conexão FireDAC da query não foi criada. Configure a conexão antes de preparar a query.';
  _ERROR_SQL_EMPTY_ =
    'O comando SQL não foi informado. Informe um SQL válido antes de preparar a query.';
  _ERROR_CONFIGURE_QUERY_ =
    'Não foi possível configurar a query FireDAC. Verifique conexão, SQL e timeout informados.';
  _ERROR_PREPARE_QUERY_ =
    'Não foi possível preparar a query FireDAC. Verifique o SQL e os parâmetros informados.';

class function TRickSQLFireDACQuerySetup.Create(const AQuery: TFDQuery;
  const AConnection: TFDConnection;
  const ACommand: TRickSQLCommand): TRickSQLFireDACQuerySetup;
begin
  Result.Query := AQuery;
  Result.Connection := AConnection;
  Result.Command := ACommand;
end;

class function TRickSQLServiceFireDACQuery.Configure(
  const ASetup: TRickSQLFireDACQuerySetup;
  out AError: TRickSQLError): Boolean;
begin
  Result := False;

  AError := TRickSQLError.Empty;

  if not ValidateSetup(ASetup, AError) then
    Exit(False);

  try
    AssignConnection(ASetup);
    AssignSQL(ASetup);
    ApplyTimeout(ASetup);
    Result := True;
  except
    on E: Exception do
      AError := TRickSQLErrorNormalizer.FromException(E,
        TRickSQLErrorKind.Command, _ERROR_CONFIGURE_QUERY_,
        _OPERATION_CONFIGURE_);
  end;
end;

class function TRickSQLServiceFireDACQuery.Prepare(const AQuery: TFDQuery;
  out AError: TRickSQLError): Boolean;
begin
  AError := TRickSQLError.Empty;
  if not ValidatePrepare(AQuery, AError) then
    Exit(False);
  Result := ExecutePrepare(AQuery, AError);
end;

class function TRickSQLServiceFireDACQuery.ValidatePrepare(
  const AQuery: TFDQuery; out AError: TRickSQLError): Boolean;
begin
  Result := Assigned(AQuery);
  if not Result then
    AError := CreateQueryError(_ERROR_QUERY_NOT_ASSIGNED_, '');
end;

class function TRickSQLServiceFireDACQuery.ExecutePrepare(
  const AQuery: TFDQuery; out AError: TRickSQLError): Boolean;
begin
  try
    AQuery.Prepare;
    Result := AQuery.Prepared;
  except
    on E: Exception do
    begin
      AError := TRickSQLErrorNormalizer.FromException(E,
        TRickSQLErrorKind.Command, _ERROR_PREPARE_QUERY_, _OPERATION_PREPARE_);
      Result := False;
    end;
  end;
end;

class function TRickSQLServiceFireDACQuery.CreateQueryError(
  const AMessage: string; const ADetail: string): TRickSQLError;
begin
  Result := TRickSQLErrorNormalizer.FromDetail(TRickSQLErrorKind.Command,
    AMessage, ADetail, _OPERATION_CONFIGURE_);
end;

class function TRickSQLServiceFireDACQuery.ValidateSetup(
  const ASetup: TRickSQLFireDACQuerySetup;
  out AError: TRickSQLError): Boolean;
begin
  if not Assigned(ASetup.Query) then
  begin
    AError := CreateQueryError(_ERROR_QUERY_NOT_ASSIGNED_, '');
    Exit(False);
  end;

  if not Assigned(ASetup.Connection) then
  begin
    AError := CreateQueryError(_ERROR_CONNECTION_NOT_ASSIGNED_, '');
    Exit(False);
  end;

  Result := Trim(ASetup.Command.Text) <> '';
  if not Result then
    AError := CreateQueryError(_ERROR_SQL_EMPTY_, '');
end;

class procedure TRickSQLServiceFireDACQuery.AssignConnection(
  const ASetup: TRickSQLFireDACQuerySetup);
begin
  ASetup.Query.Connection := ASetup.Connection;
end;

class procedure TRickSQLServiceFireDACQuery.AssignSQL(
  const ASetup: TRickSQLFireDACQuerySetup);
begin
  ASetup.Query.SQL.Text := ASetup.Command.Text;
end;

class procedure TRickSQLServiceFireDACQuery.ApplyTimeout(
  const ASetup: TRickSQLFireDACQuerySetup);
begin
  if ASetup.Command.Options.CommandTimeout <= 0 then
    Exit;

  ASetup.Query.ResourceOptions.CmdExecTimeout :=
    ASetup.Command.Options.CommandTimeout;
end;

end.
