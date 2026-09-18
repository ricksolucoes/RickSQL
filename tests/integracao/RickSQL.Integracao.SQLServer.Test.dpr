program RickSQLIntegracaoSQLServerTest;

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
  Result := TRickSQLIntegrationTestHelper.HasEnv('RICKSQL_SQLSERVER_DATABASE');
end;

function CriarConexao: TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLServer);
  Result.Server := TRickSQLIntegrationTestHelper.Env('RICKSQL_SQLSERVER_SERVER');
  Result.Database := TRickSQLIntegrationTestHelper.Env('RICKSQL_SQLSERVER_DATABASE');
  Result.UserName := TRickSQLIntegrationTestHelper.Env('RICKSQL_SQLSERVER_USERNAME');
  Result.Password := TRickSQLIntegrationTestHelper.Env('RICKSQL_SQLSERVER_PASSWORD');
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
  ExecutarSQL(AConnection, 'if object_id(''ricksql_integracao'', ''U'') is not null drop table ricksql_integracao');
  ExecutarSQL(AConnection, 'create table ricksql_integracao (' +
    'id int not null primary key, nome varchar(80), valor decimal(15,2), ' +
    'data_venda datetime, ativo bit, observacao varbinary(max), nulo varchar(20))');
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
  LCommand.AddParameter(TRickSQLParameter.Create('NOME', 'Venda SQL Server'));
  LCommand.AddParameter(TRickSQLParameter.Create('VALOR', 30.50));
  LCommand.AddParameter(TRickSQLParameter.Create('DATA', Now));
  LCommand.AddParameter(TRickSQLParameter.Create('ATIVO', True));
  LCommand.AddParameter(TRickSQLParameter.Create('OBSERVACAO', 'blob'));
  LCommand.AddParameter(TRickSQLParameter.CreateNull('NULO', ftString));
  LResult := TRickSQL.Execute(LCommand);
  TRickSQLIntegrationTestHelper.CheckResult(LResult, 'Falha no insert SQL Server.');
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
    TRickSQLIntegrationTestHelper.CheckError(LError, 'Falha na consulta SQL Server.');
    TRickSQLIntegrationTestHelper.Check(Assigned(LDataSet), 'Dataset não retornado.');
    TRickSQLIntegrationTestHelper.Check(not LDataSet.IsEmpty, 'Consulta deveria retornar dados.');
    TRickSQLIntegrationTestHelper.Check(LDataSet.FindField('valor_calculado') <> nil, 'Alias não retornado.');
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
    Writeln('SQL Server ignorado. Configure RICKSQL_SQLSERVER_DATABASE para executar.');
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
    Writeln('Testes de integração SQL Server finalizados.');
  except
    on E: Exception do
    begin
      Writeln('Falha nos testes de integração SQL Server: ', E.Message);
      Halt(1);
    end;
  end;
end.
