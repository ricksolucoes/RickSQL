unit Rick.SQL.Sample.ServicoWindows.Flow;

// Responsabilidade: demonstrar o fluxo RickSQL usado pelo exemplo de serviço Windows.
// NAO cria serviços Windows, não conhece interface visual e não instala drivers.

interface

uses
  // RickSQL
  Rick.SQL;

type
  TRickSQLSampleServicoWindowsFlow = class
  private
    class function CriarConexao: TRickSQLConnectionOptions; static;
    class function CriarComando(const ASQL: string): TRickSQLCommand; static;
    class procedure RegistrarLog(const ATexto: string); static;
    class procedure PrepararBanco; static;
    class procedure InserirExecucao; static;
    class procedure ConsultarExecucoes; static;
  public
    class procedure Executar; static;
  end;

implementation

uses
  // RTL
  System.SysUtils,
  System.IOUtils;

const
  _DATABASE_NAME_ = 'ricksql_servico_demo.db';
  _LOG_NAME_ = 'ricksql-servico.log';
  _SQL_CREATE_TABLE_ =
    'create table if not exists execucoes (' +
    'id integer primary key autoincrement, mensagem varchar(150), criada_em datetime)';
  _SQL_INSERT_ =
    'insert into execucoes (mensagem, criada_em) values (:MENSAGEM, :DATA)';
  _SQL_SELECT_ = 'select count(*) as total from execucoes';

class function TRickSQLSampleServicoWindowsFlow.CriarConexao:
  TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  Result.Database := ExtractFilePath(ParamStr(0)) + _DATABASE_NAME_;
end;

class function TRickSQLSampleServicoWindowsFlow.CriarComando(
  const ASQL: string): TRickSQLCommand;
begin
  Result := TRickSQL.Command(CriarConexao, ASQL);
end;

class procedure TRickSQLSampleServicoWindowsFlow.RegistrarLog(
  const ATexto: string);
var
  LPath: string;
begin
  LPath := ExtractFilePath(ParamStr(0)) + _LOG_NAME_;
  TFile.AppendAllText(LPath, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) +
    ' - ' + ATexto + sLineBreak);
end;

class procedure TRickSQLSampleServicoWindowsFlow.PrepararBanco;
begin
  TRickSQL.Execute(CriarComando(_SQL_CREATE_TABLE_));
  RegistrarLog('Banco preparado.');
end;

class procedure TRickSQLSampleServicoWindowsFlow.InserirExecucao;
var
  LCommand: TRickSQLCommand;
begin
  LCommand := CriarComando(_SQL_INSERT_);
  LCommand.AddParameter(TRickSQLParameter.Create('MENSAGEM', 'Execução do serviço'));
  LCommand.AddParameter(TRickSQLParameter.Create('DATA', Now));
  TRickSQL.Execute(LCommand);
  RegistrarLog('Execução registrada.');
end;

class procedure TRickSQLSampleServicoWindowsFlow.ConsultarExecucoes;
var
  LError: TRickSQLError;
  LDataSet: TRickSQLDataSet;
begin
  LDataSet := TRickSQL.Open(CriarComando(_SQL_SELECT_), LError);
  try
    if Assigned(LDataSet) then
      RegistrarLog('Total de registros: ' + LDataSet.Fields[0].AsString)
    else
      RegistrarLog(LError.Message);
  finally
    LDataSet.Free;
  end;
end;

class procedure TRickSQLSampleServicoWindowsFlow.Executar;
begin
  PrepararBanco;
  InserirExecucao;
  ConsultarExecucoes;
end;

end.
