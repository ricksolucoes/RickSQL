# Arquitetura confirmada do RickSQL

> [Voltar ao índice](../README.pt-BR.md)

Este documento descreve somente a arquitetura observada no código atual. Ele não classifica o projeto como Clean Architecture, Hexagonal, MVC ou outro estilo que não esteja explicitamente materializado.

## Visão geral

```text
Rick.SQL (API record-based)       Rick.SQL.Interf (API fluent)
              \                    /
               +--------+---------+
                        v
              Core Executors/Validators
          +-------------+-------------+
          |                           |
          v                           v
 Command.Executor                Open.Executor
          |                           |
          +-------------+-------------+
                        v
              Driver.Context.Factory
                        |
                        v
             Driver.Factory -> Provider
                        |
                        v
                  Driver.Context
                        |
                        v
             FireDAC Session (owner)
              | Connection | Query |
              +------+-------+-----+
                     |       |
                     v       v
               Parameter   Transaction
                 Binder    (`Execute`)
                     |       |
                     +---+---+
                         v
                    FireDAC/DBMS
                         |
                         v
             DataSet.Materializer (`Open`)

Erros: Core/Services -> Error.Parser / Error.Normalizer -> TRickSQLError
Client library: DriverDefinition -> ClientLibrary.Resolver -> VendorLibrary -> DriverLink.VendorLib
```

## Boundaries e responsabilidades

- `Rick.SQL` expõe a fachada record-based `TRickSQL`: criação das opções, comando, `Open` e `Execute`.
- `Rick.SQL.Interf` implementa a API fluent e mantém estado próprio de conexão, comando, parâmetros, opções, resultado e dataset.
- `core` concentra validação, resolução de provider/contexto, executores, parser de erros e materialização.
- `services` encapsula as operações FireDAC concretas: sessão, conexão, query, binder e transação.
- `services/drivers` contém providers por engine, contexto do driver, classe base e aplicação de `VendorLib`.
- `model` contém records, enums e contratos compartilhados.
- `error` contém a normalização técnica compartilhada por core e services.

## Fluxo de `TRickSQL.Execute`

```text
TRickSQL.Execute
 -> TRickSQLCoreCommandExecutor.Execute
 -> CommandValidator.Validate
    -> ConnectionValidator
    -> ParameterValidator
 -> DriverContextFactory.Create
    -> Driver.Factory.Resolve
    -> ClientLibrary.Resolver / Driver.Context
 -> FireDAC.Session.Create
 -> FireDAC.Connection.Configure/Open
 -> FireDAC.Query.Configure
 -> FireDAC.Parameter.Binder.Bind
 -> FireDAC.Query.Prepare
 -> FireDAC.Transaction.Start (quando UseTransaction=True)
 -> TFDQuery.ExecSQL
 -> RowsAffected
 -> FireDAC.Transaction.Commit
 -> RollbackAfterFailure em falha, quando aplicável
 -> TRickSQLExecutionResult
```

## Fluxo de `TRickSQL.Open`

```text
TRickSQL.Open
 -> TRickSQLCoreOpenExecutor.Open
 -> CommandValidator.Validate
    -> ConnectionValidator
    -> ParameterValidator
 -> DriverContextFactory.Create
 -> FireDAC.Session.Create
 -> FireDAC.Connection.Configure/Open
 -> FireDAC.Query.Configure
 -> FireDAC.Parameter.Binder.Bind
 -> FireDAC.Query.Prepare/Open
 -> DataSet.Materializer.Materialize
 -> dataset independente
 -> sessão FireDAC liberada
```

## API fluent

`TRickSQLInterf.Execute` e `TRickSQLInterf.Open` constroem `TRickSQLCommand` a partir do estado fluent e delegam aos mesmos executores do core. A API fluent não mantém uma conexão FireDAC permanente. O dataset retornado por `Open` é armazenado em `FDataSet` e segue a política pública `Owner(Boolean)` documentada em [Propriedade e ciclo de vida](../api/PROPRIEDADE_E_CICLO_DE_VIDA.pt-BR.md).

## Ownership e lifetime

- `TRickSQLCoreDriverContextFactory.Create` cria o contexto do driver usado pela sessão.
- `TRickSQLServiceFireDACSession` possui `DriverContext`, `TFDConnection` e `TFDQuery`.
- O destrutor da sessão libera `Query`, depois `Connection`, depois `DriverContext`.
- `Command.Executor` e `Open.Executor` criam uma sessão por operação e a liberam em `finally`.
- `Open` materializa os dados em dataset independente antes de destruir a sessão.
- O `DriverContext` mantém o driver link vivo durante a sessão e o libera em seu próprio lifecycle.

## Transações

`Execute` usa transação quando `TRickSQLCommandOptions.UseTransaction=True`. `Start`, `Commit`, `Rollback` e `RollbackAfterFailure` distinguem estado ativo/inativo de falha ao consultar `InTransaction`. `Active` preserva o contrato Boolean histórico, inclusive retornando `False` se a consulta ao estado lançar exception; os fluxos internos não dependem dessa ambiguidade.

## Drivers e compilação condicional

A factory resolve providers para 13 engines. Sem `FULL_EDITION`, DB2, Informix, SQL Server, ODBC, Oracle e SQL Anywhere permanecem resolvíveis como providers fallback, mas rejeitam uso funcional informando a exigência de `FULL_EDITION`. SQLite, Firebird, InterBase, PostgreSQL, MySQL, Advantage e Access permanecem no branch padrão.

A seleção do provider de espera do FireDAC depende do host: `CONSOLE`, `RICK_VCL_CONNECTION` ou `RICK_FMX_CONNECTION`. O projeto oficial de testes define `RICK_VCL_CONNECTION`.

## Versão e targets do projeto de testes

O `tests/RickSQL.Tests.dproj` contém `ProjectVersion = 20.3`, `Debug` como configuração padrão e `Win32` como plataforma padrão. A correspondência exata desse número de projeto com uma edição comercial específica do Delphi não é inferida aqui: **Não confirmado.**
