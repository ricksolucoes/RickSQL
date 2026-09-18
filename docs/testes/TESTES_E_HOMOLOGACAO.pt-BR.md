# Testes e homologação

> [Voltar ao índice da documentação](../README.pt-BR.md)

## Objetivo

Centralizar a estratégia de validação dos contratos públicos e internos do `RickSQL`. Os projetos executáveis permanecem em [`tests/`](../../tests/) e são projetos console Delphi (`.dpr`); esta documentação descreve o que existe nos arquivos atuais, sem transformar a existência do teste em evidência de execução.

## Organização

```text
tests/
  compilacao/
  unitarios/
  integracao/
  memoria/
  concorrencia/
```

A documentação detalhada está separada por finalidade:

- [Testes de compilação](TESTES_DE_COMPILACAO.pt-BR.md)
- [Testes unitários](TESTES_UNITARIOS.pt-BR.md)
- [Testes de integração](TESTES_DE_INTEGRACAO.pt-BR.md)
- [Configuração do ambiente](CONFIGURACAO_AMBIENTE.pt-BR.md)
- [Testes de memória](TESTES_DE_MEMORIA.pt-BR.md)
- [Testes de concorrência](TESTES_DE_CONCORRENCIA.pt-BR.md)

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
RickSQL\src\core
RickSQL\src\services
RickSQL\src\services\drivers
```

Projetos console que compilam o caminho de `Rick.SQL.Core.ClientLibrary.Resolver` devem definir `CONSOLE_CONNECTION` no nível do projeto. Cenários que exercitam SQL Server, Oracle, DB2, SQL Anywhere, Informix ou ODBC funcionalmente devem considerar `FULL_EDITION`.

## Critérios de aceite

Como critério de homologação, e não como afirmação de execução, a entrega deve demonstrar no ambiente de teste aplicável que:

- o consumidor consegue usar a fachada pública esperada;
- os drivers são resolvidos internamente sem exigir que o consumidor informe `DriverID` ou importe units físicas de driver do FireDAC;
- `Open` retorna dataset materializado e utilizável após a liberação da sessão interna;
- `Execute` retorna `TRickSQLExecutionResult` estruturado;
- falhas cobertas pela API pública são convertidas para erros estruturados;
- os testes de memória não apresentam leaks nos cenários realmente executados;
- os cenários de concorrência executados preservam os resultados esperados;
- os projetos relevantes compilam e executam no Delphi definido para a homologação.

Resultados de compilação, execução, leak checking ou homologação devem ser registrados somente quando obtidos por execução real.
