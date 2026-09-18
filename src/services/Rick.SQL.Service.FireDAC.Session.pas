unit Rick.SQL.Service.FireDAC.Session;

// Responsabilidade: manter o ciclo de vida dos recursos FireDAC de uma operação.
// NAO valida regras públicas, materializa datasets ou conhece interface visual.

interface

uses
  // FireDAC
  FireDAC.Comp.Client,

  // RickSQL
  Rick.SQL.Model.Error,
  Rick.SQL.Service.FireDAC.Driver.Context;

type
  TRickSQLServiceFireDACSession = class
  private
    FDriverContext: TRickSQLServiceFireDACDriverContext;
    FConnection: TFDConnection;
    FQuery: TFDQuery;
    FError: TRickSQLError;
    FReady: Boolean;
    class function CreateSessionError(const AMessage: string;
      const ADetail: string): TRickSQLError; static;
    procedure InitializeState;
    procedure AttachDriverContext(
      const ADriverContext: TRickSQLServiceFireDACDriverContext);
    function DriverContextReady: Boolean;
    procedure CopyDriverContextError;
    procedure CreateConnection;
    procedure CreateQuery;
    procedure MarkReady;
  public
    constructor Create(
      const ADriverContext: TRickSQLServiceFireDACDriverContext); reintroduce;
    destructor Destroy; override;
    property DriverContext: TRickSQLServiceFireDACDriverContext
      read FDriverContext;
    property Connection: TFDConnection read FConnection;
    property Query: TFDQuery read FQuery;
    property Error: TRickSQLError read FError;
    property Ready: Boolean read FReady;
  end;

implementation

uses
  // RTL
  System.SysUtils,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Error.Normalizer;

const
  _OPERATION_ = 'Criação da sessão FireDAC';
  _ERROR_SESSION_NOT_CREATED_ =
    'Não foi possível criar a sessão FireDAC. Verifique o contexto do driver e tente novamente.';
  _ERROR_DRIVER_CONTEXT_NOT_CREATED_ =
    'Não foi possível criar o contexto do driver FireDAC. Resolva o driver antes de criar a sessão.';
  _ERROR_DRIVER_CONTEXT_NOT_CONFIGURED_ =
    'Não foi possível configurar o contexto do driver FireDAC. Verifique o driver e a biblioteca cliente.';

constructor TRickSQLServiceFireDACSession.Create(
  const ADriverContext: TRickSQLServiceFireDACDriverContext);
begin
  inherited Create;

  InitializeState;
  try
    AttachDriverContext(ADriverContext);
    if not DriverContextReady then
      Exit;
    CreateConnection;
    CreateQuery;
    MarkReady;
  except
    on E: Exception do
      FError := TRickSQLErrorNormalizer.FromException(E,
        TRickSQLErrorKind.Connection, _ERROR_SESSION_NOT_CREATED_, _OPERATION_);
  end;
end;

destructor TRickSQLServiceFireDACSession.Destroy;
begin
  FreeAndNil(FQuery);
  FreeAndNil(FConnection);
  FreeAndNil(FDriverContext);
  FError := TRickSQLError.Empty;
  FReady := False;
  inherited Destroy;
end;

class function TRickSQLServiceFireDACSession.CreateSessionError(
  const AMessage: string; const ADetail: string): TRickSQLError;
begin
  Result := TRickSQLErrorNormalizer.FromDetail(TRickSQLErrorKind.Connection,
    AMessage, ADetail, _OPERATION_);
end;

procedure TRickSQLServiceFireDACSession.InitializeState;
begin
  FDriverContext := nil;
  FConnection := nil;
  FQuery := nil;
  FError := TRickSQLError.Empty;
  FReady := False;


end;

procedure TRickSQLServiceFireDACSession.AttachDriverContext(
  const ADriverContext: TRickSQLServiceFireDACDriverContext);
begin
  FDriverContext := ADriverContext;
end;

function TRickSQLServiceFireDACSession.DriverContextReady: Boolean;
begin
  Result := Assigned(FDriverContext) and FDriverContext.Configured;
  if not Result then
    CopyDriverContextError;
end;

procedure TRickSQLServiceFireDACSession.CopyDriverContextError;
begin
  if not Assigned(FDriverContext) then
  begin
    FError := CreateSessionError(_ERROR_DRIVER_CONTEXT_NOT_CREATED_, '');
    Exit;
  end;
  FError := FDriverContext.Error;
  if not FError.HasError then
    FError := CreateSessionError(_ERROR_DRIVER_CONTEXT_NOT_CONFIGURED_, '');
end;

procedure TRickSQLServiceFireDACSession.CreateConnection;
begin
  FConnection := TFDConnection.Create(nil);
end;

procedure TRickSQLServiceFireDACSession.CreateQuery;
begin
  FQuery := TFDQuery.Create(nil);
end;

procedure TRickSQLServiceFireDACSession.MarkReady;
begin
  FReady := Assigned(FConnection) and Assigned(FQuery);
end;

end.
