program RickSQLPriorityDriversPublicCompilationTest;

{$APPTYPE CONSOLE}

uses
  // RickSQL
  Rick.SQL;

var
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.SQLite);
  LOptions.Database := 'dados.db';

  LOptions := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.Firebird);
  LOptions := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.PostgreSQL);
  LOptions := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.SQLServer);
  LOptions := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.MySQL);
  LOptions := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.Oracle);
  LOptions := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.ODBC);
end.
