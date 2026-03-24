---
description: "Design Patterns (GoF) em Delphi — Creational, Structural e Behavioral com Object Pascal"
globs: ["**/*.pas"]
alwaysApply: false
---

# Design Patterns GoF — Cursor Rules para Delphi

Use estas regras ao implementar padrões de projeto em Object Pascal / Delphi.

---

## 🏗️ Padrões Criacionais (Creational)

### Factory Method

```pascal
// Interface do produto
IButton = interface
  ['{GUID}']
  procedure Render;
end;

// Creator abstrato
TButtonFactory = class abstract
public
  function CreateButton: IButton; virtual; abstract;
end;

// Implementações concretas
TVCLButton = class(TInterfacedObject, IButton)
  procedure Render;
end;

TFMXButton = class(TInterfacedObject, IButton)
  procedure Render;
end;
```

### Abstract Factory

```pascal
// Interface da fábrica abstrata
IUIFactory = interface
  ['{GUID}']
  function CreateButton: IButton;
  function CreateDialog: IDialog;
end;

// Fábricas concretas por plataforma
TVCLFactory = class(TInterfacedObject, IUIFactory)
  function CreateButton: IButton;
  function CreateDialog: IDialog;
end;

TFMXFactory = class(TInterfacedObject, IUIFactory)
  function CreateButton: IButton;
  function CreateDialog: IDialog;
end;
```

### Singleton

```pascal
// Singleton thread-safe em Delphi
TAppConfig = class
private
  class var FInstance: TAppConfig;
  constructor Create;
public
  class function GetInstance: TAppConfig;
  class procedure ReleaseInstance;
  property DatabaseUrl: string read FDatabaseUrl write FDatabaseUrl;
end;

class function TAppConfig.GetInstance: TAppConfig;
begin
  if not Assigned(FInstance) then
    FInstance := TAppConfig.Create;
  Result := FInstance;
end;
```

> ⚠️ Para ambientes multi-thread use `TCriticalSection` ao criar a instância.

### Builder

```pascal
// Builder para construção de queries complexas
TQueryBuilder = class
private
  FSql: TStringBuilder;
  FParams: TDictionary<string, Variant>;
public
  constructor Create;
  destructor Destroy; override;
  function Select(const AFields: string): TQueryBuilder;
  function From(const ATable: string): TQueryBuilder;
  function Where(const ACondition: string): TQueryBuilder;
  function OrderBy(const AField: string): TQueryBuilder;
  function Build: string;
end;

// Uso fluente (Fluent Interface)
var LSql: string;
begin
  LSql := TQueryBuilder.Create
    .Select('id, name, email')
    .From('customers')
    .Where('active = 1')
    .OrderBy('name')
    .Build;
end;
```

> ⚠️ Always `try..finally Builder.Free` para instâncias builder criadas manualmente.

### Prototype

```pascal
// Clonable através de interface
IClonable = interface
  ['{GUID}']
  function Clone: TObject;
end;

TCustomer = class(TInterfacedObject, IClonable)
private
  FId: Integer;
  FName: string;
public
  function Clone: TObject;
end;

function TCustomer.Clone: TObject;
var LClone: TCustomer;
begin
  LClone := TCustomer.Create;
  LClone.FId := FId;
  LClone.FName := FName;
  Result := LClone;
end;
```

---

## 🔧 Padrões Estruturais (Structural)

### Adapter

```pascal
// Sistema legado com interface incompatível
TOldPaymentGateway = class
  procedure ProcessarPagamento(AValor: Double; ACartao: string);
end;

// Interface nova esperada pelo domínio
IPaymentGateway = interface
  ['{GUID}']
  procedure ProcessPayment(AAmount: Currency; const ACardToken: string);
end;

// Adapter fazendo a ponte
TPaymentGatewayAdapter = class(TInterfacedObject, IPaymentGateway)
private
  FOldGateway: TOldPaymentGateway;
public
  constructor Create(AOldGateway: TOldPaymentGateway);
  procedure ProcessPayment(AAmount: Currency; const ACardToken: string);
end;

procedure TPaymentGatewayAdapter.ProcessPayment(AAmount: Currency; const ACardToken: string);
begin
  FOldGateway.ProcessarPagamento(AAmount, ACardToken);
end;
```

### Decorator

```pascal
// Adiciona comportamento sem herança
ILogger = interface
  ['{GUID}']
  procedure Log(const AMessage: string);
end;

TConsoleLogger = class(TInterfacedObject, ILogger)
  procedure Log(const AMessage: string);
end;

// Decorator que adiciona timestamp
TTimestampLoggerDecorator = class(TInterfacedObject, ILogger)
private
  FInner: ILogger;
public
  constructor Create(AInner: ILogger);
  procedure Log(const AMessage: string);
end;

procedure TTimestampLoggerDecorator.Log(const AMessage: string);
begin
  FInner.Log(Format('[%s] %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), AMessage]));
end;
```

### Facade

```pascal
// Simplifica subsistema complexo de emissão de NF-e
TNFeFacade = class
private
  FXmlBuilder: TNFeXmlBuilder;
  FSigner: TDigitalSigner;
  FTransmitter: TSefazTransmitter;
  FStorage: INFeRepository;
public
  constructor Create(ARepo: INFeRepository);
  destructor Destroy; override;
  /// <summary>Emite NF-e ocultando toda a complexidade dos subsistemas.</summary>
  procedure EmitirNFe(ANFe: TNFe);
end;
```

### Proxy

```pascal
// Proxy de acesso controlado (autorização)
ICustomerRepository = interface ... end;

TSecureCustomerRepositoryProxy = class(TInterfacedObject, ICustomerRepository)
private
  FReal: ICustomerRepository;
  FCurrentUser: TUser;
  procedure CheckPermission(const AAction: string);
public
  constructor Create(AReal: ICustomerRepository; ACurrentUser: TUser);
  function FindById(AId: Integer): TCustomer;
  procedure Delete(AId: Integer);
end;

procedure TSecureCustomerRepositoryProxy.Delete(AId: Integer);
begin
  CheckPermission('DELETE_CUSTOMER');
  FReal.Delete(AId);
end;
```

### Composite

```pascal
// Componente folha ou contêiner — trata uniformemente
IMenuComponent = interface
  ['{GUID}']
  procedure Render;
  function GetLabel: string;
end;

TMenuItem = class(TInterfacedObject, IMenuComponent)   // Folha
  procedure Render;
  function GetLabel: string;
end;

TMenuGroup = class(TInterfacedObject, IMenuComponent)  // Contêiner
private
  FChildren: TList<IMenuComponent>;
public
  constructor Create;
  destructor Destroy; override;
  procedure Add(AItem: IMenuComponent);
  procedure Render;
  function GetLabel: string;
end;
```

---

## 🎭 Padrões Comportamentais (Behavioral)

### Strategy

```pascal
// Varia o algoritmo de cálculo sem mudar o contexto
ITaxStrategy = interface
  ['{GUID}']
  function Calculate(ABaseValue: Currency): Currency;
  function GetName: string;
end;

TSimplesTaxStrategy = class(TInterfacedObject, ITaxStrategy)
  function Calculate(ABaseValue: Currency): Currency;   // 6%
  function GetName: string;
end;

TLucroPresumidoStrategy = class(TInterfacedObject, ITaxStrategy)
  function Calculate(ABaseValue: Currency): Currency;   // 15%
  function GetName: string;
end;

// Contexto que usa a strategy
TOrderCalculator = class
private
  FTaxStrategy: ITaxStrategy;
public
  constructor Create(ATaxStrategy: ITaxStrategy);
  function CalculateTotal(AOrder: TOrder): Currency;
end;
```

### Observer

```pascal
// Notificação desacoplada de eventos de domínio
IOrderObserver = interface
  ['{GUID}']
  procedure OnOrderPlaced(AOrder: TOrder);
end;

TOrderEventPublisher = class
private
  FObservers: TList<IOrderObserver>;
public
  constructor Create;
  destructor Destroy; override;
  procedure Subscribe(AObserver: IOrderObserver);
  procedure Unsubscribe(AObserver: IOrderObserver);
  procedure Notify(AOrder: TOrder);
end;

// Observers concretos
TEmailNotifier = class(TInterfacedObject, IOrderObserver)
  procedure OnOrderPlaced(AOrder: TOrder);  // envia e-mail
end;

TStockUpdater = class(TInterfacedObject, IOrderObserver)
  procedure OnOrderPlaced(AOrder: TOrder);  // atualiza estoque
end;
```

### Command

```pascal
// Encapsula ações como objetos (undo/redo, filas)
ICommand = interface
  ['{GUID}']
  procedure Execute;
  procedure Undo;
end;

TCreateCustomerCommand = class(TInterfacedObject, ICommand)
private
  FRepository: ICustomerRepository;
  FCustomer: TCustomer;
  FCreatedId: Integer;
public
  constructor Create(ARepository: ICustomerRepository; ACustomer: TCustomer);
  procedure Execute;
  procedure Undo;
end;

// CommandBus / History
TCommandHistory = class
private
  FHistory: TStack<ICommand>;
public
  procedure Execute(ACommand: ICommand);
  procedure Undo;
end;
```

### Template Method

```pascal
// Define o esqueleto do algoritmo — subclasses preenchem as lacunas
TReportGenerator = class abstract
public
  // Template Method: define a sequência
  procedure GenerateReport(const AFilePath: string);
protected
  procedure LoadData; virtual; abstract;
  procedure ProcessData; virtual; abstract;
  procedure WriteOutput(const AFilePath: string); virtual; abstract;
  procedure SendNotification; virtual;  // hook com implementação padrão
end;

procedure TReportGenerator.GenerateReport(const AFilePath: string);
begin
  LoadData;
  ProcessData;
  WriteOutput(AFilePath);
  SendNotification;
end;

TSalesReportGenerator = class(TReportGenerator)
protected
  procedure LoadData; override;
  procedure ProcessData; override;
  procedure WriteOutput(const AFilePath: string); override;
end;
```

### Chain of Responsibility

```pascal
// Passa a requisição pela cadeia até alguém tratar
IRequestHandler = interface
  ['{GUID}']
  procedure SetNext(AHandler: IRequestHandler);
  function Handle(ARequest: TValidationRequest): Boolean;
end;

TBaseHandler = class(TInterfacedObject, IRequestHandler)
private
  FNext: IRequestHandler;
public
  procedure SetNext(AHandler: IRequestHandler);
  function Handle(ARequest: TValidationRequest): Boolean; virtual;
end;

TNameValidationHandler = class(TBaseHandler)
  function Handle(ARequest: TValidationRequest): Boolean; override;
end;

TCpfValidationHandler = class(TBaseHandler)
  function Handle(ARequest: TValidationRequest): Boolean; override;
end;

TAgeValidationHandler = class(TBaseHandler)
  function Handle(ARequest: TValidationRequest): Boolean; override;
end;
```

### State

```pascal
// Comportamento varia conforme o estado interno
IOrderState = interface
  ['{GUID}']
  procedure Confirm(AOrder: TOrder);
  procedure Ship(AOrder: TOrder);
  procedure Cancel(AOrder: TOrder);
  function GetStatus: string;
end;

TNewOrderState = class(TInterfacedObject, IOrderState) ... end;
TConfirmedOrderState = class(TInterfacedObject, IOrderState) ... end;
TShippedOrderState = class(TInterfacedObject, IOrderState) ... end;
TCancelledOrderState = class(TInterfacedObject, IOrderState) ... end;

TOrder = class
private
  FState: IOrderState;
public
  procedure Confirm;  // delega para FState.Confirm(Self)
  procedure Ship;
  procedure Cancel;
  procedure SetState(AState: IOrderState);
end;
```

---

## ✅ Checklist — Design Patterns em Delphi

- [ ] Definir interface antes de implementar (`I` prefix)
- [ ] Injetar dependências via construtor (nunca hardcoded)
- [ ] Usar `TInterfacedObject` em todas as implementações de interface
- [ ] Padrões Creational criam objetos — não misturar com lógica de negócio
- [ ] Padrões Behavioral preferem interfaces a herança
- [ ] Evitar `with`, variáveis globais e acoplamento direto em qualquer padrão
- [ ] Cobrir cada padrão com testes DUnitX usando Fakes
