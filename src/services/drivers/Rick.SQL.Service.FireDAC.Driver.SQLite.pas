unit Rick.SQL.Service.FireDAC.Driver.SQLite;

// Responsabilidade: configurar o driver FireDAC para bancos SQLite.
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
  TRickSQLServiceFireDACDriverSQLite = class(
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
  FireDAC.Phys.SQLite;

const
  _DRIVER_ID_ = 'SQLite';

function TRickSQLServiceFireDACDriverSQLite.CreateDriverLink(
  const AOwner: TComponent): TComponent;
begin
  Result := nil;

  if not Assigned(AOwner) then
    Exit;

  Result := TFDPhysSQLiteDriverLink.Create(AOwner);
end;

procedure TRickSQLServiceFireDACDriverSQLite.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  if not Assigned(AParameters) then
    Exit;

  BeginParameters(AParameters);
  ApplyDatabaseOption(AOptions, AParameters);
  ApplyExtraOptions(AOptions, AParameters);
end;

function TRickSQLServiceFireDACDriverSQLite.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.SQLite, _DRIVER_ID_);
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Database
  ];
end;

end.
