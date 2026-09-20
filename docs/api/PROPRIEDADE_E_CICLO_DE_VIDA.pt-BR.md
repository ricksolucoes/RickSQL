# Propriedade e ciclo de vida

> [Voltar ao índice da documentação](../README.pt-BR.md)


## Dataset retornado

O método `TRickSQL.Open` retorna um `TDataSet` desconectado. Internamente, `Rick.SQL.Core.Open.Executor` abre uma consulta real por meio de uma sessão FireDAC (`TRickSQLServiceFireDACSession`) e, em seguida, entrega o resultado a `Rick.SQL.Core.DataSet.Materializer`, que copia a estrutura de campos (`FieldDefs`) e todos os registros retornados para um `TFDMemTable` independente, criado sem `Owner` (`TFDMemTable.Create(nil)`).

Após o retorno de `Open`:

- a sessão FireDAC interna (query, conexão e contexto do driver) é liberada, no bloco `finally` do executor, antes do método retornar;
- o `TFDMemTable` retornado continua ativo e utilizável, pois seus dados já foram copiados para memória e ele não depende da conexão original.

## Responsabilidade de liberação — fachada `TRickSQL`

Na fachada `TRickSQL`, o chamador é o proprietário do dataset retornado e deve liberá-lo explicitamente:

```pascal
LDataSet := TRickSQL.Open(LCommand, LError);
try
  // uso do dataset
finally
  LDataSet.Free;
end;
```

Não libere o dataset antes de terminar o consumo dos dados. `LDataSet.Free` é seguro mesmo quando `LDataSet` é `nil` (semântica padrão de `TObject.Free` no Delphi).


## Lifecycle da API fluent `TRickSQLInterf`

`TRickSQLInterf.New` cria uma única instância stateful que implementa todas as interfaces `IRickSQL*`. Os métodos de navegação (`Command`, `Parameter`, `Option`, `Materialization`, `Back`, `Return`, `ToBack`, `Cursor` e `Result`) retornam interfaces para essa mesma instância; eles não criam um novo estado de comando.

O estado abaixo pertence à instância e permanece nela até ser explicitamente substituído/limpo ou até a destruição da façade:

| Estado | Inicialização | Alterado por | Após `Execute` | Após `Open` | `SQL(...)` limpa? | `Parameter.Clear` limpa? | Fim do lifetime |
|---|---|---|---|---|---|---|---|
| SQL | string vazia pelo estado zerado da instância | `SQL(...)` | persiste | persiste | substitui somente o próprio SQL | não | destruição da instância |
| parâmetros consolidados | array vazio | `Add`, `AddNull`, `AddVariant`, `Clear` | persistem | persistem | não | **sim** | destruição da instância ou `Clear` |
| parâmetro em construção | `Name=''`, `Value=Null`, `DataType=ftUnknown`, `Size=0`, `Direction=ptInput`, `IsNull=False` | `Name`, `Value`, `DataType`, `Size`, `Direction`, `IsNull`, `Default` | persiste se não tiver sido consolidado | persiste se não tiver sido consolidado | não | **não** | `Default`, `Add*` (que chama `Default`) ou destruição |
| opções de comando | `TimeOut=0`, `Transation=True`, `FetchAll=True`, `MaxRedord=0` | setters de `IRickSQLCommandOptions` | persistem | persistem | não | não | destruição da instância |
| opções de materialização | `Position=True`, `Preserve=True` | setters de `IRickSQLMaterializationOptions` | persistem | persistem | não | não | destruição da instância |
| opções de conexão | campos vazios/zero; engine inicialmente `Unknown`; extras vazios | `IRickSQLConnectionOptions` | persistem | persistem | não | não; `ClearConnectionParameter` limpa apenas extras | destruição da instância |
| erro/resultado | estado neutro (`Error=''`, `Success=False`, `RowsAffected=0`, erro estruturado vazio) | `Open`/`Execute` | substituído pelo resultado da execução | substituído pelo resultado da abertura | não | não | reiniciado no início da próxima operação e na destruição |
| dataset interno | `nil` | `Open` | ver regras de ownership abaixo | substituído pelo resultado do novo `Open` | não | não | depende de `Owner` |
| `Owner` | `True` | `Owner(Boolean)` | persiste | persiste | não | não | destruição da instância |

### `SQL(...)` não inicia um comando limpo

`SQL(const ASQL: string)` altera somente o texto em `FSQL`. Ele não limpa parâmetros consolidados, o parâmetro em construção, opções de comando, opções de materialização, opções de conexão, `Owner` ou o resultado anterior. O resultado anterior só é reiniciado quando `Open` ou `Execute` começa.

Para reutilizar a configuração existente, altere apenas o estado desejado. Para remover os parâmetros consolidados, use `.Command.Parameter.Clear`. Para um comando completamente independente, `TRickSQLInterf.New` é o mecanismo existente que cria um novo estado limpo; o construtor apenas inicializa campos/defaults e não abre conexão nem cria dataset. Não existe operação pública de reset total.

### `DataSet` retorna a referência interna

`IRickSQLResult.DataSet` apenas retorna `FDataSet`. O método não clona o dataset, não materializa novamente e não altera ownership. Portanto, a validade da referência depende do valor de `Owner` e das próximas operações executadas na mesma instância.

### `Owner(True)` — padrão

Com `Owner(True)`, a instância fluent mantém a responsabilidade de liberar o dataset atualmente armazenado em `FDataSet`:

- no início de qualquer próximo `Open` ou `Execute`, `ErrorDefault` chama `FreeAndNil(FDataSet)` quando existe dataset;
- o destrutor também chama `ErrorDefault`, portanto libera o dataset ainda armazenado;
- enquanto `Owner(True)` permanecer ativo, uma referência obtida por `Result.DataSet` é válida até a próxima chamada de `Open`/`Execute` ou até a destruição da instância, pois qualquer desses eventos libera o dataset armazenado;
- mudar para `Owner(False)` não invalida essa referência; a mudança transfere ao consumidor a responsabilidade pelo `Free` futuro;
- o consumidor não deve chamar `Free` nessa referência enquanto a instância continuar com `Owner(True)`, pois a façade ainda pretende liberá-la.

### `Owner(False)` — responsabilidade do consumidor

Com `Owner(False)`, `ErrorDefault` não libera `FDataSet`. A responsabilidade de cada dataset retornado por `Open` é do consumidor:

- um novo `Open` substitui `FDataSet` pela nova referência; o dataset anterior continua vivo, mas deixa de ser rastreado pela façade, por isso o consumidor precisa ter preservado sua própria referência para liberá-lo;
- `Execute` não atribui `FDataSet`; portanto, após `Open -> Execute`, `Result.DataSet` continua retornando o último dataset aberto enquanto `Owner(False)` estiver ativo;
- destruir a façade não libera o dataset que ainda estiver em `FDataSet`;
- o consumidor deve chamar `Free` exatamente uma vez para cada dataset que assumiu; a referência permanece válida até esse `Free`, mesmo que um novo `Open` já tenha removido o dataset anterior do rastreamento da façade.

`Owner(Boolean)` altera uma flag da instância, não uma propriedade `Owner` do `TComponent`. Se o valor for alterado depois de um `Open`, a política usada na próxima limpeza/destruição será o valor atual da flag. Datasets que já tenham sido substituídos por um novo `Open` enquanto `Owner(False)` estava ativo não voltam a ser rastreados pela façade.

Enquanto `Owner(False)` estiver ativo, a façade ainda mantém em `FDataSet` a referência do último `Open`; ela apenas deixa de ser responsável pelo `Free`. Se o consumidor liberar esse dataset antes de a referência interna ser substituída, `Result.DataSet` passa a apontar para um objeto já liberado. Nesse estado, não altere para `Owner(True)` antes de um novo `Open` substituir a referência, pois a próxima limpeza tentaria liberar novamente o ponteiro ainda armazenado. O padrão seguro é preservar a referência externa e liberar o dataset depois que a façade deixar de rastreá-lo ou depois de liberar a própria façade, como caracterizado pelos testes.

### Transições sucessivas com o ownership padrão

Com `Owner(True)`:

- `Open -> Open`: o primeiro dataset é liberado antes da segunda abertura; `DataSet` passa a apontar para o novo resultado;
- `Open -> Execute`: o dataset aberto é liberado antes da execução; como `Execute` não cria dataset, `DataSet` fica `nil`;
- `Execute -> Open`: `Execute` não cria dataset; o `Open` seguinte armazena o novo dataset;
- `Execute -> Execute`: não há dataset associado às execuções; `DataSet` permanece `nil`;
- parâmetros, opções de conexão, opções de comando, opções de materialização, SQL e `Owner` não são resetados por essas transições.

## Consulta vazia

Uma consulta sem registros não é tratada como erro. O retorno esperado é:

- `TDataSet` ativo, não `nil`;
- estrutura de campos disponível (a materialização exige que a query de origem tenha ao menos uma coluna — `FieldCount > 0` — caso contrário, é retornado erro de `TRickSQLErrorKind.DataSet`);
- `RecordCount = 0`;
- `TRickSQLError` vazio (`HasError = False`).

## Limite de registros e posicionamento

- Quando `TRickSQLCommandOptions.MaxRecords` é maior que zero, a materialização interrompe a cópia de linhas assim que o limite é atingido (`ShouldStopCopy`), mesmo que a consulta original possua mais registros.
- Quando `TRickSQLCommandOptions.Materialization.PositionAtFirstRecord` é `True` (valor padrão), o dataset materializado é posicionado no primeiro registro (`ADataSet.First`) antes de ser retornado ao chamador.
- Campos nulos na origem são copiados como nulos no destino (`ATarget.Fields[AIndex].Clear`), preservando a semântica de nulidade linha a linha.

## Sessão interna

A sessão FireDAC interna (`TRickSQLServiceFireDACSession`) mantém vivos, durante a execução de uma operação:

- o contexto do driver (`FDriverContext`, do tipo `TRickSQLServiceFireDACDriverContext`), responsável por manter o driver link ativo;
- a conexão (`FConnection: TFDConnection`);
- a query (`FQuery: TFDQuery`).

A ordem de liberação, no destrutor da sessão, é:

1. query (`FreeAndNil(FQuery)`);
2. conexão (`FreeAndNil(FConnection)`);
3. contexto do driver (`FreeAndNil(FDriverContext)`), que por sua vez libera o driver link internamente.

Essa ordem evita que a conexão ou a query tentem acessar um driver link já destruído durante a finalização.

## Conexão desconectada

O resultado de `Open` não depende da conexão ativa: como os dados já foram copiados para um `TFDMemTable` independente, o dataset retornado continua utilizável mesmo após a sessão FireDAC interna ter sido completamente liberada.

## Execute

O método `TRickSQL.Execute` não retorna dataset algum. Ele retorna `TRickSQLExecutionResult` (`Success`, `RowsAffected`, `Error`), um record de valor que não exige liberação manual — ele pertence ao escopo do chamador desde sua criação.

## Transações

Quando `TRickSQLCommandOptions.UseTransaction` está ativo (valor padrão `True`), `Rick.SQL.Core.Command.Executor` inicia uma transação (`TRickSQLServiceFireDACTransaction.Start`) antes de executar o comando, confirma (`Commit`) em caso de sucesso e desfaz (`Rollback`) em caso de falha, por meio de `RollbackAfterFailure`. Quando ocorre uma falha adicional durante o rollback, o detalhe técnico dessa falha é anexado ao detalhe técnico do erro original (com o prefixo "Falha adicional ao desfazer a transação:"), sem substituir a causa original.

Nenhuma transação deve permanecer aberta após o encerramento de um comando: `Commit` e `Rollback` verificam, após a chamada ao FireDAC, se a conexão realmente saiu do estado `InTransaction`; caso contrário, retornam erro estruturado (`TRickSQLErrorKind.Transaction`). Internamente, a leitura de `InTransaction` distingue estado ativo, estado inativo e falha de inspeção; uma exception nessa leitura é normalizada como erro transacional e não é interpretada como estado inativo.

O método `TRickSQLServiceFireDACTransaction.Active` mantém o contrato Boolean histórico para compatibilidade, inclusive retornando `False` quando a inspeção lança exception. Os fluxos internos de `Start`, `Commit`, `Rollback` e `RollbackAfterFailure` não dependem desse comportamento ambíguo.

## Memória e lifecycle

A suíte oficial não possui mais uma pasta separada `tests/memoria`. Os contratos de lifetime/ownership estão consolidados nas classes correspondentes em `tests/src/`: lifecycle fluent, materialização, services FireDAC, drivers/client library e transações.

A cobertura funcional valida criação/liberação de sessão, dataset materializado independente, ownership da API fluent, contexto/driver link e encerramento transacional. **Não foi executada ferramenta de detecção de memory leaks nesta tarefa**; portanto, não se declara ausência de vazamentos.

Consulte [Testes e homologação](../testes/TESTES_E_HOMOLOGACAO.pt-BR.md) e [Lifecycle, ownership e memória](../testes/TESTES_DE_MEMORIA.pt-BR.md).
