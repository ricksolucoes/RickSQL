unit Rick.SQL.Sample.FMX.Flow;

// Responsabilidade: demonstrar o fluxo RickSQL usado pelo exemplo FMX.
// NAO cria formulários, controles visuais ou componentes de banco.

interface

type
  TRickSQLSampleFMXFlow = class
  private
    class function CriarResumo(const ATexto: string): string; static;
    class function PrepararBanco: string; static;
    class function InserirEvento: string; static;
    class function ConsultarEventos: string; static;
  public
    class function Executar: string; static;
  end;

implementation

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL;

const
  _DATABASE_NAME_ = 'ricksql_fmx_demo.db';
  _SQL_CREATE_TABLE_ =
    'create table if not exists eventos (' +
    'id integer primary key autoincrement, titulo varchar(100), criado_em datetime)';
  _SQL_INSERT_ = 'insert into eventos (titulo, criado_em) values (:TITULO, :DATA)';
  _SQL_SELECT_ = 'select id, titulo, criado_em from eventos order by id desc';

class function TRickSQLSampleFMXFlow.CriarResumo(const ATexto: string): string;
begin
  Result := FormatDateTime('hh:nn:ss', Now) + ' - ' + ATexto;
end;

class function TRickSQLSampleFMXFlow.PrepararBanco: string;
var
  LCommand: TRickSQLCommand;
begin
  LCommand := TRickSQL.Command(TRickSQL.ConnectionOptions(
    TRickSQLDatabaseEngine.SQLite), _SQL_CREATE_TABLE_);
  LCommand.Connection.Database := ExtractFilePath(ParamStr(0)) + _DATABASE_NAME_;
  TRickSQL.Execute(LCommand);
  Result := CriarResumo('Banco preparado.');
end;

class function TRickSQLSampleFMXFlow.InserirEvento: string;
var
  LCommand: TRickSQLCommand;
begin
  LCommand := TRickSQL.Command(TRickSQL.ConnectionOptions(
    TRickSQLDatabaseEngine.SQLite), _SQL_INSERT_);
  LCommand.Connection.Database := ExtractFilePath(ParamStr(0)) + _DATABASE_NAME_;
  LCommand.AddParameter(TRickSQLParameter.Create('TITULO', 'Evento FMX'));
  LCommand.AddParameter(TRickSQLParameter.Create('DATA', Now));
  TRickSQL.Execute(LCommand);
  Result := CriarResumo('Registro inserido.');
end;

class function TRickSQLSampleFMXFlow.ConsultarEventos: string;
var
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
  LDataSet: TRickSQLDataSet;
begin
  LCommand := TRickSQL.Command(TRickSQL.ConnectionOptions(
    TRickSQLDatabaseEngine.SQLite), _SQL_SELECT_);
  LCommand.Connection.Database := ExtractFilePath(ParamStr(0)) + _DATABASE_NAME_;
  LDataSet := TRickSQL.Open(LCommand, LError);
  try
    if Assigned(LDataSet) then
      Result := CriarResumo('Registros encontrados: ' + IntToStr(LDataSet.RecordCount))
    else
      Result := CriarResumo(LError.Message);
  finally
    LDataSet.Free;
  end;
end;

class function TRickSQLSampleFMXFlow.Executar: string;
begin
  Result := PrepararBanco + sLineBreak + InserirEvento + sLineBreak + ConsultarEventos;
end;

end.
