unit Rick.SQL.Integration.Test.Helper;

// Responsabilidade: oferecer utilitários mínimos para os testes de integração do RickSQL.
// NAO executa regras do framework, não cria drivers e não conhece interface visual.

interface

uses
  // RTL
  System.SysUtils,

  // Data
  Data.DB,

  // RickSQL
  Rick.SQL;

type
  TRickSQLIntegrationTestHelper = class
  public
    class procedure Check(const ACondition: Boolean;
      const AMessage: string); static;
    class procedure CheckResult(const AResult: TRickSQLExecutionResult;
      const AMessage: string); static;
    class procedure CheckError(const AError: TRickSQLError;
      const AMessage: string); static;
    class function Env(const AName: string): string; static;
    class function HasEnv(const AName: string): Boolean; static;
    class procedure FreeDataSet(var ADataSet: TDataSet); static;
  end;

implementation

class procedure TRickSQLIntegrationTestHelper.Check(
  const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

class procedure TRickSQLIntegrationTestHelper.CheckResult(
  const AResult: TRickSQLExecutionResult; const AMessage: string);
begin
  if AResult.Success then
    Exit;

  raise Exception.Create(AMessage + ' Detalhe: ' + AResult.Error.Message);
end;

class procedure TRickSQLIntegrationTestHelper.CheckError(
  const AError: TRickSQLError; const AMessage: string);
begin
  if not AError.HasError then
    Exit;

  raise Exception.Create(AMessage + ' Detalhe: ' + AError.Message);
end;

class function TRickSQLIntegrationTestHelper.Env(const AName: string): string;
begin
  Result := GetEnvironmentVariable(AName);
end;

class function TRickSQLIntegrationTestHelper.HasEnv(
  const AName: string): Boolean;
begin
  Result := Trim(Env(AName)) <> '';
end;

class procedure TRickSQLIntegrationTestHelper.FreeDataSet(
  var ADataSet: TDataSet);
begin
  if Assigned(ADataSet) then
    FreeAndNil(ADataSet);
end;

end.
