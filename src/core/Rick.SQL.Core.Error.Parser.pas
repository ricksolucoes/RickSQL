unit Rick.SQL.Core.Error.Parser;

// Responsabilidade: converter falhas internas em erros estruturados do RickSQL.
// Mantém as mensagens amigáveis legadas e delega a normalização compartilhada.

interface

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Error;

type
  TRickSQLCoreErrorParser = class
  private
    class function FriendlyMessage(
      const AKind: TRickSQLErrorKind): string; static;
  public
    class function FromException(const AException: Exception;
      const AKind: TRickSQLErrorKind;
      const AOperation: string): TRickSQLError; static;
    class function FromMessage(const AKind: TRickSQLErrorKind;
      const AMessage: string;
      const AOperation: string): TRickSQLError; static;
    class function Unexpected(const AException: Exception;
      const AOperation: string): TRickSQLError; static;
  end;

implementation

uses
  // RickSQL
  Rick.SQL.Error.Normalizer;

const
  _MESSAGE_VALIDATION_ =
    'Os dados informados para a operação SQL são inválidos. Revise as opções, o SQL e os parâmetros.';
  _MESSAGE_UNSUPPORTED_DATABASE_ =
    'O banco de dados informado não é suportado pelo RickSQL. Selecione um mecanismo disponível no enum.';
  _MESSAGE_DRIVER_ =
    'Não foi possível configurar o driver do banco de dados. Verifique o mecanismo e a biblioteca cliente.';
  _MESSAGE_CLIENT_LIBRARY_ =
    'A biblioteca cliente necessária para o banco de dados não foi localizada. Informe ClientLibraryPath ou coloque a biblioteca no diretório da aplicação.';
  _MESSAGE_CONNECTION_ =
    'Não foi possível estabelecer conexão com o banco de dados. ' +
    'Verifique o servidor, a porta, o banco informado e as credenciais de acesso.';
  _MESSAGE_COMMAND_ =
    'Não foi possível executar o comando SQL informado. Verifique a sintaxe e os parâmetros.';
  _MESSAGE_PARAMETER_ =
    'Não foi possível aplicar os parâmetros do comando SQL. Verifique nomes, tipos e valores informados.';
  _MESSAGE_TRANSACTION_ =
    'Não foi possível concluir a transação do banco de dados. Verifique o estado da conexão e tente novamente.';
  _MESSAGE_DATASET_ =
    'Não foi possível preparar o conjunto de dados retornado pela consulta. Verifique os campos retornados pelo SQL.';
  _MESSAGE_UNEXPECTED_ =
    'Ocorreu uma falha inesperada durante a operação SQL. Verifique o detalhe técnico e tente novamente.';

class function TRickSQLCoreErrorParser.FriendlyMessage(
  const AKind: TRickSQLErrorKind): string;
const
  _MAP_ERROR_MESSAGES: array[TRickSQLErrorKind] of string = (
    _MESSAGE_UNEXPECTED_,          // None
    _MESSAGE_VALIDATION_,          // Validation
    _MESSAGE_UNSUPPORTED_DATABASE_,// UnsupportedDatabase
    _MESSAGE_DRIVER_,              // Driver
    _MESSAGE_CLIENT_LIBRARY_,      // ClientLibrary
    _MESSAGE_CONNECTION_,          // Connection
    _MESSAGE_COMMAND_,             // Command
    _MESSAGE_PARAMETER_,           // Parameter
    _MESSAGE_TRANSACTION_,         // Transaction
    _MESSAGE_DATASET_,             // DataSet
    _MESSAGE_UNEXPECTED_           // Unexpected
  );
begin
  Result := _MAP_ERROR_MESSAGES[AKind];
end;

class function TRickSQLCoreErrorParser.FromException(
  const AException: Exception; const AKind: TRickSQLErrorKind;
  const AOperation: string): TRickSQLError;
begin
  Result := TRickSQLErrorNormalizer.FromException(AException, AKind,
    FriendlyMessage(AKind), AOperation);
end;

class function TRickSQLCoreErrorParser.FromMessage(
  const AKind: TRickSQLErrorKind; const AMessage: string;
  const AOperation: string): TRickSQLError;
var
  LDetail: string;
begin
  LDetail := Trim(AMessage);
  if LDetail = '' then
    LDetail := TRickSQLErrorNormalizer.TechnicalDetail(nil);
  Result := TRickSQLErrorNormalizer.FromDetail(AKind, FriendlyMessage(AKind),
    LDetail, AOperation);
end;

class function TRickSQLCoreErrorParser.Unexpected(
  const AException: Exception; const AOperation: string): TRickSQLError;
begin
  Result := FromException(AException, TRickSQLErrorKind.Unexpected, AOperation);
end;

end.
