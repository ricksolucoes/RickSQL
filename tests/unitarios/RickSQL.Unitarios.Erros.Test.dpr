program RickSQLUnitariosErrosTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Core.Error.Parser;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure CheckContains(const AText: string; const APart: string;
  const AMessage: string);
begin
  Check(Pos(APart, AText) > 0, AMessage);
end;

procedure CheckNotContains(const AText: string; const APart: string;
  const AMessage: string);
begin
  Check(Pos(APart, AText) = 0, AMessage);
end;

procedure TestarMensagemAmigavel;
var
  LError: TRickSQLError;
begin
  LError := TRickSQLCoreErrorParser.FromMessage(
    TRickSQLErrorKind.Connection, 'Falha técnica.', 'Teste de conexão');
  Check(LError.HasError, 'Erro de conexão deveria indicar falha.');
  Check(LError.Kind = TRickSQLErrorKind.Connection,
    'Categoria do erro de conexão incorreta.');
  CheckContains(LError.Message, 'Não foi possível estabelecer conexão',
    'Mensagem amigável de conexão incorreta.');
end;

procedure TestarDetalheTecnicoSeparado;
var
  LError: TRickSQLError;
begin
  LError := TRickSQLCoreErrorParser.FromMessage(
    TRickSQLErrorKind.Command, 'Erro original do banco.', 'Teste de comando');
  Check(LError.Message <> LError.TechnicalDetail,
    'Mensagem amigável não deve ser igual ao detalhe técnico.');
  CheckContains(LError.TechnicalDetail, 'Erro original do banco',
    'Detalhe técnico deveria preservar a mensagem original.');
end;

procedure TestarMascaraDeCredenciais;
var
  LError: TRickSQLError;
  LDetail: string;
begin
  LDetail := 'Server=local;Password=segredo;PWD=oculto;Senha=privada';
  LError := TRickSQLCoreErrorParser.FromMessage(
    TRickSQLErrorKind.Connection, LDetail, 'Teste seguro');
  CheckNotContains(LError.TechnicalDetail, 'segredo',
    'Password não deveria aparecer no detalhe técnico.');
  CheckNotContains(LError.TechnicalDetail, 'oculto',
    'PWD não deveria aparecer no detalhe técnico.');
  CheckNotContains(LError.TechnicalDetail, 'privada',
    'Senha não deveria aparecer no detalhe técnico.');
  CheckContains(LError.TechnicalDetail, '***',
    'Credenciais deveriam ser mascaradas.');
end;

procedure TestarErroInesperado;
var
  LError: TRickSQLError;
  LException: Exception;
begin
  LException := Exception.Create('Falha inesperada controlada.');
  try
    LError := TRickSQLCoreErrorParser.Unexpected(LException, 'Teste');
    Check(LError.Kind = TRickSQLErrorKind.Unexpected,
      'Categoria do erro inesperado incorreta.');
    CheckContains(LError.Message, 'falha inesperada',
      'Mensagem amigável inesperada incorreta.');
  finally
    LException.Free;
  end;
end;

procedure TestarResultadoComErro;
var
  LError: TRickSQLError;
  LResult: TRickSQLExecutionResult;
begin
  LError := TRickSQLCoreErrorParser.FromMessage(
    TRickSQLErrorKind.Parameter, 'Parâmetro ausente.', 'Teste');
  LResult := TRickSQLExecutionResult.Failed(LError);
  Check(not LResult.Success, 'Resultado com erro não deveria indicar sucesso.');
  Check(LResult.RowsAffected = 0, 'Resultado com erro não deve usar valor mágico.');
  Check(LResult.Error.Kind = TRickSQLErrorKind.Parameter,
    'Categoria do erro no resultado incorreta.');
end;

procedure ExecutarTestes;
begin
  TestarMensagemAmigavel;
  TestarDetalheTecnicoSeparado;
  TestarMascaraDeCredenciais;
  TestarErroInesperado;
  TestarResultadoComErro;
end;

begin
  try
    ExecutarTestes;
    Writeln('Testes unitários de erros concluídos com sucesso.');
  except
    on E: Exception do
    begin
      Writeln('Falha nos testes unitários de erros: ', E.Message);
      Halt(1);
    end;
  end;
end.
