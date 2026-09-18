unit Rick.SQL.Service.FireDAC.Driver.InterBase;

// Responsabilidade: configurar o contrato do driver FireDAC para bancos InterBase.
// NAO executa comandos SQL, materializa datasets ou conhece outros bancos.

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
  TRickSQLServiceFireDACDriverInterBase = class(
    TRickSQLServiceFireDACDriverProvider)
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
  FireDAC.Phys.IB;

const
  _DRIVER_ID_ = 'IB';
  _CLIENT_LIBRARY_ = 'gds32.dll';
  _CLIENT_LIBRARY_TO_GO_32_ = 'ibtogo.dll';
  _CLIENT_LIBRARY_TO_GO_64_ = 'ibtogo64.dll';
  _PARAM_PROTOCOL_ = 'Protocol';
  _PROTOCOL_TCP_IP_ = 'TCPIP';

function TRickSQLServiceFireDACDriverInterBase.CreateDriverLink(
  const AOwner: TComponent): TComponent;
var
  LDriverLink: TFDPhysIBDriverLink;
begin
  Result := nil;

  if not Assigned(AOwner) then
    Exit;

  LDriverLink := TFDPhysIBDriverLink.Create(AOwner);
  LDriverLink.VendorLib := _CLIENT_LIBRARY_;
  Result := LDriverLink;
end;

procedure TRickSQLServiceFireDACDriverInterBase.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  inherited ApplyConnectionOptions(AOptions, AParameters);

  if not Assigned(AParameters) then
    Exit;

  if Trim(AOptions.Server) = '' then
    Exit;

  AddParameter(AParameters, Parameter(_PARAM_PROTOCOL_, _PROTOCOL_TCP_IP_));
end;

function TRickSQLServiceFireDACDriverInterBase.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.InterBase, _DRIVER_ID_);
  Result.DefaultPort := 3050;
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Database,
    TRickSQLConnectionRequirement.UserName,
    TRickSQLConnectionRequirement.Password
  ];
  Result.AddClientLibrary(_CLIENT_LIBRARY_);
  Result.AddClientLibrary(_CLIENT_LIBRARY_TO_GO_32_);
  Result.AddClientLibrary(_CLIENT_LIBRARY_TO_GO_64_);
end;

end.
