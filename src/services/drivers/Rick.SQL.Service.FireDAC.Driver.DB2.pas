unit Rick.SQL.Service.FireDAC.Driver.DB2;

// Responsabilidade: configurar o contrato do driver FireDAC para bancos DB2.
// NAO executa comandos SQL, materializa datasets ou conhece outros bancos.

{$IFDEF FULL_EDITION}

interface

uses
  // RTL
  System.Classes,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Driver.Definition,
  Rick.SQL.Service.FireDAC.Driver.Base;

type
  TRickSQLServiceFireDACDriverDB2 = class(
    TRickSQLServiceFireDACDriverProvider)
  protected
    function GetDefinition: TRickSQLDriverDefinition; override;
  public
    function CreateDriverLink(const AOwner: TComponent): TComponent; override;
  end;

implementation

uses
  // FireDAC
  FireDAC.Phys.DB2,

  // RickSQL
  Rick.SQL.Service.FireDAC.Driver.VendorLibrary;

const
  _DRIVER_ID_ = 'DB2';
  _CLIENT_LIBRARY_ = 'db2cli.dll';

function TRickSQLServiceFireDACDriverDB2.CreateDriverLink(
  const AOwner: TComponent): TComponent;
var
  LDriverLink: TFDPhysDB2DriverLink;
begin
  Result := nil;

  if not Assigned(AOwner) then
    Exit;

  LDriverLink := TFDPhysDB2DriverLink.Create(AOwner);
  TRickSQLServiceFireDACDriverVendorLibrary.Apply(
    LDriverLink, _CLIENT_LIBRARY_);
  Result := LDriverLink;
end;

function TRickSQLServiceFireDACDriverDB2.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.DB2, _DRIVER_ID_);
  Result.DefaultPort := 50000;
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
  TRickSQLServiceFireDACDriverDB2 = class(
    TRickSQLServiceFireDACDriverProvider)
  private
    procedure RaiseFullEditionRequired;
  protected
    function GetDefinition: TRickSQLDriverDefinition; override;
  public
    function CreateDriverLink(const AOwner: TComponent): TComponent; override;
    function ValidateOptions(const AOptions: TRickSQLConnectionOptions;
      out AError: string): Boolean; override;
  end;

implementation

uses
  // RTL
  System.SysUtils;

const
  _DRIVER_ID_ = 'DB2';
  _ERROR_FULL_EDITION_REQUIRED_ =
    'O driver DB2 exige a diretiva FULL_EDITION habilitada. ' +
    'Ative FULL_EDITION nas opções de compilação ou selecione outro mecanismo de banco.';

procedure TRickSQLServiceFireDACDriverDB2.RaiseFullEditionRequired;
begin
  raise Exception.Create(_ERROR_FULL_EDITION_REQUIRED_);
end;

function TRickSQLServiceFireDACDriverDB2.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.DB2, _DRIVER_ID_);
  Result.DefaultPort := 50000;
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Server,
    TRickSQLConnectionRequirement.Database,
    TRickSQLConnectionRequirement.UserName,
    TRickSQLConnectionRequirement.Password
  ];
end;

function TRickSQLServiceFireDACDriverDB2.CreateDriverLink(
  const AOwner: TComponent): TComponent;
begin
  Result := nil;
  RaiseFullEditionRequired;
end;

function TRickSQLServiceFireDACDriverDB2.ValidateOptions(
  const AOptions: TRickSQLConnectionOptions;
  out AError: string): Boolean;
begin
  AError := _ERROR_FULL_EDITION_REQUIRED_;
  Result := False;
end;

{$ENDIF}

end.
