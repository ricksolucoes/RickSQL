# Testes unitários e contratuais

> [Voltar ao índice de testes](README.pt-BR.md)

Os testes unitários/contratuais fazem parte do mesmo projeto DUnit oficial; não existe runner separado.

## Principais grupos

- `Error`: normalização, mascaramento de dados sensíveis e metadados FireDAC;
- `Validation`: conexão, comando e 70 cenários de parâmetros/dialetos;
- `Transaction`: contrato Boolean de `Active`, inspeção segura de estado, start/commit/rollback e erros;
- `ClientLibrary`: resolução, arquitetura, `VendorLib` e falhas de setter;
- `Driver`: factory, 13 engines, fallbacks e reutilização de provider;
- `Model`: defaults, parâmetros, resultados e definições de driver;
- `Service`: sessão, conexão, query e parameter binder;
- `Materialization`: opções e dataset independente;
- `Facade`: estado, reuso e ownership da API fluent.

Esses testes não substituem integração funcional quando há efeito observável em FireDAC. Por isso SQLite local, concorrência e integrações condicionais permanecem em categorias próprias dentro da mesma suíte.
