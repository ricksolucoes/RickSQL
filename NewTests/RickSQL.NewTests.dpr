program RickSQLNewTests;

uses
  Vcl.Forms,
  TestFramework,
  GUITestRunner,
  Rick.SQL.Tests.Error.Integration in 'src\Error\Rick.SQL.Tests.Error.Integration.pas',
  Rick.SQL.Tests.Error.Normalizer in 'src\Error\Rick.SQL.Tests.Error.Normalizer.pas';

begin
  Application.Initialize;
  GUITestRunner.RunRegisteredTests;
end.
