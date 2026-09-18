unit Rick.SQL.Service.FireDAC.Connection;

// Responsabilidade: configurar, abrir e encerrar conexões FireDAC.
// NAO executa comandos SQL, materializa datasets ou exibe mensagens.

interface

uses
  // FireDAC
  FireDAC.Comp.Client,


  // RickSQL
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Error,
  Rick.SQL.Service.FireDAC.Driver.Context;

type
  TRickSQLFireDACConnectionSetup = record
    Connection: TFDConnection;
    DriverContext: TRickSQLServiceFireDACDriverContext;
    Options: TRickSQLConnectionOptions;
    class function Create(const AConnection: TFDConnection;
      const ADriverContext: TRickSQLServiceFireDACDriverContext;
      const AOptions: TRickSQLConnectionOptions)
      : TRickSQLFireDACConnectionSetup; static;
  end;

  TRickSQLServiceFireDACConnection = class
  private
    class function CreateConnectionError(const AMessage: string;
      const ADetail: string): TRickSQLError; static;
    class function ValidateSetup(const ASetup: TRickSQLFireDACConnectionSetup;
      out AError: TRickSQLError): Boolean; static;
    class procedure ApplyProviderOptions(
      const ASetup: TRickSQLFireDACConnectionSetup); static;
    class procedure DisableLoginPrompt(const AConnection: TFDConnection); static;
    class function ValidateOpen(const AConnection: TFDConnection;
      out AError: TRickSQLError): Boolean; static;
    class function ExecuteOpen(const AConnection: TFDConnection;
      out AError: TRickSQLError): Boolean; static;
  public
    class function Configure(const ASetup: TRickSQLFireDACConnectionSetup;
      out AError: TRickSQLError): Boolean; static;
    class function Open(const AConnection: TFDConnection;
      out AError: TRickSQLError): Boolean; static;
    class procedure Close(const AConnection: TFDConnection); static;
  end;

implementation

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL.Model.Types;

const
  _OPERATION_CONFIGURE_ = 'Configuração da conexão FireDAC';
  _OPERATION_OPEN_ = 'Abertura da conexão FireDAC';
  _ERROR_CONNECTION_NOT_ASSIGNED_ =
    'A conexão FireDAC não foi criada. Crie a sessão antes de configurar ou abrir a conexão.';
  _ERROR_DRIVER_CONTEXT_NOT_ASSIGNED_ =
    'O contexto do driver FireDAC não foi criado. Resolva o driver antes de configurar a conexão.';
  _ERROR_DRIVER_CONTEXT_NOT_READY_ =
    'O contexto do driver FireDAC não está configurado. Verifique a biblioteca cliente e o driver selecionado.';
  _ERROR_CONFIGURE_CONNECTION_ =
    'Não foi possível configurar a conexão com o banco de dados. Revise as opções de conexão informadas.';
  _ERROR_OPEN_CONNECTION_ =
    'Não foi possível abrir a conexão com o banco de dados. Verifique servidor, porta, banco e credenciais.';

class function TRickSQLFireDACConnectionSetup.Create(
  const AConnection: TFDConnection;
  const ADriverContext: TRickSQLServiceFireDACDriverContext;
  const AOptions: TRickSQLConnectionOptions): TRickSQLFireDACConnectionSetup;
begin
  Result.Connection := AConnection;
  Result.DriverContext := ADriverContext;
  Result.Options := AOptions;
end;

class function TRickSQLServiceFireDACConnection.Configure(
  const ASetup: TRickSQLFireDACConnectionSetup;
  out AError: TRickSQLError): Boolean;
begin
  Result := False;

  AError := TRickSQLError.Empty;

  if not ValidateSetup(ASetup, AError) then
    Exit(False);

  try
    DisableLoginPrompt(ASetup.Connection);
    ApplyProviderOptions(ASetup);
    Result := True;
  except
    on E: Exception do
      AError := CreateConnectionError(_ERROR_CONFIGURE_CONNECTION_, E.Message);
  end;
end;

class function TRickSQLServiceFireDACConnection.Open(
  const AConnection: TFDConnection; out AError: TRickSQLError): Boolean;
begin
  AError := TRickSQLError.Empty;
  if not ValidateOpen(AConnection, AError) then
    Exit(False);
  Result := ExecuteOpen(AConnection, AError);
end;

class function TRickSQLServiceFireDACConnection.ValidateOpen(
  const AConnection: TFDConnection; out AError: TRickSQLError): Boolean;
begin
  Result := Assigned(AConnection);
  if not Result then
    AError := CreateConnectionError(_ERROR_CONNECTION_NOT_ASSIGNED_, '');
end;

class function TRickSQLServiceFireDACConnection.ExecuteOpen(
  const AConnection: TFDConnection; out AError: TRickSQLError): Boolean;
begin
  try
    AConnection.Open;
    Result := AConnection.Connected;
  except
    on E: Exception do
    begin
      AError := CreateConnectionError(_ERROR_OPEN_CONNECTION_, E.Message);
      AError.Operation := _OPERATION_OPEN_;
      Result := False;
    end;
  end;
end;

class procedure TRickSQLServiceFireDACConnection.Close(
  const AConnection: TFDConnection);
begin
  if not Assigned(AConnection) then
    Exit;

  if AConnection.Connected then
    AConnection.Close;
end;

class function TRickSQLServiceFireDACConnection.CreateConnectionError(
  const AMessage: string; const ADetail: string): TRickSQLError;
begin
  Result := TRickSQLError.Create(TRickSQLErrorKind.Connection, AMessage);
  Result.TechnicalDetail := ADetail;
  Result.Operation := _OPERATION_CONFIGURE_;
end;

class function TRickSQLServiceFireDACConnection.ValidateSetup(
  const ASetup: TRickSQLFireDACConnectionSetup;
  out AError: TRickSQLError): Boolean;
begin
  if not Assigned(ASetup.Connection) then
  begin
    AError := CreateConnectionError(_ERROR_CONNECTION_NOT_ASSIGNED_, '');
    Exit(False);
  end;

  if not Assigned(ASetup.DriverContext) then
  begin
    AError := CreateConnectionError(_ERROR_DRIVER_CONTEXT_NOT_ASSIGNED_, '');
    Exit(False);
  end;

  Result := ASetup.DriverContext.Configured;
  if not Result then
    AError := CreateConnectionError(_ERROR_DRIVER_CONTEXT_NOT_READY_, '');
end;

class procedure TRickSQLServiceFireDACConnection.ApplyProviderOptions(
  const ASetup: TRickSQLFireDACConnectionSetup);
begin
  ASetup.DriverContext.Provider.ApplyConnectionOptions(
    ASetup.Options, ASetup.Connection.Params);
end;

class procedure TRickSQLServiceFireDACConnection.DisableLoginPrompt(
  const AConnection: TFDConnection);
begin
  if not Assigned(AConnection) then
    Exit;

  AConnection.LoginPrompt := False;
end;

end.
