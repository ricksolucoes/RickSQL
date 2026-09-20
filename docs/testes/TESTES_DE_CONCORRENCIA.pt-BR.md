# Testes de concorrência

> [Voltar ao índice de testes](README.pt-BR.md)

A classe `TRickSQLConcurrencyTests` contém cinco cenários no projeto oficial. Cada thread usa sua própria operação RickSQL/sessão FireDAC; o teste não compartilha uma `TFDConnection` do framework entre threads.

## Cenários finais

1. `Concurrent_IndependentSQLiteOperations_BothSucceed`: dois bancos SQLite independentes executam em paralelo.
2. `Concurrent_SQLiteAndPostgreSQL_WhenConfigured_BothSucceed`: SQLite local e PostgreSQL em paralelo, somente quando PostgreSQL está configurado.
3. `Concurrent_SameSQLiteReaders_RepeatedOperationsComplete`: dois readers executam repetidamente no mesmo arquivo SQLite e ambos devem concluir.
4. `Concurrent_SQLiteWriteContention_ReturnsBusyAndRecovers`: uma conexão de controle mantém write lock; `TRickSQL.Execute` deve retornar erro estruturado cujo código base é `SQLITE_BUSY`, e uma nova escrita deve funcionar depois que o lock é liberado.
5. `Concurrent_SuccessAndFailure_RemainIsolated`: operação válida e operação inválida simultâneas mantêm resultados independentes.

## Contrato legado substituído

A suíte antiga continha a expectativa de que leitura e escrita repetidas no mesmo SQLite deveriam sempre terminar com sucesso. Durante a migração esse cenário mostrou resultados dependentes de timing (`SQLITE_BUSY`/`SQLITE_BUSY_RECOVERY`). O contrato foi classificado como não determinístico para SQLite e substituído pelos dois cenários acima: concorrência de readers e contenção de writer com recuperação.

Não foi introduzido retry automático, mutex global ou alteração de produção apenas para tornar o teste verde. Também não é feita afirmação de thread safety global; os cenários validam somente os comportamentos exercitados.
