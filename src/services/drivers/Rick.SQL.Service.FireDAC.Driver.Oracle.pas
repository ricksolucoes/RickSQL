unit Rick.SQL.Service.FireDAC.Driver.Oracle;

// Responsabilidade: configurar o driver FireDAC para bancos Oracle.
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
  TRickSQLServiceFireDACDriverOracle = class(
    TRickSQLServiceFireDACDriverProvider)
  private
    function BuildDatabase(const AOptions: TRickSQLConnectionOptions): string;
  protected
    function GetDefinition: TRickSQLDriverDefinition; override;
  public
    function CreateDriverLink(const AOwner: TComponent): TComponent; override;
    procedure ApplyConnectionOptions(
      const AOptions: TRickSQLConnectionOptions;
      const AParameters: TStrings); override;
  end;

implementation

uses
  // RTL
  System.SysUtils,

  // FireDAC
  FireDAC.Phys.Oracle;

const
  _DRIVER_ID_ = 'Ora';
  _CLIENT_LIBRARY_ = 'oci.dll';
  _PARAM_DATABASE_ = 'Database';
  _EASY_CONNECT_FORMAT_ = '//%s:%d/%s';

function TRickSQLServiceFireDACDriverOracle.BuildDatabase(
  const AOptions: TRickSQLConnectionOptions): string;
var
  LPort: Integer;
begin
  Result := Trim(AOptions.Database);

  if Trim(AOptions.Server) = '' then
    Exit;

  LPort := AOptions.Port;
  if LPort <= 0 then
    LPort := GetDefinition.DefaultPort;

  Result := Format(_EASY_CONNECT_FORMAT_,
    [Trim(AOptions.Server), LPort, Result]);
end;

function TRickSQLServiceFireDACDriverOracle.CreateDriverLink(
  const AOwner: TComponent): TComponent;
begin
  Result := nil;

  if not Assigned(AOwner) then
    Exit;

  Result := TFDPhysOracleDriverLink.Create(AOwner);
end;

procedure TRickSQLServiceFireDACDriverOracle.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  if not Assigned(AParameters) then
    Exit;

  BeginParameters(AParameters);
  AddParameter(AParameters, Parameter(_PARAM_DATABASE_, BuildDatabase(AOptions)));
  ApplyCredentialOptions(AOptions, AParameters);
  ApplyTimeoutOption(AOptions, AParameters);
  ApplyExtraOptions(AOptions, AParameters);
end;

function TRickSQLServiceFireDACDriverOracle.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.Oracle, _DRIVER_ID_);
  Result.DefaultPort := 1521;
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Database,
    TRickSQLConnectionRequirement.UserName,
    TRickSQLConnectionRequirement.Password
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
  TRickSQLServiceFireDACDriverOracle = class(
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
  _DRIVER_ID_ = 'Ora';
  _ERROR_FULL_EDITION_REQUIRED_ =
    'O driver Oracle exige a diretiva FULL_EDITION habilitada. ' +
    'Ative FULL_EDITION nas opções de compilação ou selecione outro mecanismo de banco.';

procedure TRickSQLServiceFireDACDriverOracle.RaiseFullEditionRequired;
begin
  raise Exception.Create(_ERROR_FULL_EDITION_REQUIRED_);
end;

function TRickSQLServiceFireDACDriverOracle.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.Oracle, _DRIVER_ID_);
  Result.DefaultPort := 1521;
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Database,
    TRickSQLConnectionRequirement.UserName,
    TRickSQLConnectionRequirement.Password
  ];
end;

function TRickSQLServiceFireDACDriverOracle.CreateDriverLink(
  const AOwner: TComponent): TComponent;
begin
  Result := nil;
  RaiseFullEditionRequired;
end;

procedure TRickSQLServiceFireDACDriverOracle.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  RaiseFullEditionRequired;
end;

function TRickSQLServiceFireDACDriverOracle.ValidateOptions(
  const AOptions: TRickSQLConnectionOptions;
  out AError: string): Boolean;
begin
  AError := _ERROR_FULL_EDITION_REQUIRED_;
  Result := False;
end;

{$ENDIF}

end.


