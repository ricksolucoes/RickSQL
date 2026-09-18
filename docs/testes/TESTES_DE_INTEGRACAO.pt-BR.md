# Testes de integração do RickSQL

> [Voltar ao índice da documentação](../README.pt-BR.md)

Os projetos executáveis estão em [`tests/integracao`](../../tests/integracao/). Eles exercitam a fachada `Rick.SQL` junto com executores, providers, conexão, query, parâmetros, transações, materialização de `TDataSet` e tratamento de falhas.

## Testes disponíveis

| Arquivo | Banco/cenário | Dependência externa |
|---|---|---|
| [`RickSQL.Integracao.SQLite.Test.dpr`](../../tests/integracao/RickSQL.Integracao.SQLite.Test.dpr) | SQLite | não depende de servidor externo |
| [`RickSQL.Integracao.Firebird.Test.dpr`](../../tests/integracao/RickSQL.Integracao.Firebird.Test.dpr) | Firebird | banco Firebird configurado |
| [`RickSQL.Integracao.PostgreSQL.Test.dpr`](../../tests/integracao/RickSQL.Integracao.PostgreSQL.Test.dpr) | PostgreSQL | banco PostgreSQL configurado |
| [`RickSQL.Integracao.SQLServer.Test.dpr`](../../tests/integracao/RickSQL.Integracao.SQLServer.Test.dpr) | SQL Server | banco SQL Server configurado + `FULL_EDITION` |
| [`RickSQL.Integracao.ODBC.Test.dpr`](../../tests/integracao/RickSQL.Integracao.ODBC.Test.dpr) | ODBC | fonte ODBC configurada + `FULL_EDITION` |
| [`RickSQL.Integracao.Infraestrutura.Test.dpr`](../../tests/integracao/RickSQL.Integracao.Infraestrutura.Test.dpr) | falhas de infraestrutura | parte dos cenários é local; credencial PostgreSQL depende do ambiente |

## Ordem recomendada

1. SQLite.
2. Infraestrutura.
3. Firebird, quando configurado.
4. PostgreSQL ou SQL Server, conforme disponibilidade.
5. ODBC, quando configurado.

Essa sequência é operacional; não representa histórico de execução.

## Configuração

Os testes de bancos externos leem variáveis de ambiente. Quando a configuração necessária não existe, os projetos correspondentes possuem caminhos que informam o cenário no console em vez de assumir uma infraestrutura presente.

SQL Server e ODBC exigem `FULL_EDITION` como *Conditional Define* para a implementação funcional dos respectivos providers.

Veja [Configuração do ambiente](CONFIGURACAO_AMBIENTE.pt-BR.md) para as variáveis e permissões usadas pelos projetos atuais.

## Cobertura observável nos arquivos

Os cenários presentes atualmente incluem consulta com registros, consulta vazia, dados textuais, nulos, BLOB, aliases/campos calculados, insert, update, delete, zero registros afetados, SQL inválido e parâmetro ausente.

O projeto de infraestrutura cobre arquivo SQLite em diretório inexistente, biblioteca cliente explicitamente ausente, parâmetro SQL ausente, SQL inválido e credencial PostgreSQL inválida quando PostgreSQL está configurado. Não existe, nos arquivos atuais, um teste dedicado identificado como "servidor indisponível" ou "banco não suportado".

## Resultado

A existência desses cenários não comprova que passaram. O resultado deve ser registrado somente após execução real no ambiente configurado.
