# API pública

Este documento concentra a referência das duas formas públicas de consumo do RickSQL. O contrato foi reorganizado a partir da documentação anterior do `README.md` e deve ser lido em conjunto com as units públicas [`src/Rick.SQL.pas`](../../src/Rick.SQL.pas) e [`src/Rick.SQL.Interf.pas`](../../src/Rick.SQL.Interf.pas).

> [Voltar ao índice da documentação](../README.pt-BR.md)


## Características das fachadas

A fachada `Rick.SQL` é composta por métodos de classe e não mantém estado de instância. As classes utilitárias internas usadas pelo fluxo principal recebem o contexto necessário por parâmetro e não dependem de um estado global mutável para representar uma operação.

`Rick.SQL.Interf` possui uma característica deliberadamente diferente: `TRickSQLInterf` mantém **estado de instância** entre chamadas do encadeamento para acumular conexão, comando, parâmetros e opções até `Open` ou `Execute`. Esse estado pertence à instância retornada por `TRickSQLInterf.New`; não é estado global do framework.

O núcleo não exibe mensagens visuais e não exige que o consumidor manipule diretamente `TFDConnection`, `TFDQuery`, `TFDPhysDriverLink` ou `DriverID`.

## API pública da fachada `TRickSQL`

```pascal
TRickSQL = class
public
  class function ConnectionOptions(const AEngine: TRickSQLDatabaseEngine): TRickSQLConnectionOptions; static;
  class function Command(const AConnection: TRickSQLConnectionOptions; const ASQL: string): TRickSQLCommand; static;
  class function Open(const ACommand: TRickSQLCommand; out AError: TRickSQLError): TDataSet; static;
  class function Execute(const ACommand: TRickSQLCommand): TRickSQLExecutionResult; static;
end;
```

- `ConnectionOptions` cria `TRickSQLConnectionOptions` com os valores padrão do mecanismo informado.
- `Command` cria um `TRickSQLCommand` associando as opções de conexão ao texto SQL.
- `Open` executa uma consulta e retorna um `TDataSet` desconectado (ou `nil` em caso de falha, com `AError` preenchido).
- `Execute` executa um comando de alteração e retorna `TRickSQLExecutionResult`, com indicação de sucesso, quantidade de registros afetados e erro estruturado.

## Resultado de consultas

Consultas abertas por `TRickSQL.Open` retornam um `TDataSet` desconectado. O dado é materializado em memória (em um `TFDMemTable` interno) antes do retorno, e a conexão, a query e o driver context internos podem ser liberados sem afetar o dataset retornado. O objeto retornado pertence ao chamador e deve ser liberado por ele. Consulte [`PROPRIEDADE_E_CICLO_DE_VIDA.md`](PROPRIEDADE_E_CICLO_DE_VIDA.pt-BR.md) para o detalhamento completo do ciclo de vida.

```pascal
LDataSet := TRickSQL.Open(LCommand, LError);
try
  // uso do dataset
finally
  LDataSet.Free;
end;
```

## Execução de comandos

Comandos executados por `TRickSQL.Execute` retornam `TRickSQLExecutionResult`, contendo `Success: Boolean`, `RowsAffected: Integer` e `Error: TRickSQLError`.

```pascal
LResult := TRickSQL.Execute(LCommand);
if not LResult.Success then
  Writeln(LResult.Error.Message);
```

## Interface fluente complementar — `Rick.SQL.Interf`

Além da fachada procedural `Rick.SQL` / `TRickSQL`, o projeto disponibiliza uma unit complementar, `Rick.SQL.Interf`, que oferece a mesma funcionalidade por meio de uma API fluente (encadeamento de métodos), construída inteiramente sobre os models e executores públicos já descritos neste documento (`TRickSQLCoreOpenExecutor`, `TRickSQLCoreCommandExecutor`, `TRickSQLConnectionOptions`, `TRickSQLCommand`, `TRickSQLParameter`). Não é uma substituição do `Rick.SQL`; é uma camada adicional, e o consumidor escolhe qual das duas formas de uso prefere.

## API pública da fachada `TRickSQLInterf`

O ponto de entrada público da unit é um único método de classe:

```pascal
class function New: IRickSQL;
```

`TRickSQLInterf.New` cria a instância e a devolve já como `IRickSQL` — o consumidor nunca chama `TRickSQLInterf.Create` diretamente nem manipula a classe concreta. Todo o restante da API é acessado exclusivamente por meio das oito interfaces que `TRickSQLInterf` implementa: `IRickSQL`, `IRickSQLConnectionOptions`, `IRickSQLCommand`, `IRickSQLCommandOptions`, `IRickSQLMaterializationOptions`, `IRickSQLParameter`, `IRickSQLCursor` e `IRickSQLResult`. Cada uma delas é descrita a seguir.

### `IRickSQL` — hub central

```pascal
IRickSQL = interface
  function ConnectionOptions: IRickSQLConnectionOptions;
  function Command: IRickSQLCommand;
  function Cursor: IRickSQLCursor;
  function Result: IRickSQLResult;

  function Owner(const AOwner: Boolean): IRickSQL;
end;
```

- `ConnectionOptions` → `IRickSQLConnectionOptions`, para configurar a conexão.
- `Command` → `IRickSQLCommand`, para configurar o comando SQL e seus parâmetros.
- `Cursor` → `IRickSQLCursor`, para executar `Open` ou `Execute`.
- `Result` → `IRickSQLResult`, para ler o resultado da última operação.
- `Owner(AOwner: Boolean)` controla se a própria instância assume a posse do `TDataSet` retornado por `Open` e o libera automaticamente (padrão: `True`). Quando `Owner(False)` é usado, a liberação do `TDataSet` passa a ser responsabilidade do consumidor.

### `IRickSQLConnectionOptions`

```pascal
IRickSQLConnectionOptions = interface
  function Engine(const AEngine: TRickSQLDatabaseEngine): IRickSQLConnectionOptions;
  function Server(const AServer: string): IRickSQLConnectionOptions;
  function Port(const APort: Integer): IRickSQLConnectionOptions;
  function Database(const ADatabase: string): IRickSQLConnectionOptions;
  function UserName(const AUserName: string): IRickSQLConnectionOptions;
  function Password(const APassword: string): IRickSQLConnectionOptions;
  function CharacterSet(const ACharacterSet: string): IRickSQLConnectionOptions;
  function ConnectTimeout(const AConnectTimeout: Integer): IRickSQLConnectionOptions;
  function LibraryPath(const ALibraryPath: string): IRickSQLConnectionOptions;
  function AddConnectionParameter(const AName: string; const AValue: string): IRickSQLConnectionOptions;
  function ClearConnectionParameter: IRickSQLConnectionOptions;

  function Back: IRickSQL;
end;
```

Cada método corresponde a um campo de `TRickSQLConnectionOptions`. `AddConnectionParameter` adiciona (ou atualiza, se o nome já existir) um parâmetro extra de conexão; `ClearConnectionParameter` esvazia essa lista.

### `IRickSQLCommand`

```pascal
IRickSQLCommand = interface
  function Option: IRickSQLCommandOptions;
  function Parameter: IRickSQLParameter;

  function SQL(const ASQL: string): IRickSQLCommand;

  function Back: IRickSQL;
end;
```

`SQL` define o texto do comando. `Option` desvia para `IRickSQLCommandOptions`. `Parameter` desvia para `IRickSQLParameter`.

### `IRickSQLCommandOptions` e `IRickSQLMaterializationOptions`

```pascal
IRickSQLCommandOptions = interface
  function Materialization: IRickSQLMaterializationOptions;

  function TimeOut(const ATimeOut: Integer): IRickSQLCommand;
  function Transation(const ATransation: Boolean): IRickSQLCommand;
  function FetchAll(const AFetchAll: Boolean): IRickSQLCommand;
  function MaxRedord(const AMaxRedord: Integer): IRickSQLCommand;

  function Return: IRickSQLCommand;
end;

IRickSQLMaterializationOptions = interface
  function Position(const APosition: Boolean): IRickSQLMaterializationOptions;
  function Preserve(const APreserve: Boolean): IRickSQLMaterializationOptions;

  function ToBack: IRickSQLCommandOptions;
end;
```

Cada método corresponde a um campo de `TRickSQLCommandOptions` (`TimeOut` → `CommandTimeout`, `Transation` → `UseTransaction`, `FetchAll` → `FetchAll`, `MaxRedord` → `MaxRecords`) e de `TRickSQLMaterializationOptions` (`Position` → `PositionAtFirstRecord`, `Preserve` → `PreserveFieldMetadata`).

### `IRickSQLParameter`

```pascal
IRickSQLParameter = interface
  function Name(const AName: string): IRickSQLParameter;
  function Value(const AValue: Variant): IRickSQLParameter;
  function DataType(const ADataType: TFieldType): IRickSQLParameter;
  function Size(const ASize: Integer): IRickSQLParameter;
  function Direction(const ADirection: TParamType): IRickSQLParameter;
  function IsNull(const ANull: Boolean): IRickSQLParameter;

  function Clear: IRickSQLParameter;
  function Default: IRickSQLParameter;

  function Add: IRickSQLParameter;
  function AddNull: IRickSQLParameter;
  function AddVariant: IRickSQLParameter;

  function Return: IRickSQLCommand;
end;
```

- `Add` consolida um parâmetro usando todos os seis campos configurados (`Name`, `Value`, `DataType`, `Size`, `Direction`, `IsNull`).
- `AddNull` e `AddVariant` são atalhos que espelham, respectivamente, `TRickSQLParameter.CreateNull` e `TRickSQLParameter.Create` do model — por isso aceitam apenas os campos que esses dois construtores recebem (`Name`+`DataType` e `Name`+`Value`); `Size` e `Direction` não se aplicam a esses dois atalhos.
- `Add`, `AddNull` e `AddVariant` reiniciam automaticamente os campos de construção do parâmetro após consolidar (chamando `Default` internamente), para que o próximo `.Name(...)` comece de um estado neutro.
- `Clear` esvazia a lista de parâmetros já adicionados ao comando corrente — não afeta o parâmetro em construção.
- `Default` reinicia manualmente os campos do parâmetro em construção, sem afetar a lista já consolidada.

### `IRickSQLCursor`

```pascal
IRickSQLCursor = interface
  function Open: IRickSQLCursor;
  function Execute: IRickSQLCursor;

  function Back: IRickSQL;
end;
```

`Open` delega para `TRickSQLCoreOpenExecutor.Open`; `Execute` delega para `TRickSQLCoreCommandExecutor.Execute`. Antes de cada chamada, o estado da operação anterior (`FError`, `FErroFull`, e o `TDataSet` anterior, quando `Owner = True`) é reiniciado.

### `IRickSQLResult`

```pascal
IRickSQLResult = interface
  function DataSet: TDataSet;
  function Error: string;
  function ErrorFull: TRickSQLExecutionResult;
end;
```

`Error` devolve a mensagem amigável (`TRickSQLError.Message`); `ErrorFull` devolve o `TRickSQLExecutionResult` completo.

### Dependência adicional no model: `TRickSQLExecutionResult.Default`

Para que `IRickSQLCursor` tenha um valor neutro para `FErroFull` antes de qualquer `Open`/`Execute` ser chamado, `Rick.SQL.Model.Execution.Result` (a mesma unit que já define `TRickSQLExecutionResult`, consumida também pela fachada `Rick.SQL`) recebeu um terceiro método estático, além de `Succeeded` e `Failed`:

```pascal
class function Default: TRickSQLExecutionResult; static;
```

`Default` representa o estado "ainda não executado" (`Success := False`, `RowsAffected := 0`, `Error := TRickSQLError.Empty`). Esse método não é chamado pela fachada `TRickSQL` — é usado internamente por `TRickSQLInterf.ErrorDefault`, chamado no início de `Open`/`Execute` e na destruição da instância.

### Exemplo de uso

```pascal
uses
  Rick.SQL.Interf;

var
  LRick: IRickSQL;
begin
  LRick := TRickSQLInterf.New
    .ConnectionOptions
      .Engine(TRickSQLDatabaseEngine.SQLite)
      .Database('C:\Dados\teste.db')
    .Back
    .Command
      .SQL('select * from clientes where id = :ID')
      .Parameter
        .Name('ID')
        .Value(1)
        .Add
      .Return
    .Back
    .Cursor
      .Open
    .Back;

  if LRick.Result.Error = '' then
    Writeln('Registros: ', LRick.Result.DataSet.RecordCount)
  else
    Writeln(LRick.Result.Error);
end;
```

### Reaproveitando a mesma instância

`IRickSQL` pode ser reutilizada para mais de uma operação, mas dois pontos exigem atenção do consumidor:

- **Parâmetros do comando** (`FParameters`) e **parâmetros adicionais de conexão** (`FExtraParameters`) acumulam entre chamadas de `Open`/`Execute` na mesma instância — nada é limpo automaticamente entre um comando e outro. Use `.Parameter.Clear` e `.ConnectionOptions.ClearConnectionParameter` antes de montar um novo comando ou uma nova conexão na mesma instância, quando os parâmetros anteriores não devem ser reaproveitados.
- O `TDataSet` retornado por uma chamada anterior de `Open` é liberado automaticamente no início da chamada seguinte de `Open`/`Execute` (e na destruição do objeto), desde que `Owner(False)` não tenha sido usado. Quando `Owner(False)` é usado, essa liberação automática não ocorre, e o consumidor passa a ser o único responsável por liberar o dataset.
