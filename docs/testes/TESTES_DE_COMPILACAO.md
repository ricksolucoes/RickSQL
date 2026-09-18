# Compilation Tests

> [Back to the documentation index](../README.md)

The executable projects are located under [`tests/compilacao`](../../tests/compilacao/). The directory currently contains **18 `.dpr` projects** that validate public and internal RickSQL contracts.

## Projects

1. [`RickSQL.Models.CompilationTest.dpr`](../../tests/compilacao/RickSQL.Models.CompilationTest.dpr) — consumption of the public models through `Rick.SQL`.
2. [`RickSQL.Driver.FactoryCompilationTest.dpr`](../../tests/compilacao/RickSQL.Driver.FactoryCompilationTest.dpr) — provider and `DriverID` resolution for `TRickSQLDatabaseEngine` values.
3. [`RickSQL.Validators.ContractTest.dpr`](../../tests/compilacao/RickSQL.Validators.ContractTest.dpr) — contracts for connection, command, and parameter validators.
4. [`RickSQL.PriorityDrivers.ContractTest.dpr`](../../tests/compilacao/RickSQL.PriorityDrivers.ContractTest.dpr) — functional contracts for the priority drivers; SQL Server, Oracle, and ODBC depend on `FULL_EDITION` for their functional implementations.
5. [`RickSQL.PriorityDrivers.PublicCompilationTest.dpr`](../../tests/compilacao/RickSQL.PriorityDrivers.PublicCompilationTest.dpr) — availability of the public priority-driver types through `Rick.SQL`.
6. [`RickSQL.ComplementaryDrivers.ContractTest.dpr`](../../tests/compilacao/RickSQL.ComplementaryDrivers.ContractTest.dpr) — resolution of the complementary providers.
7. [`RickSQL.ClientLibrary.Resolver.ContractTest.dpr`](../../tests/compilacao/RickSQL.ClientLibrary.Resolver.ContractTest.dpr) — client-library resolution and validation.
8. [`RickSQL.Driver.Context.ContractTest.dpr`](../../tests/compilacao/RickSQL.Driver.Context.ContractTest.dpr) — driver-context creation and release.
9. [`RickSQL.FireDAC.Session.ContractTest.dpr`](../../tests/compilacao/RickSQL.FireDAC.Session.ContractTest.dpr) — FireDAC session lifetime.
10. [`RickSQL.FireDAC.Connection.Query.ContractTest.dpr`](../../tests/compilacao/RickSQL.FireDAC.Connection.Query.ContractTest.dpr) — connection and query configuration.
11. [`RickSQL.FireDAC.Parameter.Binder.ContractTest.dpr`](../../tests/compilacao/RickSQL.FireDAC.Parameter.Binder.ContractTest.dpr) — FireDAC parameter binding.
12. [`RickSQL.FireDAC.Transaction.ContractTest.dpr`](../../tests/compilacao/RickSQL.FireDAC.Transaction.ContractTest.dpr) — transaction start, commit, and rollback contracts.
13. [`RickSQL.Error.Parser.ContractTest.dpr`](../../tests/compilacao/RickSQL.Error.Parser.ContractTest.dpr) — conversion of exceptions into `TRickSQLError`.
14. [`RickSQL.DataSet.Materializer.ContractTest.dpr`](../../tests/compilacao/RickSQL.DataSet.Materializer.ContractTest.dpr) — in-memory dataset materialization.
15. [`RickSQL.Open.Executor.ContractTest.dpr`](../../tests/compilacao/RickSQL.Open.Executor.ContractTest.dpr) — orchestration of the `Open` flow.
16. [`RickSQL.Command.Executor.ContractTest.dpr`](../../tests/compilacao/RickSQL.Command.Executor.ContractTest.dpr) — orchestration of the `Execute` flow.
17. [`RickSQL.Facade.ContractTest.dpr`](../../tests/compilacao/RickSQL.Facade.ContractTest.dpr) — contract of the `Rick.SQL` facade.
18. [`RickSQL.LibraryPath.FinalTest.dpr`](../../tests/compilacao/RickSQL.LibraryPath.FinalTest.dpr) — final consumption through Library/Search Path without a package.

## Conditional directives

The SQL Server, Oracle, DB2, SQL Anywhere, Informix, and ODBC providers are conditional on `FULL_EDITION`. Tests that exercise functional methods of those providers must be compiled with that symbol configured under **Project > Options > Delphi Compiler > Conditional defines** or through `-D`.

Because these tests are console applications, projects that compile the `Rick.SQL.Core.ClientLibrary.Resolver` flow must also define `CONSOLE_CONNECTION` at project level to select `FireDAC.ConsoleUI.Wait`.

## Library Path

Add the following folders to the `Library Path` or `Search Path`:

```text
RickSQL\src
RickSQL\src\model
RickSQL\src\error
RickSQL\src\core
RickSQL\src\services
RickSQL\src\services\drivers
```

No package or visual component needs to be installed.

## Results

The list above describes the projects that exist in the repository. Successful compilation and execution can only be recorded after running the corresponding compiler/environment.
