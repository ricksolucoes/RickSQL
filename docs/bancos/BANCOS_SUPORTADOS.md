# Supported Databases

> [Back to the documentation index](../README.md)

## Overview

Consumers provide only the database engine through `TRickSQLDatabaseEngine`. RickSQL resolves the corresponding provider (`IRickSQLDriverProvider`), FireDAC `DriverID`, driver link, and engine-specific connection parameters internally through `Rick.SQL.Core.Driver.Factory`.

Each provider is implemented in its own unit under `src/services/drivers` and follows the same contract (`IRickSQLDriverProvider`). As a result, neither the query executor nor the command executor needs to know database-specific implementation details.

## Support matrix

| Engine (`TRickSQLDatabaseEngine`) | Internal `DriverID` | Expected client library/libraries | Default port |
|---|---|---:|---:|
| `SQLite` | `SQLite` | not required (uses a local file) | 0 |
| `Firebird` | `FB` | `fbclient.dll` | 3050 |
| `InterBase` | `IB` | `gds32.dll`, `ibtogo.dll`, `ibtogo64.dll` (in this preference order) | 3050 |
| `PostgreSQL` | `PG` | `libpq.dll` | 5432 |
| `SQLServer` | `MSSQL` | `odbc32.dll` | 1433 |
| `MySQL` | `MySQL` | `libmysql.dll` | 3306 |
| `Oracle` | `Ora` | `oci.dll` | 1521 |
| `DB2` | `DB2` | `db2cli.dll` | 50000 |
| `SQLAnywhere` | `ASA` | `dbodbc17.dll`, `dbodbc16.dll`, `dbodbc12.dll` (in this preference order) | 2638 |
| `Informix` | `Infx` | `iclit09b.dll` | 9088 |
| `Advantage` | `ADS` | `ace32.dll` (Win32 build) or `ace64.dll` (Win64 build) | 6262 |
| `Access` | `MSAcc` | `ACEODBC.DLL` | 0 |
| `ODBC` | `ODBC` | `odbc32.dll` | 0 |

Default ports and the expected client-library names are defined internally by each driver unit (`_DRIVER_ID_`, `DefaultPort`, and calls to `AddClientLibrary`). The library list feeds `TRickSQLCoreClientLibraryResolver`; when a path must be applied, `VendorLib` configuration is delegated to `TRickSQLServiceFireDACDriverVendorLibrary`.

## Availability by compilation configuration

All thirteen enum values have a provider registered in `Rick.SQL.Core.Driver.Factory`. However, six implementations are conditional on the `FULL_EDITION` symbol:

- SQL Server;
- Oracle;
- DB2;
- SQL Anywhere;
- Informix;
- ODBC.

Without `FULL_EDITION`, those providers can still be resolved by the factory, but they reject use during configuration/validation and report that the directive is required. To enable them, configure `FULL_EDITION` as a *Conditional Define* in the consuming project.

SQLite, Firebird, InterBase, PostgreSQL, MySQL, Advantage, and Access do not depend on `FULL_EDITION`.

## Required fields by engine (`RequiredConnectionOptions`)

Each provider declares, in its `TRickSQLDriverDefinition`, which `TRickSQLConnectionOptions` fields are required for that engine. The provider validates this set in `ValidateOptions`, which is called by `Rick.SQL.Core.Connection.Validator`.

| Engine | `Server` | `Database` | `UserName` | `Password` |
|---|:---:|:---:|:---:|:---:|
| SQLite | | required | | |
| Firebird | | required | required | required |
| InterBase | | required | required | required |
| PostgreSQL | required | required | required | required |
| SQL Server | required | | | |
| MySQL | required | required | required | required |
| Oracle | | required | required | required |
| DB2 | required | required | required | required |
| SQL Anywhere | | required | required | required |
| Informix | required | required | required | required |
| Advantage | | required | | |
| Access | | required | | |
| ODBC | not explicitly declared (varies by DSN or `ExtraParameters`) | | | |

When a required field is missing, `TRickSQLCoreConnectionValidator.Validate` returns a structured `TRickSQLErrorKind.Validation` error before any real connection attempt.

## Configuration examples

### SQLite

```pascal
LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
LConnection.Database := 'C:\Dados\app.db';
```

### Firebird and InterBase

- `Database` with the database file path or alias;
- `UserName` and `Password`;
- `Server` for remote databases (Firebird and InterBase also support local connections, but both providers require a user name and password).

### PostgreSQL, MySQL, DB2, Informix

- `Server`;
- `Database`;
- `UserName` and `Password`.

### SQL Server

- `Server` (may include the instance name, for example `SERVIDOR\INSTANCIA`);
- `Database`, `UserName`, and `Password` are optional at provider-validation level, but are normally required by the actual connection depending on the configured authentication mode.

### Oracle

- `Database` (service or Easy Connect identifier);
- `UserName` and `Password`.

### SQL Anywhere

- `Database`;
- `UserName` and `Password`.

### Advantage and Access

- `Database` with the file path, alias, or catalog.

### ODBC

- A DSN, driver, or additional ODBC parameters in `ExtraParameters`, because the ODBC provider does not declare a fixed set of required fields.

## Provider-specific rules

In addition to generic required fields, the following providers apply extra validation or connection-building rules.

### SQL Server — Windows authentication

The SQL Server provider (`Rick.SQL.Service.FireDAC.Driver.MSSQL`) requires `UserName` and `Password` **unless** the additional parameter `OSAuthent` is supplied with `Yes` or `True` (case-insensitive) in `ExtraParameters`, indicating Windows integrated authentication:

```pascal
LConnection.AddExtraParameter('OSAuthent', 'Yes');
```

When `OSAuthent` is not configured this way and `UserName`/`Password` are missing, validation fails with the literal message `"Informe usuário e senha ou habilite a autenticação do Windows."`. The provider also combines `Server` and `Port` into a single `server,port` parameter (the FireDAC ODBC/MSSQL driver convention) when a port is supplied and the server value does not already contain a comma.

### ODBC — DataSource vs. ODBCDriver

The ODBC provider (`Rick.SQL.Service.FireDAC.Driver.ODBC`) accepts the connection source in either of two ways, but not both at once:

- `Database` (or the additional `DataSource` parameter) identifying a configured ODBC data source (DSN); or
- the additional `ODBCDriver` parameter identifying an ODBC driver by name, without requiring a previously registered DSN.

Providing both forms at the same time is rejected by validation with the literal message `"DataSource e ODBCDriver não podem ser informados ao mesmo tempo."`. Providing neither is also rejected with `"Informe uma fonte de dados ODBC ou o nome de um driver ODBC."`.

### Oracle — automatic Easy Connect

When `Server` is supplied, the Oracle provider automatically builds an Easy Connect string in the `//server:port/database` format, using the supplied `Port` or the default port (1521) otherwise. When `Server` is omitted, `Database` is used as-is, for example as a TNS alias or service name already configured in the environment.

### Informix — HostName, InformixServer, and protocol

The Informix provider automatically applies `HostName` from `Server` and sets `Protocol` to the fixed value `olsoctcp`. The Informix server name (`InformixServer`) can be supplied explicitly through the additional `InformixServer` parameter; when it is absent, the provider also uses the `Server` value for that parameter.

### Advantage — server type

The Advantage provider automatically sets `ServerTypes` to `Local` when `Server` is empty, or to `Remote` when `Server` is provided. Consumers do not need to supply this parameter manually.

## Parameter identification and SQL dialect

The selected `TRickSQLDatabaseEngine` is also used by `Rick.SQL.Core.Parameter.Validator` to distinguish RickSQL `:NAME` markers from engine lexical constructs that also use `:`. This is a local validation step and occurs before the FireDAC session/connection is created.

This **does not** make RickSQL a full SQL parser or dialect translator. The scanner contains narrowly scoped rules required to identify parameters safely, such as engine-specific delimiters, comments, array slices, labels, PSQL, and qualifiers that are part of the official coverage. The functional description and rule matrix are documented in [Commands and parameters](../api/COMANDOS_E_PARAMETROS.md#engine-aware-lexical-parameter-identification).

`Advantage` currently uses only the scanner's common lexical rules. For `ODBC`, the enum value does not identify the actual DBMS behind the driver, so the framework also keeps only the common rules instead of assuming a specific ODBC dialect.

## Limitations

RickSQL does not translate SQL dialects. The command in `TRickSQLCommand.Text` must be compatible with the database selected by the consumer.

Examples of differences that remain the consumer's responsibility:

- `TOP` is specific to SQL Server;
- `LIMIT` is common in SQLite, PostgreSQL, and MySQL;
- date and time functions vary across databases.

The framework also does not install native libraries, database clients, or ODBC drivers in the operating system. It only locates and configures libraries that are already available. See [`BIBLIOTECAS_CLIENTE.md`](BIBLIOTECAS_CLIENTE.md).
