program RickSQLFireDACConnectionQueryContractTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Model.Error,
  Rick.SQL.Core.Driver.Context.Factory,
  Rick.SQL.Service.FireDAC.Driver.Context,
  Rick.SQL.Service.FireDAC.Session,
  Rick.SQL.Service.FireDAC.Connection,
  Rick.SQL.Service.FireDAC.Query;

procedure TestarConfiguracao;
var
  LConnection: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
  LContext: TRickSQLServiceFireDACDriverContext;
  LSession: TRickSQLServiceFireDACSession;
  LError: TRickSQLError;
begin
  LConnection := TRickSQLConnectionOptions.Create(TRickSQLDatabaseEngine.SQLite);
  LConnection.Database := ':memory:';
  LCommand := TRickSQLCommand.Create(LConnection, 'select 1 as ID');
  LContext := TRickSQLCoreDriverContextFactory.Create(
    LConnection, 'Teste de conexão e query', LError);
  LSession := TRickSQLServiceFireDACSession.Create(LContext);
  try
    if not LSession.Ready then
      Exit;

    TRickSQLServiceFireDACConnection.Configure(
      TRickSQLFireDACConnectionSetup.Create(LSession.Connection,
      LSession.DriverContext, LConnection), LError);
    TRickSQLServiceFireDACQuery.Configure(
      TRickSQLFireDACQuerySetup.Create(LSession.Query, LSession.Connection,
      LCommand), LError);
  finally
    LSession.Free;
  end;
end;

begin
  try
    TestarConfiguracao;
  except
    on E: Exception do
      Writeln(E.Message);
  end;
end.
