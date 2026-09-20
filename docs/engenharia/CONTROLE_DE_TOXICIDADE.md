# Method Toxicity control

> [Back to the documentation index](../README.md)

## Mandatory policy

The quality limits for this task are fixed and must not be loosened to make code or tests pass:

| Metric | Limit |
|---|---:|
| `Length` | `<= 20` |
| `Parameters` | `<= 6` |
| `If Depth` | `<= 5` |
| `Cyclomatic Complexity` | `<= 6` |
| `Toxicity` | `<= 1` |

Thresholds must not be changed, disabled, or bypassed with cosmetic abstractions. New code must not introduce violations; modified existing code must not worsen pre-existing violations.

## Real measurement vs static evaluation

A real measurement exists only when RAD Studio `Project > Method Toxicity Metrics` was run for the state being approved or when its exported CSV was supplied. Only then may the composite `Toxicity` value be reported as measured.

Without a current IDE report, source can be statically inspected for `Length`, `Parameters`, `If Depth`, and `Cyclomatic Complexity`; the composite value must be recorded as **Toxicity: Not measured**. The internal RAD Studio formula must not be invented.

## Current verified state

The current `RickSQL.Tests.csv`, exported for the final `tests/RickSQL.Tests.dproj` project, was supplied with this review and is **real RAD Studio Method Toxicity evidence for the test suite**. It contains 317 logical method records across all 16 `.pas` test units registered in the project.

Maximum values observed in the current CSV:

| Metric | Measured maximum | Limit | Status |
|---|---:|---:|---|
| `Length` | `18` | `20` | pass |
| `Parameters` | `4` | `6` | pass |
| `If Depth` | `1` | `5` | pass |
| `Cyclomatic Complexity` | `5` | `6` | pass |
| `Toxicity` | `0.517` | `1` | pass |

No test-suite record exceeds `20 / 6 / 5 / 6 / 1`, and the thresholds were not changed.

The supplied measurement covers **only the `tests/` files**: every filename recorded in the CSV belongs to one of the 16 test units. It must not be presented as a current measurement of `src/`. Because production files were not changed by this consolidation, the absence of a current production CSV does not introduce a new violation, but current composite `Toxicity` for `src/` remains **not confirmed by a current measurement**.

## Historical record

Earlier measurements named `RiCKSQL.csv` or `RickSQL.NewTests.csv` belong to the pre-consolidation historical state and are not renamed retroactively. For the current state, the real measurement used is `RickSQL.Tests.csv`, corresponding to `tests/RickSQL.Tests.dproj`.

## RAD Studio procedure

Open the target project, run **Project > Method Toxicity Metrics**, keep `Length=20`, `Parameters=6`, `If Depth=5`, `Cyclomatic Complexity=6`, and `Toxicity=1`, export the unedited CSV, record target/configuration/defines, separate production from tests, and reject any newly introduced violation or worsening caused by the change.

## Legacy code

A violation in untouched legacy code is technical debt, not permission to raise a threshold. If such a method must be modified, the change must not worsen its metrics; refactoring outside scope requires separate authorization.
