# Public API

This document is the consolidated reference for RickSQL's two public usage styles. The contract was reorganized from the previous `README.md` documentation and should be read together with the public units [`src/Rick.SQL.pas`](../../src/Rick.SQL.pas) and [`src/Rick.SQL.Interf.pas`](../../src/Rick.SQL.Interf.pas).

> [Back to the documentation index](../README.md)

## Facade characteristics

The `Rick.SQL` facade is composed of class methods and does not keep instance state. The internal utility classes used by the main flow receive the required context through parameters and do not rely on mutable global state to represent an operation.

`Rick.SQL.Interf` is deliberately different: `TRickSQLInterf` keeps **instance state** across chained calls so it can accumulate connection settings, command data, parameters, and options until `Open` or `Execute` is called. This state belongs to the instance returned by `TRickSQLInterf.New`; it is not global framework state.

The core does not display visual messages and does not require consumers to manipulate `TFDConnection`, `TFDQuery`, `TFDPhysDriverLink`, or `DriverID` directly.

## `TRickSQL` facade public API

```pascal
TRickSQL = class
public
  class function ConnectionOptions(const AEngine: TRickSQLDatabaseEngine): TRickSQLConnectionOptions; static;
  class function Command(const AConnection: TRickSQLConnectionOptions; const ASQL: string): TRickSQLCommand; static;
  class function Open(const ACommand: TRickSQLCommand; out AError: TRickSQLError): TDataSet; static;
  class function Execute(const ACommand: TRickSQLCommand): TRickSQLExecutionResult; static;
end;
```

- `ConnectionOptions` creates a `TRickSQLConnectionOptions` value populated with the defaults for the selected engine.
- `Command` creates a `TRickSQLCommand` that associates the connection options with the SQL text.
- `Open` executes a query and returns a disconnected `TDataSet` (or `nil` on failure, with `AError` populated).
- `Execute` runs a data-changing command and returns a `TRickSQLExecutionResult` containing success state, affected-row count, and a structured error.

## Query results

Queries opened through `TRickSQL.Open` return a disconnected `TDataSet`. The data is materialized in memory (using an internal `TFDMemTable`) before the call returns, so the internal connection, query, and driver context can be released without affecting the returned dataset. The returned object is owned by the caller and must be released by the caller. See [`PROPRIEDADE_E_CICLO_DE_VIDA.md`](PROPRIEDADE_E_CICLO_DE_VIDA.md) for the complete lifetime rules.

```pascal
LDataSet := TRickSQL.Open(LCommand, LError);
try
  // use the dataset
finally
  LDataSet.Free;
end;
```

## Command execution

Commands executed through `TRickSQL.Execute` return `TRickSQLExecutionResult`, which contains `Success: Boolean`, `RowsAffected: Integer`, and `Error: TRickSQLError`.

```pascal
LResult := TRickSQL.Execute(LCommand);
if not LResult.Success then
  Writeln(LResult.Error.Message);
```

## Complementary fluent interface — `Rick.SQL.Interf`

In addition to the procedural `Rick.SQL` / `TRickSQL` facade, the project provides the complementary `Rick.SQL.Interf` unit. It exposes the same functionality through a fluent API (method chaining), built entirely on the public models and executors already described in this document (`TRickSQLCoreOpenExecutor`, `TRickSQLCoreCommandExecutor`, `TRickSQLConnectionOptions`, `TRickSQLCommand`, `TRickSQLParameter`). It does not replace `Rick.SQL`; it is an additional layer, and consumers choose whichever usage style better fits their code.

## `TRickSQLInterf` facade public API

The unit has a single public entry-point class method:

```pascal
class function New: IRickSQL;
```

`TRickSQLInterf.New` creates the instance and returns it as `IRickSQL`. Consumers never call `TRickSQLInterf.Create` directly and never manipulate the concrete class. The rest of the API is accessed exclusively through the eight interfaces implemented by `TRickSQLInterf`: `IRickSQL`, `IRickSQLConnectionOptions`, `IRickSQLCommand`, `IRickSQLCommandOptions`, `IRickSQLMaterializationOptions`, `IRickSQLParameter`, `IRickSQLCursor`, and `IRickSQLResult`. Each interface is described below.

### `IRickSQL` — central hub

```pascal
IRickSQL = interface
  function ConnectionOptions: IRickSQLConnectionOptions;
  function Command: IRickSQLCommand;
  function Cursor: IRickSQLCursor;
  function Result: IRickSQLResult;

  function Owner(const AOwner: Boolean): IRickSQL;
end;
```

- `ConnectionOptions` → `IRickSQLConnectionOptions`, used to configure the connection.
- `Command` → `IRickSQLCommand`, used to configure the SQL command and its parameters.
- `Cursor` → `IRickSQLCursor`, used to run `Open` or `Execute`.
- `Result` → `IRickSQLResult`, used to read the outcome of the most recent operation.
- `Owner(AOwner: Boolean)` controls whether the instance itself owns the `TDataSet` returned by `Open` and releases it automatically (default: `True`). When `Owner(False)` is used, the consumer becomes responsible for releasing the `TDataSet`.

### `IRickSQLConnectionOptions`

```pascal
IRickSQLConnectionOptions = interface
  function Engine(const AEngine: TRickSQLDatabaseEngine): IRickSQLConnectionOptions;
  function Server(const AServer: string): IRickSQLConnectionOptions;
  function Port(const APort: Integer): IRickSQLConnectionOptions;
  function Database(const ADatabase: string): IRickSQLConnectionOptions;
  function UserName(const AUserName: string): IRickSQLConnectionOptions;
  function Password(const APassword: string): IRickSQLConnectionOptions;
  function CharacterSet(const ACharacterSet: string): IRickSQLConnectionOptions;
  function ConnectTimeout(const AConnectTimeout: Integer): IRickSQLConnectionOptions;
  function LibraryPath(const ALibraryPath: string): IRickSQLConnectionOptions;
  function AddConnectionParameter(const AName: string; const AValue: string): IRickSQLConnectionOptions;
  function ClearConnectionParameter: IRickSQLConnectionOptions;

  function Back: IRickSQL;
end;
```

Each method maps to a field in `TRickSQLConnectionOptions`. `AddConnectionParameter` adds an extra connection parameter (or updates it when the same name already exists); `ClearConnectionParameter` clears that list.

### `IRickSQLCommand`

```pascal
IRickSQLCommand = interface
  function Option: IRickSQLCommandOptions;
  function Parameter: IRickSQLParameter;

  function SQL(const ASQL: string): IRickSQLCommand;

  function Back: IRickSQL;
end;
```

`SQL` sets the command text. `Option` switches to `IRickSQLCommandOptions`. `Parameter` switches to `IRickSQLParameter`.

### `IRickSQLCommandOptions` and `IRickSQLMaterializationOptions`

```pascal
IRickSQLCommandOptions = interface
  function Materialization: IRickSQLMaterializationOptions;

  function TimeOut(const ATimeOut: Integer): IRickSQLCommand;
  function Transation(const ATransation: Boolean): IRickSQLCommand;
  function FetchAll(const AFetchAll: Boolean): IRickSQLCommand;
  function MaxRedord(const AMaxRedord: Integer): IRickSQLCommand;

  function Return: IRickSQLCommand;
end;

IRickSQLMaterializationOptions = interface
  function Position(const APosition: Boolean): IRickSQLMaterializationOptions;
  function Preserve(const APreserve: Boolean): IRickSQLMaterializationOptions;

  function ToBack: IRickSQLCommandOptions;
end;
```

Each method maps to a field in `TRickSQLCommandOptions` (`TimeOut` → `CommandTimeout`, `Transation` → `UseTransaction`, `FetchAll` → `FetchAll`, `MaxRedord` → `MaxRecords`) or `TRickSQLMaterializationOptions` (`Position` → `PositionAtFirstRecord`, `Preserve` → `PreserveFieldMetadata`).

### `IRickSQLParameter`

```pascal
IRickSQLParameter = interface
  function Name(const AName: string): IRickSQLParameter;
  function Value(const AValue: Variant): IRickSQLParameter;
  function DataType(const ADataType: TFieldType): IRickSQLParameter;
  function Size(const ASize: Integer): IRickSQLParameter;
  function Direction(const ADirection: TParamType): IRickSQLParameter;
  function IsNull(const ANull: Boolean): IRickSQLParameter;

  function Clear: IRickSQLParameter;
  function Default: IRickSQLParameter;

  function Add: IRickSQLParameter;
  function AddNull: IRickSQLParameter;
  function AddVariant: IRickSQLParameter;

  function Return: IRickSQLCommand;
end;
```

- `Add` finalizes a parameter using all six configured fields (`Name`, `Value`, `DataType`, `Size`, `Direction`, `IsNull`).
- `AddNull` and `AddVariant` are shortcuts that mirror `TRickSQLParameter.CreateNull` and `TRickSQLParameter.Create` from the model, respectively. They therefore accept only the fields handled by those constructors (`Name` + `DataType`, and `Name` + `Value`); `Size` and `Direction` do not apply to those two shortcuts.
- `Add`, `AddNull`, and `AddVariant` automatically reset the parameter-builder fields after finalizing the parameter (by calling `Default` internally), so the next `.Name(...)` starts from a neutral state.
- `Clear` empties the list of parameters already added to the current command; it does not affect the parameter currently being built.
- `Default` manually resets the fields of the parameter currently being built without affecting the already-finalized list.

### `IRickSQLCursor`

```pascal
IRickSQLCursor = interface
  function Open: IRickSQLCursor;
  function Execute: IRickSQLCursor;

  function Back: IRickSQL;
end;
```

`Open` delegates to `TRickSQLCoreOpenExecutor.Open`; `Execute` delegates to `TRickSQLCoreCommandExecutor.Execute`. Before each call, state from the previous operation (`FError`, `FErroFull`, and the previous `TDataSet` when `Owner = True`) is reset.

### `IRickSQLResult`

```pascal
IRickSQLResult = interface
  function DataSet: TDataSet;
  function Error: string;
  function ErrorFull: TRickSQLExecutionResult;
end;
```

`Error` returns the user-facing message (`TRickSQLError.Message`); `ErrorFull` returns the complete `TRickSQLExecutionResult`.

### Additional model dependency: `TRickSQLExecutionResult.Default`

For `IRickSQLCursor` to have a neutral value for `FErroFull` before any `Open`/`Execute` call, `Rick.SQL.Model.Execution.Result` (the same unit that already defines `TRickSQLExecutionResult` and is also consumed by the `Rick.SQL` facade) received a third static method in addition to `Succeeded` and `Failed`:

```pascal
class function Default: TRickSQLExecutionResult; static;
```

`Default` represents the "not executed yet" state (`Success := False`, `RowsAffected := 0`, `Error := TRickSQLError.Empty`). This method is not called by the `TRickSQL` facade; it is used internally by `TRickSQLInterf.ErrorDefault`, which is called at the beginning of `Open`/`Execute` and when the instance is destroyed.

### Usage example

```pascal
uses
  Rick.SQL.Interf;

var
  LRick: IRickSQL;
begin
  LRick := TRickSQLInterf.New
    .ConnectionOptions
      .Engine(TRickSQLDatabaseEngine.SQLite)
      .Database('C:\Dados\teste.db')
    .Back
    .Command
      .SQL('select * from clientes where id = :ID')
      .Parameter
        .Name('ID')
        .Value(1)
        .Add
      .Return
    .Back
    .Cursor
      .Open
    .Back;

  if LRick.Result.Error = '' then
    Writeln('Registros: ', LRick.Result.DataSet.RecordCount)
  else
    Writeln(LRick.Result.Error);
end;
```

### Reusing the same instance

`IRickSQL` can be reused for more than one operation, but consumers must pay attention to two points:

- **Command parameters** (`FParameters`) and **additional connection parameters** (`FExtraParameters`) accumulate across `Open`/`Execute` calls on the same instance; neither collection is cleared automatically between commands. Use `.Parameter.Clear` and `.ConnectionOptions.ClearConnectionParameter` before building a new command or connection on the same instance whenever the previous parameters must not be reused.
- The `TDataSet` returned by a previous `Open` call is released automatically at the beginning of the next `Open`/`Execute` call (and when the object is destroyed), unless `Owner(False)` was used. With `Owner(False)`, that automatic release does not occur and the consumer becomes solely responsible for releasing the dataset.
