# Propriedade e ciclo de vida

> [Voltar ao índice da documentação](../README.pt-BR.md)


## Dataset retornado

O método `TRickSQL.Open` retorna um `TDataSet` desconectado. Internamente, `Rick.SQL.Core.Open.Executor` abre uma consulta real por meio de uma sessão FireDAC (`TRickSQLServiceFireDACSession`) e, em seguida, entrega o resultado a `Rick.SQL.Core.DataSet.Materializer`, que copia a estrutura de campos (`FieldDefs`) e todos os registros retornados para um `TFDMemTable` independente, criado sem `Owner` (`TFDMemTable.Create(nil)`).

Após o retorno de `Open`:

- a sessão FireDAC interna (query, conexão e contexto do driver) é liberada, no bloco `finally` do executor, antes do método retornar;
- o `TFDMemTable` retornado continua ativo e utilizável, pois seus dados já foram copiados para memória e ele não depende da conexão original.

## Responsabilidade de liberação

O chamador é o proprietário do dataset retornado e deve liberá-lo explicitamente:

```pascal
LDataSet := TRickSQL.Open(LCommand, LError);
try
  // uso do dataset
finally
  LDataSet.Free;
end;
```

Não libere o dataset antes de terminar o consumo dos dados. `LDataSet.Free` é seguro mesmo quando `LDataSet` é `nil` (semântica padrão de `TObject.Free` no Delphi).

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

## Memória

Os testes de memória, localizados em `tests/memoria`, validam:

- criação e destruição repetida de sessão;
- materialização e liberação do dataset retornado por `Open`;
- arrays de parâmetros (`TRickSQLParameterArray`) com crescimento dinâmico;
- erros internos convertidos para `TRickSQLError`;
- transações (início, commit e rollback);
- driver link e contexto do driver.

Consulte [`TESTES_E_HOMOLOGACAO.md`](../testes/TESTES_E_HOMOLOGACAO.pt-BR.md) para o detalhamento dos cenários de teste.
