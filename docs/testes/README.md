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
    ├── Transaction/
    │   └── Rick.SQL.Tests.Transaction.pas
    └── Validation/
        └── Rick.SQL.Tests.Parameter.Validator.pas
```

The `RickSQL.NewTests` project consumes the production implementation under `../src` and does not structurally depend on `tests/`.

The current suite registers **135 DUnit tests across seven classes**, including `TRickSQLVendorLibraryTests` under `NewTests/src/ClientLibrary/` and `TRickSQLDriverProviderReuseTests` under `NewTests/src/Driver/`. On **2026-09-19**, the supplied evidence for `RickSQL.NewTests.dproj` on **Windows 32-bit** shows the project as **[Built]** in Delphi 12 Community Edition, and the DUnit GUI Test Runner executed **135/135**, with **0 failures**, **0 errors**, **0 overrides**, and **Score 100%**. A previously recorded `RickConnection.dproj` **Debug/Win32: Success** build is retained separately as historical evidence and was not revalidated in the current provider-reuse round. Details and evidence boundaries are documented in [Tests and validation](TESTES_E_HOMOLOGACAO.md).

Detailed documentation for the legacy suite remains separated by purpose:

- [Compilation tests](TESTES_DE_COMPILACAO.md)
- [Unit tests](TESTES_UNITARIOS.md)
- [Integration tests](TESTES_DE_INTEGRACAO.md)
- [Environment setup](CONFIGURACAO_AMBIENTE.md)
- [Memory tests](TESTES_DE_MEMORIA.md)
- [Concurrency tests](TESTES_DE_CONCORRENCIA.md)

Recorded results for `NewTests/` must not be automatically extrapolated to the legacy suite or to scenarios that were not executed.
