program RickSQLDriverContextContractTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Model.Error,
  Rick.SQL.Core.Driver.Context.Factory,
  Rick.SQL.Service.FireDAC.Driver.Context;

procedure Require(const ACondition: Boolean; const ACode: Integer);
begin
  if not ACondition then
    Halt(ACode);
end;

function MissingLibraryPath: string;
begin
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) +
    'ricksql_biblioteca_inexistente.dll';
  DeleteFile(Result);
end;

procedure TestSQLiteContext;
var
  LOptions: TRickSQLConnectionOptions;
  LContext: TRickSQLServiceFireDACDriverContext;
  LError: TRickSQLError;
begin
  LOptions := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.SQLite);
  LContext := TRickSQLCoreDriverContextFactory.Create(
    LOptions, 'Teste do contexto do driver', LError);
  try
    Require(LContext.Configured, 10);
    Require(Assigned(LContext.DriverLink), 11);
    Require(LContext.Provider.Engine = TRickSQLDatabaseEngine.SQLite, 12);
  finally
    LContext.Free;
  end;
end;

procedure TestMissingClientLibrary;
var
  LOptions: TRickSQLConnectionOptions;
  LContext: TRickSQLServiceFireDACDriverContext;
  LError: TRickSQLError;
begin
  LOptions := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.Firebird);
  LOptions.ClientLibraryPath := MissingLibraryPath;
  LContext := TRickSQLCoreDriverContextFactory.Create(
    LOptions, 'Teste do contexto do driver', LError);
  Require(not Assigned(LContext), 20);
  Require(LError.HasError, 21);
end;

begin
  TestSQLiteContext;
  TestMissingClientLibrary;
  Writeln('Contexto do driver verificado com sucesso.');
end.
