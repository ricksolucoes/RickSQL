unit Rick.SQL.Model.Driver.Definition;

// Responsabilidade: representar a definição necessária para configurar um driver de banco de dados.
// NAO cria driver links, abre conexões ou conhece a fachada pública.

interface

uses
  // RickSQL
  Rick.SQL.Model.Types;

{$SCOPEDENUMS ON}

type
  TRickSQLConnectionRequirement = (Server, Database, UserName, Password);

  TRickSQLConnectionRequirements = set of TRickSQLConnectionRequirement;
  TRickSQLStringArray = TArray<string>;

  TRickSQLDriverDefinition = record
    Engine: TRickSQLDatabaseEngine;
    DriverID: string;
    DefaultPort: Integer;
    ClientLibraries: TRickSQLStringArray;
    RequiredConnectionOptions: TRickSQLConnectionRequirements;
    class function Create(const AEngine: TRickSQLDatabaseEngine;
      const ADriverID: string): TRickSQLDriverDefinition; static;
    procedure AddClientLibrary(const AName: string);
    function Requires(const ARequirement: TRickSQLConnectionRequirement): Boolean;
  end;

implementation

class function TRickSQLDriverDefinition.Create(
  const AEngine: TRickSQLDatabaseEngine;
  const ADriverID: string): TRickSQLDriverDefinition;
begin
  Result.Engine := AEngine;
  Result.DriverID := ADriverID;
  Result.DefaultPort := 0;
  Result.ClientLibraries := nil;
  Result.RequiredConnectionOptions := [];
end;

procedure TRickSQLDriverDefinition.AddClientLibrary(const AName: string);
var
  LIndex: Integer;
begin
  LIndex := Length(ClientLibraries);
  SetLength(ClientLibraries, LIndex + 1);
  ClientLibraries[LIndex] := AName;
end;

function TRickSQLDriverDefinition.Requires(
  const ARequirement: TRickSQLConnectionRequirement): Boolean;
begin
  Result := ARequirement in RequiredConnectionOptions;
end;

end.
