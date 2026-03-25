---
description: "Delphi code refactoring — techniques to improve readability, remove code smells and apply patterns without changing behavior"
globs: ["**/*.pas"]
alwaysApply: false
---

# Delphi Code Refactoring — Claude Rules

Use these rules when detecting or fixing code smells in Object Pascal. Refactoring **doesn't change behavior** — it just improves the internal structure.

---

## 🔴 Code Smells that Require Immediate Refactoring

| Code Smell | Symptom | Technique |
|---|---|---|
| Long method | > 20 lines | Extract Method |
| Bloated class | > 300 lines / multiple responsibilities | Extract Class |
| Magic numbers | `if Age > 18` | Replace with Constant |
| Deep Nesting | `if...if...if` above 2 levels | Replace with Guard Clauses |
| Duplicate code | Same block in ≥ 2 places | Extract Method / Pull Up |
| Excessive parameters | Method with > 4 parameters | Introduce Parameter Object |
| Mixed UI logic | Business in `OnClick` | Move Method to Service |
| `with` statement | `with DataSet do...` | Remove With |
| Unnecessary temporary variable | Used only once | Inline Temp |
| Conditional with type | `if Obj is TSubClass then` | Replace Conditional with Polymorphism |
| Message chain | `A.B.C.D.Execute` | Law of Demeter / Introduce Method |
| Comment explaining what | The code should explain itself | Rename + Extract Method |

---

## ✂️ Extract Method

Extract purposeful blocks of code into named methods.

```pascal
//❌ BEFORE — long method without separation of responsibilities
procedure TOrderService.PlaceOrder(AOrder: TOrder);
var
  LTotal: Currency;
  LDiscount: Currency;
  LItem: TOrderItem;
begin
  // Calcula total
  LTotal := 0;
  for LItem in AOrder.Items do
    LTotal := LTotal + (LItem.UnitPrice * LItem.Quantity);

  //Apply discount
  if AOrder.Customer.IsVip then
    LDiscount := LTotal * 0.10
  else if LTotal > 500 then
    LDiscount := LTotal * 0.05
  else
    LDiscount := 0;

  LTotal := LTotal - LDiscount;

  //Validates stock
  for LItem in AOrder.Items do
  begin
    if LItem.Quantity > LItem.Product.StockQty then
      raise EInvalidOrderException.CreateFmt(
        'Estoque insuficiente: %s', [LItem.Product.Name]);
  end;

  AOrder.TotalAmount := LTotal;
  FRepository.Save(AOrder);
end;

//✅ AFTER — each responsibility in its own method
procedure TOrderService.PlaceOrder(AOrder: TOrder);
begin
  ValidateStock(AOrder);
  AOrder.TotalAmount := CalculateTotalWithDiscount(AOrder);
  FRepository.Save(AOrder);
end;

function TOrderService.CalculateSubtotal(AOrder: TOrder): Currency;
var LItem: TOrderItem;
begin
  Result := 0;
  for LItem in AOrder.Items do
    Result := Result + (LItem.UnitPrice * LItem.Quantity);
end;

function TOrderService.CalculateDiscount(AOrder: TOrder; ASubtotal: Currency): Currency;
const
  VIP_DISCOUNT_RATE     = 0.10;
  BULK_DISCOUNT_RATE    = 0.05;
  BULK_DISCOUNT_MINIMUM = 500;
begin
  if AOrder.Customer.IsVip then
    Result := ASubtotal * VIP_DISCOUNT_RATE
  else if ASubtotal > BULK_DISCOUNT_MINIMUM then
    Result := ASubtotal * BULK_DISCOUNT_RATE
  else
    Result := 0;
end;

function TOrderService.CalculateTotalWithDiscount(AOrder: TOrder): Currency;
var LSubtotal: Currency;
begin
  LSubtotal := CalculateSubtotal(AOrder);
  Result := LSubtotal - CalculateDiscount(AOrder, LSubtotal);
end;

procedure TOrderService.ValidateStock(AOrder: TOrder);
var LItem: TOrderItem;
begin
  for LItem in AOrder.Items do
    if LItem.Quantity > LItem.Product.StockQty then
      raise EInvalidOrderException.CreateFmt(
        'Estoque insuficiente: %s', [LItem.Product.Name]);
end;
```

---

## 🏛️ Extract Class

When a class accumulates too many responsibilities, extract the cohesive responsibilities.

```pascal
//❌ BEFORE — TCustomer with a lot of responsibility
TCustomer = class
  //Customer data
  FName: string;
  FEmail: string;
  //Address data
  FStreet: string;
  FCity: string;
  FZipCode: string;
  FState: string;
  //Contact details
  FPhone: string;
  FCellPhone: string;
  //Address validation logic
  function IsValidZipCode: Boolean;
  function GetFullAddress: string;
  //Contact validation logic
  function HasValidPhone: Boolean;
end;

//✅ AFTER — responsibilities extracted into cohesive classes
TAddress = class
private
  FStreet: string;
  FCity: string;
  FZipCode: string;
  FState: string;
public
  function IsValid: Boolean;
  function GetFormatted: string;
  property Street: string read FStreet write FStreet;
  property City: string read FCity write FCity;
  property ZipCode: string read FZipCode write FZipCode;
  property State: string read FState write FState;
end;

TContactInfo = class
private
  FPhone: string;
  FCellPhone: string;
  FEmail: string;
public
  function HasValidPhone: Boolean;
  property Phone: string read FPhone write FPhone;
  property CellPhone: string read FCellPhone write FCellPhone;
  property Email: string read FEmail write FEmail;
end;

TCustomer = class           //now cohesive — just customer data
private
  FName: string;
  FAddress: TAddress;       //composition
  FContact: TContactInfo;   //composition
public
  constructor Create(const AName: string);
  destructor Destroy; override;
  property Name: string read FName write FName;
  property Address: TAddress read FAddress;
  property Contact: TContactInfo read FContact;
end;
```

---

## 🛡️ Replace Nested Conditionals with Guard Clauses

Eliminates nesting by eliminating special cases early.

```pascal
//❌ BEFORE — nesting makes reading difficult
procedure ProcessPayment(APayment: TPayment);
begin
  if Assigned(APayment) then
  begin
    if APayment.Amount > 0 then
    begin
      if not APayment.IsExpired then
      begin
        if APayment.Customer.IsActive then
        begin
          //real logic here...buried in 4 levels
          FGateway.Process(APayment);
        end;
      end;
    end;
  end;
end;

//✅ AFTER — guard clauses: invalid cases leave early
procedure ProcessPayment(APayment: TPayment);
begin
  if not Assigned(APayment) then
    raise EArgumentNilException.Create('APayment não pode ser nil');
  if APayment.Amount <= 0 then
    raise EValidationException.Create('Valor deve ser positivo');
  if APayment.IsExpired then
    raise EBusinessRuleException.Create('Pagamento expirado');
  if not APayment.Customer.IsActive then
    raise EBusinessRuleException.Create('Cliente inativo');

  //real logic — no nesting, straight to the point
  FGateway.Process(APayment);
end;
```

---

## 🔢 Replace Magic Numbers with Constants

```pascal
//❌ BEFORE
if AOrder.Items.Count > 10 then
  LDiscount := ATotal * 0.15;
if ACustomer.Age < 18 then
  raise EException.Create('...');
if APassword.Length < 8 then
  raise EException.Create('...');

//✅ AFTER
const
  MAX_ITEMS_WITHOUT_DISCOUNT = 10;
  BULK_DISCOUNT_RATE         = 0.15;
  MINIMUM_AGE                = 18;
  MINIMUM_PASSWORD_LENGTH    = 8;

if AOrder.Items.Count > MAX_ITEMS_WITHOUT_DISCOUNT then
  LDiscount := ATotal * BULK_DISCOUNT_RATE;
if ACustomer.Age < MINIMUM_AGE then
  raise EException.Create('...');
if APassword.Length < MINIMUM_PASSWORD_LENGTH then
  raise EException.Create('...');
```

---

## 🎭 Replace Conditional with Polymorphism

Replaces `if/case` strings with polymorphism via interfaces.

```pascal
//❌ BEFORE — non-viola OCP type switch
function CalculateTax(AOrder: TOrder): Currency;
begin
  case AOrder.TaxRegime of
    trSimples:        Result := AOrder.Total * 0.06;
    trLucroPresumido: Result := AOrder.Total * 0.15;
    trLucroReal:      Result := AOrder.Total * 0.25;
    trIsento:         Result := 0;
  end;
end;

//✅ AFTER — polymorphism via Strategy
ITaxStrategy = interface
  function Calculate(ATotal: Currency): Currency;
end;

TSimplesTax       = class(TInterfacedObject, ITaxStrategy) ... end;
TLucroPresumidoTax= class(TInterfacedObject, ITaxStrategy) ... end;
TLucroRealTax     = class(TInterfacedObject, ITaxStrategy) ... end;
TIsencaoTax       = class(TInterfacedObject, ITaxStrategy) ... end;

//Add new scheme = new class, without touching existing code (OCP)
function CalculateTax(AOrder: TOrder; ATaxStrategy: ITaxStrategy): Currency;
begin
  Result := ATaxStrategy.Calculate(AOrder.Total);
end;
```

---

## 📦 Introduce Parameter Object

Groups related parameters into a Record or class.

```pascal
//❌ BEFORE — method with 6 parameters
function SearchCustomers(
  const AName: string;
  const ACity: string;
  const AState: string;
  AMinAge: Integer;
  AMaxAge: Integer;
  AOnlyActive: Boolean): TObjectList<TCustomer>;

//✅ AFTER — parameters encapsulated in DTO
TCustomerSearchCriteria = record
  Name: string;
  City: string;
  State: string;
  MinAge: Integer;
  MaxAge: Integer;
  OnlyActive: Boolean;
  class function Default: TCustomerSearchCriteria; static;
end;

function SearchCustomers(ACriteria: TCustomerSearchCriteria): TObjectList<TCustomer>;
```

---

## 🔗 Remove `with` Statement

`with` hides the context and makes debugging and refactoring difficult.

```pascal
//❌ BEFORE — with `with`
procedure LoadCustomer;
begin
  with qryCustomers do
  begin
    SQL.Text := 'SELECT * FROM customers WHERE id = :id';
    ParamByName('id').AsInteger := FId;
    Open;
    edtName.Text := FieldByName('name').AsString;
    edtEmail.Text := FieldByName('email').AsString;
    Close;
  end;
end;

//✅ AFTER — explicit and readable
procedure LoadCustomer;
begin
  qryCustomers.SQL.Text := 'SELECT * FROM customers WHERE id = :id';
  qryCustomers.ParamByName('id').AsInteger := FId;
  qryCustomers.Open;
  try
    edtName.Text  := qryCustomers.FieldByName('name').AsString;
    edtEmail.Text := qryCustomers.FieldByName('email').AsString;
  finally
    qryCustomers.Close;
  end;
end;
```

---

## 🧩 Extract Interface

When a concrete class is used directly, create an interface to decouple it.

```pascal
//❌ BEFORE — coupled to the concrete class
TOrderService = class
private
  FRepository: TFireDACOrderRepository; // acoplado!
public
  constructor Create(ARepository: TFireDACOrderRepository);
end;

//✅ AFTER — depends on the abstraction
IOrderRepository = interface
  ['{GUID}']
  function FindById(AId: Integer): TOrder;
  procedure Save(AOrder: TOrder);
end;

TFireDACOrderRepository = class(TInterfacedObject, IOrderRepository) ... end;

TOrderService = class
private
  FRepository: IOrderRepository; //uncoupled!
public
  constructor Create(ARepository: IOrderRepository);
end;
//Now tests can inject TFakeOrderRepository
```

---

## ✅ Refactoring Checklist

Before each refactoring, check:

- [ ] Is there a test covering the current behavior? (if not, write first)
- [ ] Does the observable behavior remain identical after the change?
- [ ] Does the extracted method have a self-descriptive name (without needing a comment)?
- [ ] No `with` was introduced?
- [ ] No magic number was introduced?
- [ ] Does the extracted class have a single responsibility?
- [ ] Interfaces replace concrete dependencies?
- [ ] Do guard clauses eliminate unnecessary nesting?
