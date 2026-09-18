program RickSQL.Sample.ServicoWindows;

{$IFDEF DEBUG}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
{$IFDEF DEBUG}
  // RTL
  System.SysUtils,

  // Exemplo
  Rick.SQL.Sample.ServicoWindows.Flow in 'Rick.SQL.Sample.ServicoWindows.Flow.pas';
{$ELSE}
  // RTL
  System.Classes,
  System.SysUtils,

  // Windows
  Winapi.Windows,

  // VCL
  Vcl.SvcMgr,

  // Exemplo
  Rick.SQL.Sample.ServicoWindows.Flow in 'Rick.SQL.Sample.ServicoWindows.Flow.pas';
{$ENDIF}

{$IFDEF DEBUG}

begin
  try
    Writeln('RickSQL - exemplo de serviço Windows em modo DEBUG');
    Writeln('Executando fluxo diretamente, sem Service Control Manager...');
    Writeln('');

    TRickSQLSampleServicoWindowsFlow.Executar;

    Writeln('');
    Writeln('Fluxo finalizado. Pressione ENTER para sair.');
    Readln;
  except
    on E: Exception do
    begin
      Writeln('Falha inesperada no exemplo: ' + E.Message);
      Readln;
    end;
  end;
end.

{$ELSE}

type
  TRickSQLSampleService = class(TService)
  private
    FWorker: TThread;
    FWorkerError: string;
    procedure AoIniciarServico(ASender: TService; var AStarted: Boolean);
    procedure AoPararServico(ASender: TService; var AStopped: Boolean);
    procedure ExecutarWorker;
    procedure IniciarWorker;
    procedure PararWorker;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetServiceController: TServiceController; override;
  end;

var
  RickSQLSampleService: TRickSQLSampleService;

procedure ServiceController(ACtrlCode: DWord); stdcall;
begin
  if Assigned(RickSQLSampleService) then
    RickSQLSampleService.Controller(ACtrlCode);
end;

constructor TRickSQLSampleService.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner, 0);

  ServiceName := 'RickSQLSampleService';
  DisplayName := 'RickSQL - Exemplo de Serviço Windows';
  OnStart := AoIniciarServico;
  OnStop := AoPararServico;
end;

destructor TRickSQLSampleService.Destroy;
begin
  PararWorker;
  inherited Destroy;
end;

function TRickSQLSampleService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TRickSQLSampleService.AoIniciarServico(ASender: TService;
  var AStarted: Boolean);
begin
  IniciarWorker;
  AStarted := True;
end;

procedure TRickSQLSampleService.AoPararServico(ASender: TService;
  var AStopped: Boolean);
begin
  PararWorker;
  AStopped := True;
end;

procedure TRickSQLSampleService.ExecutarWorker;
begin
  try
    TRickSQLSampleServicoWindowsFlow.Executar;
  except
    on E: Exception do
      FWorkerError := E.Message;
  end;
end;

procedure TRickSQLSampleService.IniciarWorker;
begin
  if Assigned(FWorker) then
    Exit;

  FWorkerError := '';
  FWorker := TThread.CreateAnonymousThread(
    procedure
    begin
      ExecutarWorker;
    end);

  FWorker.FreeOnTerminate := False;
  FWorker.Start;
end;

procedure TRickSQLSampleService.PararWorker;
begin
  if not Assigned(FWorker) then
    Exit;

  FWorker.Terminate;
  FWorker.WaitFor;
  FreeAndNil(FWorker);
end;

begin
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;

  Application.CreateForm(TRickSQLSampleService, RickSQLSampleService);
  Application.Run;
end.

{$ENDIF}
