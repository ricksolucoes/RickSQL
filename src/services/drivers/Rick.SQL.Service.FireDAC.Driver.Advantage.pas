unit Rick.SQL.Service.FireDAC.Driver.Advantage;

// Responsabilidade: configurar o contrato do driver FireDAC para bancos Advantage.
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
  TRickSQLServiceFireDACDriverAdvantage = class(
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
  FireDAC.Phys.ADS;

const
  _DRIVER_ID_ = 'ADS';
  _CLIENT_LIBRARY_32_ = 'ace32.dll';
  _CLIENT_LIBRARY_64_ = 'ace64.dll';
  _PARAM_SERVER_TYPES_ = 'ServerTypes';
  _SERVER_TYPE_LOCAL_ = 'Local';
  _SERVER_TYPE_REMOTE_ = 'Remote';

function TRickSQLServiceFireDACDriverAdvantage.CreateDriverLink(
  const AOwner: TComponent): TComponent;
var
  LDriverLink: TFDPhysADSDriverLink;
begin
  Result := nil;

  if not Assigned(AOwner) then
    Exit;

  LDriverLink := TFDPhysADSDriverLink.Create(AOwner);
  LDriverLink.VendorLib := _CLIENT_LIBRARY_32_;
  Result := LDriverLink;
end;

procedure TRickSQLServiceFireDACDriverAdvantage.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  inherited ApplyConnectionOptions(AOptions, AParameters);

  if not Assigned(AParameters) then
    Exit;

  if AOptions.Server = '' then
    AddParameter(AParameters, Parameter(_PARAM_SERVER_TYPES_, _SERVER_TYPE_LOCAL_))
  else
    AddParameter(AParameters, Parameter(_PARAM_SERVER_TYPES_, _SERVER_TYPE_REMOTE_));
end;

function TRickSQLServiceFireDACDriverAdvantage.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.Advantage, _DRIVER_ID_);
  Result.DefaultPort := 6262;
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Database
  ];
  Result.AddClientLibrary(_CLIENT_LIBRARY_32_);
  Result.AddClientLibrary(_CLIENT_LIBRARY_64_);
end;

end.
