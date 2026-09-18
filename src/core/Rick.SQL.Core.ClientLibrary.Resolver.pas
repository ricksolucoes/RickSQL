unit Rick.SQL.Core.ClientLibrary.Resolver;

// Responsabilidade: localizar e configurar a biblioteca cliente exigida pelo banco selecionado.
// NAO baixa bibliotecas, instala clientes, copia arquivos ou altera o sistema operacional.

interface

uses
  // FireDAC
  FireDAC.DApt,
  FireDAC.Stan.Def,
{$IFDEF CONSOLE_CONNECTION}
  FireDAC.ConsoleUI.Wait,
{$ELSE}
  FireDAC.FMXUI.Wait,
{$ENDIF}
  FireDAC.Stan.Async,

  // RTL
  System.Classes,
  System.TypInfo,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Connection.Options,
  Rick.SQL.Model.Driver.Definition,
  Rick.SQL.Model.Error;

{$SCOPEDENUMS ON}

type
  TRickSQLClientLibrarySource = (
    NotRequired,
    ConfiguredPath,
    ExecutableDirectory,
    FrameworkDirectory,
    EnvironmentPath,
    DriverDefault
  );

  TRickSQLBinaryArchitecture = (
    Unknown,
    Win32,
    Win64
  );

  TRickSQLBinaryInspection = record
    Success: Boolean;
    Machine: Word;
    Detail: string;
  end;

  TRickSQLClientLibraryResolution = record
    Success: Boolean;
    Required: Boolean;
    Path: string;
    Source: TRickSQLClientLibrarySource;
    class function Empty: TRickSQLClientLibraryResolution; static;
    class function Located(const APath: string;
      const ASource: TRickSQLClientLibrarySource)
      : TRickSQLClientLibraryResolution; static;
    class function NotRequired: TRickSQLClientLibraryResolution; static;
  end;

  TRickSQLClientLibraryConfiguration = record
    Options: TRickSQLConnectionOptions;
    DriverLink: TComponent;
    class function Create(const AOptions: TRickSQLConnectionOptions;
      const ADriverLink: TComponent)
      : TRickSQLClientLibraryConfiguration; static;
  end;

  TRickSQLVendorLibraryAssignment = record
    DriverLink: TComponent;
    Path: string;
    class function Create(const ADriverLink: TComponent;
      const APath: string): TRickSQLVendorLibraryAssignment; static;
  end;

  TRickSQLClientLibrarySearchContext = record
    Options: TRickSQLConnectionOptions;
    Definition: TRickSQLDriverDefinition;
    class function Create(const AOptions: TRickSQLConnectionOptions;
      const ADefinition: TRickSQLDriverDefinition)
      : TRickSQLClientLibrarySearchContext; static;
  end;

  TRickSQLCoreClientLibraryResolver = class
  private
    class function CombinePath(const ABasePath: string;
      const AChildPath: string): string; static;
    class function ExecutableDirectory: string; static;
    class function CurrentPlatformName: string; static;
    class function DequotePath(const APath: string): string; static;
    class function ExpandVariables(const AValue: string): string; static;
    class function NormalizeExplicitPath(const APath: string): string; static;
    class function DatabaseEngineName(
      const AEngine: TRickSQLDatabaseEngine): string; static;
    class function LibraryNames(
      const ADefinition: TRickSQLDriverDefinition): string; static;
    class function SearchDetail(
      const AContext: TRickSQLClientLibrarySearchContext): string; static;
    class function FindSystemFile(const AFileName: string): string; static;
    class function ReadMachine(const AStream: TStream): Word; static;
    class function ReadPEMachine(const AStream: TStream;
      const AOffset: Integer): Word; static;
    class function ReadPEOffset(const AStream: TStream): Integer; static;
    class function HasDOSHeader(const AStream: TStream): Boolean; static;
    class function InspectBinary(
      const APath: string): TRickSQLBinaryInspection; static;
    class function InspectBinaryStream(const APath: string;
      var AInspection: TRickSQLBinaryInspection): Boolean; static;
    class function ArchitectureFromMachine(const AMachine: Word)
      : TRickSQLBinaryArchitecture; static;
    class function CurrentArchitecture: TRickSQLBinaryArchitecture; static;
    class function ArchitectureName(
      const AArchitecture: TRickSQLBinaryArchitecture): string; static;
    class function CreateError(const AMessage: string;
      const ADetail: string): TRickSQLError; static;
    class function ResolveInternal(const AOptions: TRickSQLConnectionOptions;
      out AError: TRickSQLError): TRickSQLClientLibraryResolution; static;
    class function ResolveByContext(
      const AContext: TRickSQLClientLibrarySearchContext;
      out AError: TRickSQLError): TRickSQLClientLibraryResolution; static;
    class function ResolveExplicit(
      const AContext: TRickSQLClientLibrarySearchContext;
      out AError: TRickSQLError): TRickSQLClientLibraryResolution; static;
    class function ResolveStandard(
      const AContext: TRickSQLClientLibrarySearchContext;
      out AError: TRickSQLError): TRickSQLClientLibraryResolution; static;
    class function ResolveEnvironmentOrDefault(
      const ADefinition: TRickSQLDriverDefinition)
      : TRickSQLClientLibraryResolution; static;
    class function LocateExplicitPath(
      const AContext: TRickSQLClientLibrarySearchContext): string; static;
    class function ResolveDirectories(
      const ADefinition: TRickSQLDriverDefinition)
      : TRickSQLClientLibraryResolution; static;
    class function IsCompatibleCandidate(const APath: string): Boolean; static;
    class function FindCandidate(const ALibrary: string;
      const ADirectory: string; var AFirstFound: string): string; static;
    class function FindInDirectory(const ADefinition: TRickSQLDriverDefinition;
      const ADirectory: string): string; static;
    class function FindInFramework(
      const ADefinition: TRickSQLDriverDefinition): string; static;
    class function LoadPathDirectories: TStringList; static;
    class function FindInEnvironment(
      const ADefinition: TRickSQLDriverDefinition): string; static;
    class function FindSystemCandidate(const ALibrary: string;
      var AFirstFound: string): string; static;
    class function FindByDriverDefault(
      const ADefinition: TRickSQLDriverDefinition): string; static;
    class function ArchitectureIsCompatible(
      const ADetected: TRickSQLBinaryArchitecture): Boolean; static;
    class function ArchitectureDetail(
      const APath: string; const ADetected: TRickSQLBinaryArchitecture): string; static;
    class function CreateArchitectureError(
      const AResolution: TRickSQLClientLibraryResolution;
      const ADetected: TRickSQLBinaryArchitecture): TRickSQLError; static;
    class function ValidateArchitecture(
      const AResolution: TRickSQLClientLibraryResolution;
      out AError: TRickSQLError): Boolean; static;
    class function ConfigureInternal(
      const AConfiguration: TRickSQLClientLibraryConfiguration;
      out AError: TRickSQLError): Boolean; static;
    class function SetVendorLibrary(
      const AAssignment: TRickSQLVendorLibraryAssignment;
      out AError: TRickSQLError): Boolean; static;
    class function VendorProperty(const ADriverLink: TComponent): PPropInfo; static;
    class function ApplyVendorLibrary(
      const AAssignment: TRickSQLVendorLibraryAssignment;
      const AProperty: PPropInfo; out AError: TRickSQLError): Boolean; static;
  public
    class function Resolve(const AOptions: TRickSQLConnectionOptions;
      out AError: TRickSQLError): TRickSQLClientLibraryResolution; static;
    class function Configure(
      const AConfiguration: TRickSQLClientLibraryConfiguration;
      out AError: TRickSQLError): Boolean; static;
  end;

implementation

uses
  // RTL
  System.SysUtils,
  // Windows
  Winapi.Windows,

  // RickSQL
  Rick.SQL.Model.Contracts,
  Rick.SQL.Core.Driver.Factory;

const
  _OPERATION_ = 'Resolução da biblioteca cliente';
  _PROPERTY_VENDOR_LIB_ = 'VendorLib';
  _FRAMEWORK_DIRECTORY_ = 'RickSQL';
  _LIBRARIES_DIRECTORY_ = 'libs';
  _ENV_PATH_ = 'PATH';
  _PLATFORM_WIN64_ = 'Win64';
  _PLATFORM_WIN32_ = 'Win32';
  _ARCH_UNKNOWN_ = 'desconhecida';
  _ENGINE_DEFAULT_ = 'banco de dados';
  _ENGINE_FIREBIRD_ = 'Firebird';
  _ENGINE_INTERBASE_ = 'InterBase';
  _ENGINE_POSTGRESQL_ = 'PostgreSQL';
  _ENGINE_SQLSERVER_ = 'SQL Server';
  _ENGINE_MYSQL_ = 'MySQL';
  _ENGINE_SQLITE_ = 'SQLite';
  _ENGINE_ORACLE_ = 'Oracle';
  _ENGINE_DB2_ = 'DB2';
  _ENGINE_SQLANYWHERE_ = 'SQL Anywhere';
  _ENGINE_INFORMIX_ = 'Informix';
  _ENGINE_ADVANTAGE_ = 'Advantage';
  _ENGINE_ACCESS_ = 'Access';
  _ENGINE_ODBC_ = 'ODBC';
  _DETAIL_SEARCH_ = 'Bibliotecas: %s. Diretório do executável: %s. ' +
    'Diretório convencional: %s.';
  _DETAIL_ARCHITECTURE_ =
    'Arquivo: %s. Arquitetura detectada: %s. Esperada: %s.';
  _DOS_SIGNATURE_ = $5A4D;
  _PE_SIGNATURE_ = $00004550;
  _MACHINE_I386_ = $014C;
  _MACHINE_AMD64_ = $8664;
  _ERROR_DRIVER_NOT_FOUND_ =
    'Não foi possível identificar o driver do banco de dados informado. ' +
    'Informe um mecanismo de banco válido antes de iniciar a conexão.';
  _ERROR_EXPLICIT_PATH_ =
    'O caminho informado para a biblioteca cliente do %s não foi localizado. ' +
    'Verifique ClientLibraryPath: %s.';
  _ERROR_LIBRARY_NOT_FOUND_ =
    'A biblioteca cliente necessária para o %s não foi localizada. ' +
    'Informe ClientLibraryPath ou disponibilize uma destas bibliotecas: %s.';
  _ERROR_ARCHITECTURE_ =
    'A biblioteca cliente "%s" é incompatível com a arquitetura %s da aplicação. ' +
    'Disponibilize uma versão %s da biblioteca.';
  _ERROR_DRIVER_LINK_REQUIRED_ =
    'O driver link não foi criado para configurar a biblioteca cliente. ' +
    'Crie o contexto do driver antes de configurar VendorLib.';
  _ERROR_VENDOR_LIB_UNAVAILABLE_ =
    'O driver selecionado não permite configurar a biblioteca cliente automaticamente. ' +
    'Configure a biblioteca cliente pelo mecanismo padrão do fornecedor.';
  _ERROR_VENDOR_LIB_CONFIGURE_ =
    'Não foi possível configurar a biblioteca cliente no driver selecionado. ' +
    'Verifique se o caminho informado é válido para a arquitetura da aplicação.';
  _ERROR_UNEXPECTED_ =
    'Não foi possível resolver a biblioteca cliente do banco de dados. ' +
    'Verifique o mecanismo do banco e o caminho da biblioteca cliente.';

class function TRickSQLClientLibraryResolution.Empty
  : TRickSQLClientLibraryResolution;
begin
  Result.Success := False;
  Result.Required := False;
  Result.Path := '';
  Result.Source := TRickSQLClientLibrarySource.NotRequired;
end;

class function TRickSQLClientLibraryResolution.Located(const APath: string;
  const ASource: TRickSQLClientLibrarySource)
  : TRickSQLClientLibraryResolution;
begin
  Result := Empty;
  Result.Success := True;
  Result.Required := True;
  Result.Path := APath;
  Result.Source := ASource;
end;

class function TRickSQLClientLibraryResolution.NotRequired
  : TRickSQLClientLibraryResolution;
begin
  Result := Empty;
  Result.Success := True;
end;

class function TRickSQLClientLibraryConfiguration.Create(
  const AOptions: TRickSQLConnectionOptions;
  const ADriverLink: TComponent): TRickSQLClientLibraryConfiguration;
begin
  Result.Options := AOptions;
  Result.DriverLink := ADriverLink;
end;

class function TRickSQLVendorLibraryAssignment.Create(
  const ADriverLink: TComponent;
  const APath: string): TRickSQLVendorLibraryAssignment;
begin
  Result.DriverLink := ADriverLink;
  Result.Path := APath;
end;

class function TRickSQLClientLibrarySearchContext.Create(
  const AOptions: TRickSQLConnectionOptions;
  const ADefinition: TRickSQLDriverDefinition)
  : TRickSQLClientLibrarySearchContext;
begin
  Result.Options := AOptions;
  Result.Definition := ADefinition;
end;

class function TRickSQLCoreClientLibraryResolver.CombinePath(
  const ABasePath: string; const AChildPath: string): string;
begin
  Result := IncludeTrailingPathDelimiter(ABasePath) + AChildPath;
end;

class function TRickSQLCoreClientLibraryResolver.ExecutableDirectory: string;
begin
  Result := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

class function TRickSQLCoreClientLibraryResolver.CurrentPlatformName: string;
begin
  if SizeOf(Pointer) = 8 then
    Exit(_PLATFORM_WIN64_);

  Result := _PLATFORM_WIN32_;
end;

class function TRickSQLCoreClientLibraryResolver.DequotePath(
  const APath: string): string;
begin
  Result := Trim(APath);
  if Length(Result) < 2 then
    Exit;
  if (Result[1] <> '"') or (Result[Length(Result)] <> '"') then
    Exit;
  Result := Copy(Result, 2, Length(Result) - 2);
end;

class function TRickSQLCoreClientLibraryResolver.ExpandVariables(
  const AValue: string): string;
var
  LSize: DWORD;
begin
  Result := AValue;
  LSize := ExpandEnvironmentStrings(PChar(AValue), nil, 0);
  if LSize = 0 then
    Exit;
  SetLength(Result, LSize);
  ExpandEnvironmentStrings(PChar(AValue), PChar(Result), LSize);
  SetLength(Result, LSize - 1);
end;

class function TRickSQLCoreClientLibraryResolver.NormalizeExplicitPath(
  const APath: string): string;
var
  LPath: string;
begin
  LPath := ExpandVariables(DequotePath(APath));
  if LPath = '' then
    Exit('');
  if (ExtractFileDrive(LPath) = '') and (LPath[1] <> PathDelim) then
    LPath := CombinePath(ExecutableDirectory, LPath);
  Result := ExpandFileName(LPath);
end;

class function TRickSQLCoreClientLibraryResolver.DatabaseEngineName(
  const AEngine: TRickSQLDatabaseEngine): string;
const
  _MAP_ENGINE_: array[TRickSQLDatabaseEngine] of string = (
    _ENGINE_DEFAULT_,      // Unknown
    _ENGINE_FIREBIRD_,     // Firebird
    _ENGINE_INTERBASE_,    // InterBase
    _ENGINE_POSTGRESQL_,   // PostgreSQL
    _ENGINE_SQLSERVER_,    // SQLServer
    _ENGINE_MYSQL_,        // MySQL
    _ENGINE_SQLITE_,       // SQLite
    _ENGINE_ORACLE_,       // Oracle
    _ENGINE_DB2_,          // DB2
    _ENGINE_SQLANYWHERE_,  // SQLAnywhere
    _ENGINE_INFORMIX_,     // Informix
    _ENGINE_ADVANTAGE_,    // Advantage
    _ENGINE_ACCESS_,       // Access
    _ENGINE_ODBC_          // ODBC
  );
begin
  Result := _MAP_ENGINE_[AEngine];
end;

class function TRickSQLCoreClientLibraryResolver.LibraryNames(
  const ADefinition: TRickSQLDriverDefinition): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to Length(ADefinition.ClientLibraries) - 1 do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + ADefinition.ClientLibraries[LIndex];
  end;
end;

class function TRickSQLCoreClientLibraryResolver.SearchDetail(
  const AContext: TRickSQLClientLibrarySearchContext): string;
var
  LFrameworkDirectory: string;
begin
  LFrameworkDirectory := CombinePath(ExecutableDirectory,
    _FRAMEWORK_DIRECTORY_);
  LFrameworkDirectory := CombinePath(LFrameworkDirectory,
    _LIBRARIES_DIRECTORY_);
  Result := Format(_DETAIL_SEARCH_, [LibraryNames(AContext.Definition),
    ExecutableDirectory, LFrameworkDirectory]);
end;

class function TRickSQLCoreClientLibraryResolver.FindSystemFile(
  const AFileName: string): string;
var
  LBuffer: string;
  LLength: DWORD;
  LFilePart: PChar;
begin
  Result := '';
  LFilePart := nil;
  SetLength(LBuffer, 32768);
  LLength := SearchPath(nil, PChar(AFileName), nil,
    DWORD(Length(LBuffer)), PChar(LBuffer), LFilePart);
  if (LLength = 0) or (LLength >= DWORD(Length(LBuffer))) then
    Exit;
  SetLength(LBuffer, LLength);
  Result := LBuffer;
end;

class function TRickSQLCoreClientLibraryResolver.HasDOSHeader(
  const AStream: TStream): Boolean;
var
  LDosSignature: Word;
begin
  Result := False;
  if not Assigned(AStream) or (AStream.Size < 70) then
    Exit;
  AStream.Position := 0;
  AStream.ReadBuffer(LDosSignature, SizeOf(LDosSignature));
  Result := LDosSignature = _DOS_SIGNATURE_;
end;

class function TRickSQLCoreClientLibraryResolver.ReadPEOffset(
  const AStream: TStream): Integer;
begin
  Result := -1;
  AStream.Position := $3C;
  AStream.ReadBuffer(Result, SizeOf(Result));
  if (Result < 0) or (Int64(Result) + 6 > AStream.Size) then
    Result := -1;
end;

class function TRickSQLCoreClientLibraryResolver.ReadPEMachine(
  const AStream: TStream; const AOffset: Integer): Word;
var
  LPESignature: Cardinal;
begin
  Result := 0;
  if AOffset < 0 then
    Exit;
  AStream.Position := AOffset;
  AStream.ReadBuffer(LPESignature, SizeOf(LPESignature));
  if LPESignature <> _PE_SIGNATURE_ then
    Exit;
  AStream.ReadBuffer(Result, SizeOf(Result));
end;

class function TRickSQLCoreClientLibraryResolver.ReadMachine(
  const AStream: TStream): Word;
var
  LOffset: Integer;
begin
  Result := 0;
  if not HasDOSHeader(AStream) then
    Exit;
  LOffset := ReadPEOffset(AStream);
  Result := ReadPEMachine(AStream, LOffset);
end;

class function TRickSQLCoreClientLibraryResolver.InspectBinaryStream(
  const APath: string; var AInspection: TRickSQLBinaryInspection): Boolean;
var
  LStream: TFileStream;
begin
  LStream := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
  try
    AInspection.Machine := ReadMachine(LStream);
    Result := True;
  finally
    LStream.Free;
  end;
end;

class function TRickSQLCoreClientLibraryResolver.InspectBinary(
  const APath: string): TRickSQLBinaryInspection;
begin
  Result.Success := False;
  Result.Machine := 0;
  Result.Detail := '';
  try
    Result.Success := InspectBinaryStream(APath, Result);
  except
    on E: Exception do
      Result.Detail := E.Message;
  end;
end;

class function TRickSQLCoreClientLibraryResolver.ArchitectureFromMachine(
  const AMachine: Word): TRickSQLBinaryArchitecture;
begin
  case AMachine of
    _MACHINE_I386_: Result := TRickSQLBinaryArchitecture.Win32;
    _MACHINE_AMD64_: Result := TRickSQLBinaryArchitecture.Win64;
  else
    Result := TRickSQLBinaryArchitecture.Unknown;
  end;
end;

class function TRickSQLCoreClientLibraryResolver.CurrentArchitecture
  : TRickSQLBinaryArchitecture;
begin
  if SizeOf(Pointer) = 8 then
    Exit(TRickSQLBinaryArchitecture.Win64);

  Result := TRickSQLBinaryArchitecture.Win32;
end;

class function TRickSQLCoreClientLibraryResolver.ArchitectureName(
  const AArchitecture: TRickSQLBinaryArchitecture): string;
begin
  case AArchitecture of
    TRickSQLBinaryArchitecture.Win32: Result := _PLATFORM_WIN32_;
    TRickSQLBinaryArchitecture.Win64: Result := _PLATFORM_WIN64_;
  else
    Result := _ARCH_UNKNOWN_;
  end;
end;

class function TRickSQLCoreClientLibraryResolver.CreateError(
  const AMessage: string; const ADetail: string): TRickSQLError;
begin
  Result := TRickSQLError.Create(TRickSQLErrorKind.ClientLibrary, AMessage);
  Result.TechnicalDetail := ADetail;
  Result.Operation := _OPERATION_;
end;

class function TRickSQLCoreClientLibraryResolver.IsCompatibleCandidate(
  const APath: string): Boolean;
var
  LInspection: TRickSQLBinaryInspection;
  LArchitecture: TRickSQLBinaryArchitecture;
begin
  LInspection := InspectBinary(APath);
  if not LInspection.Success then
    Exit(True);
  LArchitecture := ArchitectureFromMachine(LInspection.Machine);
  Result := ArchitectureIsCompatible(LArchitecture);
end;

class function TRickSQLCoreClientLibraryResolver.FindCandidate(
  const ALibrary: string; const ADirectory: string;
  var AFirstFound: string): string;
var
  LCandidate: string;
begin
  Result := '';
  LCandidate := ExpandFileName(CombinePath(ADirectory, ALibrary));
  if not FileExists(LCandidate) then
    Exit;
  if AFirstFound = '' then
    AFirstFound := LCandidate;
  if IsCompatibleCandidate(LCandidate) then
    Result := LCandidate;
end;

class function TRickSQLCoreClientLibraryResolver.FindInDirectory(
  const ADefinition: TRickSQLDriverDefinition;
  const ADirectory: string): string;
var
  LLibrary: string;
  LFirstFound: string;
begin
  Result := '';
  LFirstFound := '';
  if not DirectoryExists(ADirectory) then
    Exit;
  for LLibrary in ADefinition.ClientLibraries do
  begin
    Result := FindCandidate(LLibrary, ADirectory, LFirstFound);
    if Result <> '' then
      Exit;
  end;
  Result := LFirstFound;
end;

class function TRickSQLCoreClientLibraryResolver.FindInFramework(
  const ADefinition: TRickSQLDriverDefinition): string;
var
  LBaseDirectory: string;
  LPlatformDirectory: string;
begin
  LBaseDirectory := CombinePath(ExecutableDirectory, _FRAMEWORK_DIRECTORY_);
  LBaseDirectory := CombinePath(LBaseDirectory, _LIBRARIES_DIRECTORY_);
  LPlatformDirectory := CombinePath(LBaseDirectory, CurrentPlatformName);
  Result := FindInDirectory(ADefinition, LPlatformDirectory);
  if Result <> '' then
    Exit;
  Result := FindInDirectory(ADefinition, LBaseDirectory);
end;

class function TRickSQLCoreClientLibraryResolver.LoadPathDirectories
  : TStringList;
begin
  Result := TStringList.Create;
  Result.StrictDelimiter := True;
  Result.Delimiter := ';';
  Result.DelimitedText := GetEnvironmentVariable(_ENV_PATH_);
end;

class function TRickSQLCoreClientLibraryResolver.FindInEnvironment(
  const ADefinition: TRickSQLDriverDefinition): string;
var
  LDirectories: TStringList;
  LDirectory: string;
begin
  Result := '';
  LDirectories := LoadPathDirectories;
  try
    for LDirectory in LDirectories do
    begin
      Result := FindInDirectory(ADefinition,
        ExpandVariables(DequotePath(LDirectory)));
      if Result <> '' then
        Exit;
    end;
  finally
    LDirectories.Free;
  end;
end;

class function TRickSQLCoreClientLibraryResolver.FindSystemCandidate(
  const ALibrary: string; var AFirstFound: string): string;
begin
  Result := FindSystemFile(ALibrary);
  if Result = '' then
    Exit;
  if AFirstFound = '' then
    AFirstFound := Result;
  if not IsCompatibleCandidate(Result) then
    Result := '';
end;

class function TRickSQLCoreClientLibraryResolver.FindByDriverDefault(
  const ADefinition: TRickSQLDriverDefinition): string;
var
  LLibrary: string;
  LFirstFound: string;
begin
  Result := '';
  LFirstFound := '';
  for LLibrary in ADefinition.ClientLibraries do
  begin
    Result := FindSystemCandidate(LLibrary, LFirstFound);
    if Result <> '' then
      Exit;
  end;
  Result := LFirstFound;
end;

class function TRickSQLCoreClientLibraryResolver.ResolveExplicit(
  const AContext: TRickSQLClientLibrarySearchContext;
  out AError: TRickSQLError): TRickSQLClientLibraryResolution;
var
  LFoundPath: string;
begin
  LFoundPath := LocateExplicitPath(AContext);
  if LFoundPath <> '' then
    Exit(TRickSQLClientLibraryResolution.Located(LFoundPath,
      TRickSQLClientLibrarySource.ConfiguredPath));
  AError := CreateError(Format(_ERROR_EXPLICIT_PATH_, [
    DatabaseEngineName(AContext.Definition.Engine),
    AContext.Options.ClientLibraryPath]),
    NormalizeExplicitPath(AContext.Options.ClientLibraryPath));
  Result := TRickSQLClientLibraryResolution.Empty;
end;

class function TRickSQLCoreClientLibraryResolver.LocateExplicitPath(
  const AContext: TRickSQLClientLibrarySearchContext): string;
var
  LPath: string;
begin
  LPath := NormalizeExplicitPath(AContext.Options.ClientLibraryPath);
  if FileExists(LPath) then
    Exit(LPath);
  Result := '';
  if DirectoryExists(LPath) then
    Result := FindInDirectory(AContext.Definition, LPath);
end;

class function TRickSQLCoreClientLibraryResolver.ResolveDirectories(
  const ADefinition: TRickSQLDriverDefinition)
  : TRickSQLClientLibraryResolution;
var
  LPath: string;
begin
  LPath := FindInDirectory(ADefinition, ExecutableDirectory);
  if LPath <> '' then
    Exit(TRickSQLClientLibraryResolution.Located(LPath,
      TRickSQLClientLibrarySource.ExecutableDirectory));
  LPath := FindInFramework(ADefinition);
  if LPath <> '' then
    Exit(TRickSQLClientLibraryResolution.Located(LPath,
      TRickSQLClientLibrarySource.FrameworkDirectory));
  Result := TRickSQLClientLibraryResolution.Empty;
end;

class function TRickSQLCoreClientLibraryResolver.ResolveStandard(
  const AContext: TRickSQLClientLibrarySearchContext;
  out AError: TRickSQLError): TRickSQLClientLibraryResolution;
begin
  Result := ResolveDirectories(AContext.Definition);
  if Result.Success then
    Exit;
  Result := ResolveEnvironmentOrDefault(AContext.Definition);
  if Result.Success then
    Exit;
  AError := CreateError(Format(_ERROR_LIBRARY_NOT_FOUND_, [
    DatabaseEngineName(AContext.Definition.Engine),
    LibraryNames(AContext.Definition)]), SearchDetail(AContext));
end;

class function TRickSQLCoreClientLibraryResolver.ResolveEnvironmentOrDefault(
  const ADefinition: TRickSQLDriverDefinition)
  : TRickSQLClientLibraryResolution;
var
  LPath: string;
begin
  LPath := FindInEnvironment(ADefinition);
  if LPath <> '' then
    Exit(TRickSQLClientLibraryResolution.Located(LPath,
      TRickSQLClientLibrarySource.EnvironmentPath));
  LPath := FindByDriverDefault(ADefinition);
  if LPath <> '' then
    Exit(TRickSQLClientLibraryResolution.Located(LPath,
      TRickSQLClientLibrarySource.DriverDefault));
  Result := TRickSQLClientLibraryResolution.Empty;
end;

class function TRickSQLCoreClientLibraryResolver.ArchitectureIsCompatible(
  const ADetected: TRickSQLBinaryArchitecture): Boolean;
begin
  Result := (ADetected = TRickSQLBinaryArchitecture.Unknown) or
    (ADetected = CurrentArchitecture);
end;

class function TRickSQLCoreClientLibraryResolver.ArchitectureDetail(
  const APath: string; const ADetected: TRickSQLBinaryArchitecture): string;
begin
  Result := Format(_DETAIL_ARCHITECTURE_, [APath,
    ArchitectureName(ADetected), ArchitectureName(CurrentArchitecture)]);
end;

class function TRickSQLCoreClientLibraryResolver.CreateArchitectureError(
  const AResolution: TRickSQLClientLibraryResolution;
  const ADetected: TRickSQLBinaryArchitecture): TRickSQLError;
begin
  Result := CreateError(Format(_ERROR_ARCHITECTURE_, [
    ExtractFileName(AResolution.Path), ArchitectureName(CurrentArchitecture),
    ArchitectureName(CurrentArchitecture)]),
    ArchitectureDetail(AResolution.Path, ADetected));
end;

class function TRickSQLCoreClientLibraryResolver.ValidateArchitecture(
  const AResolution: TRickSQLClientLibraryResolution;
  out AError: TRickSQLError): Boolean;
var
  LInspection: TRickSQLBinaryInspection;
  LDetected: TRickSQLBinaryArchitecture;
begin
  LInspection := InspectBinary(AResolution.Path);
  if not LInspection.Success then
  begin
    AError := CreateError(_ERROR_UNEXPECTED_, LInspection.Detail);
    Exit(False);
  end;
  LDetected := ArchitectureFromMachine(LInspection.Machine);
  Result := ArchitectureIsCompatible(LDetected);
  if not Result then
    AError := CreateArchitectureError(AResolution, LDetected);
end;

class function TRickSQLCoreClientLibraryResolver.ResolveByContext(
  const AContext: TRickSQLClientLibrarySearchContext;
  out AError: TRickSQLError): TRickSQLClientLibraryResolution;
begin
  if Length(AContext.Definition.ClientLibraries) = 0 then
    Exit(TRickSQLClientLibraryResolution.NotRequired);
  if Trim(AContext.Options.ClientLibraryPath) <> '' then
    Result := ResolveExplicit(AContext, AError)
  else
    Result := ResolveStandard(AContext, AError);
  if Result.Success and not ValidateArchitecture(Result, AError) then
    Result := TRickSQLClientLibraryResolution.Empty;
end;

class function TRickSQLCoreClientLibraryResolver.ResolveInternal(
  const AOptions: TRickSQLConnectionOptions;
  out AError: TRickSQLError): TRickSQLClientLibraryResolution;
var
  LProvider: IRickSQLDriverProvider;
  LContext: TRickSQLClientLibrarySearchContext;
begin
  AError := TRickSQLError.Empty;
  LProvider := TRickSQLCoreDriverFactory.Resolve(AOptions.Engine);
  if LProvider = nil then
  begin
    AError := CreateError(_ERROR_DRIVER_NOT_FOUND_, '');
    Exit(TRickSQLClientLibraryResolution.Empty);
  end;
  LContext := TRickSQLClientLibrarySearchContext.Create(
    AOptions, LProvider.Definition);
  Result := ResolveByContext(LContext, AError);
end;

class function TRickSQLCoreClientLibraryResolver.Resolve(
  const AOptions: TRickSQLConnectionOptions;
  out AError: TRickSQLError): TRickSQLClientLibraryResolution;
begin
  try
    Result := ResolveInternal(AOptions, AError);
  except
    on E: Exception do
    begin
      AError := CreateError(_ERROR_UNEXPECTED_, E.Message);
      Result := TRickSQLClientLibraryResolution.Empty;
    end;
  end;
end;

class function TRickSQLCoreClientLibraryResolver.VendorProperty(
  const ADriverLink: TComponent): PPropInfo;
begin
  Result := nil;
  if Assigned(ADriverLink) then
    Result := GetPropInfo(ADriverLink.ClassInfo, _PROPERTY_VENDOR_LIB_);
end;

class function TRickSQLCoreClientLibraryResolver.ApplyVendorLibrary(
  const AAssignment: TRickSQLVendorLibraryAssignment;
  const AProperty: PPropInfo; out AError: TRickSQLError): Boolean;
begin
  try
    SetStrProp(AAssignment.DriverLink, AProperty, AAssignment.Path);
    Result := True;
  except
    on E: Exception do
    begin
      AError := CreateError(_ERROR_VENDOR_LIB_CONFIGURE_, E.Message);
      Result := False;
    end;
  end;
end;

class function TRickSQLCoreClientLibraryResolver.SetVendorLibrary(
  const AAssignment: TRickSQLVendorLibraryAssignment;
  out AError: TRickSQLError): Boolean;
var
  LProperty: PPropInfo;
begin
  LProperty := VendorProperty(AAssignment.DriverLink);
  if not Assigned(LProperty) then
  begin
    AError := CreateError(_ERROR_VENDOR_LIB_UNAVAILABLE_,
      AAssignment.DriverLink.ClassName);
    Exit(False);
  end;
  Result := ApplyVendorLibrary(AAssignment, LProperty, AError);
end;

class function TRickSQLCoreClientLibraryResolver.ConfigureInternal(
  const AConfiguration: TRickSQLClientLibraryConfiguration;
  out AError: TRickSQLError): Boolean;
var
  LResolution: TRickSQLClientLibraryResolution;
begin
  AError := TRickSQLError.Empty;
  if not Assigned(AConfiguration.DriverLink) then
  begin
    AError := CreateError(_ERROR_DRIVER_LINK_REQUIRED_, '');
    Exit(False);
  end;
  LResolution := Resolve(AConfiguration.Options, AError);
  if not LResolution.Success then
    Exit(False);
  if not LResolution.Required then
    Exit(True);
  Result := SetVendorLibrary(TRickSQLVendorLibraryAssignment.Create(
    AConfiguration.DriverLink, LResolution.Path), AError);
end;

class function TRickSQLCoreClientLibraryResolver.Configure(
  const AConfiguration: TRickSQLClientLibraryConfiguration;
  out AError: TRickSQLError): Boolean;
begin
  try
    Result := ConfigureInternal(AConfiguration, AError);
  except
    on E: Exception do
    begin
      AError := CreateError(_ERROR_UNEXPECTED_, E.Message);
      Result := False;
    end;
  end;
end;

end.
