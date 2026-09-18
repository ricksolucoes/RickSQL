unit Rick.SQL;

// Responsabilidade: expor a fachada pública do RickSQL para as aplicações consumidoras.
// NAO executa operações FireDAC diretamente, não conhece interface visual e não registra componentes.

interface

uses
  // Data
  Data.DB,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Command.Options,
  Rick.SQL.Model.Parameter,
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Error,
  Rick.SQL.Model.Execution.Result;

type
  TRickSQLDataSet                   = Data.DB.TDataSet;
  TRickSQLDatabaseEngine            = Rick.SQL.Model.Types.TRickSQLDatabaseEngine;
  TRickSQLErrorKind                 = Rick.SQL.Model.Types.TRickSQLErrorKind;
  TRickSQLConnectionParameter       = Rick.SQL.Model.Connection.Options.TRickSQLConnectionParameter;
  TRickSQLConnectionParameterArray  = Rick.SQL.Model.Connection.Options.TRickSQLConnectionParameterArray;
  TRickSQLConnectionOptions         = Rick.SQL.Model.Connection.Options.TRickSQLConnectionOptions;
  TRickSQLMaterializationOptions    = Rick.SQL.Model.Command.Options.TRickSQLMaterializationOptions;
  TRickSQLCommandOptions            = Rick.SQL.Model.Command.Options.TRickSQLCommandOptions;
  TRickSQLParameter                 = Rick.SQL.Model.Parameter.TRickSQLParameter;
  TRickSQLParameterArray            = Rick.SQL.Model.Parameter.TRickSQLParameterArray;
  TRickSQLCommand                   = Rick.SQL.Model.Command.TRickSQLCommand;
  TRickSQLError                     = Rick.SQL.Model.Error.TRickSQLError;
  TRickSQLExecutionResult           = Rick.SQL.Model.Execution.Result.TRickSQLExecutionResult;

  TRickSQL = class
  public
    class function ConnectionOptions(const AEngine: TRickSQLDatabaseEngine): TRickSQLConnectionOptions; static;
    class function Command(const AConnection: TRickSQLConnectionOptions; const ASQL: string): TRickSQLCommand; static;
    class function Open(const ACommand: TRickSQLCommand; out AError: TRickSQLError): TDataSet; static;
    class function Execute(const ACommand: TRickSQLCommand): TRickSQLExecutionResult; static;
  end;

implementation

uses
  // RickSQL
  Rick.SQL.Core.Open.Executor,
  Rick.SQL.Core.Command.Executor;

class function TRickSQL.ConnectionOptions(const AEngine: TRickSQLDatabaseEngine): TRickSQLConnectionOptions;
begin
  Result := TRickSQLConnectionOptions.Create(AEngine);
end;

class function TRickSQL.Command(const AConnection: TRickSQLConnectionOptions;
  const ASQL: string): TRickSQLCommand;
begin
  Result := TRickSQLCommand.Create(AConnection, ASQL);
end;

class function TRickSQL.Open(const ACommand: TRickSQLCommand;
  out AError: TRickSQLError): TDataSet;
begin
  Result := TRickSQLCoreOpenExecutor.Open(ACommand, AError);
end;

class function TRickSQL.Execute(const ACommand: TRickSQLCommand): TRickSQLExecutionResult;
begin
  Result := TRickSQLCoreCommandExecutor.Execute(ACommand);
end;

end.
