# Bibliotecas clientes

> [Voltar ao índice da documentação](../README.pt-BR.md)


## Objetivo

Alguns bancos exigem uma biblioteca cliente nativa para que o FireDAC consiga abrir a conexão. O `RickSQL` possui resolução interna dessas bibliotecas por meio da unit `Rick.SQL.Core.ClientLibrary.Resolver`, classe `TRickSQLCoreClientLibraryResolver`.

Quando o mecanismo escolhido não exige biblioteca cliente (por exemplo, `SQLite`, cuja definição de driver não declara nenhuma entrada em `ClientLibraries`), o resolvedor retorna sucesso imediatamente, sem realizar nenhuma busca.

## Resolução e aplicação de `VendorLib`

A resolução da biblioteca e a aplicação do caminho ao FireDAC são responsabilidades distintas:

```text
TRickSQLCoreClientLibraryResolver
        │
        ├── determina se o engine exige biblioteca cliente
        ├── localiza e valida o arquivo aplicável
        └── produz o caminho resolvido
                    ↓
TRickSQLServiceFireDACDriverVendorLibrary
        │
        └── aplica o caminho à propriedade VendorLib do DriverLink
```

`TRickSQLCoreClientLibraryResolver` permanece responsável pela política de localização. A aplicação de `VendorLib` fica centralizada em `Rick.SQL.Service.FireDAC.Driver.VendorLibrary`, classe `TRickSQLServiceFireDACDriverVendorLibrary`, que não procura arquivos, não valida PE e não resolve providers.

O fluxo principal (`Driver.Context`) e o caminho compatível `TRickSQLCoreClientLibraryResolver.Configure` delegam para essa mesma implementação canônica. Providers que precisam preencher um `VendorLib` padrão também utilizam a mesma autoridade, evitando regras de atribuição independentes.

Quando o caminho recebido pela implementação canônica é vazio, a aplicação é ignorada e um valor de `VendorLib` já existente é preservado. Isso permite que engines que não exigem client library e configurações que dependem do mecanismo padrão do driver continuem sem uma atribuição forçada.

A centralização é da **aplicação** de `VendorLib`; a classificação externa de erros continua pertencendo ao fluxo que fez a chamada. O caminho compatível `Configure` preserva erros de `ClientLibrary`, enquanto `Driver.Context` preserva a classificação de `Driver`.

## Ordem de procura

Quando o mecanismo exige biblioteca cliente, a resolução segue esta ordem:

1. **Caminho explícito** — se `ClientLibraryPath` estiver preenchido em `TRickSQLConnectionOptions`, o resolvedor normaliza o caminho (removendo aspas, expandindo variáveis de ambiente e resolvendo caminhos relativos a partir do diretório do executável) e verifica se aponta para um arquivo existente ou para um diretório que contenha uma das bibliotecas esperadas. Se não localizar nada, o processo é interrompido com erro — o caminho explícito não é combinado com as demais fontes.
2. **Diretório do executável** — quando `ClientLibraryPath` não é informado, o resolvedor procura as bibliotecas esperadas diretamente na pasta onde está o `.exe` da aplicação consumidora.
3. **Subdiretório convencional do framework** — o resolvedor procura em `<diretório do executável>\RickSQL\libs\<Win32|Win64>` (de acordo com a arquitetura do processo em execução) e, na sequência, em `<diretório do executável>\RickSQL\libs`.
4. **Variável de ambiente `PATH`** — cada diretório listado em `PATH` é percorrido, na ordem em que aparece na variável.
5. **Configuração padrão do driver** — por fim, o resolvedor usa a API do sistema (`SearchPath`) para localizar a biblioteca pelos mecanismos padrão do Windows (diretórios do sistema, diretório de instalação de aplicações registradas, entre outros).

Se nenhuma fonte localizar uma biblioteca compatível, a resolução falha com um erro estruturado (`TRickSQLErrorKind.ClientLibrary`).

## Configuração explícita

```pascal
LConnection.ClientLibraryPath := 'C:\Clientes\Firebird\fbclient.dll';
```

Quando o caminho for informado, ele tem prioridade absoluta sobre as demais fontes de busca; se o arquivo ou diretório indicado não contiver uma biblioteca compatível, a resolução falha imediatamente, sem tentar as demais fontes.

## Diretório do executável

A biblioteca pode ser colocada ao lado do `.exe` da aplicação consumidora:

```text
MinhaAplicacao.exe
fbclient.dll
```

## Subdiretório convencional

O framework também procura em uma estrutura de pastas própria, ao lado do executável:

```text
MinhaAplicacao.exe
RickSQL\
  libs\
    Win64\
      fbclient.dll
    Win32\
      fbclient.dll
```

Quando não existir uma subpasta específica de arquitetura (`Win32` ou `Win64`), o resolvedor também procura diretamente em `RickSQL\libs`.

## Arquitetura Win32 e Win64

A biblioteca cliente localizada precisa ter a mesma arquitetura do executável em tempo de execução (32 ou 64 bits). O resolvedor inspeciona o cabeçalho PE (`IMAGE_FILE_HEADER.Machine`) do arquivo candidato para identificar se ele é compatível com a arquitetura do processo atual. Quando a arquitetura não é identificável (arquivo sem cabeçalho PE reconhecido), o candidato é considerado compatível por padrão; quando é identificável e diverge da arquitetura do processo, a resolução falha com erro estruturado, informando o arquivo, a arquitetura detectada e a arquitetura esperada.

## Bibliotecas cliente por banco

A tabela abaixo descreve as bibliotecas declaradas pelos providers. SQL Server, Oracle, DB2, SQL Anywhere, Informix e ODBC somente possuem implementação funcional quando `FULL_EDITION` está definido na compilação do projeto consumidor; consulte [`BANCOS_SUPORTADOS.md`](BANCOS_SUPORTADOS.pt-BR.md).

| Banco | Biblioteca(s) cliente(s) |
|---|---|
| Firebird | `fbclient.dll` |
| InterBase | `gds32.dll`, `ibtogo.dll`, `ibtogo64.dll` (nessa ordem de preferência) |
| PostgreSQL | `libpq.dll` |
| SQL Server | `odbc32.dll` |
| MySQL | `libmysql.dll` |
| Oracle | `oci.dll` |
| DB2 | `db2cli.dll` |
| SQL Anywhere | `dbodbc17.dll`, `dbodbc16.dll`, `dbodbc12.dll` (o resolvedor tenta essas versões nessa ordem) |
| Informix | `iclit09b.dll` |
| Advantage | `ace32.dll` (Win32) e `ace64.dll` (Win64) |
| Access | `ACEODBC.DLL` |
| ODBC | `odbc32.dll` |
| SQLite | não exige biblioteca cliente adicional |

## Comportamento quando a biblioteca não for localizada

O erro é retornado em `TRickSQLError`, com `Kind = TRickSQLErrorKind.ClientLibrary`.

Mensagem amigável esperada, quando um caminho explícito não é localizado:

```text
O caminho informado para a biblioteca cliente do <banco> não foi localizado.
Verifique ClientLibraryPath: <caminho informado>.
```

Mensagem amigável esperada, quando nenhuma das fontes padrão localiza a biblioteca:

```text
A biblioteca cliente necessária para o <banco> não foi localizada.
Informe ClientLibraryPath ou disponibilize uma destas bibliotecas: <lista de bibliotecas>.
```

O detalhe técnico (`TechnicalDetail`) informa as bibliotecas procuradas, o diretório do executável e o diretório convencional do framework utilizados na busca.

## O que o RickSQL não faz

O framework não baixa, instala, copia ou registra bibliotecas no sistema operacional. Ele localiza bibliotecas já presentes no ambiente por meio do resolver e, quando há um caminho a aplicar, encaminha a configuração do `VendorLib` para a implementação canônica `TRickSQLServiceFireDACDriverVendorLibrary`.

A distribuição das bibliotecas exigidas continua sendo responsabilidade da aplicação que utiliza o framework.
