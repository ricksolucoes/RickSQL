# Documentação do RickSQL

Este diretório é a fonte canônica da documentação técnica do projeto. O código em `src/` continua sendo a autoridade primária sobre comportamento; `tests/` é a única suíte oficial de testes; `samples/` contém exemplos executáveis.

## Índice

| Área | Documento |
|---|---|
| Integração | [Guia de integração](integracao/GUIA_DE_INTEGRACAO.pt-BR.md) |
| Exemplos | [Exemplos de uso](integracao/EXEMPLOS_DE_USO.pt-BR.md) |
| API pública | [API pública](api/API_PUBLICA.pt-BR.md) |
| Conexão | [Opções de conexão](api/OPCOES_DE_CONEXAO.pt-BR.md) |
| Comandos | [Comandos e parâmetros](api/COMANDOS_E_PARAMETROS.pt-BR.md) |
| Ownership/lifetime | [Propriedade e ciclo de vida](api/PROPRIEDADE_E_CICLO_DE_VIDA.pt-BR.md) |
| Erros | [Tratamento de erros](api/TRATAMENTO_DE_ERROS.pt-BR.md) |
| Bancos | [Bancos suportados](bancos/BANCOS_SUPORTADOS.pt-BR.md) |
| Client libraries | [Bibliotecas clientes](bancos/BIBLIOTECAS_CLIENTE.pt-BR.md) |
| Arquitetura | [Arquitetura confirmada](engenharia/ARQUITETURA.pt-BR.md) |
| Qualidade | [Controle de toxicidade](engenharia/CONTROLE_DE_TOXICIDADE.pt-BR.md) |
| Testes | [Suíte oficial](testes/README.pt-BR.md) |
| Homologação | [Testes e homologação](testes/TESTES_E_HOMOLOGACAO.pt-BR.md) |
| Cobertura | [Matriz de cobertura](testes/MATRIZ_DE_COBERTURA.pt-BR.md) |

## Estado da suíte oficial

A suíte oficial reside exclusivamente em `tests/`. O projeto Delphi é `tests/RickSQL.Tests.dproj`, com `MainSource` `RickSQL.Tests.dpr`. O runner usa DUnit GUI e, após o fechamento da janela, executa novamente os testes para gerar `dunitx-results.xml`, exceto com `/noxml`.

A evidência pós-migração fornecida em 20/09/2026 registra 217 testes, 0 failures e 0 errors no branch sem `FULL_EDITION`. Testes de infraestrutura externa são condicionais e não devem ser interpretados como executados apenas porque a suíte global terminou verde.

## Regra de autoridade

Quando documentação e implementação divergirem, use nesta ordem: requisito vigente, código atual, configuração atual e testes que representem contrato válido. Informações que dependam de ambiente externo ou ferramenta não executada devem permanecer identificadas como **Não confirmado**.
