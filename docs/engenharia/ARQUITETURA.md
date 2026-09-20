# Confirmed RickSQL architecture

> [Back to the documentation index](../README.md)

This document describes only the architecture observed in the current code. It does not label the project as Clean Architecture, Hexagonal, MVC, or another style unless that structure is explicitly present.

## Overview

```text
Rick.SQL (record API)             Rick.SQL.Interf (fluent API)
              \                    /
               +--------+---------+
                        v
              Core Executors/Validators
          +-------------+-------------+
          |                           |
          v                           v
 Command.Executor                Open.Executor
          |                           |
          +-------------+-------------+
                        v
              Driver.Context.Factory
                        |
                        v
             Driver.Factory -> Provider
                        |
                        v
                  Driver.Context
                        |
                        v
             FireDAC Session (owner)
              | Connection | Query |
              +------+-------+-----+
                     |       |
                     v       v
               Parameter   Transaction
                 Binder    (`Execute`)
                     |       |
                     +---+---+
                         v
                    FireDAC/DBMS
                         |
                         v
             DataSet.Materializer (`Open`)

Errors: Core/Services -> Error.Parser / Error.Normalizer -> TRickSQLError
Client library: DriverDefinition -> ClientLibrary.Resolver -> VendorLibrary -> DriverLink.VendorLib
```

## Boundaries and responsibilities

- `Rick.SQL` exposes the record-based `TRickSQL` facade: options, command creation, `Open`, and `Execute`.
- `Rick.SQL.Interf` implements the fluent API and keeps its own connection/command/parameter/options/result/dataset state.
- `core` contains validation, provider/context resolution, executors, error parsing, and materialization.
- `services` encapsulates concrete FireDAC session, connection, query, binder, and transaction operations.
- `services/drivers` contains engine providers, driver context, base behavior, and `VendorLib` application.
- `model` contains records, enums, and shared contracts.
- `error` contains the shared technical normalization used by core and services.

## `TRickSQL.Execute` flow

```text
TRickSQL.Execute
 -> TRickSQLCoreCommandExecutor.Execute
 -> CommandValidator.Validate
    -> ConnectionValidator
    -> ParameterValidator
 -> DriverContextFactory.Create
    -> Driver.Factory.Resolve
    -> ClientLibrary.Resolver / Driver.Context
 -> FireDAC.Session.Create
 -> FireDAC.Connection.Configure/Open
 -> FireDAC.Query.Configure
 -> FireDAC.Parameter.Binder.Bind
 -> FireDAC.Query.Prepare
 -> FireDAC.Transaction.Start (when UseTransaction=True)
 -> TFDQuery.ExecSQL
 -> RowsAffected
 -> FireDAC.Transaction.Commit
 -> RollbackAfterFailure on failure when applicable
 -> TRickSQLExecutionResult
```

## `TRickSQL.Open` flow

```text
TRickSQL.Open
 -> TRickSQLCoreOpenExecutor.Open
 -> CommandValidator.Validate
    -> ConnectionValidator
    -> ParameterValidator
 -> DriverContextFactory.Create
 -> FireDAC.Session.Create
 -> FireDAC.Connection.Configure/Open
 -> FireDAC.Query.Configure
 -> FireDAC.Parameter.Binder.Bind
 -> FireDAC.Query.Prepare/Open
 -> DataSet.Materializer.Materialize
 -> independent dataset
 -> FireDAC session released
```

## Fluent API

`TRickSQLInterf.Execute` and `TRickSQLInterf.Open` build a `TRickSQLCommand` from fluent state and delegate to the same core executors. The fluent API does not keep a permanent FireDAC connection. The `Open` dataset is stored in `FDataSet` and follows the public `Owner(Boolean)` policy documented in [Ownership and lifecycle](../api/PROPRIEDADE_E_CICLO_DE_VIDA.md).

## Ownership and lifetime

- `TRickSQLCoreDriverContextFactory.Create` creates the driver context used by the session.
- `TRickSQLServiceFireDACSession` owns `DriverContext`, `TFDConnection`, and `TFDQuery`.
- Session destruction releases `Query`, then `Connection`, then `DriverContext`.
- `Command.Executor` and `Open.Executor` create one session per operation and release it in `finally`.
- `Open` materializes data into an independent dataset before the session is destroyed.
- `DriverContext` keeps the driver link alive for the session lifetime.

## Transactions

`Execute` uses a transaction when `TRickSQLCommandOptions.UseTransaction=True`. `Start`, `Commit`, `Rollback`, and `RollbackAfterFailure` distinguish active/inactive state from a failure while inspecting `InTransaction`. `Active` preserves its historical Boolean contract, including returning `False` if state inspection raises an exception; internal flows do not depend on that ambiguity.

## Drivers and conditional compilation

The factory resolves providers for 13 engines. Without `FULL_EDITION`, DB2, Informix, SQL Server, ODBC, Oracle, and SQL Anywhere remain resolvable as fallback providers but reject functional use and report the `FULL_EDITION` requirement. SQLite, Firebird, InterBase, PostgreSQL, MySQL, Advantage, and Access remain on the default operational branch.

The FireDAC wait provider is selected from `CONSOLE`, `RICK_VCL_CONNECTION`, or `RICK_FMX_CONNECTION`. The official test project defines `RICK_VCL_CONNECTION`.

## Test project version and targets

`tests/RickSQL.Tests.dproj` contains `ProjectVersion = 20.3`, defaults to `Debug`, and defaults to `Win32`. The exact commercial Delphi release corresponding to that project version is not inferred here: **Not confirmed.**
