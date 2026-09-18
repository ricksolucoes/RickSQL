# Testes unitários do RickSQL

> [Voltar ao índice da documentação](../README.pt-BR.md)

Os projetos executáveis estão em [`tests/unitarios`](../../tests/unitarios/). São aplicações console Delphi e não dependem de framework externo de testes.

## Projetos disponíveis

- [`RickSQL.Unitarios.Modelos.Test.dpr`](../../tests/unitarios/RickSQL.Unitarios.Modelos.Test.dpr) — modelos públicos, valores padrão, parâmetros, erros e resultados.
- [`RickSQL.Unitarios.Validadores.Test.dpr`](../../tests/unitarios/RickSQL.Unitarios.Validadores.Test.dpr) — conexão, SQL, opções do comando e parâmetros.
- [`RickSQL.Unitarios.Drivers.Test.dpr`](../../tests/unitarios/RickSQL.Unitarios.Drivers.Test.dpr) — resolução dos providers, `DriverID` e portas padrão.
- [`RickSQL.Unitarios.Erros.Test.dpr`](../../tests/unitarios/RickSQL.Unitarios.Erros.Test.dpr) — mensagens amigáveis, detalhe técnico e ausência de credenciais.

## Configuração no Delphi

Configure o `Search Path` ou `Library Path` com:

```text
RickSQL\src
RickSQL\src\model
RickSQL\src\error
RickSQL\src\core
RickSQL\src\services
RickSQL\src\services\drivers
```

Depois abra cada `.dpr`, compile e execute no ambiente Delphi aplicável.

## Escopo

Esses projetos não abrem conexão com banco externo. O objetivo é validar contratos internos antes dos testes de integração.

## Divergência conhecida no estado atual

`RickSQL.Unitarios.Drivers.Test.dpr` espera `DefaultPort = 0` para `TRickSQLDatabaseEngine.Informix`, enquanto `src/services/drivers/Rick.SQL.Service.FireDAC.Driver.Informix.pas` define `DefaultPort := 9088` nos dois ramos de compilação. Portanto, esse caso está desalinhado com a implementação e não deve ser interpretado como um contrato válido do provider até que código e teste sejam reconciliados.

## Resultado esperado

Cada projeto foi escrito para terminar com uma mensagem de sucesso no console; em caso de falha, exibe a mensagem correspondente e encerra com código de saída `1`.

Isso descreve o comportamento previsto do harness. O resultado real de uma execução deve ser registrado separadamente.
