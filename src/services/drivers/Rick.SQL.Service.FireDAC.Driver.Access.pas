unit Rick.SQL.Service.FireDAC.Driver.Access;

// Responsabilidade: configurar o contrato do driver FireDAC para bancos Access.
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
  TRickSQLServiceFireDACDriverAccess = class(
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
  FireDAC.Phys.MSAcc;

const
  _DRIVER_ID_ = 'MSAcc';
  _CLIENT_LIBRARY_ = 'ACEODBC.DLL';
  _PARAM_DATABASE_ = 'Database';
  _PARAM_PASSWORD_ = 'Password';

function TRickSQLServiceFireDACDriverAccess.CreateDriverLink(
  const AOwner: TComponent): TComponent;
var
  LDriverLink: TFDPhysMSAccessDriverLink;
begin
  Result := nil;

  if not Assigned(AOwner) then
    Exit;

  LDriverLink := TFDPhysMSAccessDriverLink.Create(AOwner);
  Result := LDriverLink;
end;

procedure TRickSQLServiceFireDACDriverAccess.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  if not Assigned(AParameters) then
    Exit;

  BeginParameters(AParameters);
  AddParameter(AParameters, Parameter(_PARAM_DATABASE_, AOptions.Database));
  AddParameter(AParameters, Parameter(_PARAM_PASSWORD_, AOptions.Password));
  ApplyTimeoutOption(AOptions, AParameters);
  ApplyExtraOptions(AOptions, AParameters);
end;

function TRickSQLServiceFireDACDriverAccess.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.Access, _DRIVER_ID_);
  Result.DefaultPort := 0;
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Database
  ];
  Result.AddClientLibrary(_CLIENT_LIBRARY_);
end;

end.
