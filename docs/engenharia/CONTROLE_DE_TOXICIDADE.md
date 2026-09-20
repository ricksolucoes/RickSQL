# Toxicity Control

> [Back to the documentation index](../README.md)

## Purpose

Define quality criteria that keep RickSQL code simple, readable, testable, and clearly separated by responsibility across `model`, `error`, `core`, `services`, and `services/drivers`.

This document distinguishes two kinds of information:

- **engineering rule** — a criterion that should guide new or modified code;
- **observable structure** — a responsibility that is centralized in the current code and can be verified in the referenced units.

The presence of a rule in this file does not, by itself, mean that every existing method has been measured or approved by a tool.

## Method-level rules

### Length

The project policy uses **20 lines/instructions as the reference limit for `Length`**. Methods above that limit should be reviewed; when refactoring is authorized and a separable responsibility exists, logic can be extracted into semantically clear private methods.

The goal is not to create micro-methods merely to manipulate a metric. Extractions must improve cohesion and readability without changing behavior.

### Parameters

The historical policy for this project prefers **no more than two simple parameters** per method. When a coherent larger set of data is required, configuration records may be used when there is a real architectural justification.

This policy is stricter than relying only on the generic `Parameters` threshold. DTOs, records, or artificial abstractions must not be created solely to reduce the parameter count.

### Decision depth

Public methods should aim for a maximum decision depth of 1. Compound validation should be delegated to focused responsibilities when that is appropriate for the existing design.

The `Rick.SQL.Core.Connection.Validator`, `Rick.SQL.Core.Command.Validator`, and `Rick.SQL.Core.Parameter.Validator` units illustrate validation separated by responsibility.

### Early return

Guard clauses and early return (`Exit`) are preferred when they avoid unnecessary nesting, for example:

```pascal
if not Assigned(ASession) then
  Exit;
```

Avoid `else` after a branch that already terminates control flow with `Exit`, unless readability or semantics provide a concrete reason for keeping it.

### Responsibility and duplication

A method should not combine independent responsibilities merely to reduce the number of types or units. At the same time, cosmetic abstractions without a real consumer should not be introduced.

In the current code, the following responsibilities are centralized:

- connection creation/configuration — `Rick.SQL.Service.FireDAC.Connection`;
- query preparation/configuration — `Rick.SQL.Service.FireDAC.Query`;
- parameter binding — `Rick.SQL.Service.FireDAC.Parameter.Binder`;
- commit and rollback — `Rick.SQL.Service.FireDAC.Transaction`;
- dataset materialization — `Rick.SQL.Core.DataSet.Materializer`;
- shared exception normalization, sanitization, and technical metadata extraction — `Rick.SQL.Error.Normalizer` under `src/error`;
- fixed user-facing messages for core flows — `Rick.SQL.Core.Error.Parser`, which delegates technical normalization;
- driver-context resolution — `Rick.SQL.Core.Driver.Context.Factory`, reused by the `Open` and `Execute` executors;
- application of an already resolved path to the DriverLink `VendorLib` property — `Rick.SQL.Service.FireDAC.Driver.VendorLibrary`, reused by `Driver.Context`, the compatible `ClientLibraryResolver.Configure` path, and providers that define a default `VendorLib`.

These centralizations are observable characteristics of the current architecture. Any future change should be reassessed against the code rather than against this list in isolation.

## Method Toxicity Metrics

New or modified Delphi code must consider:

- `Length`;
- `Parameters`;
- `If Depth`;
- `Cyclomatic Complexity`;
- composite `Toxicity`, when measured by RAD Studio.

For this project, the existing documentation policy uses `Length = 20` as a limit and prefers methods with at most two simple parameters when that preserves cohesion. This design preference does not automatically replace the `Parameters` threshold defined by the project, the user, or, when neither exists, the engineering baseline. For the remaining metrics, use the thresholds configured in the environment/project or the engineering baseline adopted by the project.

### Real measurement vs. static analysis

A **real measurement** exists only when RAD Studio runs `Project > Method Toxicity Metrics` or when a CSV exported by that tool is analyzed.

Without that execution:

- size, parameter count, conditional depth, and complexity may be reviewed statically;
- the composite `Toxicity` value must not be invented;
- `"Method Toxicity Metrics approved"` must not be recorded as a real result.

The minimum rule for any Delphi change is to avoid introducing new toxicity and to avoid worsening pre-existing toxicity outside the authorized scope.

### Current recorded real measurements — 2026-09-19

On **2026-09-19**, two CSV exports from RAD Studio **Method Toxicity Metrics** were supplied and analyzed: `Framework.csv`, whose measured methods are under production `src`, and `Teste-New.csv`, whose measured methods are under `NewTests`. Because the CSV files themselves do not encode IDE edition, target platform, build configuration, or conditional defines, those environment properties are not inferred from the current measurement.

| Measured scope | Max `Length` | Max `Parameters` | Max `If Depth` | Max `Cyclomatic Complexity` | Max `Toxicity` |
|---|---:|---:|---:|---:|---:|
| production `src` (`Framework.csv`) | 19 | 5 | 4 | 6 | 0.588 |
| `NewTests` (`Teste-New.csv`) | 18 | 4 | 1 | 3 | 0.350 |
| `Rick.SQL.Tests.Fluent.Lifecycle.pas` subset | 18 | 2 | 1 | 2 | 0.279 |

Against the project's baseline thresholds (`Length = 20`, `Parameters = 6`, `If Depth = 5`, `Cyclomatic Complexity = 6`, and `Toxicity = 1`), no measured method represented in the supplied CSV exports exceeds a threshold. Production `Cyclomatic Complexity` reaches the baseline limit of 6 but does not exceed it. The maximum production `Toxicity` is `0.588`, while the maximum for `NewTests` is `0.350`.

`Teste-New.csv` includes **25 measured methods** from `NewTests/src/Facade/Rick.SQL.Tests.Fluent.Lifecycle.pas`, including the lifecycle test helpers and its 17 published tests. In that unit, the highest measured `Toxicity` is `0.279` (`TDataSetReleaseProbe.Notification`), and the highest measured `Length` is 18 (`OpenOpen_OwnerFalse_DevePreservarDataSetAnterior`). The two scope-isolation helpers added by the destructor-test adjustment, `OpenOwnedDataSetAndReleaseFacade` and `OpenExternalDataSetAndReleaseFacade`, measure `Toxicity` at `0.133` and `0.146`, respectively; both have one parameter, `If Depth = 0`, and `Cyclomatic Complexity = 1`. This is real CSV-based Method Toxicity evidence for the lifecycle unit after the adjustment; it replaces the previous limitation that only static analysis was available for those tests.

The current DUnit execution associated with the updated source is documented separately in [Tests and validation](../testes/TESTES_E_HOMOLOGACAO.md): 152 tests executed, with 0 failures, 0 errors, and 0 overrides. Test execution evidence and Method Toxicity evidence remain distinct: neither is used to infer a build configuration that its artifact does not show.

### Historical recorded measurement — 2026-09-19 — before the lifecycle class

The previously documented `RickSQL.NewTests.dproj` measurement, captured in **Delphi 12 Community Edition** for **Windows 32-bit**, showed a highest visible `Toxicity` of `0.350`, with visible `Length` up to 14, `Parameters` up to 4, `If Depth` up to 1, and `Cyclomatic Complexity` up to 3. That snapshot predated `TRickSQLFluentLifecycleTests`. It remains useful as historical evidence, but the current `Teste-New.csv` measurement above now independently covers the lifecycle unit while retaining the same global maximum `Toxicity` of `0.350`.

### Historical recorded measurement — 2026-09-18

The previous measurement of the same project, also on **Delphi 12 Community Edition** and **Windows 32-bit**, was recorded before the transaction, FireDAC infrastructure, and `VendorLib` consolidation units were added. In that capture, the highest displayed `Toxicity` was `0.325`, with visible `Length` up to `14`, `Parameters` up to `4`, `If Depth` up to `1`, and `Cyclomatic Complexity` up to `3`. This record is kept only as project-evolution history; the current CSV-based measurements documented above are the latest real measurements recorded here.

## Dead code

The project rule is not to retain:

- unused variables;
- methods with no known consumer;
- commented-out blocks containing an old implementation;
- unused constants;
- orphaned `uses` entries;
- `initialization` or `finalization` sections without an architectural need.

Determining whether an element is actually dead code must be based on analysis of the project and its consumers. It must not be inferred solely from a name or from the absence of a reference in a single unit.

## Instantiation rules

Stateless classes can use `class function` and `class procedure`, as the current validators, factories, and executors do.

Classes that keep resources alive may be instantiated when their responsibility requires an independent lifetime. In the current code:

- `TRickSQLServiceFireDACDriverContext` keeps the driver link alive while the connection is in use;
- `TRickSQLServiceFireDACSession` keeps the driver context, connection, and query alive during an operation;
- `TRickSQLInterf` keeps the instance state required by the complementary fluent API.

None of these cases should be mechanically converted into class methods merely to enforce stylistic uniformity.

## `uses` organization

The preferred style separates dependencies by group when more than one category is present:

```pascal
uses
  // RTL
  System.SysUtils,

  // Data
  Data.DB,

  // FireDAC
  FireDAC.Comp.Client,

  // RickSQL
  Rick.SQL.Model.Command;
```

The `model` area must not depend on `error`, `core`, or `services`. `Rick.SQL.Error.Normalizer` depends on `model` types and the FireDAC APIs required for metadata extraction, but it does not depend on `core` or `services`; this allows both `core` and `services` to share the same normalization policy without introducing a `services -> core` dependency. The `Rick.SQL` facade keeps the executors in its `implementation` section, preventing those dependencies from becoming part of the public contract.

## Unit responsibility

New internal units should briefly state their responsibility and, when useful, what they explicitly do not do, following the pattern already present in much of the code:

```pascal
unit Rick.SQL.Core.Command.Validator;

// Responsibility: validate the data required to execute an SQL command.
// Does NOT create connections, execute SQL, or know about the visual interface.
```

This is an editorial maintenance rule. It must not be used to claim automatically that every historical unit already follows the pattern without inspection.

## FireDAC wait provider

The core does not create visual components or display messages. `Rick.SQL.Core.ClientLibrary.Resolver` selects at compile time only the `IFDGUIxWaitCursor` implementation required by FireDAC:

- `CONSOLE`: `FireDAC.ConsoleUI.Wait`;
- `RICK_VCL_CONNECTION`: `FireDAC.VCLUI.Wait`;
- `RICK_FMX_CONNECTION`: `FireDAC.FMXUI.Wait`.

`RICK_VCL_CONNECTION` and `RICK_FMX_CONNECTION` are mutually exclusive. Non-console hosts must explicitly declare one of them; missing configuration is treated as a compile-time error.

## Messages

User-facing messages controlled by the framework are kept in Brazilian Portuguese and should identify the problem without exposing sensitive data. The framework must not display `ShowMessage`, `MessageDlg`, or equivalents; it returns `TRickSQLError` and `TRickSQLExecutionResult` so the consumer can decide how to present the result.

## Message security

`Rick.SQL.Error.Normalizer` masks values associated with the following keys:

- `Password=`;
- `PWD=`;
- `Pass=`;
- `Senha=`;
- `User Password=`;
- `User_Password=`.

The detected value is replaced with `***` in textual error surfaces processed by the normalizer. This mechanism does not authorize logging full connection strings or sensitive parameters outside the normalization policy.

## Per-method checklist

```text
[ ] Length is within the applicable policy or has a justified exception.
[ ] Parameter count is within the applicable policy or has justified modeling.
[ ] If Depth has no unnecessary nesting.
[ ] Cyclomatic complexity is assessed when multiple paths are present.
[ ] Early return is used when it improves control flow.
[ ] No unnecessary else follows Exit.
[ ] Independent responsibilities are not mixed.
[ ] Operational strings are not duplicated when a shared constant is appropriate.
[ ] Logic already centralized under another responsibility is not duplicated.
[ ] No confirmed dead code remains.
[ ] The change does not introduce or worsen toxicity.
```

## Per-unit checklist

```text
[ ] The name follows the Rick.SQL namespace/prefix when the unit belongs to the framework.
[ ] Public types follow the established naming convention (TRickSQL*/IRickSQL*).
[ ] The unit responsibility is clear.
[ ] Uses contains only required dependencies and respects layer direction.
[ ] Model does not depend on error/core/services.
[ ] Error normalizer does not depend on core/services.
[ ] The core creates no visual components.
[ ] The FireDAC Wait provider matches the host: CONSOLE, RICK_VCL_CONNECTION, or RICK_FMX_CONNECTION.
[ ] No mutable global state is introduced without explicit justification.
```

## Message checklist

```text
[ ] User-facing message is in Brazilian Portuguese.
[ ] Accents and punctuation have been reviewed.
[ ] Resolution guidance is included when applicable.
[ ] No password is exposed.
[ ] No complete connection string is exposed without sanitization.
[ ] Technical detail is kept separate from the user-facing message.
```
