program RickSQLDriverFactoryCompilationTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Model.Contracts,
  Rick.SQL.Core.Driver.Factory;

var
  LEngine: TRickSQLDatabaseEngine;
  LProvider: IRickSQLDriverProvider;
  LValue: Integer;
begin
  for LValue := Ord(Low(TRickSQLDatabaseEngine)) to
    Ord(High(TRickSQLDatabaseEngine)) do
  begin
    LEngine := TRickSQLDatabaseEngine(LValue);
    LProvider := TRickSQLCoreDriverFactory.Resolve(LEngine);

    if not Assigned(LProvider) then
      Halt(1);

    if LProvider.Engine <> LEngine then
      Halt(2);

    if Trim(LProvider.Definition.DriverID) = '' then
      Halt(3);
  end;
end.
