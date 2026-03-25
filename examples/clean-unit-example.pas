/// <summary>
/// Example of a clean and well-organized unit in Delphi.
/// Demonstrates: organization of sections, enums, interfaces, classes,
/// properties, XMLDoc, guard clauses and memory management.
/// </summary>
unit Example.Domain.Product.Entity;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  // =========================================================================
  // 1. Enums and Records first
  // =========================================================================

  TProductCategory = (pcElectronics, pcClothing, pcFood, pcServices);

  TProductStatus = (psActive, psInactive, psDiscontinued);

  /// <summary>Immutable record to represent product dimensions.</summary>
  TProductDimensions = record
    Width: Double;
    Height: Double;
    Depth: Double;
    Weight: Double;
    class function Create(AWidth, AHeight, ADepth, AWeight: Double): TProductDimensions; static;
    function Volume: Double;
    function IsEmpty: Boolean;
  end;

  // =========================================================================
  // 2. Interfaces
  // =========================================================================

  /// <summary>
  /// Interface for entities that have domain validation.
  /// </summary>
  IValidatable = interface
    ['{C3D4E5F6-0003-0003-0003-000000000001}']
    function IsValid: Boolean;
    function GetValidationErrors: TArray<string>;
  end;

  // =========================================================================
  // 3. Classes
  // =========================================================================

  /// <summary>
  /// Domain entity representing a product.
  /// Implements IValidatable for domain validation.
  /// </summary>
  TProduct = class(TInterfacedObject, IValidatable)
  private
    FId: Integer;
    FName: string;
    FDescription: string;
    FPrice: Currency;
    FCategory: TProductCategory;
    FStatus: TProductStatus;
    FDimensions: TProductDimensions;
    FTags: TList<string>;

    function GetName: string;
    procedure SetName(const AValue: string);
    function GetPrice: Currency;
    procedure SetPrice(AValue: Currency);
    function GetIsAvailable: Boolean;
  public
    constructor Create(const AName: string; APrice: Currency);
    destructor Destroy; override;

    // Business methods
    function IsValid: Boolean;
    function GetValidationErrors: TArray<string>;
    procedure Activate;
    procedure Deactivate;
    procedure Discontinue;
    procedure AddTag(const ATag: string);
    function HasTag(const ATag: string): Boolean;

    // Properties last
    property Id: Integer read FId write FId;
    property Name: string read GetName write SetName;
    property Description: string read FDescription write FDescription;
    property Price: Currency read GetPrice write SetPrice;
    property Category: TProductCategory read FCategory write FCategory;
    property Status: TProductStatus read FStatus;
    property Dimensions: TProductDimensions read FDimensions write FDimensions;
    property IsAvailable: Boolean read GetIsAvailable;
    property Tags: TList<string> read FTags;
  end;

implementation

const
  MIN_NAME_LENGTH = 3;
  MAX_NAME_LENGTH = 100;

{ TProductDimensions }

class function TProductDimensions.Create(
  AWidth, AHeight, ADepth, AWeight: Double): TProductDimensions;
begin
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.Depth := ADepth;
  Result.Weight := AWeight;
end;

function TProductDimensions.Volume: Double;
begin
  Result := Width * Height * Depth;
end;

function TProductDimensions.IsEmpty: Boolean;
begin
  Result := (Width = 0) and (Height = 0) and (Depth = 0);
end;

{ TProduct }

constructor TProduct.Create(const AName: string; APrice: Currency);
begin
  inherited Create;
  FTags := TList<string>.Create;

  // Guard clauses in the constructor
  if AName.Trim.IsEmpty then
    raise EArgumentException.Create('Product name cannot be empty');
  if APrice < 0 then
    raise EArgumentException.Create('Price cannot be negative');

  FName := AName.Trim;
  FPrice := APrice;
  FStatus := psActive;
  FCategory := pcElectronics;
end;

destructor TProduct.Destroy;
begin
  FTags.Free;
  inherited;
end;

function TProduct.GetName: string;
begin
  Result := FName;
end;

procedure TProduct.SetName(const AValue: string);
begin
  if AValue.Trim.IsEmpty then
    raise EArgumentException.Create('Product name cannot be empty');
  FName := AValue.Trim;
end;

function TProduct.GetPrice: Currency;
begin
  Result := FPrice;
end;

procedure TProduct.SetPrice(AValue: Currency);
begin
  if AValue < 0 then
    raise EArgumentException.Create('Price cannot be negative');
  FPrice := AValue;
end;

function TProduct.GetIsAvailable: Boolean;
begin
  Result := (FStatus = psActive) and (FPrice > 0);
end;

function TProduct.IsValid: Boolean;
begin
  Result := Length(GetValidationErrors) = 0;
end;

function TProduct.GetValidationErrors: TArray<string>;
var
  LErrors: TList<string>;
begin
  LErrors := TList<string>.Create;
  try
    if FName.Length < MIN_NAME_LENGTH then
      LErrors.Add(Format('Name must have at least %d characters',
        [MIN_NAME_LENGTH]));

    if FName.Length > MAX_NAME_LENGTH then
      LErrors.Add(Format('Name must have at most %d characters',
        [MAX_NAME_LENGTH]));

    if FPrice < 0 then
      LErrors.Add('Price cannot be negative');

    Result := LErrors.ToArray;
  finally
    LErrors.Free;
  end;
end;

procedure TProduct.Activate;
begin
  if FStatus = psDiscontinued then
    raise EInvalidOpException.Create(
      'A discontinued product cannot be reactivated');
  FStatus := psActive;
end;

procedure TProduct.Deactivate;
begin
  FStatus := psInactive;
end;

procedure TProduct.Discontinue;
begin
  FStatus := psDiscontinued;
end;

procedure TProduct.AddTag(const ATag: string);
begin
  if ATag.Trim.IsEmpty then
    raise EArgumentException.Create('Tag cannot be empty');
  if not HasTag(ATag) then
    FTags.Add(ATag.Trim.ToLower);
end;

function TProduct.HasTag(const ATag: string): Boolean;
begin
  Result := FTags.Contains(ATag.Trim.ToLower);
end;

end.

