# RickSQL documentation

This directory is the canonical technical documentation source for the project. Source code under `src/` remains the primary authority for behavior; `tests/` is the single official test suite; `samples/` contains executable examples.

## Index

| Area | Document |
|---|---|
| Integration | [Integration guide](integracao/GUIA_DE_INTEGRACAO.md) |
| Examples | [Usage examples](integracao/EXEMPLOS_DE_USO.md) |
| Public API | [Public API](api/API_PUBLICA.md) |
| Connection | [Connection options](api/OPCOES_DE_CONEXAO.md) |
| Commands | [Commands and parameters](api/COMANDOS_E_PARAMETROS.md) |
| Ownership/lifetime | [Ownership and lifecycle](api/PROPRIEDADE_E_CICLO_DE_VIDA.md) |
| Errors | [Error handling](api/TRATAMENTO_DE_ERROS.md) |
| Databases | [Supported databases](bancos/BANCOS_SUPORTADOS.md) |
| Client libraries | [Client libraries](bancos/BIBLIOTECAS_CLIENTE.md) |
| Architecture | [Confirmed architecture](engenharia/ARQUITETURA.md) |
| Quality | [Toxicity control](engenharia/CONTROLE_DE_TOXICIDADE.md) |
| Tests | [Official suite](testes/README.md) |
| Validation | [Tests and validation](testes/TESTES_E_HOMOLOGACAO.md) |
| Coverage | [Coverage matrix](testes/MATRIZ_DE_COBERTURA.md) |

## Official suite state

The official suite lives exclusively under `tests/`. The Delphi project file is `tests/RickSQL.Tests.dproj`, whose `MainSource` is `RickSQL.Tests.dpr`. The runner uses DUnit GUI and, after the window is closed, executes the tests again to generate `dunitx-results.xml`, unless `/noxml` is supplied.

The supplied post-migration evidence from 2026-09-20 records 217 tests, 0 failures, and 0 errors on the branch without `FULL_EDITION`. Environment-conditional integration tests must not be treated as externally executed merely because the global suite is green.

## Authority rule

When documentation and implementation diverge, use the current requirement, current code, current configuration, and tests that represent valid contracts. Information that depends on an external environment or a tool that was not run must remain identified as **Not confirmed**.
