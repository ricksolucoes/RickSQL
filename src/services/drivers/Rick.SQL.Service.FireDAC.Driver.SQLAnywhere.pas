unit Rick.SQL.Service.FireDAC.Driver.SQLAnywhere;

// Responsabilidade: configurar o contrato do driver FireDAC para bancos SQL Anywhere.
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
  TRickSQLServiceFireDACDriverSQLAnywhere = class(
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
  FireDAC.Phys.ASA;

const
  _DRIVER_ID_ = 'ASA';
  _CLIENT_LIBRARY_17_ = 'dbodbc17.dll';
  _CLIENT_LIBRARY_16_ = 'dbodbc16.dll';
  _CLIENT_LIBRARY_12_ = 'dbodbc12.dll';
  _PARAM_SERVER_NAME_ = 'Server';

function TRickSQLServiceFireDACDriverSQLAnywhere.CreateDriverLink(
  const AOwner: TComponent): TComponent;
var
  LDriverLink: TFDPhysASADriverLink;
begin
  Result := nil;

  if not Assigned(AOwner) then
    Exit;

  LDriverLink := TFDPhysASADriverLink.Create(AOwner);
  LDriverLink.VendorLib := _CLIENT_LIBRARY_17_;
  Result := LDriverLink;
end;

procedure TRickSQLServiceFireDACDriverSQLAnywhere.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  inherited ApplyConnectionOptions(AOptions, AParameters);

  if not Assigned(AParameters) then
    Exit;

  AddParameter(AParameters, Parameter(_PARAM_SERVER_NAME_, AOptions.Server));
end;

function TRickSQLServiceFireDACDriverSQLAnywhere.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.SQLAnywhere, _DRIVER_ID_);
  Result.DefaultPort := 2638;
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Database,
    TRickSQLConnectionRequirement.UserName,
    TRickSQLConnectionRequirement.Password
  ];
  Result.AddClientLibrary(_CLIENT_LIBRARY_17_);
  Result.AddClientLibrary(_CLIENT_LIBRARY_16_);
  Result.AddClientLibrary(_CLIENT_LIBRARY_12_);
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
  TRickSQLServiceFireDACDriverSQLAnywhere = class(
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
  _DRIVER_ID_ = 'ASA';
  _ERROR_FULL_EDITION_REQUIRED_ =
    'O driver SQL Anywhere exige a diretiva FULL_EDITION habilitada. ' +
    'Ative FULL_EDITION nas opções de compilação ou selecione outro mecanismo de banco.';

procedure TRickSQLServiceFireDACDriverSQLAnywhere.RaiseFullEditionRequired;
begin
  raise Exception.Create(_ERROR_FULL_EDITION_REQUIRED_);
end;

function TRickSQLServiceFireDACDriverSQLAnywhere.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.SQLAnywhere, _DRIVER_ID_);
  Result.DefaultPort := 2638;
  Result.RequiredConnectionOptions := [
    TRickSQLConnectionRequirement.Database,
    TRickSQLConnectionRequirement.UserName,
    TRickSQLConnectionRequirement.Password
  ];
end;

function TRickSQLServiceFireDACDriverSQLAnywhere.CreateDriverLink(
  const AOwner: TComponent): TComponent;
begin
  Result := nil;
  RaiseFullEditionRequired;
end;

procedure TRickSQLServiceFireDACDriverSQLAnywhere.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  RaiseFullEditionRequired;
end;

function TRickSQLServiceFireDACDriverSQLAnywhere.ValidateOptions(
  const AOptions: TRickSQLConnectionOptions;
  out AError: string): Boolean;
begin
  AError := _ERROR_FULL_EDITION_REQUIRED_;
  Result := False;
end;

{$ENDIF}


end.


