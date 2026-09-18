# Documentação do RickSQL

Este diretório é a fonte canônica da documentação técnica do projeto. A implementação em `src/` continua sendo a fonte primária para comportamento; `tests/` e `samples/` complementam essa leitura com contratos e exemplos executáveis.

> [Voltar ao README principal](../README.pt-BR.md)

Os documentos em português do Brasil usam o sufixo `.pt-BR.md`. As versões em inglês preservam o mesmo nome-base sem esse sufixo.

## Integração

| Documento | Conteúdo |
|---|---|
| [Guia de integração](integracao/GUIA_DE_INTEGRACAO.pt-BR.md) | estrutura do projeto, Library/Search Path, diretivas e fluxo de uso |
| [Exemplos de uso](integracao/EXEMPLOS_DE_USO.pt-BR.md) | exemplos `Interface`, console, FMX e serviço Windows existentes em `samples/` |

## API

| Documento | Conteúdo |
|---|---|
| [API pública](api/API_PUBLICA.pt-BR.md) | `TRickSQL`, `TRickSQLInterf` e interfaces fluentes |
| [Opções de conexão](api/OPCOES_DE_CONEXAO.pt-BR.md) | `TRickSQLConnectionOptions`, defaults, validações e parâmetros adicionais |
| [Comandos e parâmetros](api/COMANDOS_E_PARAMETROS.pt-BR.md) | criação de comandos, parâmetros, `Open`, `Execute` e opções de execução |
| [Propriedade e ciclo de vida](api/PROPRIEDADE_E_CICLO_DE_VIDA.pt-BR.md) | ownership, materialização, sessão interna e transações |
| [Tratamento de erros](api/TRATAMENTO_DE_ERROS.pt-BR.md) | `TRickSQLError`, categorias, `DBMSCode`, `SQLState` e mascaramento de credenciais |

## Bancos de dados

| Documento | Conteúdo |
|---|---|
| [Bancos suportados](bancos/BANCOS_SUPORTADOS.pt-BR.md) | providers, `DriverID`, portas, requisitos e regras específicas |
| [Bibliotecas clientes](bancos/BIBLIOTECAS_CLIENTE.pt-BR.md) | resolução de DLLs, ordem de procura e comportamento por arquitetura |

## Testes e homologação

| Documento | Conteúdo |
|---|---|
| [Visão geral de testes e homologação](testes/TESTES_E_HOMOLOGACAO.pt-BR.md) | estratégia, ordem e critérios de aceite |
| [Testes de compilação](testes/TESTES_DE_COMPILACAO.pt-BR.md) | 18 projetos de contrato/compilação existentes |
| [Testes unitários](testes/TESTES_UNITARIOS.pt-BR.md) | projetos isolados de models, validadores, drivers e erros |
| [Testes de integração](testes/TESTES_DE_INTEGRACAO.pt-BR.md) | projetos SQLite, Firebird, PostgreSQL, SQL Server, ODBC e infraestrutura |
| [Configuração do ambiente](testes/CONFIGURACAO_AMBIENTE.pt-BR.md) | Library Path, variáveis e requisitos dos testes externos |
| [Testes de memória](testes/TESTES_DE_MEMORIA.pt-BR.md) | cenários com `ReportMemoryLeaksOnShutdown` |
| [Testes de concorrência](testes/TESTES_DE_CONCORRENCIA.pt-BR.md) | cenários simultâneos e isolamento de falhas |

## Engenharia

| Documento | Conteúdo |
|---|---|
| [Controle de toxicidade](engenharia/CONTROLE_DE_TOXICIDADE.pt-BR.md) | regras de qualidade, responsabilidades e checklist de revisão |

## Organização documental

- O `README.md` da raiz é a landing page padrão do repositório em inglês; `README.pt-BR.md` contém a versão equivalente em português do Brasil.
- `docs/` contém a documentação técnica detalhada.
- `samples/` contém somente os projetos de exemplo.
- `tests/` contém somente projetos e artefatos de teste.
- `LICENSE` e `LICENSE-pt-BR` permanecem na raiz por serem documentos normativos de licenciamento.

A documentação não deve declarar compilação, aprovação de testes, ausência de leaks ou conformidade de métricas sem evidência real da ferramenta correspondente.
