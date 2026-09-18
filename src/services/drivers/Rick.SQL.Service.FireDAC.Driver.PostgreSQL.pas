unit Rick.SQL.Service.FireDAC.Driver.PostgreSQL;

// Responsabilidade: configurar o driver FireDAC para bancos PostgreSQL.
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
  TRickSQLServiceFireDACDriverPostgreSQL = class(
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
  // FireDAC
  FireDAC.Phys.PG;

const
  _DRIVER_ID_ = 'PG';
  _CLIENT_LIBRARY_ = 'libpq.dll';
  _PARAM_PROTOCOL_ = 'Protocol';
  _PROTOCOL_TCP_IP_ = 'TCPIP';

function TRickSQLServiceFireDACDriverPostgreSQL.CreateDriverLink(
  const AOwner: TComponent): TComponent;
begin
  Result := nil;

  if not Assigned(AOwner) then
    Exit;

  Result := TFDPhysPgDriverLink.Create(AOwner);
end;

procedure TRickSQLServiceFireDACDriverPostgreSQL.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  inherited ApplyConnectionOptions(AOptions, AParameters);

  if not Assigned(AParameters) then
    Exit;

  AddParameter(AParameters, Parameter(_PARAM_PROTOCOL_, _PROTOCOL_TCP_IP_));
end;

function TRickSQLServiceFireDACDriverPostgreSQL.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.PostgreSQL, _DRIVER_ID_);
  Result.DefaultPort := 5432;
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Server,
    TRickSQLConnectionRequirement.Database,
    TRickSQLConnectionRequirement.UserName,
    TRickSQLConnectionRequirement.Password
  ];
  Result.AddClientLibrary(_CLIENT_LIBRARY_);
end;

end.
