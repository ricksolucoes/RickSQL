# Error Handling

> [Back to the documentation index](../README.md)

## Main type

Errors are represented by the `TRickSQLError` record declared in `Rick.SQL.Model.Error`:

| Field | Type | Description |
|---|---|---|
| `Kind` | `TRickSQLErrorKind` | error category |
| `Message` | `string` | user-facing message controlled by the framework, in Brazilian Portuguese |
| `TechnicalDetail` | `string` | technical detail that may preserve the original FireDAC or database message |
| `DBMSCode` | `Integer` | database error code, when available |
| `SQLState` | `string` | SQLSTATE extracted from the first FireDAC error when the concrete error type exposes it; the current implementation handles `TFDIBError`, `TFDMySQLError`, and, under `FULL_EDITION`, `TFDODBCNativeError` |
| `Operation` | `string` | operation in which the error occurred (for example, `"Abertura da consulta FireDAC"`) |
| `HasError` | `Boolean` | indicates whether the record represents an actual error |

`TRickSQLError.Empty` returns an empty error (`Kind = None`, `HasError = False`) and is used as the initial value for operations. `TRickSQLError.Create(AKind, AMessage)` creates an error and sets `HasError` automatically to `AKind <> TRickSQLErrorKind.None`.

## Categories (`TRickSQLErrorKind`)

```text
None, Validation, UnsupportedDatabase, Driver, ClientLibrary,
Connection, Command, Parameter, Transaction, DataSet, Unexpected
```

In flows that use `Rick.SQL.Core.Error.Parser`, each category is mapped to a fixed user-facing message controlled by the framework. The parser retains that contextual responsibility and delegates technical normalization to the shared `Rick.SQL.Error.Normalizer` component under `src/error`. The strings below are shown exactly as produced by the current implementation and therefore remain in Brazilian Portuguese:

| Category | Framework message (pt-BR) |
|---|---|
| `Validation` | Os dados informados para a operação SQL são inválidos. Revise as opções, o SQL e os parâmetros. |
| `UnsupportedDatabase` | O banco de dados informado não é suportado pelo RickSQL. Selecione um mecanismo disponível no enum. |
| `Driver` | Não foi possível configurar o driver do banco de dados. Verifique o mecanismo e a biblioteca cliente. |
| `ClientLibrary` | A biblioteca cliente necessária para o banco de dados não foi localizada. Informe ClientLibraryPath ou coloque a biblioteca no diretório da aplicação. |
| `Connection` | Não foi possível estabelecer conexão com o banco de dados. Verifique o servidor, a porta, o banco informado e as credenciais de acesso. |
| `Command` | Não foi possível executar o comando SQL informado. Verifique a sintaxe e os parâmetros. |
| `Parameter` | Não foi possível aplicar os parâmetros do comando SQL. Verifique nomes, tipos e valores informados. |
| `Transaction` | Não foi possível concluir a transação do banco de dados. Verifique o estado da conexão e tente novamente. |
| `DataSet` | Não foi possível preparar o conjunto de dados retornado pela consulta. Verifique os campos retornados pelo SQL. |
| `Unexpected` (or any other unmapped category) | Ocorreu uma falha inesperada durante a operação SQL. Verifique o detalhe técnico e tente novamente. |

Validation errors (`Rick.SQL.Core.Connection.Validator`, `Rick.SQL.Core.Command.Validator`, `Rick.SQL.Core.Parameter.Validator`) do not use that fixed table. They build user-facing messages directly for each violated rule, such as `"O comando SQL não foi informado."` or `"A porta deve estar entre 1 e 65535 ou permanecer com o valor zero."`.

## Shared normalization

`Rick.SQL.Error.Normalizer`, physically located at `src/error/Rick.SQL.Error.Normalizer.pas`, is the shared authority for turning an exception into the technical data of a `TRickSQLError`. The component that captures the failure remains responsible for functional context (`Kind`, `Message`, and `Operation`); the normalizer does not know specific services or business operations.

For flows routed through the normalizer, it centralizes `TechnicalDetail` extraction and treatment, sanitization of textual error surfaces, and extraction of structured FireDAC metadata. `Rick.SQL.Core.Error.Parser` remains responsible for the fixed user-facing messages used by core flows and delegates shared normalization to this component.

## Technical detail

`TechnicalDetail` may preserve the original FireDAC or database message (`EFDDBEngineException.Errors[0].Message`, when available, or `Exception.Message` as a fallback). This content may appear in another language because it is produced by an external vendor and should be used only for technical diagnostics, never as the primary message shown to an end user. When no detail is available, the normalizer fills `TechnicalDetail` with the fixed string `"Nenhum detalhe técnico foi informado."`.

## Database code (`DBMSCode`)

When the normalized exception is an `EFDDBEngineException` with at least one entry in `Errors`, `DBMSCode` is populated from `Errors[0].ErrorCode`. Otherwise, it remains `0`.

## Security and credential masking

The shared normalizer masks, in `Message` and `TechnicalDetail` values processed by it, values associated with the following keys (case-insensitive comparison): `Password=`, `PWD=`, `Pass=`, `Senha=`, `User Password=`, `User_Password=`. The value after the key, up to the next delimiter (`;`, `,`, or line break), is replaced with `***`.

Example technical detail after masking:

```text
Server=meuservidor;Database=erp;User=admin;Password=***;
```

## Errors from `Open`

When `TRickSQL.Open` fails:

- the return value is `nil`;
- `TRickSQLError` (the `out AError` parameter) is populated with the category corresponding to the stage that failed (validation, driver resolution, client library, connection, command, or dataset);
- no exception should escape the public API; internal stages catch exceptions and convert them into `TRickSQLError` values.

## Errors from `Execute`

When `TRickSQL.Execute` fails:

- `TRickSQLExecutionResult.Success = False`;
- `RowsAffected` is always `0` on failure (`TRickSQLExecutionResult.Failed`) and must not be used as the error indicator; use `Success` and `Error.HasError` instead;
- `Error` contains the structured failure.

## Rollback errors

If an additional error occurs while rolling back after a command failure, the technical detail from that additional failure is appended to the original error's `TechnicalDetail` using the literal prefix `"Falha adicional ao desfazer a transação:"`. The original cause is preserved rather than overwritten.

## Recommended usage

```pascal
LDataSet := TRickSQL.Open(LCommand, LError);
if not Assigned(LDataSet) then
begin
  Writeln(LError.Message);
  Writeln(LError.TechnicalDetail);
end;
```

In visual interfaces, the consuming application decides how to present `LError.Message` to the end user. RickSQL does not display windows, dialog boxes, or notifications; it only returns structured data.
