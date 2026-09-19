# Configuração de ambiente para os testes de integração

> [Voltar ao índice da documentação](../README.pt-BR.md)

Os projetos executáveis ficam em [`tests/integracao`](../../tests/integracao/). A documentação original dessa configuração foi centralizada aqui; as variáveis abaixo correspondem aos nomes utilizados pelos projetos atuais.

## Library Path mínimo

```text
RickSQL\src
RickSQL\src\model
RickSQL\src\error
RickSQL\src\core
RickSQL\src\services
RickSQL\src\services\drivers
RickSQL\tests\integracao
```

Como os projetos legados desta seção são aplicações console, `Rick.SQL.Core.ClientLibrary.Resolver` seleciona `FireDAC.ConsoleUI.Wait` automaticamente por meio de `CONSOLE`; não é necessário define específico do RickSQL para esse provider.

## SQLite

O teste SQLite não exige servidor externo. Ele cria um arquivo temporário no diretório temporário do Windows.

## Firebird

Variáveis utilizadas:

```text
RICKSQL_FIREBIRD_SERVER
RICKSQL_FIREBIRD_DATABASE
RICKSQL_FIREBIRD_USERNAME
RICKSQL_FIREBIRD_PASSWORD
RICKSQL_FIREBIRD_CLIENT_LIBRARY
```

`RICKSQL_FIREBIRD_CLIENT_LIBRARY` é opcional quando a biblioteca cliente já estiver disponível no ambiente.

## PostgreSQL

Variáveis utilizadas:

```text
RICKSQL_POSTGRESQL_SERVER
RICKSQL_POSTGRESQL_DATABASE
RICKSQL_POSTGRESQL_USERNAME
RICKSQL_POSTGRESQL_PASSWORD
RICKSQL_POSTGRESQL_CLIENT_LIBRARY
```

`RICKSQL_POSTGRESQL_CLIENT_LIBRARY` é opcional quando a biblioteca cliente já estiver disponível no ambiente.

## SQL Server

Além das variáveis abaixo, o projeto deve ser compilado com `FULL_EDITION` nos *Conditional Defines*.

```text
RICKSQL_SQLSERVER_SERVER
RICKSQL_SQLSERVER_DATABASE
RICKSQL_SQLSERVER_USERNAME
RICKSQL_SQLSERVER_PASSWORD
```

## ODBC

Além das variáveis abaixo, o projeto deve ser compilado com `FULL_EDITION` nos *Conditional Defines*.

```text
RICKSQL_ODBC_DATASOURCE
RICKSQL_ODBC_USERNAME
RICKSQL_ODBC_PASSWORD
RICKSQL_ODBC_SELECT_SQL
```

`RICKSQL_ODBC_SELECT_SQL` é opcional. Quando não informado, o teste usa `select 1 as codigo`.

## Permissões necessárias

Os testes externos criam e removem a tabela `ricksql_integracao`. Use banco de homologação ou base temporária apropriada ao ambiente.

A configuração de credenciais e infraestrutura deve permanecer fora do repositório.
