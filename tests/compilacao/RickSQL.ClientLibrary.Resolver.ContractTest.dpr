program RickSQL.ClientLibrary.Resolver.ContractTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.Classes,
  System.SysUtils,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Core.ClientLibrary.Resolver;

type
  TTestProcedure = procedure;

  TRickSQLTestDriverLink = class(TComponent)
  private
    FVendorLib: string;
  published
    property VendorLib: string read FVendorLib write FVendorLib;
  end;

var
  LHasFailure: Boolean;

const
  _TITLE_ = 'RickSQL - Teste de contrato da resolução de bibliotecas clientes';
  _STATUS_OK_ = 'OK';
  _STATUS_FAIL_ = 'FALHA';
  _RESULT_OK_ = 'Todos os testes foram executados com sucesso.';
  _RESULT_FAIL_ = 'Existem testes com falha. Verifique as mensagens acima.';
  _WAIT_EXIT_ = 'Pressione ENTER para sair.';
  _TEST_SQLITE_ = 'SQLite sem biblioteca cliente externa';
  _TEST_EXPLICIT_LIBRARY_ = 'Configuração de biblioteca explícita';
  _TEST_MISSING_LIBRARY_ = 'Biblioteca explícita inexistente';
  _TEST_ARCHITECTURE_ = 'Arquitetura incompatível';

procedure WaitExit;
begin
  Writeln;
  Writeln(_WAIT_EXIT_);
  Readln;
end;

procedure FailTest(const AMessage: string);
begin
  raise Exception.Create(AMessage);
end;

procedure RunTest(const AName: string; const ATest: TTestProcedure);
begin
  Write(AName + '... ');

  try
    ATest;
    Writeln(_STATUS_OK_);
  except
    on E: Exception do
    begin
      LHasFailure := True;
      Writeln(_STATUS_FAIL_);
      Writeln('  ' + E.Message);
    end;
  end;
end;

function TemporaryFilePath(const AName: string): string;
var
  LDirectory: string;
begin
  LDirectory := GetEnvironmentVariable('TEMP');

  if Trim(LDirectory) = '' then
    LDirectory := ExtractFilePath(ParamStr(0));

  Result := IncludeTrailingPathDelimiter(LDirectory) + AName;
end;

procedure CreateEmptyFile(const APath: string);
var
  LStream: TFileStream;
begin
  LStream := TFileStream.Create(APath, fmCreate);
  try
  finally
    LStream.Free;
  end;
end;

procedure CreateBinaryFile(const APath: string; const AMachine: Word);
var
  LStream: TFileStream;
  LDosSignature: Word;
  LPEOffset: Integer;
  LPESignature: Cardinal;
begin
  LDosSignature := $5A4D;
  LPEOffset := 64;
  LPESignature := $00004550;

  LStream := TFileStream.Create(APath, fmCreate);
  try
    LStream.Size := 70;
    LStream.Position := 0;
    LStream.WriteBuffer(LDosSignature, SizeOf(LDosSignature));
    LStream.Position := $3C;
    LStream.WriteBuffer(LPEOffset, SizeOf(LPEOffset));
    LStream.Position := LPEOffset;
    LStream.WriteBuffer(LPESignature, SizeOf(LPESignature));
    LStream.WriteBuffer(AMachine, SizeOf(AMachine));
  finally
    LStream.Free;
  end;
end;

function FirebirdOptions(const APath: string): TRickSQLConnectionOptions;
begin
  Result := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.Firebird);
  Result.ClientLibraryPath := APath;
end;

procedure TestSQLiteWithoutClientLibrary;
var
  LOptions: TRickSQLConnectionOptions;
  LResolution: TRickSQLClientLibraryResolution;
  LError: TRickSQLError;
begin
  LOptions := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.SQLite);

  LResolution := TRickSQLCoreClientLibraryResolver.Resolve(LOptions, LError);

  if not LResolution.Success or LResolution.Required then
    FailTest('O SQLite não deveria exigir biblioteca cliente externa.');

  if LError.HasError then
    FailTest(LError.Message);
end;

procedure TestExplicitLibraryConfiguration;
var
  LPath: string;
  LLink: TRickSQLTestDriverLink;
  LConfiguration: TRickSQLClientLibraryConfiguration;
  LError: TRickSQLError;
begin
  LPath := TemporaryFilePath('ricksql_client_library_test.dll');
  CreateEmptyFile(LPath);

  LLink := TRickSQLTestDriverLink.Create(nil);
  try
    LConfiguration := TRickSQLClientLibraryConfiguration.Create(
      FirebirdOptions(LPath), LLink);

    if not TRickSQLCoreClientLibraryResolver.Configure(
      LConfiguration, LError) then
      FailTest(LError.Message);

    if not SameText(LLink.VendorLib, ExpandFileName(LPath)) then
      FailTest('VendorLib não recebeu o caminho resolvido.');
  finally
    LLink.Free;
    DeleteFile(LPath);
  end;
end;

procedure TestMissingExplicitLibrary;
var
  LPath: string;
  LResolution: TRickSQLClientLibraryResolution;
  LError: TRickSQLError;
begin
  LPath := TemporaryFilePath('ricksql_missing_client_library.dll');
  DeleteFile(LPath);

  LResolution := TRickSQLCoreClientLibraryResolver.Resolve(
    FirebirdOptions(LPath), LError);

  if LResolution.Success then
    FailTest('O caminho inexistente deveria ter sido rejeitado.');

  if not LError.HasError then
    FailTest('A ausência da biblioteca não produziu erro estruturado.');
end;

procedure TestArchitectureMismatch;
var
  LPath: string;
  LMachine: Word;
  LResolution: TRickSQLClientLibraryResolution;
  LError: TRickSQLError;
begin
  LPath := TemporaryFilePath('ricksql_architecture_test.dll');

  if SizeOf(Pointer) = 8 then
    LMachine := $014C
  else
    LMachine := $8664;

  CreateBinaryFile(LPath, LMachine);
  try
    LResolution := TRickSQLCoreClientLibraryResolver.Resolve(
      FirebirdOptions(LPath), LError);

    if LResolution.Success then
      FailTest('A arquitetura incompatível deveria ter sido rejeitada.');

    if not LError.HasError then
      FailTest('A incompatibilidade não produziu erro estruturado.');
  finally
    DeleteFile(LPath);
  end;
end;

begin
  LHasFailure := False;

  Writeln(_TITLE_);
  Writeln;

  RunTest(_TEST_SQLITE_, TestSQLiteWithoutClientLibrary);
  RunTest(_TEST_EXPLICIT_LIBRARY_, TestExplicitLibraryConfiguration);
  RunTest(_TEST_MISSING_LIBRARY_, TestMissingExplicitLibrary);
  RunTest(_TEST_ARCHITECTURE_, TestArchitectureMismatch);

  Writeln;

  if LHasFailure then
  begin
    Writeln(_RESULT_FAIL_);
    ExitCode := 1;
  end
  else
    Writeln(_RESULT_OK_);

  WaitExit;
end.
