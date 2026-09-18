# Tests and Validation

> [Back to the documentation index](../README.md)

## Purpose

Centralize the validation strategy for RickSQL's public and internal contracts. The official suite for new refactorings is under [`NewTests/`](../../NewTests/) and uses DUnit with the GUI Test Runner. The [`tests/`](../../tests/) tree remains the legacy suite of Delphi console projects (`.dpr`) and reference material. The presence of any test is not evidence that it has been executed.

## Organization

```text
NewTests/
├── RickSQL.NewTests.dpr
├── RickSQL.NewTests.dproj
└── src/
    └── Error/
        ├── Rick.SQL.Tests.Error.Integration.pas
        └── Rick.SQL.Tests.Error.Normalizer.pas

tests/                  # legacy
├── compilacao/
├── unitarios/
├── integracao/
├── memoria/
└── concorrencia/
```

The project under `NewTests/` consumes the production implementation directly from `../src`, while its own test units are organized under `NewTests/src/`. It does not reuse helpers that exist only under `tests/`. New refactorings and behavioral fixes must add their coverage to this official suite.

Detailed documentation for the legacy suite is separated by purpose:

- [Compilation tests](TESTES_DE_COMPILACAO.md)
- [Unit tests](TESTES_UNITARIOS.md)
- [Integration tests](TESTES_DE_INTEGRACAO.md)
- [Environment setup](CONFIGURACAO_AMBIENTE.md)
- [Memory tests](TESTES_DE_MEMORIA.md)
- [Concurrency tests](TESTES_DE_CONCORRENCIA.md)

## Official new suite

`NewTests/RickSQL.NewTests.dpr` is the DUnit entry point using the GUI Test Runner. The units registered under `NewTests/src/Error/` cover shared `TRickSQLError` normalization and integration of the components changed by the exception refactoring.

The current suite registers two test classes:

- `TRickSQLErrorNormalizerTests` — 6 tests covering generic exceptions, sanitization, parser contract, deterministic FireDAC metadata, and preservation of the code actually supplied by SQLite/FireDAC;
- `TRickSQLErrorIntegrationTests` — 8 integration tests covering Driver Context, Connection, Query, Session, Parameter Binder, Transaction, DataSet Materializer, and Client Library Resolver.

### Recorded real execution — 2026-09-18

The suite was executed on **Delphi 12 Community Edition**, targeting **Windows 32-bit**, using the **DUnit GUI Test Runner**. The runner displayed:

```text
Tests:     14
Run:       14
Failures:   0
Errors:     0
Overrides:  0
Score:    100%
```

This result confirms execution of the `NewTests` suite in that environment. It does not constitute execution of the legacy `tests/` tree and does not prove external scenarios that are not part of these 14 tests. The real Method Toxicity measurement for the test project is recorded in [Toxicity control](../engenharia/CONTROLE_DE_TOXICIDADE.md).

## Validation order

For scenarios that depend on a real database, the recommended documentation sequence is:

1. SQLite, because it does not depend on an external server.
2. Firebird, when configured.
3. PostgreSQL or SQL Server, depending on availability.
4. ODBC and any other engines available in the validation environment.

The order above is operational guidance. It does not indicate that these databases were exercised in the environment where this documentation was reviewed.

## Compilation tests

The `tests/compilacao` directory contains 18 `.dpr` projects covering models, the factory, validators, drivers, client-library resolution, FireDAC sessions, connection/query handling, parameters, transactions, error parsing, materialization, executors, the facade, and Library/Search Path consumption.

Details and prerequisites are documented in [Compilation tests](TESTES_DE_COMPILACAO.md).

## Unit tests

The `tests/unitarios` directory contains four isolated projects for models, validators, drivers, and errors. They do not depend on an external database connection.

There is a known discrepancy in the current state: `RickSQL.Unitarios.Drivers.Test.dpr` expects port `0` for Informix, while `Rick.SQL.Service.FireDAC.Driver.Informix.pas` defines `DefaultPort := 9088` in both the `FULL_EDITION` branch and the fallback branch. This must be resolved before that test is used as evidence of conformance for the Informix provider.

See [Unit tests](TESTES_UNITARIOS.md).

## Integration tests

The current projects cover SQLite, Firebird, PostgreSQL, SQL Server, ODBC, and infrastructure scenarios. SQL Server and ODBC require `FULL_EDITION` for their providers to use the functional implementations.

Observable scenarios in the current files include queries with rows, empty queries, text values, null fields, BLOBs, aliases/calculated fields, insert, update, delete, zero affected rows, invalid SQL, and missing parameters. The external Firebird, PostgreSQL, and SQL Server projects repeat the basic table-creation, insert, query, update, and delete flow when the environment is configured.

`RickSQL.Integracao.Infraestrutura.Test.dpr` covers a SQLite file in a non-existent directory, an explicitly missing client library, a missing SQL parameter, invalid SQL, and invalid PostgreSQL credentials when PostgreSQL is configured. The current files do not contain a dedicated scenario named "server unavailable" or an explicit "unsupported database" scenario.

See [Integration tests](TESTES_DE_INTEGRACAO.md) and [Environment setup](CONFIGURACAO_AMBIENTE.md).

## Memory tests

The projects enable `ReportMemoryLeaksOnShutdown` and repeat SQLite flows and parameter-array manipulation. This mechanism allows Delphi to report observable memory leaks when the process terminates.

The current tests do not instrument every internal type individually to prove separate release of the driver link, context, connection, query, transaction, or memtable. Therefore, the absence of a report can only be stated after actually running the corresponding project.

See [Memory tests](TESTES_DE_MEMORIA.md).

## Concurrency tests

The three current projects exercise concurrent SQLite operations, failure isolation between threads, and simultaneous execution across SQLite and PostgreSQL when the external environment is configured.

They validate observable operation behavior, but do not instrument the identity of each internal object to prove individually that the connection, query, context, and transaction are distinct instances.

See [Concurrency tests](TESTES_DE_CONCORRENCIA.md).

## Delphi configuration

For the test projects, configure the `Search Path` or `Library Path` with the framework folders:

```text
RickSQL\src
RickSQL\src\model
RickSQL\src\error
RickSQL\src\core
RickSQL\src\services
RickSQL\src\services\drivers
```

Console projects that compile the `Rick.SQL.Core.ClientLibrary.Resolver` path must define `CONSOLE_CONNECTION` at project level. Scenarios that functionally exercise SQL Server, Oracle, DB2, SQL Anywhere, Informix, or ODBC must account for `FULL_EDITION`.

## Acceptance criteria

As validation criteria—not as a statement that execution has occurred—the delivery should demonstrate in the applicable test environment that:

- the consumer can use the expected public facade;
- drivers are resolved internally without requiring the consumer to provide a `DriverID` or import physical FireDAC driver units;
- `Open` returns a materialized dataset that remains usable after the internal session is released;
- `Execute` returns a structured `TRickSQLExecutionResult`;
- failures covered by the public API are converted into structured errors;
- memory tests do not report leaks in the scenarios actually executed;
- executed concurrency scenarios preserve the expected results;
- the relevant projects compile and run in the Delphi version selected for validation.

Compilation, execution, leak-checking, or validation results must be recorded only when obtained through actual execution.
