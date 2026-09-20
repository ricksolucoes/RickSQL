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
    │   ├── Rick.SQL.Tests.Driver.Contracts.pas
    │   └── Rick.SQL.Tests.Driver.ProviderReuse.pas
    ├── Error/
    │   ├── Rick.SQL.Tests.Error.Integration.pas
    │   └── Rick.SQL.Tests.Error.Normalizer.pas
    ├── Infrastructure/
    │   └── Rick.SQL.Tests.FireDAC.WaitProvider.pas
    ├── Facade/
    │   └── Rick.SQL.Tests.Fluent.Lifecycle.pas
    ├── Materialization/
    │   └── Rick.SQL.Tests.DataSet.Materializer.pas
    ├── Transaction/
    │   └── Rick.SQL.Tests.Transaction.pas
    └── Validation/
        └── Rick.SQL.Tests.Parameter.Validator.pas
```

The `RickSQL.NewTests` project consumes the production implementation under `../src` and does not structurally depend on `tests/`.

The current source suite registers **163 DUnit tests across ten classes** in each compilation configuration. `TRickSQLDriverContractTests` adds five active tests per configuration to distinguish `Unknown` from the 13 supported engines and validate Informix for the applicable `FULL_EDITION` branch. The latest supplied DUnit GUI Test Runner evidence, finished at **2026-09-20 11:14:06**, records **163 tests**, all `PASS`, with **0 failures**, **0 errors**, and a **100% success rate**. The execution includes the five driver-contract tests. Its Informix test names are the fallback variants, so this evidence covers the configuration **without `FULL_EDITION`**; the `FULL_EDITION` branch remains without current execution evidence. Details and evidence boundaries are documented in [Tests and validation](TESTES_E_HOMOLOGACAO.md).

Detailed documentation for the legacy suite remains separated by purpose:

- [Compilation tests](TESTES_DE_COMPILACAO.md)
- [Unit tests](TESTES_UNITARIOS.md)
- [Integration tests](TESTES_DE_INTEGRACAO.md)
- [Environment setup](CONFIGURACAO_AMBIENTE.md)
- [Memory tests](TESTES_DE_MEMORIA.md)
- [Concurrency tests](TESTES_DE_CONCORRENCIA.md)

Recorded results for `NewTests/` must not be automatically extrapolated to the legacy suite or to scenarios that were not executed.
