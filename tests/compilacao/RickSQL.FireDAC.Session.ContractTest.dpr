program RickSQLFireDACSessionContractTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Model.Error,
  Rick.SQL.Core.Driver.Context.Factory,
  Rick.SQL.Service.FireDAC.Driver.Context,
  Rick.SQL.Service.FireDAC.Session;

procedure Require(const ACondition: Boolean; const ACode: Integer);
begin
  if not ACondition then
    Halt(ACode);
end;

function MissingLibraryPath: string;
begin
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) +
    'ricksql_sessao_biblioteca_inexistente.dll';
  DeleteFile(Result);
end;

procedure TestSQLiteSession;
var
  LOptions: TRickSQLConnectionOptions;
  LContext: TRickSQLServiceFireDACDriverContext;
  LSession: TRickSQLServiceFireDACSession;
  LError: TRickSQLError;
begin
  LOptions := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.SQLite);
  LContext := TRickSQLCoreDriverContextFactory.Create(
    LOptions, 'Teste da sessão FireDAC', LError);
  LSession := TRickSQLServiceFireDACSession.Create(LContext);
  try
    Require(LSession.Ready, 10);
    Require(Assigned(LSession.DriverContext), 11);
    Require(Assigned(LSession.Connection), 12);
    Require(Assigned(LSession.Query), 13);
    Require(not LSession.Error.HasError, 14);
  finally
    LSession.Free;
  end;
end;

procedure TestSessionWithMissingClientLibrary;
var
  LOptions: TRickSQLConnectionOptions;
  LContext: TRickSQLServiceFireDACDriverContext;
  LSession: TRickSQLServiceFireDACSession;
  LError: TRickSQLError;
begin
  LOptions := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.Firebird);
  LOptions.ClientLibraryPath := MissingLibraryPath;
  LContext := TRickSQLCoreDriverContextFactory.Create(
    LOptions, 'Teste da sessão FireDAC', LError);
  Require(not Assigned(LContext), 20);
  Require(LError.HasError, 21);
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  TestSQLiteSession;
  TestSessionWithMissingClientLibrary;
  Writeln('Sessão FireDAC verificada com sucesso.');
end.
