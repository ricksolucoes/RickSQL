program RickSQLUnitariosModelosTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,
  System.Variants,

  // Data
  Data.DB,

  // RickSQL
  Rick.SQL;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure TestarOpcoesDeConexao;
var
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  Check(LOptions.Engine = TRickSQLDatabaseEngine.SQLite,
    'Engine padrão incorreto.');
  Check(LOptions.Port = 0, 'Porta padrão da conexão incorreta.');
  Check(LOptions.ConnectTimeout = 0, 'Timeout padrão da conexão incorreto.');
  Check(Length(LOptions.ExtraParameters) = 0,
    'Parâmetros adicionais deveriam iniciar vazios.');
end;

procedure TestarParametroAdicional;
var
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  LOptions.AddExtraParameter('LockingMode', 'Normal');
  Check(Length(LOptions.ExtraParameters) = 1,
    'Parâmetro adicional não foi criado.');
  Check(LOptions.ExtraParameters[0].Name = 'LockingMode',
    'Nome do parâmetro adicional incorreto.');
  Check(LOptions.ExtraParameters[0].Value = 'Normal',
    'Valor do parâmetro adicional incorreto.');
end;

procedure TestarOpcoesDoComando;
var
  LOptions: TRickSQLCommandOptions;
begin
  LOptions := TRickSQLCommandOptions.CreateDefault;
  Check(LOptions.CommandTimeout = 0, 'Timeout padrão do comando incorreto.');
  Check(LOptions.UseTransaction, 'Transação deveria estar habilitada.');
  Check(LOptions.FetchAll, 'FetchAll deveria estar habilitado.');
  Check(LOptions.MaxRecords = 0, 'MaxRecords padrão incorreto.');
  Check(LOptions.Materialization.PositionAtFirstRecord,
    'O dataset deveria posicionar no primeiro registro.');
end;

procedure TestarParametroComValor;
var
  LParameter: TRickSQLParameter;
begin
  LParameter := TRickSQLParameter.Create('CODIGO', 10);
  Check(LParameter.Name = 'CODIGO', 'Nome do parâmetro incorreto.');
  Check(LParameter.DataType = ftUnknown, 'Tipo padrão do parâmetro incorreto.');
  Check(LParameter.Direction = ptInput, 'Direção padrão do parâmetro incorreta.');
  Check(not LParameter.IsNull, 'Parâmetro com valor não deveria ser nulo.');
end;

procedure TestarParametroNulo;
var
  LParameter: TRickSQLParameter;
begin
  LParameter := TRickSQLParameter.CreateNull('DATA', ftDateTime);
  Check(LParameter.Name = 'DATA', 'Nome do parâmetro nulo incorreto.');
  Check(LParameter.DataType = ftDateTime, 'Tipo do parâmetro nulo incorreto.');
  Check(LParameter.Direction = ptInput, 'Direção do parâmetro nulo incorreta.');
  Check(LParameter.IsNull, 'Parâmetro nulo não foi marcado como nulo.');
  Check(VarIsNull(LParameter.Value), 'Valor do parâmetro deveria ser Null.');
end;

procedure TestarComando;
var
  LOptions: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
begin
  LOptions := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  LCommand := TRickSQL.Command(LOptions, 'select :CODIGO as codigo');
  LCommand.AddParameter(TRickSQLParameter.Create('CODIGO', 1));
  Check(LCommand.Text = 'select :CODIGO as codigo', 'SQL do comando incorreto.');
  Check(Length(LCommand.Parameters) = 1, 'Parâmetro do comando não foi adicionado.');
  Check(LCommand.Connection.Engine = TRickSQLDatabaseEngine.SQLite,
    'Conexão do comando incorreta.');
end;

procedure TestarErro;
var
  LError: TRickSQLError;
begin
  LError := TRickSQLError.Empty;
  Check(not LError.HasError, 'Erro vazio não deveria indicar falha.');
  Check(LError.Kind = TRickSQLErrorKind.None, 'Categoria do erro vazio incorreta.');
  LError := TRickSQLError.Create(TRickSQLErrorKind.Validation, 'Falha validada.');
  Check(LError.HasError, 'Erro criado deveria indicar falha.');
  Check(LError.Message = 'Falha validada.', 'Mensagem do erro incorreta.');
end;

procedure TestarResultadoDeExecucao;
var
  LResult: TRickSQLExecutionResult;
  LError: TRickSQLError;
begin
  LResult := TRickSQLExecutionResult.Succeeded(3);
  Check(LResult.Success, 'Resultado de sucesso deveria estar marcado.');
  Check(LResult.RowsAffected = 3, 'Quantidade afetada incorreta.');
  LError := TRickSQLError.Create(TRickSQLErrorKind.Command, 'Falha no comando.');
  LResult := TRickSQLExecutionResult.Failed(LError);
  Check(not LResult.Success, 'Resultado de falha não deveria estar marcado.');
  Check(LResult.Error.Kind = TRickSQLErrorKind.Command,
    'Categoria do erro de execução incorreta.');
end;

procedure ExecutarTestes;
begin
  TestarOpcoesDeConexao;
  TestarParametroAdicional;
  TestarOpcoesDoComando;
  TestarParametroComValor;
  TestarParametroNulo;
  TestarComando;
  TestarErro;
  TestarResultadoDeExecucao;
end;

begin
  try
    ExecutarTestes;
    Writeln('Testes unitários de modelos concluídos com sucesso.');
  except
    on E: Exception do
    begin
      Writeln('Falha nos testes unitários de modelos: ', E.Message);
      Halt(1);
    end;
  end;
end.
