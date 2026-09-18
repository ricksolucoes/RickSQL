program RickSQLPriorityDriversContractTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.Classes,
  System.SysUtils,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Model.Contracts,
  Rick.SQL.Core.Driver.Factory;

procedure Require(const ACondition: Boolean; const ACode: Integer);
begin
  if not ACondition then
    Halt(ACode);
end;

function CreateOptions(const AEngine: TRickSQLDatabaseEngine)
  : TRickSQLConnectionOptions;
begin
  Result := TRickSQLConnectionOptions.Create(AEngine);
  Result.Server := '127.0.0.1';
  Result.Database := 'BaseTeste';
  Result.UserName := 'usuario';
  Result.Password := 'senha';
  Result.CharacterSet := 'UTF8';
end;

procedure TestProvider(const AEngine: TRickSQLDatabaseEngine;
  const AExpectedDriverID: string);
var
  LOwner: TComponent;
  LLink: TComponent;
  LParameters: TStringList;
  LProvider: IRickSQLDriverProvider;
  LOptions: TRickSQLConnectionOptions;
  LError: string;
begin
  LOwner := TComponent.Create(nil);
  LParameters := TStringList.Create;
  try
    LProvider := TRickSQLCoreDriverFactory.Resolve(AEngine);
    LOptions := CreateOptions(AEngine);
    LLink := LProvider.CreateDriverLink(LOwner);
    LProvider.ApplyConnectionOptions(LOptions, LParameters);
    Require(Assigned(LLink), 10 + Ord(AEngine));
    Require(LProvider.ValidateOptions(LOptions, LError), 30 + Ord(AEngine));
    Require(LParameters.Values['DriverID'] = AExpectedDriverID,
      50 + Ord(AEngine));
  finally
    LParameters.Free;
    LOwner.Free;
  end;
end;

procedure TestODBC;
var
  LOptions: TRickSQLConnectionOptions;
  LProvider: IRickSQLDriverProvider;
  LParameters: TStringList;
  LError: string;
begin
  LProvider := TRickSQLCoreDriverFactory.Resolve(
    TRickSQLDatabaseEngine.ODBC);
  LOptions := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.ODBC);
  LOptions.Database := 'MinhaFonteODBC';
  LParameters := TStringList.Create;
  try
    Require(LProvider.ValidateOptions(LOptions, LError), 80);
    LProvider.ApplyConnectionOptions(LOptions, LParameters);
    Require(LParameters.Values['DataSource'] = 'MinhaFonteODBC', 81);
  finally
    LParameters.Free;
  end;
end;

begin
  TestProvider(TRickSQLDatabaseEngine.SQLite, 'SQLite');
  TestProvider(TRickSQLDatabaseEngine.Firebird, 'FB');
  TestProvider(TRickSQLDatabaseEngine.PostgreSQL, 'PG');
  TestProvider(TRickSQLDatabaseEngine.SQLServer, 'MSSQL');
  TestProvider(TRickSQLDatabaseEngine.MySQL, 'MySQL');
  TestProvider(TRickSQLDatabaseEngine.Oracle, 'Ora');
  TestODBC;
end.
