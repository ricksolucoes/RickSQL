unit Rick.SQL.Service.FireDAC.Parameter.Binder;

// Responsabilidade: aplicar parâmetros do RickSQL aos parâmetros de uma query FireDAC.
// NAO valida conexão, executa comandos SQL ou conhece interface visual.

interface

uses
  // FireDAC
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,

  // RickSQL
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Error,
  Rick.SQL.Model.Parameter;

type
  TRickSQLFireDACParameterBindSetup = record
    Query: TFDQuery;
    Command: TRickSQLCommand;
    class function Create(const AQuery: TFDQuery;
      const ACommand: TRickSQLCommand): TRickSQLFireDACParameterBindSetup; static;
  end;

  TRickSQLServiceFireDACParameterBinder = class
  private
    class function CreateParameterError(const AMessage: string;
      const ADetail: string): TRickSQLError; static;
    class function ValidateSetup(
      const ASetup: TRickSQLFireDACParameterBindSetup;
      out AError: TRickSQLError): Boolean; static;
    class function FindFDParam(const AQuery: TFDQuery;
      const AParameter: TRickSQLParameter): TFDParam; static;
    class function CreateMissingParameterError(
      const AParameter: TRickSQLParameter): TRickSQLError; static;
    class function ApplyWithError(const AFDParam: TFDParam;
      const AParameter: TRickSQLParameter;
      out AError: TRickSQLError): Boolean; static;
    class function BindParameter(
      const ASetup: TRickSQLFireDACParameterBindSetup;
      const AIndex: Integer; out AError: TRickSQLError): Boolean; static;
  public
    class function Bind(const ASetup: TRickSQLFireDACParameterBindSetup;
      out AError: TRickSQLError): Boolean; static;
  end;

implementation

uses
  // RTL
  System.SysUtils,

  // Data
  Data.DB,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Error.Normalizer;

const
  _OPERATION_ = 'Aplicação de parâmetros FireDAC';
  _ERROR_QUERY_NOT_ASSIGNED_ =
    'A query FireDAC não foi criada. Prepare a sessão antes de aplicar parâmetros.';
  _ERROR_PARAM_NOT_FOUND_ =
    'O parâmetro SQL "%s" não foi localizado na query FireDAC. Confira se o nome existe no SQL informado.';
  _ERROR_BIND_PARAMETER_ =
    'Não foi possível aplicar o parâmetro SQL "%s" na query FireDAC. Verifique tipo, tamanho e valor do parâmetro.';

procedure ApplyParameter(const AFDParam: TFDParam;
  const AParameter: TRickSQLParameter); forward;

class function TRickSQLFireDACParameterBindSetup.Create(
  const AQuery: TFDQuery;
  const ACommand: TRickSQLCommand): TRickSQLFireDACParameterBindSetup;
begin
  Result.Query := AQuery;
  Result.Command := ACommand;
end;

class function TRickSQLServiceFireDACParameterBinder.Bind(
  const ASetup: TRickSQLFireDACParameterBindSetup;
  out AError: TRickSQLError): Boolean;
var
  LIndex: Integer;
begin
  AError := TRickSQLError.Empty;

  if not ValidateSetup(ASetup, AError) then
    Exit(False);

  for LIndex := 0 to Length(ASetup.Command.Parameters) - 1 do
    if not BindParameter(ASetup, LIndex, AError) then
      Exit(False);

  Result := True;
end;

class function TRickSQLServiceFireDACParameterBinder.BindParameter(
  const ASetup: TRickSQLFireDACParameterBindSetup;
  const AIndex: Integer; out AError: TRickSQLError): Boolean;
var
  LParameter: TRickSQLParameter;
  LFDParam: TFDParam;
begin
  LParameter := ASetup.Command.Parameters[AIndex];
  LFDParam := FindFDParam(ASetup.Query, LParameter);

  if not Assigned(LFDParam) then
  begin
    AError := CreateMissingParameterError(LParameter);
    Exit(False);
  end;

  Result := ApplyWithError(LFDParam, LParameter, AError);
end;

class function TRickSQLServiceFireDACParameterBinder.FindFDParam(
  const AQuery: TFDQuery; const AParameter: TRickSQLParameter): TFDParam;
begin
  Result := AQuery.Params.FindParam(Trim(AParameter.Name));
end;

class function TRickSQLServiceFireDACParameterBinder.CreateMissingParameterError(
  const AParameter: TRickSQLParameter): TRickSQLError;
begin
  Result := CreateParameterError(Format(_ERROR_PARAM_NOT_FOUND_,
    [AParameter.Name]), '');
end;

class function TRickSQLServiceFireDACParameterBinder.ApplyWithError(
  const AFDParam: TFDParam; const AParameter: TRickSQLParameter;
  out AError: TRickSQLError): Boolean;
begin
  Result := False;
  try
    ApplyParameter(AFDParam, AParameter);
    Result := True;
  except
    on E: Exception do
      AError := TRickSQLErrorNormalizer.FromException(E,
        TRickSQLErrorKind.Parameter, Format(_ERROR_BIND_PARAMETER_,
        [AParameter.Name]), _OPERATION_);
  end;
end;

class function TRickSQLServiceFireDACParameterBinder.CreateParameterError(
  const AMessage: string; const ADetail: string): TRickSQLError;
begin
  Result := TRickSQLErrorNormalizer.FromDetail(TRickSQLErrorKind.Parameter,
    AMessage, ADetail, _OPERATION_);
end;

class function TRickSQLServiceFireDACParameterBinder.ValidateSetup(
  const ASetup: TRickSQLFireDACParameterBindSetup;
  out AError: TRickSQLError): Boolean;
begin
  Result := Assigned(ASetup.Query);
  if not Result then
    AError := CreateParameterError(_ERROR_QUERY_NOT_ASSIGNED_, '');
end;

procedure ApplyDataType(const AFDParam: TFDParam;
  const AParameter: TRickSQLParameter);
begin
  if AParameter.DataType = ftUnknown then
    Exit;

  AFDParam.DataType := AParameter.DataType;
end;

procedure ApplyDirection(const AFDParam: TFDParam;
  const AParameter: TRickSQLParameter);
begin
  AFDParam.ParamType := AParameter.Direction;
end;

procedure ApplySize(const AFDParam: TFDParam;
  const AParameter: TRickSQLParameter);
begin
  if AParameter.Size <= 0 then
    Exit;

  AFDParam.Size := AParameter.Size;
end;

procedure ApplyValue(const AFDParam: TFDParam;
  const AParameter: TRickSQLParameter);
begin
  if AParameter.IsNull then
  begin
    AFDParam.Clear;
    Exit;
  end;

  AFDParam.Value := AParameter.Value;
end;

procedure ApplyParameter(const AFDParam: TFDParam;
  const AParameter: TRickSQLParameter);
begin
  ApplyDataType(AFDParam, AParameter);
  ApplyDirection(AFDParam, AParameter);
  ApplySize(AFDParam, AParameter);
  ApplyValue(AFDParam, AParameter);
end;

end.
