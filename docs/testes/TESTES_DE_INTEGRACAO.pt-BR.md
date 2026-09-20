# Testes de integração

> [Voltar ao índice de testes](README.pt-BR.md)

Todos os testes de integração pertencem ao projeto único `tests/RickSQL.Tests.dproj`.

## SQLite local

`TRickSQLSQLiteIntegrationTests` usa arquivo temporário por fixture e valida o fluxo público real:

```text
Rick.SQL -> validators -> driver/provider -> FireDAC -> resultado observável
```

Cenários: CRUD e `RowsAffected`, zero linhas afetadas, parâmetros, tipos mistos, consulta vazia, SQL vazio, parâmetro ausente, SQL inválido e diretório inexistente. O fixture remove banco e arquivos auxiliares (`-journal`, `-wal`, `-shm`) no teardown.

## Integrações externas condicionais

`TRickSQLExternalIntegrationTests` contém Firebird e PostgreSQL no branch padrão. Com `FULL_EDITION`, acrescenta SQL Server e ODBC. Os métodos usam `Exit` quando a variável mínima do cenário não está configurada.

Consequência: o resultado global 217/217 confirma que os métodos não falharam, mas **não confirma** que Firebird/PostgreSQL foram acessados. Execução externa real nesta entrega: **Não confirmado.**

Consulte [Configuração de ambiente](CONFIGURACAO_AMBIENTE.pt-BR.md) para as variáveis reconhecidas.
