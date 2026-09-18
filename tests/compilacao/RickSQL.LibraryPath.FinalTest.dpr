program RickSQL.LibraryPath.FinalTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL;

const
  _DATABASE_NAME_ = 'ricksql_library_path_final.db';
  _SQL_CREATE_TABLE_ =
    'create table if not exists clientes (' +
    'id integer primary key autoincrement, nome varchar(80), ativo integer)';
  _SQL_INSERT_ =
    'insert into clientes (nome, ativo) values (:NOME, :ATIVO)';
  _SQL_SELECT_ =
    'select id, nome, ativo from clientes where ativo = :ATIVO order by id';

function CriarConexao: TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  Result.Database := ExtractFilePath(ParamStr(0)) + _DATABASE_NAME_;
end;

function CriarComando(const ASQL: string): TRickSQLCommand;
begin
  Result := TRickSQL.Command(CriarConexao, ASQL);
end;

procedure ValidarResultado(const AResult: TRickSQLExecutionResult);
begin
  if AResult.Success then
    Exit;

  raise Exception.Create(AResult.Error.Message);
end;

procedure PrepararBanco;
begin
  ValidarResultado(TRickSQL.Execute(CriarComando(_SQL_CREATE_TABLE_)));
end;

procedure InserirCliente;
var
  LCommand: TRickSQLCommand;
begin
  LCommand := CriarComando(_SQL_INSERT_);
  LCommand.AddParameter(TRickSQLParameter.Create('NOME', 'Cliente Library Path'));
  LCommand.AddParameter(TRickSQLParameter.Create('ATIVO', 1));
  ValidarResultado(TRickSQL.Execute(LCommand));
end;

procedure ConsultarClientes;
var
  LCommand: TRickSQLCommand;
  LDataSet: TRickSQLDataSet;
  LError: TRickSQLError;
begin
  LCommand := CriarComando(_SQL_SELECT_);
  LCommand.AddParameter(TRickSQLParameter.Create('ATIVO', 1));
  LDataSet := TRickSQL.Open(LCommand, LError);
  try
    if not Assigned(LDataSet) then
      raise Exception.Create(LError.Message);
    Writeln('Registros encontrados: ', LDataSet.RecordCount);
  finally
    LDataSet.Free;
  end;
end;

begin
  try
    PrepararBanco;
    InserirCliente;
    ConsultarClientes;
    Writeln('Teste final pelo Library Path concluído.');
  except
    on E: Exception do
      Writeln('Falha no teste final pelo Library Path: ' + E.Message);
  end;
end.
