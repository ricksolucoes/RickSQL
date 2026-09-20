# Tests and validation

> [Back to the documentation index](../README.md)

## Strategy

Official coverage is responsibility- and observable-behavior-oriented rather than `1 unit = 1 test`. A responsibility may be validated by unit, contract, functional, local integration, lifecycle, concurrency, or a combination of those levels.

The [final coverage matrix](MATRIZ_DE_COBERTURA.md) contains all 43 units under `src/`. No 100% line-coverage claim is made because no line-coverage tool was used in this task.

The current review confirms responsibility-level coverage for the branch actually executed (`RICK_VCL_CONNECTION`, without `FULL_EDITION`). `FULL_EDITION` branches, `CONSOLE`/`RICK_FMX_CONNECTION` selection, and external integrations without infrastructure are not treated as implicitly approved; they remain conditional/**Not confirmed**.

## DUnit classes in the validated branch

| Class | Executed tests | Focus |
|---|---:|---|
| `TRickSQLErrorIntegrationTests` | 8 | cross-layer error propagation/normalization |
| `TRickSQLErrorNormalizerTests` | 6 | sanitization and FireDAC metadata |
| `TRickSQLFireDACWaitProviderTests` | 1 | VCL wait provider |
| `TRickSQLParameterValidatorTests` | 70 | SQL parameters and dialects |
| `TRickSQLTransactionTests` | 24 | `Active`, start, commit, rollback, inspection failures |
| `TRickSQLVendorLibraryTests` | 16 | client library and `VendorLib` |
| `TRickSQLDriverProviderReuseTests` | 11 | factory/provider/context and SQLite flows |
| `TRickSQLDriverContractTests` | 9 | 13-engine contracts and fallbacks |
| `TRickSQLFluentLifecycleTests` | 17 | fluent state and ownership |
| `TRickSQLDataSetMaterializerTests` | 6 | materialization and dataset lifetime |
| `TRickSQLModelTests` | 12 | records/options/models |
| `TRickSQLCommandConnectionValidatorTests` | 11 | connection/command validators |
| `TRickSQLFireDACServiceTests` | 8 | session/connection/query/binder |
| `TRickSQLSQLiteIntegrationTests` | 10 | functional `Open`/`Execute` on local SQLite |
| `TRickSQLExternalIntegrationTests` | 3 | conditional Firebird/PostgreSQL integration |
| `TRickSQLConcurrencyTests` | 5 | isolation and concurrency |
| **Total** | **217** | branch without `FULL_EDITION` |

## Post-migration evidence

The supplied execution from 2026-09-20 14:21:27, with the suite already under `tests/` and the project opened through `RickSQL.Tests.dproj`, recorded 217 tests, 0 failures, and 0 errors. The DUnit GUI also displayed 217/217. The runner's XML pass confirmed the same 217 tests and zero failures.

## Pre- and post-migration gates

Before legacy removal, all 43 source units were inventoried, legacy scenarios were classified, relevant contracts were migrated/replaced, and functional coverage existed for `Open`, `Execute`, validators, drivers, transactions, error handling, materialization, and client libraries. Migration remained blocked until the transition suite had real green execution evidence.

After migration, `tests/` is the only official suite, the legacy standalone projects are absent, the final project references existing units, and 217 tests run with zero failures/errors from the final path.

## External integrations

External methods are environment-conditional. Missing minimum variables cause an early `Exit`, which DUnit records as `PASS`; therefore the global suite result is not evidence that an external server was accessed. SQLite local execution is confirmed. Firebird, PostgreSQL, SQL Server/ODBC under `FULL_EDITION`, and other external servers: **Not confirmed**.

## Memory, concurrency, and toxicity

Lifecycle/ownership are exercised functionally, but no memory-leak detector was run. The former nondeterministic “SQLite reader and writer must always both succeed” expectation was replaced with deterministic reader concurrency and busy-then-recovery contracts.

Mandatory toxicity limits are `Length <= 20`, `Parameters <= 6`, `If Depth <= 5`, `Cyclomatic Complexity <= 6`, and `Toxicity <= 1`. The current `RickSQL.Tests.csv` provides real measurement for all 16 test units: 317 measured methods, with maxima `Length 18`, `Parameters 4`, `If Depth 1`, `Cyclomatic Complexity 5`, and `Toxicity 0.517`, with no threshold violation. This evidence measures `tests/`, not `src/`; a current production measurement is **Not confirmed**.
