# Integration tests

> [Back to the test index](README.md)

All integration tests belong to the single `tests/RickSQL.Tests.dproj` project.

`TRickSQLSQLiteIntegrationTests` uses a temporary local database per fixture and validates real public flows through validators, provider/driver, FireDAC, and observable results. Scenarios cover CRUD/RowsAffected, zero affected rows, parameters, mixed types, empty result, empty SQL, missing parameter, invalid SQL, and a missing directory.

`TRickSQLExternalIntegrationTests` contains Firebird and PostgreSQL in the default branch, plus SQL Server and ODBC under `FULL_EDITION`. Methods return early when their minimum environment variable is absent. Therefore 217/217 does **not** prove that external servers were accessed. Actual external execution in this delivery: **Not confirmed.**
