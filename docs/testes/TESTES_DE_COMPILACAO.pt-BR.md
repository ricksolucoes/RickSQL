# Contratos de compilação

> [Voltar ao índice de testes](README.pt-BR.md)

A suíte final não mantém mais projetos isolados em `tests/compilacao`. Os contratos anteriormente espalhados nesses executáveis foram migrados ou substituídos pela única suíte DUnit em `tests/`.

## O que o build da suíte verifica

Ao compilar `tests/RickSQL.Tests.dproj`, o compilador precisa resolver:

- as duas APIs públicas (`Rick.SQL` e `Rick.SQL.Interf`);
- models, validators e executors;
- factory/provider/contexto de drivers;
- services FireDAC;
- parser/normalizador de erros;
- materialização;
- branches condicionais incluídos na configuração ativa;
- todas as 16 units de teste registradas no runner.

Os antigos contratos de factory, validators, client library, driver context, sessão, conexão/query, binder, transaction, error parser, materializer, executors e fachada estão representados por testes DUnit contratuais ou funcionais. A [matriz final](MATRIZ_DE_COBERTURA.pt-BR.md) registra a decisão unit a unit.

## Projeto atual

- projeto: `tests/RickSQL.Tests.dproj`;
- `MainSource`: `RickSQL.Tests.dpr`;
- configuração padrão: `Debug`;
- plataforma padrão: `Win32`;
- define do runner VCL: `RICK_VCL_CONNECTION`;
- `FULL_EDITION`: não definido no branch validado.

O projeto contém `ProjectVersion = 20.3`. A edição comercial exata do Delphi correspondente a esse número não é inferida: **Não confirmado.**

## Evidência

A execução pós-migração do binário atualizado apresentou 217 testes registrados e executados no path final, sem failure/error. O log textual completo do compilador não foi anexado ao repositório; portanto, a documentação registra a execução real do artefato compilado e não inventa warnings/hints inexistentes.
