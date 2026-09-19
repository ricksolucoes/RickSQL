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
    ├── Infrastructure/
    │   └── Rick.SQL.Tests.FireDAC.WaitProvider.pas
    ├── Transaction/
    │   └── Rick.SQL.Tests.Transaction.pas
    └── Validation/
        └── Rick.SQL.Tests.Parameter.Validator.pas
```

The `RickSQL.NewTests` project consumes the production implementation under `../src` and does not structurally depend on `tests/`.

The most recent execution reported before explicit FireDAC provider selection ran **108 tests**, with **107 passed**, **1 failure**, and **0 errors**. The failure occurred in `UseTransactionFalse_NaoDeveIntroduzirErroTransacional` because the `IFDGUIxWaitCursor` factory was not registered. Static inspection of the current suite finds **109 DUnit `published` methods across five classes** after adding `TRickSQLFireDACWaitProviderTests`; full execution of this 109-test version has not yet been confirmed. Details and evidence boundaries are documented in [Tests and validation](TESTES_E_HOMOLOGACAO.md).

Detailed documentation for the legacy suite remains separated by purpose:

- [Compilation tests](TESTES_DE_COMPILACAO.md)
- [Unit tests](TESTES_UNITARIOS.md)
- [Integration tests](TESTES_DE_INTEGRACAO.md)
- [Environment setup](CONFIGURACAO_AMBIENTE.md)
- [Memory tests](TESTES_DE_MEMORIA.md)
- [Concurrency tests](TESTES_DE_CONCORRENCIA.md)

Recorded results for `NewTests/` must not be automatically extrapolated to the legacy suite or to scenarios that were not executed.
