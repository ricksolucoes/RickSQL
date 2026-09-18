# Opções de conexão

> [Voltar ao índice da documentação](../README.pt-BR.md)


## Tipo principal

As opções de conexão são representadas pelo record `TRickSQLConnectionOptions`, declarado em `Rick.SQL.Model.Connection.Options` e exposto como alias pela unit pública `Rick.SQL`.

## Campos disponíveis

| Campo | Tipo | Descrição |
|---|---|---|
| `Engine` | `TRickSQLDatabaseEngine` | mecanismo de banco selecionado |
| `Server` | `string` | servidor, host ou endereço da instância |
| `Port` | `Integer` | porta de conexão; zero permite usar a porta padrão do mecanismo |
| `Database` | `string` | banco, catálogo, serviço ou caminho de arquivo local, conforme o mecanismo |
| `UserName` | `string` | usuário de conexão |
| `Password` | `string` | senha de conexão |
| `CharacterSet` | `string` | conjunto de caracteres |
| `ConnectTimeout` | `Integer` | tempo máximo, em segundos, para estabelecer a conexão |
| `ClientLibraryPath` | `string` | caminho explícito para a biblioteca cliente nativa |
| `ExtraParameters` | `TRickSQLConnectionParameterArray` | parâmetros adicionais específicos do FireDAC, como pares nome/valor |

## Criação e valores padrão

A criação recomendada é feita pela fachada:

```pascal
LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
```

Internamente, esse método chama `TRickSQLConnectionOptions.Create(AEngine)`, que define `Engine` com o valor informado e inicializa os demais campos com valores neutros: `Server`, `Database`, `UserName`, `Password`, `CharacterSet` e `ClientLibraryPath` em branco; `Port` e `ConnectTimeout` em zero; `ExtraParameters` vazio (`nil`).

## Validações aplicadas

Antes de qualquer conexão real, `Rick.SQL.Core.Connection.Validator` aplica as seguintes verificações sobre `TRickSQLConnectionOptions`:

- `Engine` deve corresponder a um valor válido de `TRickSQLDatabaseEngine`.
- Pelo menos um dado de conexão deve estar preenchido: `Server`, `Database`, `UserName`, `Password`, `Port` diferente de zero, ou algum item em `ExtraParameters`. Caso contrário, o erro retornado indica que as opções de conexão não foram configuradas.
- `Port` deve estar entre 0 e 65535.
- `ConnectTimeout` não pode ser negativo.
- `ClientLibraryPath`, quando informado, não pode conter os caracteres `*`, `?`, retorno de carro (`#13`) ou nova linha (`#10`).
- Cada item de `ExtraParameters` deve ter `Name` preenchido, sem `=`, `#13` ou `#10` no nome, e `Value` preenchido.
- O nome `DriverID` é reservado ao framework: um parâmetro adicional com esse nome é rejeitado pelo validador, pois o `DriverID` é sempre resolvido internamente a partir do mecanismo escolhido.
- Não são permitidos nomes de parâmetros adicionais duplicados (comparação sem diferenciar maiúsculas de minúsculas).
- Por fim, o provider específico do mecanismo (`IRickSQLDriverProvider.ValidateOptions`) valida os campos obrigatórios daquele banco — consulte a tabela de campos obrigatórios em [`BANCOS_SUPORTADOS.md`](../bancos/BANCOS_SUPORTADOS.pt-BR.md).

## Exemplo SQLite

```pascal
LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
LConnection.Database := 'C:\Dados\app.db';
```

## Exemplo Firebird

```pascal
LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.Firebird);
LConnection.Server := '127.0.0.1';
LConnection.Database := 'C:\Dados\ERP.FDB';
LConnection.UserName := 'SYSDBA';
LConnection.Password := 'senha';
LConnection.CharacterSet := 'UTF8';
LConnection.ClientLibraryPath := 'C:\Clientes\Firebird\fbclient.dll';
```

## Exemplo PostgreSQL

```pascal
LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.PostgreSQL);
LConnection.Server := '127.0.0.1';
LConnection.Port := 5432;
LConnection.Database := 'erp';
LConnection.UserName := 'postgres';
LConnection.Password := 'senha';
```

## Exemplo SQL Server

```pascal
LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLServer);
LConnection.Server := 'SERVIDOR\INSTANCIA';
LConnection.Database := 'ERP';
LConnection.UserName := 'usuario';
LConnection.Password := 'senha';
```

## Parâmetros adicionais

Use `ExtraParameters`, por meio do método `AddExtraParameter`, para parâmetros específicos do FireDAC que não possuam campo direto em `TRickSQLConnectionOptions`:

```pascal
LConnection.AddExtraParameter('Encrypt', 'No');
```

O parâmetro `DriverID` é reservado ao framework e não deve ser informado pelo consumidor; se informado, a validação da conexão retornará erro estruturado antes de qualquer tentativa de conexão.

## Segurança

A senha (`Password`) é usada somente para montar a conexão real com o banco. Mensagens e detalhes técnicos processados por `Rick.SQL.Error.Normalizer` mascaram automaticamente valores associados a chaves sensíveis (`Password=`, `PWD=`, `Pass=`, `Senha=`, `User Password=`, `User_Password=`), substituindo o valor por `***`. O normalizador compartilhado fica em `src/error`. Consulte [`TRATAMENTO_DE_ERROS.md`](TRATAMENTO_DE_ERROS.pt-BR.md) para o detalhamento completo desse mecanismo.
