unit MeuApp.Examples.Refactoring;
{
  REFATORAÇÃO DE CÓDIGO DELPHI — Exemplos Antes/Depois
  =====================================================
  Demonstra as principais técnicas de refatoração aplicadas em Object Pascal,
  seguindo as convenções do Delphi AI Spec-Kit.

  Técnicas demonstradas:
  1. Extract Method              — quebra método longo em métodos menores
  2. Guard Clauses               — substitui nesting por saídas antecipadas
  3. Replace Magic Numbers       — constantes nomeadas no lugar de literais
  4. Replace Conditional w/ Poly — elimina case/if de tipo com Strategy
  5. Introduce Parameter Object  — agrupa parâmetros em Record/DTO
  6. Remove `with` Statement     — elimina escopo implícito perigoso
  7. Extract Class               — separa responsabilidades em classes coesas
  8. Extract Interface + DI      — desacopla dependências para testabilidade
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

// ============================================================================
// EXCEÇÕES DE DOMÍNIO
// ============================================================================

type
  EBusinessRuleException     = class(Exception);
  EValidationException       = class(Exception);
  EInsufficientFundsException= class(Exception);
  EArgumentNilException      = class(Exception);

// ============================================================================
// TÉCNICA 1: GUARD CLAUSES
// Elimina nesting criando saídas antecipadas para casos inválidos.
// ============================================================================

type
  TAccount = class
  public
    Balance: Currency;
    IsActive: Boolean;
    IsBlocked: Boolean;
  end;

  { ❌ ANTES: 5 níveis de nesting }
  TBankServiceBefore = class
  public
    function Withdraw(AAccount: TAccount; AAmount: Currency): Boolean;
  end;

  { ✅ DEPOIS: guard clauses — casos inválidos saem cedo, lógica no topo }
  TBankServiceAfter = class
  public
    function Withdraw(AAccount: TAccount; AAmount: Currency): Boolean;
  end;

// ============================================================================
// TÉCNICA 2: REPLACE MAGIC NUMBERS WITH CONSTANTS
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
      ANNUAL_INTEREST_RATE     = 0.139;  // 13.9% ao ano
      MONTHS_IN_YEAR           = 12;
      MIN_ELIGIBLE_AGE         = 18;
      MAX_ELIGIBLE_AGE         = 70;
      MIN_INCOME_MULTIPLIER    = 3.0;    // renda mínima = 3x a parcela
  public
    function CalculateMonthlyPayment(APrincipal: Currency; AMonths: Integer): Currency;
    function IsEligible(AAge: Integer; AIncome: Currency): Boolean;
  end;

// ============================================================================
// TÉCNICA 3: EXTRACT METHOD
// Quebra método longo em partes com responsabilidade única.
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

  { ❌ ANTES: um método de 40 linhas gerando nota fiscal }
  TInvoiceServiceBefore = class
  public
    procedure GenerateInvoice(AOrder: TOrder);
  end;

  { ✅ DEPOIS: responsabilidades extraídas, cada método ≤ 15 linhas }
  TInvoiceServiceAfter = class
  private
    const
      VIP_DISCOUNT_RATE  = 0.10;  // 10% para VIP
      BULK_DISCOUNT_MIN  = 500.0; // mínimo para desconto por volume
      BULK_DISCOUNT_RATE = 0.05;  // 5% por volume
      STANDARD_TAX_RATE  = 0.12;  // 12% de imposto padrão

    function CalculateSubtotal(AOrder: TOrder): Currency;
    function CalculateDiscount(AOrder: TOrder; ASubtotal: Currency): Currency;
    function CalculateTax(ASubtotal: Currency): Currency;
    procedure WriteInvoiceFile(AOrder: TOrder; ASubtotal, ADiscount, ATax: Currency);
  public
    procedure GenerateInvoice(AOrder: TOrder);
  end;

// ============================================================================
// TÉCNICA 4: REPLACE CONDITIONAL WITH POLYMORPHISM (Strategy)
// ============================================================================

type
  TShippingMethodKind = (smPAC, smSEDEX, smTransportadora, smRetirada);

  { ❌ ANTES: case com lógica espalhada }
  TShippingServiceBefore = class
  public
    function CalculateFreight(AWeightKg: Double; AMethod: TShippingMethodKind): Currency;
  end;

  { ✅ DEPOIS: Strategy — adicionar novo meio = nova classe, zero edições }
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

  // Factory que mapeia o enum legado → Strategy moderna
  TFreightStrategyFactory = class
  public
    class function Create(AMethod: TShippingMethodKind): IFreightStrategy;
  end;

  TShippingServiceAfter = class
  public
    function CalculateFreight(AWeightKg: Double; AStrategy: IFreightStrategy): Currency;
  end;

// ============================================================================
// TÉCNICA 5: INTRODUCE PARAMETER OBJECT
// ============================================================================

type
  { ❌ ANTES: 7 parâmetros }
  TReportServiceBefore = class
  public
    function GenerateSalesReport(
      AStartDate: TDate; AEndDate: TDate;
      const ACategory: string; const ASalesRepId: string;
      AMinAmount: Currency; AGroupByMonth: Boolean;
      AIncludeReturns: Boolean): string;
  end;

  { ✅ DEPOIS: parâmetros em Record com valores padrão }
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
// TÉCNICA 6: EXTRACT INTERFACE + DEPENDENCY INVERSION
// Desacopla dependências para permitir testes com Fakes.
// ============================================================================

type
  { ❌ ANTES: acoplado a classes concretas }
  TNotificationServiceBefore = class
  public
    procedure NotifyOrderPlaced(AOrderId: Integer; const AEmail: string);
    // Instancia TSmtpSender e TSlackClient internamente — impossível testar
  end;

  { ✅ DEPOIS: depende de interfaces, testável com Fakes }
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

  // Fakes para testes DUnitX
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
// TÉCNICA 1: GUARD CLAUSES — Implementação
// ============================================================================

{ TBankServiceBefore }

function TBankServiceBefore.Withdraw(AAccount: TAccount; AAmount: Currency): Boolean;
begin
  Result := False;
  // 5 níveis de nesting — difícil de ler e manter
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
  // Guard clauses — casos inválidos eliminam o nesting
  if not Assigned(AAccount) then
    raise EArgumentNilException.Create('Conta não pode ser nula');
  if not AAccount.IsActive then
    raise EBusinessRuleException.Create('Operação negada: conta inativa');
  if AAmount <= 0 then
    raise EValidationException.Create('Valor do saque deve ser maior que zero');
  if AAccount.Balance < AAmount then
    raise EInsufficientFundsException.CreateFmt(
      'Saldo insuficiente. Disponível: R$%.2f', [AAccount.Balance]);
  if AAccount.IsBlocked then
    raise EBusinessRuleException.Create('Operação negada: conta bloqueada');

  // Lógica principal — sem nesting, fácil de entender
  AAccount.Balance := AAccount.Balance - AAmount;
  Result := True;
end;

// ============================================================================
// TÉCNICA 2: MAGIC NUMBERS — Implementação
// ============================================================================

{ TLoanCalculatorBefore }

function TLoanCalculatorBefore.CalculateMonthlyPayment(APrincipal: Currency;
  AMonths: Integer): Currency;
var LMonthlyRate: Double;
begin
  // ❌ 0.139 e 12 são números mágicos — o que significam?
  LMonthlyRate := 0.139 / 12;
  Result := APrincipal * (LMonthlyRate * Power(1 + LMonthlyRate, AMonths)) /
            (Power(1 + LMonthlyRate, AMonths) - 1);
end;

function TLoanCalculatorBefore.IsEligible(AAge: Integer; AIncome: Currency): Boolean;
begin
  // ❌ 18, 70 e 3.0 são mágicos — por que estes valores?
  Result := (AAge >= 18) and (AAge <= 70) and (AIncome >= AIncome * 3.0);
end;

{ TLoanCalculatorAfter }

function TLoanCalculatorAfter.CalculateMonthlyPayment(APrincipal: Currency;
  AMonths: Integer): Currency;
var LMonthlyRate: Double;
begin
  // ✅ Constantes nomeadas — auto-documentado
  LMonthlyRate := ANNUAL_INTEREST_RATE / MONTHS_IN_YEAR;
  Result := APrincipal * (LMonthlyRate * Power(1 + LMonthlyRate, AMonths)) /
            (Power(1 + LMonthlyRate, AMonths) - 1);
end;

function TLoanCalculatorAfter.IsEligible(AAge: Integer; AIncome: Currency): Boolean;
var LMonthlyPayment: Currency;
begin
  // ✅ Lógica clara com constantes
  if (AAge < MIN_ELIGIBLE_AGE) or (AAge > MAX_ELIGIBLE_AGE) then
    Exit(False);
  LMonthlyPayment := CalculateMonthlyPayment(AIncome, MONTHS_IN_YEAR);
  Result := AIncome >= LMonthlyPayment * MIN_INCOME_MULTIPLIER;
end;

// ============================================================================
// TÉCNICA 3: EXTRACT METHOD — Implementação
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
  // ❌ ANTES: tudo em um método — 40+ linhas misturando cálculo, formatação e E/S

  // Calcula subtotal
  LSubtotal := 0;
  for LItem in AOrder.Items do
    LSubtotal := LSubtotal + (LItem.UnitPrice * LItem.Quantity);

  // Aplica desconto
  if AOrder.IsVipCustomer then
    LDiscount := LSubtotal * 0.10
  else if LSubtotal > 500 then
    LDiscount := LSubtotal * 0.05
  else
    LDiscount := 0;

  // Calcula imposto
  LTax := (LSubtotal - LDiscount) * 0.12;
  LTotal := LSubtotal - LDiscount + LTax;

  // Grava arquivo
  LLines := TStringList.Create;
  try
    LLines.Add('=== NOTA FISCAL ===');
    LLines.Add(Format('Cliente: %s', [AOrder.CustomerName]));
    for LItem in AOrder.Items do
      LLines.Add(Format('  %-30s %3dx R$%8.2f = R$%8.2f',
        [LItem.ProductName, LItem.Quantity,
         LItem.UnitPrice, LItem.UnitPrice * LItem.Quantity]));
    LLines.Add(Format('Subtotal:  R$%.2f', [LSubtotal]));
    LLines.Add(Format('Desconto: -R$%.2f', [LDiscount]));
    LLines.Add(Format('Imposto:  +R$%.2f', [LTax]));
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
  // ✅ APÓS: responsabilidade única — calcula apenas o subtotal
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
    LLines.Add('=== NOTA FISCAL ===');
    LLines.Add(Format('Cliente: %s', [AOrder.CustomerName]));
    for LItem in AOrder.Items do
      LLines.Add(Format('  %-30s %3dx R$%8.2f = R$%8.2f',
        [LItem.ProductName, LItem.Quantity,
         LItem.UnitPrice, LItem.UnitPrice * LItem.Quantity]));
    LLines.Add(Format('Subtotal:  R$%.2f', [ASubtotal]));
    LLines.Add(Format('Desconto: -R$%.2f', [ADiscount]));
    LLines.Add(Format('Imposto:  +R$%.2f', [ATax]));
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
  // ✅ Orquestra os métodos extraídos — lê como prosa
  LSubtotal := CalculateSubtotal(AOrder);
  LDiscount := CalculateDiscount(AOrder, LSubtotal);
  LTax      := CalculateTax(LSubtotal - LDiscount);
  WriteInvoiceFile(AOrder, LSubtotal, LDiscount, LTax);
end;

// ============================================================================
// TÉCNICA 4: STRATEGY — Implementação
// ============================================================================

{ TShippingServiceBefore }

function TShippingServiceBefore.CalculateFreight(AWeightKg: Double;
  AMethod: TShippingMethodKind): Currency;
begin
  // ❌ ANTES: case que precisa ser editado a cada novo método de entrega
  case AMethod of
    smPAC:            Result := AWeightKg * 2.50 + 8.0;
    smSEDEX:          Result := AWeightKg * 4.80 + 15.0;
    smTransportadora: Result := AWeightKg * 1.20;
    smRetirada:       Result := 0;
  else
    raise EArgumentException.Create('Método de entrega desconhecido');
  end;
end;

{ TPACStrategy }
function TPACStrategy.Calculate(AWeightKg: Double): Currency;
const BASE_FEE = 8.0; RATE_PER_KG = 2.50;
begin
  Result := AWeightKg * RATE_PER_KG + BASE_FEE;
end;
function TPACStrategy.GetCarrierName: string;
begin Result := 'Correios PAC'; end;

{ TSEDEXStrategy }
function TSEDEXStrategy.Calculate(AWeightKg: Double): Currency;
const BASE_FEE = 15.0; RATE_PER_KG = 4.80;
begin
  Result := AWeightKg * RATE_PER_KG + BASE_FEE;
end;
function TSEDEXStrategy.GetCarrierName: string;
begin Result := 'Correios SEDEX'; end;

{ TTransportadoraStrategy }
function TTransportadoraStrategy.Calculate(AWeightKg: Double): Currency;
const RATE_PER_KG = 1.20;
begin Result := AWeightKg * RATE_PER_KG; end;
function TTransportadoraStrategy.GetCarrierName: string;
begin Result := 'Transportadora Parceira'; end;

{ TRetiradaStrategy }
function TRetiradaStrategy.Calculate(AWeightKg: Double): Currency;
begin Result := 0; end;
function TRetiradaStrategy.GetCarrierName: string;
begin Result := 'Retirada na Loja'; end;

{ TFreightStrategyFactory }
class function TFreightStrategyFactory.Create(AMethod: TShippingMethodKind): IFreightStrategy;
begin
  case AMethod of
    smPAC:            Result := TPACStrategy.Create;
    smSEDEX:          Result := TSEDEXStrategy.Create;
    smTransportadora: Result := TTransportadoraStrategy.Create;
    smRetirada:       Result := TRetiradaStrategy.Create;
  else
    raise EArgumentException.Create('Método de entrega desconhecido');
  end;
end;

{ TShippingServiceAfter }

function TShippingServiceAfter.CalculateFreight(AWeightKg: Double;
  AStrategy: IFreightStrategy): Currency;
begin
  // ✅ DEPOIS: apenas delega — adicionar nova modalidade = nova classe
  if not Assigned(AStrategy) then
    raise EArgumentNilException.Create('AStrategy não pode ser nil');
  Result := AStrategy.Calculate(AWeightKg);
end;

// ============================================================================
// TÉCNICA 5: PARAMETER OBJECT — Implementação
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
  // ❌ 7 parâmetros — chamada confusa no ponto de uso
  Result := Format('Report %s-%s Cat:%s Rep:%s Min:%.0f',
    [DateToStr(AStartDate), DateToStr(AEndDate), ACategory, ASalesRepId, AMinAmount]);
end;

{ TReportServiceAfter }

function TReportServiceAfter.GenerateSalesReport(AFilter: TSalesReportFilter): string;
begin
  // ✅ UM parâmetro coeso — ponto de uso legível:
  //    ReportService.GenerateSalesReport(TSalesReportFilter.Default)
  Result := Format('Report %s-%s Cat:%s Rep:%s Min:%.0f',
    [DateToStr(AFilter.StartDate), DateToStr(AFilter.EndDate),
     AFilter.Category, AFilter.SalesRepId, AFilter.MinAmount]);
end;

// ============================================================================
// TÉCNICA 6: EXTRACT INTERFACE + DI — Implementação
// ============================================================================

{ TNotificationServiceBefore }

procedure TNotificationServiceBefore.NotifyOrderPlaced(AOrderId: Integer;
  const AEmail: string);
begin
  // ❌ Instancia dependências internamente — impossível testar sem servidor SMTP/Slack
  // TSmtpSender.Create('smtp.empresa.com', 587).Send(AEmail, ...);
  // TSlackClient.Create(SLACK_TOKEN).Post('#pedidos', ...);
  Writeln('[BEFORE] Notificando pedido (hardcoded — não testável)');
end;

{ TNotificationServiceAfter }

constructor TNotificationServiceAfter.Create(AEmailSender: IEmailSender;
  ASlackNotifier: ISlackNotifier);
begin
  inherited Create;
  if not Assigned(AEmailSender) then
    raise EArgumentNilException.Create('AEmailSender não pode ser nil');
  if not Assigned(ASlackNotifier) then
    raise EArgumentNilException.Create('ASlackNotifier não pode ser nil');
  FEmailSender  := AEmailSender;
  FSlackNotifier := ASlackNotifier;
end;

procedure TNotificationServiceAfter.NotifyOrderPlaced(AOrderId: Integer;
  const AEmail: string);
begin
  // ✅ Delega para abstrações — fácil de testar com TFakeEmailSender
  FEmailSender.Send(
    AEmail,
    Format('Pedido #%d confirmado', [AOrderId]),
    Format('Seu pedido #%d foi recebido e está sendo processado.', [AOrderId])
  );
  FSlackNotifier.PostMessage(
    '#pedidos',
    Format('🛍️ Novo pedido #%d para %s', [AOrderId, AEmail])
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
// DEMONSTRAÇÃO — Como usar as versões refatoradas
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
      Writeln(Format('Saldo após saque: R$%.2f', [LAccount.Balance]));  // 700

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
  Writeln('=== STRATEGY — FRETE ===');
  LSvc := TShippingServiceAfter.Create;
  try
    LFreight := LSvc.CalculateFreight(2.5, TPACStrategy.Create);
    Writeln(Format('PAC 2.5kg: R$%.2f', [LFreight]));    // 2.5*2.5 + 8 = 14.25

    LFreight := LSvc.CalculateFreight(2.5, TSEDEXStrategy.Create);
    Writeln(Format('SEDEX 2.5kg: R$%.2f', [LFreight]));  // 2.5*4.8 + 15 = 27.00

    LFreight := LSvc.CalculateFreight(2.5, TRetiradaStrategy.Create);
    Writeln(Format('Retirada: R$%.2f', [LFreight]));      // 0.00
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
    // Uso com valores default + sobrescrita seletiva — muito mais legível
    LFilter           := TSalesReportFilter.Default;
    LFilter.Category  := 'Eletrônicos';
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

  // Interfaces gerenciadas por ARC — sem Free necessário para os fakes
  LSvc := TNotificationServiceAfter.Create(LEmailFake, LSlackFake);
  try
    LSvc.NotifyOrderPlaced(1042, 'joao@email.com');

    // Verificações sem servidor real
    Writeln(Format('E-mail enviado para: %s (%d)', [LEmailFake.LastTo, LEmailFake.SentCount]));
    Writeln(Format('Slack postado: %s (%d)', [LSlackFake.LastMessage, LSlackFake.PostedCount]));
  finally
    LSvc.Free;
  end;
end;

end.
