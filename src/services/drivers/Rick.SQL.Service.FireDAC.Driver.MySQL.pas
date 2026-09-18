unit Rick.SQL.Service.FireDAC.Driver.MySQL;

// Responsabilidade: configurar o driver FireDAC para bancos MySQL.
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
  TRickSQLServiceFireDACDriverMySQL = class(
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
  FireDAC.Phys.MySQL;

const
  _DRIVER_ID_ = 'MySQL';
  _CLIENT_LIBRARY_ = 'libmysql.dll';
  _PARAM_PROTOCOL_ = 'Protocol';
  _PROTOCOL_TCP_IP_ = 'TCPIP';

function TRickSQLServiceFireDACDriverMySQL.CreateDriverLink(
  const AOwner: TComponent): TComponent;
begin
  Result := nil;

  if not Assigned(AOwner) then
    Exit;

  Result := TFDPhysMySQLDriverLink.Create(AOwner);
end;

procedure TRickSQLServiceFireDACDriverMySQL.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  inherited ApplyConnectionOptions(AOptions, AParameters);

  if not Assigned(AParameters) then
    Exit;

  AddParameter(AParameters, Parameter(_PARAM_PROTOCOL_, _PROTOCOL_TCP_IP_));
end;

function TRickSQLServiceFireDACDriverMySQL.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.MySQL, _DRIVER_ID_);
  Result.DefaultPort := 3306;
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Server,
    TRickSQLConnectionRequirement.Database,
    TRickSQLConnectionRequirement.UserName,
    TRickSQLConnectionRequirement.Password
  ];
  Result.AddClientLibrary(_CLIENT_LIBRARY_);
end;

end.
