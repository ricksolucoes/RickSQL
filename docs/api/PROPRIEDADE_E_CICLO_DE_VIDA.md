# Ownership and Lifetime

> [Back to the documentation index](../README.md)

## Returned dataset

`TRickSQL.Open` returns a disconnected `TDataSet`. Internally, `Rick.SQL.Core.Open.Executor` opens a real query through a FireDAC session (`TRickSQLServiceFireDACSession`) and then passes the result to `Rick.SQL.Core.DataSet.Materializer`, which copies the field structure (`FieldDefs`) and all returned rows into an independent `TFDMemTable` created without an owner (`TFDMemTable.Create(nil)`).

After `Open` returns:

- the internal FireDAC session (query, connection, and driver context) has already been released in the executor's `finally` block before the method returns;
- the returned `TFDMemTable` remains active and usable because its data has already been copied into memory and no longer depends on the original connection.

## Release responsibility

The caller owns the returned dataset and must release it explicitly:

```pascal
LDataSet := TRickSQL.Open(LCommand, LError);
try
  // use the dataset
finally
  LDataSet.Free;
end;
```

Do not release the dataset before you finish consuming its data. `LDataSet.Free` is safe even when `LDataSet` is `nil` (the standard Delphi semantics of `TObject.Free`).

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
