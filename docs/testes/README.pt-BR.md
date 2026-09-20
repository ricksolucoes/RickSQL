# Documentação de testes

> [Voltar ao índice da documentação](../README.pt-BR.md)

O RickSQL mantém duas estruturas de testes com responsabilidades distintas:

- [`NewTests/`](../../NewTests/) — suíte oficial para novas refatorações e correções comportamentais, baseada em DUnit com GUI Test Runner;
- [`tests/`](../../tests/) — suíte legada, preservada como material auxiliar, contratos históricos e cenários de compilação, integração, memória e concorrência.

A suíte oficial está organizada atualmente assim:

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

O projeto `RickSQL.NewTests` consome a implementação de produção em `../src` e não depende estruturalmente de `tests/`.

A suíte atual registra **135 testes DUnit em sete classes**, incluindo `TRickSQLVendorLibraryTests` em `NewTests/src/ClientLibrary/` e `TRickSQLDriverProviderReuseTests` em `NewTests/src/Driver/`. Em **19/09/2026**, a evidência fornecida para `RickSQL.NewTests.dproj` em **Windows 32-bit** mostra o projeto como **[Built]** no Delphi 12 Community Edition, e o DUnit GUI Test Runner executou **135/135**, com **0 falhas**, **0 erros**, **0 overrides** e **Score 100%**. Um build `RickConnection.dproj` **Debug/Win32: Success** registrado anteriormente é mantido separadamente como evidência histórica e não foi revalidado na rodada atual de reutilização do provider. Os detalhes e os limites dessas evidências estão em [Testes e homologação](TESTES_E_HOMOLOGACAO.pt-BR.md).

A documentação detalhada da suíte legada permanece separada por finalidade:

- [Testes de compilação](TESTES_DE_COMPILACAO.pt-BR.md)
- [Testes unitários](TESTES_UNITARIOS.pt-BR.md)
- [Testes de integração](TESTES_DE_INTEGRACAO.pt-BR.md)
- [Configuração do ambiente](CONFIGURACAO_AMBIENTE.pt-BR.md)
- [Testes de memória](TESTES_DE_MEMORIA.pt-BR.md)
- [Testes de concorrência](TESTES_DE_CONCORRENCIA.pt-BR.md)

Resultados registrados para `NewTests/` não devem ser extrapolados automaticamente para a suíte legada ou para cenários que não foram executados.
