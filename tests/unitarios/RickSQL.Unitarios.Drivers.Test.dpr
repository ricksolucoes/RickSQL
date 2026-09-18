program RickSQLUnitariosDriversTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.Classes,
  System.SysUtils,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Model.Contracts,
  Rick.SQL.Model.Driver.Definition,
  Rick.SQL.Core.Driver.Factory;

type
  TRickSQLDriverExpectation = record
    Engine: TRickSQLDatabaseEngine;
    DriverID: string;
    DefaultPort: Integer;
    class function Create(const AEngine: TRickSQLDatabaseEngine;
      const ADriverID: string; const ADefaultPort: Integer)
      : TRickSQLDriverExpectation; static;
  end;

class function TRickSQLDriverExpectation.Create(
  const AEngine: TRickSQLDatabaseEngine; const ADriverID: string;
  const ADefaultPort: Integer): TRickSQLDriverExpectation;
begin
  Result.Engine := AEngine;
  Result.DriverID := ADriverID;
  Result.DefaultPort := ADefaultPort;
end;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

function CriarOpcoes(const AEngine: TRickSQLDatabaseEngine)
  : TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(AEngine);
  Result.Server := 'localhost';
  Result.Database := 'banco_teste';
  Result.UserName := 'usuario';
  Result.Password := 'senha';
end;

procedure ValidarDefinicao(const AExpected: TRickSQLDriverExpectation;
  const ADefinition: TRickSQLDriverDefinition);
begin
  Check(ADefinition.Engine = AExpected.Engine,
    'Engine da definição do driver incorreto.');
  Check(ADefinition.DriverID = AExpected.DriverID,
    'DriverID da definição do driver incorreto.');
  Check(ADefinition.DefaultPort = AExpected.DefaultPort,
    'Porta padrão da definição do driver incorreta.');
end;

procedure ValidarParametros(const AExpected: TRickSQLDriverExpectation;
  const AProvider: IRickSQLDriverProvider);
var
  LParameters: TStringList;
begin
  LParameters := TStringList.Create;
  try
    AProvider.ApplyConnectionOptions(CriarOpcoes(AExpected.Engine), LParameters);
    Check(LParameters.Values['DriverID'] = AExpected.DriverID,
      'DriverID não foi aplicado nos parâmetros FireDAC.');
  finally
    LParameters.Free;
  end;
end;

procedure ValidarDriver(const AExpected: TRickSQLDriverExpectation);
var
  LProvider: IRickSQLDriverProvider;
  LDefinition: TRickSQLDriverDefinition;
begin
  LProvider := TRickSQLCoreDriverFactory.Resolve(AExpected.Engine);
  Check(LProvider <> nil, 'Provider do driver não foi resolvido.');
  LDefinition := LProvider.Definition;
  ValidarDefinicao(AExpected, LDefinition);
  ValidarParametros(AExpected, LProvider);
end;

procedure ExecutarDriversPrincipais;
begin
  ValidarDriver(TRickSQLDriverExpectation.Create(TRickSQLDatabaseEngine.SQLite, 'SQLite', 0));
  ValidarDriver(TRickSQLDriverExpectation.Create(TRickSQLDatabaseEngine.Firebird, 'FB', 3050));
  ValidarDriver(TRickSQLDriverExpectation.Create(TRickSQLDatabaseEngine.PostgreSQL, 'PG', 5432));
  ValidarDriver(TRickSQLDriverExpectation.Create(TRickSQLDatabaseEngine.SQLServer, 'MSSQL', 1433));
  ValidarDriver(TRickSQLDriverExpectation.Create(TRickSQLDatabaseEngine.MySQL, 'MySQL', 3306));
  ValidarDriver(TRickSQLDriverExpectation.Create(TRickSQLDatabaseEngine.Oracle, 'Ora', 1521));
  ValidarDriver(TRickSQLDriverExpectation.Create(TRickSQLDatabaseEngine.ODBC, 'ODBC', 0));
end;

procedure ExecutarDriversComplementares;
begin
  ValidarDriver(TRickSQLDriverExpectation.Create(TRickSQLDatabaseEngine.InterBase, 'IB', 3050));
  ValidarDriver(TRickSQLDriverExpectation.Create(TRickSQLDatabaseEngine.DB2, 'DB2', 50000));
  ValidarDriver(TRickSQLDriverExpectation.Create(TRickSQLDatabaseEngine.SQLAnywhere, 'ASA', 2638));
  ValidarDriver(TRickSQLDriverExpectation.Create(TRickSQLDatabaseEngine.Informix, 'Infx', 0));
  ValidarDriver(TRickSQLDriverExpectation.Create(TRickSQLDatabaseEngine.Advantage, 'ADS', 6262));
  ValidarDriver(TRickSQLDriverExpectation.Create(TRickSQLDatabaseEngine.Access, 'MSAcc', 0));
end;

procedure ExecutarTestes;
begin
  ExecutarDriversPrincipais;
  ExecutarDriversComplementares;
end;

begin
  try
    ExecutarTestes;
    Writeln('Testes unitários de drivers concluídos com sucesso.');
  except
    on E: Exception do
    begin
      Writeln('Falha nos testes unitários de drivers: ', E.Message);
      Halt(1);
    end;
  end;
end.
