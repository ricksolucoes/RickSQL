# Suíte oficial de testes

> [Voltar ao índice](../README.pt-BR.md)

`tests/` é a única infraestrutura oficial de testes do RickSQL. A antiga suíte legada foi removida depois da aprovação do Quality Gate pré-migração, e a antiga pasta de transição `NewTests/` foi renomeada para `tests/`.

## Projeto

```text
tests/
├── RickSQL.Tests.dproj       # arquivo de projeto Delphi
├── RickSQL.Tests.dpr         # MainSource
├── RickSQL.Tests.res
└── src/
    ├── ClientLibrary/
    ├── Concurrency/
    ├── Driver/
    ├── Error/
    ├── Facade/
    ├── Infrastructure/
    ├── Integration/
    ├── Materialization/
    ├── Model/
    ├── Service/
    ├── Transaction/
    └── Validation/
```

O projeto de testes está integralmente consolidado como `RickSQL.Tests.dproj`, com `MainSource=RickSQL.Tests.dpr`; o executável gerado é `RickSQL.Tests.exe`.

## Runner

O projeto usa DUnit clássico com `GUITestRunner`. Depois que a janela GUI é fechada, `XMLTestRunner.RunRegisteredTests` executa a suíte novamente e grava `dunitx-results.xml` ao lado do executável. O switch `/noxml` desativa somente essa segunda execução.

Consequência operacional: cada teste deve ser self-contained, idempotente e capaz de executar duas vezes seguidas sem depender de ordem ou resíduos da execução anterior.

## Resultado pós-migração

A evidência local fornecida em 20/09/2026 14:21:27 registra:

- 217 testes executados;
- 217 passes;
- 0 failures;
- 0 errors;
- 100% de sucesso;
- execução no path final `tests/`;
- branch sem `FULL_EDITION`.

O resultado inclui os dois cenários determinísticos que substituíram o antigo teste SQLite reader/writer flakey: `Concurrent_SameSQLiteReaders_RepeatedOperationsComplete` e `Concurrent_SQLiteWriteContention_ReturnsBusyAndRecovers`.

## O que o resultado não comprova

Os testes de Firebird e PostgreSQL retornam imediatamente quando as variáveis de ambiente mínimas não estão configuradas. Assim, um `PASS` nesses métodos não prova que um servidor externo foi acessado. SQL Server e ODBC são compilados na classe de integração apenas sob `FULL_EDITION`. Execução real dessas integrações externas: **Não confirmado.**

Também não é declarado percentual de cobertura de linhas nem ausência de memory leaks. A cobertura é orientada a responsabilidade; lifecycle é validado funcionalmente, enquanto medição de leak exige ferramenta específica. O resultado 217/217 corresponde ao branch `RICK_VCL_CONNECTION` sem `FULL_EDITION`; branches `FULL_EDITION`, `CONSOLE` e `RICK_FMX_CONNECTION` não são considerados executados por essa evidência.

## Documentos relacionados

- [Testes e homologação](TESTES_E_HOMOLOGACAO.pt-BR.md)
- [Matriz de cobertura](MATRIZ_DE_COBERTURA.pt-BR.md)
- [Testes unitários/contratuais](TESTES_UNITARIOS.pt-BR.md)
- [Integração](TESTES_DE_INTEGRACAO.pt-BR.md)
- [Concorrência](TESTES_DE_CONCORRENCIA.pt-BR.md)
- [Lifecycle e memória](TESTES_DE_MEMORIA.pt-BR.md)
- [Contratos de compilação](TESTES_DE_COMPILACAO.pt-BR.md)
- [Configuração de ambiente](CONFIGURACAO_AMBIENTE.pt-BR.md)
