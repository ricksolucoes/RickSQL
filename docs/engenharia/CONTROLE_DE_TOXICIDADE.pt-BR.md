# Controle de toxicidade

> [Voltar ao índice da documentação](../README.pt-BR.md)

## Objetivo

Definir critérios de qualidade para manter o código do `RickSQL` simples, legível, testável e com responsabilidades bem separadas entre `model`, `error`, `core`, `services` e `services/drivers`.

Este documento separa duas categorias de informação:

- **regra de engenharia** — critério que deve orientar código novo ou alterado;
- **estrutura observável** — responsabilidade que está centralizada no código atual e pode ser verificada nas units indicadas.

A existência de uma regra neste arquivo não significa, por si só, que todo método atual foi medido ou aprovado por uma ferramenta.

## Regras por método

### Comprimento

A política do projeto adota **20 linhas/instruções como limite de referência para `Length`**. Métodos acima desse limite devem ser analisados; quando a refatoração estiver autorizada e houver responsabilidade separável, a lógica pode ser extraída para métodos privados semanticamente claros.

O objetivo não é criar micro-métodos apenas para manipular a métrica. Extrações devem melhorar coesão e leitura sem alterar comportamento.

### Parâmetros

A política histórica deste projeto prefere **no máximo dois parâmetros simples** por método. Quando há um conjunto coerente maior de dados, records de configuração podem ser usados quando tiverem justificativa arquitetural real.

Isso é mais restritivo que usar apenas o threshold genérico de `Parameters`; não se deve criar DTOs, records ou abstrações artificiais apenas para reduzir contagem.

### Profundidade de decisão

Métodos públicos devem buscar profundidade de decisão máxima igual a 1. Validações compostas devem ser delegadas a responsabilidades específicas quando isso fizer sentido no desenho existente.

As units `Rick.SQL.Core.Connection.Validator`, `Rick.SQL.Core.Command.Validator` e `Rick.SQL.Core.Parameter.Validator` exemplificam a separação de validações por responsabilidade.

### Retorno antecipado

Guard clauses e retorno antecipado (`Exit`) são preferidos quando evitam aninhamento desnecessário, por exemplo:

```pascal
if not Assigned(ASession) then
  Exit;
```

Evite `else` após um ramo que encerra o fluxo com `Exit`, salvo quando houver motivo de legibilidade ou semântica que justifique a construção.

### Responsabilidade e duplicação

Um método não deve concentrar responsabilidades independentes apenas para reduzir quantidade de tipos ou units. Ao mesmo tempo, não se deve criar abstrações cosméticas sem consumidor real.

No código atual, as responsabilidades abaixo estão centralizadas:

- criação/configuração de conexão — `Rick.SQL.Service.FireDAC.Connection`;
- preparação/configuração de query — `Rick.SQL.Service.FireDAC.Query`;
- aplicação de parâmetros — `Rick.SQL.Service.FireDAC.Parameter.Binder`;
- commit e rollback — `Rick.SQL.Service.FireDAC.Transaction`;
- materialização do dataset — `Rick.SQL.Core.DataSet.Materializer`;
- normalização compartilhada de exceptions, sanitização e metadados técnicos — `Rick.SQL.Error.Normalizer`, em `src/error`;
- mensagens amigáveis fixas dos fluxos de core — `Rick.SQL.Core.Error.Parser`, que delega a normalização técnica;
- resolução do contexto do driver — `Rick.SQL.Core.Driver.Context.Factory`, reutilizada pelos executores de `Open` e `Execute`;
- aplicação do caminho já resolvido à propriedade `VendorLib` do DriverLink — `Rick.SQL.Service.FireDAC.Driver.VendorLibrary`, reutilizada por `Driver.Context`, pelo caminho compatível `ClientLibraryResolver.Configure` e pelos providers que definem `VendorLib` padrão.

Essas centralizações são características observáveis da arquitetura atual; qualquer alteração futura deve ser reavaliada contra o código, não contra esta lista isoladamente.

## Method Toxicity Metrics

Código Delphi novo ou alterado deve considerar:

- `Length`;
- `Parameters`;
- `If Depth`;
- `Cyclomatic Complexity`;
- `Toxicity` composto, quando medido pelo RAD Studio.

Para este projeto, a política documental existente usa `Length = 20` como limite e prefere métodos com até dois parâmetros simples quando isso preserva a coesão. Essa preferência de design não substitui automaticamente o threshold de `Parameters` definido pelo projeto, pelo usuário ou, na ausência deles, pela baseline de engenharia. Para as demais métricas, devem ser utilizados os thresholds configurados no ambiente/projeto ou a baseline adotada pela engenharia do projeto.

### Medição real x análise estática

**Métrica real** existe somente quando o RAD Studio executa `Project > Method Toxicity Metrics` ou quando um CSV exportado pela ferramenta é analisado.

Sem essa execução:

- é permitido revisar estaticamente tamanho, parâmetros, profundidade condicional e complexidade;
- não se deve inventar o valor composto de `Toxicity`;
- não se deve registrar “Method Toxicity Metrics aprovado” como resultado real.

A regra mínima para qualquer alteração Delphi é não introduzir nova toxicidade e não agravar toxicidade preexistente fora do escopo autorizado.

### Medições reais atuais registradas — evidência fornecida em 20/09/2026

Na rodada de **20/09/2026**, foram fornecidos e analisados dois CSVs do RAD Studio **Method Toxicity Metrics**: `RiCKSQL.csv`, cujos métodos medidos pertencem a `src`, e `RickSQL.NewTests.csv`, cujos métodos medidos pertencem a `NewTests`. Os arquivos contêm, respectivamente, **419** e **218** medições de métodos. Como os próprios CSVs não registram data de exportação, edição da IDE, plataforma alvo, configuração de build ou defines condicionais, essas propriedades não são inferidas da medição atual.

| Escopo medido | `Length` máx. | `Parameters` máx. | `If Depth` máx. | `Cyclomatic Complexity` máx. | `Toxicity` máx. |
|---|---:|---:|---:|---:|---:|
| produção `src` (`RiCKSQL.csv`) | 19 | 5 | 4 | 6 | 0,588 |
| `NewTests` (`RickSQL.NewTests.csv`) | 18 | 4 | 1 | 3 | 0,350 |
| subconjunto `Rick.SQL.Tests.Fluent.Lifecycle.pas` | 18 | 2 | 1 | 2 | 0,279 |
| subconjunto `Rick.SQL.Tests.DataSet.Materializer.pas` | 14 | 3 | 0 | 1 | 0,217 |
| subconjunto `Rick.SQL.Tests.Driver.Contracts.pas` | 13 | 1 | 0 | 1 | 0,204 |

Considerando os thresholds baseline do projeto (`Length = 20`, `Parameters = 6`, `If Depth = 5`, `Cyclomatic Complexity = 6` e `Toxicity = 1`), nenhum método medido representado nos CSVs fornecidos ultrapassa um threshold. A `Cyclomatic Complexity` de produção alcança o limite baseline 6, mas não o excede. O maior `Toxicity` medido em produção é `0,588`, enquanto em `NewTests` é `0,350`.

`RickSQL.NewTests.csv` contém **26 métodos medidos** de `NewTests/src/Facade/Rick.SQL.Tests.Fluent.Lifecycle.pas`, incluindo os helpers de lifecycle e seus 17 testes `published`. Nessa unit, o maior `Toxicity` medido é `0,279` (`TDataSetReleaseProbe.Notification`) e o maior `Length` medido é 18 (`OpenOpen_OwnerFalse_DevePreservarDataSetAnterior`). Os dois helpers de isolamento de escopo adicionados no ajuste do teste de destrutor, `OpenOwnedDataSetAndReleaseFacade` e `OpenExternalDataSetAndReleaseFacade`, medem `Toxicity` de `0,133` e `0,146`, respectivamente; ambos possuem um parâmetro, `If Depth = 0` e `Cyclomatic Complexity = 1`.

`NewTests/src/Materialization/Rick.SQL.Tests.DataSet.Materializer.pas` possui **8 métodos medidos** em `RickSQL.NewTests.csv`. Seus máximos são `Length = 14`, `Parameters = 3`, `If Depth = 0`, `Cyclomatic Complexity = 1` e `Toxicity = 0,217`; o maior `Toxicity` da unit pertence a `Open_DeveRetornarDataSetUtilAposLiberacaoDaSessaoInterna`. Assim, os seis testes `published` de caracterização de `FetchAll`/materialização possuem evidência real de execução DUnit e evidência real de Method Toxicity no conjunto fornecido.

`NewTests/src/Driver/Rick.SQL.Tests.Driver.Contracts.pas` possui **7 métodos medidos** em `RickSQL.NewTests.csv`. Seus máximos são `Length = 13`, `Parameters = 1`, `If Depth = 0`, `Cyclomatic Complexity = 1` e `Toxicity = 0,204`; o maior `Toxicity` medido pertence a `Factory_SupportedEngines_ResolveProviders`. Isso elimina a lacuna anterior de medição da classe de contratos de driver. O resultado DUnit fornecido também executa com sucesso os cinco testes `published` de contrato; os nomes dos testes fallback de Informix identificam a configuração condicional executada como o branch **sem `FULL_EDITION`**.

Evidência de execução e evidência de Method Toxicity permanecem distintas: nenhuma delas é usada para inferir edição da IDE, plataforma alvo, configuração de build ou branch condicional que o respectivo artefato não demonstre.

A medição CSV anteriormente registrada em 19/09/2026 (`Framework.csv`/`Teste-New.csv`) permanece como evidência histórica anterior à inclusão dos testes de materialização e contratos de driver. Ela apresentava os mesmos máximos globais de `Toxicity` (`0,588` em produção e `0,350` em `NewTests`) e já fornecia medição real para a unit de lifecycle.

### Medição histórica registrada — 19/09/2026 — anterior à classe de lifecycle

A medição anteriormente documentada de `RickSQL.NewTests.dproj`, capturada no **Delphi 12 Community Edition** para **Windows 32-bit**, mostrava maior `Toxicity` visível de `0,350`, `Length` visível até 14, `Parameters` até 4, `If Depth` até 1 e `Cyclomatic Complexity` até 3. Essa captura antecedia `TRickSQLFluentLifecycleTests`. Ela permanece útil como evidência histórica, mas a medição atual de `RickSQL.NewTests.csv` acima cobre independentemente as units de lifecycle e contratos de driver e mantém o mesmo maior `Toxicity` global de `0,350`.

### Medição histórica registrada — 18/09/2026

A medição anterior do mesmo projeto, também no **Delphi 12 Community Edition** e em **Windows 32-bit**, foi registrada antes da inclusão das units de transação, infraestrutura FireDAC e consolidação de `VendorLib`. Naquela captura, o maior `Toxicity` exibido era `0,325`, com `Length` visível até `14`, `Parameters` até `4`, `If Depth` até `1` e `Cyclomatic Complexity` até `3`. Esse registro permanece apenas como histórico da evolução do projeto; as medições atuais baseadas nos CSVs documentadas acima são as referências reais mais recentes registradas aqui.

## Código morto

A regra do projeto é não manter:

- variável sem uso;
- método sem consumidor conhecido;
- bloco de código comentado como implementação antiga;
- constante sem uso;
- `uses` órfão;
- `initialization` ou `finalization` sem necessidade arquitetural.

A determinação de que um elemento está realmente morto deve ser baseada em análise do projeto e de seus consumidores; não deve ser inferida apenas pelo nome ou pela ausência de uma referência em uma única unit.

## Regras de instanciação

Classes sem estado podem usar `class function` e `class procedure`, como ocorre nos validadores, factories e executores atuais.

Classes que mantêm recursos vivos podem ser instanciadas quando a responsabilidade exigir lifetime próprio. No código atual:

- `TRickSQLServiceFireDACDriverContext` mantém o driver link vivo durante a conexão;
- `TRickSQLServiceFireDACSession` mantém contexto do driver, conexão e query durante uma operação;
- `TRickSQLInterf` mantém estado de instância necessário ao encadeamento fluente da API complementar.

Nenhum desses casos deve ser transformado mecanicamente em método de classe apenas para uniformizar estilo.

## Organização dos `uses`

O padrão preferido separa dependências por grupo quando houver mais de uma categoria:

```pascal
uses
  // RTL
  System.SysUtils,

  // Data
  Data.DB,

  // FireDAC
  FireDAC.Comp.Client,

  // RickSQL
  Rick.SQL.Model.Command;
```

A área `model` não deve depender de `error`, `core` ou `services`. `Rick.SQL.Error.Normalizer` depende dos tipos de `model` e das APIs FireDAC necessárias à extração de metadados, mas não depende de `core` nem de `services`; assim, `core` e `services` podem compartilhar a mesma política de normalização sem introduzir `services -> core`. A fachada `Rick.SQL` mantém os executores na seção `implementation`, evitando expor essas dependências como parte de seu contrato público.

## Responsabilidade das units

Units internas novas devem registrar de forma curta sua responsabilidade e, quando útil, aquilo que explicitamente não fazem, seguindo o padrão já presente em grande parte do código:

```pascal
unit Rick.SQL.Core.Command.Validator;

// Responsabilidade: validar os dados necessários para executar um comando SQL.
// NAO cria conexão, não executa SQL e não conhece interface visual.
```

Essa é uma regra editorial para manutenção; não deve ser usada para afirmar automaticamente que toda unit histórica já segue o padrão sem inspeção.

## Provider de espera do FireDAC

O núcleo não cria componentes visuais nem exibe mensagens. `Rick.SQL.Core.ClientLibrary.Resolver` seleciona em compilação apenas a implementação de `IFDGUIxWaitCursor` exigida pelo FireDAC:

- `CONSOLE`: `FireDAC.ConsoleUI.Wait`;
- `RICK_VCL_CONNECTION`: `FireDAC.VCLUI.Wait`;
- `RICK_FMX_CONNECTION`: `FireDAC.FMXUI.Wait`.

`RICK_VCL_CONNECTION` e `RICK_FMX_CONNECTION` são mutuamente exclusivos. Hosts não-console devem declarar explicitamente um deles; a ausência de configuração é tratada como erro de compilação.

## Mensagens

Mensagens amigáveis controladas pelo framework são mantidas em português do Brasil e devem indicar o problema sem expor dados sensíveis. O framework não deve exibir `ShowMessage`, `MessageDlg` ou equivalentes; ele devolve `TRickSQLError` e `TRickSQLExecutionResult` para que o consumidor decida a apresentação.

## Segurança nas mensagens

`Rick.SQL.Error.Normalizer` mascara valores associados às chaves:

- `Password=`;
- `PWD=`;
- `Pass=`;
- `Senha=`;
- `User Password=`;
- `User_Password=`.

O valor encontrado é substituído por `***` nas superfícies textuais processadas pelo normalizador. Esse mecanismo não autoriza registrar strings de conexão completas ou parâmetros sensíveis fora da política de normalização.

## Checklist por método

```text
[ ] Length dentro da política aplicável ou exceção justificada.
[ ] Quantidade de parâmetros dentro da política aplicável ou modelagem justificada.
[ ] If Depth sem aninhamento desnecessário.
[ ] Complexidade ciclomática avaliada quando houver múltiplos caminhos.
[ ] Utiliza retorno antecipado quando melhora o fluxo.
[ ] Não possui else desnecessário após Exit.
[ ] Não mistura responsabilidades independentes.
[ ] Não contém strings operacionais duplicadas quando uma constante compartilhada é apropriada.
[ ] Não duplica lógica já centralizada em outra responsabilidade.
[ ] Não contém código morto confirmado.
[ ] Alteração não introduz nem agrava toxicidade.
```

## Checklist por unit

```text
[ ] Nome segue o namespace/prefixo Rick.SQL quando fizer parte do framework.
[ ] Tipos públicos seguem a nomenclatura já estabelecida (TRickSQL*/IRickSQL*).
[ ] Responsabilidade da unit está clara.
[ ] Uses contêm somente dependências necessárias e respeitam a direção de camadas.
[ ] Model não depende de error/core/services.
[ ] Error normalizer não depende de core/services.
[ ] Não existem componentes visuais criados pelo núcleo.
[ ] Provider de Wait do FireDAC corresponde ao host: CONSOLE, RICK_VCL_CONNECTION ou RICK_FMX_CONNECTION.
[ ] Não existe estado global mutável introduzido sem justificativa explícita.
```

## Checklist de mensagens

```text
[ ] Mensagem amigável em português do Brasil.
[ ] Acentuação e pontuação revisadas.
[ ] Orientação de resolução quando aplicável.
[ ] Nenhuma senha exposta.
[ ] Nenhuma string de conexão completa exposta sem sanitização.
[ ] Detalhe técnico separado da mensagem amigável.
```
