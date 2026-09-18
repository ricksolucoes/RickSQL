# Comandos e parâmetros

> [Voltar ao índice da documentação](../README.pt-BR.md)


## Criação de comando

Um comando SQL é representado pelo record `TRickSQLCommand`, criado pela fachada:

```pascal
LCommand := TRickSQL.Command(
  LConnection,
  'select * from vendas where empresa_id = :EMPRESA_ID'
);
```

Internamente, `TRickSQL.Command` chama `TRickSQLCommand.Create(AConnection, ASQL)`, que associa as opções de conexão informadas, o texto SQL, uma lista de parâmetros vazia e as opções padrão de comando (`TRickSQLCommandOptions.CreateDefault`).

## Parâmetros

Os parâmetros são representados pelo record `TRickSQLParameter` e aplicados ao comando por meio do método `AddParameter` de `TRickSQLCommand`:

```pascal
procedure TRickSQLCommand.AddParameter(const AParameter: TRickSQLParameter);
```

`AddParameter` recebe sempre um `TRickSQLParameter` já construído — não existe sobrecarga que receba nome e valor diretamente. Para criar o parâmetro, utilize os métodos estáticos do próprio `TRickSQLParameter`:

```pascal
LCommand.AddParameter(TRickSQLParameter.Create('EMPRESA_ID', 10));
```

`TRickSQLParameter.Create(AName, AValue)` define `Name`, `Value`, `DataType := ftUnknown`, `Size := 0`, `Direction := ptInput` e calcula `IsNull` automaticamente a partir do valor informado (verdadeiro quando o `Variant` recebido é nulo ou vazio).

Os valores nunca são concatenados ao texto SQL: eles são aplicados como parâmetros nomeados pelo binder interno (`Rick.SQL.Service.FireDAC.Parameter.Binder`) no momento da execução.

## Valores nulos

Para enviar `Null` explicitamente, utilize o construtor estático `TRickSQLParameter.CreateNull`, que exige a informação do tipo de campo (`TFieldType`):

```pascal
LCommand.AddParameter(TRickSQLParameter.CreateNull('DATA_CANCELAMENTO', ftDateTime));
```

`CreateNull` define `Value := Null`, `IsNull := True` e preenche `DataType` com o tipo informado. O validador de parâmetros (`Rick.SQL.Core.Parameter.Validator`) exige que todo parâmetro marcado como nulo possua um `DataType` diferente de `ftUnknown`; caso contrário, a validação falha antes da execução.

## Tipos de dado suportados

O binder de parâmetros e o validador tratam os campos do FireDAC (`TFieldType`) organizados nas seguintes famílias:

- textuais: `ftString`, `ftMemo`, `ftFmtMemo`, `ftFixedChar`, `ftWideString`, `ftOraClob`, `ftFixedWideChar`, `ftWideMemo`, `ftGuid`;
- numéricos: `ftSmallint`, `ftInteger`, `ftWord`, `ftFloat`, `ftCurrency`, `ftBCD`, `ftAutoInc`, `ftLargeint`, `ftFMTBcd`, `ftLongWord`, `ftShortint`, `ftByte`, `ftExtended`;
- booleano: `ftBoolean`;
- data e hora: `ftDate`, `ftTime`, `ftDateTime`, `ftTimeStamp`, `ftOraTimeStamp`;
- binários/BLOB, quando aplicável ao tipo (`ftBytes`, `ftVarBytes`, `ftBlob`, `ftGraphic`, `ftOraBlob`, entre outros que aceitam a propriedade `Size`).

Tipos que representam estruturas complexas (`ftCursor`, `ftADT`, `ftArray`, `ftReference`, `ftDataSet`, `ftInterface`, `ftIDispatch`, `ftConnection`, `ftParams`) não são suportados como parâmetro e são rejeitados pelo validador.

Quando `DataType` é deixado como `ftUnknown` (valor padrão de `TRickSQLParameter.Create`), o validador não aplica verificação de compatibilidade de tipo sobre o valor informado.

## Regras de validação de parâmetros

Antes da execução, `Rick.SQL.Core.Parameter.Validator` aplica, nesta ordem:

1. **Nomes** — cada parâmetro deve ter um nome não vazio, iniciado por letra ou `_` e composto apenas por letras, números, `_` ou `$`; nomes duplicados (sem diferenciar maiúsculas de minúsculas) são rejeitados.
2. **Definição** — `Size` não pode ser negativo; um `Size` maior que zero só é aceito para tipos que suportam tamanho (textuais e BLOB); `Direction` deve ser `ptInput` (parâmetros de saída ou entrada/saída ainda não são suportados); o `DataType` deve ser um tipo suportado; um parâmetro marcado como nulo deve informar `DataType`; um parâmetro não marcado como nulo não pode carregar um valor `Null` ou vazio.
3. **Compatibilidade de valor** — quando `DataType` é conhecido, o valor deve ser compatível com a família do tipo (string, numérico, booleano ou data/hora).
4. **Parâmetros obrigatórios** — o texto SQL é varrido internamente (respeitando literais entre aspas simples e duplas, comentários de linha `--`, comentários de bloco `/* */` e o operador de cast `::` do PostgreSQL, como em `coluna::integer`) para identificar todos os marcadores `:NOME` presentes; cada marcador precisa ter um parâmetro correspondente adicionado ao comando, caso contrário a validação falha antes de qualquer execução real.

## Consulta com Open

```pascal
LDataSet := TRickSQL.Open(LCommand, LError);
try
  if not Assigned(LDataSet) then
  begin
    Writeln(LError.Message);
    Exit;
  end;

  while not LDataSet.Eof do
  begin
    Writeln(LDataSet.FieldByName('NOME').AsString);
    LDataSet.Next;
  end;
finally
  LDataSet.Free;
end;
```

## Comando com Execute

```pascal
LCommand := TRickSQL.Command(
  LConnection,
  'update clientes set ativo = :ATIVO where id = :ID'
);

LCommand.AddParameter(TRickSQLParameter.Create('ATIVO', True));
LCommand.AddParameter(TRickSQLParameter.Create('ID', 15));

LResult := TRickSQL.Execute(LCommand);
if not LResult.Success then
  Writeln(LResult.Error.Message);
```

## Parâmetros não localizados

Quando o SQL possuir um marcador de parâmetro sem valor correspondente, o framework retorna erro estruturado antes de qualquer tentativa de execução no banco.

Exemplo:

```sql
select * from clientes where id = :ID
```

Se `ID` não for adicionado ao comando por `AddParameter`, a validação falhará com uma mensagem indicando o nome do parâmetro obrigatório ausente.

## Regras de segurança

Nunca monte o SQL concatenando valores recebidos do usuário.

Errado:

```pascal
LSQL := 'select * from clientes where nome = ''' + LNome + '''';
```

Correto:

```pascal
LSQL := 'select * from clientes where nome = :NOME';
LCommand := TRickSQL.Command(LConnection, LSQL);
LCommand.AddParameter(TRickSQLParameter.Create('NOME', LNome));
```

## Opções do comando

`TRickSQLCommand.Options`, do tipo `TRickSQLCommandOptions`, é preenchido com os valores padrão a seguir na criação do comando:

| Campo | Valor padrão | Descrição |
|---|---|---|
| `CommandTimeout` | `0` | tempo limite do comando; zero usa o padrão do driver |
| `UseTransaction` | `True` | indica se `Execute` deve envolver o comando em uma transação |
| `FetchAll` | `True` | quando `True` e `MaxRecords <= 0`, tenta chamar `FetchAll` no dataset de origem via RTTI antes da cópia; quando `False`, essa pré-busca explícita é omitida |
| `MaxRecords` | `0` | quantidade máxima de registros; zero significa sem limite |
| `Materialization.PositionAtFirstRecord` | `True` | posiciona o dataset materializado no primeiro registro |
| `Materialization.PreserveFieldMetadata` | `True` | quando `True`, copia para os campos materializados metadados de apresentação/validação disponíveis no dataset de origem (`Alignment`, `DisplayLabel`, `DisplayWidth`, `Visible`, `EditMask`, `Required` e `DisplayFormat` de campos numéricos) |

Esses campos podem ser ajustados diretamente antes de chamar `Open` ou `Execute`, por exemplo: `LCommand.Options.CommandTimeout := 30;`.

`FetchAll := False` não define um limite de registros. A materialização continua percorrendo o dataset de origem até `Eof`, salvo quando `MaxRecords > 0`; a diferença é que a chamada explícita ao método `FetchAll` do dataset de origem é evitada. `PreserveFieldMetadata := False` também não elimina a estrutura de campos (`FieldDefs`) necessária ao `TFDMemTable`; ele apenas deixa de copiar os metadados adicionais listados acima.
