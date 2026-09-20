# Testes e homologação

> [Voltar ao índice](../README.pt-BR.md)

## Estratégia

A cobertura oficial é orientada a responsabilidade e comportamento observável, não à regra artificial `1 unit = 1 teste`. Uma responsabilidade pode ser validada por teste unitário, contratual, funcional, integração local, lifecycle, concorrência ou combinação desses níveis.

A [matriz final de cobertura](MATRIZ_DE_COBERTURA.pt-BR.md) contém todas as 43 units de `src/`. Não é declarado 100% de line coverage porque não foi utilizada ferramenta de cobertura de linhas nesta tarefa.

A revisão atual confirma cobertura suficiente por responsabilidade para o branch realmente executado (`RICK_VCL_CONNECTION`, sem `FULL_EDITION`). Branches `FULL_EDITION`, seleção `CONSOLE`/`RICK_FMX_CONNECTION` e integrações externas sem infraestrutura não são considerados aprovados implicitamente; permanecem condicionais/**Não confirmado**.

## Classes DUnit no branch validado

| Classe | Testes executados | Foco |
|---|---:|---|
| `TRickSQLErrorIntegrationTests` | 8 | propagação/normalização de erros entre camadas |
| `TRickSQLErrorNormalizerTests` | 6 | sanitização e metadados FireDAC |
| `TRickSQLFireDACWaitProviderTests` | 1 | provider de espera VCL |
| `TRickSQLParameterValidatorTests` | 70 | parâmetros e dialetos SQL |
| `TRickSQLTransactionTests` | 24 | `Active`, start, commit, rollback e falhas de inspeção |
| `TRickSQLVendorLibraryTests` | 16 | client library e `VendorLib` |
| `TRickSQLDriverProviderReuseTests` | 11 | factory/provider/contexto e fluxos SQLite |
| `TRickSQLDriverContractTests` | 9 | contratos dos 13 engines e fallbacks |
| `TRickSQLFluentLifecycleTests` | 17 | estado e ownership da API fluent |
| `TRickSQLDataSetMaterializerTests` | 6 | materialização e lifetime do dataset |
| `TRickSQLModelTests` | 12 | records/options/models |
| `TRickSQLCommandConnectionValidatorTests` | 11 | validadores de conexão/comando |
| `TRickSQLFireDACServiceTests` | 8 | session/connection/query/binder |
| `TRickSQLSQLiteIntegrationTests` | 10 | `Open`/`Execute` funcionais em SQLite local |
| `TRickSQLExternalIntegrationTests` | 3 | integrações condicionais Firebird/PostgreSQL |
| `TRickSQLConcurrencyTests` | 5 | isolamento e concorrência |
| **Total** | **217** | branch sem `FULL_EDITION` |

## Evidência pós-migração

A execução fornecida em 20/09/2026 14:21:27, já com a suíte em `tests/` e o projeto aberto por `RickSQL.Tests.dproj`, registrou 217 testes, 0 failures e 0 errors. A GUI também exibiu 217/217.

A segunda execução XML do runner confirmou os mesmos 217 testes e 0 falhas. Isso atende ao requisito de reexecução no path definitivo.

## Quality Gate pré-migração

Antes da remoção da suíte antiga foram confirmados: inventário completo de `src`, matriz das 43 units, auditoria da suíte antiga, migração/substituição dos contratos legados relevantes, cobertura funcional de `Open`/`Execute`, validators, drivers, transações, errors, materialização e client libraries. O gate permaneceu bloqueado até a primeira execução real verde da suíte de transição.

## Quality Gate pós-migração

Estado confirmado após `NewTests -> tests`:

- `NewTests/` não integra mais o estado final;
- `tests/` contém a suíte consolidada;
- projetos legados isolados foram removidos;
- `tests/RickSQL.Tests.dproj` referencia os arquivos existentes da suíte;
- 217 testes executados no path final;
- 0 failures;
- 0 errors;
- cenário de concorrência SQLite reformulado para contratos determinísticos;
- `.pas` da suíte final em UTF-8 com BOM.

## Integrações externas

Os métodos externos são condicionais ao ambiente. Ausência de variável mínima provoca `Exit` e o DUnit registra `PASS`, por isso o resultado global não é evidência de acesso a servidor.

| Integração | Presente na suíte | Execução externa confirmada |
|---|---|---|
| SQLite | Sim | Sim, local e temporária |
| Firebird | Sim | **Não confirmado** |
| PostgreSQL | Sim | **Não confirmado** |
| SQL Server (`FULL_EDITION`) | Condicional | **Não confirmado** |
| ODBC (`FULL_EDITION`) | Condicional | **Não confirmado** |
| Oracle/DB2/SQL Anywhere/Informix | contratos/fallbacks | servidor externo **Não confirmado** |

## Memória e concorrência

Lifecycle/ownership são exercitados por testes funcionais, mas não foi executado detector de memory leaks. Não é feita afirmação de “sem leaks”.

A antiga expectativa de que leitura e escrita SQLite simultâneas sobre o mesmo arquivo sempre deveriam terminar com sucesso foi substituída porque SQLite pode retornar `SQLITE_BUSY` sob contenção legítima. A suíte final testa dois contratos determinísticos: leitores simultâneos concluem; uma escrita bloqueada reporta busy estruturado e volta a funcionar depois que o lock é liberado.

## Method Toxicity

Os limites obrigatórios são `Length <= 20`, `Parameters <= 6`, `If Depth <= 5`, `Cyclomatic Complexity <= 6`, `Toxicity <= 1`. O CSV atual `RickSQL.Tests.csv` fornece medição real para as 16 units da suíte: 317 métodos medidos, máximos `Length 18`, `Parameters 4`, `If Depth 1`, `Cyclomatic Complexity 5` e `Toxicity 0,517`, sem violação dos thresholds. Essa evidência mede `tests/`, não `src/`; medição atual de produção: **Não confirmado**. Consulte [Controle de toxicidade](../engenharia/CONTROLE_DE_TOXICIDADE.pt-BR.md).
