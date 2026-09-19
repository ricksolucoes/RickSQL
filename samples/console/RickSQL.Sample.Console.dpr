program RickSQL.Sample.Console;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.SysUtils,
  Rick.SQL.Sample.Console.Runner in 'Rick.SQL.Sample.Console.Runner.pas';

var
  LThread: TThread;
  LThreadError: string;

begin
  LThread := nil;
  LThreadError := '';

  try
    Writeln('RickSQL - exemplo console');
    Writeln('Executando fluxo em thread externa...');

    LThread := TThread.CreateAnonymousThread(
      procedure
      begin
        try
          TRickSQLSampleConsoleRunner.Executar;
        except
          on E: Exception do
            LThreadError := E.Message;
        end;
      end);

    LThread.FreeOnTerminate := False;
    LThread.Start;
    LThread.WaitFor;

    if LThreadError <> '' then
      raise Exception.Create(LThreadError);

    Writeln('Fluxo finalizado. Pressione ENTER para sair.');
    Readln;
  except
    on E: Exception do
    begin
      Writeln('Falha inesperada no exemplo: ' + E.Message);
      Readln;
    end;
  end;

  LThread.Free;
end.
