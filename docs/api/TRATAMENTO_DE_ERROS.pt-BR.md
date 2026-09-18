# Tratamento de erros

> [Voltar ao índice da documentação](../README.pt-BR.md)


## Tipo principal

Erros são representados pelo record `TRickSQLError`, declarado em `Rick.SQL.Model.Error`:

| Campo | Tipo | Descrição |
|---|---|---|
| `Kind` | `TRickSQLErrorKind` | categoria do erro |
| `Message` | `string` | mensagem amigável, controlada pelo framework, em português do Brasil |
| `TechnicalDetail` | `string` | detalhe técnico, podendo preservar a mensagem original do FireDAC ou do banco |
| `DBMSCode` | `Integer` | código de erro do banco de dados, quando disponível |
| `SQLState` | `string` | SQLSTATE extraído do primeiro erro FireDAC quando o tipo concreto expõe essa informação; atualmente há tratamento para `TFDIBError`, `TFDMySQLError` e, sob `FULL_EDITION`, `TFDODBCNativeError` |
| `Operation` | `string` | operação em que o erro ocorreu (ex.: "Abertura da consulta FireDAC") |
| `HasError` | `Boolean` | indica se o record representa um erro real |

`TRickSQLError.Empty` retorna um erro vazio (`Kind = None`, `HasError = False`), utilizado como valor inicial em todas as operações. `TRickSQLError.Create(AKind, AMessage)` cria um erro preenchendo `HasError` automaticamente como `AKind <> TRickSQLErrorKind.None`.

## Categorias (`TRickSQLErrorKind`)

```text
None, Validation, UnsupportedDatabase, Driver, ClientLibrary,
Connection, Command, Parameter, Transaction, DataSet, Unexpected
```

Nos fluxos que usam `Rick.SQL.Core.Error.Parser`, cada categoria é convertida em uma mensagem amigável fixa, controlada pelo framework. O parser preserva essa responsabilidade contextual e delega a normalização técnica ao componente compartilhado `Rick.SQL.Error.Normalizer`, localizado em `src/error`:

| Categoria | Mensagem amigável |
|---|---|
| `Validation` | Os dados informados para a operação SQL são inválidos. Revise as opções, o SQL e os parâmetros. |
| `UnsupportedDatabase` | O banco de dados informado não é suportado pelo RickSQL. Selecione um mecanismo disponível no enum. |
| `Driver` | Não foi possível configurar o driver do banco de dados. Verifique o mecanismo e a biblioteca cliente. |
| `ClientLibrary` | A biblioteca cliente necessária para o banco de dados não foi localizada. Informe ClientLibraryPath ou coloque a biblioteca no diretório da aplicação. |
| `Connection` | Não foi possível estabelecer conexão com o banco de dados. Verifique o servidor, a porta, o banco informado e as credenciais de acesso. |
| `Command` | Não foi possível executar o comando SQL informado. Verifique a sintaxe e os parâmetros. |
| `Parameter` | Não foi possível aplicar os parâmetros do comando SQL. Verifique nomes, tipos e valores informados. |
| `Transaction` | Não foi possível concluir a transação do banco de dados. Verifique o estado da conexão e tente novamente. |
| `DataSet` | Não foi possível preparar o conjunto de dados retornado pela consulta. Verifique os campos retornados pelo SQL. |
| `Unexpected` (ou qualquer outra categoria não mapeada) | Ocorreu uma falha inesperada durante a operação SQL. Verifique o detalhe técnico e tente novamente. |

Erros de validação (`Rick.SQL.Core.Connection.Validator`, `Rick.SQL.Core.Command.Validator`, `Rick.SQL.Core.Parameter.Validator`) não usam essa tabela fixa: eles constroem a mensagem amigável diretamente, de forma específica para cada regra violada (por exemplo, "O comando SQL não foi informado." ou "A porta deve estar entre 1 e 65535 ou permanecer com o valor zero.").

## Normalização compartilhada

`Rick.SQL.Error.Normalizer`, fisicamente localizado em `src/error/Rick.SQL.Error.Normalizer.pas`, é a autoridade compartilhada para transformar uma exception em dados técnicos de `TRickSQLError`. O componente que captura a falha continua responsável pelo contexto funcional (`Kind`, `Message` e `Operation`); o normalizador não conhece services específicos nem operações de negócio.

Nos fluxos que passam pelo normalizador, ele concentra a obtenção e o tratamento de `TechnicalDetail`, a sanitização das superfícies textuais e a extração de metadados estruturados do FireDAC. `Rick.SQL.Core.Error.Parser` permanece responsável pelas mensagens amigáveis fixas utilizadas pelos fluxos de core e delega essa normalização compartilhada.

## Detalhe técnico

O campo `TechnicalDetail` pode preservar a mensagem original do FireDAC ou do banco de dados (`EFDDBEngineException.Errors[0].Message`, quando disponível, ou `Exception.Message` como alternativa). Esse conteúdo pode aparecer em outro idioma, pois é produzido por um fornecedor externo, e deve ser usado apenas para diagnóstico técnico — nunca como mensagem principal ao usuário final. Quando nenhum detalhe está disponível, o normalizador preenche `TechnicalDetail` com o texto fixo "Nenhum detalhe técnico foi informado.".

## Código do banco (`DBMSCode`)

Quando a exception normalizada é uma `EFDDBEngineException` com pelo menos um erro em `Errors`, `DBMSCode` é preenchido com `Errors[0].ErrorCode`. Caso contrário, permanece em `0`.

## Segurança e mascaramento de credenciais

O normalizador compartilhado mascara, em `Message` e `TechnicalDetail` processados por ele, valores associados às seguintes chaves (comparação sem diferenciar maiúsculas de minúsculas): `Password=`, `PWD=`, `Pass=`, `Senha=`, `User Password=`, `User_Password=`. O valor localizado após a chave, até o próximo delimitador (`;`, `,`, quebra de linha), é substituído por `***`.

Exemplo de detalhe técnico após o mascaramento:

```text
Server=meuservidor;Database=erp;User=admin;Password=***;
```

## Erro em Open

Quando `TRickSQL.Open` falha:

- o retorno é `nil`;
- `TRickSQLError` (parâmetro `out AError`) é preenchido com a categoria correspondente à etapa que falhou (validação, resolução de driver, biblioteca cliente, conexão, comando ou dataset);
- nenhuma exceção deve escapar da API pública — todas as etapas internas capturam exceções e as convertem em `TRickSQLError`.

## Erro em Execute

Quando `TRickSQL.Execute` falha:

- `TRickSQLExecutionResult.Success = False`;
- `RowsAffected` é sempre `0` em caso de falha (`TRickSQLExecutionResult.Failed`) — não deve ser usado como indicador de erro, apenas `Success` e `Error.HasError`;
- `Error` contém a falha estruturada.

## Erro de rollback

Quando ocorre um erro adicional durante o rollback executado após uma falha de comando, o detalhe técnico dessa falha adicional é anexado ao `TechnicalDetail` do erro original, com o prefixo "Falha adicional ao desfazer a transação:", preservando a causa original do erro sem sobrescrevê-la.

## Uso recomendado

```pascal
LDataSet := TRickSQL.Open(LCommand, LError);
if not Assigned(LDataSet) then
begin
  Writeln(LError.Message);
  Writeln(LError.TechnicalDetail);
end;
```

Em interfaces visuais, a aplicação consumidora decide como apresentar a mensagem (`LError.Message`) ao usuário final. O `RickSQL` não exibe telas, caixas de diálogo ou notificações — ele apenas retorna dados estruturados.
