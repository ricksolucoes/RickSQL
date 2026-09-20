# Testes e homologação

> [Voltar ao índice da documentação](../README.pt-BR.md)

## Objetivo

Centralizar a estratégia de validação dos contratos públicos e internos do `RickSQL`. A suíte oficial para novas refatorações fica em [`NewTests/`](../../NewTests/) e utiliza DUnit com GUI Test Runner. A árvore [`tests/`](../../tests/) permanece como suíte legada de projetos console Delphi (`.dpr`) e material auxiliar. A existência de qualquer teste não constitui evidência de execução.

## Organização

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

tests/                  # legado
├── compilacao/
├── unitarios/
├── integracao/
├── memoria/
└── concorrencia/
```

O projeto em `NewTests/` consome diretamente a implementação de produção em `../src`, enquanto suas próprias units de teste ficam organizadas em `NewTests/src/`. Ele não reutiliza helpers existentes somente em `tests/`. Novas refatorações e correções comportamentais devem adicionar sua cobertura nessa suíte oficial.

A documentação detalhada da suíte legada está separada por finalidade:

- [Testes de compilação](TESTES_DE_COMPILACAO.pt-BR.md)
- [Testes unitários](TESTES_UNITARIOS.pt-BR.md)
- [Testes de integração](TESTES_DE_INTEGRACAO.pt-BR.md)
- [Configuração do ambiente](CONFIGURACAO_AMBIENTE.pt-BR.md)
- [Testes de memória](TESTES_DE_MEMORIA.pt-BR.md)
- [Testes de concorrência](TESTES_DE_CONCORRENCIA.pt-BR.md)

## Nova suíte oficial

O projeto `NewTests/RickSQL.NewTests.dpr` é o ponto de entrada DUnit com GUI Test Runner. As units registradas em `NewTests/src/Error/` cobrem a normalização compartilhada de `TRickSQLError` e a integração dos componentes alterados pela refatoração de exceptions. A unit `NewTests/src/Infrastructure/Rick.SQL.Tests.FireDAC.WaitProvider.pas` valida o provider VCL de `IFDGUIxWaitCursor` registrado pelo resolver. A unit `NewTests/src/Validation/Rick.SQL.Tests.Parameter.Validator.pas` cobre a identificação e a validação de parâmetros SQL sem depender de conexão ou banco externo. A unit `NewTests/src/Transaction/Rick.SQL.Tests.Transaction.pas` cobre estado transacional, `Start`, `Commit`, `Rollback`, `RollbackAfterFailure`, compatibilidade de `Active` e `UseTransaction=False` usando SQLite local. A unit `NewTests/src/ClientLibrary/Rick.SQL.Tests.ClientLibrary.VendorLibrary.pas` cobre a autoridade canônica de aplicação de `VendorLib`, o caminho compatível `Configure`, o fluxo por `Driver.Context`/`Driver.Context.Factory`, path vazio, ausência da propriedade, falha de setter, equivalência observável e preservação de default de provider. A unit `NewTests/src/Driver/Rick.SQL.Tests.Driver.ProviderReuse.pas` cobre consistência entre provider/definition, overloads de compatibilidade, propagação do provider resolvido durante a validação, reutilização pelo `ClientLibraryResolver` e pela `Driver.Context.Factory`, isolamento entre operações e os caminhos `Execute`/`Open` com SQLite.

A suíte atual registra sete classes de teste:

- `TRickSQLErrorNormalizerTests` — 6 testes para exception genérica, sanitização, contrato do parser, metadata FireDAC determinística e preservação do código realmente fornecido pelo SQLite/FireDAC;
- `TRickSQLErrorIntegrationTests` — 8 testes de integração cobrindo Driver Context, Connection, Query, Session, Parameter Binder, Transaction, DataSet Materializer e Client Library Resolver;
- `TRickSQLFireDACWaitProviderTests` — 1 teste de infraestrutura que confirma o provider `Forms` e a criação de `IFDGUIxWaitCursor` no runner VCL;
- `TRickSQLParameterValidatorTests` — 70 testes DUnit de comportamento cobrindo parâmetros simples/múltiplos/repetidos, case-insensitive, parâmetros extras, strings, comentários, falsos positivos/falsos negativos e construções lexicais específicas dos engines representados pelo framework. Os testes informam explicitamente o engine quando a interpretação depende do dialeto e permanecem offline/determinísticos.
- `TRickSQLTransactionTests` — 24 testes DUnit cobrindo estado ativo/inativo, falha determinística de inspeção de `InTransaction`, `Start`, `Commit`, `Rollback`, preservação do erro primário em `RollbackAfterFailure`, contrato compatível de `Active` e execução com `UseTransaction=False`.
- `TRickSQLVendorLibraryTests` — 15 testes DUnit cobrindo aplicação canônica de `VendorLib`, path vazio, DriverLink sem `VendorLib`, falha de setter, `ClientLibraryResolver.Configure`, `Driver.Context`, `Driver.Context.Factory`, preservação das classificações `ClientLibrary` e `Driver`, equivalência entre os caminhos e default do provider InterBase;
- `TRickSQLDriverProviderReuseTests` — 11 testes DUnit cobrindo correspondência entre provider/definition, overloads de compatibilidade, reutilização do provider devolvido pela validação, resolução da client library e criação do Driver Context com provider já disponível, isolamento entre operações independentes e os caminhos `Execute`/`Open` com SQLite.

### Execução real registrada — 19/09/2026

A versão atual da suíte oficial foi executada com **DUnit + GUI Test Runner**. A evidência fornecida registra **Delphi 12 Community Edition** e alvo **Windows 32-bit** para `RickSQL.NewTests.dproj`. O runner exibiu:

```text
Tests:      135
Run:        135
Failures:     0
Errors:       0
Overrides:    0
Score:      100%
```

A árvore do runner mostra `TRickSQLDriverProviderReuseTests` registrada junto às demais classes e todos os testes exibidos estão aprovados. O total de 135 coincide com os métodos `published` do código atual: 6 de `TRickSQLErrorNormalizerTests`, 8 de `TRickSQLErrorIntegrationTests`, 1 de `TRickSQLFireDACWaitProviderTests`, 70 de `TRickSQLParameterValidatorTests`, 24 de `TRickSQLTransactionTests`, 15 de `TRickSQLVendorLibraryTests` e 11 de `TRickSQLDriverProviderReuseTests`.

Essa execução valida a suíte oficial `NewTests/`; ela não constitui execução da árvore legada `tests/`, nem comprova Win64, Release ou `FULL_EDITION`.

### Evidência atual de build registrada — 19/09/2026 — `RickSQL.NewTests.dproj`

A captura fornecida do Delphi 12 Community Edition mostra `RickSQL.NewTests.dproj` como **[Built]**, com o alvo selecionado **Windows 32-bit**. Essa é a evidência atual de build associada à rodada de homologação com 135 testes. Ela não deve ser extrapolada como evidência de Win64, Release, `FULL_EDITION` ou de outro projeto.

### Build histórico registrado — `RickConnection.dproj`

Uma rodada de validação documentada anteriormente registrou o projeto principal `RickConnection.dproj` compilado no **Delphi 12 Community Edition**, configuração **Debug**, alvo **Windows 32-bit**, com a saída do IDE:

```text
Compiling RickConnection.dproj (Debug, Win32)
Success
```

Esse resultado é mantido como evidência histórica para a configuração mostrada. O `RickConnection.dproj` **não foi revalidado pela evidência atual de reutilização do provider**, portanto esse build histórico não deve ser apresentado como parte da rodada atual de `RickSQL.NewTests.dproj`.

### Histórico de homologação anterior

Em **18/09/2026**, uma versão anterior da suíte, ainda sem `TRickSQLTransactionTests`, executou 84 testes com 0 falhas e 0 erros. Depois, durante a correção transacional, houve uma execução de 108 testes com 107 aprovados, 1 falha e 0 erros; a falha em `UseTransactionFalse_NaoDeveIntroduzirErroTransacional` revelou a ausência da factory de `IFDGUIxWaitCursor`. A seleção explícita do provider Console/VCL/FMX e `TRickSQLFireDACWaitProviderTests` foram adicionadas em seguida. Uma rodada intermediária posterior, antes da inclusão de `TRickSQLDriverProviderReuseTests`, executou **124/124** testes sem falhas ou erros.

Esses resultados permanecem apenas como histórico. O estado homologado mais recente documentado é a execução de **135/135**, sem falhas ou erros, em 19/09/2026. A medição real mais recente de Method Toxicity do `RickSQL.NewTests.dproj`, também em 19/09/2026, está registrada em [Controle de toxicidade](../engenharia/CONTROLE_DE_TOXICIDADE.pt-BR.md).

## Ordem de homologação

Para cenários que dependem de banco real, a sequência documental recomendada é:

1. SQLite, por não depender de servidor externo.
2. Firebird, quando configurado.
3. PostgreSQL ou SQL Server, conforme disponibilidade.
4. ODBC e demais mecanismos disponíveis no ambiente de homologação.

A ordem acima é uma orientação operacional. Não indica que os bancos tenham sido executados no ambiente em que esta documentação foi revisada.

## Testes de compilação

A pasta `tests/compilacao` contém 18 projetos `.dpr` cobrindo models, factory, validadores, drivers, resolução de biblioteca cliente, sessão FireDAC, conexão/query, parâmetros, transação, parser de erros, materialização, executores, fachada e consumo por Library/Search Path.

Os detalhes e pré-requisitos estão em [Testes de compilação](TESTES_DE_COMPILACAO.pt-BR.md).

## Testes unitários

A pasta `tests/unitarios` contém quatro projetos isolados para models, validadores, drivers e erros. Eles não dependem de conexão com banco externo.

Há uma divergência conhecida no estado atual: `RickSQL.Unitarios.Drivers.Test.dpr` espera porta `0` para Informix, enquanto `Rick.SQL.Service.FireDAC.Driver.Informix.pas` define `DefaultPort := 9088` tanto no ramo `FULL_EDITION` quanto no fallback. Esse ponto deve ser tratado antes de usar esse teste como evidência de conformidade do provider Informix.

Veja [Testes unitários](TESTES_UNITARIOS.pt-BR.md).

## Testes de integração

Os projetos atuais cobrem SQLite, Firebird, PostgreSQL, SQL Server, ODBC e cenários de infraestrutura. SQL Server e ODBC exigem `FULL_EDITION` para que os respectivos providers usem suas implementações funcionais.

Os cenários observáveis nos arquivos atuais incluem consulta com registros, consulta vazia, valores textuais, campos nulos, BLOB, aliases/campos calculados, insert, update, delete, zero registros afetados, SQL inválido e parâmetro ausente. Os projetos externos de Firebird, PostgreSQL e SQL Server repetem o fluxo básico de criação de tabela, insert, consulta, update e delete quando o ambiente está configurado.

`RickSQL.Integracao.Infraestrutura.Test.dpr` cobre arquivo SQLite em diretório inexistente, biblioteca cliente explicitamente ausente, parâmetro SQL ausente, SQL inválido e credencial PostgreSQL inválida quando o ambiente PostgreSQL está configurado. Nos arquivos atuais não existe um cenário dedicado chamado "servidor indisponível" nem um cenário explícito de "banco não suportado".

Veja [Testes de integração](TESTES_DE_INTEGRACAO.pt-BR.md) e [Configuração do ambiente](CONFIGURACAO_AMBIENTE.pt-BR.md).

## Testes de memória

Os projetos habilitam `ReportMemoryLeaksOnShutdown` e repetem fluxos de SQLite e manipulação de arrays de parâmetros. Esse mecanismo permite que o Delphi reporte leaks observáveis ao encerramento.

Os testes atuais não instrumentam individualmente cada tipo interno para provar separadamente a liberação de driver link, contexto, conexão, query, transação ou memtable. Portanto, a ausência de relatório somente pode ser afirmada após execução real do projeto correspondente.

Veja [Testes de memória](TESTES_DE_MEMORIA.pt-BR.md).

## Testes de concorrência

Os três projetos atuais exercitam operações simultâneas em SQLite, isolamento de falha entre threads e execução simultânea entre SQLite e PostgreSQL quando o ambiente externo está configurado.

Eles validam o comportamento observável das operações, mas não instrumentam a identidade de cada objeto interno para provar individualmente que conexão, query, contexto e transação são instâncias distintas.

Veja [Testes de concorrência](TESTES_DE_CONCORRENCIA.pt-BR.md).

## Configuração no Delphi

Para os projetos de teste, configure o `Search Path` ou `Library Path` com as pastas do framework:

```text
RickSQL\src
RickSQL\src\model
RickSQL\src\error
RickSQL\src\core
RickSQL\src\services
RickSQL\src\services\drivers
```

Projetos console selecionam `FireDAC.ConsoleUI.Wait` automaticamente por `CONSOLE`. O runner VCL `NewTests` define `RICK_VCL_CONNECTION`, e projetos FMX devem definir `RICK_FMX_CONNECTION`. `RICK_VCL_CONNECTION` e `RICK_FMX_CONNECTION` são mutuamente exclusivos. Cenários que exercitam SQL Server, Oracle, DB2, SQL Anywhere, Informix ou ODBC funcionalmente devem considerar `FULL_EDITION`.

## Critérios de aceite

Como critério de homologação, e não como afirmação de execução, a entrega deve demonstrar no ambiente de teste aplicável que:

- o consumidor consegue usar a fachada pública esperada;
- os drivers são resolvidos internamente sem exigir que o consumidor informe `DriverID` ou importe units físicas de driver do FireDAC;
- `Open` retorna dataset materializado e utilizável após a liberação da sessão interna;
- `Execute` retorna `TRickSQLExecutionResult` estruturado;
- falhas cobertas pela API pública são convertidas para erros estruturados;
- a resolução da client library permanece separada da aplicação canônica de `VendorLib`, preservando path vazio e as classificações de erro dos fluxos existentes;
- os testes de memória não apresentam leaks nos cenários realmente executados;
- os cenários de concorrência executados preservam os resultados esperados;
- os projetos relevantes compilam e executam no Delphi definido para a homologação.

Resultados de compilação, execução, leak checking ou homologação devem ser registrados somente quando obtidos por execução real.
