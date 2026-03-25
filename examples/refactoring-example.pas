unit MeuApp.Examples.Refactoring;
{
  DELPHI CODE REFACTORING — Before/After Examples
  ===============================================
  Demonstrates the main refactoring techniques applied in Object Pascal,
  following the conventions of the Delphi AI Spec-Kit.

  Techniques demonstrated:
  1. Extract Method              — breaks a long method into smaller ones
  2. Guard Clauses               — replaces nesting with early exits
  3. Replace Magic Numbers       — named constants instead of literals
  4. Replace Conditional w/ Poly — eliminates type case/if with Strategy
  5. Introduce Parameter Object  — groups parameters into Record/DTO
  6. Remove `with` Statement     — eliminates dangerous implicit scope
  7. Extract Class               — separates responsibilities into cohesive classes
  8. Extract Interface + DI      — decouples dependencies for testability
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

// ============================================================================
// DOMAIN EXCEPTIONS
// ============================================================================

type
  EBusinessRuleException     = class(Exception);
  EValidationException       = class(Exception);
  EInsufficientFundsException= class(Exception);
  EArgumentNilException      = class(Exception);

// ============================================================================
// TECHNIQUE 1: GUARD CLAUSES
// Eliminates nesting by creating early exits for invalid cases.
// ============================================================================

type
  TAccount = class
  public
    Balance: Currency;
    IsActive: Boolean;
    IsBlocked: Boolean;
  end;

  { ❌ BEFORE: 5 levels of nesting }
  TBankServiceBefore = class
  public
    function Withdraw(AAccount: TAccount; AAmount: Currency): Boolean;
  end;

  { ✅ AFTER: guard clauses — invalid cases exit early, logic at the top }
  TBankServiceAfter = class
  public
    function Withdraw(AAccount: TAccount; AAmount: Currency): Boolean;
  end;

// ============================================================================
// TECHNIQUE 2: REPLACE MAGIC NUMBERS WITH CONSTANTS
// ============================================================================

type
  TLoanCalculatorBefore = class
  public
    function CalculateMonthlyPayment(APrincipal: Currency; AMonths: Integer): Currency;
    function IsEligible(AAge: Integer; AIncome: Currency): Boolean;
  end;

  TLoanCalculatorAfter = class
  private
    const
      ANNUAL_INTEREST_RATE     = 0.139;  // 13.9% per year
      MONTHS_IN_YEAR           = 12;
      MIN_ELIGIBLE_AGE         = 18;
      MAX_ELIGIBLE_AGE         = 70;
      MIN_INCOME_MULTIPLIER    = 3.0;    // minimum income = 3x the installment
  public
    function CalculateMonthlyPayment(APrincipal: Currency; AMonths: Integer): Currency;
    function IsEligible(AAge: Integer; AIncome: Currency): Boolean;
  end;

// ============================================================================
// TECHNIQUE 3: EXTRACT METHOD
// Break long method into parts with single responsibility.
// ============================================================================

type
  TOrderItem = record
    ProductName: string;
    UnitPrice: Currency;
    Quantity: Integer;
  end;

  TOrder = class
  public
    CustomerName: string;
    IsVipCustomer: Boolean;
    Items: TArray<TOrderItem>;
    InvoicePath: string;
    function GetItemCount: Integer;
  end;

  { ❌ BEFORE: a 40-line method generating an invoice }
  TInvoiceServiceBefore = class
  public
    procedure GenerateInvoice(AOrder: TOrder);
  end;

  { ✅ AFTER: responsibilities extracted, each method ≤ 15 lines }
  TInvoiceServiceAfter = class
  private
    const
      VIP_DISCOUNT_RATE  = 0.10;  // 10% for VIP
      BULK_DISCOUNT_MIN  = 500.0; // minimum for bulk discount
      BULK_DISCOUNT_RATE = 0.05;  // 5% bulk
      STANDARD_TAX_RATE  = 0.12;  // 12% default tax

    function CalculateSubtotal(AOrder: TOrder): Currency;
    function CalculateDiscount(AOrder: TOrder; ASubtotal: Currency): Currency;
    function CalculateTax(ASubtotal: Currency): Currency;
    procedure WriteInvoiceFile(AOrder: TOrder; ASubtotal, ADiscount, ATax: Currency);
  public
    procedure GenerateInvoice(AOrder: TOrder);
  end;

// ============================================================================
// TECHNIQUE 4: CONDITIONAL REPLACE WITH POLYMORPHISM (Strategy)
// ============================================================================

type
  TShippingMethodKind = (smPAC, smSEDEX, smTransportadora, smRetirada);

  { ❌ BEFORE: case with scattered logic }
  TShippingServiceBefore = class
  public
    function CalculateFreight(AWeightKg: Double; AMethod: TShippingMethodKind): Currency;
  end;

  { ✅ AFTER: Strategy — add new method = new class, zero edits }
  IFreightStrategy = interface
    ['{AAAA0001-0000-0000-0000-000000000001}']
    function Calculate(AWeightKg: Double): Currency;
    function GetCarrierName: string;
  end;

  TPACStrategy = class(TInterfacedObject, IFreightStrategy)
  public
    function Calculate(AWeightKg: Double): Currency;
    function GetCarrierName: string;
  end;

  TSEDEXStrategy = class(TInterfacedObject, IFreightStrategy)
  public
    function Calculate(AWeightKg: Double): Currency;
    function GetCarrierName: string;
  end;

  TTransportadoraStrategy = class(TInterfacedObject, IFreightStrategy)
  public
    function Calculate(AWeightKg: Double): Currency;
    function GetCarrierName: string;
  end;

  TRetiradaStrategy = class(TInterfacedObject, IFreightStrategy)
  public
    function Calculate(AWeightKg: Double): Currency;
    function GetCarrierName: string;
  end;

  // Factory that maps the legacy enum → Modern Strategy
  TFreightStrategyFactory = class
  public
    class function Create(AMethod: TShippingMethodKind): IFreightStrategy;
  end;

  TShippingServiceAfter = class
  public
    function CalculateFreight(AWeightKg: Double; AStrategy: IFreightStrategy): Currency;
  end;

// ============================================================================
// TECHNIQUE 5: INTRODUCE PARAMETER OBJECT
// ============================================================================

type
  { ❌ BEFORE: 7 parameters }
  TReportServiceBefore = class
  public
    function GenerateSalesReport(
      AStartDate: TDate; AEndDate: TDate;
      const ACategory: string; const ASalesRepId: string;
      AMinAmount: Currency; AGroupByMonth: Boolean;
      AIncludeReturns: Boolean): string;
  end;

  { ✅ AFTER: parameters in Record with default values }
  TSalesReportFilter = record
    StartDate: TDate;
    EndDate: TDate;
    Category: string;
    SalesRepId: string;
    MinAmount: Currency;
    GroupByMonth: Boolean;
    IncludeReturns: Boolean;
    class function Default: TSalesReportFilter; static;
  end;

  TReportServiceAfter = class
  public
    function GenerateSalesReport(AFilter: TSalesReportFilter): string;
  end;

// ============================================================================
// TECHNIQUE 6: EXTRACT INTERFACE + DEPENDENCY INVERSION
// Decouples dependencies to allow testing with Fakes.
// ============================================================================

type
  { ❌ BEFORE: coupled to concrete classes }
  TNotificationServiceBefore = class
  public
    procedure NotifyOrderPlaced(AOrderId: Integer; const AEmail: string);
    // Instantiate TSmtpSender and TSlackClient internally — impossible to test
  end;

  { ✅ AFTER: depends on interfaces, testable with Fakes }
  IEmailSender = interface
    ['{AAAA0002-0000-0000-0000-000000000002}']
    procedure Send(const ATo, ASubject, ABody: string);
  end;

  ISlackNotifier = interface
    ['{AAAA0003-0000-0000-0000-000000000003}']
    procedure PostMessage(const AChannel, AMessage: string);
  end;

  TNotificationServiceAfter = class
  private
    FEmailSender: IEmailSender;
    FSlackNotifier: ISlackNotifier;
  public
    constructor Create(AEmailSender: IEmailSender; ASlackNotifier: ISlackNotifier);
    procedure NotifyOrderPlaced(AOrderId: Integer; const AEmail: string);
  end;

  // Fakes for DUnitX tests
  TFakeEmailSender = class(TInterfacedObject, IEmailSender)
  public
    LastTo: string;
    LastSubject: string;
    SentCount: Integer;
    procedure Send(const ATo, ASubject, ABody: string);
  end;

  TFakeSlackNotifier = class(TInterfacedObject, ISlackNotifier)
  public
    LastMessage: string;
    PostedCount: Integer;
    procedure PostMessage(const AChannel, AMessage: string);
  end;

implementation

// ============================================================================
// TECHNIQUE 1: GUARD CLAUSES — Implementation
// ============================================================================

{ TBankServiceBefore }

function TBankServiceBefore.Withdraw(AAccount: TAccount; AAmount: Currency): Boolean;
begin
  Result := False;
  // 5 nesting levels — difficult to read and maintain
  if Assigned(AAccount) then
    if AAccount.IsActive then
      if AAmount > 0 then
        if AAccount.Balance >= AAmount then
          if not AAccount.IsBlocked then
          begin
            AAccount.Balance := AAccount.Balance - AAmount;
            Result := True;
          end;
end;

{ TBankServiceAfter }

function TBankServiceAfter.Withdraw(AAccount: TAccount; AAmount: Currency): Boolean;
begin
  // Guard clauses — invalid cases eliminate nesting
  if not Assigned(AAccount) then
    raise EArgumentNilException.Create('Account cannot be null');
  if not AAccount.IsActive then
    raise EBusinessRuleException.Create('Operation denied: inactive account');
  if AAmount <= 0 then
    raise EValidationException.Create('Withdrawal amount must be greater than zero');
  if AAccount.Balance < AAmount then
    raise EInsufficientFundsException.CreateFmt(
      'Insufficient balance. Available: R$%.2f', [AAccount.Balance]);
  if AAccount.IsBlocked then
    raise EBusinessRuleException.Create('Operation denied: account blocked');

  // Core logic — no nesting, easy to understand
  AAccount.Balance := AAccount.Balance - AAmount;
  Result := True;
end;

// ============================================================================
// TECHNIQUE 2: MAGIC NUMBERS — Implementation
// ============================================================================

{ TLoanCalculatorBefore }

function TLoanCalculatorBefore.CalculateMonthlyPayment(APrincipal: Currency;
  AMonths: Integer): Currency;
var LMonthlyRate: Double;
begin
  // ❌ 0.139 and 12 are magic numbers — what do they mean?
  LMonthlyRate := 0.139 / 12;
  Result := APrincipal * (LMonthlyRate * Power(1 + LMonthlyRate, AMonths)) /
            (Power(1 + LMonthlyRate, AMonths) - 1);
end;

function TLoanCalculatorBefore.IsEligible(AAge: Integer; AIncome: Currency): Boolean;
begin
  // ❌ 18, 70 and 3.0 are magic — why these values?
  Result := (AAge >= 18) and (AAge <= 70) and (AIncome >= AIncome * 3.0);
end;

{ TLoanCalculatorAfter }

function TLoanCalculatorAfter.CalculateMonthlyPayment(APrincipal: Currency;
  AMonths: Integer): Currency;
var LMonthlyRate: Double;
begin
  // ✅ Named constants — self-documenting
  LMonthlyRate := ANNUAL_INTEREST_RATE / MONTHS_IN_YEAR;
  Result := APrincipal * (LMonthlyRate * Power(1 + LMonthlyRate, AMonths)) /
            (Power(1 + LMonthlyRate, AMonths) - 1);
end;

function TLoanCalculatorAfter.IsEligible(AAge: Integer; AIncome: Currency): Boolean;
var LMonthlyPayment: Currency;
begin
  // ✅ Clear logic with constants
  if (AAge < MIN_ELIGIBLE_AGE) or (AAge > MAX_ELIGIBLE_AGE) then
    Exit(False);
  LMonthlyPayment := CalculateMonthlyPayment(AIncome, MONTHS_IN_YEAR);
  Result := AIncome >= LMonthlyPayment * MIN_INCOME_MULTIPLIER;
end;

// ============================================================================
// TECHNIQUE 3: EXTRACT METHOD — Implementation
// ============================================================================

{ TOrder }

function TOrder.GetItemCount: Integer;
begin
  Result := Length(Items);
end;

{ TInvoiceServiceBefore }

procedure TInvoiceServiceBefore.GenerateInvoice(AOrder: TOrder);
var
  LSubtotal, LDiscount, LTax, LTotal: Currency;
  LItem: TOrderItem;
  LLines: TStringList;
begin
  // ❌ BEFORE: all in one method — 40+ lines mixing calculation, formatting and I/O

  // Calculate subtotal
  LSubtotal := 0;
  for LItem in AOrder.Items do
    LSubtotal := LSubtotal + (LItem.UnitPrice * LItem.Quantity);

  //Apply discount
  if AOrder.IsVipCustomer then
    LDiscount := LSubtotal * 0.10
  else if LSubtotal > 500 then
    LDiscount := LSubtotal * 0.05
  else
    LDiscount := 0;

  // Calculate tax
  LTax := (LSubtotal - LDiscount) * 0.12;
  LTotal := LSubtotal - LDiscount + LTax;

  // Write file
  LLines := TStringList.Create;
  try
    LLines.Add('=== TAX NOTE ===');
    LLines.Add(Format('Client: %s', [AOrder.CustomerName]));
    for LItem in AOrder.Items do
      LLines.Add(Format('  %-30s %3dx R$%8.2f = R$%8.2f',
        [LItem.ProductName, LItem.Quantity,
         LItem.UnitPrice, LItem.UnitPrice * LItem.Quantity]));
    LLines.Add(Format('Subtotal: R$%.2f', [LSubtotal]));
    LLines.Add(Format('Discount: -R$%.2f', [LDiscount]));
    LLines.Add(Format('Tax: +R$%.2f', [LTax]));
    LLines.Add(Format('TOTAL:     R$%.2f', [LTotal]));
    LLines.SaveToFile(AOrder.InvoicePath);
  finally
    LLines.Free;
  end;
end;

{ TInvoiceServiceAfter }

function TInvoiceServiceAfter.CalculateSubtotal(AOrder: TOrder): Currency;
var LItem: TOrderItem;
begin
  // ✅ AFTER: single responsibility — calculates only the subtotal
  Result := 0;
  for LItem in AOrder.Items do
    Result := Result + (LItem.UnitPrice * LItem.Quantity);
end;

function TInvoiceServiceAfter.CalculateDiscount(AOrder: TOrder; ASubtotal: Currency): Currency;
begin
  if AOrder.IsVipCustomer then
    Result := ASubtotal * VIP_DISCOUNT_RATE
  else if ASubtotal > BULK_DISCOUNT_MIN then
    Result := ASubtotal * BULK_DISCOUNT_RATE
  else
    Result := 0;
end;

function TInvoiceServiceAfter.CalculateTax(ASubtotal: Currency): Currency;
begin
  Result := ASubtotal * STANDARD_TAX_RATE;
end;

procedure TInvoiceServiceAfter.WriteInvoiceFile(AOrder: TOrder;
  ASubtotal, ADiscount, ATax: Currency);
var
  LLines: TStringList;
  LItem: TOrderItem;
begin
  LLines := TStringList.Create;
  try
    LLines.Add('=== TAX NOTE ===');
    LLines.Add(Format('Client: %s', [AOrder.CustomerName]));
    for LItem in AOrder.Items do
      LLines.Add(Format('  %-30s %3dx R$%8.2f = R$%8.2f',
        [LItem.ProductName, LItem.Quantity,
         LItem.UnitPrice, LItem.UnitPrice * LItem.Quantity]));
    LLines.Add(Format('Subtotal: R$%.2f', [ASubtotal]));
    LLines.Add(Format('Discount: -R$%.2f', [ADiscount]));
    LLines.Add(Format('Tax: +R$%.2f', [ATax]));
    LLines.Add(Format('TOTAL:     R$%.2f', [ASubtotal - ADiscount + ATax]));
    LLines.SaveToFile(AOrder.InvoicePath);
  finally
    LLines.Free;
  end;
end;

procedure TInvoiceServiceAfter.GenerateInvoice(AOrder: TOrder);
var
  LSubtotal, LDiscount, LTax: Currency;
begin
  // ✅ Orchestrates extracted methods — reads like prose
  LSubtotal := CalculateSubtotal(AOrder);
  LDiscount := CalculateDiscount(AOrder, LSubtotal);
  LTax      := CalculateTax(LSubtotal - LDiscount);
  WriteInvoiceFile(AOrder, LSubtotal, LDiscount, LTax);
end;

// ============================================================================
// TECHNIQUE 4: STRATEGY — Implementation
// ============================================================================

{ TShippingServiceBefore }

function TShippingServiceBefore.CalculateFreight(AWeightKg: Double;
  AMethod: TShippingMethodKind): Currency;
begin
  // ❌ BEFORE: case that needs to be edited with each new delivery method
  case AMethod of
    smPAC:            Result := AWeightKg * 2.50 + 8.0;
    smSEDEX:          Result := AWeightKg * 4.80 + 15.0;
    smTransportadora: Result := AWeightKg * 1.20;
    smRetirada:       Result := 0;
  else
    raise EArgumentException.Create('Unknown delivery method');
  end;
end;

{ TPACStrategy }
function TPACStrategy.Calculate(AWeightKg: Double): Currency;
const BASE_FEE = 8.0; RATE_PER_KG = 2.50;
begin
  Result := AWeightKg * RATE_PER_KG + BASE_FEE;
end;
function TPACStrategy.GetCarrierName: string;
begin Result := 'PAC Post Office'; end;

{ TSEDEXStrategy }
function TSEDEXStrategy.Calculate(AWeightKg: Double): Currency;
const BASE_FEE = 15.0; RATE_PER_KG = 4.80;
begin
  Result := AWeightKg * RATE_PER_KG + BASE_FEE;
end;
function TSEDEXStrategy.GetCarrierName: string;
begin Result := 'SEDEX Post Office'; end;

{ TTransportadoraStrategy }
function TTransportadoraStrategy.Calculate(AWeightKg: Double): Currency;
const RATE_PER_KG = 1.20;
begin Result := AWeightKg * RATE_PER_KG; end;
function TTransportadoraStrategy.GetCarrierName: string;
begin Result := 'Partner Carrier'; end;

{ TRetiradaStrategy }
function TRetiradaStrategy.Calculate(AWeightKg: Double): Currency;
begin Result := 0; end;
function TRetiradaStrategy.GetCarrierName: string;
begin Result := 'In-Store Pickup'; end;

{ TFreightStrategyFactory }
class function TFreightStrategyFactory.Create(AMethod: TShippingMethodKind): IFreightStrategy;
begin
  case AMethod of
    smPAC:            Result := TPACStrategy.Create;
    smSEDEX:          Result := TSEDEXStrategy.Create;
    smTransportadora: Result := TTransportadoraStrategy.Create;
    smRetirada:       Result := TRetiradaStrategy.Create;
  else
    raise EArgumentException.Create('Unknown delivery method');
  end;
end;

{ TShippingServiceAfter }

function TShippingServiceAfter.CalculateFreight(AWeightKg: Double;
  AStrategy: IFreightStrategy): Currency;
begin
  // ✅ AFTER: just delegate — add new modality = new class
  if not Assigned(AStrategy) then
    raise EArgumentNilException.Create('AStrategy cannot be nil');
  Result := AStrategy.Calculate(AWeightKg);
end;

// ============================================================================
// TECHNIQUE 5: PARAMETER OBJECT — Implementation
// ============================================================================

{ TSalesReportFilter }

class function TSalesReportFilter.Default: TSalesReportFilter;
begin
  Result.StartDate      := StartOfYear(Date);
  Result.EndDate        := Date;
  Result.Category       := '';
  Result.SalesRepId     := '';
  Result.MinAmount      := 0;
  Result.GroupByMonth   := False;
  Result.IncludeReturns := False;
end;

{ TReportServiceBefore }

function TReportServiceBefore.GenerateSalesReport(AStartDate: TDate;
  AEndDate: TDate; const ACategory: string; const ASalesRepId: string;
  AMinAmount: Currency; AGroupByMonth: Boolean; AIncludeReturns: Boolean): string;
begin
  // ❌ 7 parameters — confusing call at point of use
  Result := Format('Report %s-%s Cat:%s Rep:%s Min:%.0f',
    [DateToStr(AStartDate), DateToStr(AEndDate), ACategory, ASalesRepId, AMinAmount]);
end;

{ TReportServiceAfter }

function TReportServiceAfter.GenerateSalesReport(AFilter: TSalesReportFilter): string;
begin
  // ✅ ONE cohesive parameter — readable point of use:
  // ReportService.GenerateSalesReport(TSalesReportFilter.Default)
  Result := Format('Report %s-%s Cat:%s Rep:%s Min:%.0f',
    [DateToStr(AFilter.StartDate), DateToStr(AFilter.EndDate),
     AFilter.Category, AFilter.SalesRepId, AFilter.MinAmount]);
end;

// ============================================================================
// TECHNIQUE 6: EXTRACT INTERFACE + DI — Implementation
// ============================================================================

{ TNotificationServiceBefore }

procedure TNotificationServiceBefore.NotifyOrderPlaced(AOrderId: Integer;
  const AEmail: string);
begin
  // ❌ Instantiates dependencies internally — impossible to test without SMTP/Slack server
  // TSmtpSender.Create('smtp.empresa.com', 587).Send(AEmail, ...);
  // TSlackClient.Create(SLACK_TOKEN).Post('#orders', ...);
  Writeln('[BEFORE] Notifying request (hardcoded — not testable)');
end;

{ TNotificationServiceAfter }

constructor TNotificationServiceAfter.Create(AEmailSender: IEmailSender;
  ASlackNotifier: ISlackNotifier);
begin
  inherited Create;
  if not Assigned(AEmailSender) then
    raise EArgumentNilException.Create('AEmailSender cannot be nil');
  if not Assigned(ASlackNotifier) then
    raise EArgumentNilException.Create('ASlackNotifier cannot be nil');
  FEmailSender  := AEmailSender;
  FSlackNotifier := ASlackNotifier;
end;

procedure TNotificationServiceAfter.NotifyOrderPlaced(AOrderId: Integer;
  const AEmail: string);
begin
  // ✅ Delegates to abstractions — easy to test with TFakeEmailSender
  FEmailSender.Send(
    AEmail,
    Format('Order #%d confirmed', [AOrderId]),
    Format('Your order #%d has been received and is being processed.', [AOrderId])
  );
  FSlackNotifier.PostMessage(
    '#orders',
    Format('🛍️ New order #%d for %s', [AOrderId, AEmail])
  );
end;

{ TFakeEmailSender }

procedure TFakeEmailSender.Send(const ATo, ASubject, ABody: string);
begin
  LastTo      := ATo;
  LastSubject := ASubject;
  Inc(SentCount);
end;

{ TFakeSlackNotifier }

procedure TFakeSlackNotifier.PostMessage(const AChannel, AMessage: string);
begin
  LastMessage := AMessage;
  Inc(PostedCount);
end;

// ============================================================================
// DEMO — How to use refactored versions
// ============================================================================

procedure DemoGuardClauses;
var
  LSvc: TBankServiceAfter;
  LAccount: TAccount;
begin
  Writeln('=== GUARD CLAUSES ===');
  LSvc := TBankServiceAfter.Create;
  try
    LAccount := TAccount.Create;
    try
      LAccount.IsActive  := True;
      LAccount.IsBlocked := False;
      LAccount.Balance   := 1000;

      LSvc.Withdraw(LAccount, 300);
      Writeln(Format('Balance after withdrawal: R$%.2f', [LAccount.Balance]));  // 700

      try
        LSvc.Withdraw(LAccount, 5000);  // saldo insuficiente
      except
        on E: EInsufficientFundsException do
          Writeln('Capturado: ' + E.Message);
      end;
    finally
      LAccount.Free;
    end;
  finally
    LSvc.Free;
  end;
end;

procedure DemoStrategy;
var
  LSvc: TShippingServiceAfter;
  LFreight: Currency;
begin
  Writeln('=== STRATEGY — SHIPPING ===');
  LSvc := TShippingServiceAfter.Create;
  try
    LFreight := LSvc.CalculateFreight(2.5, TPACStrategy.Create);
    Writeln(Format('PAC 2.5kg: R$%.2f', [LFreight]));    // 2.5*2.5 + 8 = 14.25

    LFreight := LSvc.CalculateFreight(2.5, TSEDEXStrategy.Create);
    Writeln(Format('SEDEX 2.5kg: R$%.2f', [LFreight]));  // 2.5*4.8 + 15 = 27.00

    LFreight := LSvc.CalculateFreight(2.5, TRetiradaStrategy.Create);
    Writeln(Format('Withdrawal: R$%.2f', [LFreight]));      // 0.00
  finally
    LSvc.Free;
  end;
end;

procedure DemoParameterObject;
var
  LSvc: TReportServiceAfter;
  LFilter: TSalesReportFilter;
begin
  Writeln('=== PARAMETER OBJECT ===');
  LSvc := TReportServiceAfter.Create;
  try
    // Use with default values ​​+ selective overwrite — much more readable
    LFilter           := TSalesReportFilter.Default;
    LFilter.Category  := 'Electronics';
    LFilter.MinAmount := 500;

    Writeln(LSvc.GenerateSalesReport(LFilter));
  finally
    LSvc.Free;
  end;
end;

procedure DemoDependencyInversion;
var
  LEmailFake: TFakeEmailSender;
  LSlackFake: TFakeSlackNotifier;
  LSvc: TNotificationServiceAfter;
begin
  Writeln('=== DEPENDENCY INVERSION + FAKES ===');

  LEmailFake := TFakeEmailSender.Create;
  LSlackFake := TFakeSlackNotifier.Create;

  // Interfaces managed by ARC — no Free needed for fakes
  LSvc := TNotificationServiceAfter.Create(LEmailFake, LSlackFake);
  try
    LSvc.NotifyOrderPlaced(1042, 'joao@email.com');

    // Real serverless checks
    Writeln(Format('Email sent to: %s (%d)', [LEmailFake.LastTo, LEmailFake.SentCount]));
    Writeln(Format('Slack posted: %s (%d)', [LSlackFake.LastMessage, LSlackFake.PostedCount]));
  finally
    LSvc.Free;
  end;
end;

end.

