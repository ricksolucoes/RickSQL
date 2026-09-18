# 🗄️ RickSQL

<p align="center">
  <strong>Delphi SQL execution layer with encapsulated drivers, connections, materialization, and errors.</strong>
</p>

<p align="center">
  <a href="https://docwiki.embarcadero.com/RADStudio/en/Delphi_Language_Guide_Index">
    <img src="https://img.shields.io/badge/Language-Object%20Pascal-5C2D91?style=for-the-badge&logo=delphi&logoColor=white" alt="Object Pascal">
  </a>
  <a href="https://www.embarcadero.com/products/delphi">
    <img src="https://img.shields.io/badge/IDE-Delphi-E62431?style=for-the-badge&logo=delphi&logoColor=white" alt="IDE Delphi">
  </a>
  <a href="https://docwiki.embarcadero.com/RADStudio/en/FireMonkey_Application_Platform">
    <img src="https://img.shields.io/badge/UI-FireMonkey/VCL-2563EB?style=for-the-badge" alt="FireMonkey">
  </a>
</p>

<p align="center">
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-Revocable%20Software%20License-8250DF?style=flat-square" alt="License">
  </a>
  <img src="https://img.shields.io/badge/Owner-RickSolu%C3%A7%C3%B5es-1F6FEB?style=flat-square" alt="RickSoluções">
  <img src="https://img.shields.io/badge/Platform-Multiplataforma-0078D4?style=flat-square&logo=windows&logoColor=white" alt="Multiplataforma">
</p>

<p align="center">
  🇺🇸 English | 🇧🇷 <a href="README.pt-BR.md">Português (Brasil)</a>
</p>

## ✨ Overview

`RickSQL` is a Delphi framework for executing SQL commands on top of FireDAC. The application provides the database engine, connection options, and command; the framework internally resolves the provider, `DriverID`, driver link, default port, client library, FireDAC session, parameters, transaction, materialization, and conversion of failures into structured errors.

The project provides two public usage styles:

- **`Rick.SQL` / `TRickSQL`** — the primary, direct, record-oriented facade;
- **`Rick.SQL.Interf` / `TRickSQLInterf`** — a complementary fluent API based on interfaces.

The core does not create forms or display visual messages. The consuming application decides how to present results and errors.

## ⚙️ Installation

*Optional*

> For convenience, I recommend using [**Boss**](https://github.com/HashLoad/boss) (a dependency manager for Delphi). Run the command below in a terminal such as Windows PowerShell:

```sh
boss install github.com/ricksolucoes/RickSQL
```

## 🎫 Manual installation for Delphi

If you prefer a manual installation, add the following folders to your project under **Project > Options > Building > Delphi Compiler > Search path**:

```text
RickSQL\src
RickSQL\src\model
RickSQL\src\error
RickSQL\src\core
RickSQL\src\services
RickSQL\src\services\drivers
```

Minimal SQLite example:

```pascal
uses
  System.SysUtils,
  Data.DB,
  Rick.SQL;

var
  LConnection: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
  LDataSet: TRickSQLDataSet;
begin
  LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  LConnection.Database := 'C:\Dados\teste.db';

  LCommand := TRickSQL.Command(LConnection, 'select * from clientes');
  LDataSet := TRickSQL.Open(LCommand, LError);
  try
    if not Assigned(LDataSet) then
      Writeln(LError.Message)
    else
      Writeln('Registros: ', LDataSet.RecordCount);
  finally
    LDataSet.Free;
  end;
end.
```

`TRickSQLDataSet` is a public alias for `Data.DB.TDataSet`. The dataset returned by `TRickSQL.Open` is materialized in memory and is owned by the caller.

## 🗄️ Supported databases

The `TRickSQLDatabaseEngine` enum has providers for thirteen database engines:

| Availability | Engines |
|---|---|
| Default | SQLite, Firebird, InterBase, PostgreSQL, MySQL, Advantage, Access |
| Requires `FULL_EDITION` | SQL Server, Oracle, DB2, SQL Anywhere, Informix, ODBC |

The presence of a provider in the factory does not eliminate external dependencies: some databases require a native client library, a server, or environment-specific configuration.

See [Supported databases](docs/bancos/BANCOS_SUPORTADOS.md) and [Client libraries](docs/bancos/BIBLIOTECAS_CLIENTE.md) for ports, `DriverID` values, required fields, and expected libraries.

## 🔌 Usage styles

### `TRickSQL`

The `Rick.SQL` facade exposes four primary operations:

```pascal
TRickSQL.ConnectionOptions(...);
TRickSQL.Command(...);
TRickSQL.Open(...);
TRickSQL.Execute(...);
```

`Open` returns a disconnected `TDataSet`, or `nil` with a populated `TRickSQLError`. `Execute` returns a `TRickSQLExecutionResult` containing `Success`, `RowsAffected`, and `Error`.

### `TRickSQLInterf`

The `Rick.SQL.Interf` unit provides a complementary fluent API:

```pascal
LRick := TRickSQLInterf.New
  .ConnectionOptions
    .Engine(TRickSQLDatabaseEngine.SQLite)
    .Database('C:\Dados\teste.db')
  .Back
  .Command
    .SQL('select * from clientes')
  .Back
  .Cursor
    .Open
  .Back;
```

The complete reference for both public surfaces, including `IRickSQL*`, ownership, parameters, and instance reuse, is available in [Public API](docs/api/API_PUBLICA.md).

## ⚙️ Compiler directives

### `CONSOLE_CONNECTION`

Console projects must define `CONSOLE_CONNECTION` in the compiler options (**Project > Options > Delphi Compiler > Conditional defines**) or through `-D`. The symbol is read inside `Rick.SQL.Core.ClientLibrary.Resolver`, so an isolated `{$DEFINE ...}` in the `.dpr` does not propagate to separately compiled units.

When the symbol is defined, the resolver uses `FireDAC.ConsoleUI.Wait`; otherwise, it uses `FireDAC.FMXUI.Wait`. This does not turn the framework into a visual component: the selection exists solely for FireDAC's wait mechanism.

### `FULL_EDITION`

Enables the functional implementations of the SQL Server, Oracle, DB2, SQL Anywhere, Informix, and ODBC providers. Without the symbol, those providers remain registered in the factory but reject configuration/validation and report that `FULL_EDITION` is required.

See the [Integration guide](docs/integracao/GUIA_DE_INTEGRACAO.md) for full configuration details.

## 📦 Project structure

```text
RickSQL/
├── README.md
├── README.pt-BR.md
├── LICENSE
├── LICENSE-pt-BR
├── src/       # Delphi implementation and contracts
├── NewTests/  # official suite for new refactorings: DUnit + GUI Test Runner
├── tests/     # legacy compilation, unit, integration, memory, and concurrency suite
├── samples/   # executable examples
└── docs/      # centralized technical documentation
```

Detailed documentation is not distributed across `tests` and `samples`; the canonical English index is [`docs/README.md`](docs/README.md).

## 📚 Documentation

| Area | Document |
|---|---|
| Getting started | [Integration guide](docs/integracao/GUIA_DE_INTEGRACAO.md) |
| Examples | [Usage examples](docs/integracao/EXEMPLOS_DE_USO.md) |
| API | [Public API](docs/api/API_PUBLICA.md) |
| Connection | [Connection options](docs/api/OPCOES_DE_CONEXAO.md) |
| Commands | [Commands and parameters](docs/api/COMANDOS_E_PARAMETROS.md) |
| Lifetime | [Ownership and lifetime](docs/api/PROPRIEDADE_E_CICLO_DE_VIDA.md) |
| Errors | [Error handling](docs/api/TRATAMENTO_DE_ERROS.md) |
| Databases | [Supported databases](docs/bancos/BANCOS_SUPORTADOS.md) |
| Libraries | [Client libraries](docs/bancos/BIBLIOTECAS_CLIENTE.md) |
| Tests | [Tests and validation](docs/testes/TESTES_E_HOMOLOGACAO.md) |
| Engineering | [Toxicity control](docs/engenharia/CONTROLE_DE_TOXICIDADE.md) |

## 🧪 Tests

The official suite for new refactorings and behavioral fixes lives under `NewTests/` and uses DUnit with the GUI Test Runner. Exception-normalization tests are organized under `NewTests/src/Error/`, while SQL parameter validation/identification coverage lives under `NewTests/src/Validation/`; the project and runner remain at the root of `NewTests/`. The `tests/` tree remains as the legacy suite and reference material; `NewTests/` does not structurally depend on it.

The recorded execution of the current suite on Delphi 12 Community Edition, targeting Windows 32-bit, ran **84 of 84 tests** with **0 failures** and **0 errors**. Of those, 70 tests belong to `TRickSQLParameterValidatorTests`. Documentation for both structures and the scope of this evidence is centralized under [`docs/testes`](docs/testes/README.md).

## 📜 License

This project is distributed under a revocable license (**Revocable Software License**).

Before using the software, read [`LICENSE`](LICENSE) for the complete terms, usage restrictions, and permissions.

<div align="center">

## 🗄️ RickSQL

**Delphi SQL execution layer with encapsulated drivers, connections, materialization, and errors.**

Developed by **RickSoluções**

<br>

[🇧🇷 Leia a versão oficial em Português (Brasil)](./README.pt-BR.md)

</div>
