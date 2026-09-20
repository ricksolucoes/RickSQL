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

O projeto `RickSQL.NewTests` consome a implementação de produção em `../src` e não depende estruturalmente de `tests/`.

A suíte fonte atual registra **163 testes DUnit em dez classes** em cada configuração de compilação. `TRickSQLDriverContractTests` acrescenta cinco testes ativos por configuração para distinguir `Unknown` dos 13 engines suportados e validar `Informix` conforme o branch de `FULL_EDITION`. A evidência mais recente fornecida do DUnit GUI Test Runner, finalizada em **20/09/2026 11:14:06**, registra **163 testes**, todos `PASS`, com **0 falhas**, **0 erros** e **100% de sucesso**. A execução inclui os cinco testes de contratos de driver. Os nomes dos testes de Informix executados correspondem às variantes fallback, portanto essa evidência cobre a configuração **sem `FULL_EDITION`**; o branch `FULL_EDITION` permanece sem evidência de execução atual. Os detalhes e os limites estão em [Testes e homologação](TESTES_E_HOMOLOGACAO.pt-BR.md).

A documentação detalhada da suíte legada permanece separada por finalidade:

- [Testes de compilação](TESTES_DE_COMPILACAO.pt-BR.md)
- [Testes unitários](TESTES_UNITARIOS.pt-BR.md)
- [Testes de integração](TESTES_DE_INTEGRACAO.pt-BR.md)
- [Configuração do ambiente](CONFIGURACAO_AMBIENTE.pt-BR.md)
- [Testes de memória](TESTES_DE_MEMORIA.pt-BR.md)
- [Testes de concorrência](TESTES_DE_CONCORRENCIA.pt-BR.md)

Resultados registrados para `NewTests/` não devem ser extrapolados automaticamente para a suíte legada ou para cenários que não foram executados.
