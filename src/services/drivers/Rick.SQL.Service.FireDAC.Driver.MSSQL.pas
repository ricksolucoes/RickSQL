unit Rick.SQL.Service.FireDAC.Driver.MSSQL;

// Responsabilidade: configurar o driver FireDAC para bancos Microsoft SQL Server.
// NAO executa comandos SQL, materializa datasets ou conhece outros bancos.

{$IFDEF FULL_EDITION}

interface

uses
  // RTL
  System.Classes,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Driver.Definition,
  Rick.SQL.Service.FireDAC.Driver.Base;

type
  TRickSQLServiceFireDACDriverMSSQL = class(
    TRickSQLServiceFireDACDriverProvider)
  private
    function BuildServer(const AOptions: TRickSQLConnectionOptions): string;
    function UsesWindowsAuthentication(
      const AOptions: TRickSQLConnectionOptions): Boolean;
    function ValidateAuthentication(const AOptions: TRickSQLConnectionOptions;
      out AError: string): Boolean;
  protected
    function GetDefinition: TRickSQLDriverDefinition; override;
  public
    function CreateDriverLink(const AOwner: TComponent): TComponent; override;
    procedure ApplyConnectionOptions(
      const AOptions: TRickSQLConnectionOptions;
      const AParameters: TStrings); override;
    function ValidateOptions(const AOptions: TRickSQLConnectionOptions;
      out AError: string): Boolean; override;
  end;

implementation

uses
  // RTL
  System.SysUtils,

  // FireDAC
  FireDAC.Phys.MSSQL;

const
  _DRIVER_ID_ = 'MSSQL';
  _CLIENT_LIBRARY_ = 'odbc32.dll';
  _PARAM_SERVER_ = 'Server';
  _PARAM_OS_AUTHENT_ = 'OSAuthent';
  _VALUE_YES_ = 'Yes';
  _VALUE_TRUE_ = 'True';
  _SERVER_PORT_FORMAT_ = '%s,%d';
  _ERROR_AUTHENTICATION_REQUIRED_ =
    'Informe usuário e senha ou habilite a autenticação do Windows. ' +
    'Preencha UserName e Password ou informe OSAuthent como Yes.';

function TRickSQLServiceFireDACDriverMSSQL.BuildServer(
  const AOptions: TRickSQLConnectionOptions): string;
begin
  Result := Trim(AOptions.Server);

  if AOptions.Port <= 0 then
    Exit;

  if Pos(',', Result) > 0 then
    Exit;

  Result := Format(_SERVER_PORT_FORMAT_, [Result, AOptions.Port]);
end;

function TRickSQLServiceFireDACDriverMSSQL.UsesWindowsAuthentication(
  const AOptions: TRickSQLConnectionOptions): Boolean;
var
  LValue: string;
begin
  LValue := ExtraParameterValue(AOptions, _PARAM_OS_AUTHENT_);
  Result := SameText(LValue, _VALUE_YES_) or
    SameText(LValue, _VALUE_TRUE_);
end;

function TRickSQLServiceFireDACDriverMSSQL.ValidateAuthentication(
  const AOptions: TRickSQLConnectionOptions;
  out AError: string): Boolean;
begin
  if UsesWindowsAuthentication(AOptions) then
    Exit(True);

  Result := (Trim(AOptions.UserName) <> '') and
    (AOptions.Password <> '');

  if not Result then
    AError := _ERROR_AUTHENTICATION_REQUIRED_;
end;

function TRickSQLServiceFireDACDriverMSSQL.CreateDriverLink(
  const AOwner: TComponent): TComponent;
begin
  Result := nil;

  if not Assigned(AOwner) then
    Exit;

  Result := TFDPhysMSSQLDriverLink.Create(AOwner);
end;

procedure TRickSQLServiceFireDACDriverMSSQL.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  if not Assigned(AParameters) then
    Exit;

  BeginParameters(AParameters);
  AddParameter(AParameters, Parameter(_PARAM_SERVER_, BuildServer(AOptions)));
  ApplyDatabaseOption(AOptions, AParameters);
  ApplyCredentialOptions(AOptions, AParameters);
  ApplyTimeoutOption(AOptions, AParameters);
  ApplyExtraOptions(AOptions, AParameters);
end;

function TRickSQLServiceFireDACDriverMSSQL.ValidateOptions(
  const AOptions: TRickSQLConnectionOptions;
  out AError: string): Boolean;
begin
  if not inherited ValidateOptions(AOptions, AError) then
    Exit(False);

  Result := ValidateAuthentication(AOptions, AError);
end;

function TRickSQLServiceFireDACDriverMSSQL.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.SQLServer, _DRIVER_ID_);
  Result.DefaultPort := 1433;
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Server
  ];
  Result.AddClientLibrary(_CLIENT_LIBRARY_);
end;

{$ELSE}

interface

uses
  // RTL
  System.Classes,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Driver.Definition,
  Rick.SQL.Service.FireDAC.Driver.Base;

type
  TRickSQLServiceFireDACDriverMSSQL = class(
    TRickSQLServiceFireDACDriverProvider)
  private
    procedure RaiseFullEditionRequired;
  protected
    function GetDefinition: TRickSQLDriverDefinition; override;
  public
    function CreateDriverLink(const AOwner: TComponent): TComponent; override;
    procedure ApplyConnectionOptions(
      const AOptions: TRickSQLConnectionOptions;
      const AParameters: TStrings); override;
    function ValidateOptions(const AOptions: TRickSQLConnectionOptions;
      out AError: string): Boolean; override;
  end;

implementation

uses
  // RTL
  System.SysUtils;

const
  _DRIVER_ID_ = 'MSSQL';
  _ERROR_FULL_EDITION_REQUIRED_ =
    'O driver Microsoft SQL Server exige a diretiva FULL_EDITION habilitada. ' +
    'Ative FULL_EDITION nas opções de compilação ou selecione outro mecanismo de banco.';

procedure TRickSQLServiceFireDACDriverMSSQL.RaiseFullEditionRequired;
begin
  raise Exception.Create(_ERROR_FULL_EDITION_REQUIRED_);
end;

function TRickSQLServiceFireDACDriverMSSQL.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.SQLServer, _DRIVER_ID_);
  Result.DefaultPort := 1433;
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Server
  ];
end;

function TRickSQLServiceFireDACDriverMSSQL.CreateDriverLink(
  const AOwner: TComponent): TComponent;
begin
  Result := nil;
  RaiseFullEditionRequired;
end;

procedure TRickSQLServiceFireDACDriverMSSQL.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  RaiseFullEditionRequired;
end;

function TRickSQLServiceFireDACDriverMSSQL.ValidateOptions(
  const AOptions: TRickSQLConnectionOptions;
  out AError: string): Boolean;
begin
  AError := _ERROR_FULL_EDITION_REQUIRED_;
  Result := False;
end;
{$ENDIF}
end.


