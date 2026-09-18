program RickSQL.Validators.ContractTest;

{$APPTYPE CONSOLE}

uses
  // RTL
  System.SysUtils,

  // Data
  Data.DB,

  // RickSQL
  Rick.SQL,
  Rick.SQL.Core.Connection.Validator,
  Rick.SQL.Core.Command.Validator;

procedure FailTest(const AMessage: string);
begin
  Writeln('FALHA: ' + AMessage);
  Halt(1);
end;

procedure AssertValid(const ACommand: TRickSQLCommand);
var
  LError: TRickSQLError;
begin
  if not TRickSQLCoreCommandValidator.Validate(ACommand, LError) then
    FailTest(LError.Message);
end;

procedure AssertInvalid(const ACommand: TRickSQLCommand);
var
  LError: TRickSQLError;
begin
  if TRickSQLCoreCommandValidator.Validate(ACommand, LError) then
    FailTest('O comando deveria ter sido rejeitado.');
  if not LError.HasError then
    FailTest('O erro estruturado não foi preenchido.');
end;

function SQLiteConnection: TRickSQLConnectionOptions;
begin
  Result := TRickSQLConnectionOptions.Create(
    TRickSQLDatabaseEngine.SQLite);
  Result.Database := ':memory:';
end;

procedure TestValidCommand;
var
  LCommand: TRickSQLCommand;
  LParameter: TRickSQLParameter;
begin
  LCommand := TRickSQLCommand.Create(SQLiteConnection,
    'select now()::date where id = :ID');
  LParameter := TRickSQLParameter.Create('ID', 1);
  LParameter.DataType := ftInteger;
  LCommand.AddParameter(LParameter);
  AssertValid(LCommand);
end;

procedure TestEmptySQL;
var
  LCommand: TRickSQLCommand;
begin
  LCommand := TRickSQLCommand.Create(SQLiteConnection, '   ');
  AssertInvalid(LCommand);
end;

procedure TestDuplicateParameter;
var
  LCommand: TRickSQLCommand;
begin
  LCommand := TRickSQLCommand.Create(SQLiteConnection,
    'select * from teste where id = :ID');
  LCommand.AddParameter(TRickSQLParameter.Create('ID', 1));
  LCommand.AddParameter(TRickSQLParameter.Create('id', 2));
  AssertInvalid(LCommand);
end;

procedure TestMissingParameter;
var
  LCommand: TRickSQLCommand;
begin
  LCommand := TRickSQLCommand.Create(SQLiteConnection,
    'select * from teste where id = :ID');
  AssertInvalid(LCommand);
end;

procedure TestIgnoredParameterText;
var
  LCommand: TRickSQLCommand;
begin
  LCommand := TRickSQLCommand.Create(SQLiteConnection,
    'select '':IGNORADO'' /* :BLOCO */ -- :LINHA' + sLineBreak +
    'from teste');
  AssertValid(LCommand);
end;

procedure TestIncompatibleValue;
var
  LCommand: TRickSQLCommand;
  LParameter: TRickSQLParameter;
begin
  LCommand := TRickSQLCommand.Create(SQLiteConnection,
    'select * from teste where id = :ID');
  LParameter := TRickSQLParameter.Create('ID', 'texto');
  LParameter.DataType := ftInteger;
  LCommand.AddParameter(LParameter);
  AssertInvalid(LCommand);
end;

procedure TestInvalidClientLibraryPath;
var
  LOptions: TRickSQLConnectionOptions;
  LError: TRickSQLError;
begin
  LOptions := SQLiteConnection;
  LOptions.ClientLibraryPath := 'C:\bibliotecas\*.dll';
  if TRickSQLCoreConnectionValidator.Validate(LOptions, LError) then
    FailTest('O caminho com curinga deveria ter sido rejeitado.');
end;

begin
  TestValidCommand;
  TestEmptySQL;
  TestDuplicateParameter;
  TestMissingParameter;
  TestIgnoredParameterText;
  TestIncompatibleValue;
  TestInvalidClientLibraryPath;
  Writeln('Contratos de validação verificados com sucesso.');
end.
