# Testes de concorrência do RickSQL

> [Voltar ao índice da documentação](../README.pt-BR.md)

Os projetos executáveis ficam em [`tests/concorrencia`](../../tests/concorrencia/) e exercitam operações simultâneas do RickSQL.

## Objetivo

Validar o comportamento observável quando operações são executadas em paralelo: resultado das consultas/comandos, isolamento de uma falha e execução com bancos distintos quando o ambiente externo está disponível.

Os testes atuais não instrumentam a identidade de conexão, query, contexto de driver ou transação para provar individualmente que cada objeto interno é distinto; essa conclusão não deve ser inferida apenas da execução concorrente.

## Testes disponíveis

### [`RickSQL.Concorrencia.SQLite.Test.dpr`](../../tests/concorrencia/RickSQL.Concorrencia.SQLite.Test.dpr)

Executa consultas e comandos simultâneos sobre um banco SQLite temporário.

### [`RickSQL.Concorrencia.FalhaIsolada.Test.dpr`](../../tests/concorrencia/RickSQL.Concorrencia.FalhaIsolada.Test.dpr)

Executa uma consulta válida e uma consulta inválida em paralelo, verificando o comportamento observável de isolamento entre os dois fluxos.

### [`RickSQL.Concorrencia.BancosDiferentes.Test.dpr`](../../tests/concorrencia/RickSQL.Concorrencia.BancosDiferentes.Test.dpr)

Executa operações simultâneas em SQLite e PostgreSQL.

Variáveis utilizadas pelo projeto:

```text
RICKSQL_PG_SERVER
RICKSQL_PG_PORT
RICKSQL_PG_DATABASE
RICKSQL_PG_USER
RICKSQL_PG_PASSWORD
```

Se `RICKSQL_PG_DATABASE` não estiver configurada, o próprio teste possui caminho de saída com mensagem no console.

## Resultado

A documentação descreve os cenários presentes. Sucesso, falha ou garantias de thread safety dependem de execução e análise reais no ambiente alvo.
