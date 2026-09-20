# Ownership and Lifetime

> [Back to the documentation index](../README.md)

## Returned dataset

`TRickSQL.Open` returns a disconnected `TDataSet`. Internally, `Rick.SQL.Core.Open.Executor` opens a real query through a FireDAC session (`TRickSQLServiceFireDACSession`) and then passes the result to `Rick.SQL.Core.DataSet.Materializer`, which copies the field structure (`FieldDefs`) and all returned rows into an independent `TFDMemTable` created without an owner (`TFDMemTable.Create(nil)`).

After `Open` returns:

- the internal FireDAC session (query, connection, and driver context) has already been released in the executor's `finally` block before the method returns;
- the returned `TFDMemTable` remains active and usable because its data has already been copied into memory and no longer depends on the original connection.

## Release responsibility — `TRickSQL` facade

With the `TRickSQL` facade, the caller owns the returned dataset and must release it explicitly:

```pascal
LDataSet := TRickSQL.Open(LCommand, LError);
try
  // use the dataset
finally
  LDataSet.Free;
end;
```

Do not release the dataset before you finish consuming its data. `LDataSet.Free` is safe even when `LDataSet` is `nil` (the standard Delphi semantics of `TObject.Free`).


## Fluent API lifecycle — `TRickSQLInterf`

`TRickSQLInterf.New` creates one stateful instance that implements all `IRickSQL*` interfaces. Navigation methods (`Command`, `Parameter`, `Option`, `Materialization`, `Back`, `Return`, `ToBack`, `Cursor`, and `Result`) return interfaces to that same instance; they do not create a new command state.

The state below belongs to the instance and remains there until it is explicitly replaced/cleared or the facade is destroyed:

| State | Initialization | Changed by | After `Execute` | After `Open` | Cleared by `SQL(...)`? | Cleared by `Parameter.Clear`? | End of lifetime |
|---|---|---|---|---|---|---|---|
| SQL | empty string from the zero-initialized instance | `SQL(...)` | persists | persists | replaces only the SQL itself | no | instance destruction |
| finalized parameters | empty array | `Add`, `AddNull`, `AddVariant`, `Clear` | persist | persist | no | **yes** | instance destruction or `Clear` |
| parameter under construction | `Name=''`, `Value=Null`, `DataType=ftUnknown`, `Size=0`, `Direction=ptInput`, `IsNull=False` | `Name`, `Value`, `DataType`, `Size`, `Direction`, `IsNull`, `Default` | persists if not finalized | persists if not finalized | no | **no** | `Default`, `Add*` (which calls `Default`), or destruction |
| command options | `TimeOut=0`, `Transation=True`, `FetchAll=True`, `MaxRedord=0` | `IRickSQLCommandOptions` setters | persist | persist | no | no | instance destruction |
| materialization options | `Position=True`, `Preserve=True` | `IRickSQLMaterializationOptions` setters | persist | persist | no | no | instance destruction |
| connection options | empty/zero fields; engine initially `Unknown`; no extra parameters | `IRickSQLConnectionOptions` | persist | persist | no | no; `ClearConnectionParameter` clears extras only | instance destruction |
| error/result | neutral state (`Error=''`, `Success=False`, `RowsAffected=0`, empty structured error) | `Open`/`Execute` | replaced by execution result | replaced by open result | no | no | reset at the beginning of the next operation and during destruction |
| internal dataset | `nil` | `Open` | see ownership rules below | replaced by the new `Open` result | no | no | depends on `Owner` |
| `Owner` | `True` | `Owner(Boolean)` | persists | persists | no | no | instance destruction |

### `SQL(...)` does not start a clean command

`SQL(const ASQL: string)` changes only `FSQL`. It does not clear finalized parameters, the parameter under construction, command options, materialization options, connection options, `Owner`, or the previous result. The previous result is reset only when `Open` or `Execute` starts.

To reuse existing configuration, change only the required state. To remove finalized parameters, use `.Command.Parameter.Clear`. For a completely independent command, `TRickSQLInterf.New` is the existing mechanism that creates clean state; its constructor only initializes fields/defaults and does not open a connection or create a dataset. There is no public full-reset operation.

### `DataSet` returns the internal reference

`IRickSQLResult.DataSet` only returns `FDataSet`. It does not clone the dataset, materialize it again, or change ownership. The reference lifetime therefore depends on `Owner` and on subsequent operations performed on the same instance.

### `Owner(True)` — default

With `Owner(True)`, the fluent instance is responsible for releasing the dataset currently stored in `FDataSet`:

- at the beginning of any subsequent `Open` or `Execute`, `ErrorDefault` calls `FreeAndNil(FDataSet)` when a dataset exists;
- the destructor also calls `ErrorDefault`, so it releases the dataset still stored by the facade;
- while `Owner(True)` remains active, a reference returned by `Result.DataSet` is valid until the next `Open`/`Execute` or instance destruction, because either event releases the stored dataset;
- changing to `Owner(False)` does not invalidate that reference; it transfers the responsibility for the eventual `Free` to the consumer;
- the consumer must not call `Free` on that reference while the instance remains under `Owner(True)`, because the facade still intends to release it.

### `Owner(False)` — consumer responsibility

With `Owner(False)`, `ErrorDefault` does not release `FDataSet`. The consumer owns every dataset returned by `Open`:

- a new `Open` replaces `FDataSet` with the new reference; the previous dataset remains alive but is no longer tracked by the facade, so the consumer must have kept its own reference in order to release it;
- `Execute` does not assign `FDataSet`; therefore, after `Open -> Execute`, `Result.DataSet` still returns the last opened dataset while `Owner(False)` remains active;
- destroying the facade does not release the dataset still stored in `FDataSet`;
- the consumer must call `Free` exactly once for every dataset whose ownership it accepted; that reference remains valid until this `Free`, even if a newer `Open` has already removed the previous dataset from facade tracking.

`Owner(Boolean)` changes an instance flag, not a `TComponent.Owner` property. If the value changes after an `Open`, the policy used by the next cleanup/destruction is the current flag value. Datasets that were already displaced by a newer `Open` while `Owner(False)` was active are not tracked again by the facade.

While `Owner(False)` is active, the facade still keeps the last `Open` reference in `FDataSet`; it only stops being responsible for calling `Free`. If the consumer frees that dataset before the internal reference is replaced, `Result.DataSet` then points to an already released object. In that state, do not switch to `Owner(True)` before a new `Open` replaces the reference, because the next cleanup would attempt to release the still-stored pointer again. The safe pattern is to keep the external reference and release the dataset after the facade stops tracking it or after the facade itself has been released, as characterized by the tests.

### Successive transitions with default ownership

With `Owner(True)`:

- `Open -> Open`: the first dataset is released before the second open; `DataSet` then points to the new result;
- `Open -> Execute`: the opened dataset is released before execution; because `Execute` does not create a dataset, `DataSet` becomes `nil`;
- `Execute -> Open`: `Execute` creates no dataset; the following `Open` stores the newly returned dataset;
- `Execute -> Execute`: neither execution creates a dataset; `DataSet` remains `nil`;
- parameters, connection options, command options, materialization options, SQL, and `Owner` are not reset by those transitions.

## Empty query

A query that returns no rows is not treated as an error. The expected result is:

- an active, non-`nil` `TDataSet`;
- an available field structure (materialization requires the source query to contain at least one column—`FieldCount > 0`; otherwise a `TRickSQLErrorKind.DataSet` error is returned);
- `RecordCount = 0`;
- an empty `TRickSQLError` (`HasError = False`).

## Record limit and positioning

- When `TRickSQLCommandOptions.MaxRecords` is greater than zero, materialization stops copying rows as soon as the limit is reached (`ShouldStopCopy`), even when the source query has additional rows.
- When `TRickSQLCommandOptions.Materialization.PositionAtFirstRecord` is `True` (the default), the materialized dataset is positioned on the first record (`ADataSet.First`) before it is returned to the caller.
- Null fields in the source are copied as nulls in the destination (`ATarget.Fields[AIndex].Clear`), preserving null semantics row by row.

## Internal session

During an operation, the internal FireDAC session (`TRickSQLServiceFireDACSession`) keeps the following objects alive:

- the driver context (`FDriverContext`, of type `TRickSQLServiceFireDACDriverContext`), which keeps the driver link active;
- the connection (`FConnection: TFDConnection`);
- the query (`FQuery: TFDQuery`).

The session destructor releases them in this order:

1. query (`FreeAndNil(FQuery)`);
2. connection (`FreeAndNil(FConnection)`);
3. driver context (`FreeAndNil(FDriverContext)`), which in turn releases the driver link internally.

This order prevents the connection or query from trying to access a driver link that has already been destroyed during finalization.

## Disconnected result

The result of `Open` does not depend on an active connection. Because the data has already been copied into an independent `TFDMemTable`, the returned dataset remains usable after the internal FireDAC session has been fully released.

## `Execute`

`TRickSQL.Execute` does not return a dataset. It returns `TRickSQLExecutionResult` (`Success`, `RowsAffected`, `Error`), a value record that requires no manual release and belongs to the caller's scope from the moment it is created.

## Transactions

When `TRickSQLCommandOptions.UseTransaction` is enabled (default: `True`), `Rick.SQL.Core.Command.Executor` starts a transaction (`TRickSQLServiceFireDACTransaction.Start`) before executing the command, commits it (`Commit`) on success, and rolls it back (`Rollback`) on failure through `RollbackAfterFailure`. If an additional failure occurs during rollback, its technical detail is appended to the original error's technical detail using the literal prefix `"Falha adicional ao desfazer a transação:"`, without replacing the original cause.

No transaction should remain open after a command finishes. After calling FireDAC, both `Commit` and `Rollback` verify that the connection actually left the `InTransaction` state; otherwise, they return a structured `TRickSQLErrorKind.Transaction` error. Internally, reading `InTransaction` distinguishes active state, inactive state, and inspection failure; an exception raised by that read is normalized as a transaction error and is not interpreted as an inactive state.

`TRickSQLServiceFireDACTransaction.Active` keeps its historical Boolean contract for compatibility, including returning `False` when state inspection raises an exception. The internal `Start`, `Commit`, `Rollback`, and `RollbackAfterFailure` flows do not depend on that ambiguous behavior.

## Memory

The memory tests under `tests/memoria` exercise:

- repeated session creation and destruction;
- materialization and release of the dataset returned by `Open`;
- dynamically growing parameter arrays (`TRickSQLParameterArray`);
- internal errors converted into `TRickSQLError`;
- transactions (start, commit, and rollback);
- driver link and driver context.

See [`TESTES_E_HOMOLOGACAO.md`](../testes/TESTES_E_HOMOLOGACAO.md) for details of the available test scenarios.
