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
    ├── ClientLibrary/
    │   └── Rick.SQL.Tests.ClientLibrary.VendorLibrary.pas
    ├── Driver/
    │   └── Rick.SQL.Tests.Driver.ProviderReuse.pas
    ├── Error/
    │   ├── Rick.SQL.Tests.Error.Integration.pas
    │   └── Rick.SQL.Tests.Error.Normalizer.pas
    ├── Infrastructure/
    │   └── Rick.SQL.Tests.FireDAC.WaitProvider.pas
    ├── Facade/
    │   └── Rick.SQL.Tests.Fluent.Lifecycle.pas
    ├── Transaction/
    │   └── Rick.SQL.Tests.Transaction.pas
    └── Validation/
        └── Rick.SQL.Tests.Parameter.Validator.pas
```

The `RickSQL.NewTests` project consumes the production implementation under `../src` and does not structurally depend on `tests/`.

The current source suite registers **152 DUnit tests across eight classes**, including `TRickSQLFluentLifecycleTests` under `NewTests/src/Facade/`. The latest supplied DUnit GUI Test Runner evidence, dated **2026-09-19**, executed **152/152**, with **0 failures**, **0 errors**, and **0 overrides**, matching the current source count. The previous **135/135** Delphi 12 Community Edition/Windows 32-bit build-and-run evidence is retained as historical validation and is not used as proof of the current build configuration. Details and evidence boundaries are documented in [Tests and validation](TESTES_E_HOMOLOGACAO.md).

Detailed documentation for the legacy suite remains separated by purpose:

- [Compilation tests](TESTES_DE_COMPILACAO.md)
- [Unit tests](TESTES_UNITARIOS.md)
- [Integration tests](TESTES_DE_INTEGRACAO.md)
- [Environment setup](CONFIGURACAO_AMBIENTE.md)
- [Memory tests](TESTES_DE_MEMORIA.md)
- [Concurrency tests](TESTES_DE_CONCORRENCIA.md)

Recorded results for `NewTests/` must not be automatically extrapolated to the legacy suite or to scenarios that were not executed.
