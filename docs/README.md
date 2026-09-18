# RickSQL Documentation

This directory is the canonical source for the project's technical documentation. The implementation under `src/` remains the primary source of truth for behavior; `NewTests/`, `tests/`, and `samples/` complement that source with the official coverage for new refactorings, legacy contracts, and executable examples.

> [Back to the main README](../README.md)

English documents use the base `.md` filename. Their Brazilian Portuguese counterparts use the same filename with the `.pt-BR.md` suffix.

## Integration

| Document | Contents |
|---|---|
| [Integration guide](integracao/GUIA_DE_INTEGRACAO.md) | project structure, Library/Search Path, directives, and usage flow |
| [Usage examples](integracao/EXEMPLOS_DE_USO.md) | existing `Interface`, console, FMX, and Windows service examples under `samples/` |

## API

| Document | Contents |
|---|---|
| [Public API](api/API_PUBLICA.md) | `TRickSQL`, `TRickSQLInterf`, and fluent interfaces |
| [Connection options](api/OPCOES_DE_CONEXAO.md) | `TRickSQLConnectionOptions`, defaults, validation rules, and additional parameters |
| [Commands and parameters](api/COMANDOS_E_PARAMETROS.md) | command creation, parameters, `Open`, `Execute`, and execution options |
| [Ownership and lifetime](api/PROPRIEDADE_E_CICLO_DE_VIDA.md) | ownership, materialization, internal session, and transactions |
| [Error handling](api/TRATAMENTO_DE_ERROS.md) | `TRickSQLError`, categories, `DBMSCode`, `SQLState`, and credential masking |

## Databases

| Document | Contents |
|---|---|
| [Supported databases](bancos/BANCOS_SUPORTADOS.md) | providers, `DriverID`, ports, requirements, and database-specific rules |
| [Client libraries](bancos/BIBLIOTECAS_CLIENTE.md) | DLL resolution, search order, and architecture-specific behavior |

## Tests and validation

| Document | Contents |
|---|---|
| [Tests and validation overview](testes/TESTES_E_HOMOLOGACAO.md) | official `NewTests` suite, legacy `tests` suite, recorded results, and acceptance criteria |
| [Compilation tests](testes/TESTES_DE_COMPILACAO.md) | 18 existing contract/compilation projects |
| [Unit tests](testes/TESTES_UNITARIOS.md) | isolated projects for models, validators, drivers, and errors |
| [Integration tests](testes/TESTES_DE_INTEGRACAO.md) | SQLite, Firebird, PostgreSQL, SQL Server, ODBC, and infrastructure projects |
| [Environment setup](testes/CONFIGURACAO_AMBIENTE.md) | Library Path, environment variables, and external-test requirements |
| [Memory tests](testes/TESTES_DE_MEMORIA.md) | scenarios using `ReportMemoryLeaksOnShutdown` |
| [Concurrency tests](testes/TESTES_DE_CONCORRENCIA.md) | concurrent scenarios and failure isolation |

## Engineering

| Document | Contents |
|---|---|
| [Toxicity control](engenharia/CONTROLE_DE_TOXICIDADE.md) | quality rules, responsibilities, and review checklist |

## Documentation organization

- The root `README.md` is the repository landing page and contains only the overview, getting-started information, and navigation.
- `docs/` contains detailed technical documentation.
- `samples/` contains only example projects.
- `NewTests/` contains the official DUnit suite with the GUI Test Runner for new refactorings and behavioral fixes.
- `tests/` contains the legacy suite and its test artifacts.
- `LICENSE` and `LICENSE-pt-BR` remain at the repository root because they are normative licensing documents.

The documentation must not claim successful compilation, passing tests, absence of leaks, or metric conformance without real evidence from the corresponding tool or execution environment.
