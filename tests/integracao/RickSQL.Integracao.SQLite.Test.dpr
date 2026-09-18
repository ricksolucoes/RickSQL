program RickSQLIntegracaoSQLiteTest;

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

function CriarConexao: TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  Result.Database := TPath.Combine(TPath.GetTempPath, 'ricksql_integracao.sqlite');
end;

procedure ExecutarSQL(const AConnection: TRickSQLConnectionOptions;
  const ASQL: string);
var
  LCommand: TRickSQLCommand;
  LResult: TRickSQLExecutionResult;
begin
  LCommand := TRickSQL.Command(AConnection, ASQL);
  LResult := TRickSQL.Execute(LCommand);
  TRickSQLIntegrationTestHelper.CheckResult(LResult, 'Falha ao executar SQL.');
end;

procedure PrepararBase(const AConnection: TRickSQLConnectionOptions);
begin
  ExecutarSQL(AConnection, 'drop table if exists ricksql_integracao');
  ExecutarSQL(AConnection, 'create table ricksql_integracao (' +
    'id integer primary key, nome varchar(80), valor numeric(15,2), ' +
    'data_venda timestamp, ativo integer, observacao blob, nulo varchar(20))');
end;

procedure TestarInsert(const AConnection: TRickSQLConnectionOptions);
var
  LCommand: TRickSQLCommand;
  LResult: TRickSQLExecutionResult;
begin
  LCommand := TRickSQL.Command(AConnection, 'insert into ricksql_integracao ' +
    '(id, nome, valor, data_venda, ativo, observacao, nulo) values ' +
    '(:ID, :NOME, :VALOR, :DATA, :ATIVO, :OBSERVACAO, :NULO)');
  LCommand.AddParameter(TRickSQLParameter.Create('ID', 1));
  LCommand.AddParameter(TRickSQLParameter.Create('NOME', 'Venda teste'));
  LCommand.AddParameter(TRickSQLParameter.Create('VALOR', 123.45));
  LCommand.AddParameter(TRickSQLParameter.Create('DATA', Now));
  LCommand.AddParameter(TRickSQLParameter.Create('ATIVO', 1));
  LCommand.AddParameter(TRickSQLParameter.Create('OBSERVACAO', 'blob'));
  LCommand.AddParameter(TRickSQLParameter.CreateNull('NULO', ftString));
  LResult := TRickSQL.Execute(LCommand);
  TRickSQLIntegrationTestHelper.CheckResult(LResult, 'Falha no insert.');
end;

procedure TestarConsultaComRegistros(
  const AConnection: TRickSQLConnectionOptions);
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
    TRickSQLIntegrationTestHelper.CheckError(LError, 'Falha na consulta.');
    TRickSQLIntegrationTestHelper.Check(Assigned(LDataSet), 'Dataset não retornado.');
    TRickSQLIntegrationTestHelper.Check(not LDataSet.IsEmpty, 'Consulta deveria retornar dados.');
    TRickSQLIntegrationTestHelper.Check(LDataSet.FieldByName('nome').AsString = 'Venda teste', 'Texto incorreto.');
    TRickSQLIntegrationTestHelper.Check(LDataSet.FindField('valor_calculado') <> nil, 'Alias não retornado.');
    TRickSQLIntegrationTestHelper.Check(LDataSet.FindField('observacao') <> nil, 'Campo BLOB não retornado.');
  finally
    TRickSQLIntegrationTestHelper.FreeDataSet(LDataSet);
  end;
end;

procedure TestarConsultaVazia(const AConnection: TRickSQLConnectionOptions);
var
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
  LDataSet: TDataSet;
begin
  LCommand := TRickSQL.Command(AConnection, 'select * from ricksql_integracao ' +
    'where id = :ID');
  LCommand.AddParameter(TRickSQLParameter.Create('ID', 999));
  LDataSet := TRickSQL.Open(LCommand, LError);
  try
    TRickSQLIntegrationTestHelper.CheckError(LError, 'Falha na consulta vazia.');
    TRickSQLIntegrationTestHelper.Check(Assigned(LDataSet), 'Dataset vazio não retornado.');
    TRickSQLIntegrationTestHelper.Check(LDataSet.IsEmpty, 'Consulta deveria retornar vazia.');
  finally
    TRickSQLIntegrationTestHelper.FreeDataSet(LDataSet);
  end;
end;

procedure TestarUpdateDelete(const AConnection: TRickSQLConnectionOptions);
var
  LCommand: TRickSQLCommand;
  LResult: TRickSQLExecutionResult;
begin
  LCommand := TRickSQL.Command(AConnection, 'update ricksql_integracao ' +
    'set nome = :NOME where id = :ID');
  LCommand.AddParameter(TRickSQLParameter.Create('NOME', 'Venda alterada'));
  LCommand.AddParameter(TRickSQLParameter.Create('ID', 1));
  LResult := TRickSQL.Execute(LCommand);
  TRickSQLIntegrationTestHelper.CheckResult(LResult, 'Falha no update.');
  LCommand := TRickSQL.Command(AConnection, 'delete from ricksql_integracao where id = :ID');
  LCommand.AddParameter(TRickSQLParameter.Create('ID', 1));
  LResult := TRickSQL.Execute(LCommand);
  TRickSQLIntegrationTestHelper.CheckResult(LResult, 'Falha no delete.');
end;

procedure TestarZeroAfetados(const AConnection: TRickSQLConnectionOptions);
var
  LCommand: TRickSQLCommand;
  LResult: TRickSQLExecutionResult;
begin
  LCommand := TRickSQL.Command(AConnection, 'update ricksql_integracao ' +
    'set nome = :NOME where id = :ID');
  LCommand.AddParameter(TRickSQLParameter.Create('NOME', 'Sem efeito'));
  LCommand.AddParameter(TRickSQLParameter.Create('ID', 777));
  LResult := TRickSQL.Execute(LCommand);
  TRickSQLIntegrationTestHelper.CheckResult(LResult, 'Zero afetados falhou.');
  TRickSQLIntegrationTestHelper.Check(LResult.RowsAffected = 0,
    'Zero registros afetados deveria retornar 0.');
end;

procedure TestarFalhasControladas(const AConnection: TRickSQLConnectionOptions);
var
  LCommand: TRickSQLCommand;
  LResult: TRickSQLExecutionResult;
  LError: TRickSQLError;
  LDataSet: TDataSet;
begin
  LResult := TRickSQL.Execute(TRickSQL.Command(AConnection, 'select * from'));
  TRickSQLIntegrationTestHelper.Check(not LResult.Success, 'SQL inválido deveria falhar.');
  LCommand := TRickSQL.Command(AConnection, 'select * from ricksql_integracao where id = :ID');
  LDataSet := TRickSQL.Open(LCommand, LError);
  try
    TRickSQLIntegrationTestHelper.Check(not Assigned(LDataSet), 'Parâmetro ausente deveria falhar.');
    TRickSQLIntegrationTestHelper.Check(LError.HasError, 'Erro do parâmetro ausente não retornado.');
  finally
    TRickSQLIntegrationTestHelper.FreeDataSet(LDataSet);
  end;
end;

procedure ExecutarTestes;
var
  LConnection: TRickSQLConnectionOptions;
begin
  LConnection := CriarConexao;
  PrepararBase(LConnection);
  TestarInsert(LConnection);
  TestarConsultaComRegistros(LConnection);
  TestarConsultaVazia(LConnection);
  TestarUpdateDelete(LConnection);
  TestarZeroAfetados(LConnection);
  TestarFalhasControladas(LConnection);
end;

begin
  try
    ExecutarTestes;
    Writeln('Testes de integração SQLite concluídos com sucesso.');
  except
    on E: Exception do
    begin
      Writeln('Falha nos testes de integração SQLite: ', E.Message);
      Halt(1);
    end;
  end;
end.
