program RickSQLIntegracaoPostgreSQLTest;

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
  Result := TRickSQLIntegrationTestHelper.HasEnv('RICKSQL_POSTGRESQL_DATABASE');
end;

function CriarConexao: TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.PostgreSQL);
  Result.Server := TRickSQLIntegrationTestHelper.Env('RICKSQL_POSTGRESQL_SERVER');
  Result.Database := TRickSQLIntegrationTestHelper.Env('RICKSQL_POSTGRESQL_DATABASE');
  Result.UserName := TRickSQLIntegrationTestHelper.Env('RICKSQL_POSTGRESQL_USERNAME');
  Result.Password := TRickSQLIntegrationTestHelper.Env('RICKSQL_POSTGRESQL_PASSWORD');
  Result.ClientLibraryPath := TRickSQLIntegrationTestHelper.Env('RICKSQL_POSTGRESQL_CLIENT_LIBRARY');
end;

procedure ExecutarSQL(const AConnection: TRickSQLConnectionOptions;
  const ASQL: string);
var
  LResult: TRickSQLExecutionResult;
begin
  LResult := TRickSQL.Execute(TRickSQL.Command(AConnection, ASQL));
  TRickSQLIntegrationTestHelper.CheckResult(LResult, 'Falha ao executar SQL.');
end;

procedure PrepararBase(const AConnection: TRickSQLConnectionOptions);
begin
  ExecutarSQL(AConnection, 'drop table if exists ricksql_integracao');
  ExecutarSQL(AConnection, 'create table ricksql_integracao (' +
    'id integer primary key, nome varchar(80), valor numeric(15,2), ' +
    'data_venda timestamp, ativo boolean, observacao bytea, nulo varchar(20))');
end;

procedure InserirRegistro(const AConnection: TRickSQLConnectionOptions);
var
  LCommand: TRickSQLCommand;
  LResult: TRickSQLExecutionResult;
begin
  LCommand := TRickSQL.Command(AConnection, 'insert into ricksql_integracao ' +
    '(id, nome, valor, data_venda, ativo, observacao, nulo) values ' +
    '(:ID, :NOME, :VALOR, :DATA, :ATIVO, :OBSERVACAO, :NULO)');
  LCommand.AddParameter(TRickSQLParameter.Create('ID', 1));
  LCommand.AddParameter(TRickSQLParameter.Create('NOME', 'Venda PostgreSQL'));
  LCommand.AddParameter(TRickSQLParameter.Create('VALOR', 20.50));
  LCommand.AddParameter(TRickSQLParameter.Create('DATA', Now));
  LCommand.AddParameter(TRickSQLParameter.Create('ATIVO', True));
  LCommand.AddParameter(TRickSQLParameter.Create('OBSERVACAO', 'blob'));
  LCommand.AddParameter(TRickSQLParameter.CreateNull('NULO', ftString));
  LResult := TRickSQL.Execute(LCommand);
  TRickSQLIntegrationTestHelper.CheckResult(LResult, 'Falha no insert PostgreSQL.');
end;

procedure ConsultarRegistro(const AConnection: TRickSQLConnectionOptions);
var
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
  LDataSet: TDataSet;
begin
  LCommand := TRickSQL.Command(AConnection, 'select id, nome, valor, ' +
    'data_venda, ativo, observacao, nulo, valor + 1 as valor_calculado ' +
    'from ricksql_integracao where id = :ID');
  LCommand.AddParameter(TRickSQLParameter.Create('ID', 1));
  LDataSet := TRickSQL.Open(LCommand, LError);
  try
    TRickSQLIntegrationTestHelper.CheckError(LError, 'Falha na consulta PostgreSQL.');
    TRickSQLIntegrationTestHelper.Check(Assigned(LDataSet), 'Dataset não retornado.');
    TRickSQLIntegrationTestHelper.Check(not LDataSet.IsEmpty, 'Consulta deveria retornar dados.');
    TRickSQLIntegrationTestHelper.Check(LDataSet.FindField('nulo') <> nil, 'Campo nulo não retornado.');
  finally
    TRickSQLIntegrationTestHelper.FreeDataSet(LDataSet);
  end;
end;

procedure TestarComandos(const AConnection: TRickSQLConnectionOptions);
begin
  ExecutarSQL(AConnection, 'update ricksql_integracao set nome = ''Alterado'' where id = 1');
  ExecutarSQL(AConnection, 'delete from ricksql_integracao where id = 1');
  ExecutarSQL(AConnection, 'update ricksql_integracao set nome = ''Sem efeito'' where id = 999');
end;

procedure ExecutarTestes;
var
  LConnection: TRickSQLConnectionOptions;
begin
  if not AmbienteConfigurado then
  begin
    Writeln('PostgreSQL ignorado. Configure RICKSQL_POSTGRESQL_DATABASE para executar.');
    Exit;
  end;

  LConnection := CriarConexao;
  PrepararBase(LConnection);
  InserirRegistro(LConnection);
  ConsultarRegistro(LConnection);
  TestarComandos(LConnection);
end;

begin
  try
    ExecutarTestes;
    Writeln('Testes de integração PostgreSQL finalizados.');
  except
    on E: Exception do
    begin
      Writeln('Falha nos testes de integração PostgreSQL: ', E.Message);
      Halt(1);
    end;
  end;
end.
