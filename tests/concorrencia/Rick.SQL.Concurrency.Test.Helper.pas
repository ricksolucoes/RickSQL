unit Rick.SQL.Concurrency.Test.Helper;

// Responsabilidade: oferecer utilitários mínimos para testes de concorrência do RickSQL.
// NAO executa regras do framework, não cria drivers e não conhece interface visual.

interface

uses
  // RTL
  System.SysUtils,
  System.IOUtils,

  // Data
  Data.DB,

  // RickSQL
  Rick.SQL;

type
  TRickSQLConcurrencyTestHelper = class
  public
    class procedure Check(const ACondition: Boolean;
      const AMessage: string); static;
    class function Env(const AName: string): string; static;
    class function HasEnv(const AName: string): Boolean; static;
    class function TempDatabaseName(const APrefix: string): string; static;
    class function SQLiteConnection(
      const ADatabase: string): TRickSQLConnectionOptions; static;
    class procedure DeleteFileIfExists(const AFileName: string); static;
    class procedure FreeDataSet(var ADataSet: TDataSet); static;
  end;

implementation

USES
  Winapi.Windows;

class procedure TRickSQLConcurrencyTestHelper.Check(
  const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

class function TRickSQLConcurrencyTestHelper.Env(const AName: string): string;
begin
  Result := GetEnvironmentVariable(AName);
end;

class function TRickSQLConcurrencyTestHelper.HasEnv(
  const AName: string): Boolean;
begin
  Result := Trim(Env(AName)) <> '';
end;

class function TRickSQLConcurrencyTestHelper.TempDatabaseName(
  const APrefix: string): string;
begin
  Result := TPath.Combine(TPath.GetTempPath,
    Format('%s_%d.sqlite', [APrefix, GetTickCount]));
end;

class function TRickSQLConcurrencyTestHelper.SQLiteConnection(
  const ADatabase: string): TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  Result.Database := ADatabase;
end;

class procedure TRickSQLConcurrencyTestHelper.DeleteFileIfExists(
  const AFileName: string);
begin
  if TFile.Exists(AFileName) then
    TFile.Delete(AFileName);
end;

class procedure TRickSQLConcurrencyTestHelper.FreeDataSet(
  var ADataSet: TDataSet);
begin
  if Assigned(ADataSet) then
    FreeAndNil(ADataSet);
end;

end.
