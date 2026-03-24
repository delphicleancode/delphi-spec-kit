---
name: "Refatoração de Código Delphi"
description: "Técnicas de refatoração para Object Pascal: Extract Method, Extract Class, Guard Clauses, Replace Magic Numbers, Replace Conditional with Polymorphism, Introduce Parameter Object, Remove With, Extract Interface. Sempre com foco em manter o comportamento e melhorar a legibilidade."
---

# Refatoração de Código Delphi — Skill

Use esta skill quando o usuário solicitar refatoração, revisão de código ou remoção de code smells em Object Pascal. A refatoração **nunca altera o comportamento observável** — apenas melhora a estrutura interna do código.

## Quando Usar

- O usuário pede para "melhorar", "limpar" ou "refatorar" um código existente
- Ao revisar código e encontrar code smells
- Ao preparar código legado para receber novas funcionalidades
- Antes de adicionar testes a um código não testável
- Ao responder "por que este código é difícil de entender?"

## Princípio Fundamental

> "Refatoração é a arte de mudar a estrutura do código sem mudar seu comportamento."
> Sempre escreva (ou verifique a existência de) testes **antes** de refatorar.

---

## 📋 Catálogo de Code Smells e Técnicas

### 1. Extract Method — Método Longo

**Detectar:** Método com mais de 20 linhas ou que precisa de comentários para explicar blocos.

**Antes:**
```pascal
procedure TInvoiceService.GenerateInvoice(AOrder: TOrder);
var
  LTax, LSubtotal, LTotal: Currency;
  LItem: TOrderItem;
  LLines: TStringList;
begin
  // Calcula subtotal
  LSubtotal := 0;
  for LItem in AOrder.Items do
    LSubtotal += LItem.UnitPrice * LItem.Quantity;

  // Calcula imposto
  if AOrder.IsExempt then LTax := 0
  else LTax := LSubtotal * 0.12;

  LTotal := LSubtotal + LTax;

  // Gera linhas do relatório
  LLines := TStringList.Create;
  try
    LLines.Add('NOTA FISCAL');
    LLines.Add(Format('Cliente: %s', [AOrder.Customer.Name]));
    for LItem in AOrder.Items do
      LLines.Add(Format('  %s x%d = R$%.2f',
        [LItem.Product.Name, LItem.Quantity, LItem.UnitPrice * LItem.Quantity]));
    LLines.Add(Format('Total: R$%.2f', [LTotal]));
    LLines.SaveToFile(AOrder.InvoicePath);
  finally
    LLines.Free;
  end;
end;
```

**Depois:**
```pascal
procedure TInvoiceService.GenerateInvoice(AOrder: TOrder);
var
  LSubtotal, LTax: Currency;
begin
  LSubtotal := CalculateSubtotal(AOrder);
  LTax      := CalculateTax(AOrder, LSubtotal);
  SaveInvoiceFile(AOrder, LSubtotal + LTax);
end;

function TInvoiceService.CalculateSubtotal(AOrder: TOrder): Currency;
var LItem: TOrderItem;
begin
  Result := 0;
  for LItem in AOrder.Items do
    Result := Result + (LItem.UnitPrice * LItem.Quantity);
end;

function TInvoiceService.CalculateTax(AOrder: TOrder; ASubtotal: Currency): Currency;
const
  STANDARD_TAX_RATE = 0.12;
begin
  if AOrder.IsExempt then Result := 0
  else Result := ASubtotal * STANDARD_TAX_RATE;
end;

procedure TInvoiceService.SaveInvoiceFile(AOrder: TOrder; ATotal: Currency);
var
  LLines: TStringList;
  LItem: TOrderItem;
begin
  LLines := TStringList.Create;
  try
    LLines.Add('NOTA FISCAL');
    LLines.Add(Format('Cliente: %s', [AOrder.Customer.Name]));
    for LItem in AOrder.Items do
      LLines.Add(Format('  %s x%d = R$%.2f',
        [LItem.Product.Name, LItem.Quantity, LItem.UnitPrice * LItem.Quantity]));
    LLines.Add(Format('Total: R$%.2f', [ATotal]));
    LLines.SaveToFile(AOrder.InvoicePath);
  finally
    LLines.Free;
  end;
end;
```

---

### 2. Extract Class — Classe com Múltiplas Responsabilidades

**Detectar:** Classe com campos de naturezas diferentes, métodos sem coesão.

**Antes:**
```pascal
TEmployee = class
private
  // Dados pessoais
  FName: string;
  FBirthDate: TDate;
  FCpf: string;
  // Dados salariais
  FBaseSalary: Currency;
  FBonusPercentage: Double;
  FDepartmentId: Integer;
  // Dados de RH
  FHiredDate: TDate;
  FVacationDaysLeft: Integer;
  FPerformanceScore: Integer;
public
  function CalculateGrossSalary: Currency;
  function CalculateNetSalary: Currency;
  function CalculateVacationPay: Currency;
  function GetNextVacationDate: TDate;
  function GetYearsOfService: Integer;
  function IsEligibleForBonus: Boolean;
end;
```

**Depois:**
```pascal
// Value Object — imutável
TEmployeePersonalData = record
  Name: string;
  BirthDate: TDate;
  Cpf: string;
end;

// Classe coesa: responsabilidade salarial
TEmployeeSalary = class
private
  FBaseSalary: Currency;
  FBonusPercentage: Double;
public
  constructor Create(ABaseSalary: Currency; ABonusPercentage: Double);
  function CalculateGross: Currency;
  function CalculateNet: Currency;
  function IsEligibleForBonus: Boolean;
end;

// Classe coesa: responsabilidade de RH
TEmployeeHrRecord = class
private
  FHiredDate: TDate;
  FVacationDaysLeft: Integer;
  FPerformanceScore: Integer;
public
  function GetYearsOfService: Integer;
  function GetNextVacationDate: TDate;
  function CalculateVacationPay(AGrossSalary: Currency): Currency;
end;

// Entidade principal — agora apenas agrega as partes
TEmployee = class
private
  FPersonalData: TEmployeePersonalData;
  FSalary: TEmployeeSalary;
  FHrRecord: TEmployeeHrRecord;
public
  constructor Create(AData: TEmployeePersonalData;
    ASalary: TEmployeeSalary; AHr: TEmployeeHrRecord);
  destructor Destroy; override;
  property PersonalData: TEmployeePersonalData read FPersonalData;
  property Salary: TEmployeeSalary read FSalary;
  property HrRecord: TEmployeeHrRecord read FHrRecord;
end;
```

---

### 3. Replace Nested Conditionals with Guard Clauses

**Detectar:** Mais de 2 níveis de `if..then..begin..end` aninhados.

**Antes:**
```pascal
function TBankService.Withdraw(AAccount: TAccount; AAmount: Currency): Boolean;
begin
  Result := False;
  if Assigned(AAccount) then
  begin
    if AAccount.IsActive then
    begin
      if AAmount > 0 then
      begin
        if AAccount.Balance >= AAmount then
        begin
          if not AAccount.IsBlocked then
          begin
            AAccount.Balance := AAccount.Balance - AAmount;
            FRepository.Save(AAccount);
            Result := True;
          end;
        end;
      end;
    end;
  end;
end;
```

**Depois:**
```pascal
function TBankService.Withdraw(AAccount: TAccount; AAmount: Currency): Boolean;
begin
  if not Assigned(AAccount) then
    raise EArgumentNilException.Create('Conta não pode ser nula');
  if not AAccount.IsActive then
    raise EBusinessRuleException.Create('Conta inativa');
  if AAmount <= 0 then
    raise EValidationException.Create('Valor do saque deve ser positivo');
  if AAccount.Balance < AAmount then
    raise EInsufficientFundsException.CreateFmt(
      'Saldo insuficiente. Disponível: R$%.2f', [AAccount.Balance]);
  if AAccount.IsBlocked then
    raise EBusinessRuleException.Create('Conta bloqueada');

  AAccount.Balance := AAccount.Balance - AAmount;
  FRepository.Save(AAccount);
  Result := True;
end;
```

---

### 4. Replace Magic Numbers with Constants

**Detectar:** Literais numéricos ou de string sem nome explicativo no código.

**Antes:**
```pascal
if AProduct.Stock < 5 then NotifyLowStock(AProduct);
LInstallmentValue := AOrder.Total / 12;
if APassword.Length < 8 then raise ...;
if AUser.FailedLogins >= 3 then LockAccount(AUser);
LInterest := ADebt * 0.02;  // juros de mora
```

**Depois:**
```pascal
const
  LOW_STOCK_THRESHOLD       = 5;
  MAX_INSTALLMENTS          = 12;
  MIN_PASSWORD_LENGTH       = 8;
  MAX_FAILED_LOGIN_ATTEMPTS = 3;
  MONTHLY_INTEREST_RATE     = 0.02;

if AProduct.Stock < LOW_STOCK_THRESHOLD then NotifyLowStock(AProduct);
LInstallmentValue := AOrder.Total / MAX_INSTALLMENTS;
if APassword.Length < MIN_PASSWORD_LENGTH then raise ...;
if AUser.FailedLogins >= MAX_FAILED_LOGIN_ATTEMPTS then LockAccount(AUser);
LInterest := ADebt * MONTHLY_INTEREST_RATE;
```

---

### 5. Replace Conditional with Polymorphism (Strategy/State)

**Detectar:** `case` ou cadeia `if/else if` que verifica o tipo ou regime de um objeto.

**Antes:**
```pascal
function TShippingService.CalculateFreight(AOrder: TOrder): Currency;
begin
  case AOrder.ShippingMethod of
    smPAC:     Result := AOrder.Weight * 2.50 + 8.0;
    smSEDEX:   Result := AOrder.Weight * 4.80 + 15.0;
    smTransp:  Result := AOrder.Weight * 1.20;
    smRetirada:Result := 0;
  end;
end;
```

**Depois:**
```pascal
// Interface Strategy
IFreightStrategy = interface
  ['{GUID}']
  function Calculate(AWeightKg: Double): Currency;
  function GetCarrierName: string;
end;

// Implementações: uma por variação
TPACFreightStrategy = class(TInterfacedObject, IFreightStrategy)
  function Calculate(AWeightKg: Double): Currency;   // peso * 2.50 + 8.0
  function GetCarrierName: string;
end;

TSEDEXFreightStrategy = class(TInterfacedObject, IFreightStrategy)
  function Calculate(AWeightKg: Double): Currency;   // peso * 4.80 + 15.0
  function GetCarrierName: string;
end;

TTransportadoraFreightStrategy = class(TInterfacedObject, IFreightStrategy)
  function Calculate(AWeightKg: Double): Currency;   // peso * 1.20
  function GetCarrierName: string;
end;

TRetiradaFreightStrategy = class(TInterfacedObject, IFreightStrategy)
  function Calculate(AWeightKg: Double): Currency;   // sempre 0
  function GetCarrierName: string;
end;

// Context — não precisa mais do case
function TShippingService.CalculateFreight(AOrder: TOrder;
  AStrategy: IFreightStrategy): Currency;
begin
  Result := AStrategy.Calculate(AOrder.WeightKg);
end;
```

---

### 6. Introduce Parameter Object

**Detectar:** Método com > 4 parâmetros, especialmente se vários são opcionais.

**Antes:**
```pascal
function TReportService.GenerateSalesReport(
  AStartDate: TDate;
  AEndDate: TDate;
  const AProductCategory: string;
  const ASalesRepId: string;
  AMinAmount: Currency;
  AGroupByMonth: Boolean;
  AIncludeReturns: Boolean): TReportResult;
```

**Depois:**
```pascal
TSalesReportFilter = record
  StartDate: TDate;
  EndDate: TDate;
  ProductCategory: string;
  SalesRepId: string;
  MinAmount: Currency;
  GroupByMonth: Boolean;
  IncludeReturns: Boolean;
  // Construtor com defaults
  class function Default: TSalesReportFilter; static;
end;

class function TSalesReportFilter.Default: TSalesReportFilter;
begin
  Result.StartDate       := StartOfYear(Date);
  Result.EndDate         := Date;
  Result.ProductCategory := '';
  Result.SalesRepId      := '';
  Result.MinAmount       := 0;
  Result.GroupByMonth    := False;
  Result.IncludeReturns  := False;
end;

function TReportService.GenerateSalesReport(
  AFilter: TSalesReportFilter): TReportResult;
```

---

### 7. Remove `with` Statement

**Detectar:** Qualquer `with Objeto do begin...end` no código.

**Regra:** Nunca use `with`. Prefira variáveis locais ou qualificação explícita.

**Antes:**
```pascal
procedure TCustomerForm.LoadData;
begin
  with qryCustomers do
  begin
    Close;
    SQL.Text := 'SELECT * FROM customers WHERE id = :id';
    ParamByName('id').AsInteger := FCustomerId;
    Open;
    with FieldByName('address') do
    begin
      edtStreet.Text := AsString;
    end;
  end;
end;
```

**Depois:**
```pascal
procedure TCustomerForm.LoadData;
var LAddressField: TField;
begin
  qryCustomers.Close;
  qryCustomers.SQL.Text := 'SELECT * FROM customers WHERE id = :id';
  qryCustomers.ParamByName('id').AsInteger := FCustomerId;
  qryCustomers.Open;

  LAddressField := qryCustomers.FieldByName('address');
  edtStreet.Text := LAddressField.AsString;
end;
```

---

### 8. Extract Interface / Invert Dependency

**Detectar:** Service ou classe dependendo diretamente de classe concreta (não interface).

**Antes:**
```pascal
TOrderService = class
private
  FEmailSender: TSmtpEmailSender;      // classe concreta
  FRepository:  TFireDACOrderRepo;     // classe concreta
public
  constructor Create;  // instancia internamente — impossível testar
end;

constructor TOrderService.Create;
begin
  FEmailSender := TSmtpEmailSender.Create('smtp.server.com', 587);
  FRepository  := TFireDACOrderRepo.Create(GetDatabaseConnection);
end;
```

**Depois:**
```pascal
// 1. Extraia interfaces
IEmailSender = interface
  ['{GUID}']
  procedure Send(const ATo, ASubject, ABody: string);
end;

IOrderRepository = interface
  ['{GUID}']
  function FindById(AId: Integer): TOrder;
  procedure Save(AOrder: TOrder);
end;

// 2. Injete no construtor — testável e flexível
TOrderService = class
private
  FEmailSender: IEmailSender;
  FRepository:  IOrderRepository;
public
  constructor Create(ARepository: IOrderRepository; AEmailSender: IEmailSender);
end;

// 3. Em testes, injete fakes
TFakeEmailSender = class(TInterfacedObject, IEmailSender)
  FSentMessages: TStringList;
  procedure Send(const ATo, ASubject, ABody: string);
end;
```

---

### 9. Rename — Nomes Auto-Descritivos

**Detectar:** Variáveis como `x`, `tmp`, `data`, `flag`; métodos como `Proc1`, `DoIt`, `Handle`.

```pascal
// ❌ ANTES
var x, tmp: Integer;
    s: string;
    flag: Boolean;
procedure Handle(d: TData);
function Calc(v: Double): Double;

// ✅ DEPOIS
var LRetryCount, LMaxRetries: Integer;
    LCustomerFullName: string;
    LIsPaymentApproved: Boolean;
procedure ProcessCustomerOrder(AOrderData: TOrderData);
function CalculateShippingCost(AWeightKg: Double): Currency;
```

---

### 10. Inline Method — Método Desnecessariamente Delegado

**Detectar:** Método que apenas chama outro método, sem lógica adicional.

```pascal
// ❌ ANTES — delegação desnecessária
function TOrder.GetTotal: Currency;
begin
  Result := CalculateOrderTotal;  // só delega
end;

function TOrder.CalculateOrderTotal: Currency;
begin
  Result := FSubtotal + FTax - FDiscount;
end;

// ✅ DEPOIS — apenas um método com nome descritivo
function TOrder.GetTotal: Currency;
begin
  Result := FSubtotal + FTax - FDiscount;
end;
```

---

## 🔄 Processo de Refatoração Seguro

```
1. ENTENDER  → Leia e compreenda o código atual
2. TESTAR    → Escreva/execute testes que cobrem o comportamento atual
3. PEQUENO   → Faça uma refatoração por vez (não tudo de uma vez)
4. TESTAR    → Execute os testes novamente — devem continuar passando
5. COMMIT    → Commit atômico por refatoração (mensagem: "refactor: extract CalculateTax")
6. REPETIR   → Próxima refatoração
```

## ✅ Checklist Final

- [ ] Existe teste cobrindo o comportamento antes de refatorar?
- [ ] O comportamento observável permanece igual?
- [ ] Nenhum `with` foi introduzido?
- [ ] Nenhum número mágico sem nome?
- [ ] Método resultante tem ≤ 20 linhas?
- [ ] Nome do método extraído dispensa comentário?
- [ ] Dependências são agora via interface?
- [ ] Guard clauses substituem nesting profundo?
- [ ] Parâmetros em excesso foram agrupados em DTO/Record?
