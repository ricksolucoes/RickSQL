# Official test suite

> [Back to the documentation index](../README.md)

`tests/` is RickSQL's single official test infrastructure. The legacy suite was removed after the pre-migration Quality Gate passed, and the former transition folder `NewTests/` was renamed to `tests/`.

## Project

```text
tests/
├── RickSQL.Tests.dproj       # Delphi project file
├── RickSQL.Tests.dpr         # MainSource
├── RickSQL.Tests.res
└── src/
    ├── ClientLibrary/
    ├── Concurrency/
    ├── Driver/
    ├── Error/
    ├── Facade/
    ├── Infrastructure/
    ├── Integration/
    ├── Materialization/
    ├── Model/
    ├── Service/
    ├── Transaction/
    └── Validation/
```

The test project is fully consolidated as `RickSQL.Tests.dproj` with `MainSource=RickSQL.Tests.dpr`; the generated executable is `RickSQL.Tests.exe`.

## Runner

The project uses classic DUnit with `GUITestRunner`. After the GUI closes, `XMLTestRunner.RunRegisteredTests` executes the suite again and writes `dunitx-results.xml` next to the executable. `/noxml` disables only this second run.

Operational consequence: each test must be self-contained, idempotent, and able to run twice in sequence without order dependencies or leftovers.

## Post-migration result

The supplied local evidence from 2026-09-20 14:21:27 records 217 executed tests, 217 passes, 0 failures, 0 errors, and 100% success from the final `tests/` path on the branch without `FULL_EDITION`.

The result includes the two deterministic scenarios that replaced the flaky legacy SQLite reader/writer test: `Concurrent_SameSQLiteReaders_RepeatedOperationsComplete` and `Concurrent_SQLiteWriteContention_ReturnsBusyAndRecovers`.

## What the result does not prove

Firebird and PostgreSQL tests return immediately when their minimum environment variables are absent. A `PASS` for those methods therefore does not prove an external server was accessed. SQL Server and ODBC integration methods are compiled only with `FULL_EDITION`. Actual execution of those external integrations: **Not confirmed.**

No line-coverage percentage or memory-leak-free claim is made. Coverage is responsibility-oriented; lifecycle is validated functionally, while leak measurement requires a dedicated tool. The 217/217 result corresponds to the `RICK_VCL_CONNECTION` branch without `FULL_EDITION`; `FULL_EDITION`, `CONSOLE`, and `RICK_FMX_CONNECTION` branches are not treated as executed by this evidence.

## Related documents

- [Tests and validation](TESTES_E_HOMOLOGACAO.md)
- [Coverage matrix](MATRIZ_DE_COBERTURA.md)
- [Unit/contract tests](TESTES_UNITARIOS.md)
- [Integration](TESTES_DE_INTEGRACAO.md)
- [Concurrency](TESTES_DE_CONCORRENCIA.md)
- [Lifecycle and memory](TESTES_DE_MEMORIA.md)
- [Compilation contracts](TESTES_DE_COMPILACAO.md)
- [Environment setup](CONFIGURACAO_AMBIENTE.md)
