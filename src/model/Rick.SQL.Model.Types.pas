unit Rick.SQL.Model.Types;

// Responsabilidade: declarar os tipos fundamentais compartilhados pelo RickSQL.
// NAO cria conexões, executa comandos SQL ou conhece componentes visuais.

interface

{$SCOPEDENUMS ON}

type
  TRickSQLDriverProviderClass = class of TInterfacedObject;

  TRickSQLDatabaseEngine = (Unknown, Firebird, InterBase, PostgreSQL, SQLServer,
                            MySQL, SQLite, Oracle, DB2, SQLAnywhere, Informix,
                            Advantage, Access, ODBC);

  TRickSQLErrorKind = (None, Validation, UnsupportedDatabase, Driver,
                        ClientLibrary, Connection, Command, Parameter,
                        Transaction, DataSet, Unexpected);

implementation

end.
