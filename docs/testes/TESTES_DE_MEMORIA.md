# RickSQL Memory Tests

> [Back to the documentation index](../README.md)

The executable projects are located under [`tests/memoria`](../../tests/memoria/) and enable `ReportMemoryLeaksOnShutdown` so Delphi can report observable memory leaks when the process terminates.

## Purpose

Repeatedly exercise the resources involved in framework operations, including the driver context/driver, connection, query, materialized dataset, structured errors, and parameter arrays.

The harness does not instrument each internal type individually. Therefore, the test can reveal leaks reported by the runtime, but the documentation must not claim that each class was released independently without a compatible execution and instrumentation setup.

## Available tests

### [`RickSQL.Memoria.SQLite.Test.dpr`](../../tests/memoria/RickSQL.Memoria.SQLite.Test.dpr)

Runs repeated cycles that create a temporary SQLite database, create a table, insert records, query data, and release the dataset returned by the framework. This flow repeatedly creates and destroys the internal components involved in the operation.

### [`RickSQL.Memoria.Parametros.Test.dpr`](../../tests/memoria/RickSQL.Memoria.Parametros.Test.dpr)

Creates a command with a large number of parameters to exercise dynamic arrays and their scope teardown.

## Running the tests

Configure the RickSQL folders in the `Library Path` or `Search Path`, then compile the corresponding project with the applicable Delphi environment.

Each test enables:

```pascal
ReportMemoryLeaksOnShutdown := True;
```

A leak report can only be evaluated after the binary has actually been executed. The absence of a leak report was not measured as part of this documentation reorganization.
