# Bancos suportados

> [Voltar ao índice da documentação](../README.pt-BR.md)


## Visão geral

O consumidor informa apenas o mecanismo de banco em `TRickSQLDatabaseEngine`. O `RickSQL` resolve internamente, por meio de `Rick.SQL.Core.Driver.Factory`, o provider correspondente (`IRickSQLDriverProvider`), o `DriverID` do FireDAC, o driver link e os parâmetros de conexão específicos do mecanismo.

Cada provider é implementado em uma unit própria na pasta `src/services/drivers`, seguindo o mesmo contrato (`IRickSQLDriverProvider`), o que garante que o executor de consultas e o executor de comandos nunca conheçam detalhes específicos de nenhum banco.

## Tabela de suporte

| Mecanismo (`TRickSQLDatabaseEngine`) | `DriverID` interno | Biblioteca(s) cliente(s) esperada(s) | Porta padrão |
|---|---|---:|---:|
| `SQLite` | `SQLite` | não obrigatória (usa arquivo local) | 0 |
| `Firebird` | `FB` | `fbclient.dll` | 3050 |
| `InterBase` | `IB` | `gds32.dll`, `ibtogo.dll`, `ibtogo64.dll` (nessa ordem de preferência) | 3050 |
| `PostgreSQL` | `PG` | `libpq.dll` | 5432 |
| `SQLServer` | `MSSQL` | `odbc32.dll` | 1433 |
| `MySQL` | `MySQL` | `libmysql.dll` | 3306 |
| `Oracle` | `Ora` | `oci.dll` | 1521 |
| `DB2` | `DB2` | `db2cli.dll` | 50000 |
| `SQLAnywhere` | `ASA` | `dbodbc17.dll`, `dbodbc16.dll`, `dbodbc12.dll` (nessa ordem de preferência) | 2638 |
| `Informix` | `Infx` | `iclit09b.dll` | 9088 |
| `Advantage` | `ADS` | `ace32.dll` (build Win32) ou `ace64.dll` (build Win64) | 6262 |
| `Access` | `MSAcc` | `ACEODBC.DLL` | 0 |
| `ODBC` | `ODBC` | `odbc32.dll` | 0 |

Os valores de porta padrão e os nomes das bibliotecas cliente esperadas são definidos internamente em cada unit de driver (constantes `_DRIVER_ID_`, `DefaultPort` e chamadas a `AddClientLibrary`). A lista de bibliotecas alimenta `TRickSQLCoreClientLibraryResolver`; quando existe um caminho a aplicar, a configuração de `VendorLib` é encaminhada para `TRickSQLServiceFireDACDriverVendorLibrary`.

## Disponibilidade por configuração de compilação

Todos os treze valores do enum possuem provider registrado na `Rick.SQL.Core.Driver.Factory`. Entretanto, seis implementações são condicionadas ao símbolo `FULL_EDITION`:

- SQL Server;
- Oracle;
- DB2;
- SQL Anywhere;
- Informix;
- ODBC.

Sem `FULL_EDITION`, esses providers permanecem localizáveis pela factory, mas rejeitam sua utilização durante configuração/validação informando que a diretiva é obrigatória. Para habilitá-los, configure `FULL_EDITION` como *Conditional Define* do projeto consumidor.

SQLite, Firebird, InterBase, PostgreSQL, MySQL, Advantage e Access não dependem de `FULL_EDITION`.

## Campos exigidos por mecanismo (`RequiredConnectionOptions`)

Cada provider declara, em sua `TRickSQLDriverDefinition`, o conjunto de campos de `TRickSQLConnectionOptions` que são obrigatórios para aquele mecanismo. Esse conjunto é verificado pelo próprio provider durante `ValidateOptions`, chamado por `Rick.SQL.Core.Connection.Validator`.

| Mecanismo | `Server` | `Database` | `UserName` | `Password` |
|---|:---:|:---:|:---:|:---:|
| SQLite | | obrigatório | | |
| Firebird | | obrigatório | obrigatório | obrigatório |
| InterBase | | obrigatório | obrigatório | obrigatório |
| PostgreSQL | obrigatório | obrigatório | obrigatório | obrigatório |
| SQL Server | obrigatório | | | |
| MySQL | obrigatório | obrigatório | obrigatório | obrigatório |
| Oracle | | obrigatório | obrigatório | obrigatório |
| DB2 | obrigatório | obrigatório | obrigatório | obrigatório |
| SQL Anywhere | | obrigatório | obrigatório | obrigatório |
| Informix | obrigatório | obrigatório | obrigatório | obrigatório |
| Advantage | | obrigatório | | |
| Access | | obrigatório | | |
| ODBC | não declarado explicitamente (varia conforme DSN ou `ExtraParameters`) | | | |

Quando um campo obrigatório não é informado, `TRickSQLCoreConnectionValidator.Validate` retorna erro estruturado (`TRickSQLErrorKind.Validation`) antes de qualquer tentativa de conexão real.

## Exemplos de configuração

### SQLite

```pascal
LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
LConnection.Database := 'C:\Dados\app.db';
```

### Firebird e InterBase

- `Database` com o caminho do arquivo ou alias;
- `UserName` e `Password`;
- `Server`, quando o banco estiver remoto (Firebird e InterBase também aceitam conexão local, mas os providers exigem usuário e senha em ambos os casos).

### PostgreSQL, MySQL, DB2, Informix

- `Server`;
- `Database`;
- `UserName` e `Password`.

### SQL Server

- `Server` (pode incluir a instância, por exemplo `SERVIDOR\INSTANCIA`);
- `Database`, `UserName` e `Password` são opcionais no nível de validação do provider, mas normalmente necessários para a conexão real, dependendo do modo de autenticação configurado.

### Oracle

- `Database` (serviço ou identificador Easy Connect);
- `UserName` e `Password`.

### SQL Anywhere

- `Database`;
- `UserName` e `Password`.

### Advantage e Access

- `Database` com o caminho do arquivo, alias ou catálogo.

### ODBC

- DSN, driver ou parâmetros ODBC adicionais informados em `ExtraParameters`, já que o provider ODBC não declara um conjunto fixo de campos obrigatórios.

## Regras específicas por provider

Além dos campos obrigatórios genéricos, os providers a seguir aplicam regras adicionais de validação ou montagem da conexão:

### SQL Server — autenticação do Windows

O provider de SQL Server (`Rick.SQL.Service.FireDAC.Driver.MSSQL`) exige `UserName` e `Password` **a não ser** que o parâmetro adicional `OSAuthent` seja informado com o valor `Yes` ou `True` (comparação sem diferenciar maiúsculas de minúsculas) em `ExtraParameters`, indicando autenticação integrada do Windows:

```pascal
LConnection.AddExtraParameter('OSAuthent', 'Yes');
```

Quando `OSAuthent` não estiver definido dessa forma e `UserName`/`Password` não forem informados, a validação falha com a mensagem "Informe usuário e senha ou habilite a autenticação do Windows.". O provider também combina `Server` e `Port` em um único parâmetro no formato `servidor,porta` (convenção do driver ODBC/MSSQL do FireDAC) quando a porta é informada e o servidor ainda não contém uma vírgula.

### ODBC — DataSource x ODBCDriver

O provider ODBC (`Rick.SQL.Service.FireDAC.Driver.ODBC`) aceita a fonte de conexão de duas formas, mas não simultaneamente:

- `Database` (ou o parâmetro adicional `DataSource`) identificando uma fonte de dados ODBC já configurada (DSN); ou
- o parâmetro adicional `ODBCDriver`, identificando um driver ODBC pelo nome, sem depender de um DSN previamente cadastrado.

Informar as duas formas ao mesmo tempo é rejeitado pela validação ("DataSource e ODBCDriver não podem ser informados ao mesmo tempo."). Não informar nenhuma das duas também é rejeitado ("Informe uma fonte de dados ODBC ou o nome de um driver ODBC.").

### Oracle — Easy Connect automático

Quando `Server` é informado, o provider Oracle monta automaticamente a string de conexão no formato Easy Connect `//servidor:porta/database`, usando `Port` quando informado ou a porta padrão (1521) caso contrário. Quando `Server` não é informado, `Database` é usado como está (por exemplo, um alias TNS ou nome de serviço já configurado no ambiente).

### Informix — HostName, InformixServer e protocolo

O provider Informix aplica automaticamente `HostName` (a partir de `Server`) e o parâmetro `Protocol` fixo em `olsoctcp`. O nome do servidor Informix (`InformixServer`) pode ser informado explicitamente via parâmetro adicional `InformixServer`; quando ausente, o provider utiliza o valor de `Server` também para esse parâmetro.

### Advantage — tipo de servidor

O provider Advantage define automaticamente o parâmetro `ServerTypes` como `Local` quando `Server` está vazio, ou como `Remote` quando `Server` é informado — o consumidor não precisa informar esse parâmetro manualmente.

## Identificação de parâmetros e dialeto

A seleção de `TRickSQLDatabaseEngine` também é utilizada por `Rick.SQL.Core.Parameter.Validator` para desambiguar marcadores RickSQL `:NOME` de construções lexicais do engine que também utilizam `:`. Essa etapa é uma validação local e ocorre antes da criação da sessão/conexão FireDAC.

Isso **não** significa que o RickSQL tenha se tornado um parser ou tradutor de SQL. O scanner possui regras delimitadas às construções necessárias para identificar parâmetros com segurança, como delimitadores específicos, comentários, array slices, labels, PSQL e qualificadores que foram incorporados à cobertura oficial. A descrição funcional e a matriz dessas regras estão em [Comandos e parâmetros](../api/COMANDOS_E_PARAMETROS.pt-BR.md#identificação-lexical-de-parâmetros-por-engine).

`Advantage` usa atualmente somente as regras lexicais comuns do scanner. Para `ODBC`, o valor do enum não identifica o DBMS efetivo por trás do driver; por isso o framework também mantém apenas as regras comuns em vez de presumir um dialeto ODBC específico.

## Limitações

O `RickSQL` não converte dialetos SQL. O comando informado em `TRickSQLCommand.Text` deve ser compatível com o banco escolhido pelo consumidor.

Exemplos de diferenças que permanecem sob responsabilidade do consumidor:

- `TOP` é específico de SQL Server;
- `LIMIT` é comum em SQLite, PostgreSQL e MySQL;
- funções de data e hora variam conforme o banco.

O framework também não instala bibliotecas nativas, clientes de banco de dados ou drivers ODBC no sistema operacional; ele apenas localiza e configura bibliotecas já disponíveis (ver [`BIBLIOTECAS_CLIENTE.md`](BIBLIOTECAS_CLIENTE.pt-BR.md)).
