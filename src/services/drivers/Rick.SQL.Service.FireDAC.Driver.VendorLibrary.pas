unit Rick.SQL.Service.FireDAC.Driver.VendorLibrary;

// Responsabilidade: aplicar a biblioteca cliente ao VendorLib de um DriverLink FireDAC.
// NAO resolve caminhos de bibliotecas, cria DriverLinks ou conhece providers específicos.

interface

uses
  // RTL
  System.Classes,

  // RickSQL
  Rick.SQL.Model.Error;

{$SCOPEDENUMS ON}

type
  TRickSQLVendorLibraryApplyStatus = (
    Skipped,
    Applied,
    DriverLinkRequired,
    PropertyUnavailable,
    InspectionFailed,
    Failed
  );

  TRickSQLVendorLibraryApplyResult = record
    Status: TRickSQLVendorLibraryApplyStatus;
    Error: TRickSQLError;
    function Succeeded: Boolean;
  end;

  TRickSQLServiceFireDACDriverVendorLibrary = class
  public
    class procedure Apply(const ADriverLink: TComponent;
      const AVendorLibraryPath: string); static;
    class function TryApply(const ADriverLink: TComponent;
      const AVendorLibraryPath: string): TRickSQLVendorLibraryApplyResult; static;
  end;

implementation

uses
  // RTL
  System.SysUtils,
  System.TypInfo,

  // RickSQL
  Rick.SQL.Model.Types,
  Rick.SQL.Error.Normalizer;

type
  ERickSQLVendorLibraryDriverLinkRequired = class(Exception);
  ERickSQLVendorLibraryUnavailable = class(Exception);

  ERickSQLVendorLibraryInspection = class(Exception)
  private
    FError: TRickSQLError;
  public
    constructor Create(const AError: TRickSQLError);
    property Error: TRickSQLError read FError;
  end;

const
  _PROPERTY_VENDOR_LIB_ = 'VendorLib';
  _ERROR_DRIVER_LINK_REQUIRED_ = 'DriverLink não informado.';

constructor ERickSQLVendorLibraryInspection.Create(const AError: TRickSQLError);
begin
  inherited Create(AError.TechnicalDetail);
  FError := AError;
end;

function TRickSQLVendorLibraryApplyResult.Succeeded: Boolean;
begin
  Result := Status in [TRickSQLVendorLibraryApplyStatus.Skipped,
    TRickSQLVendorLibraryApplyStatus.Applied];
end;

class procedure TRickSQLServiceFireDACDriverVendorLibrary.Apply(
  const ADriverLink: TComponent; const AVendorLibraryPath: string);
var
  LProperty: PPropInfo;
begin
  if Trim(AVendorLibraryPath) = '' then
    Exit;
  if not Assigned(ADriverLink) then
    raise ERickSQLVendorLibraryDriverLinkRequired.Create(
      _ERROR_DRIVER_LINK_REQUIRED_);
  try
    LProperty := GetPropInfo(ADriverLink.ClassInfo, _PROPERTY_VENDOR_LIB_);
  except
    on E: Exception do
      raise ERickSQLVendorLibraryInspection.Create(
        TRickSQLErrorNormalizer.FromException(E,
          TRickSQLErrorKind.ClientLibrary, '', ''));
  end;
  if not Assigned(LProperty) then
    raise ERickSQLVendorLibraryUnavailable.Create(ADriverLink.ClassName);
  SetStrProp(ADriverLink, LProperty, AVendorLibraryPath);
end;

class function TRickSQLServiceFireDACDriverVendorLibrary.TryApply(
  const ADriverLink: TComponent;
  const AVendorLibraryPath: string): TRickSQLVendorLibraryApplyResult;
begin
  Result.Status := TRickSQLVendorLibraryApplyStatus.Skipped;
  Result.Error := TRickSQLError.Empty;
  if Trim(AVendorLibraryPath) = '' then
    Exit;
  try
    Apply(ADriverLink, AVendorLibraryPath);
    Result.Status := TRickSQLVendorLibraryApplyStatus.Applied;
  except
    on E: ERickSQLVendorLibraryDriverLinkRequired do
      Result.Status := TRickSQLVendorLibraryApplyStatus.DriverLinkRequired;
    on E: ERickSQLVendorLibraryUnavailable do
    begin
      Result.Status := TRickSQLVendorLibraryApplyStatus.PropertyUnavailable;
      Result.Error := TRickSQLErrorNormalizer.FromDetail(
        TRickSQLErrorKind.ClientLibrary, '', E.Message, '');
    end;
    on E: ERickSQLVendorLibraryInspection do
    begin
      Result.Status := TRickSQLVendorLibraryApplyStatus.InspectionFailed;
      Result.Error := E.Error;
    end;
    on E: Exception do
    begin
      Result.Status := TRickSQLVendorLibraryApplyStatus.Failed;
      Result.Error := TRickSQLErrorNormalizer.FromException(E,
        TRickSQLErrorKind.ClientLibrary, '', '');
    end;
  end;
end;

end.
