# Compilation contracts

> [Back to the test index](README.md)

The final suite no longer keeps standalone projects under `tests/compilacao`. Their valid contracts were migrated or replaced by the single DUnit suite under `tests/`.

Building `tests/RickSQL.Tests.dproj` requires the compiler to resolve both public APIs, models, validators/executors, driver factory/providers/context, FireDAC services, error parser/normalizer, materialization, active conditional branches, and all 16 registered test units.

Current project facts: `RickSQL.Tests.dproj`, `MainSource=RickSQL.Tests.dpr`, default `Debug`, default `Win32`, `RICK_VCL_CONNECTION` defined, and no `FULL_EDITION` in the validated branch. `ProjectVersion=20.3`; the exact commercial Delphi release is **Not confirmed**.

The post-migration executable registered and ran 217 tests from the final path with zero failures/errors. A full textual compiler log is not stored in the repository, so no unobserved warning/hint result is claimed.
