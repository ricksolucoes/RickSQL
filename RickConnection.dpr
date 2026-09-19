program RickConnection;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Rick.SQL in 'src\Rick.SQL.pas',
  Rick.SQL.Core.ClientLibrary.Resolver in 'src\core\Rick.SQL.Core.ClientLibrary.Resolver.pas',
  Rick.SQL.Core.Command.Executor in 'src\core\Rick.SQL.Core.Command.Executor.pas',
  Rick.SQL.Core.Command.Validator in 'src\core\Rick.SQL.Core.Command.Validator.pas',
  Rick.SQL.Core.Connection.Validator in 'src\core\Rick.SQL.Core.Connection.Validator.pas',
  Rick.SQL.Core.DataSet.Materializer in 'src\core\Rick.SQL.Core.DataSet.Materializer.pas',
  Rick.SQL.Core.Driver.Context.Factory in 'src\core\Rick.SQL.Core.Driver.Context.Factory.pas',
  Rick.SQL.Core.Driver.Factory in 'src\core\Rick.SQL.Core.Driver.Factory.pas',
  Rick.SQL.Core.Error.Parser in 'src\core\Rick.SQL.Core.Error.Parser.pas',
  Rick.SQL.Core.Open.Executor in 'src\core\Rick.SQL.Core.Open.Executor.pas',
  Rick.SQL.Core.Parameter.Validator in 'src\core\Rick.SQL.Core.Parameter.Validator.pas',
  Rick.SQL.Model.Command.Options in 'src\model\Rick.SQL.Model.Command.Options.pas',
  Rick.SQL.Model.Command in 'src\model\Rick.SQL.Model.Command.pas',
  Rick.SQL.Model.Connection.Options in 'src\model\Rick.SQL.Model.Connection.Options.pas',
  Rick.SQL.Model.Contracts in 'src\model\Rick.SQL.Model.Contracts.pas',
  Rick.SQL.Model.Driver.Definition in 'src\model\Rick.SQL.Model.Driver.Definition.pas',
  Rick.SQL.Model.Error in 'src\model\Rick.SQL.Model.Error.pas',
  Rick.SQL.Model.Execution.Result in 'src\model\Rick.SQL.Model.Execution.Result.pas',
  Rick.SQL.Model.Parameter in 'src\model\Rick.SQL.Model.Parameter.pas',
  Rick.SQL.Model.Types in 'src\model\Rick.SQL.Model.Types.pas',
  Rick.SQL.Service.FireDAC.Connection in 'src\services\Rick.SQL.Service.FireDAC.Connection.pas',
  Rick.SQL.Service.FireDAC.Parameter.Binder in 'src\services\Rick.SQL.Service.FireDAC.Parameter.Binder.pas',
  Rick.SQL.Service.FireDAC.Query in 'src\services\Rick.SQL.Service.FireDAC.Query.pas',
  Rick.SQL.Service.FireDAC.Session in 'src\services\Rick.SQL.Service.FireDAC.Session.pas',
  Rick.SQL.Service.FireDAC.Transaction in 'src\services\Rick.SQL.Service.FireDAC.Transaction.pas',
  Rick.SQL.Service.FireDAC.Driver.Access in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.Access.pas',
  Rick.SQL.Service.FireDAC.Driver.Advantage in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.Advantage.pas',
  Rick.SQL.Service.FireDAC.Driver.Base in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.Base.pas',
  Rick.SQL.Service.FireDAC.Driver.Context in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.Context.pas',
  Rick.SQL.Service.FireDAC.Driver.VendorLibrary in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.VendorLibrary.pas',
  Rick.SQL.Service.FireDAC.Driver.DB2 in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.DB2.pas',
  Rick.SQL.Service.FireDAC.Driver.Firebird in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.Firebird.pas',
  Rick.SQL.Service.FireDAC.Driver.Informix in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.Informix.pas',
  Rick.SQL.Service.FireDAC.Driver.InterBase in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.InterBase.pas',
  Rick.SQL.Service.FireDAC.Driver.MSSQL in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.MSSQL.pas',
  Rick.SQL.Service.FireDAC.Driver.MySQL in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.MySQL.pas',
  Rick.SQL.Service.FireDAC.Driver.ODBC in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.ODBC.pas',
  Rick.SQL.Service.FireDAC.Driver.Oracle in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.Oracle.pas',
  Rick.SQL.Service.FireDAC.Driver.PostgreSQL in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.PostgreSQL.pas',
  Rick.SQL.Service.FireDAC.Driver.SQLAnywhere in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.SQLAnywhere.pas',
  Rick.SQL.Service.FireDAC.Driver.SQLite in 'src\services\drivers\Rick.SQL.Service.FireDAC.Driver.SQLite.pas',
  Rick.SQL.Interf in 'src\Rick.SQL.Interf.pas',
  Rick.SQL.Error.Normalizer in 'src\error\Rick.SQL.Error.Normalizer.pas';

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
