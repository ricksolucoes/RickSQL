# Configuração do ambiente de testes

> [Voltar ao índice de testes](README.pt-BR.md)

## Projeto oficial

Abra `tests/RickSQL.Tests.dproj`. O arquivo referencia `RickSQL.Tests.dpr` como `MainSource`, usa `Debug`/`Win32` como defaults e define `RICK_VCL_CONNECTION`.

Fluxo recomendado para validação completa:

1. remover outputs antigos de `Win32\Debug` quando houver dúvida sobre artefato stale;
2. executar **Build** do projeto;
3. abrir/executar o DUnit GUI Test Runner;
4. executar todos os testes registrados;
5. verificar failures/errors na GUI;
6. fechar a GUI para permitir a segunda execução XML;
7. conferir `dunitx-results.xml`;
8. usar `/noxml` apenas quando a segunda execução não for desejada durante diagnóstico local.

A suíte precisa ser idempotente porque o fluxo normal executa os testes duas vezes.

## SQLite

Os cenários self-contained criam arquivos temporários e removem banco, journal, WAL e SHM quando aplicável. Não é necessário servidor SQLite. A suíte inclui diretamente as units do driver SQLite do FireDAC.

## Firebird

O teste externo só executa CRUD quando `RICKSQL_FIREBIRD_DATABASE` não está vazio. Variáveis lidas:

```text
RICKSQL_FIREBIRD_SERVER
RICKSQL_FIREBIRD_DATABASE
RICKSQL_FIREBIRD_USERNAME
RICKSQL_FIREBIRD_PASSWORD
RICKSQL_FIREBIRD_CLIENT_LIBRARY
```

## PostgreSQL

Os testes externos usam:

```text
RICKSQL_POSTGRESQL_SERVER
RICKSQL_POSTGRESQL_DATABASE
RICKSQL_POSTGRESQL_USERNAME
RICKSQL_POSTGRESQL_PASSWORD
RICKSQL_POSTGRESQL_CLIENT_LIBRARY
```

O cenário de concorrência entre SQLite e PostgreSQL também aceita a porta e aliases legados:

```text
RICKSQL_POSTGRESQL_PORT
RICKSQL_PG_SERVER
RICKSQL_PG_PORT
RICKSQL_PG_DATABASE
RICKSQL_PG_USER
RICKSQL_PG_PASSWORD
```

Se nenhuma variável de banco PostgreSQL estiver configurada, o cenário condicional retorna sem acessar servidor.

## `FULL_EDITION`

No branch validado, `FULL_EDITION` não está definido. Quando definido, a classe de integração acrescenta:

### SQL Server

```text
RICKSQL_SQLSERVER_SERVER
RICKSQL_SQLSERVER_DATABASE
RICKSQL_SQLSERVER_USERNAME
RICKSQL_SQLSERVER_PASSWORD
```

### ODBC

```text
RICKSQL_ODBC_DATASOURCE
RICKSQL_ODBC_USERNAME
RICKSQL_ODBC_PASSWORD
RICKSQL_ODBC_SELECT_SQL   # opcional; default do teste: select 1 as codigo
```

Execução real do branch `FULL_EDITION`: **Não confirmado.**

## Interpretação dos resultados

Um método DUnit condicional pode aparecer como `PASS` mesmo quando retornou por falta de configuração. Antes de declarar uma integração externa aprovada, registre também a configuração utilizada e confirme que o método realmente alcançou o servidor.
