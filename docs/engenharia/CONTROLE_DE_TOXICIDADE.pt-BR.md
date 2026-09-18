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
- resolução do contexto do driver — `Rick.SQL.Core.Driver.Context.Factory`, reutilizada pelos executores de `Open` e `Execute`.

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

### Medição real registrada — `RickSQL.NewTests.dproj`

Em **18/09/2026**, o RAD Studio **Delphi 12 Community Edition** executou `Project > Method Toxicity Metrics` para `RickSQL.NewTests.dproj`, com alvo **Windows 32-bit**. Na grade exibida, os maiores valores observados foram:

| Métrica | Maior valor observado |
|---|---:|
| `Length` | 14 |
| `Parameters` | 3 |
| `If Depth` | 1 |
| `Cyclomatic Complexity` | 3 |
| `Toxicity` | 0,292 |

Nenhum método listado atingiu o threshold oficial de `Toxicity = 1`. Portanto, **não foi observada violação de Toxicity no projeto de testes medido**. O máximo de `Parameters = 3` permanece abaixo da baseline de 6; ele apenas ultrapassa a preferência de design por até dois parâmetros simples e, isoladamente, não representa violação do threshold oficial de Toxicity.

Essa medição é específica de `RickSQL.NewTests.dproj`. Ela não deve ser apresentada como medição real das units de produção em `src/` nem da suíte legada `tests/` sem executar a ferramenta nesses projetos/units correspondentes.

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

## Interface visual e `CONSOLE_CONNECTION`

O núcleo não cria componentes visuais nem exibe mensagens. `Rick.SQL.Core.ClientLibrary.Resolver` possui uma dependência de unit de espera do FireDAC selecionada em compilação:

- padrão: `FireDAC.FMXUI.Wait`;
- com `CONSOLE_CONNECTION`: `FireDAC.ConsoleUI.Wait`.

Projetos console devem definir `CONSOLE_CONNECTION` no nível das opções do compilador para que o símbolo alcance a unit do resolvedor.

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
[ ] Dependência de Wait do FireDAC respeita CONSOLE_CONNECTION quando aplicável.
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
