unit Rick.SQL.Model.Command;

// Responsabilidade: representar um comando SQL e os dados necessários para sua execução.
// NAO abre conexões, aplica parâmetros ou executa comandos SQL.

interface

uses
  // RickSQL
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Command.Options,
  Rick.SQL.Model.Parameter;

type
  TRickSQLCommand = record
    Connection: TRickSQLConnectionOptions;
    Text: string;
    Parameters: TRickSQLParameterArray;
    Options: TRickSQLCommandOptions;
    class function Create(const AConnection: TRickSQLConnectionOptions;
      const ASQL: string): TRickSQLCommand; static;
    procedure AddParameter(const AParameter: TRickSQLParameter);
  end;

implementation

class function TRickSQLCommand.Create(
  const AConnection: TRickSQLConnectionOptions;
  const ASQL: string): TRickSQLCommand;
begin
  Result.Connection := AConnection;
  Result.Text := ASQL;
  Result.Parameters := nil;
  Result.Options := TRickSQLCommandOptions.CreateDefault;
end;

procedure TRickSQLCommand.AddParameter(
  const AParameter: TRickSQLParameter);
begin
  Insert(AParameter, Parameters, Length(Parameters));
end;

end.
