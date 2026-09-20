unit Rick.SQL.Model.Command.Options;

// Responsabilidade: representar as opções de execução de um comando SQL.
// NAO executa comandos, controla transações ou conhece componentes FireDAC.

interface

type
  TRickSQLMaterializationOptions = record
    PositionAtFirstRecord: Boolean;
    PreserveFieldMetadata: Boolean;
    class function CreateDefault: TRickSQLMaterializationOptions; static;
  end;

  TRickSQLCommandOptions = record
    CommandTimeout: Integer;
    UseTransaction: Boolean;
    /// <summary>
    /// Solicita o prefetch explícito do dataset de origem antes da materialização
    /// quando não existe limite positivo em MaxRecords.
    /// </summary>
    /// <remarks>
    /// False apenas omite o prefetch explícito: não torna o resultado lazy ou
    /// conectado e não limita linhas. MaxRecords controla a quantidade materializada.
    /// </remarks>
    FetchAll: Boolean;
    /// <summary>
    /// Limita a quantidade de registros materializados; zero significa sem limite.
    /// </summary>
    MaxRecords: Integer;
    Materialization: TRickSQLMaterializationOptions;
    class function CreateDefault: TRickSQLCommandOptions; static;
  end;

implementation

class function TRickSQLMaterializationOptions.CreateDefault
  : TRickSQLMaterializationOptions;
begin
  Result.PositionAtFirstRecord := True;
  Result.PreserveFieldMetadata := True;
end;

class function TRickSQLCommandOptions.CreateDefault: TRickSQLCommandOptions;
begin
  Result.CommandTimeout := 0;
  Result.UseTransaction := True;
  Result.FetchAll := True;
  Result.MaxRecords := 0;
  Result.Materialization := TRickSQLMaterializationOptions.CreateDefault;
end;

end.
