program RickSQLNewTests;

// SEM {$APPTYPE CONSOLE} de proposito: este continua sendo um app GUI
// (subsistema Windows). Isso e necessario para o duplo-clique abrir a
// janela do GUITestRunner normalmente. Se compilarmos como CONSOLE,
// IsConsole fica sempre True e quebra a logica de decisao de modo.

uses
  Vcl.Forms,
  Vcl.Dialogs,
  System.SysUtils,
  System.IOUtils,
  TestFramework,
  GUITestRunner,
  XMLTestRunner,  // Unit do DUnit responsavel por gerar o XML (JUnit-like)
  Rick.SQL.Tests.Error.Integration in 'src\Error\Rick.SQL.Tests.Error.Integration.pas',
  Rick.SQL.Tests.Error.Normalizer in 'src\Error\Rick.SQL.Tests.Error.Normalizer.pas',
  Rick.SQL.Tests.FireDAC.WaitProvider in 'src\Infrastructure\Rick.SQL.Tests.FireDAC.WaitProvider.pas',
  Rick.SQL.Tests.Parameter.Validator in 'src\Validation\Rick.SQL.Tests.Parameter.Validator.pas',
  Rick.SQL.Tests.Transaction in 'src\Transaction\Rick.SQL.Tests.Transaction.pas',
  Rick.SQL.Tests.ClientLibrary.VendorLibrary in 'src\ClientLibrary\Rick.SQL.Tests.ClientLibrary.VendorLibrary.pas',
  Rick.SQL.Tests.Driver.ProviderReuse in 'src\Driver\Rick.SQL.Tests.Driver.ProviderReuse.pas',
  Rick.SQL.Tests.Fluent.Lifecycle in 'src\Facade\Rick.SQL.Tests.Fluent.Lifecycle.pas',
  Rick.SQL.Tests.DataSet.Materializer in 'src\Materialization\Rick.SQL.Tests.DataSet.Materializer.pas';

var
  xmlOutputPath : string;
  results       : TTestResult;

procedure GerarXML;
begin
  xmlOutputPath := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'dunitx-results.xml');

  // ATENCAO: isto executa a suite de testes NOVAMENTE (headless), depois
  // que voce ja rodou/inspecionou tudo na GUI. Se os testes tem efeitos
  // colaterais reais (transacoes, conexoes, drivers de banco), rodar duas
  // vezes seguidas pode nao ser seguro — confirme que sao idempotentes.
  results := XMLTestRunner.RunRegisteredTests(xmlOutputPath);
  try
    if TFile.Exists(xmlOutputPath) then
      ShowMessage('XML gerado com sucesso em:' + sLineBreak + xmlOutputPath)
    else
      ShowMessage('ATENCAO: XML nao foi encontrado apos a execucao em:' + sLineBreak + xmlOutputPath);
  finally
    results.Free;
  end;
end;

begin
  Application.Initialize;

  // Abre a GUI normalmente (voce ve os testes rodando, arvore, erros, etc.)
  GUITestRunner.RunRegisteredTests;

  // Ao fechar a janela da GUI, gera o XML automaticamente.
  // Para pular essa etapa (ex: so quer olhar a GUI, sem gerar arquivo),
  // rode o executavel com o parametro /noxml
  if not FindCmdLineSwitch('noxml') then
    GerarXML;
end.

