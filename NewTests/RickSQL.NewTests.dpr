program RickSQLNewTests;

uses
  Vcl.Forms,
  TestFramework,
  GUITestRunner,
  Rick.SQL.Tests.Error.Integration in 'src\Error\Rick.SQL.Tests.Error.Integration.pas',
  Rick.SQL.Tests.Error.Normalizer in 'src\Error\Rick.SQL.Tests.Error.Normalizer.pas',
  Rick.SQL.Tests.Parameter.Validator in 'src\Validation\Rick.SQL.Tests.Parameter.Validator.pas';

begin
  Application.Initialize;
  GUITestRunner.RunRegisteredTests;
end.
