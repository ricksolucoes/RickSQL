program RickSQLUnitariosValidadoresTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,

  // Data
  Data.DB,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Core.Connection.Validator,
  Rick.SQL.Core.Command.Validator,
  Rick.SQL.Core.Parameter.Validator;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

function CriarConexaoSQLite: TRickSQLConnectionOptions;
begin
  Result := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  Result.Database := ':memory:';
end;

function CriarComandoValido: TRickSQLCommand;
begin
  Result := TRickSQL.Command(CriarConexaoSQLite, 'select 1 as valor');
end;

procedure TestarConexaoValida;
var
  LError: TRickSQLError;
begin
  Check(TRickSQLCoreConnectionValidator.Validate(CriarConexaoSQLite, LError),
    'Conexão SQLite válida foi recusada.');
  Check(not LError.HasError, 'Erro deveria estar vazio na conexão válida.');
end;

procedure TestarConexaoNaoConfigurada;
var
  LError: TRickSQLError;
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  Check(not TRickSQLCoreConnectionValidator.Validate(LOptions, LError),
    'Conexão sem dados deveria falhar.');
  Check(LError.Kind = TRickSQLErrorKind.Validation,
    'Categoria da falha de conexão incorreta.');
end;

procedure TestarTimeoutDaConexao;
var
  LError: TRickSQLError;
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := CriarConexaoSQLite;
  LOptions.ConnectTimeout := -1;
  Check(not TRickSQLCoreConnectionValidator.Validate(LOptions, LError),
    'Timeout negativo da conexão deveria falhar.');
end;

procedure TestarPortaInvalida;
var
  LError: TRickSQLError;
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := CriarConexaoSQLite;
  LOptions.Port := 70000;
  Check(not TRickSQLCoreConnectionValidator.Validate(LOptions, LError),
    'Porta inválida deveria falhar.');
end;

procedure TestarParametroReservado;
var
  LError: TRickSQLError;
  LOptions: TRickSQLConnectionOptions;
begin
  LOptions := CriarConexaoSQLite;
  LOptions.AddExtraParameter('DriverID', 'SQLite');
  Check(not TRickSQLCoreConnectionValidator.Validate(LOptions, LError),
    'DriverID adicional deveria ser bloqueado.');
end;

procedure TestarSQLVazio;
var
  LError: TRickSQLError;
  LCommand: TRickSQLCommand;
begin
  LCommand := TRickSQL.Command(CriarConexaoSQLite, '   ');
  Check(not TRickSQLCoreCommandValidator.Validate(LCommand, LError),
    'SQL vazio deveria falhar.');
end;

procedure TestarTimeoutDoComando;
var
  LError: TRickSQLError;
  LCommand: TRickSQLCommand;
begin
  LCommand := CriarComandoValido;
  LCommand.Options.CommandTimeout := -1;
  Check(not TRickSQLCoreCommandValidator.Validate(LCommand, LError),
    'Timeout negativo do comando deveria falhar.');
end;

procedure TestarLimiteDeRegistros;
var
  LError: TRickSQLError;
  LCommand: TRickSQLCommand;
begin
  LCommand := CriarComandoValido;
  LCommand.Options.MaxRecords := -1;
  Check(not TRickSQLCoreCommandValidator.Validate(LCommand, LError),
    'Limite de registros negativo deveria falhar.');
end;

procedure TestarParametroObrigatorio;
var
  LError: TRickSQLError;
  LCommand: TRickSQLCommand;
begin
  LCommand := TRickSQL.Command(CriarConexaoSQLite, 'select :CODIGO as valor');
  Check(not TRickSQLCoreCommandValidator.Validate(LCommand, LError),
    'Parâmetro obrigatório ausente deveria falhar.');
end;

procedure TestarParametroDuplicado;
var
  LError: TRickSQLError;
  LCommand: TRickSQLCommand;
begin
  LCommand := TRickSQL.Command(CriarConexaoSQLite, 'select :CODIGO as valor');
  LCommand.AddParameter(TRickSQLParameter.Create('CODIGO', 1));
  LCommand.AddParameter(TRickSQLParameter.Create('CODIGO', 2));
  Check(not TRickSQLCoreParameterValidator.Validate(LCommand, LError),
    'Parâmetro duplicado deveria falhar.');
end;

procedure TestarParametroSemNome;
var
  LError: TRickSQLError;
  LCommand: TRickSQLCommand;
begin
  LCommand := CriarComandoValido;
  LCommand.AddParameter(TRickSQLParameter.Create('', 1));
  Check(not TRickSQLCoreParameterValidator.Validate(LCommand, LError),
    'Parâmetro sem nome deveria falhar.');
end;

procedure TestarParametroIncompativel;
var
  LError: TRickSQLError;
  LCommand: TRickSQLCommand;
  LParameter: TRickSQLParameter;
begin
  LCommand := TRickSQL.Command(CriarConexaoSQLite, 'select :CODIGO as valor');
  LParameter := TRickSQLParameter.Create('CODIGO', 'ABC');
  LParameter.DataType := ftInteger;
  LCommand.AddParameter(LParameter);
  Check(not TRickSQLCoreParameterValidator.Validate(LCommand, LError),
    'Valor incompatível com ftInteger deveria falhar.');
end;

procedure TestarCastPostgreSQLIgnorado;
var
  LError: TRickSQLError;
  LCommand: TRickSQLCommand;
begin
  LCommand := TRickSQL.Command(CriarConexaoSQLite,
    'select codigo::integer as valor from teste where id = :ID');
  LCommand.AddParameter(TRickSQLParameter.Create('ID', 1));
  Check(TRickSQLCoreCommandValidator.Validate(LCommand, LError),
    'Cast :: do PostgreSQL não deveria ser tratado como parâmetro obrigatório.');
end;

procedure ExecutarTestes;
begin
  TestarConexaoValida;
  TestarConexaoNaoConfigurada;
  TestarTimeoutDaConexao;
  TestarPortaInvalida;
  TestarParametroReservado;
  TestarSQLVazio;
  TestarTimeoutDoComando;
  TestarLimiteDeRegistros;
  TestarParametroObrigatorio;
  TestarParametroDuplicado;
  TestarParametroSemNome;
  TestarParametroIncompativel;
  TestarCastPostgreSQLIgnorado;
end;

begin
  try
    ExecutarTestes;
    Writeln('Testes unitários dos validadores concluídos com sucesso.');
  except
    on E: Exception do
    begin
      Writeln('Falha nos testes unitários dos validadores: ', E.Message);
      Halt(1);
    end;
  end;
end.
