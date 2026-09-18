unit Rick.SQL.Sample.Interf.Runner;

// Responsabilidade: demonstrar o consumo do Rick.SQL.Interf em uma aplicação console.
// NAO implementa regras do framework, não conhece interface visual e não instala drivers.

interface

uses
  // RickSQL
  Rick.SQL.Interf;

type
  TRickSQLSampleInterfRunner = class
  private
    class procedure EscreverErro(const ARick: IRickSQL); static;
  public
    class procedure Executar; static;
  end;

implementation

uses
  // RTL
  System.SysUtils;

const
  _DATABASE_NAME_ = 'ricksql_interf_console_demo.db';
  _SQL_CREATE_TABLE_ =
    'create table if not exists clientes (' +
    'id integer primary key autoincrement, ' +
    'nome varchar(100), ativo integer, criado_em datetime)';
  _SQL_INSERT_ =
    'insert into clientes (nome, ativo, criado_em) values (:NOME, :ATIVO, :DATA)';
  _SQL_UPDATE_ = 'update clientes set ativo = :ATIVO where nome = :NOME';
  _SQL_SELECT_ =
    'select id, nome, ativo, criado_em from clientes where ativo = :ATIVO order by id';


class procedure TRickSQLSampleInterfRunner.EscreverErro(const ARick: IRickSQL);
begin
  Writeln('Erro: ', ARick.Result.Error);

  if ARick.Result.ErrorFull.Error.TechnicalDetail <> '' then
    Writeln('Detalhe técnico: ', ARick.Result.ErrorFull.Error.TechnicalDetail);
end;

class procedure TRickSQLSampleInterfRunner.Executar;
var
  LRick: IRickSQL;
begin
  LRick := TRickSQLInterf.New
              .ConnectionOptions
                .Engine(TRickSQLDatabaseEngine.SQLite)
                .Database(ExtractFilePath(ParamStr(0)) + _DATABASE_NAME_)
            .Back
            .Command
              .SQL(_SQL_CREATE_TABLE_)
            .Back
            .Cursor
              .Execute
            .Back;

  if not LRick.Result.Error.Trim.IsEmpty then
  begin
    EscreverErro(LRick);
    Exit;
  end;

  LRick
    .Command
      .SQL(_SQL_INSERT_)
      .Parameter
        .Name('NOME')
        .Value('Cliente exemplo')
          .Add
        .Name('ATIVO')
        .Value(1)
          .Add
        .Name('DATA')
        .Value(Now)
          .Add
      .Return
    .Back
    .Cursor
      .Execute
    .Back
    ;

  if not LRick.Result.Error.Trim.IsEmpty then
  begin
    EscreverErro(LRick);
    Exit;
  end;

  // Esvazia os parâmetros consolidados deste comando antes do próximo,
  // já que a mesma instância IRickSQL é reaproveitada em todo o fluxo.
  LRick
    .Command
      .Parameter
        .Clear
      .Return
      .SQL(_SQL_UPDATE_)
      .Parameter
        .Name('ATIVO')
        .Value(1)
          .Add
        .Name('NOME')
        .Value('Cliente exemplo')
          .Add
      .Return
    .Back
    .Cursor
      .Execute
    .Back;

  if not LRick.Result.Error.Trim.IsEmpty then
  begin
    EscreverErro(LRick);
    Exit;
  end;

  LRick
    .Command
      .Parameter
        .Clear
      .Return
    .SQL(_SQL_SELECT_)
    .Parameter
      .Name('ATIVO')
        .Value(1)
          .Add
        .Return
    .Back
    .Cursor
      .Open
    .Back;

  if not LRick.Result.Error.Trim.IsEmpty then
    EscreverErro(LRick)
  else
    Writeln('Registros encontrados: ', LRick.Result.DataSet.RecordCount);

  LRick
    .Command
      .Parameter
        .Clear
      .Return
    .Back;

end;

end.
