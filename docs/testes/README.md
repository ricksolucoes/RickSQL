# Test Documentation

> [Back to the documentation index](../README.md)

RickSQL maintains two test structures with distinct responsibilities:

- [`NewTests/`](../../NewTests/) — the official suite for new refactorings and behavioral fixes, based on DUnit with the GUI Test Runner;
- [`tests/`](../../tests/) — the legacy suite, preserved as reference material, historical contracts, and compilation, integration, memory, and concurrency scenarios.

The official suite is currently organized as follows:

```text
NewTests/
├── RickSQL.NewTests.dpr
├── RickSQL.NewTests.dproj
└── src/
    ├── Error/
    │   ├── Rick.SQL.Tests.Error.Integration.pas
    │   └── Rick.SQL.Tests.Error.Normalizer.pas
    └── Validation/
        └── Rick.SQL.Tests.Parameter.Validator.pas
```

The `RickSQL.NewTests` project consumes the production implementation under `../src` and does not structurally depend on `tests/`.

The recorded execution on Delphi 12 Community Edition, targeting Windows 32-bit, ran **84 of 84 tests** with **0 failures** and **0 errors**. The suite includes 70 `TRickSQLParameterValidatorTests` tests in addition to the 14 existing error-normalization/integration tests. Execution details, coverage, and the scope of this evidence are documented in [Tests and validation](TESTES_E_HOMOLOGACAO.md).

Detailed documentation for the legacy suite remains separated by purpose:

- [Compilation tests](TESTES_DE_COMPILACAO.md)
- [Unit tests](TESTES_UNITARIOS.md)
- [Integration tests](TESTES_DE_INTEGRACAO.md)
- [Environment setup](CONFIGURACAO_AMBIENTE.md)
- [Memory tests](TESTES_DE_MEMORIA.md)
- [Concurrency tests](TESTES_DE_CONCORRENCIA.md)

Recorded results for `NewTests/` must not be automatically extrapolated to the legacy suite or to scenarios that were not executed.
