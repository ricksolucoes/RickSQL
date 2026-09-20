# Guia de integração do RickSQL

> [Voltar ao índice da documentação](../README.pt-BR.md)

Este guia descreve como integrar o código-fonte do RickSQL a um projeto Delphi. A implementação permanece em `src/`; a documentação fica em `docs/`; os exemplos executáveis ficam em `samples/`; e `tests/` é a única suíte oficial DUnit.

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
    error/
    core/
    services/
      drivers/
  docs/
    README.md
    README.pt-BR.md
    integracao/
    api/
    bancos/
    testes/
    engenharia/
  tests/
    RickSQL.Tests.dproj
    RickSQL.Tests.dpr
    RickSQL.Tests.res
    src/
      ClientLibrary/
      Concurrency/
      Driver/
      Error/
      Facade/
      Infrastructure/
      Integration/
      Materialization/
      Model/
      Service/
      Transaction/
      Validation/
  samples/
    Interface/
    console/
    fmx/
    servico-windows/
```

A fachada pública principal é `Rick.SQL`, contendo a classe `TRickSQL`. O projeto também expõe a API fluente complementar `Rick.SQL.Interf`, cujo ponto de entrada é `TRickSQLInterf.New` e cujo consumo ocorre pelas interfaces `IRickSQL*`. As demais units internas seguem o prefixo `Rick.SQL.` para reduzir colisões de nomes com units de outros projetos presentes no mesmo `Library Path`.

Não existe pasta `packages` no projeto, nem arquivo `.dpk`.

## Organização interna relevante

No pipeline normal de `Open`/`Execute`, `Rick.SQL.Core.Connection.Validator` resolve o `IRickSQLDriverProvider` por meio de `Rick.SQL.Core.Driver.Factory` durante a validação das opções de conexão. `Rick.SQL.Core.Command.Validator` devolve essa mesma interface ao executor, que a repassa para `TRickSQLCoreDriverContextFactory`.

A unit `Rick.SQL.Core.Driver.Context.Factory.pas` permanece responsável por criar o `TRickSQLServiceFireDACDriverContext` e resolver o caminho da biblioteca cliente por meio de `Rick.SQL.Core.ClientLibrary.Resolver`, mas o pipeline principal reutiliza o provider já resolvido durante a validação. O overload compatível `Create(AOptions, AOperation, AError)` continua disponível para consumidores isolados e pode resolver um provider quando ele não foi fornecido.

A unit `src/error/Rick.SQL.Error.Normalizer.pas` concentra a política compartilhada de normalização de exceptions, sanitização de `Message`/`TechnicalDetail` e extração de metadados FireDAC. Ela fica fora de `core` e `services` para poder ser consumida por ambos sem introduzir uma dependência `services -> core`. `Rick.SQL.Core.Error.Parser` permanece responsável pelas mensagens amigáveis fixas usadas pelos fluxos de core e delega a normalização técnica.

A resolução da client library permanece em `Rick.SQL.Core.ClientLibrary.Resolver`. No pipeline principal, o overload de `Resolve` que recebe provider obtém `Definition` da mesma instância já devolvida pela validação; o overload compatível sem provider continua disponível para consumidores isolados. A aplicação de um caminho já resolvido à propriedade `VendorLib` do DriverLink é centralizada em `Rick.SQL.Service.FireDAC.Driver.VendorLibrary`, classe `TRickSQLServiceFireDACDriverVendorLibrary`. `Driver.Context`, o caminho compatível `ClientLibraryResolver.Configure` e providers que possuem `VendorLib` padrão convergem para essa implementação, sem duplicar a mecânica de atribuição.

O fluxo interno relevante fica, de forma simplificada:

```text
Open.Executor / Command.Executor
              ↓
       Command.Validator
              ↓
     Connection.Validator
              ↓
       Driver.Factory.Resolve
              ↓
     IRickSQLDriverProvider
              ↓
 mesmo provider devolvido ao executor
              ↓
     Driver.Context.Factory
              ↓
      ClientLibraryResolver
              ↓
       Provider.Definition
              ↓
        path resolvido
              ↓
   Driver.Context(provider, path)
              ↓
     Provider.CreateDriverLink
              ↓
FireDAC.Driver.VendorLibrary
              ↓
          VendorLib
```

Essa reutilização é interna a cada operação: os overloads compatíveis existentes permanecem disponíveis para chamadas isoladas, `Driver.Factory` continua sendo o composition point de engine para provider e nenhum cache global de provider/definition é introduzido. A fachada `Rick.SQL`, a API fluente e a política de resolução da client library mantêm seus contratos existentes.

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

## Ausência de package e seleção do provider FireDAC

O `RickSQL` não possui:

- arquivo `.dpk`;
- instalação de package;
- registro na paleta de componentes;
- componentes visuais próprios.

O código interno seleciona condicionalmente apenas a implementação de `IFDGUIxWaitCursor` exigida pelo FireDAC. `Rick.SQL.Core.ClientLibrary.Resolver` referencia `FireDAC.ConsoleUI.Wait`, `FireDAC.VCLUI.Wait` ou `FireDAC.FMXUI.Wait` conforme o host informado na compilação. Isso não transforma o RickSQL em componente visual nem altera sua API pública.

A distribuição do framework é feita por código-fonte, acompanhada da documentação centralizada em `docs/` e dos arquivos de licença presentes na raiz do projeto.

## Diretivas de compilação

### Provider de espera do FireDAC

A seleção segue este contrato:

| Host | Condição | Provider |
| --- | --- | --- |
| Console | `CONSOLE` | `FireDAC.ConsoleUI.Wait` |
| VCL | `RICK_VCL_CONNECTION` | `FireDAC.VCLUI.Wait` |
| FMX | `RICK_FMX_CONNECTION` | `FireDAC.FMXUI.Wait` |

Aplicações console não precisam de define específico do RickSQL. Aplicações VCL devem definir `RICK_VCL_CONNECTION`, e aplicações FMX devem definir `RICK_FMX_CONNECTION`, no nível do projeto. Os símbolos `RICK_VCL_CONNECTION` e `RICK_FMX_CONNECTION` são mutuamente exclusivos. Em uma aplicação não-console, a ausência de ambos provoca erro de compilação.

O sample console usa `CONSOLE` automaticamente; o sample FMX define `RICK_FMX_CONNECTION`; o projeto oficial em `tests/`, por ser VCL, define `RICK_VCL_CONNECTION`. No sample de serviço Windows, Debug é console e Release define `RICK_VCL_CONNECTION`, coerente com o host baseado em `Vcl.SvcMgr`.

### Providers condicionais — `FULL_EDITION`

As implementações de SQL Server, Oracle, DB2, SQL Anywhere, Informix e ODBC são compiladas sob `FULL_EDITION`. Para utilizar esses mecanismos, adicione `FULL_EDITION` aos *Conditional Defines* do projeto consumidor. Sem o símbolo, a factory ainda resolve os providers, mas suas operações de configuração/validação retornam a exigência de `FULL_EDITION`.

Os providers de SQLite, Firebird, InterBase, PostgreSQL, MySQL, Advantage e Access não utilizam essa condição.

## Suíte oficial de testes

A validação do framework fica em `tests/RickSQL.Tests.dproj`. O `MainSource` é `RickSQL.Tests.dpr`; o runner usa DUnit GUI e executa novamente a suíte em modo XML após o fechamento da janela. Consulte [Testes e homologação](../testes/TESTES_E_HOMOLOGACAO.pt-BR.md).

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

Alguns bancos exigem bibliotecas nativas, como `fbclient.dll` (Firebird), `libpq.dll` (PostgreSQL) ou `libmysql.dll` (MySQL). `Rick.SQL.Core.ClientLibrary.Resolver` localiza e valida o caminho; `Rick.SQL.Service.FireDAC.Driver.VendorLibrary` aplica esse caminho ao `VendorLib` do DriverLink. O `RickSQL` não instala, baixa ou copia arquivos no sistema operacional.

Consulte [Bibliotecas clientes](../bancos/BIBLIOTECAS_CLIENTE.pt-BR.md) para a ordem de procura, arquitetura e nomes esperados por mecanismo.
