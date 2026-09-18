unit Rick.SQL.Model.Parameter;

// Responsabilidade: representar os parâmetros associados a um comando SQL.
// NAO localiza parâmetros em queries, converte valores ou executa comandos.

interface

uses
  // RTL
  System.Variants,

  // Data
  Data.DB;

type
  TRickSQLParameter = record
    Name: string;
    Value: Variant;
    DataType: TFieldType;
    Size: Integer;
    Direction: TParamType;
    IsNull: Boolean;
    class function Create(const AName: string;
      const AValue: Variant): TRickSQLParameter; static;
    class function CreateNull(const AName: string;
      const ADataType: TFieldType): TRickSQLParameter; static;
  end;

  TRickSQLParameterArray = TArray<TRickSQLParameter>;

implementation

class function TRickSQLParameter.Create(const AName: string;
  const AValue: Variant): TRickSQLParameter;
begin
  Result.Name := AName;
  Result.Value := AValue;
  Result.DataType := ftUnknown;
  Result.Size := 0;
  Result.Direction := ptInput;
  Result.IsNull := VarIsNull(AValue) or VarIsEmpty(AValue);
end;

class function TRickSQLParameter.CreateNull(const AName: string;
  const ADataType: TFieldType): TRickSQLParameter;
begin
  Result.Name := AName;
  Result.Value := Null;
  Result.DataType := ADataType;
  Result.Size := 0;
  Result.Direction := ptInput;
  Result.IsNull := True;
end;

end.
