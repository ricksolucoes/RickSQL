unit Rick.SQL.Sample.Console.Runner;

// Responsabilidade: demonstrar o consumo do RickSQL em uma aplicação console.
// NAO implementa regras do framework, não conhece interface visual e não instala drivers.

interface

uses
  // RickSQL
  Rick.SQL;

type
  TRickSQLSampleConsoleRunner = class
  private
    class function CriarConexao: TRickSQLConnectionOptions; static;
    class function CriarComando(const ASQL: string): TRickSQLCommand; static;
    class function ExecutarComando(const ACommand: TRickSQLCommand): Boolean; static;
    class function AbrirConsulta(const ACommand: TRickSQLCommand): TRickSQLDataSet; static;
    class procedure PrepararBanco; static;
    class procedure InserirCliente; static;
    class procedure AtualizarCliente; static;
    class procedure ConsultarClientes; static;
    class procedure EscreverErro(const AError: TRickSQLError); static;
  public
    class procedure Executar; static;
  end;

implementation

uses
  // RTL
  System.SysUtils;

const
  _DATABASE_NAME_ = 'ricksql_console_demo.db';
  _SQL_CREATE_TABLE_ =
    'create table if not exists clientes (' +
    'id integer primary key autoincrement, ' +
    'nome varchar(100), ativo integer, criado_em datetime)';
  _SQL_INSERT_ =
    'insert into clientes (nome, ativo, criado_em) values (:NOME, :ATIVO, :DATA)';
  _SQL_UPDATE_ = 'update clientes set ativo = :ATIVO where nome = :NOME';
  _SQL_SELECT_ =
    'select id, nome, ativo, criado_em from clientes where ativo = :ATIVO order by id';

class function TRickSQLSampleConsoleRunner.CriarConexao:
  TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  Result.Database := ExtractFilePath(ParamStr(0)) + _DATABASE_NAME_;
end;

class function TRickSQLSampleConsoleRunner.CriarComando(
  const ASQL: string): TRickSQLCommand;
begin
  Result := TRickSQL.Command(CriarConexao, ASQL);
end;

class function TRickSQLSampleConsoleRunner.ExecutarComando(
  const ACommand: TRickSQLCommand): Boolean;
var
  LResult: TRickSQLExecutionResult;
begin
  LResult := TRickSQL.Execute(ACommand);
  Result := LResult.Success;

  if not Result then
    EscreverErro(LResult.Error);
end;

class function TRickSQLSampleConsoleRunner.AbrirConsulta(
  const ACommand: TRickSQLCommand): TRickSQLDataSet;
var
  LError: TRickSQLError;
begin
  Result := TRickSQL.Open(ACommand, LError);

  if not Assigned(Result) then
    EscreverErro(LError);
end;

class procedure TRickSQLSampleConsoleRunner.PrepararBanco;
begin
  ExecutarComando(CriarComando(_SQL_CREATE_TABLE_));
end;

class procedure TRickSQLSampleConsoleRunner.InserirCliente;
var
  LCommand: TRickSQLCommand;
begin
  LCommand := CriarComando(_SQL_INSERT_);
  LCommand.AddParameter(TRickSQLParameter.Create('NOME', 'Cliente exemplo'));
  LCommand.AddParameter(TRickSQLParameter.Create('ATIVO', 1));
  LCommand.AddParameter(TRickSQLParameter.Create('DATA', Now));
  ExecutarComando(LCommand);
end;

class procedure TRickSQLSampleConsoleRunner.AtualizarCliente;
var
  LCommand: TRickSQLCommand;
begin
  LCommand := CriarComando(_SQL_UPDATE_);
  LCommand.AddParameter(TRickSQLParameter.Create('ATIVO', 1));
  LCommand.AddParameter(TRickSQLParameter.Create('NOME', 'Cliente exemplo'));
  ExecutarComando(LCommand);
end;

class procedure TRickSQLSampleConsoleRunner.ConsultarClientes;
var
  LCommand: TRickSQLCommand;
  LDataSet: TRickSQLDataSet;
begin
  LCommand := CriarComando(_SQL_SELECT_);
  LCommand.AddParameter(TRickSQLParameter.Create('ATIVO', 1));
  LDataSet := AbrirConsulta(LCommand);
  try
    if Assigned(LDataSet) then
      Writeln('Registros encontrados: ', LDataSet.RecordCount);
  finally
    LDataSet.Free;
  end;
end;

class procedure TRickSQLSampleConsoleRunner.EscreverErro(
  const AError: TRickSQLError);
begin
  Writeln('Erro: ', AError.Message);

  if AError.TechnicalDetail <> '' then
    Writeln('Detalhe técnico: ', AError.TechnicalDetail);
end;

class procedure TRickSQLSampleConsoleRunner.Executar;
begin
  PrepararBanco;
  InserirCliente;
  AtualizarCliente;
  ConsultarClientes;
end;

end.
