unit Rick.SQL.Core.Driver.Factory;

// Responsabilidade: resolver o provedor de driver correspondente ao banco selecionado.
// NAO abre conexões, executa comandos SQL ou mantém registros globais mutáveis.

interface

uses
  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Contracts;

type
  TRickSQLCoreDriverFactory = class
  public
    class function Resolve(const AEngine: TRickSQLDatabaseEngine)
      : IRickSQLDriverProvider; static;
  end;

implementation

uses
  // RickSQL
  Rick.SQL.Service.FireDAC.Driver.Firebird,
  Rick.SQL.Service.FireDAC.Driver.InterBase,
  Rick.SQL.Service.FireDAC.Driver.PostgreSQL,
  Rick.SQL.Service.FireDAC.Driver.MSSQL,
  Rick.SQL.Service.FireDAC.Driver.MySQL,
  Rick.SQL.Service.FireDAC.Driver.SQLite,
  Rick.SQL.Service.FireDAC.Driver.Oracle,
  Rick.SQL.Service.FireDAC.Driver.DB2,
  Rick.SQL.Service.FireDAC.Driver.SQLAnywhere,
  Rick.SQL.Service.FireDAC.Driver.Informix,
  Rick.SQL.Service.FireDAC.Driver.Advantage,
  Rick.SQL.Service.FireDAC.Driver.Access,
  Rick.SQL.Service.FireDAC.Driver.ODBC;

const
  _MAP_DRIVER_: array[TRickSQLDatabaseEngine] of TRickSQLDriverProviderClass = (
    nil,                                     // Unknown
    TRickSQLServiceFireDACDriverFirebird,    // Firebird      (Primary)
    TRickSQLServiceFireDACDriverInterBase,   // InterBase     (Complementary)
    TRickSQLServiceFireDACDriverPostgreSQL,  // PostgreSQL    (Primary)
    TRickSQLServiceFireDACDriverMSSQL,       // SQLServer     (Primary)
    TRickSQLServiceFireDACDriverMySQL,       // MySQL         (Primary)
    TRickSQLServiceFireDACDriverSQLite,      // SQLite        (Primary)
    TRickSQLServiceFireDACDriverOracle,      // Oracle        (Primary)
    TRickSQLServiceFireDACDriverDB2,         // DB2           (Complementary)
    TRickSQLServiceFireDACDriverSQLAnywhere, // SQLAnywhere   (Complementary)
    TRickSQLServiceFireDACDriverInformix,    // Informix      (Complementary)
    TRickSQLServiceFireDACDriverAdvantage,   // Advantage     (Complementary)
    TRickSQLServiceFireDACDriverAccess,      // Access        (Complementary)
    TRickSQLServiceFireDACDriverODBC         // ODBC          (Primary)
  );

class function TRickSQLCoreDriverFactory.Resolve(
  const AEngine: TRickSQLDatabaseEngine): IRickSQLDriverProvider;
var
  LClass: TRickSQLDriverProviderClass;
begin
  Result := nil;
  LClass := _MAP_DRIVER_[AEngine];
  if Assigned(LClass) then
    Result := LClass.Create as IRickSQLDriverProvider;
end;

end.
