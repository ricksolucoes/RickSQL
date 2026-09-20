# Lifecycle, ownership e memória

> [Voltar ao índice de testes](README.pt-BR.md)

A suíte final não possui uma pasta separada `tests/memoria`. Os contratos de lifecycle/ownership foram consolidados nas classes que exercitam a responsabilidade real.

Cobertura principal:

- `TRickSQLFluentLifecycleTests`: ownership do dataset, `Open -> Open`, `Open -> Execute`, destrutor, `Owner(True/False)` e isolamento de instâncias;
- `TRickSQLDataSetMaterializerTests`: dataset materializado permanece utilizável após liberar a sessão interna;
- `TRickSQLFireDACServiceTests`: criação/lifetime de session, connection e query;
- `TRickSQLDriverContractTests`/`VendorLibraryTests`: ownership do driver link/contexto;
- `TRickSQLTransactionTests`: encerramento e diagnóstico de transações.

Esses testes validam lifecycle funcional. **Não foi executado detector de memory leaks nesta tarefa.** Portanto, não se declara que o projeto esteja livre de vazamentos de memória.
