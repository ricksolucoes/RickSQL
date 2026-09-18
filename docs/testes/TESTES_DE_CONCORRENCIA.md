# RickSQL Concurrency Tests

> [Back to the documentation index](../README.md)

The executable projects are located under [`tests/concorrencia`](../../tests/concorrencia/) and exercise concurrent RickSQL operations.

## Purpose

Validate observable behavior when operations run in parallel: query/command results, isolation of a failing operation, and execution against different databases when the external environment is available.

The current tests do not instrument the identity of the connection, query, driver context, or transaction to prove individually that every internal object is distinct. That conclusion must not be inferred solely from concurrent execution.

## Available tests

### [`RickSQL.Concorrencia.SQLite.Test.dpr`](../../tests/concorrencia/RickSQL.Concorrencia.SQLite.Test.dpr)

Runs concurrent queries and commands against a temporary SQLite database.

### [`RickSQL.Concorrencia.FalhaIsolada.Test.dpr`](../../tests/concorrencia/RickSQL.Concorrencia.FalhaIsolada.Test.dpr)

Runs one valid query and one invalid query in parallel, checking the observable isolation behavior between the two flows.

### [`RickSQL.Concorrencia.BancosDiferentes.Test.dpr`](../../tests/concorrencia/RickSQL.Concorrencia.BancosDiferentes.Test.dpr)

Runs concurrent operations against SQLite and PostgreSQL.

Environment variables used by the project:

```text
RICKSQL_PG_SERVER
RICKSQL_PG_PORT
RICKSQL_PG_DATABASE
RICKSQL_PG_USER
RICKSQL_PG_PASSWORD
```

If `RICKSQL_PG_DATABASE` is not configured, the test itself contains an exit path that prints a message to the console.

## Results

This documentation describes the scenarios present in the source tree. Success, failure, or thread-safety guarantees depend on actual execution and analysis in the target environment.
