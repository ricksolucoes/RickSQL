unit Rick.SQL.Core.Driver.Context.Factory;

// Responsabilidade: criar o contexto de driver FireDAC a partir das opções de conexão.
// NAO abre conexões, executa comandos SQL ou conhece interface visual.

interface

uses
  // RickSQL
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Contracts,
  Rick.SQL.Model.Error,
  Rick.SQL.Service.FireDAC.Driver.Context;

type
  TRickSQLCoreDriverContextFactory = class
  private
    class function ResolveProvider(
      const AOptions: TRickSQLConnectionOptions;
      const AOperation: string;
      out AError: TRickSQLError): IRickSQLDriverProvider; static;
    class function ResolveLibrary(
      const AOptions: TRickSQLConnectionOptions;
      out AError: TRickSQLError): string; static;
    class function CreateDriverError(const AOperation: string): TRickSQLError; static;
  public
    class function Create(const AOptions: TRickSQLConnectionOptions;
      const AOperation: string;
      out AError: TRickSQLError): TRickSQLServiceFireDACDriverContext; static;
  end;

implementation

uses
  // RickSQL
  Rick.SQL.Core.ClientLibrary.Resolver,
  Rick.SQL.Core.Driver.Factory,
  Rick.SQL.Core.Error.Parser,
  Rick.SQL.Model.Types;

const
  _ERROR_DRIVER_NOT_FOUND_ =
    'Não foi possível resolver o driver do banco de dados. Revise o mecanismo informado.';

class function TRickSQLCoreDriverContextFactory.Create(
  const AOptions: TRickSQLConnectionOptions; const AOperation: string;
  out AError: TRickSQLError): TRickSQLServiceFireDACDriverContext;
var
  LProvider: IRickSQLDriverProvider;
  LPath: string;
begin
  Result := nil;
  LProvider := ResolveProvider(AOptions, AOperation, AError);
  if LProvider = nil then
    Exit;
  LPath := ResolveLibrary(AOptions, AError);
  if not AError.HasError then
    Result := TRickSQLServiceFireDACDriverContext.Create(LProvider, LPath);
end;

class function TRickSQLCoreDriverContextFactory.ResolveProvider(
  const AOptions: TRickSQLConnectionOptions; const AOperation: string;
  out AError: TRickSQLError): IRickSQLDriverProvider;
begin
  Result := TRickSQLCoreDriverFactory.Resolve(AOptions.Engine);
  if Result = nil then
    AError := CreateDriverError(AOperation)
  else
    AError := TRickSQLError.Empty;
end;

class function TRickSQLCoreDriverContextFactory.ResolveLibrary(
  const AOptions: TRickSQLConnectionOptions;
  out AError: TRickSQLError): string;
var
  LResolution: TRickSQLClientLibraryResolution;
begin
  Result := '';
  LResolution := TRickSQLCoreClientLibraryResolver.Resolve(AOptions, AError);
  if LResolution.Success then
    Result := LResolution.Path;
end;

class function TRickSQLCoreDriverContextFactory.CreateDriverError(
  const AOperation: string): TRickSQLError;
begin
  Result := TRickSQLCoreErrorParser.FromMessage(TRickSQLErrorKind.Driver,
    _ERROR_DRIVER_NOT_FOUND_, AOperation);
end;

end.
