# Testes de memória do RickSQL

> [Voltar ao índice da documentação](../README.pt-BR.md)

Os projetos executáveis ficam em [`tests/memoria`](../../tests/memoria/) e habilitam `ReportMemoryLeaksOnShutdown` para que o Delphi reporte leaks observáveis ao encerramento do processo.

## Objetivo

Exercitar repetidamente recursos envolvidos nas operações do framework, incluindo contexto/driver, conexão, query, dataset materializado, erros estruturados e arrays de parâmetros.

O harness não instrumenta cada tipo interno individualmente. Portanto, o teste pode evidenciar leaks reportados pelo runtime, mas a documentação não deve afirmar separadamente que cada classe foi liberada sem uma execução e instrumentação compatíveis.

## Testes disponíveis

### [`RickSQL.Memoria.SQLite.Test.dpr`](../../tests/memoria/RickSQL.Memoria.SQLite.Test.dpr)

Executa ciclos repetidos de criação de banco SQLite temporário, criação de tabela, inserção de registros, consulta e liberação do dataset retornado. Esse fluxo força criação e destruição repetida dos componentes internos envolvidos.

### [`RickSQL.Memoria.Parametros.Test.dpr`](../../tests/memoria/RickSQL.Memoria.Parametros.Test.dpr)

Cria um comando com grande quantidade de parâmetros para exercitar arrays dinâmicos e seu encerramento de escopo.

## Execução

Configure as pastas do RickSQL no `Library Path` ou `Search Path` e compile o projeto correspondente no Delphi aplicável.

Cada teste ativa:

```pascal
ReportMemoryLeaksOnShutdown := True;
```

Um relatório de leak somente pode ser avaliado após a execução real do binário. A ausência de relatório não foi medida durante esta reorganização documental.
