# Connection Options

> [Back to the documentation index](../README.md)

## Main type

Connection options are represented by the `TRickSQLConnectionOptions` record, declared in `Rick.SQL.Model.Connection.Options` and exposed as an alias by the public `Rick.SQL` unit.

## Available fields

| Field | Type | Description |
|---|---|---|
| `Engine` | `TRickSQLDatabaseEngine` | selected database engine |
| `Server` | `string` | server, host, or instance address |
| `Port` | `Integer` | connection port; zero allows the engine's default port to be used |
| `Database` | `string` | database, catalog, service, or local file path, depending on the engine |
| `UserName` | `string` | connection user name |
| `Password` | `string` | connection password |
| `CharacterSet` | `string` | character set |
| `ConnectTimeout` | `Integer` | maximum time, in seconds, allowed to establish the connection |
| `ClientLibraryPath` | `string` | explicit path to the native client library |
| `ExtraParameters` | `TRickSQLConnectionParameterArray` | additional FireDAC-specific parameters represented as name/value pairs |

## Creation and default values

The recommended way to create connection options is through the facade:

```pascal
LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
```

Internally, this method calls `TRickSQLConnectionOptions.Create(AEngine)`, which assigns the supplied value to `Engine` and initializes the remaining fields with neutral values: `Server`, `Database`, `UserName`, `Password`, `CharacterSet`, and `ClientLibraryPath` are blank; `Port` and `ConnectTimeout` are zero; `ExtraParameters` is empty (`nil`).

## Validation rules

Before any real connection attempt, `Rick.SQL.Core.Connection.Validator` applies the following checks to `TRickSQLConnectionOptions`:

- `Engine` must correspond to a valid `TRickSQLDatabaseEngine` value.
- At least one connection value must be provided: `Server`, `Database`, `UserName`, `Password`, a non-zero `Port`, or at least one item in `ExtraParameters`. Otherwise, the returned error states that the connection options were not configured.
- `Port` must be between 0 and 65535.
- `ConnectTimeout` cannot be negative.
- `ClientLibraryPath`, when supplied, cannot contain `*`, `?`, carriage return (`#13`), or line feed (`#10`).
- Every `ExtraParameters` item must have a non-empty `Name`, the name cannot contain `=`, `#13`, or `#10`, and `Value` must be provided.
- The name `DriverID` is reserved by the framework. An additional parameter with that name is rejected because `DriverID` is always resolved internally from the selected engine.
- Duplicate additional-parameter names are not allowed; comparison is case-insensitive.
- Finally, the provider for the selected engine (`IRickSQLDriverProvider.ValidateOptions`) validates that database's required fields. See the required-field table in [`BANCOS_SUPORTADOS.md`](../bancos/BANCOS_SUPORTADOS.md).

## SQLite example

```pascal
LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
LConnection.Database := 'C:\Dados\app.db';
```

## Firebird example

```pascal
LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.Firebird);
LConnection.Server := '127.0.0.1';
LConnection.Database := 'C:\Dados\ERP.FDB';
LConnection.UserName := 'SYSDBA';
LConnection.Password := 'senha';
LConnection.CharacterSet := 'UTF8';
LConnection.ClientLibraryPath := 'C:\Clientes\Firebird\fbclient.dll';
```

## PostgreSQL example

```pascal
LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.PostgreSQL);
LConnection.Server := '127.0.0.1';
LConnection.Port := 5432;
LConnection.Database := 'erp';
LConnection.UserName := 'postgres';
LConnection.Password := 'senha';
```

## SQL Server example

```pascal
LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLServer);
LConnection.Server := 'SERVIDOR\INSTANCIA';
LConnection.Database := 'ERP';
LConnection.UserName := 'usuario';
LConnection.Password := 'senha';
```

## Additional parameters

Use `ExtraParameters`, through the `AddExtraParameter` method, for FireDAC-specific parameters that do not have a dedicated field in `TRickSQLConnectionOptions`:

```pascal
LConnection.AddExtraParameter('Encrypt', 'No');
```

`DriverID` is reserved by the framework and must not be supplied by the consumer. If it is provided, connection validation returns a structured error before any connection attempt.

## Security

`Password` is used only when building the actual database connection. Framework-controlled user-facing messages and the technical detail produced by `Rick.SQL.Core.Error.Parser` automatically mask values associated with sensitive keys (`Password=`, `PWD=`, `Pass=`, `Senha=`, `User Password=`, `User_Password=`), replacing the value with `***`. See [`TRATAMENTO_DE_ERROS.md`](TRATAMENTO_DE_ERROS.md) for full details of this mechanism.
