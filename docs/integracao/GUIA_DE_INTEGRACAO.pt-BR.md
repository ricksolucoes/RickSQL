# Guia de integração do RickSQL

> [Voltar ao índice da documentação](../README.pt-BR.md)

Este guia descreve como integrar o código-fonte do RickSQL a um projeto Delphi. A implementação permanece em `src/`; a documentação foi centralizada em `docs/`; os exemplos executáveis ficam em `samples/`; a suíte oficial de novas refatorações fica em `NewTests/`; e `tests/` permanece como suíte legada.

## Estrutura de pastas

A estrutura física relevante para integração é:

```text
RickSQL/
  README.md
  README.pt-BR.md
  LICENSE
  LICENSE-pt-BR
  src/
    Rick.SQL.pas
    Rick.SQL.Interf.pas
    model/
      Rick.SQL.Model.Types.pas
      Rick.SQL.Model.Connection.Options.pas
      Rick.SQL.Model.Command.Options.pas
      Rick.SQL.Model.Command.pas
      Rick.SQL.Model.Parameter.pas
      Rick.SQL.Model.Error.pas
      Rick.SQL.Model.Execution.Result.pas
      Rick.SQL.Model.Driver.Definition.pas
      Rick.SQL.Model.Contracts.pas
    error/
      Rick.SQL.Error.Normalizer.pas
    core/
      Rick.SQL.Core.Connection.Validator.pas
      Rick.SQL.Core.Command.Validator.pas
      Rick.SQL.Core.Parameter.Validator.pas
      Rick.SQL.Core.Driver.Factory.pas
      Rick.SQL.Core.Driver.Context.Factory.pas
      Rick.SQL.Core.ClientLibrary.Resolver.pas
      Rick.SQL.Core.DataSet.Materializer.pas
      Rick.SQL.Core.Error.Parser.pas
      Rick.SQL.Core.Open.Executor.pas
      Rick.SQL.Core.Command.Executor.pas
    services/
      Rick.SQL.Service.FireDAC.Session.pas
      Rick.SQL.Service.FireDAC.Connection.pas
      Rick.SQL.Service.FireDAC.Query.pas
      Rick.SQL.Service.FireDAC.Parameter.Binder.pas
      Rick.SQL.Service.FireDAC.Transaction.pas
      drivers/
        Rick.SQL.Service.FireDAC.Driver.Base.pas
        Rick.SQL.Service.FireDAC.Driver.Context.pas
        Rick.SQL.Service.FireDAC.Driver.Firebird.pas
        Rick.SQL.Service.FireDAC.Driver.InterBase.pas
        Rick.SQL.Service.FireDAC.Driver.PostgreSQL.pas
        Rick.SQL.Service.FireDAC.Driver.MSSQL.pas
        Rick.SQL.Service.FireDAC.Driver.MySQL.pas
        Rick.SQL.Service.FireDAC.Driver.SQLite.pas
        Rick.SQL.Service.FireDAC.Driver.Oracle.pas
        Rick.SQL.Service.FireDAC.Driver.DB2.pas
        Rick.SQL.Service.FireDAC.Driver.SQLAnywhere.pas
        Rick.SQL.Service.FireDAC.Driver.Informix.pas
        Rick.SQL.Service.FireDAC.Driver.Advantage.pas
        Rick.SQL.Service.FireDAC.Driver.Access.pas
        Rick.SQL.Service.FireDAC.Driver.ODBC.pas
  docs/
    README.md
    README.pt-BR.md
    integracao/
    api/
    bancos/
    testes/
    engenharia/
  NewTests/
    RickSQL.NewTests.dpr
    RickSQL.NewTests.dproj
    src/
      Error/
        Rick.SQL.Tests.Error.Integration.pas
        Rick.SQL.Tests.Error.Normalizer.pas
  tests/                  # legado
    compilacao/
    unitarios/
    integracao/
    memoria/
    concorrencia/
  samples/
    Interface/
    console/
    fmx/
    servico-windows/
```

A fachada pública principal é `Rick.SQL`, contendo a classe `TRickSQL`. O projeto também expõe a API fluente complementar `Rick.SQL.Interf`, cujo ponto de entrada é `TRickSQLInterf.New` e cujo consumo ocorre pelas interfaces `IRickSQL*`. As demais units internas seguem o prefixo `Rick.SQL.` para reduzir colisões de nomes com units de outros projetos presentes no mesmo `Library Path`.

Não existe pasta `packages` no projeto, nem arquivo `.dpk`.

## Organização interna relevante

A unit `Rick.SQL.Core.Driver.Context.Factory.pas`, com a classe `TRickSQLCoreDriverContextFactory`, centraliza a resolução do provider (via `Rick.SQL.Core.Driver.Factory`) e da biblioteca cliente (via `Rick.SQL.Core.ClientLibrary.Resolver`) necessárias para criar um `TRickSQLServiceFireDACDriverContext`.

Ela é consumida tanto por `Rick.SQL.Core.Open.Executor` quanto por `Rick.SQL.Core.Command.Executor`, evitando que os dois executores repitam a lógica de criação do contexto do driver.

A unit `src/error/Rick.SQL.Error.Normalizer.pas` concentra a política compartilhada de normalização de exceptions, sanitização de `Message`/`TechnicalDetail` e extração de metadados FireDAC. Ela fica fora de `core` e `services` para poder ser consumida por ambos sem introduzir uma dependência `services -> core`. `Rick.SQL.Core.Error.Parser` permanece responsável pelas mensagens amigáveis fixas usadas pelos fluxos de core e delega a normalização técnica.

A política de separação de responsabilidades está documentada em [Controle de toxicidade](../engenharia/CONTROLE_DE_TOXICIDADE.pt-BR.md).

## Configuração no Delphi

Configure o caminho do código-fonte no `Library Path` global do Delphi ou no `Search Path` do projeto consumidor.

Caminhos absolutos recomendados:

```text
C:\Bibliotecas\RickSQL\src
C:\Bibliotecas\RickSQL\src\model
C:\Bibliotecas\RickSQL\src\error
C:\Bibliotecas\RickSQL\src\core
C:\Bibliotecas\RickSQL\src\services
C:\Bibliotecas\RickSQL\src\services\drivers
```

Também é possível utilizar uma variável de ambiente:

```text
RICKSQL_HOME=C:\Bibliotecas\RickSQL
```

E configurar o `Library Path` com:

```text
$(RICKSQL_HOME)\src
$(RICKSQL_HOME)\src\model
$(RICKSQL_HOME)\src\error
$(RICKSQL_HOME)\src\core
$(RICKSQL_HOME)\src\services
$(RICKSQL_HOME)\src\services\drivers
```

## Uso em aplicações existentes

Para usar a fachada principal, importe:

```pascal
uses
  Rick.SQL;
```

Para usar a API fluente complementar, importe:

```pascal
uses
  Rick.SQL.Interf;
```

Não é necessário importar as duas units para uma mesma forma de consumo.

A aplicação não precisa importar diretamente units do FireDAC, como:

```pascal
FireDAC.Phys.FB;
FireDAC.Phys.PG;
FireDAC.Phys.MSSQL;
```

Essas referências são tratadas internamente pelos providers do `RickSQL`, localizados em `src/services/drivers`, e vinculadas ao executável por meio da unit `Rick.SQL.Core.Driver.Factory`, que referencia todas as units de driver em sua cláusula `uses` da seção `implementation`.

## Ausência de package e interface visual

O `RickSQL` não possui:

- arquivo `.dpk`;
- instalação de package;
- registro na paleta de componentes;
- componentes visuais;
- dependência de VCL no código interno (`src/`).

O framework não exige que o consumidor seja uma aplicação FMX. Existe, porém, uma seleção condicional da unit de espera do FireDAC em `Rick.SQL.Core.ClientLibrary.Resolver`: sem `CONSOLE_CONNECTION`, a compilação referencia `FireDAC.FMXUI.Wait`; com `CONSOLE_CONNECTION`, referencia `FireDAC.ConsoleUI.Wait`.

A distribuição do framework é feita por código-fonte, acompanhada da documentação centralizada em `docs/` e dos arquivos de licença presentes na raiz do projeto.

## Diretivas de compilação

### Aplicações console — `CONSOLE_CONNECTION`

Projetos console devem definir `CONSOLE_CONNECTION` como *Conditional Define* do projeto. A diretiva é lida por `Rick.SQL.Core.ClientLibrary.Resolver`, portanto precisa estar disponível durante a compilação dessa unit. Configure o símbolo em **Project > Options > Delphi Compiler > Conditional defines** (ou por `-D` no compilador).

Um `{$DEFINE CONSOLE_CONNECTION}` colocado somente no `.dpr` não é suficiente para alterar a compilação de uma unit separada que consulta o símbolo. Por isso, o projeto [`samples/console/RickSQL.Sample.Console.dproj`](../../samples/console/RickSQL.Sample.Console.dproj) define o símbolo nas opções do compilador.

O sample console demonstra o consumo da fachada `Rick.SQL` nesse cenário.

### Providers condicionais — `FULL_EDITION`

As implementações de SQL Server, Oracle, DB2, SQL Anywhere, Informix e ODBC são compiladas sob `FULL_EDITION`. Para utilizar esses mecanismos, adicione `FULL_EDITION` aos *Conditional Defines* do projeto consumidor. Sem o símbolo, a factory ainda resolve os providers, mas suas operações de configuração/validação retornam a exigência de `FULL_EDITION`.

Os providers de SQLite, Firebird, InterBase, PostgreSQL, MySQL, Advantage e Access não utilizam essa condição.

## Fluxo recomendado de uso

1. Adicionar as pastas do `RickSQL` ao `Library Path` ou `Search Path` do projeto.
2. Declarar `Rick.SQL` no `uses` da unit consumidora, ou `Rick.SQL.Interf` quando a API fluente for a forma escolhida.
3. Na fachada principal, criar `TRickSQLConnectionOptions` por `TRickSQL.ConnectionOptions(AEngine)`.
4. Preencher os campos de conexão exigidos pelo mecanismo escolhido (ver [Opções de conexão](../api/OPCOES_DE_CONEXAO.pt-BR.md) e [Bancos suportados](../bancos/BANCOS_SUPORTADOS.pt-BR.md)).
5. Criar `TRickSQLCommand` por `TRickSQL.Command(AConnection, ASQL)`.
6. Adicionar parâmetros por `LCommand.AddParameter(TRickSQLParameter.Create(ANome, AValor))`, quando o SQL exigir.
7. Executar `TRickSQL.Open`, para consultas, ou `TRickSQL.Execute`, para comandos de alteração.
8. Tratar `TRickSQLError` (retornado por `Open`) ou `TRickSQLExecutionResult.Error` (retornado por `Execute`).
9. Liberar o `TDataSet` retornado por `Open` no bloco `finally` correspondente.

A forma fluente equivalente está detalhada em [API pública](../api/API_PUBLICA.pt-BR.md) e demonstrada em [Exemplos de uso](EXEMPLOS_DE_USO.pt-BR.md).

## Bibliotecas clientes

Alguns bancos exigem bibliotecas nativas, como `fbclient.dll` (Firebird), `libpq.dll` (PostgreSQL) ou `libmysql.dll` (MySQL). O `RickSQL` pode localizar e configurar essas bibliotecas por meio de `Rick.SQL.Core.ClientLibrary.Resolver`, mas não instala, baixa ou copia arquivos no sistema operacional.

Consulte [Bibliotecas clientes](../bancos/BIBLIOTECAS_CLIENTE.pt-BR.md) para a ordem de procura, arquitetura e nomes esperados por mecanismo.
