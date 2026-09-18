unit Rick.SQL.Service.FireDAC.Driver.Informix;

// Responsabilidade: configurar o contrato do driver FireDAC para bancos Informix.
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
  TRickSQLServiceFireDACDriverInformix = class(
    TRickSQLServiceFireDACDriverProvider)
  private
    function ResolveInformixServer(
      const AOptions: TRickSQLConnectionOptions): string;
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
  FireDAC.Phys.Infx;

const
  _DRIVER_ID_ = 'Infx';
  _CLIENT_LIBRARY_ = 'iclit09b.dll';
  _PARAM_HOST_NAME_ = 'HostName';
  _PARAM_SERVER_ = 'Server';
  _PARAM_PROTOCOL_ = 'Protocol';
  _PARAM_INFORMIX_SERVER_ = 'InformixServer';
  _PROTOCOL_ = 'olsoctcp';

function TRickSQLServiceFireDACDriverInformix.ResolveInformixServer(
  const AOptions: TRickSQLConnectionOptions): string;
begin
  Result := ExtraParameterValue(AOptions, _PARAM_INFORMIX_SERVER_);

  if Trim(Result) <> '' then
    Exit;

  Result := AOptions.Server;
end;

function TRickSQLServiceFireDACDriverInformix.CreateDriverLink(
  const AOwner: TComponent): TComponent;
var
  LDriverLink: TFDPhysInfxDriverLink;
begin
  Result := nil;

  if not Assigned(AOwner) then
    Exit;

  LDriverLink := TFDPhysInfxDriverLink.Create(AOwner);
  LDriverLink.VendorLib := _CLIENT_LIBRARY_;
  Result := LDriverLink;
end;

procedure TRickSQLServiceFireDACDriverInformix.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  inherited ApplyConnectionOptions(AOptions, AParameters);

  if not Assigned(AParameters) then
    Exit;

  AddParameter(AParameters, Parameter(_PARAM_HOST_NAME_, AOptions.Server));
  AddParameter(AParameters,
    Parameter(_PARAM_SERVER_, ResolveInformixServer(AOptions)));
  AddParameter(AParameters, Parameter(_PARAM_PROTOCOL_, _PROTOCOL_));
end;

function TRickSQLServiceFireDACDriverInformix.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.Informix, _DRIVER_ID_);
  Result.DefaultPort := 9088;
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Server,
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
  TRickSQLServiceFireDACDriverInformix = class(
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
  _DRIVER_ID_ = 'Infx';
  _ERROR_FULL_EDITION_REQUIRED_ =
    'O driver Informix exige a diretiva FULL_EDITION habilitada. ' +
    'Ative FULL_EDITION nas opções de compilação ou selecione outro mecanismo de banco.';

procedure TRickSQLServiceFireDACDriverInformix.RaiseFullEditionRequired;
begin
  raise Exception.Create(_ERROR_FULL_EDITION_REQUIRED_);
end;

function TRickSQLServiceFireDACDriverInformix.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.Informix, _DRIVER_ID_);
  Result.DefaultPort := 9088;
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Server,
    TRickSQLConnectionRequirement.Database,
    TRickSQLConnectionRequirement.UserName,
    TRickSQLConnectionRequirement.Password
  ];
end;

function TRickSQLServiceFireDACDriverInformix.CreateDriverLink(
  const AOwner: TComponent): TComponent;
begin
  Result := nil;
  RaiseFullEditionRequired;
end;

procedure TRickSQLServiceFireDACDriverInformix.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  RaiseFullEditionRequired;
end;

function TRickSQLServiceFireDACDriverInformix.ValidateOptions(
  const AOptions: TRickSQLConnectionOptions;
  out AError: string): Boolean;
begin
  AError := _ERROR_FULL_EDITION_REQUIRED_;
  Result := False;
end;


{$ENDIF}

end.


