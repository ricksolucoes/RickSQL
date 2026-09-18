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
4. **Required parameters** — the SQL text is scanned internally (while respecting single- and double-quoted literals, `--` line comments, `/* */` block comments, and PostgreSQL's `::` cast operator, as in `coluna::integer`) to identify every `:NAME` marker. Each marker must have a corresponding parameter added to the command; otherwise validation fails before any real database execution.

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
| `FetchAll` | `True` | when `True` and `MaxRecords <= 0`, attempts to call `FetchAll` on the source dataset through RTTI before copying; when `False`, that explicit prefetch is skipped |
| `MaxRecords` | `0` | maximum number of rows; zero means no limit |
| `Materialization.PositionAtFirstRecord` | `True` | positions the materialized dataset on the first record |
| `Materialization.PreserveFieldMetadata` | `True` | when `True`, copies available presentation/validation metadata from the source dataset to the materialized fields (`Alignment`, `DisplayLabel`, `DisplayWidth`, `Visible`, `EditMask`, `Required`, and `DisplayFormat` for numeric fields) |

These fields can be adjusted directly before calling `Open` or `Execute`, for example: `LCommand.Options.CommandTimeout := 30;`.

`FetchAll := False` does not impose a record limit. Materialization still iterates over the source dataset until `Eof` unless `MaxRecords > 0`; the difference is that the explicit call to the source dataset's `FetchAll` method is skipped. Likewise, `PreserveFieldMetadata := False` does not remove the field structure (`FieldDefs`) required by `TFDMemTable`; it only prevents the additional metadata listed above from being copied.
