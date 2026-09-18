program RickSQL.Memoria.Parametros.Test;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Memory.Test.Helper;

procedure AdicionarParametros(var ACommand: TRickSQLCommand);
var
  LIndex: Integer;
begin
  for LIndex := 1 to 250 do
    ACommand.AddParameter(TRickSQLParameter.Create('P' + IntToStr(LIndex), LIndex));
end;

procedure ValidarArray(const ACommand: TRickSQLCommand);
begin
  TRickSQLMemoryTestHelper.Check(Length(ACommand.Parameters) = 250,
    'A quantidade de parâmetros não foi preservada.');
end;

procedure ExecutarTeste;
var
  LConnection: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
begin
  LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  LConnection.Database := ':memory:';
  LCommand := TRickSQL.Command(LConnection, 'select 1');
  AdicionarParametros(LCommand);
  ValidarArray(LCommand);
end;

begin
  ReportMemoryLeaksOnShutdown := True;

  try
    ExecutarTeste;
    Writeln('Teste de memória dos arrays de parâmetros concluído com sucesso.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
