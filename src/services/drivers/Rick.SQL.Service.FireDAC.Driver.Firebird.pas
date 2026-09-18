unit Rick.SQL.Service.FireDAC.Driver.Firebird;

// Responsabilidade: configurar o driver FireDAC para bancos Firebird.
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
  TRickSQLServiceFireDACDriverFirebird = class(
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
  FireDAC.Phys.FB;

const
  _DRIVER_ID_ = 'FB';
  _CLIENT_LIBRARY_ = 'fbclient.dll';
  _PARAM_PROTOCOL_ = 'Protocol';
  _PROTOCOL_TCP_IP_ = 'TCPIP';

function TRickSQLServiceFireDACDriverFirebird.CreateDriverLink(
  const AOwner: TComponent): TComponent;
begin
  Result := nil;

  if not Assigned(AOwner) then
    Exit;

  Result := TFDPhysFBDriverLink.Create(AOwner);
end;

procedure TRickSQLServiceFireDACDriverFirebird.ApplyConnectionOptions(
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

function TRickSQLServiceFireDACDriverFirebird.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.Firebird, _DRIVER_ID_);
  Result.DefaultPort := 3050;
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Database,
    TRickSQLConnectionRequirement.UserName,
    TRickSQLConnectionRequirement.Password
  ];
  Result.AddClientLibrary(_CLIENT_LIBRARY_);
end;

end.
