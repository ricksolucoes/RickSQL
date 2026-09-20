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
    ├── ClientLibrary/
    │   └── Rick.SQL.Tests.ClientLibrary.VendorLibrary.pas
    ├── Driver/
    │   └── Rick.SQL.Tests.Driver.ProviderReuse.pas
    ├── Error/
    │   ├── Rick.SQL.Tests.Error.Integration.pas
    │   └── Rick.SQL.Tests.Error.Normalizer.pas
    ├── Infrastructure/
    │   └── Rick.SQL.Tests.FireDAC.WaitProvider.pas
    ├── Transaction/
    │   └── Rick.SQL.Tests.Transaction.pas
    └── Validation/
        └── Rick.SQL.Tests.Parameter.Validator.pas

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

`NewTests/RickSQL.NewTests.dpr` is the DUnit entry point using the GUI Test Runner. Units under `NewTests/src/Error/` cover shared `TRickSQLError` normalization and integration of the components changed by the exception refactoring. `NewTests/src/Infrastructure/Rick.SQL.Tests.FireDAC.WaitProvider.pas` validates the VCL `IFDGUIxWaitCursor` provider registered by the resolver. `NewTests/src/Validation/Rick.SQL.Tests.Parameter.Validator.pas` covers SQL parameter identification and validation without depending on an external database. `NewTests/src/Transaction/Rick.SQL.Tests.Transaction.pas` covers transaction state, `Start`, `Commit`, `Rollback`, `RollbackAfterFailure`, `Active` compatibility, and `UseTransaction=False` using local SQLite. `NewTests/src/ClientLibrary/Rick.SQL.Tests.ClientLibrary.VendorLibrary.pas` covers the canonical `VendorLib` application authority, the compatible `Configure` path, the `Driver.Context`/`Driver.Context.Factory` flow, empty paths, missing properties, setter failures, observable equivalence, and provider-default preservation. `NewTests/src/Driver/Rick.SQL.Tests.Driver.ProviderReuse.pas` covers provider/definition consistency, compatibility overloads, propagation of the provider resolved during validation, reuse by `ClientLibraryResolver` and `Driver.Context.Factory`, operation isolation, and the `Execute`/`Open` SQLite paths. `NewTests/src/Facade/Rick.SQL.Tests.Fluent.Lifecycle.pas` characterizes the stateful fluent lifecycle, parameter clearing, option persistence, result reset, successive operations, dataset ownership, and instance isolation using local SQLite.

The current source suite registers eight test classes:

- `TRickSQLErrorNormalizerTests` — 6 tests covering generic exceptions, sanitization, parser contract, deterministic FireDAC metadata, and preservation of the code actually supplied by SQLite/FireDAC;
- `TRickSQLErrorIntegrationTests` — 8 integration tests covering Driver Context, Connection, Query, Session, Parameter Binder, Transaction, DataSet Materializer, and Client Library Resolver;
- `TRickSQLFireDACWaitProviderTests` — 1 infrastructure test confirming the `Forms` provider and creation of `IFDGUIxWaitCursor` in the VCL runner;
- `TRickSQLParameterValidatorTests` — 70 behavior-oriented DUnit tests covering simple/multiple/repeated parameters, case-insensitive names, extra parameters, strings, comments, false positives/false negatives, and engine-specific lexical constructs represented by the framework. Tests specify the engine explicitly when interpretation depends on the dialect and remain offline/deterministic.
- `TRickSQLTransactionTests` — 24 DUnit tests covering active/inactive state, deterministic `InTransaction` inspection failure, `Start`, `Commit`, `Rollback`, primary-error preservation in `RollbackAfterFailure`, the compatible `Active` contract, and `UseTransaction=False`.
- `TRickSQLVendorLibraryTests` — 15 DUnit tests covering canonical `VendorLib` application, empty paths, a DriverLink without `VendorLib`, setter failure, `ClientLibraryResolver.Configure`, `Driver.Context`, `Driver.Context.Factory`, preservation of the `ClientLibrary` and `Driver` classifications, path equivalence, and the InterBase provider default;
- `TRickSQLDriverProviderReuseTests` — 11 DUnit tests covering provider/definition correspondence, compatibility overloads, reuse of the provider returned by validation, provider-aware client-library resolution and driver-context creation, isolation between independent operations, and the `Execute`/`Open` SQLite paths;
- `TRickSQLFluentLifecycleTests` — 17 DUnit characterization tests covering initial state, persisted parameters/options, `Clear`, error reset, `Open`/`Execute` sequences, `Owner(True)`, `Owner(False)`, destruction, and isolation between instances.

### Current recorded real execution — 2026-09-19

After the fluent-lifecycle destructor test adjustment, the supplied **DUnit + GUI Test Runner** capture shows `RickSQL.NewTests.exe` executing the complete current suite:

```text
Tests:      152
Run:        152
Failures:     0
Errors:       0
Overrides:    0
```

The 152 executed tests match the 152 tests registered by the current source across eight classes, including the 17 tests in `TRickSQLFluentLifecycleTests`. This is therefore the latest recorded real execution of the current `NewTests/` suite. The capture demonstrates test execution; it does **not**, by itself, identify the IDE edition, target platform, build configuration, Win64, Release, or `FULL_EDITION`, so no new build claim is inferred from it.

An intermediate execution of the same 152-test suite reported one failure in `Destructor_OwnerTrue_DeveLiberarDataSet`. The test was then adjusted so that the fluent facade and its temporary interface references leave a separate scope before dataset-release verification. The subsequent supplied execution is the 152/152 result above, with no production-code or public-API change required for that adjustment.

### Historical recorded real execution — 2026-09-19 — before the lifecycle class

The previous official-suite revision that predated `TRickSQLFluentLifecycleTests` was executed with **DUnit + GUI Test Runner**. The supplied evidence for that revision records **Delphi 12 Community Edition** and a **Windows 32-bit** target for `RickSQL.NewTests.dproj`. The runner displayed:

```text
Tests:      135
Run:        135
Failures:     0
Errors:       0
Overrides:    0
Score:      100%
```

The total of 135 matched the `published` methods in that historical revision: 6 in `TRickSQLErrorNormalizerTests`, 8 in `TRickSQLErrorIntegrationTests`, 1 in `TRickSQLFireDACWaitProviderTests`, 70 in `TRickSQLParameterValidatorTests`, 24 in `TRickSQLTransactionTests`, 15 in `TRickSQLVendorLibraryTests`, and 11 in `TRickSQLDriverProviderReuseTests`. This result is retained as historical validation only; the current-suite execution is the 152/152 run documented above.

### Historical recorded build evidence — 2026-09-19 — `RickSQL.NewTests.dproj`

The supplied Delphi 12 Community Edition capture shows `RickSQL.NewTests.dproj` as **[Built]** with the selected target **Windows 32-bit**. This is historical build evidence associated with the 135-test validation round and predates the lifecycle tests. It must not be extrapolated as evidence for Win64, Release, `FULL_EDITION`, or another project.

### Historical recorded build — `RickConnection.dproj`

A previously documented validation round recorded the main `RickConnection.dproj` project compiled in **Delphi 12 Community Edition**, configuration **Debug**, target **Windows 32-bit**, with the IDE output:

```text
Compiling RickConnection.dproj (Debug, Win32)
Success
```

That result is retained as historical evidence for the configuration shown. `RickConnection.dproj` was **not revalidated by the current provider-reuse evidence**, so this historical build must not be presented as part of the current `RickSQL.NewTests.dproj` validation round.

### Previous validation history

On **2026-09-18**, an earlier suite version that did not yet include `TRickSQLTransactionTests` ran 84 tests with 0 failures and 0 errors. Later, during the transaction fix, a 108-test execution reported 107 passed, 1 failure, and 0 errors; the failure in `UseTransactionFalse_NaoDeveIntroduzirErroTransacional` exposed the missing `IFDGUIxWaitCursor` factory. Explicit Console/VCL/FMX provider selection and `TRickSQLFireDACWaitProviderTests` were added afterward. A later intermediate round, before `TRickSQLDriverProviderReuseTests` was added, executed **124/124** tests with no failures or errors.

Those earlier results are retained only as history. The latest documented real execution is the current-suite **152/152** run, with 0 failures, 0 errors, and 0 overrides, on 2026-09-19. Current real Method Toxicity measurements for both production `src` and `NewTests`, also supplied on 2026-09-19, are recorded in [Toxicity control](../engenharia/CONTROLE_DE_TOXICIDADE.md).

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

Console projects automatically select `FireDAC.ConsoleUI.Wait` through `CONSOLE`. The VCL `NewTests` runner defines `RICK_VCL_CONNECTION`, and FMX projects must define `RICK_FMX_CONNECTION`. `RICK_VCL_CONNECTION` and `RICK_FMX_CONNECTION` are mutually exclusive. Scenarios that functionally exercise SQL Server, Oracle, DB2, SQL Anywhere, Informix, or ODBC must account for `FULL_EDITION`.

## Acceptance criteria

As validation criteria—not as a statement that execution has occurred—the delivery should demonstrate in the applicable test environment that:

- the consumer can use the expected public facade;
- drivers are resolved internally without requiring the consumer to provide a `DriverID` or import physical FireDAC driver units;
- `Open` returns a materialized dataset that remains usable after the internal session is released;
- `Execute` returns a structured `TRickSQLExecutionResult`;
- failures covered by the public API are converted into structured errors;
- client-library resolution remains separate from canonical `VendorLib` application, preserving empty-path behavior and the existing flows' error classifications;
- memory tests do not report leaks in the scenarios actually executed;
- executed concurrency scenarios preserve the expected results;
- the relevant projects compile and run in the Delphi version selected for validation.

Compilation, execution, leak-checking, or validation results must be recorded only when obtained through actual execution.
