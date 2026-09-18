unit Rick.SQL.Service.FireDAC.Driver.ODBC;

// Responsabilidade: configurar o driver FireDAC para fontes de dados ODBC.
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
  TRickSQLServiceFireDACDriverODBC = class(
    TRickSQLServiceFireDACDriverProvider)
  private
    function HasDataSource(const AOptions: TRickSQLConnectionOptions): Boolean;
    function HasODBCDriver(const AOptions: TRickSQLConnectionOptions): Boolean;
    function ValidateSource(const AOptions: TRickSQLConnectionOptions;
      out AError: string): Boolean;
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
  System.SysUtils,

  // FireDAC
  FireDAC.Phys.ODBC;

const
  _DRIVER_ID_ = 'ODBC';
  _CLIENT_LIBRARY_ = 'odbc32.dll';
  _PARAM_DATA_SOURCE_ = 'DataSource';
  _PARAM_ODBC_DRIVER_ = 'ODBCDriver';
  _ERROR_SOURCE_REQUIRED_ =
    'Informe uma fonte de dados ODBC ou o nome de um driver ODBC. ' +
    'Preencha Database ou o parâmetro adicional ODBCDriver.';
  _ERROR_SOURCE_CONFLICT_ =
    'DataSource e ODBCDriver não podem ser informados ao mesmo tempo. ' +
    'Remova uma das opções antes de conectar.';

function TRickSQLServiceFireDACDriverODBC.HasDataSource(
  const AOptions: TRickSQLConnectionOptions): Boolean;
begin
  Result := (Trim(AOptions.Database) <> '') or
    (Trim(ExtraParameterValue(AOptions, _PARAM_DATA_SOURCE_)) <> '');
end;

function TRickSQLServiceFireDACDriverODBC.HasODBCDriver(
  const AOptions: TRickSQLConnectionOptions): Boolean;
begin
  Result := Trim(ExtraParameterValue(
    AOptions, _PARAM_ODBC_DRIVER_)) <> '';
end;

function TRickSQLServiceFireDACDriverODBC.ValidateSource(
  const AOptions: TRickSQLConnectionOptions;
  out AError: string): Boolean;
begin
  if HasDataSource(AOptions) and HasODBCDriver(AOptions) then
  begin
    AError := _ERROR_SOURCE_CONFLICT_;
    Exit(False);
  end;

  Result := HasDataSource(AOptions) or HasODBCDriver(AOptions);
  if not Result then
    AError := _ERROR_SOURCE_REQUIRED_;
end;

function TRickSQLServiceFireDACDriverODBC.CreateDriverLink(
  const AOwner: TComponent): TComponent;
begin
  Result := nil;

  if not Assigned(AOwner) then
    Exit;

  Result := TFDPhysODBCDriverLink.Create(AOwner);
end;

procedure TRickSQLServiceFireDACDriverODBC.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  if not Assigned(AParameters) then
    Exit;

  BeginParameters(AParameters);
  if not HasODBCDriver(AOptions) then
    AddParameter(AParameters, Parameter(_PARAM_DATA_SOURCE_, AOptions.Database));
  ApplyCredentialOptions(AOptions, AParameters);
  ApplyTimeoutOption(AOptions, AParameters);
  ApplyExtraOptions(AOptions, AParameters);
end;

function TRickSQLServiceFireDACDriverODBC.ValidateOptions(
  const AOptions: TRickSQLConnectionOptions;
  out AError: string): Boolean;
begin
  if not inherited ValidateOptions(AOptions, AError) then
    Exit(False);

  Result := ValidateSource(AOptions, AError);
end;

function TRickSQLServiceFireDACDriverODBC.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.ODBC, _DRIVER_ID_);
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
  TRickSQLServiceFireDACDriverODBC = class(
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
  _DRIVER_ID_ = 'ODBC';
  _ERROR_FULL_EDITION_REQUIRED_ =
    'O driver ODBC exige a diretiva FULL_EDITION habilitada. ' +
    'Ative FULL_EDITION nas opções de compilação ou selecione outro mecanismo de banco.';

procedure TRickSQLServiceFireDACDriverODBC.RaiseFullEditionRequired;
begin
  raise Exception.Create(_ERROR_FULL_EDITION_REQUIRED_);
end;

function TRickSQLServiceFireDACDriverODBC.GetDefinition
  : TRickSQLDriverDefinition;
begin
  Result := TRickSQLDriverDefinition.Create(
    TRickSQLDatabaseEngine.ODBC, _DRIVER_ID_);
end;

function TRickSQLServiceFireDACDriverODBC.CreateDriverLink(
  const AOwner: TComponent): TComponent;
begin
  Result := nil;
  RaiseFullEditionRequired;
end;

procedure TRickSQLServiceFireDACDriverODBC.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  RaiseFullEditionRequired;
end;

function TRickSQLServiceFireDACDriverODBC.ValidateOptions(
  const AOptions: TRickSQLConnectionOptions;
  out AError: string): Boolean;
begin
  AError := _ERROR_FULL_EDITION_REQUIRED_;
  Result := False;
end;


{$ENDIF}

end.


