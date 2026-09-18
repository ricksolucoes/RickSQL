unit Rick.SQL.Service.FireDAC.Driver.Base;

// Responsabilidade: definir o comportamento comum dos provedores de drivers FireDAC.
// NAO seleciona bancos, executa comandos SQL ou mantém estado global mutável.

interface

uses
  // RTL
  System.Classes,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Driver.Definition,
  Rick.SQL.Model.Contracts;

type
  TRickSQLFireDACConnectionParameter = record
    Name: string;
    Value: string;
    class function Create(const AName: string;
      const AValue: string): TRickSQLFireDACConnectionParameter; static;
  end;

  TRickSQLServiceFireDACDriverProvider = class abstract(TInterfacedObject,
    IRickSQLDriverProvider)
  private
    function ValidateServer(const AOptions: TRickSQLConnectionOptions;
      out AError: string): Boolean;
    function ValidateDatabase(const AOptions: TRickSQLConnectionOptions;
      out AError: string): Boolean;
    function ValidateUserName(const AOptions: TRickSQLConnectionOptions;
      out AError: string): Boolean;
    function ValidatePassword(const AOptions: TRickSQLConnectionOptions;
      out AError: string): Boolean;
  protected
    class function Parameter(const AName: string;
      const AValue: string): TRickSQLFireDACConnectionParameter; static;
    class procedure AddParameter(const AParameters: TStrings;
      const AParameter: TRickSQLFireDACConnectionParameter); static;
    procedure BeginParameters(const AParameters: TStrings);
    procedure ApplyServerOption(const AOptions: TRickSQLConnectionOptions;
      const AParameters: TStrings);
    procedure ApplyPortOption(const AOptions: TRickSQLConnectionOptions;
      const AParameters: TStrings);
    procedure ApplyDatabaseOption(const AOptions: TRickSQLConnectionOptions;
      const AParameters: TStrings);
    procedure ApplyCredentialOptions(const AOptions: TRickSQLConnectionOptions;
      const AParameters: TStrings);
    procedure ApplyCharacterSetOption(
      const AOptions: TRickSQLConnectionOptions;
      const AParameters: TStrings);
    procedure ApplyTimeoutOption(const AOptions: TRickSQLConnectionOptions;
      const AParameters: TStrings);
    procedure ApplyExtraOptions(const AOptions: TRickSQLConnectionOptions;
      const AParameters: TStrings);
    function ExtraParameterValue(const AOptions: TRickSQLConnectionOptions;
      const AName: string): string;
    function GetDefinition: TRickSQLDriverDefinition; virtual; abstract;
  public
    function Engine: TRickSQLDatabaseEngine;
    function Definition: TRickSQLDriverDefinition;
    function CreateDriverLink(const AOwner: TComponent): TComponent;
      virtual; abstract;
    procedure ApplyConnectionOptions(
      const AOptions: TRickSQLConnectionOptions;
      const AParameters: TStrings); virtual;
    function ValidateOptions(const AOptions: TRickSQLConnectionOptions;
      out AError: string): Boolean; virtual;
  end;

implementation

uses
  // RTL
  System.SysUtils;

const
  _PARAM_DRIVER_ID_ = 'DriverID';
  _PARAM_SERVER_ = 'Server';
  _PARAM_PORT_ = 'Port';
  _PARAM_DATABASE_ = 'Database';
  _PARAM_USER_NAME_ = 'User_Name';
  _PARAM_PASSWORD_ = 'Password';
  _PARAM_CHARACTER_SET_ = 'CharacterSet';
  _PARAM_LOGIN_TIMEOUT_ = 'LoginTimeout';
  _ERROR_SERVER_REQUIRED_ =
    'O servidor do banco de dados deve ser informado. ' +
    'Preencha Server nas opções de conexão.';
  _ERROR_DATABASE_REQUIRED_ =
    'O banco de dados ou arquivo deve ser informado. ' +
    'Preencha Database nas opções de conexão.';
  _ERROR_USER_REQUIRED_ =
    'O usuário do banco de dados deve ser informado. ' +
    'Preencha UserName nas opções de conexão.';
  _ERROR_PASSWORD_REQUIRED_ =
    'A senha do banco de dados deve ser informada. ' +
    'Preencha Password nas opções de conexão.';

class function TRickSQLFireDACConnectionParameter.Create(
  const AName: string;
  const AValue: string): TRickSQLFireDACConnectionParameter;
begin
  Result.Name := AName;
  Result.Value := AValue;
end;

class function TRickSQLServiceFireDACDriverProvider.Parameter(
  const AName: string;
  const AValue: string): TRickSQLFireDACConnectionParameter;
begin
  Result := TRickSQLFireDACConnectionParameter.Create(AName, AValue);
end;

class procedure TRickSQLServiceFireDACDriverProvider.AddParameter(
  const AParameters: TStrings;
  const AParameter: TRickSQLFireDACConnectionParameter);
begin
  if not Assigned(AParameters) then
    Exit;

  if Trim(AParameter.Name) = '' then
    Exit;

  if AParameter.Value = '' then
    Exit;

  AParameters.Values[AParameter.Name] := AParameter.Value;
end;

procedure TRickSQLServiceFireDACDriverProvider.BeginParameters(
  const AParameters: TStrings);
begin
  if not Assigned(AParameters) then
    Exit;

  AParameters.Clear;
  AddParameter(AParameters, Parameter(_PARAM_DRIVER_ID_, GetDefinition.DriverID));
end;

procedure TRickSQLServiceFireDACDriverProvider.ApplyServerOption(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  AddParameter(AParameters, Parameter(_PARAM_SERVER_, AOptions.Server));
end;

procedure TRickSQLServiceFireDACDriverProvider.ApplyPortOption(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  if AOptions.Port <= 0 then
    Exit;

  AddParameter(AParameters, Parameter(_PARAM_PORT_, IntToStr(AOptions.Port)));
end;

procedure TRickSQLServiceFireDACDriverProvider.ApplyDatabaseOption(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  AddParameter(AParameters, Parameter(_PARAM_DATABASE_, AOptions.Database));
end;

procedure TRickSQLServiceFireDACDriverProvider.ApplyCredentialOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  AddParameter(AParameters, Parameter(_PARAM_USER_NAME_, AOptions.UserName));
  AddParameter(AParameters, Parameter(_PARAM_PASSWORD_, AOptions.Password));
end;

procedure TRickSQLServiceFireDACDriverProvider.ApplyCharacterSetOption(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  AddParameter(AParameters, Parameter(_PARAM_CHARACTER_SET_, AOptions.CharacterSet));
end;

procedure TRickSQLServiceFireDACDriverProvider.ApplyTimeoutOption(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  if AOptions.ConnectTimeout <= 0 then
    Exit;

  AddParameter(AParameters, Parameter(_PARAM_LOGIN_TIMEOUT_,
    IntToStr(AOptions.ConnectTimeout)));
end;

procedure TRickSQLServiceFireDACDriverProvider.ApplyExtraOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
var
  LParameter: TRickSQLConnectionParameter;
begin
  for LParameter in AOptions.ExtraParameters do
    AddParameter(AParameters, Parameter(LParameter.Name, LParameter.Value));
end;

function TRickSQLServiceFireDACDriverProvider.ExtraParameterValue(
  const AOptions: TRickSQLConnectionOptions;
  const AName: string): string;
var
  LParameter: TRickSQLConnectionParameter;
begin
  Result := '';

  for LParameter in AOptions.ExtraParameters do
    if SameText(Trim(LParameter.Name), Trim(AName)) then
      Exit(LParameter.Value);
end;

procedure TRickSQLServiceFireDACDriverProvider.ApplyConnectionOptions(
  const AOptions: TRickSQLConnectionOptions;
  const AParameters: TStrings);
begin
  if not Assigned(AParameters) then
    Exit;

  BeginParameters(AParameters);
  ApplyServerOption(AOptions, AParameters);
  ApplyPortOption(AOptions, AParameters);
  ApplyDatabaseOption(AOptions, AParameters);
  ApplyCredentialOptions(AOptions, AParameters);
  ApplyCharacterSetOption(AOptions, AParameters);
  ApplyTimeoutOption(AOptions, AParameters);
  ApplyExtraOptions(AOptions, AParameters);
end;

function TRickSQLServiceFireDACDriverProvider.Definition
  : TRickSQLDriverDefinition;
begin
  Result := GetDefinition;
end;

function TRickSQLServiceFireDACDriverProvider.Engine
  : TRickSQLDatabaseEngine;
begin
  Result := GetDefinition.Engine;
end;

function TRickSQLServiceFireDACDriverProvider.ValidateServer(
  const AOptions: TRickSQLConnectionOptions;
  out AError: string): Boolean;
begin
  Result := not GetDefinition.Requires(
    TRickSQLConnectionRequirement.Server) or
    (Trim(AOptions.Server) <> '');

  if not Result then
    AError := _ERROR_SERVER_REQUIRED_;
end;

function TRickSQLServiceFireDACDriverProvider.ValidateDatabase(
  const AOptions: TRickSQLConnectionOptions;
  out AError: string): Boolean;
begin
  Result := not GetDefinition.Requires(
    TRickSQLConnectionRequirement.Database) or
    (Trim(AOptions.Database) <> '');

  if not Result then
    AError := _ERROR_DATABASE_REQUIRED_;
end;

function TRickSQLServiceFireDACDriverProvider.ValidateUserName(
  const AOptions: TRickSQLConnectionOptions;
  out AError: string): Boolean;
begin
  Result := not GetDefinition.Requires(
    TRickSQLConnectionRequirement.UserName) or
    (Trim(AOptions.UserName) <> '');

  if not Result then
    AError := _ERROR_USER_REQUIRED_;
end;

function TRickSQLServiceFireDACDriverProvider.ValidatePassword(
  const AOptions: TRickSQLConnectionOptions;
  out AError: string): Boolean;
begin
  Result := not GetDefinition.Requires(
    TRickSQLConnectionRequirement.Password) or
    (AOptions.Password <> '');

  if not Result then
    AError := _ERROR_PASSWORD_REQUIRED_;
end;

function TRickSQLServiceFireDACDriverProvider.ValidateOptions(
  const AOptions: TRickSQLConnectionOptions;
  out AError: string): Boolean;
begin
  AError := '';

  if not ValidateServer(AOptions, AError) then
    Exit(False);

  if not ValidateDatabase(AOptions, AError) then
    Exit(False);

  if not ValidateUserName(AOptions, AError) then
    Exit(False);

  Result := ValidatePassword(AOptions, AError);
end;

end.
