# Environment Setup for Integration Tests

> [Back to the documentation index](../README.md)

The executable projects are located under [`tests/integracao`](../../tests/integracao/). The original setup documentation has been centralized here; the variables below match the names used by the current projects.

## Minimum Library Path

```text
RickSQL\src
RickSQL\src\model
RickSQL\src\core
RickSQL\src\services
RickSQL\src\services\drivers
RickSQL\tests\integracao
```

Because the projects are console applications and compile the core, configure `CONSOLE_CONNECTION` at project level whenever the flow includes `Rick.SQL.Core.ClientLibrary.Resolver`.

## SQLite

The SQLite test does not require an external server. It creates a temporary file in the Windows temporary directory.

## Firebird

Variables used:

```text
RICKSQL_FIREBIRD_SERVER
RICKSQL_FIREBIRD_DATABASE
RICKSQL_FIREBIRD_USERNAME
RICKSQL_FIREBIRD_PASSWORD
RICKSQL_FIREBIRD_CLIENT_LIBRARY
```

`RICKSQL_FIREBIRD_CLIENT_LIBRARY` is optional when the client library is already available in the environment.

## PostgreSQL

Variables used:

```text
RICKSQL_POSTGRESQL_SERVER
RICKSQL_POSTGRESQL_DATABASE
RICKSQL_POSTGRESQL_USERNAME
RICKSQL_POSTGRESQL_PASSWORD
RICKSQL_POSTGRESQL_CLIENT_LIBRARY
```

`RICKSQL_POSTGRESQL_CLIENT_LIBRARY` is optional when the client library is already available in the environment.

## SQL Server

In addition to the variables below, the project must be compiled with `FULL_EDITION` under *Conditional Defines*.

```text
RICKSQL_SQLSERVER_SERVER
RICKSQL_SQLSERVER_DATABASE
RICKSQL_SQLSERVER_USERNAME
RICKSQL_SQLSERVER_PASSWORD
```

## ODBC

In addition to the variables below, the project must be compiled with `FULL_EDITION` under *Conditional Defines*.

```text
RICKSQL_ODBC_DATASOURCE
RICKSQL_ODBC_USERNAME
RICKSQL_ODBC_PASSWORD
RICKSQL_ODBC_SELECT_SQL
```

`RICKSQL_ODBC_SELECT_SQL` is optional. When it is not provided, the test uses `select 1 as codigo`.

## Required permissions

The external tests create and remove the `ricksql_integracao` table. Use a validation database or a temporary database appropriate for the environment.

Credentials and infrastructure configuration must remain outside the repository.
