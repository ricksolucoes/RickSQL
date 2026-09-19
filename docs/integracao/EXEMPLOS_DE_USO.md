# Usage Examples

> [Back to the documentation index](../README.md)

The executable projects remain under [`samples/`](../../samples/). They are not part of the framework core and are not mandatory dependencies of consuming applications. Documentation for these examples is centralized here.

## Configuration requirement

Before compiling any example, add the framework folders to Delphi's `Library Path` or the project's `Search Path`:

```text
RickSQL\src
RickSQL\src\model
RickSQL\src\error
RickSQL\src\core
RickSQL\src\services
RickSQL\src\services\drivers
```

The examples demonstrate both public usage styles. `console`, `fmx`, and `servico-windows` use the primary facade:

```pascal
uses
  Rick.SQL;
```

The `Interface` example uses the fluent API:

```pascal
uses
  Rick.SQL.Interf;
```

The consuming application does not need to import `FireDAC.Phys.*` directly.

## Convention used by the examples

The supporting units in the examples begin with `Rick.SQL`, following the framework's naming convention. Direct references to visual interfaces remain in the projects that demonstrate FMX or Windows service integration.

In the core, the FireDAC wait unit is selected through conditional compilation. Console applications automatically use `FireDAC.ConsoleUI.Wait` through `CONSOLE`; VCL applications define `RICK_VCL_CONNECTION`; FMX applications define `RICK_FMX_CONNECTION`. There is no arbitrary visual fallback for non-console hosts.

## Fluent API example (`Interface`)

Location: [`samples/Interface`](../../samples/Interface/)

Main files:

- [`RickSQL.Sample.Interf.dpr`](../../samples/Interface/RickSQL.Sample.Interf.dpr)
- [`Rick.SQL.Sample.Interf.Runner.pas`](../../samples/Interface/Rick.SQL.Sample.Interf.Runner.pas)

Demonstrates:

- instance creation through `TRickSQLInterf.New`;
- fluent SQLite connection configuration;
- command and query execution through `IRickSQLCursor`;
- result access through `IRickSQLResult`;
- fluent parameters;
- reuse of the same `IRickSQL` instance;
- use of `.Parameter.Clear` between commands to clear finalized parameters before the next operation.

## Console example

Location: [`samples/console`](../../samples/console/)

Main files:

- [`RickSQL.Sample.Console.dpr`](../../samples/console/RickSQL.Sample.Console.dpr)
- [`Rick.SQL.Sample.Console.Runner.pas`](../../samples/console/Rick.SQL.Sample.Console.Runner.pas)
- [`RickSQL.Sample.Console.dproj`](../../samples/console/RickSQL.Sample.Console.dproj)

Demonstrates:

- configuration through the `SQLite` engine;
- automatic creation of a local database file;
- SQL command execution;
- parameterized queries;
- structured error handling;
- release of the returned `TDataSet`;
- execution on a worker thread;
- automatic selection of `FireDAC.ConsoleUI.Wait` through `CONSOLE`, with no RickSQL-specific define.

## Windows service example

Location: [`samples/servico-windows`](../../samples/servico-windows/)

Main files:

- [`RickSQL.Sample.ServicoWindows.dpr`](../../samples/servico-windows/RickSQL.Sample.ServicoWindows.dpr)
- [`Rick.SQL.Sample.ServicoWindows.Flow.pas`](../../samples/servico-windows/Rick.SQL.Sample.ServicoWindows.Flow.pas)

Demonstrates:

- RickSQL consumption inside a `TService`;
- execution on a worker thread;
- creation of a local SQLite database;
- logging to a file;
- command execution;
- data queries;
- resource release when the service shuts down.

## FMX example

Location: [`samples/fmx`](../../samples/fmx/)

Main files:

- [`RickSQL.Sample.FMX.dpr`](../../samples/fmx/RickSQL.Sample.FMX.dpr)
- [`Rick.SQL.Sample.FMX.Flow.pas`](../../samples/fmx/Rick.SQL.Sample.FMX.Flow.pas)

Demonstrates:

- RickSQL consumption in an FMX application;
- `RICK_FMX_CONNECTION` configured at project level to register `FireDAC.FMXUI.Wait`;
- execution on a worker thread;
- UI updates on the main thread;
- structured error handling;
- release of the returned `TDataSet`.

## Further reading

- [Integration guide](GUIA_DE_INTEGRACAO.md)
- [Public API](../api/API_PUBLICA.md)
- [Ownership and lifetime](../api/PROPRIEDADE_E_CICLO_DE_VIDA.md)
