unit Rick.SQL.Model.Connection.Options;

// Responsabilidade: representar as opções de conexão informadas ao RickSQL.
// NAO abre conexões, seleciona drivers ou executa comandos SQL.

interface

uses
  // RickSQL
  Rick.SQL.Model.Types;

type
  TRickSQLConnectionParameter = record
    Name: string;
    Value: string;
    class function Create(const AName: string;
      const AValue: string): TRickSQLConnectionParameter; static;
  end;

  TRickSQLConnectionParameterArray =
    TArray<TRickSQLConnectionParameter>;

  TRickSQLConnectionOptions = record
    Engine: TRickSQLDatabaseEngine;
    Server: string;
    Port: Integer;
    Database: string;
    UserName: string;
    Password: string;
    CharacterSet: string;
    ConnectTimeout: Integer;
    ClientLibraryPath: string;
    ExtraParameters: TRickSQLConnectionParameterArray;
    class function Create(const AEngine: TRickSQLDatabaseEngine)
      : TRickSQLConnectionOptions; static;
    procedure AddExtraParameter(const AName: string;
      const AValue: string);
  end;

implementation

uses
  System.SysUtils;

class function TRickSQLConnectionParameter.Create(const AName: string;
  const AValue: string): TRickSQLConnectionParameter;
begin
  Result.Name := AName;
  Result.Value := AValue;
end;

class function TRickSQLConnectionOptions.Create(
  const AEngine: TRickSQLDatabaseEngine): TRickSQLConnectionOptions;
begin
  Result.Engine := AEngine;
  Result.Server := '';
  Result.Port := 0;
  Result.Database := '';
  Result.UserName := '';
  Result.Password := '';
  Result.CharacterSet := '';
  Result.ConnectTimeout := 0;
  Result.ClientLibraryPath := '';
  Result.ExtraParameters := nil;
end;

procedure TRickSQLConnectionOptions.AddExtraParameter(const AName: string;
  const AValue: string);
var
  I: Integer;
begin
  for I := Low(ExtraParameters) to High(ExtraParameters) do
  begin
    if not SameText(ExtraParameters[I].Name, AName) then
      Continue;

    ExtraParameters[I].Value := AValue;
    Exit;
  end;

  Insert(TRickSQLConnectionParameter
          .Create(AName, AValue),
            ExtraParameters,
            Length(ExtraParameters)
        );
end;

end.
