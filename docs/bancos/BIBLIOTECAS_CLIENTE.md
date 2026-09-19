# Client Libraries

> [Back to the documentation index](../README.md)

## Purpose

Some databases require a native client library before FireDAC can open a connection. RickSQL resolves these libraries internally through the `TRickSQLCoreClientLibraryResolver` class in `Rick.SQL.Core.ClientLibrary.Resolver`.

When the selected engine does not require a client library—for example, `SQLite`, whose driver definition declares no entries in `ClientLibraries`—the resolver succeeds immediately without performing any search.

## Resolution and `VendorLib` application

Client-library resolution and applying the resulting path to FireDAC are separate responsibilities:

```text
TRickSQLCoreClientLibraryResolver
        │
        ├── determines whether the engine requires a client library
        ├── locates and validates the applicable file
        └── produces the resolved path
                    ↓
TRickSQLServiceFireDACDriverVendorLibrary
        │
        └── applies the path to the DriverLink VendorLib property
```

`TRickSQLCoreClientLibraryResolver` remains responsible for the location policy. `VendorLib` application is centralized in `Rick.SQL.Service.FireDAC.Driver.VendorLibrary`, through `TRickSQLServiceFireDACDriverVendorLibrary`; this component does not search for files, validate PE binaries, or resolve providers.

The main `Driver.Context` flow and the compatible `TRickSQLCoreClientLibraryResolver.Configure` path delegate to this same canonical implementation. Providers that need to set a default `VendorLib` also use the same authority, avoiding independent assignment rules.

When the path received by the canonical implementation is empty, application is skipped and an existing `VendorLib` value is preserved. This allows engines that do not require a client library and configurations that depend on the driver's default mechanism to continue without a forced assignment.

The centralized responsibility is **applying** `VendorLib`; the external error classification still belongs to the calling flow. The compatible `Configure` path preserves `ClientLibrary` errors, while `Driver.Context` preserves the `Driver` classification.

## Search order

When a client library is required, resolution follows this order:

1. **Explicit path** — if `ClientLibraryPath` is set in `TRickSQLConnectionOptions`, the resolver normalizes the path (removing quotes, expanding environment variables, and resolving relative paths from the executable directory) and checks whether it points to an existing file or to a directory containing one of the expected libraries. If nothing is found, resolution stops with an error; an explicit path is not combined with the remaining sources.
2. **Executable directory** — when `ClientLibraryPath` is not supplied, the resolver searches for the expected libraries directly beside the consuming application's `.exe`.
3. **Framework conventional subdirectory** — the resolver searches `<executable directory>\RickSQL\libs\<Win32|Win64>` according to the running process architecture, followed by `<executable directory>\RickSQL\libs`.
4. **`PATH` environment variable** — each directory listed in `PATH` is inspected in the order in which it appears.
5. **Default driver/system lookup** — finally, the resolver uses the system API (`SearchPath`) to locate the library through the standard Windows search mechanisms (system directories, registered application-installation directories, and related locations).

If no source contains a compatible library, resolution fails with a structured `TRickSQLErrorKind.ClientLibrary` error.

## Explicit configuration

```pascal
LConnection.ClientLibraryPath := 'C:\Clientes\Firebird\fbclient.dll';
```

When a path is explicitly provided, it has absolute priority over all other search sources. If the specified file or directory does not contain a compatible library, resolution fails immediately without trying the remaining sources.

## Executable directory

The library can be placed beside the consuming application's `.exe`:

```text
MinhaAplicacao.exe
fbclient.dll
```

## Conventional subdirectory

The framework also searches its own folder convention beside the executable:

```text
MinhaAplicacao.exe
RickSQL\
  libs\
    Win64\
      fbclient.dll
    Win32\
      fbclient.dll
```

If no architecture-specific subfolder (`Win32` or `Win64`) exists, the resolver also searches directly under `RickSQL\libs`.

## Win32 and Win64 architecture

The located client library must match the runtime architecture of the executable (32-bit or 64-bit). The resolver inspects the candidate file's PE header (`IMAGE_FILE_HEADER.Machine`) to determine whether it is compatible with the current process architecture. When the architecture cannot be identified (a file without a recognized PE header), the candidate is considered compatible by default. When the architecture is identifiable and differs from the current process architecture, resolution fails with a structured error that identifies the file, detected architecture, and expected architecture.

## Client libraries by database

The table below lists the libraries declared by the providers. SQL Server, Oracle, DB2, SQL Anywhere, Informix, and ODBC have functional implementations only when `FULL_EDITION` is defined while compiling the consuming project. See [`BANCOS_SUPORTADOS.md`](BANCOS_SUPORTADOS.md).

| Database | Client library/libraries |
|---|---|
| Firebird | `fbclient.dll` |
| InterBase | `gds32.dll`, `ibtogo.dll`, `ibtogo64.dll` (in this preference order) |
| PostgreSQL | `libpq.dll` |
| SQL Server | `odbc32.dll` |
| MySQL | `libmysql.dll` |
| Oracle | `oci.dll` |
| DB2 | `db2cli.dll` |
| SQL Anywhere | `dbodbc17.dll`, `dbodbc16.dll`, `dbodbc12.dll` (the resolver tries these versions in this order) |
| Informix | `iclit09b.dll` |
| Advantage | `ace32.dll` (Win32) and `ace64.dll` (Win64) |
| Access | `ACEODBC.DLL` |
| ODBC | `odbc32.dll` |
| SQLite | no additional client library required |

## Behavior when a library cannot be found

The error is returned through `TRickSQLError` with `Kind = TRickSQLErrorKind.ClientLibrary`.

The framework's expected user-facing message when an explicit path cannot be found is shown below exactly as produced by the current implementation:

```text
O caminho informado para a biblioteca cliente do <banco> não foi localizado.
Verifique ClientLibraryPath: <caminho informado>.
```

The expected user-facing message when none of the standard search sources contains the library is likewise shown verbatim:

```text
A biblioteca cliente necessária para o <banco> não foi localizada.
Informe ClientLibraryPath ou disponibilize uma destas bibliotecas: <lista de bibliotecas>.
```

`TechnicalDetail` reports the libraries that were searched for, the executable directory, and the framework conventional directory used during resolution.

## What RickSQL does not do

The framework does not download, install, copy, or register libraries in the operating system. It locates libraries already present in the environment through the resolver and, when a path must be applied, delegates `VendorLib` configuration to the canonical `TRickSQLServiceFireDACDriverVendorLibrary` implementation.

Distribution of required client libraries remains the responsibility of the application that uses the framework.
