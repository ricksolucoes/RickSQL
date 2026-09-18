program RickSQLIntegracaoInfraestruturaTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,
  System.IOUtils,

  // Data
  Data.DB,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Integration.Test.Helper;

procedure CheckFalhaExecucao(const ACommand: TRickSQLCommand;
  const AMessage: string);
var
  LResult: TRickSQLExecutionResult;
begin
  LResult := TRickSQL.Execute(ACommand);
  TRickSQLIntegrationTestHelper.Check(not LResult.Success, AMessage);
  TRickSQLIntegrationTestHelper.Check(LResult.Error.HasError,
    'Erro estruturado não foi preenchido.');
end;

procedure TestarArquivoSQLiteInexistente;
var
  LConnection: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
begin
  LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  LConnection.Database := TPath.Combine(TPath.Combine(TPath.GetTempPath,
    'ricksql_diretorio_inexistente'), 'base.sqlite');
  LCommand := TRickSQL.Command(LConnection, 'create table teste (id integer)');
  CheckFalhaExecucao(LCommand, 'Arquivo em diretório inexistente deveria falhar.');
end;

procedure TestarBibliotecaClienteAusente;
var
  LConnection: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
begin
  LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.Firebird);
  LConnection.Server := '127.0.0.1';
  LConnection.Database := 'base_inexistente.fdb';
  LConnection.UserName := 'SYSDBA';
  LConnection.Password := 'masterkey';
  LConnection.ClientLibraryPath := 'C:\RickSQL\biblioteca-inexistente.dll';
  LCommand := TRickSQL.Command(LConnection, 'select 1 from rdb$database');
  CheckFalhaExecucao(LCommand, 'Biblioteca cliente ausente deveria falhar.');
end;

procedure TestarParametroAusente;
var
  LConnection: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
  LDataSet: TDataSet;
begin
  LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  LConnection.Database := TPath.Combine(TPath.GetTempPath, 'ricksql_infra.sqlite');
  LCommand := TRickSQL.Command(LConnection, 'select :ID as codigo');
  LDataSet := TRickSQL.Open(LCommand, LError);
  try
    TRickSQLIntegrationTestHelper.Check(not Assigned(LDataSet), 'Parâmetro ausente deveria falhar.');
    TRickSQLIntegrationTestHelper.Check(LError.HasError, 'Erro do parâmetro ausente não retornado.');
  finally
    TRickSQLIntegrationTestHelper.FreeDataSet(LDataSet);
  end;
end;

procedure TestarSQLInvalido;
var
  LConnection: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
begin
  LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  LConnection.Database := TPath.Combine(TPath.GetTempPath, 'ricksql_infra.sqlite');
  LCommand := TRickSQL.Command(LConnection, 'select * from');
  CheckFalhaExecucao(LCommand, 'SQL inválido deveria falhar.');
end;

procedure TestarCredencialInvalidaPostgreSQL;
var
  LConnection: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
begin
  if not TRickSQLIntegrationTestHelper.HasEnv('RICKSQL_POSTGRESQL_DATABASE') then
    Exit;

  LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.PostgreSQL);
  LConnection.Server := TRickSQLIntegrationTestHelper.Env('RICKSQL_POSTGRESQL_SERVER');
  LConnection.Database := TRickSQLIntegrationTestHelper.Env('RICKSQL_POSTGRESQL_DATABASE');
  LConnection.UserName := TRickSQLIntegrationTestHelper.Env('RICKSQL_POSTGRESQL_USERNAME');
  LConnection.Password := 'senha_invalida_ricksql';
  LCommand := TRickSQL.Command(LConnection, 'select 1');
  CheckFalhaExecucao(LCommand, 'Credencial inválida deveria falhar.');
end;

procedure ExecutarTestes;
begin
  TestarArquivoSQLiteInexistente;
  TestarBibliotecaClienteAusente;
  TestarParametroAusente;
  TestarSQLInvalido;
  TestarCredencialInvalidaPostgreSQL;
end;

begin
  try
    ExecutarTestes;
    Writeln('Testes de infraestrutura concluídos com sucesso.');
  except
    on E: Exception do
    begin
      Writeln('Falha nos testes de infraestrutura: ', E.Message);
      Halt(1);
    end;
  end;
end.
