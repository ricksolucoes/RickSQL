# Test environment configuration

> [Back to the test index](README.md)

Open `tests/RickSQL.Tests.dproj`. It references `RickSQL.Tests.dpr` as `MainSource`, defaults to `Debug`/`Win32`, and defines `RICK_VCL_CONNECTION`.

Recommended validation flow: clean stale `Win32\Debug` output when needed, Build the project, run the DUnit GUI suite, check GUI failures/errors, close the GUI to trigger the second XML run, and inspect `dunitx-results.xml`. `/noxml` disables only the second run. The suite must be idempotent.

SQLite tests are self-contained and use temporary files.

Firebird variables: `RICKSQL_FIREBIRD_SERVER`, `RICKSQL_FIREBIRD_DATABASE`, `RICKSQL_FIREBIRD_USERNAME`, `RICKSQL_FIREBIRD_PASSWORD`, `RICKSQL_FIREBIRD_CLIENT_LIBRARY`. The external CRUD test runs only when `RICKSQL_FIREBIRD_DATABASE` is non-empty.

PostgreSQL variables used by external tests: `RICKSQL_POSTGRESQL_SERVER`, `RICKSQL_POSTGRESQL_DATABASE`, `RICKSQL_POSTGRESQL_USERNAME`, `RICKSQL_POSTGRESQL_PASSWORD`, `RICKSQL_POSTGRESQL_CLIENT_LIBRARY`. The concurrency scenario additionally accepts `RICKSQL_POSTGRESQL_PORT` and legacy aliases `RICKSQL_PG_SERVER`, `RICKSQL_PG_PORT`, `RICKSQL_PG_DATABASE`, `RICKSQL_PG_USER`, and `RICKSQL_PG_PASSWORD`.

With `FULL_EDITION`, SQL Server uses `RICKSQL_SQLSERVER_SERVER`, `RICKSQL_SQLSERVER_DATABASE`, `RICKSQL_SQLSERVER_USERNAME`, `RICKSQL_SQLSERVER_PASSWORD`; ODBC uses `RICKSQL_ODBC_DATASOURCE`, `RICKSQL_ODBC_USERNAME`, `RICKSQL_ODBC_PASSWORD`, and optional `RICKSQL_ODBC_SELECT_SQL`. Actual `FULL_EDITION` execution: **Not confirmed.**

A conditional DUnit method can show `PASS` after an early return due to missing configuration. Do not claim external integration approval without evidence that the method actually reached the server.
