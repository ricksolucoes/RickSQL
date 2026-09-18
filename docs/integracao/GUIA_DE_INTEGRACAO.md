# RickSQL Integration Guide

> [Back to the documentation index](../README.md)

This guide explains how to integrate the RickSQL source code into a Delphi project. The implementation remains under `src/`; documentation is centralized under `docs/`; executable examples live under `samples/`; the official suite for new refactorings lives under `NewTests/`; and `tests/` remains the legacy suite.

## Directory structure

The physical structure relevant to integration is:

```text
RickSQL/
  README.md
  README.pt-BR.md
  LICENSE
  LICENSE-pt-BR
  src/
    Rick.SQL.pas
    Rick.SQL.Interf.pas
    model/
      Rick.SQL.Model.Types.pas
      Rick.SQL.Model.Connection.Options.pas
      Rick.SQL.Model.Command.Options.pas
      Rick.SQL.Model.Command.pas
      Rick.SQL.Model.Parameter.pas
      Rick.SQL.Model.Error.pas
      Rick.SQL.Model.Execution.Result.pas
      Rick.SQL.Model.Driver.Definition.pas
      Rick.SQL.Model.Contracts.pas
    error/
      Rick.SQL.Error.Normalizer.pas
    core/
      Rick.SQL.Core.Connection.Validator.pas
      Rick.SQL.Core.Command.Validator.pas
      Rick.SQL.Core.Parameter.Validator.pas
      Rick.SQL.Core.Driver.Factory.pas
      Rick.SQL.Core.Driver.Context.Factory.pas
      Rick.SQL.Core.ClientLibrary.Resolver.pas
      Rick.SQL.Core.DataSet.Materializer.pas
      Rick.SQL.Core.Error.Parser.pas
      Rick.SQL.Core.Open.Executor.pas
      Rick.SQL.Core.Command.Executor.pas
    services/
      Rick.SQL.Service.FireDAC.Session.pas
      Rick.SQL.Service.FireDAC.Connection.pas
      Rick.SQL.Service.FireDAC.Query.pas
      Rick.SQL.Service.FireDAC.Parameter.Binder.pas
      Rick.SQL.Service.FireDAC.Transaction.pas
      drivers/
        Rick.SQL.Service.FireDAC.Driver.Base.pas
        Rick.SQL.Service.FireDAC.Driver.Context.pas
        Rick.SQL.Service.FireDAC.Driver.Firebird.pas
        Rick.SQL.Service.FireDAC.Driver.InterBase.pas
        Rick.SQL.Service.FireDAC.Driver.PostgreSQL.pas
        Rick.SQL.Service.FireDAC.Driver.MSSQL.pas
        Rick.SQL.Service.FireDAC.Driver.MySQL.pas
        Rick.SQL.Service.FireDAC.Driver.SQLite.pas
        Rick.SQL.Service.FireDAC.Driver.Oracle.pas
        Rick.SQL.Service.FireDAC.Driver.DB2.pas
        Rick.SQL.Service.FireDAC.Driver.SQLAnywhere.pas
        Rick.SQL.Service.FireDAC.Driver.Informix.pas
        Rick.SQL.Service.FireDAC.Driver.Advantage.pas
        Rick.SQL.Service.FireDAC.Driver.Access.pas
        Rick.SQL.Service.FireDAC.Driver.ODBC.pas
  docs/
    README.md
    README.pt-BR.md
    integracao/
    api/
    bancos/
    testes/
    engenharia/
  NewTests/
    RickSQL.NewTests.dpr
    RickSQL.NewTests.dproj
    src/
      Error/
        Rick.SQL.Tests.Error.Integration.pas
        Rick.SQL.Tests.Error.Normalizer.pas
  tests/                  # legacy
    compilacao/
    unitarios/
    integracao/
    memoria/
    concorrencia/
  samples/
    Interface/
    console/
    fmx/
    servico-windows/
```

The primary public facade is `Rick.SQL`, which contains the `TRickSQL` class. The project also exposes the complementary fluent API `Rick.SQL.Interf`, whose entry point is `TRickSQLInterf.New` and whose public consumption occurs through the `IRickSQL*` interfaces. The remaining internal units use the `Rick.SQL.` prefix to reduce naming collisions with units from other projects on the same `Library Path`.

The project has no `packages` directory and no `.dpk` file.

## Relevant internal organization

`Rick.SQL.Core.Driver.Context.Factory.pas`, through `TRickSQLCoreDriverContextFactory`, centralizes provider resolution (through `Rick.SQL.Core.Driver.Factory`) and client-library resolution (through `Rick.SQL.Core.ClientLibrary.Resolver`) required to create a `TRickSQLServiceFireDACDriverContext`.

It is consumed by both `Rick.SQL.Core.Open.Executor` and `Rick.SQL.Core.Command.Executor`, preventing the two executors from duplicating driver-context creation logic.

The `src/error/Rick.SQL.Error.Normalizer.pas` unit centralizes the shared policy for exception normalization, `Message`/`TechnicalDetail` sanitization, and FireDAC metadata extraction. It is placed outside `core` and `services` so both can consume it without introducing a `services -> core` dependency. `Rick.SQL.Core.Error.Parser` remains responsible for the fixed user-facing messages used by core flows and delegates technical normalization.

The separation-of-responsibilities policy is documented in [Toxicity control](../engenharia/CONTROLE_DE_TOXICIDADE.md).

## Delphi configuration

Configure the source-code path either in Delphi's global `Library Path` or in the consuming project's `Search Path`.

Recommended absolute paths:

```text
C:\Bibliotecas\RickSQL\src
C:\Bibliotecas\RickSQL\src\model
C:\Bibliotecas\RickSQL\src\error
C:\Bibliotecas\RickSQL\src\core
C:\Bibliotecas\RickSQL\src\services
C:\Bibliotecas\RickSQL\src\services\drivers
```

You can also use an environment variable:

```text
RICKSQL_HOME=C:\Bibliotecas\RickSQL
```

Then configure the `Library Path` with:

```text
$(RICKSQL_HOME)\src
$(RICKSQL_HOME)\src\model
$(RICKSQL_HOME)\src\error
$(RICKSQL_HOME)\src\core
$(RICKSQL_HOME)\src\services
$(RICKSQL_HOME)\src\services\drivers
```

## Using RickSQL in existing applications

To use the primary facade, import:

```pascal
uses
  Rick.SQL;
```

To use the complementary fluent API, import:

```pascal
uses
  Rick.SQL.Interf;
```

You do not need to import both units for the same usage style.

The application does not need to import FireDAC units directly, such as:

```pascal
FireDAC.Phys.FB;
FireDAC.Phys.PG;
FireDAC.Phys.MSSQL;
```

These references are handled internally by the RickSQL providers under `src/services/drivers` and are linked into the executable through `Rick.SQL.Core.Driver.Factory`, which references all driver units in the `implementation` section of its `uses` clause.

## No package or visual component installation

RickSQL has no:

- `.dpk` file;
- package installation step;
- component-palette registration;
- visual components;
- VCL dependency in the internal source code (`src/`).

The framework does not require the consuming application to be FMX. There is, however, a conditional selection of the FireDAC wait unit in `Rick.SQL.Core.ClientLibrary.Resolver`: without `CONSOLE_CONNECTION`, compilation references `FireDAC.FMXUI.Wait`; with `CONSOLE_CONNECTION`, it references `FireDAC.ConsoleUI.Wait`.

The framework is distributed as source code, together with the centralized documentation under `docs/` and the license files at the project root.

## Compiler directives

### Console applications — `CONSOLE_CONNECTION`

Console projects must define `CONSOLE_CONNECTION` as a project-level *Conditional Define*. The directive is read by `Rick.SQL.Core.ClientLibrary.Resolver`, so it must be available while that unit is being compiled. Configure the symbol under **Project > Options > Delphi Compiler > Conditional defines** or pass it through `-D` to the compiler.

A `{$DEFINE CONSOLE_CONNECTION}` placed only in the `.dpr` is not sufficient to change the compilation of a separately compiled unit that checks the symbol. For that reason, [`samples/console/RickSQL.Sample.Console.dproj`](../../samples/console/RickSQL.Sample.Console.dproj) defines the symbol in the compiler options.

The console sample demonstrates use of the `Rick.SQL` facade in this scenario.

### Conditional providers — `FULL_EDITION`

The SQL Server, Oracle, DB2, SQL Anywhere, Informix, and ODBC implementations are compiled under `FULL_EDITION`. To use these engines, add `FULL_EDITION` to the consuming project's *Conditional Defines*. Without the symbol, the factory still resolves the providers, but their configuration/validation operations report that `FULL_EDITION` is required.

SQLite, Firebird, InterBase, PostgreSQL, MySQL, Advantage, and Access providers do not use this condition.

## Recommended usage flow

1. Add the RickSQL folders to the project's `Library Path` or `Search Path`.
2. Add `Rick.SQL` to the consuming unit's `uses` clause, or `Rick.SQL.Interf` when the fluent API is the selected usage style.
3. With the primary facade, create `TRickSQLConnectionOptions` through `TRickSQL.ConnectionOptions(AEngine)`.
4. Fill in the connection fields required by the selected engine (see [Connection options](../api/OPCOES_DE_CONEXAO.md) and [Supported databases](../bancos/BANCOS_SUPORTADOS.md)).
5. Create a `TRickSQLCommand` through `TRickSQL.Command(AConnection, ASQL)`.
6. Add parameters through `LCommand.AddParameter(TRickSQLParameter.Create(AName, AValue))` when required by the SQL.
7. Call `TRickSQL.Open` for queries or `TRickSQL.Execute` for data-changing commands.
8. Handle `TRickSQLError` (returned by `Open`) or `TRickSQLExecutionResult.Error` (returned by `Execute`).
9. Release the `TDataSet` returned by `Open` in the corresponding `finally` block.

The equivalent fluent flow is documented in [Public API](../api/API_PUBLICA.md) and demonstrated in [Usage examples](EXEMPLOS_DE_USO.md).

## Client libraries

Some databases require native libraries such as `fbclient.dll` (Firebird), `libpq.dll` (PostgreSQL), or `libmysql.dll` (MySQL). RickSQL can locate and configure these libraries through `Rick.SQL.Core.ClientLibrary.Resolver`, but it does not install, download, or copy files into the operating system.

See [Client libraries](../bancos/BIBLIOTECAS_CLIENTE.md) for the search order, architecture rules, and expected library names for each engine.
