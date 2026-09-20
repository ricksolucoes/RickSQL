# Controle de Method Toxicity

> [Voltar ao índice](../README.pt-BR.md)

## Política obrigatória

Os limites de qualidade desta tarefa são fixos e não podem ser afrouxados para aprovar código ou testes:

| Métrica | Limite |
|---|---:|
| `Length` | `<= 20` |
| `Parameters` | `<= 6` |
| `If Depth` | `<= 5` |
| `Cyclomatic Complexity` | `<= 6` |
| `Toxicity` | `<= 1` |

Não é permitido alterar thresholds do RAD Studio, criar configuração alternativa, desabilitar a métrica ou introduzir abstrações cosméticas apenas para reduzir números. Código novo não pode criar violação; código existente alterado não pode agravar violação preexistente.

## Métrica real x avaliação estática

### Métrica real

Somente existe quando `Project > Method Toxicity Metrics` foi executado no RAD Studio ou quando um CSV exportado pela ferramenta foi fornecido para o estado que está sendo aprovado. Nessa situação, o valor composto de `Toxicity` pode ser informado como medido.

### Avaliação estática

Quando não há relatório atual da IDE, o código-fonte pode ser inspecionado quanto a `Length`, `Parameters`, `If Depth` e `Cyclomatic Complexity`. Nessa situação, o valor composto deve ser registrado como:

> **Toxicity: Não medido.**

A fórmula interna do RAD Studio não deve ser inventada.

## Estado atual verificado

O CSV atual `RickSQL.Tests.csv`, exportado para o projeto final `tests/RickSQL.Tests.dproj`, foi fornecido nesta revisão e constitui **medição real do RAD Studio para a suíte de testes**. O arquivo contém 317 registros lógicos de métodos distribuídos pelas 16 units `.pas` registradas no projeto de testes.

Máximos observados no CSV atual:

| Métrica | Máximo medido | Limite | Situação |
|---|---:|---:|---|
| `Length` | `18` | `20` | aprovado |
| `Parameters` | `4` | `6` | aprovado |
| `If Depth` | `1` | `5` | aprovado |
| `Cyclomatic Complexity` | `5` | `6` | aprovado |
| `Toxicity` | `0,517` | `1` | aprovado |

Nenhum registro da suíte de testes excede os thresholds `20 / 6 / 5 / 6 / 1`. Os thresholds não foram alterados.

A medição fornecida cobre **somente os arquivos da suíte `tests/`**: os paths registrados no CSV apontam para as 16 units de teste. Ela não deve ser apresentada como medição atual de `src/`. Como nenhum arquivo de produção foi modificado nesta consolidação, a ausência de um CSV atual de produção não cria uma violação nova, mas o `Toxicity` composto de `src/` nesta revisão permanece **Não confirmado por medição atual**.

## Registro histórico

Medições anteriores com nomes como `RiCKSQL.csv` e `RickSQL.NewTests.csv` pertencem ao estado histórico anterior à consolidação definitiva. Esses nomes não são renomeados retroativamente. Para o estado atual, a evidência real utilizada é `RickSQL.Tests.csv`, correspondente ao projeto `tests/RickSQL.Tests.dproj`.

## Procedimento no RAD Studio

1. abrir o projeto desejado;
2. usar **Project > Method Toxicity Metrics**;
3. manter `Length=20`, `Parameters=6`, `If Depth=5`, `Cyclomatic Complexity=6`;
4. manter `Toxicity=1`;
5. exportar o CSV sem editar os resultados;
6. registrar configuração/target/defines da medição;
7. separar produção e testes na análise;
8. reprovar qualquer nova violação ou agravamento causado pela alteração.

## Código legado

Violação em método legado não alterado é débito técnico, não autorização para elevar threshold. Se o método precisar ser alterado, a mudança não pode piorar suas métricas. Refatoração fora do escopo exige autorização própria.
