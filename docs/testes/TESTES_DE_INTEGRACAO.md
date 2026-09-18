# RickSQL Integration Tests

> [Back to the documentation index](../README.md)

The executable projects are located under [`tests/integracao`](../../tests/integracao/). They exercise the `Rick.SQL` facade together with executors, providers, connection handling, queries, parameters, transactions, `TDataSet` materialization, and failure handling.

## Available tests

| File | Database/scenario | External dependency |
|---|---|---|
| [`RickSQL.Integracao.SQLite.Test.dpr`](../../tests/integracao/RickSQL.Integracao.SQLite.Test.dpr) | SQLite | no external server required |
| [`RickSQL.Integracao.Firebird.Test.dpr`](../../tests/integracao/RickSQL.Integracao.Firebird.Test.dpr) | Firebird | configured Firebird database |
| [`RickSQL.Integracao.PostgreSQL.Test.dpr`](../../tests/integracao/RickSQL.Integracao.PostgreSQL.Test.dpr) | PostgreSQL | configured PostgreSQL database |
| [`RickSQL.Integracao.SQLServer.Test.dpr`](../../tests/integracao/RickSQL.Integracao.SQLServer.Test.dpr) | SQL Server | configured SQL Server database + `FULL_EDITION` |
| [`RickSQL.Integracao.ODBC.Test.dpr`](../../tests/integracao/RickSQL.Integracao.ODBC.Test.dpr) | ODBC | configured ODBC data source + `FULL_EDITION` |
| [`RickSQL.Integracao.Infraestrutura.Test.dpr`](../../tests/integracao/RickSQL.Integracao.Infraestrutura.Test.dpr) | infrastructure failures | some scenarios are local; PostgreSQL credentials depend on the environment |

## Recommended order

1. SQLite.
2. Infrastructure scenarios.
3. Firebird, when configured.
4. PostgreSQL or SQL Server, depending on availability.
5. ODBC, when configured.

This sequence is operational guidance; it does not represent an execution history.

## Configuration

External-database tests read environment variables. When the required configuration is missing, the corresponding projects contain paths that report the situation in the console instead of assuming the infrastructure is present.

SQL Server and ODBC require `FULL_EDITION` as a *Conditional Define* for the functional implementations of their providers.

See [Environment setup](CONFIGURACAO_AMBIENTE.md) for the variables and permissions used by the current projects.

## Observable coverage in the current files

The scenarios currently present include queries that return rows, empty queries, text values, nulls, BLOBs, aliases/calculated fields, insert, update, delete, zero affected rows, invalid SQL, and missing parameters.

The infrastructure project covers a SQLite file in a non-existent directory, an explicitly missing client library, a missing SQL parameter, invalid SQL, and invalid PostgreSQL credentials when PostgreSQL is configured. The current files do not contain a dedicated test identified as "server unavailable" or "unsupported database".

## Results

The presence of these scenarios does not prove that they pass. Results must be recorded only after actual execution in a configured environment.
