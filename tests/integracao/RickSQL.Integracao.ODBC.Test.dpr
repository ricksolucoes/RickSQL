program RickSQLIntegracaoODBCTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,

  // Data
  Data.DB,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Integration.Test.Helper;

function AmbienteConfigurado: Boolean;
begin
  Result := TRickSQLIntegrationTestHelper.HasEnv('RICKSQL_ODBC_DATASOURCE');
end;

function CriarConexao: TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.ODBC);
  Result.Database := TRickSQLIntegrationTestHelper.Env('RICKSQL_ODBC_DATASOURCE');
  Result.UserName := TRickSQLIntegrationTestHelper.Env('RICKSQL_ODBC_USERNAME');
  Result.Password := TRickSQLIntegrationTestHelper.Env('RICKSQL_ODBC_PASSWORD');
end;

procedure TestarConsultaSimples(const AConnection: TRickSQLConnectionOptions);
var
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
  LDataSet: TDataSet;
begin
  LCommand := TRickSQL.Command(AConnection,
    TRickSQLIntegrationTestHelper.Env('RICKSQL_ODBC_SELECT_SQL'));
  if Trim(LCommand.Text) = '' then
    LCommand.Text := 'select 1 as codigo';
  LDataSet := TRickSQL.Open(LCommand, LError);
  try
    TRickSQLIntegrationTestHelper.CheckError(LError, 'Falha na consulta ODBC.');
    TRickSQLIntegrationTestHelper.Check(Assigned(LDataSet), 'Dataset ODBC não retornado.');
  finally
    TRickSQLIntegrationTestHelper.FreeDataSet(LDataSet);
  end;
end;

procedure ExecutarTestes;
var
  LConnection: TRickSQLConnectionOptions;
begin
  if not AmbienteConfigurado then
  begin
    Writeln('ODBC ignorado. Configure RICKSQL_ODBC_DATASOURCE para executar.');
    Exit;
  end;

  LConnection := CriarConexao;
  TestarConsultaSimples(LConnection);
end;

begin
  try
    ExecutarTestes;
    Writeln('Testes de integração ODBC finalizados.');
  except
    on E: Exception do
    begin
      Writeln('Falha nos testes de integração ODBC: ', E.Message);
      Halt(1);
    end;
  end;
end.
