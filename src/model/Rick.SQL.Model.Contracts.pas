unit Rick.SQL.Model.Contracts;

// Responsabilidade: declarar os contratos internos utilizados pelas camadas do RickSQL.
// NAO implementa drivers, executa comandos ou mantém estado global.

interface

uses
  // RTL
  System.Classes,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Driver.Definition;

type
  IRickSQLDriverProvider = interface
    ['{F886E7F4-210A-40F8-99DB-CC384EAB96BF}']
    function Engine: TRickSQLDatabaseEngine;
    function Definition: TRickSQLDriverDefinition;
    function CreateDriverLink(const AOwner: TComponent): TComponent;
    procedure ApplyConnectionOptions(
      const AOptions: TRickSQLConnectionOptions;
      const AParameters: TStrings);
    function ValidateOptions(const AOptions: TRickSQLConnectionOptions;
      out AError: string): Boolean;
  end;

implementation

end.
