program RickSQL.FireDAC.Parameter.Binder.ContractTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,
  System.Variants,

  // Data
  Data.DB,

  // FireDAC
  FireDAC.Comp.Client,

  // RickSQL
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Error,
  Rick.SQL.Model.Parameter,
  Rick.SQL.Model.Types,
  Rick.SQL.Service.FireDAC.Parameter.Binder;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure AddFDParam(const AQuery: TFDQuery; const AName: string;
  const ADataType: TFieldType);
begin
  AQuery.Params.CreateParam(ADataType, AName, ptInput);
end;

function CreateCommand: TRickSQLCommand;
var
  LConnection: TRickSQLConnectionOptions;
  LParameter: TRickSQLParameter;
begin
  LConnection := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.SQLite);
  Result := TRickSQLCommand.Create(LConnection, 'select :ID, :NOME, :DATA');
  Result.AddParameter(TRickSQLParameter.Create('ID', 10));
  LParameter := TRickSQLParameter.Create('NOME', 'RickSQL');
  LParameter.DataType := ftString;
  LParameter.Size := 80;
  Result.AddParameter(LParameter);
  Result.AddParameter(TRickSQLParameter.CreateNull('DATA', ftDateTime));
end;

procedure TestBindSuccess;
var
  LQuery: TFDQuery;
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
begin
  LQuery := TFDQuery.Create(nil);
  try
    AddFDParam(LQuery, 'ID', ftInteger);
    AddFDParam(LQuery, 'NOME', ftString);
    AddFDParam(LQuery, 'DATA', ftDateTime);
    LCommand := CreateCommand;
    Check(TRickSQLServiceFireDACParameterBinder.Bind(
      TRickSQLFireDACParameterBindSetup.Create(LQuery, LCommand), LError),
      LError.Message);
    Check(LQuery.Params.ParamByName('NOME').Size = 80,
      'O tamanho do parâmetro não foi aplicado.');
    Check(LQuery.Params.ParamByName('DATA').IsNull,
      'O parâmetro nulo não foi aplicado.');
  finally
    LQuery.Free;
  end;
end;

procedure TestMissingParameter;
var
  LQuery: TFDQuery;
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
begin
  LQuery := TFDQuery.Create(nil);
  try
    AddFDParam(LQuery, 'ID', ftInteger);
    LCommand := CreateCommand;
    Check(not TRickSQLServiceFireDACParameterBinder.Bind(
      TRickSQLFireDACParameterBindSetup.Create(LQuery, LCommand), LError),
      'O binder aceitou parâmetro ausente na query.');
    Check(LError.Kind = TRickSQLErrorKind.Parameter,
      'O erro de parâmetro ausente não foi estruturado corretamente.');
  finally
    LQuery.Free;
  end;
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  TestBindSuccess;
  TestMissingParameter;
end.
