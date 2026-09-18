program RickSQL.ComplementaryDrivers.ContractTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Rick.SQL,
  Rick.SQL.Model.Contracts,
  Rick.SQL.Core.Driver.Factory;

procedure CheckProvider(const AEngine: TRickSQLDatabaseEngine);
var
  LProvider: IRickSQLDriverProvider;
begin
  LProvider := TRickSQLCoreDriverFactory.Resolve(AEngine);

  if LProvider = nil then
    raise Exception.Create('Provider complementar não localizado.');

  if LProvider.Definition.DriverID = '' then
    raise Exception.Create('DriverID complementar não informado.');
end;

begin
  try
    CheckProvider(TRickSQLDatabaseEngine.InterBase);
    CheckProvider(TRickSQLDatabaseEngine.DB2);
    CheckProvider(TRickSQLDatabaseEngine.SQLAnywhere);
    CheckProvider(TRickSQLDatabaseEngine.Informix);
    CheckProvider(TRickSQLDatabaseEngine.Advantage);
    CheckProvider(TRickSQLDatabaseEngine.Access);
    Writeln('Contrato dos drivers complementares validado.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
