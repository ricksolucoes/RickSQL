# RickSQL Unit Tests

> [Back to the documentation index](../README.md)

The executable projects are located under [`tests/unitarios`](../../tests/unitarios/). They are Delphi console applications and do not depend on an external testing framework.

## Available projects

- [`RickSQL.Unitarios.Modelos.Test.dpr`](../../tests/unitarios/RickSQL.Unitarios.Modelos.Test.dpr) — public models, default values, parameters, errors, and results.
- [`RickSQL.Unitarios.Validadores.Test.dpr`](../../tests/unitarios/RickSQL.Unitarios.Validadores.Test.dpr) — connection validation, SQL validation, command options, and parameters.
- [`RickSQL.Unitarios.Drivers.Test.dpr`](../../tests/unitarios/RickSQL.Unitarios.Drivers.Test.dpr) — provider resolution, `DriverID`, and default ports.
- [`RickSQL.Unitarios.Erros.Test.dpr`](../../tests/unitarios/RickSQL.Unitarios.Erros.Test.dpr) — user-facing messages, technical details, and credential masking.

## Delphi configuration

Configure the `Search Path` or `Library Path` with:

```text
RickSQL\src
RickSQL\src\model
RickSQL\src\error
RickSQL\src\core
RickSQL\src\services
RickSQL\src\services\drivers
```

Then open each `.dpr`, compile it, and run it in the applicable Delphi environment.

## Scope

These projects do not open connections to external databases. Their purpose is to validate internal contracts before integration testing.

## Known discrepancy in the current state

`RickSQL.Unitarios.Drivers.Test.dpr` expects `DefaultPort = 0` for `TRickSQLDatabaseEngine.Informix`, while `src/services/drivers/Rick.SQL.Service.FireDAC.Driver.Informix.pas` defines `DefaultPort := 9088` in both compilation branches. This case is therefore out of sync with the implementation and must not be treated as a valid provider contract until the code and test are reconciled.

## Expected harness behavior

Each project is written to finish with a success message in the console; if an assertion fails, it prints the corresponding failure message and terminates with exit code `1`.

This describes the intended behavior of the test harness. Actual execution results must be recorded separately.
