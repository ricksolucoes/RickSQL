unit Rick.SQL.Tests.FireDAC.WaitProvider;

interface

uses
  TestFramework;

type
  TRickSQLFireDACWaitProviderTests = class(TTestCase)
  published
    procedure VCL_DeveRegistrarProviderDeEsperaDoFireDAC;
  end;

implementation

uses
  // FireDAC
  FireDAC.Stan.Consts,
  FireDAC.Stan.Factory,
  FireDAC.UI.Intf,

  // RickSQL
  Rick.SQL.Core.ClientLibrary.Resolver;

procedure TRickSQLFireDACWaitProviderTests.
  VCL_DeveRegistrarProviderDeEsperaDoFireDAC;
var
  LWaitCursor: IFDGUIxWaitCursor;
begin
  CheckEquals(C_FD_GUIxFormsProvider, FFDGUIxProvider,
    'A suite DUnit VCL deve selecionar o provider Forms do FireDAC.');

  LWaitCursor := nil;
  FDCreateInterface(IFDGUIxWaitCursor, LWaitCursor, True,
    C_FD_GUIxFormsProvider);

  Check(LWaitCursor <> nil,
    'O Resolver deve registrar IFDGUIxWaitCursor para aplicações VCL.');
end;

initialization
  RegisterTest(TRickSQLFireDACWaitProviderTests.Suite);

end.
