# Testes de compilação

> [Voltar ao índice da documentação](../README.pt-BR.md)

Os projetos executáveis estão em [`tests/compilacao`](../../tests/compilacao/). A pasta contém atualmente **18 projetos `.dpr`** e valida contratos públicos e internos do RickSQL.

## Projetos

1. [`RickSQL.Models.CompilationTest.dpr`](../../tests/compilacao/RickSQL.Models.CompilationTest.dpr) — consumo dos models públicos por `Rick.SQL`.
2. [`RickSQL.Driver.FactoryCompilationTest.dpr`](../../tests/compilacao/RickSQL.Driver.FactoryCompilationTest.dpr) — resolução de provider e `DriverID` para os valores de `TRickSQLDatabaseEngine`.
3. [`RickSQL.Validators.ContractTest.dpr`](../../tests/compilacao/RickSQL.Validators.ContractTest.dpr) — contratos dos validadores de conexão, comando e parâmetros.
4. [`RickSQL.PriorityDrivers.ContractTest.dpr`](../../tests/compilacao/RickSQL.PriorityDrivers.ContractTest.dpr) — contratos funcionais dos drivers prioritários; SQL Server, Oracle e ODBC dependem de `FULL_EDITION` para a implementação funcional.
5. [`RickSQL.PriorityDrivers.PublicCompilationTest.dpr`](../../tests/compilacao/RickSQL.PriorityDrivers.PublicCompilationTest.dpr) — disponibilidade dos tipos públicos dos drivers prioritários por meio de `Rick.SQL`.
6. [`RickSQL.ComplementaryDrivers.ContractTest.dpr`](../../tests/compilacao/RickSQL.ComplementaryDrivers.ContractTest.dpr) — resolução dos providers complementares.
7. [`RickSQL.ClientLibrary.Resolver.ContractTest.dpr`](../../tests/compilacao/RickSQL.ClientLibrary.Resolver.ContractTest.dpr) — resolução e validação de bibliotecas clientes.
8. [`RickSQL.Driver.Context.ContractTest.dpr`](../../tests/compilacao/RickSQL.Driver.Context.ContractTest.dpr) — criação e liberação do contexto do driver.
9. [`RickSQL.FireDAC.Session.ContractTest.dpr`](../../tests/compilacao/RickSQL.FireDAC.Session.ContractTest.dpr) — ciclo de vida da sessão FireDAC.
10. [`RickSQL.FireDAC.Connection.Query.ContractTest.dpr`](../../tests/compilacao/RickSQL.FireDAC.Connection.Query.ContractTest.dpr) — configuração de conexão e query.
11. [`RickSQL.FireDAC.Parameter.Binder.ContractTest.dpr`](../../tests/compilacao/RickSQL.FireDAC.Parameter.Binder.ContractTest.dpr) — aplicação de parâmetros FireDAC.
12. [`RickSQL.FireDAC.Transaction.ContractTest.dpr`](../../tests/compilacao/RickSQL.FireDAC.Transaction.ContractTest.dpr) — contratos de início, commit e rollback de transação.
13. [`RickSQL.Error.Parser.ContractTest.dpr`](../../tests/compilacao/RickSQL.Error.Parser.ContractTest.dpr) — conversão de exceptions em `TRickSQLError`.
14. [`RickSQL.DataSet.Materializer.ContractTest.dpr`](../../tests/compilacao/RickSQL.DataSet.Materializer.ContractTest.dpr) — materialização de dataset em memória.
15. [`RickSQL.Open.Executor.ContractTest.dpr`](../../tests/compilacao/RickSQL.Open.Executor.ContractTest.dpr) — orquestração do fluxo de `Open`.
16. [`RickSQL.Command.Executor.ContractTest.dpr`](../../tests/compilacao/RickSQL.Command.Executor.ContractTest.dpr) — orquestração do fluxo de `Execute`.
17. [`RickSQL.Facade.ContractTest.dpr`](../../tests/compilacao/RickSQL.Facade.ContractTest.dpr) — contrato da fachada `Rick.SQL`.
18. [`RickSQL.LibraryPath.FinalTest.dpr`](../../tests/compilacao/RickSQL.LibraryPath.FinalTest.dpr) — consumo final por Library/Search Path, sem package.

## Diretivas condicionais

Os providers de SQL Server, Oracle, DB2, SQL Anywhere, Informix e ODBC são condicionados a `FULL_EDITION`. Testes que exercitam métodos funcionais desses providers devem ser compilados com esse símbolo configurado em **Project > Options > Delphi Compiler > Conditional defines** ou por `-D`.

Como esses testes são aplicações console, projetos que compilam o fluxo de `Rick.SQL.Core.ClientLibrary.Resolver` devem definir também `CONSOLE_CONNECTION` no nível do projeto para selecionar `FireDAC.ConsoleUI.Wait`.

## Library Path

Adicione ao `Library Path` ou `Search Path`:

```text
RickSQL\src
RickSQL\src\model
RickSQL\src\error
RickSQL\src\core
RickSQL\src\services
RickSQL\src\services\drivers
```

Nenhum package ou componente visual deve ser instalado.

## Resultado

A lista acima descreve os projetos existentes. Compilação e execução bem-sucedidas somente podem ser registradas depois de executar o compilador/ambiente correspondente.
