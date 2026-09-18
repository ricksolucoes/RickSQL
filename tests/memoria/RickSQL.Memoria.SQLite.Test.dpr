program RickSQL.Memoria.SQLite.Test;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,

  // Data
  Data.DB,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Memory.Test.Helper;

procedure CriarTabela(const AConnection: TRickSQLConnectionOptions);
var
  LCommand: TRickSQLCommand;
  LResult: TRickSQLExecutionResult;
begin
  LCommand := TRickSQL.Command(AConnection,
    'create table memoria (id integer primary key, nome varchar(40))');
  LResult := TRickSQL.Execute(LCommand);
  TRickSQLMemoryTestHelper.CheckResult(LResult, 'Falha ao criar tabela.');
end;

procedure InserirRegistro(const AConnection: TRickSQLConnectionOptions;
  const AId: Integer);
var
  LCommand: TRickSQLCommand;
  LResult: TRickSQLExecutionResult;
begin
  LCommand := TRickSQL.Command(AConnection,
    'insert into memoria (id, nome) values (:ID, :NOME)');
  LCommand.AddParameter(TRickSQLParameter.Create('ID', AId));
  LCommand.AddParameter(TRickSQLParameter.Create('NOME', 'Registro ' + IntToStr(AId)));
  LResult := TRickSQL.Execute(LCommand);
  TRickSQLMemoryTestHelper.CheckResult(LResult, 'Falha ao inserir registro.');
end;

procedure ConsultarRegistros(const AConnection: TRickSQLConnectionOptions);
var
  LError: TRickSQLError;
  LDataSet: TDataSet;
begin
  LDataSet := TRickSQL.Open(TRickSQL.Command(AConnection,
    'select id, nome from memoria order by id'), LError);
  try
    TRickSQLMemoryTestHelper.CheckError(LError, 'Falha ao consultar registros.');
    TRickSQLMemoryTestHelper.Check(Assigned(LDataSet), 'Dataset não retornado.');
    TRickSQLMemoryTestHelper.Check(LDataSet.Active, 'Dataset retornado inativo.');
  finally
    TRickSQLMemoryTestHelper.FreeDataSet(LDataSet);
  end;
end;

procedure ExecutarCiclo(const ADatabase: string);
var
  LConnection: TRickSQLConnectionOptions;
  LIndex: Integer;
begin
  LConnection := TRickSQLMemoryTestHelper.SQLiteConnection(ADatabase);
  CriarTabela(LConnection);

  for LIndex := 1 to 20 do
    InserirRegistro(LConnection, LIndex);

  ConsultarRegistros(LConnection);
end;

procedure ExecutarTeste;
var
  LIndex: Integer;
  LDatabase: string;
begin
  for LIndex := 1 to 25 do
  begin
    LDatabase := TRickSQLMemoryTestHelper.TempDatabaseName;
    try
      ExecutarCiclo(LDatabase);
    finally
      TRickSQLMemoryTestHelper.DeleteFileIfExists(LDatabase);
    end;
  end;
end;

begin
  ReportMemoryLeaksOnShutdown := True;

  try
    ExecutarTeste;
    Writeln('Teste de memória SQLite concluído com sucesso.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
