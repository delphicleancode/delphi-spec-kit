---
description: "Refatoração de código Delphi — técnicas para melhorar legibilidade, remover code smells e aplicar padrões sem alterar o comportamento"
globs: ["**/*.pas"]
alwaysApply: false
---

# Refatoração de Código Delphi — Cursor Rules

Use estas regras ao detectar ou corrigir code smells em Object Pascal. A refatoração **não muda o comportamento** — apenas melhora a estrutura interna.

---

## 🔴 Code Smells que Exigem Refatoração Imediata

| Code Smell | Sintoma | Técnica |
|---|---|---|
| Método longo | > 20 linhas | Extract Method |
| Classe inchada | > 300 linhas / múltiplas responsabilidades | Extract Class |
| Números mágicos | `if Age > 18` | Replace with Constant |
| Nesting profundo | `if...if...if` acima de 2 níveis | Replace with Guard Clauses |
| Código duplicado | Mesmo bloco em ≥ 2 lugares | Extract Method / Pull Up |
| Parâmetros em excesso | Método com > 4 parâmetros | Introduce Parameter Object |
| Lógica de UI misturada | Negócio em `OnClick` | Move Method to Service |
| `with` statement | `with DataSet do...` | Remove With |
| Variável temporária desnecessária | Usada apenas uma vez | Inline Temp |
| Condicional com tipo | `if Obj is TSubClass then` | Replace Conditional with Polymorphism |
| Cadeia de mensagens | `A.B.C.D.Execute` | Law of Demeter / Introduce Method |
| Comentário explicando o quê | O código deveria se auto-explicar | Rename + Extract Method |

---

## ✂️ Extract Method

Extraia blocos de código com propósito próprio em métodos nomeados.

```pascal
// ❌ ANTES — método longo sem separação de responsabilidades
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

  // Aplica desconto
  if AOrder.Customer.IsVip then
    LDiscount := LTotal * 0.10
  else if LTotal > 500 then
    LDiscount := LTotal * 0.05
  else
    LDiscount := 0;

  LTotal := LTotal - LDiscount;

  // Valida estoque
  for LItem in AOrder.Items do
  begin
    if LItem.Quantity > LItem.Product.StockQty then
      raise EInvalidOrderException.CreateFmt(
        'Estoque insuficiente: %s', [LItem.Product.Name]);
  end;

  AOrder.TotalAmount := LTotal;
  FRepository.Save(AOrder);
end;

// ✅ DEPOIS — cada responsabilidade em seu próprio método
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

Quando uma classe acumula responsabilidades demais, extraia as responsabilidades coesas.

```pascal
// ❌ ANTES — TCustomer com muita responsabilidade
TCustomer = class
  // Dados do cliente
  FName: string;
  FEmail: string;
  // Dados de endereço
  FStreet: string;
  FCity: string;
  FZipCode: string;
  FState: string;
  // Dados de contato
  FPhone: string;
  FCellPhone: string;
  // Lógica de validação de endereço
  function IsValidZipCode: Boolean;
  function GetFullAddress: string;
  // Lógica de validação de contato
  function HasValidPhone: Boolean;
end;

// ✅ DEPOIS — responsabilidades extraídas em classes coesas
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

TCustomer = class           // agora coesa — apenas dados do cliente
private
  FName: string;
  FAddress: TAddress;       // composição
  FContact: TContactInfo;   // composição
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

Elimina nesting eliminando casos especiais cedo.

```pascal
// ❌ ANTES — nesting dificulta leitura
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
          // lógica real aqui... enterrada em 4 níveis
          FGateway.Process(APayment);
        end;
      end;
    end;
  end;
end;

// ✅ DEPOIS — guard clauses: casos inválidos saem cedo
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

  // lógica real — sem nesting, direto ao ponto
  FGateway.Process(APayment);
end;
```

---

## 🔢 Replace Magic Numbers with Constants

```pascal
// ❌ ANTES
if AOrder.Items.Count > 10 then
  LDiscount := ATotal * 0.15;
if ACustomer.Age < 18 then
  raise EException.Create('...');
if APassword.Length < 8 then
  raise EException.Create('...');

// ✅ DEPOIS
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

Substitui cadeias de `if/case` por polimorfismo via interfaces.

```pascal
// ❌ ANTES — switch no tipo viola OCP
function CalculateTax(AOrder: TOrder): Currency;
begin
  case AOrder.TaxRegime of
    trSimples:        Result := AOrder.Total * 0.06;
    trLucroPresumido: Result := AOrder.Total * 0.15;
    trLucroReal:      Result := AOrder.Total * 0.25;
    trIsento:         Result := 0;
  end;
end;

// ✅ DEPOIS — polimorfismo via Strategy
ITaxStrategy = interface
  function Calculate(ATotal: Currency): Currency;
end;

TSimplesTax       = class(TInterfacedObject, ITaxStrategy) ... end;
TLucroPresumidoTax= class(TInterfacedObject, ITaxStrategy) ... end;
TLucroRealTax     = class(TInterfacedObject, ITaxStrategy) ... end;
TIsencaoTax       = class(TInterfacedObject, ITaxStrategy) ... end;

// Adicionar novo regime = nova classe, sem tocar no código existente (OCP)
function CalculateTax(AOrder: TOrder; ATaxStrategy: ITaxStrategy): Currency;
begin
  Result := ATaxStrategy.Calculate(AOrder.Total);
end;
```

---

## 📦 Introduce Parameter Object

Agrupa parâmetros relacionados em um Record ou classe.

```pascal
// ❌ ANTES — método com 6 parâmetros
function SearchCustomers(
  const AName: string;
  const ACity: string;
  const AState: string;
  AMinAge: Integer;
  AMaxAge: Integer;
  AOnlyActive: Boolean): TObjectList<TCustomer>;

// ✅ DEPOIS — parâmetros encapsulados em DTO
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

O `with` esconde o contexto e dificulta debug e refatoração.

```pascal
// ❌ ANTES — com `with`
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

// ✅ DEPOIS — explícito e legível
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

Quando uma classe concreta é usada diretamente, crie uma interface para desacoplar.

```pascal
// ❌ ANTES — acoplado à classe concreta
TOrderService = class
private
  FRepository: TFireDACOrderRepository; // acoplado!
public
  constructor Create(ARepository: TFireDACOrderRepository);
end;

// ✅ DEPOIS — depende da abstração
IOrderRepository = interface
  ['{GUID}']
  function FindById(AId: Integer): TOrder;
  procedure Save(AOrder: TOrder);
end;

TFireDACOrderRepository = class(TInterfacedObject, IOrderRepository) ... end;

TOrderService = class
private
  FRepository: IOrderRepository; // desacoplado!
public
  constructor Create(ARepository: IOrderRepository);
end;
// Agora testes podem injetar TFakeOrderRepository
```

---

## ✅ Checklist de Refatoração

Antes de cada refatoração, verifique:

- [ ] Existe teste cobrindo o comportamento atual? (se não, escreva antes)
- [ ] O comportamento observável permanece idêntico após a mudança?
- [ ] Método extraído tem nome auto-descritivo (sem precisar de comentário)?
- [ ] Nenhum `with` foi introduzido?
- [ ] Nenhum número mágico foi introduzido?
- [ ] A classe extraída tem uma única responsabilidade?
- [ ] Interfaces substituem dependências concretas?
- [ ] Guard clauses eliminam o nesting desnecessário?
