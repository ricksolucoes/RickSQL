unit Rick.SQL.Interf;

interface

uses
  // Data
  Data.DB,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Model.Error,
  Rick.SQL.Model.Command,
  Rick.SQL.Model.Parameter,
  Rick.SQL.Core.Open.Executor,
  Rick.SQL.Core.Command.Executor,
  Rick.SQL.Model.Command.Options,
  Rick.SQL.Model.Execution.Result,
  Rick.SQL.Model.Connection.Options;

type
  TRickSQLDataSet                   = Data.DB.TDataSet;
  TRickSQLDatabaseEngine            = Rick.SQL.Model.Types.TRickSQLDatabaseEngine;
  TRickSQLErrorKind                 = Rick.SQL.Model.Types.TRickSQLErrorKind;
  TRickSQLConnectionParameter       = Rick.SQL.Model.Connection.Options.TRickSQLConnectionParameter;
  TRickSQLConnectionParameterArray  = Rick.SQL.Model.Connection.Options.TRickSQLConnectionParameterArray;
  TRickSQLConnectionOptions         = Rick.SQL.Model.Connection.Options.TRickSQLConnectionOptions;
  TRickSQLMaterializationOptions    = Rick.SQL.Model.Command.Options.TRickSQLMaterializationOptions;
  TRickSQLCommandOptions            = Rick.SQL.Model.Command.Options.TRickSQLCommandOptions;
  TRickSQLParameter                 = Rick.SQL.Model.Parameter.TRickSQLParameter;
  TRickSQLParameterArray            = Rick.SQL.Model.Parameter.TRickSQLParameterArray;
  TRickSQLCommand                   = Rick.SQL.Model.Command.TRickSQLCommand;
  TRickSQLError                     = Rick.SQL.Model.Error.TRickSQLError;
  TRickSQLExecutionResult           = Rick.SQL.Model.Execution.Result.TRickSQLExecutionResult;

  IRickSQL                          = interface;
  IRickSQLConnectionOptions         = interface;
  IRickSQLCommand                   = interface;
  IRickSQLParameter                 = interface;
  IRickSQLCommandOptions            = interface;
  IRickSQLMaterializationOptions    = interface;
  IRickSQLCursor                    = interface;
  IRickSQLResult                    = interface;

  IRickSQL = interface
    ['{63214E8F-9245-4FD7-BDB6-0B06D173C7A1}']
    function ConnectionOptions: IRickSQLConnectionOptions;
    function Command: IRickSQLCommand;
    function Cursor: IRickSQLCursor;
    function Result: IRickSQLResult;

    function Owner(const AOwner : Boolean) : IRickSQL;
  end;

  IRickSQLConnectionOptions = interface
    ['{ED31305A-B0D3-4F1A-9BC0-47544C79C2A3}']
    function Engine(const AEngine: TRickSQLDatabaseEngine): IRickSQLConnectionOptions;
    function Server(const AServer: string): IRickSQLConnectionOptions;
    function Port(const APort: Integer): IRickSQLConnectionOptions;
    function Database(const ADatabase: string): IRickSQLConnectionOptions;
    function UserName(const AUserName: string): IRickSQLConnectionOptions;
    function Password(const APassword: string): IRickSQLConnectionOptions;
    function CharacterSet(const ACharacterSet: string): IRickSQLConnectionOptions;
    function ConnectTimeout(const AConnectTimeout: Integer): IRickSQLConnectionOptions;
    function LibraryPath(const ALibraryPath: string): IRickSQLConnectionOptions;
    function AddConnectionParameter(const AName: string; const AValue: string): IRickSQLConnectionOptions;
    function ClearConnectionParameter: IRickSQLConnectionOptions;

    function Back : IRickSQL;
  end;

  IRickSQLCommand = interface
    ['{5D5D5813-B3B9-4A20-9721-F0B2B645DEDB}']
    function Option : IRickSQLCommandOptions;
    function Parameter : IRickSQLParameter;

    function SQL(const ASQL : string) : IRickSQLCommand;

    function Back : IRickSQL;
  end;

  IRickSQLParameter  = interface
    ['{04BC15FE-2183-44EE-B136-37E53A4EC1CF}']

    function Name(const AName: string): IRickSQLParameter;
    function Value(const AValue: Variant): IRickSQLParameter;
    function DataType(const ADataType: TFieldType): IRickSQLParameter;
    function Size(const ASize: Integer): IRickSQLParameter;
    function Direction(const ADirection: TParamType): IRickSQLParameter;
    function IsNull(const ANull: Boolean): IRickSQLParameter;

    function Clear : IRickSQLParameter;
    function Default : IRickSQLParameter;

    function Add : IRickSQLParameter;
    function AddNull : IRickSQLParameter;
    function AddVariant : IRickSQLParameter;

    function Return : IRickSQLCommand;
  end;

  IRickSQLCommandOptions = interface
    ['{97214BCC-10AF-44B2-B7B8-317A18940180}']

    function Materialization : IRickSQLMaterializationOptions;

    function TimeOut(const ATimeOut : Integer) : IRickSQLCommand;
    function Transation(const ATransation : Boolean) : IRickSQLCommand;
    function FetchAll(const AFetchAll : Boolean) : IRickSQLCommand;
    function MaxRedord(const AMaxRedord : Integer) : IRickSQLCommand;

    function Return : IRickSQLCommand;
  end;

  IRickSQLMaterializationOptions = interface
    ['{CF12BD96-CC86-4E9C-9FF8-20E1BCE4C138}']

    function Position(const APosition : Boolean) : IRickSQLMaterializationOptions;
    function Preserve(const APreserve : Boolean) : IRickSQLMaterializationOptions;

    function ToBack :  IRickSQLCommandOptions;
  end;

  IRickSQLCursor = interface
    ['{4C561634-3358-412F-9DA6-D31E1111DEE0}']

    function Open: IRickSQLCursor;
    function Execute: IRickSQLCursor;


    function Back : IRickSQL;
  end;

  IRickSQLResult = interface
    ['{DD9CAA98-7542-4FB9-B8C4-4F88E8020C05}']
    function DataSet : TDataSet;
    function Error : string;
    function ErrorFull : TRickSQLExecutionResult;
  end;


  TRickSQLInterf = class(TInterfacedObject, IRickSQL, IRickSQLConnectionOptions,
                                            IRickSQLCommand, IRickSQLCommandOptions,
                                            IRickSQLMaterializationOptions, IRickSQLParameter,
                                            IRickSQLCursor, IRickSQLResult)
  private
    //Executor
    FDataSet            : TDataSet;
    FError              : string;
    FErroFull           : TRickSQLExecutionResult;
    FOwner              : Boolean;

    //Connection Options
    FEngine             : TRickSQLDatabaseEngine;
    FServer             : string;
    FPort               : Integer;
    FDatabase           : string;
    FUserName           : string;
    FPassword           : string;
    FCharacterSet       : string;
    FConnectTimeout     : Integer;
    FClientLibraryPath  : string;
    FExtraParameters    : TRickSQLConnectionParameterArray;

    //Command
    FSQL                : string;
    FParameters         : TRickSQLParameterArray;

    //Command Options
    FTimeout            : Integer;
    FTransaction        : Boolean;
    FFetchAll           : Boolean;
    FMaxRecords         : Integer;


    //Materialization Options
    FPosition           : Boolean;
    FPreserve           : Boolean;

    //Parameter
    FName               : string;
    FValue              : Variant;
    FDataType           : TFieldType;
    FSize               : Integer;
    FDirection          : TParamType;
    FNull               : Boolean;


    procedure ConnectionOptionsDefault;
    procedure CommandParameterDefault;
    procedure CommandOptionsDefault;
    procedure MaterializationOptionsDefault;

    procedure ErrorDefault;

    function BuildConnection: TRickSQLConnectionOptions;
    function BuildCommand: TRickSQLCommand;

  protected
    //Rick SQL
    function ConnectionOptions: IRickSQLConnectionOptions;
    function Command: IRickSQLCommand;
    function Cursor: IRickSQLCursor;
    function Result: IRickSQLResult;
    function Owner(const AOwner : Boolean) : IRickSQL;

    //Connection Options
    function Engine(const AEngine: TRickSQLDatabaseEngine): IRickSQLConnectionOptions;
    function Server(const AServer: string): IRickSQLConnectionOptions;
    function Port(const APort: Integer): IRickSQLConnectionOptions;
    function Database(const ADatabase: string): IRickSQLConnectionOptions;
    function UserName(const AUserName: string): IRickSQLConnectionOptions;
    function Password(const APassword: string): IRickSQLConnectionOptions;
    function CharacterSet(const ACharacterSet: string): IRickSQLConnectionOptions;
    function ConnectTimeout(const AConnectTimeout: Integer): IRickSQLConnectionOptions;
    function LibraryPath(const ALibraryPath: string): IRickSQLConnectionOptions;

    function AddConnectionParameter(const AName: string; const AValue: string): IRickSQLConnectionOptions;
    function ClearConnectionParameter: IRickSQLConnectionOptions;


    //Command
    function Option : IRickSQLCommandOptions;
    function Parameter : IRickSQLParameter;
    function SQL(const ASQL : string) : IRickSQLCommand;

    //Parameter
    function Name(const AName: string): IRickSQLParameter;
    function Value(const AValue: Variant): IRickSQLParameter;
    function DataType(const ADataType: TFieldType): IRickSQLParameter;
    function Size(const ASize: Integer): IRickSQLParameter;
    function Direction(const ADirection: TParamType): IRickSQLParameter;
    function IsNull(const ANull: Boolean): IRickSQLParameter;

    function Clear : IRickSQLParameter;
    function Default : IRickSQLParameter;

    function Add : IRickSQLParameter;
    function AddNull : IRickSQLParameter;
    function AddVariant : IRickSQLParameter;


    //Command Options
    function Materialization : IRickSQLMaterializationOptions;

    function TimeOut(const ATimeOut : Integer) : IRickSQLCommand;
    function Transation(const ATransation : Boolean) : IRickSQLCommand;
    function FetchAll(const AFetchAll : Boolean) : IRickSQLCommand;
    function MaxRedord(const AMaxRedord : Integer) : IRickSQLCommand;

    //Materialization Options
    function Position(const APosition : Boolean) : IRickSQLMaterializationOptions;
    function Preserve(const APreserve : Boolean) : IRickSQLMaterializationOptions;

    //Abrir ou Executar
    function Open: IRickSQLCursor;
    function Execute: IRickSQLCursor;

    //Resultado
    function DataSet : TDataSet;
    function Error : string;
    function ErrorFull : TRickSQLExecutionResult;

    function Back : IRickSQL;
    function Return : IRickSQLCommand;
    function ToBack :  IRickSQLCommandOptions;

    Constructor Create;
  public
    Destructor Destroy; override;
    class function New: IRickSQL;
  end;

implementation

uses
  //RTL
  System.Variants,
  System.SysUtils;

{ TRickSQLInterf }

function TRickSQLInterf.Back: IRickSQL;
begin
  Result := Self;
end;

function TRickSQLInterf.BuildConnection: TRickSQLConnectionOptions;
begin
  Result := TRickSQLConnectionOptions.Create(FEngine);
  Result.Server            := FServer;
  Result.Port              := FPort;
  Result.Database          := FDatabase;
  Result.UserName          := FUserName;
  Result.Password          := FPassword;
  Result.CharacterSet      := FCharacterSet;
  Result.ConnectTimeout    := FConnectTimeout;
  Result.ClientLibraryPath := FClientLibraryPath;
  Result.ExtraParameters   := FExtraParameters;
end;

function TRickSQLInterf.BuildCommand: TRickSQLCommand;
var
  LParameter : TRickSQLParameter;
begin
  Result := TRickSQLCommand.Create(BuildConnection, FSQL);
  Result.Options.CommandTimeout := FTimeout;
  Result.Options.UseTransaction := FTransaction;
  Result.Options.FetchAll       := FFetchAll;
  Result.Options.MaxRecords     := FMaxRecords;
  Result.Options.Materialization.PositionAtFirstRecord := FPosition;
  Result.Options.Materialization.PreserveFieldMetadata := FPreserve;

  for LParameter in FParameters do
    Result.AddParameter(LParameter);
end;

function TRickSQLInterf.Command: IRickSQLCommand;
begin
  Result := Self;
end;

procedure TRickSQLInterf.CommandOptionsDefault;
begin
  FTimeout        := 0;
  FTransaction    := True;
  FFetchAll       := True;
  FMaxRecords     := 0;
end;

procedure TRickSQLInterf.CommandParameterDefault;
begin
  FName             := EmptyStr;
  FValue            := Null;
  FDataType         := ftUnknown;
  FSize             := 0;
  FDirection        := ptInput;
  FNull             := False;

end;

function TRickSQLInterf.ConnectionOptions: IRickSQLConnectionOptions;
begin
  Result := Self;
end;

procedure TRickSQLInterf.ConnectionOptionsDefault;
begin
  FServer             := EmptyStr;
  FPort               := 0;
  FDatabase           := EmptyStr;
  FUserName           := EmptyStr;
  FPassword           := EmptyStr;
  FCharacterSet       := EmptyStr;
  FConnectTimeout     := 0;
  FClientLibraryPath  := EmptyStr;
  FExtraParameters    := nil;

end;

function TRickSQLInterf.Engine(
  const AEngine: TRickSQLDatabaseEngine): IRickSQLConnectionOptions;
begin
  Result := Self;
  FEngine := AEngine;
end;

function TRickSQLInterf.Error: string;
begin
  Result := FError;
end;

procedure TRickSQLInterf.ErrorDefault;
begin
  FError := EmptyStr;
  FErroFull := TRickSQLExecutionResult.Default;

  if FOwner AND Assigned(FDataSet) then
    FreeAndNil(FDataSet);
end;

function TRickSQLInterf.ErrorFull: TRickSQLExecutionResult;
begin
  Result := FErroFull;
end;

function TRickSQLInterf.Server(const AServer: string): IRickSQLConnectionOptions;
begin
  Result := Self;
  FServer := AServer;
end;

function TRickSQLInterf.Size(const ASize: Integer): IRickSQLParameter;
begin
  Result := Self;
  FSize := ASize;
end;

function TRickSQLInterf.SQL(const ASQL: string): IRickSQLCommand;
begin
  Result := Self;
  FSQL := ASQL;
end;

function TRickSQLInterf.TimeOut(const ATimeOut: Integer): IRickSQLCommand;
begin
  Result:= Self;
  FTimeout := ATimeOut;
end;

function TRickSQLInterf.ToBack: IRickSQLCommandOptions;
begin
  Result := Self;
end;

function TRickSQLInterf.Transation(const ATransation: Boolean): IRickSQLCommand;
begin
  Result := Self;
  FTransaction := ATransation;
end;

function TRickSQLInterf.Port(const APort: Integer): IRickSQLConnectionOptions;
begin
  Result := Self;
  FPort := APort;
end;

function TRickSQLInterf.Position(
  const APosition: Boolean): IRickSQLMaterializationOptions;
begin
  Result := Self;
  FPosition := APosition;
end;

function TRickSQLInterf.Preserve(
  const APreserve: Boolean): IRickSQLMaterializationOptions;
begin
  Result := Self;
  FPreserve := APreserve;
end;

function TRickSQLInterf.Result: IRickSQLResult;
begin
  Result := Self;
end;

function TRickSQLInterf.Return: IRickSQLCommand;
begin
  Result := Self;
end;

function TRickSQLInterf.Database(const ADatabase: string): IRickSQLConnectionOptions;
begin
  Result := Self;
  FDatabase := ADatabase;
end;

function TRickSQLInterf.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

function TRickSQLInterf.DataType(
  const ADataType: TFieldType): IRickSQLParameter;
begin
  Result := Self;
  FDataType := ADataType;
end;

function TRickSQLInterf.UserName(const AUserName: string): IRickSQLConnectionOptions;
begin
  Result := Self;
  FUserName := AUserName;
end;

function TRickSQLInterf.Value(const AValue: Variant): IRickSQLParameter;
begin
  Result := Self;
  FValue := AValue
end;

function TRickSQLInterf.Parameter: IRickSQLParameter;
begin
  Result := Self;
end;

function TRickSQLInterf.Password(const APassword: string): IRickSQLConnectionOptions;
begin
  Result := Self;
  FPassword := APassword;
end;

function TRickSQLInterf.CharacterSet(const ACharacterSet: string): IRickSQLConnectionOptions;
begin
  Result := Self;
  FCharacterSet := ACharacterSet;
end;

function TRickSQLInterf.Clear: IRickSQLParameter;
begin
  Result := Self;
  FParameters := nil;
end;

function TRickSQLInterf.ClearConnectionParameter: IRickSQLConnectionOptions;
begin
  Result := Self;
  FExtraParameters := nil;
end;

function TRickSQLInterf.ConnectTimeout(const AConnectTimeout: Integer): IRickSQLConnectionOptions;
begin
  Result := Self;
  FConnectTimeout := AConnectTimeout;
end;

function TRickSQLInterf.LibraryPath(const ALibraryPath: string): IRickSQLConnectionOptions;
begin
  Result := Self;
  FClientLibraryPath := ALibraryPath;
end;

procedure TRickSQLInterf.MaterializationOptionsDefault;
begin
  FPreserve := True;
  FPosition := True;
end;

function TRickSQLInterf.MaxRedord(const AMaxRedord: Integer): IRickSQLCommand;
begin
  Result := Self;
  FMaxRecords := AMaxRedord;
end;


function TRickSQLInterf.Add: IRickSQLParameter;
var
  LParameter : TRickSQLParameter;
begin
  Result := Self;

  LParameter.Name       := FName;
  LParameter.Value      := FValue;
  LParameter.DataType   := FDataType;
  LParameter.Size       := FSize;
  LParameter.Direction  := FDirection;
  LParameter.IsNull     := FNull;

  Insert(LParameter, FParameters, Length(FParameters));

  Default;
end;

function TRickSQLInterf.AddConnectionParameter(const AName,
  AValue: string): IRickSQLConnectionOptions;
var
  I: Integer;
begin
  Result := Self;

  for I := Low(FExtraParameters) to High(FExtraParameters) do
  begin
    if not SameText(FExtraParameters[I].Name, AName) then
      Continue;

    FExtraParameters[I].Value := AValue;
    Exit;
  end;

  Insert(TRickSQLConnectionParameter
          .Create(AName, AValue),
            FExtraParameters,
            Length(FExtraParameters)
        );
end;


function TRickSQLInterf.AddNull: IRickSQLParameter;
begin
  Result := Self;

  Insert(TRickSQLParameter
          .CreateNull(FName, FDataType),
            FParameters,
            Length(FParameters)
        );

  Default;
end;

function TRickSQLInterf.AddVariant: IRickSQLParameter;
begin
  Result := Self;

  Insert(TRickSQLParameter
          .Create(FName, FValue),
            FParameters,
            Length(FParameters)
        );

  Default;
end;

constructor TRickSQLInterf.Create;
begin
  ConnectionOptionsDefault;
  CommandParameterDefault;
  CommandOptionsDefault;
  MaterializationOptionsDefault;
  FOwner := True;
end;

function TRickSQLInterf.Default: IRickSQLParameter;
begin
  Result := Self;
  CommandParameterDefault;

end;

destructor TRickSQLInterf.Destroy;
begin
  ErrorDefault;

  inherited;
end;

function TRickSQLInterf.Direction(
  const ADirection: TParamType): IRickSQLParameter;
begin
  Result := Self;
  FDirection := ADirection;
end;

function TRickSQLInterf.Execute: IRickSQLCursor;
begin
  Result := Self;

  ErrorDefault;

  FErroFull := TRickSQLCoreCommandExecutor.Execute(BuildCommand);
  FError := FErroFull.Error.Message;
end;

function TRickSQLInterf.Cursor: IRickSQLCursor;
begin
  Result := Self;
end;

function TRickSQLInterf.FetchAll(const AFetchAll: Boolean): IRickSQLCommand;
begin
  Result := Self;
  FFetchAll := AFetchAll;
end;

function TRickSQLInterf.Name(const AName: string): IRickSQLParameter;
begin
  Result := Self;
  FName := AName;
end;

class function TRickSQLInterf.New: IRickSQL;
begin
  Result:= Self.Create;
end;

function TRickSQLInterf.IsNull(const ANull: Boolean): IRickSQLParameter;
begin
  Result := Self;
  FNull := ANull;
end;

function TRickSQLInterf.Open: IRickSQLCursor;
var
  LError   : TRickSQLError;
begin
  Result := Self;
  ErrorDefault;

  FDataSet := TRickSQLCoreOpenExecutor.Open(BuildCommand, LError);

  if Assigned(FDataSet) then
    FErroFull := TRickSQLExecutionResult.Succeeded(0)
  else
    FErroFull := TRickSQLExecutionResult.Failed(LError);

  FError := FErroFull.Error.Message;
end;

function TRickSQLInterf.Option: IRickSQLCommandOptions;
begin
  Result := Self;
end;

function TRickSQLInterf.Owner(const AOwner: Boolean): IRickSQL;
begin
  Result := Self;
  FOwner := AOwner;
end;

function TRickSQLInterf.Materialization: IRickSQLMaterializationOptions;
begin
  Result := Self;
end;

end.
