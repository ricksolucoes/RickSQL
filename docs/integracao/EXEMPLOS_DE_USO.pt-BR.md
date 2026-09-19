# Exemplos de uso

> [Voltar ao índice da documentação](../README.pt-BR.md)

Os projetos executáveis continuam em [`samples/`](../../samples/). Eles não fazem parte do núcleo do framework e não são dependências obrigatórias de aplicações consumidoras. A documentação desses exemplos fica centralizada aqui.

## Requisito de configuração

Antes de compilar qualquer exemplo, adicione ao `Library Path` ou `Search Path` do Delphi as pastas do framework:

```text
RickSQL\src
RickSQL\src\model
RickSQL\src\error
RickSQL\src\core
RickSQL\src\services
RickSQL\src\services\drivers
```

Os exemplos demonstram as duas formas públicas de consumo. `console`, `fmx` e `servico-windows` usam a fachada principal:

```pascal
uses
  Rick.SQL;
```

O exemplo `Interface` usa a API fluente:

```pascal
uses
  Rick.SQL.Interf;
```

A aplicação consumidora não precisa importar `FireDAC.Phys.*` diretamente.

## Padrão aplicado aos exemplos

As units auxiliares dos exemplos iniciam com `Rick.SQL`, mantendo o padrão nominal do framework. As referências diretas de interface visual ficam nos projetos que demonstram FMX ou serviço Windows.

No núcleo, a unit de espera do FireDAC é selecionada por compilação condicional. Aplicações console usam automaticamente `FireDAC.ConsoleUI.Wait` por meio de `CONSOLE`; aplicações VCL definem `RICK_VCL_CONNECTION`; aplicações FMX definem `RICK_FMX_CONNECTION`. Não existe fallback visual arbitrário para hosts não-console.

## Exemplo de API fluente (`Interface`)

Local: [`samples/Interface`](../../samples/Interface/)

Arquivos principais:

- [`RickSQL.Sample.Interf.dpr`](../../samples/Interface/RickSQL.Sample.Interf.dpr)
- [`Rick.SQL.Sample.Interf.Runner.pas`](../../samples/Interface/Rick.SQL.Sample.Interf.Runner.pas)

Demonstra:

- criação da instância por `TRickSQLInterf.New`;
- configuração fluente da conexão SQLite;
- execução de comandos e consulta por `IRickSQLCursor`;
- leitura do resultado por `IRickSQLResult`;
- parâmetros fluentes;
- reaproveitamento da mesma instância `IRickSQL`;
- uso de `.Parameter.Clear` entre comandos para limpar os parâmetros consolidados antes da próxima operação.

## Exemplo console

Local: [`samples/console`](../../samples/console/)

Arquivos principais:

- [`RickSQL.Sample.Console.dpr`](../../samples/console/RickSQL.Sample.Console.dpr)
- [`Rick.SQL.Sample.Console.Runner.pas`](../../samples/console/Rick.SQL.Sample.Console.Runner.pas)
- [`RickSQL.Sample.Console.dproj`](../../samples/console/RickSQL.Sample.Console.dproj)

Demonstra:

- configuração pelo mecanismo `SQLite`;
- criação automática de um arquivo de banco local;
- execução de comando SQL;
- consulta parametrizada;
- tratamento de erro estruturado;
- liberação do `TDataSet` retornado;
- execução em thread externa;
- seleção automática de `FireDAC.ConsoleUI.Wait` pelo símbolo `CONSOLE`, sem define específico do RickSQL.

## Exemplo de serviço Windows

Local: [`samples/servico-windows`](../../samples/servico-windows/)

Arquivos principais:

- [`RickSQL.Sample.ServicoWindows.dpr`](../../samples/servico-windows/RickSQL.Sample.ServicoWindows.dpr)
- [`Rick.SQL.Sample.ServicoWindows.Flow.pas`](../../samples/servico-windows/Rick.SQL.Sample.ServicoWindows.Flow.pas)

Demonstra:

- consumo do `RickSQL` dentro de um `TService`;
- execução em worker thread;
- criação de banco SQLite local;
- escrita de log em arquivo;
- execução de comando;
- consulta de dados;
- liberação dos recursos no encerramento do serviço.

## Exemplo FMX

Local: [`samples/fmx`](../../samples/fmx/)

Arquivos principais:

- [`RickSQL.Sample.FMX.dpr`](../../samples/fmx/RickSQL.Sample.FMX.dpr)
- [`Rick.SQL.Sample.FMX.Flow.pas`](../../samples/fmx/Rick.SQL.Sample.FMX.Flow.pas)

Demonstra:

- consumo do `RickSQL` em aplicação FMX;
- `RICK_FMX_CONNECTION` configurado no projeto para registrar `FireDAC.FMXUI.Wait`;
- execução em thread externa;
- atualização de tela pela thread principal;
- tratamento de erro estruturado;
- liberação do `TDataSet` retornado.

## Leitura complementar

- [Guia de integração](GUIA_DE_INTEGRACAO.pt-BR.md)
- [API pública](../api/API_PUBLICA.pt-BR.md)
- [Propriedade e ciclo de vida](../api/PROPRIEDADE_E_CICLO_DE_VIDA.pt-BR.md)
