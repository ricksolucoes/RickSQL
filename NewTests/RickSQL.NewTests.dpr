program RickSQLNewTests;

uses
  Vcl.Forms,
  TestFramework,
  GUITestRunner,
  Rick.SQL.Tests.Error.Integration in 'src\Error\Rick.SQL.Tests.Error.Integration.pas',
  Rick.SQL.Tests.Error.Normalizer in 'src\Error\Rick.SQL.Tests.Error.Normalizer.pas',
  Rick.SQL.Tests.FireDAC.WaitProvider in 'src\Infrastructure\Rick.SQL.Tests.FireDAC.WaitProvider.pas',
  Rick.SQL.Tests.Parameter.Validator in 'src\Validation\Rick.SQL.Tests.Parameter.Validator.pas',
  Rick.SQL.Tests.Transaction in 'src\Transaction\Rick.SQL.Tests.Transaction.pas',
  Rick.SQL.Tests.ClientLibrary.VendorLibrary in 'src\ClientLibrary\Rick.SQL.Tests.ClientLibrary.VendorLibrary.pas';

begin
  Application.Initialize;
  GUITestRunner.RunRegisteredTests;
end.
