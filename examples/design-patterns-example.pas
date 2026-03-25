unit MeuApp.Examples.DesignPatterns;
{
  DESIGN PATTERNS IN DELPHI — Complete Practical Example
  ======================================================
  This file demonstrates the main GoF patterns applied in Object Pascal,
  following all conventions from the Delphi AI Spec-Kit:
  - Prefixes: T (classes), I (interfaces), E (exceptions), F (fields), A (params), L (locals)
  - Memory management: try..finally for TObject without ARC
  - Interfaces with TInterfacedObject for automatic ARC
  - Constructor Injection (DIP)
  - Guard clauses
  - XMLDoc in English
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

// ============================================================================
// CUSTOM EXCEPTIONS
// ============================================================================

type
  EInvalidOperationException = class(Exception);
  EAuthorizationException = class(Exception);
  EValidationException = class(Exception);
  EEntityNotFoundException = class(Exception);

// ============================================================================
// DEFAULT: STRATEGY
// Vary discount algorithms without changing context (TOrderCalculator).
// ============================================================================

type
  IDiscountStrategy = interface
    ['{11111111-1111-1111-1111-111111111111}']
    function Apply(ABasePrice: Currency): Currency;
    function GetDescription: string;
  end;

  TNoDiscountStrategy = class(TInterfacedObject, IDiscountStrategy)
  public
    function Apply(ABasePrice: Currency): Currency;
    function GetDescription: string;
  end;

  TPercentageDiscountStrategy = class(TInterfacedObject, IDiscountStrategy)
  private
    FPercentage: Double;
  public
    constructor Create(APercentage: Double);
    function Apply(ABasePrice: Currency): Currency;
    function GetDescription: string;
  end;

  TBlackFridayDiscountStrategy = class(TInterfacedObject, IDiscountStrategy)
  public
    function Apply(ABasePrice: Currency): Currency;
    function GetDescription: string;
  end;

  /// <summary>
  /// Context that delegates the discount calculation to the configured strategy.
  /// Change the strategy without modifying this code (OCP).
  /// </summary>
  TOrderCalculator = class
  private
    FStrategy: IDiscountStrategy;
  public
    constructor Create(AStrategy: IDiscountStrategy);
    function CalculateFinalPrice(ABasePrice: Currency): Currency;
    property Strategy: IDiscountStrategy read FStrategy write FStrategy;
  end;

// ============================================================================
// DEFAULT: OBSERVER
// Notifies multiple listeners about request events.
// ============================================================================

type
  TOrderEventArgs = record
    OrderId: Integer;
    CustomerEmail: string;
    TotalAmount: Currency;
    EventTime: TDateTime;
  end;

  IOrderEventListener = interface
    ['{22222222-2222-2222-2222-222222222222}']
    procedure OnOrderPlaced(const AArgs: TOrderEventArgs);
    procedure OnOrderCancelled(const AArgs: TOrderEventArgs);
  end;

  /// <summary>
  /// Order event publisher. Notifies all subscribed listeners.
  /// Listeners are referenced by interface — no manual memory management.
  /// </summary>
  TOrderEventBus = class
  private
    FListeners: TList<IOrderEventListener>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Subscribe(AListener: IOrderEventListener);
    procedure Unsubscribe(AListener: IOrderEventListener);
    procedure PublishOrderPlaced(const AArgs: TOrderEventArgs);
    procedure PublishOrderCancelled(const AArgs: TOrderEventArgs);
  end;

  TEmailNotificationListener = class(TInterfacedObject, IOrderEventListener)
  public
    procedure OnOrderPlaced(const AArgs: TOrderEventArgs);
    procedure OnOrderCancelled(const AArgs: TOrderEventArgs);
  end;

  TStockUpdateListener = class(TInterfacedObject, IOrderEventListener)
  public
    procedure OnOrderPlaced(const AArgs: TOrderEventArgs);
    procedure OnOrderCancelled(const AArgs: TOrderEventArgs);
  end;

// ============================================================================
// PATTERN: DECORATOR
// Add behavior to the logger without inheritance.
// ============================================================================

type
  ILogger = interface
    ['{33333333-3333-3333-3333-333333333333}']
    procedure Log(const ALevel, AMessage: string);
  end;

  TConsoleLogger = class(TInterfacedObject, ILogger)
  public
    procedure Log(const ALevel, AMessage: string);
  end;

  TTimestampLogDecorator = class(TInterfacedObject, ILogger)
  private
    FInner: ILogger;
  public
    constructor Create(AInner: ILogger);
    procedure Log(const ALevel, AMessage: string);
  end;

  TLevelFilterLogDecorator = class(TInterfacedObject, ILogger)
  private
    FInner: ILogger;
    FMinLevel: string;
  public
    constructor Create(AInner: ILogger; const AMinLevel: string);
    procedure Log(const ALevel, AMessage: string);
  end;

// ============================================================================
// DEFAULT: BUILDER (Fluent Interface)
// Builds SQL queries without string concatenation.
// ============================================================================

type
  /// <summary>
  /// Fluent builder for parameterized SQL queries.
  /// Usage: TQueryBuilder.Create.Select('*').From('customers').Where('active=1').Build
  /// </summary>
  TQueryBuilder = class
  private
    FSelectClause: string;
    FFromClause: string;
    FWhereConditions: TStringList;
    FOrderByClause: string;
    FLimitValue: Integer;
    procedure ValidateBeforeBuild;
  public
    constructor Create;
    destructor Destroy; override;
    function Select(const AFields: string): TQueryBuilder;
    function From(const ATable: string): TQueryBuilder;
    function Where(const ACondition: string): TQueryBuilder;
    function OrderBy(const AField: string; ADescending: Boolean = False): TQueryBuilder;
    function Limit(ACount: Integer): TQueryBuilder;

    /// <summary>Finalizes and returns the assembled SQL query.</summary>
    /// <exception cref="EValidationException">If SELECT or FROM were not configured.</exception>
    function Build: string;
  end;

// ============================================================================
// DEFAULT: CHAIN ​​OF RESPONSIBILITY
// Customer validation pipeline.
// ============================================================================

type
  TCustomerDTO = record
    Name: string;
    Email: string;
    Cpf: string;
    Age: Integer;
  end;

  TValidationResult = record
    IsValid: Boolean;
    ErrorMessage: string;
    class function Ok: TValidationResult; static;
    class function Fail(const AMessage: string): TValidationResult; static;
  end;

  ICustomerValidator = interface
    ['{44444444-4444-4444-4444-444444444444}']
    procedure SetNext(AValidator: ICustomerValidator);
    function Validate(const ADto: TCustomerDTO): TValidationResult;
  end;

  TBaseCustomerValidator = class(TInterfacedObject, ICustomerValidator)
  private
    FNext: ICustomerValidator;
  public
    procedure SetNext(AValidator: ICustomerValidator);
    function Validate(const ADto: TCustomerDTO): TValidationResult; virtual;
  end;

  TNameValidator = class(TBaseCustomerValidator)
  public
    function Validate(const ADto: TCustomerDTO): TValidationResult; override;
  end;

  TEmailValidator = class(TBaseCustomerValidator)
  public
    function Validate(const ADto: TCustomerDTO): TValidationResult; override;
  end;

  TCpfValidator = class(TBaseCustomerValidator)
  public
    function Validate(const ADto: TCustomerDTO): TValidationResult; override;
  end;

  TAgeValidator = class(TBaseCustomerValidator)
  public
    function Validate(const ADto: TCustomerDTO): TValidationResult; override;
  end;

// ============================================================================
// DEFAULT: FACTORY METHOD
// Create report exporters by type.
// ============================================================================

type
  TReportData = record
    Title: string;
    Lines: TArray<string>;
  end;

  IReportExporter = interface
    ['{55555555-5555-5555-5555-555555555555}']
    procedure Export(const AData: TReportData; const AOutputPath: string);
    function GetExtension: string;
  end;

  TPdfReportExporter = class(TInterfacedObject, IReportExporter)
  public
    procedure Export(const AData: TReportData; const AOutputPath: string);
    function GetExtension: string;
  end;

  TExcelReportExporter = class(TInterfacedObject, IReportExporter)
  public
    procedure Export(const AData: TReportData; const AOutputPath: string);
    function GetExtension: string;
  end;

  TCsvReportExporter = class(TInterfacedObject, IReportExporter)
  public
    procedure Export(const AData: TReportData; const AOutputPath: string);
    function GetExtension: string;
  end;

  /// <summary>
  /// Factory Method: creates the correct exporter based on the requested format.
  /// </summary>
  TReportExporterFactory = class
  public
    class function CreateExporter(const AFormat: string): IReportExporter;
  end;

implementation

// ============================================================================
// STRATEGY — Implementation
// ============================================================================

{ TNoDiscountStrategy }

function TNoDiscountStrategy.Apply(ABasePrice: Currency): Currency;
begin
  Result := ABasePrice;
end;

function TNoDiscountStrategy.GetDescription: string;
begin
  Result := 'No discount';
end;

{ TPercentageDiscountStrategy }

constructor TPercentageDiscountStrategy.Create(APercentage: Double);
begin
  inherited Create;
  if (APercentage < 0) or (APercentage > 100) then
    raise EValidationException.Create('Percentage must be between 0 and 100');
  FPercentage := APercentage;
end;

function TPercentageDiscountStrategy.Apply(ABasePrice: Currency): Currency;
begin
  Result := ABasePrice * (1 - FPercentage / 100);
end;

function TPercentageDiscountStrategy.GetDescription: string;
begin
  Result := Format('%.0f%% discount', [FPercentage]);
end;

{ TBlackFridayDiscountStrategy }

function TBlackFridayDiscountStrategy.Apply(ABasePrice: Currency): Currency;
const
  BLACK_FRIDAY_DISCOUNT = 0.50; // 50%
begin
  Result := ABasePrice * (1 - BLACK_FRIDAY_DISCOUNT);
end;

function TBlackFridayDiscountStrategy.GetDescription: string;
begin
  Result := 'Black Friday — 50% off';
end;

{ TOrderCalculator }

constructor TOrderCalculator.Create(AStrategy: IDiscountStrategy);
begin
  inherited Create;
  if not Assigned(AStrategy) then
    raise EArgumentNilException.Create('AStrategy cannot be nil');
  FStrategy := AStrategy;
end;

function TOrderCalculator.CalculateFinalPrice(ABasePrice: Currency): Currency;
begin
  if ABasePrice < 0 then
    raise EValidationException.Create('Base price cannot be negative');
  Result := FStrategy.Apply(ABasePrice);
end;

// ============================================================================
// OBSERVER — Implementation
// ============================================================================

{ TOrderEventBus }

constructor TOrderEventBus.Create;
begin
  inherited Create;
  FListeners := TList<IOrderEventListener>.Create;
end;

destructor TOrderEventBus.Destroy;
begin
  FListeners.Free;
  inherited Destroy;
end;

procedure TOrderEventBus.Subscribe(AListener: IOrderEventListener);
begin
  if not Assigned(AListener) then
    raise EArgumentNilException.Create('AListener cannot be nil');
  FListeners.Add(AListener);
end;

procedure TOrderEventBus.Unsubscribe(AListener: IOrderEventListener);
begin
  FListeners.Remove(AListener);
end;

procedure TOrderEventBus.PublishOrderPlaced(const AArgs: TOrderEventArgs);
var
  LListener: IOrderEventListener;
begin
  for LListener in FListeners do
    LListener.OnOrderPlaced(AArgs);
end;

procedure TOrderEventBus.PublishOrderCancelled(const AArgs: TOrderEventArgs);
var
  LListener: IOrderEventListener;
begin
  for LListener in FListeners do
    LListener.OnOrderCancelled(AArgs);
end;

{ TEmailNotificationListener }

procedure TEmailNotificationListener.OnOrderPlaced(const AArgs: TOrderEventArgs);
begin
  // In production: send confirmation email to AArgs.CustomerEmail
  Writeln(Format('[EMAIL] Order #%d confirmed — sending to %s',
    [AArgs.OrderId, AArgs.CustomerEmail]));
end;

procedure TEmailNotificationListener.OnOrderCancelled(const AArgs: TOrderEventArgs);
begin
  Writeln(Format('[EMAIL] Order #%d canceled — notifying %s',
    [AArgs.OrderId, AArgs.CustomerEmail]));
end;

{ TStockUpdateListener }

procedure TStockUpdateListener.OnOrderPlaced(const AArgs: TOrderEventArgs);
begin
  Writeln(Format('[STOCK] Reserving order items #%d', [AArgs.OrderId]));
end;

procedure TStockUpdateListener.OnOrderCancelled(const AArgs: TOrderEventArgs);
begin
  Writeln(Format('[STOCK] Releasing items from canceled order #%d', [AArgs.OrderId]));
end;

// ============================================================================
// DECORATOR — Implementation
// ============================================================================

{ TConsoleLogger }

procedure TConsoleLogger.Log(const ALevel, AMessage: string);
begin
  Writeln(Format('[%s] %s', [ALevel, AMessage]));
end;

{ TTimestampLogDecorator }

constructor TTimestampLogDecorator.Create(AInner: ILogger);
begin
  inherited Create;
  if not Assigned(AInner) then
    raise EArgumentNilException.Create('AInner logger cannot be nil');
  FInner := AInner;
end;

procedure TTimestampLogDecorator.Log(const ALevel, AMessage: string);
begin
  FInner.Log(ALevel, Format('%s | %s',
    [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), AMessage]));
end;

{ TLevelFilterLogDecorator }

constructor TLevelFilterLogDecorator.Create(AInner: ILogger; const AMinLevel: string);
begin
  inherited Create;
  if not Assigned(AInner) then
    raise EArgumentNilException.Create('AInner logger cannot be nil');
  FInner := AInner;
  FMinLevel := AMinLevel.ToUpper;
end;

procedure TLevelFilterLogDecorator.Log(const ALevel, AMessage: string);
begin
  if ALevel.ToUpper >= FMinLevel then
    FInner.Log(ALevel, AMessage);
end;

// ============================================================================
// BUILDER — Implementation
// ============================================================================

{ TQueryBuilder }

constructor TQueryBuilder.Create;
begin
  inherited Create;
  FWhereConditions := TStringList.Create;
  FLimitValue := 0;
end;

destructor TQueryBuilder.Destroy;
begin
  FWhereConditions.Free;
  inherited Destroy;
end;

function TQueryBuilder.Select(const AFields: string): TQueryBuilder;
begin
  FSelectClause := AFields;
  Result := Self;
end;

function TQueryBuilder.From(const ATable: string): TQueryBuilder;
begin
  FFromClause := ATable;
  Result := Self;
end;

function TQueryBuilder.Where(const ACondition: string): TQueryBuilder;
begin
  if not ACondition.Trim.IsEmpty then
    FWhereConditions.Add(ACondition);
  Result := Self;
end;

function TQueryBuilder.OrderBy(const AField: string; ADescending: Boolean): TQueryBuilder;
begin
  FOrderByClause := AField;
  if ADescending then
    FOrderByClause := FOrderByClause + ' DESC';
  Result := Self;
end;

function TQueryBuilder.Limit(ACount: Integer): TQueryBuilder;
begin
  if ACount <= 0 then
    raise EValidationException.Create('Limit must be greater than zero');
  FLimitValue := ACount;
  Result := Self;
end;

procedure TQueryBuilder.ValidateBeforeBuild;
begin
  if FSelectClause.Trim.IsEmpty then
    raise EValidationException.Create('SELECT clause is mandatory');
  if FFromClause.Trim.IsEmpty then
    raise EValidationException.Create('FROM clause is mandatory');
end;

function TQueryBuilder.Build: string;
var
  LResult: TStringBuilder;
begin
  ValidateBeforeBuild;

  LResult := TStringBuilder.Create;
  try
    LResult.Append('SELECT').Append(FSelectClause);
    LResult.Append(' FROM ').Append(FFromClause);

    if FWhereConditions.Count > 0 then
      LResult.Append(' WHERE ').Append(String.Join(' AND ', FWhereConditions.ToStringArray));

    if not FOrderByClause.IsEmpty then
      LResult.Append(' ORDER BY ').Append(FOrderByClause);

    if FLimitValue > 0 then
      LResult.Append(' LIMIT').Append(FLimitValue.ToString);

    Result := LResult.ToString;
  finally
    LResult.Free;
  end;
end;

// ============================================================================
// CHAIN ​​OF RESPONSIBILITY — Implementation
// ============================================================================

{ TValidationResult }

class function TValidationResult.Ok: TValidationResult;
begin
  Result.IsValid := True;
  Result.ErrorMessage := '';
end;

class function TValidationResult.Fail(const AMessage: string): TValidationResult;
begin
  Result.IsValid := False;
  Result.ErrorMessage := AMessage;
end;

{ TBaseCustomerValidator }

procedure TBaseCustomerValidator.SetNext(AValidator: ICustomerValidator);
begin
  FNext := AValidator;
end;

function TBaseCustomerValidator.Validate(const ADto: TCustomerDTO): TValidationResult;
begin
  if Assigned(FNext) then
    Result := FNext.Validate(ADto)
  else
    Result := TValidationResult.Ok;
end;

{ TNameValidator }

function TNameValidator.Validate(const ADto: TCustomerDTO): TValidationResult;
const
  MIN_NAME_LENGTH = 3;
begin
  if ADto.Name.Trim.IsEmpty then
    Exit(TValidationResult.Fail('Name is mandatory'));
  if ADto.Name.Trim.Length < MIN_NAME_LENGTH then
    Exit(TValidationResult.Fail('Name must have at least 3 characters'));
  Result := inherited Validate(ADto);
end;

{ TEmailValidator }

function TEmailValidator.Validate(const ADto: TCustomerDTO): TValidationResult;
begin
  if ADto.Email.Trim.IsEmpty then
    Exit(TValidationResult.Fail('Email is mandatory'));
  if not ADto.Email.Contains('@') then
    Exit(TValidationResult.Fail('Invalid email'));
  Result := inherited Validate(ADto);
end;

{ TCpfValidator }

function TCpfValidator.Validate(const ADto: TCustomerDTO): TValidationResult;
const
  CPF_LENGTH = 11;
begin
  if ADto.Cpf.Trim.IsEmpty then
    Exit(TValidationResult.Fail('CPF is mandatory'));
  if ADto.Cpf.Trim.Length <> CPF_LENGTH then
    Exit(TValidationResult.Fail('CPF must have 11 digits'));
  Result := inherited Validate(ADto);
end;

{ TAgeValidator }

function TAgeValidator.Validate(const ADto: TCustomerDTO): TValidationResult;
const
  MINIMUM_AGE = 18;
begin
  if ADto.Age < MINIMUM_AGE then
    Exit(TValidationResult.Fail(Format('Minimum age: %d years', [MINIMUM_AGE])));
  Result := inherited Validate(ADto);
end;

// ============================================================================
// FACTORY METHOD — Implementation
// ============================================================================

{ TPdfReportExporter }

procedure TPdfReportExporter.Export(const AData: TReportData; const AOutputPath: string);
begin
  // In production: actual PDF generation
  Writeln(Format('[PDF] Exporting "%s" to %s', [AData.Title, AOutputPath]));
end;

function TPdfReportExporter.GetExtension: string;
begin
  Result := '.pdf';
end;

{ TExcelReportExporter }

procedure TExcelReportExporter.Export(const AData: TReportData; const AOutputPath: string);
begin
  Writeln(Format('[EXCEL] Exporting "%s" to %s', [AData.Title, AOutputPath]));
end;

function TExcelReportExporter.GetExtension: string;
begin
  Result := '.xlsx';
end;

{ TCsvReportExporter }

procedure TCsvReportExporter.Export(const AData: TReportData; const AOutputPath: string);
begin
  Writeln(Format('[CSV] Exporting "%s" to %s', [AData.Title, AOutputPath]));
end;

function TCsvReportExporter.GetExtension: string;
begin
  Result := '.csv';
end;

{ TReportExporterFactory }

class function TReportExporterFactory.CreateExporter(const AFormat: string): IReportExporter;
begin
  case AFormat.ToLower of
    'pdf'  : Result := TPdfReportExporter.Create;
    'excel',
    'xlsx' : Result := TExcelReportExporter.Create;
    'csv'  : Result := TCsvReportExporter.Create;
  else
    raise EArgumentException.CreateFmt('Unsupported export format: "%s"', [AFormat]);
  end;
end;

// ============================================================================
// USAGE DEMONSTRATION — How to orchestrate patterns
// ============================================================================

procedure DemoStrategyPattern;
var
  LCalc: TOrderCalculator;
  LPrice: Currency;
begin
  Writeln('=== STRATEGY PATTERN ===');

  // No discount (default)
  LCalc := TOrderCalculator.Create(TNoDiscountStrategy.Create);
  try
    LPrice := LCalc.CalculateFinalPrice(100);
    Writeln(Format('No discount: R$ %.2f', [LPrice]));   // 100.00

    // Change the strategy at runtime — without changing TOrderCalculator
    LCalc.Strategy := TPercentageDiscountStrategy.Create(20);
    LPrice := LCalc.CalculateFinalPrice(100);
    Writeln(Format('20%% discount: R$ %.2f', [LPrice])); // 80.00

    LCalc.Strategy := TBlackFridayDiscountStrategy.Create;
    LPrice := LCalc.CalculateFinalPrice(100);
    Writeln(Format('Black Friday: R$ %.2f', [LPrice]));    // 50.00
  finally
    LCalc.Free;
  end;
end;

procedure DemoObserverPattern;
var
  LBus: TOrderEventBus;
  LArgs: TOrderEventArgs;
begin
  Writeln('=== OBSERVER PATTERN ===');

  LBus := TOrderEventBus.Create;
  try
    // Subscribe listeners — ARC-managed interfaces
    LBus.Subscribe(TEmailNotificationListener.Create);
    LBus.Subscribe(TStockUpdateListener.Create);

    LArgs.OrderId := 1001;
    LArgs.CustomerEmail := 'joao@email.com';
    LArgs.TotalAmount := 299.90;
    LArgs.EventTime := Now;

    LBus.PublishOrderPlaced(LArgs);  // dispara os dois listeners
    LBus.PublishOrderCancelled(LArgs);
  finally
    LBus.Free;
  end;
end;

procedure DemoDecoratorPattern;
var
  LLogger: ILogger;
begin
  Writeln('=== DECORATOR PATTERN ===');

  // Composition: ConsoleLogger → Timestamp → LevelFilter
  LLogger :=
    TLevelFilterLogDecorator.Create(
      TTimestampLogDecorator.Create(
        TConsoleLogger.Create
      ),
      'WARN'  // Filters DEBUG and INFO in production
    );

  LLogger.Log('DEBUG', 'Starting connection');   // filtrado, not aparece
  LLogger.Log('INFO',  'Service started');     // filtrado
  LLogger.Log('WARN',  'Attempt 2 of 3');    // aparece com timestamp
  LLogger.Log('ERROR', 'Connection failed');    // aparece com timestamp
end;

procedure DemoBuilderPattern;
var
  LBuilder: TQueryBuilder;
  LSql: string;
begin
  Writeln('=== BUILDER PATTERN ===');

  LBuilder := TQueryBuilder.Create;
  try
    LSql := LBuilder
      .Select('id, name, email, created_at')
      .From('customers')
      .Where('active = 1')
      .Where('age >= 18')
      .OrderBy('name')
      .Limit(50)
      .Build;

    Writeln(LSql);
    // SELECT id, name, email, created_at FROM customers WHERE active = 1 AND age >= 18 ORDER BY name LIMIT 50
  finally
    LBuilder.Free;
  end;
end;

procedure DemoChainOfResponsibilityPattern;
var
  LNameValidator: ICustomerValidator;
  LEmailValidator: ICustomerValidator;
  LCpfValidator: ICustomerValidator;
  LAgeValidator: ICustomerValidator;
  LResult: TValidationResult;
  LCustomer: TCustomerDTO;
begin
  Writeln('=== CHAIN ​​OF RESPONSIBILITY ===');

  // Set up the validation chain
  LNameValidator  := TNameValidator.Create;
  LEmailValidator := TEmailValidator.Create;
  LCpfValidator   := TCpfValidator.Create;
  LAgeValidator   := TAgeValidator.Create;

  LNameValidator.SetNext(LEmailValidator);
  LEmailValidator.SetNext(LCpfValidator);
  LCpfValidator.SetNext(LAgeValidator);

  // Test 1: invalid data
  LCustomer.Name  := 'Jo';           // muito curto
  LCustomer.Email := 'invalid';
  LCustomer.Cpf   := '12345678901';
  LCustomer.Age   := 25;

  LResult := LNameValidator.Validate(LCustomer);
  Writeln(Format('Valid: %s — %s', [BoolToStr(LResult.IsValid, True), LResult.ErrorMessage]));

  // Test 2: valid data
  LCustomer.Name  := 'John Silva';
  LCustomer.Email := 'joao@email.com';
  LCustomer.Cpf   := '12345678901';
  LCustomer.Age   := 25;

  LResult := LNameValidator.Validate(LCustomer);
  Writeln(Format('Valid: %s — %s', [BoolToStr(LResult.IsValid, True), LResult.ErrorMessage]));
end;

procedure DemoFactoryMethodPattern;
var
  LExporter: IReportExporter;
  LData: TReportData;
begin
  Writeln('=== FACTORY METHOD ===');

  LData.Title := 'Sales Report';
  LData.Lines := ['Item 1', 'Item 2', 'Total: R$ 1.500,00'];

  // Create the correct exporter without knowing the concrete class
  LExporter := TReportExporterFactory.CreateExporter('pdf');
  LExporter.Export(LData, 'C:\reports\sales' + LExporter.GetExtension);

  LExporter := TReportExporterFactory.CreateExporter('excel');
  LExporter.Export(LData, 'C:\reports\sales' + LExporter.GetExtension);

  LExporter := TReportExporterFactory.CreateExporter('csv');
  LExporter.Export(LData, 'C:\reports\sales' + LExporter.GetExtension);
end;

end.

