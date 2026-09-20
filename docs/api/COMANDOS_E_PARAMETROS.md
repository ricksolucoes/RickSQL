# Commands and Parameters

> [Back to the documentation index](../README.md)

## Creating a command

An SQL command is represented by the `TRickSQLCommand` record, created through the facade:

```pascal
LCommand := TRickSQL.Command(
  LConnection,
  'select * from vendas where empresa_id = :EMPRESA_ID'
);
```

Internally, `TRickSQL.Command` calls `TRickSQLCommand.Create(AConnection, ASQL)`, which associates the supplied connection options, SQL text, an empty parameter list, and the default command options (`TRickSQLCommandOptions.CreateDefault`).

## Parameters

Parameters are represented by the `TRickSQLParameter` record and added to a command through `TRickSQLCommand.AddParameter`:

```pascal
procedure TRickSQLCommand.AddParameter(const AParameter: TRickSQLParameter);
```

`AddParameter` always receives a fully constructed `TRickSQLParameter`; there is no overload that accepts a name and value directly. Use the static methods on `TRickSQLParameter` itself to create a parameter:

```pascal
LCommand.AddParameter(TRickSQLParameter.Create('EMPRESA_ID', 10));
```

`TRickSQLParameter.Create(AName, AValue)` sets `Name`, `Value`, `DataType := ftUnknown`, `Size := 0`, `Direction := ptInput`, and derives `IsNull` automatically from the supplied value (true when the received `Variant` is null or empty).

Values are never concatenated into the SQL text. They are bound as named parameters by the internal binder (`Rick.SQL.Service.FireDAC.Parameter.Binder`) at execution time.

## Null values

To send `Null` explicitly, use the static `TRickSQLParameter.CreateNull` constructor, which requires a field type (`TFieldType`):

```pascal
LCommand.AddParameter(TRickSQLParameter.CreateNull('DATA_CANCELAMENTO', ftDateTime));
```

`CreateNull` sets `Value := Null`, `IsNull := True`, and assigns the supplied type to `DataType`. The parameter validator (`Rick.SQL.Core.Parameter.Validator`) requires every parameter marked as null to have a `DataType` other than `ftUnknown`; otherwise validation fails before execution.

## Supported data types

The parameter binder and validator handle FireDAC field types (`TFieldType`) grouped into the following families:

- text: `ftString`, `ftMemo`, `ftFmtMemo`, `ftFixedChar`, `ftWideString`, `ftOraClob`, `ftFixedWideChar`, `ftWideMemo`, `ftGuid`;
- numeric: `ftSmallint`, `ftInteger`, `ftWord`, `ftFloat`, `ftCurrency`, `ftBCD`, `ftAutoInc`, `ftLargeint`, `ftFMTBcd`, `ftLongWord`, `ftShortint`, `ftByte`, `ftExtended`;
- Boolean: `ftBoolean`;
- date/time: `ftDate`, `ftTime`, `ftDateTime`, `ftTimeStamp`, `ftOraTimeStamp`;
- binary/BLOB types, when applicable (`ftBytes`, `ftVarBytes`, `ftBlob`, `ftGraphic`, `ftOraBlob`, and other types that accept the `Size` property).

Types that represent complex structures (`ftCursor`, `ftADT`, `ftArray`, `ftReference`, `ftDataSet`, `ftInterface`, `ftIDispatch`, `ftConnection`, `ftParams`) are not supported as command parameters and are rejected by the validator.

When `DataType` is left as `ftUnknown` (the default value used by `TRickSQLParameter.Create`), the validator does not perform value/type compatibility checks.

## Parameter validation rules

Before execution, `Rick.SQL.Core.Parameter.Validator` applies the following checks in this order:

1. **Names** — every parameter must have a non-empty name that starts with a letter or `_` and contains only letters, numbers, `_`, or `$`; duplicate names are rejected case-insensitively.
2. **Definition** — `Size` cannot be negative; a `Size` greater than zero is accepted only for types that support a size (text and BLOB types); `Direction` must be `ptInput` (output and input/output parameters are not supported yet); `DataType` must be a supported type; a parameter marked as null must specify `DataType`; and a parameter not marked as null cannot carry a `Null` or empty value.
3. **Value compatibility** — when `DataType` is known, the value must be compatible with its type family (string, numeric, Boolean, or date/time).
4. **Required parameters** — the SQL text is scanned internally by a lexical scanner that receives the command's `TRickSQLDatabaseEngine`. The scanner recognizes `:NAME` markers only when the `:` character does not belong to a literal, comment, delimited identifier, or engine-specific syntax recognized by the framework. Names found more than once in the SQL are consolidated case-insensitively; every identified name must have a corresponding parameter added to the command, otherwise validation fails before the FireDAC session/connection is created.

## Engine-aware lexical parameter identification

The scanner is not a complete SQL parser and it does not translate dialects. Its narrower responsibility is to distinguish RickSQL `:NAME` markers from `:` occurrences that belong to known lexical constructs of the engines represented by `TRickSQLDatabaseEngine`.

Common rules continue to recognize single- and double-quoted strings, doubled-quote escaping, `--` and `/* */` comments, the `::` operator, and `:=` as an occurrence that does not start a parameter. Additional rules are applied only when the selected engine requires the distinction:

| Engine | Constructs considered while identifying parameters |
|---|---|
| `PostgreSQL` | `E'...'` strings, dollar-quoted strings (`$$...$$` and `$tag$...$tag$`), nested block comments, and `:` in array slices |
| `Firebird` | alternative quoting `q'...'`, array bounds, and variables/labels inside PSQL bodies after `BEGIN` |
| `InterBase` | array-slice bounds and variables inside PSQL bodies after `BEGIN` |
| `SQLServer` | `[...]` identifiers, labels, nested block comments, and the `:` separator in `JSON_OBJECT` |
| `MySQL` | backtick identifiers, `#` comments, backslash escaping in strings, MySQL's `--` comment rule, and structured labels |
| `SQLite` | `[...]` and backtick identifiers |
| `Oracle` | alternative quoting `q'...'`/`nq'...'`, the `:` separator in `JSON_OBJECT`, and `:NEW`, `:OLD`, and `:PARENT` pseudorecords |
| `DB2` | structured labels recognized by the scanner |
| `SQLAnywhere` | `[...]` and backtick identifiers, `//` comments, nested block comments, and structured labels |
| `Informix` | `:` used in database/catalog qualification, including qualified references |
| `Access` | `[...]` identifiers |
| `Advantage`, `ODBC` | use the common lexical rules; the current scanner has no additional `:` rule for these enum values |

Identification still occurs before FireDAC receives the command for `Prepare`. FireDAC remains responsible for preparing/executing the query and binding the parameters that have already been validated; it is not used as the source of truth for discovering required parameters at this stage. In particular, `ODBC` does not identify the DBMS behind the driver, so the scanner does not attempt to infer an underlying ODBC dialect.

## Query with `Open`

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

## Command with `Execute`

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

## Missing parameters

When the SQL contains a parameter marker with no corresponding value, the framework returns a structured error before attempting to execute anything against the database.

Example:

```sql
select * from clientes where id = :ID
```

If `ID` is not added to the command through `AddParameter`, validation fails with a message that identifies the missing required parameter.

## Security rules

Never build SQL by concatenating values received from users.

Incorrect:

```pascal
LSQL := 'select * from clientes where nome = ''' + LNome + '''';
```

Correct:

```pascal
LSQL := 'select * from clientes where nome = :NOME';
LCommand := TRickSQL.Command(LConnection, LSQL);
LCommand.AddParameter(TRickSQLParameter.Create('NOME', LNome));
```

## Command options

`TRickSQLCommand.Options`, of type `TRickSQLCommandOptions`, is initialized with the following defaults when a command is created:

| Field | Default | Description |
|---|---|---|
| `CommandTimeout` | `0` | command timeout; zero uses the driver's default |
| `UseTransaction` | `True` | determines whether `Execute` wraps the command in a transaction |
| `FetchAll` | `True` | when `True` and `MaxRecords <= 0`, asks the source dataset to complete fetching explicitly before copying when that capability is available; when `False`, that explicit prefetch request is skipped |
| `MaxRecords` | `0` | maximum number of rows; zero means no limit |
| `Materialization.PositionAtFirstRecord` | `True` | positions the materialized dataset on the first record |
| `Materialization.PreserveFieldMetadata` | `True` | when `True`, copies available presentation/validation metadata from the source dataset to the materialized fields (`Alignment`, `DisplayLabel`, `DisplayWidth`, `Visible`, `EditMask`, `Required`, and `DisplayFormat` for numeric fields) |

These fields can be adjusted directly before calling `Open` or `Execute`, for example: `LCommand.Options.CommandTimeout := 30;`.

`FetchAll := False` does not impose a record limit, enable lazy/streaming reads, or keep the query connected. Materialization still iterates over the source dataset until `Eof` unless `MaxRecords > 0`; the difference is only that no explicit prefetch is requested before copying. When `MaxRecords > 0`, that explicit prefetch is not requested regardless of `FetchAll`, and `MaxRecords` controls how many rows are materialized. The result of `Open` remains an in-memory dataset independent of the source query, connection, and session. Likewise, `PreserveFieldMetadata := False` does not remove the field structure (`FieldDefs`) required by `TFDMemTable`; it only prevents the additional metadata listed above from being copied.
