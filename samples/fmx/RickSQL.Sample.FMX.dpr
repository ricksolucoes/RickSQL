program RickSQL.Sample.FMX;

uses
  System.Classes,
  System.SysUtils,
  System.StartUpCopy,
  FMX.Forms,
  FMX.Types,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Memo,
  FMX.Layouts,
  Rick.SQL.Sample.FMX.Flow in 'Rick.SQL.Sample.FMX.Flow.pas';

type
  TRickSQLSampleForm = class(TForm)
  private
    FLayout: TLayout;
    FMemo: TMemo;
    FButton: TButton;
    procedure ConfigurarTela;
    procedure CriarLayout;
    procedure CriarBotao;
    procedure CriarMemo;
    procedure ExecutarClick(ASender: TObject);
    procedure ExecutarEmThread;
    procedure AdicionarLinha(const ATexto: string);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  RickSQLSampleForm: TRickSQLSampleForm;

constructor TRickSQLSampleForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  ConfigurarTela;
end;

procedure TRickSQLSampleForm.ConfigurarTela;
begin
  Caption := 'RickSQL - Exemplo FMX';
  Width := 720;
  Height := 480;
  CriarLayout;
  CriarBotao;
  CriarMemo;
end;

procedure TRickSQLSampleForm.CriarLayout;
begin
  FLayout := TLayout.Create(Self);
  FLayout.Parent := Self;
  FLayout.Align := TAlignLayout.Client;
  FLayout.Margins.Left := 12;
  FLayout.Margins.Top := 12;
  FLayout.Margins.Right := 12;
  FLayout.Margins.Bottom := 12;
end;

procedure TRickSQLSampleForm.CriarBotao;
begin
  FButton := TButton.Create(Self);
  FButton.Parent := FLayout;
  FButton.Align := TAlignLayout.Top;
  FButton.Text := 'Executar RickSQL';
  FButton.OnClick := ExecutarClick;
end;

procedure TRickSQLSampleForm.CriarMemo;
begin
  FMemo := TMemo.Create(Self);
  FMemo.Parent := FLayout;
  FMemo.Align := TAlignLayout.Client;
  FMemo.Lines.Add('Clique no botão para executar o exemplo.');
end;

procedure TRickSQLSampleForm.ExecutarClick(ASender: TObject);
begin
  AdicionarLinha('Executando fluxo em thread externa...');
  ExecutarEmThread;
end;

procedure TRickSQLSampleForm.ExecutarEmThread;
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      LTexto: string;
    begin
      LTexto := TRickSQLSampleFMXFlow.Executar;
      TThread.Queue(nil,
        procedure
        begin
          AdicionarLinha(LTexto);
        end);
    end).Start;
end;

procedure TRickSQLSampleForm.AdicionarLinha(const ATexto: string);
begin
  FMemo.Lines.Add(ATexto);
end;

begin
  Application.Initialize;
  Application.CreateForm(TRickSQLSampleForm, RickSQLSampleForm);
  Application.Run;
end.

