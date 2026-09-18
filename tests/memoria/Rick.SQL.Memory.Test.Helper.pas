unit Rick.SQL.Memory.Test.Helper;

// Responsabilidade: oferecer utilitários mínimos para testes de memória do RickSQL.
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
  TRickSQLMemoryTestHelper = class
  public
    class procedure Check(const ACondition: Boolean;
      const AMessage: string); static;
    class procedure CheckResult(const AResult: TRickSQLExecutionResult;
      const AMessage: string); static;
    class procedure CheckError(const AError: TRickSQLError;
      const AMessage: string); static;
    class function TempDatabaseName: string; static;
    class function SQLiteConnection(
      const ADatabase: string): TRickSQLConnectionOptions; static;
    class procedure DeleteFileIfExists(const AFileName: string); static;
    class procedure FreeDataSet(var ADataSet: TDataSet); static;
  end;

implementation

class procedure TRickSQLMemoryTestHelper.Check(const ACondition: Boolean;
  const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

class procedure TRickSQLMemoryTestHelper.CheckResult(
  const AResult: TRickSQLExecutionResult; const AMessage: string);
begin
  if AResult.Success then
    Exit;

  raise Exception.Create(AMessage + ' Detalhe: ' + AResult.Error.Message);
end;

class procedure TRickSQLMemoryTestHelper.CheckError(
  const AError: TRickSQLError; const AMessage: string);
begin
  if not AError.HasError then
    Exit;

  raise Exception.Create(AMessage + ' Detalhe: ' + AError.Message);
end;

class function TRickSQLMemoryTestHelper.TempDatabaseName: string;
begin
  Result := TPath.Combine(TPath.GetTempPath,
    Format('ricksql_memoria_%d.sqlite', [GetTickCount]));
end;

class function TRickSQLMemoryTestHelper.SQLiteConnection(
  const ADatabase: string): TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  Result.Database := ADatabase;
end;

class procedure TRickSQLMemoryTestHelper.DeleteFileIfExists(
  const AFileName: string);
begin
  if TFile.Exists(AFileName) then
    TFile.Delete(AFileName);
end;

class procedure TRickSQLMemoryTestHelper.FreeDataSet(
  var ADataSet: TDataSet);
begin
  if Assigned(ADataSet) then
    FreeAndNil(ADataSet);
end;

end.
