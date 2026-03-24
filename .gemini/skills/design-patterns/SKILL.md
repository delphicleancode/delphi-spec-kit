---
name: "Design Patterns GoF — Delphi"
description: "Implementação dos 23 padrões GoF (Gang of Four) em Object Pascal / Delphi com interfaces, TInterfacedObject e princípios SOLID. Cobre Creational, Structural e Behavioral patterns."
---

# Design Patterns GoF em Delphi — Skill

Use esta skill quando o usuário solicitar implementação de padrões de projeto (Design Patterns) em Delphi. Aplique sempre junto com as convenções de nomenclatura (T/I/E/F/A/L) e gerenciamento de memória (try..finally).

## Quando Usar

- Criar `Factory`, `Abstract Factory` ou `Builder` para criação de objetos complexos
- Implementar `Strategy` para variar algoritmos (cálculo de frete, impostos, exportação)
- Usar `Observer` para notificações desacopladas (Domain Events)
- Aplicar `Command` para undo/redo, filas de tarefas ou auditoria
- Usar `Decorator` para adicionar responsabilidades sem herança
- Implementar `Adapter` para integração com sistemas legados
- Usar `Facade` para simplificar subsistemas complexos (ex: emissão NFe)
- Aplicar `Template Method` para algoritmos com variações (relatórios, exportações)
- Usar `State` para comportamento que muda conforme o estado do objeto
- Usar `Chain of Responsibility` para pipelines de validação ou processamento

---

## 🏗️ Padrões Criacionais (Creational)

### Singleton — Configuração Global

```pascal
unit MeuApp.Infra.AppConfig;

interface

type
  TAppConfig = class
  private
    class var FInstance: TAppConfig;
    FDatabaseUrl: string;
    FApiKey: string;
    constructor Create;
  public
    class function GetInstance: TAppConfig;
    class procedure ReleaseInstance;
    property DatabaseUrl: string read FDatabaseUrl write FDatabaseUrl;
    property ApiKey: string read FApiKey write FApiKey;
  end;

implementation

constructor TAppConfig.Create;
begin
  inherited Create;
  FDatabaseUrl := 'localhost:5432/myapp';
end;

class function TAppConfig.GetInstance: TAppConfig;
begin
  if not Assigned(FInstance) then
    FInstance := TAppConfig.Create;
  Result := FInstance;
end;

class procedure TAppConfig.ReleaseInstance;
begin
  FreeAndNil(FInstance);
end;

initialization
finalization
  TAppConfig.ReleaseInstance;
end.
```

### Factory Method — Criação com Polimorfismo

```pascal
unit MeuApp.Domain.Report.Factory;

interface

uses
  MeuApp.Domain.Report.Intf;

type
  IReportExporter = interface
    ['{A1B2-...}']
    procedure Export(const AData: TReportData; const AFilePath: string);
  end;

  // Factory Method — cada subclasse decide qual exportador criar
  TReportExporterFactory = class abstract
  public
    function CreateExporter: IReportExporter; virtual; abstract;
    // Template Method usando Factory Method
    procedure ExportReport(const AData: TReportData; const AFilePath: string);
  end;

  TPdfReportFactory = class(TReportExporterFactory)
    function CreateExporter: IReportExporter; override;
  end;

  TExcelReportFactory = class(TReportExporterFactory)
    function CreateExporter: IReportExporter; override;
  end;

implementation

procedure TReportExporterFactory.ExportReport(const AData: TReportData; const AFilePath: string);
var
  LExporter: IReportExporter;
begin
  LExporter := CreateExporter;
  LExporter.Export(AData, AFilePath);
end;
```

### Abstract Factory — Família de Objetos Relacionados

```pascal
unit MeuApp.Infra.UI.Factory;

interface

type
  IButton = interface ['{...}'] procedure Render; end;
  IInputField = interface ['{...}'] procedure Render; end;
  IDialog = interface ['{...}'] procedure Show(const AMsg: string); end;

  // Abstract Factory
  IUIComponentFactory = interface
    ['{B2C3-...}']
    function CreateButton(const ACaption: string): IButton;
    function CreateInputField(const APlaceholder: string): IInputField;
    function CreateDialog: IDialog;
  end;

  TVCLComponentFactory = class(TInterfacedObject, IUIComponentFactory)
    function CreateButton(const ACaption: string): IButton;
    function CreateInputField(const APlaceholder: string): IInputField;
    function CreateDialog: IDialog;
  end;

  TFMXComponentFactory = class(TInterfacedObject, IUIComponentFactory)
    function CreateButton(const ACaption: string): IButton;
    function CreateInputField(const APlaceholder: string): IInputField;
    function CreateDialog: IDialog;
  end;
```

### Builder — Construção Passo a Passo

```pascal
unit MeuApp.Infra.Query.Builder;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  /// <summary>
  ///   Builder para construção fluente de queries SQL parametrizadas.
  /// </summary>
  TQueryBuilder = class
  private
    FSelect: string;
    FFrom: string;
    FWheres: TStringList;
    FOrderBy: string;
    FLimit: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    function Select(const AFields: string): TQueryBuilder;
    function From(const ATable: string): TQueryBuilder;
    function Where(const ACondition: string): TQueryBuilder;
    function OrderBy(const AField: string; ADesc: Boolean = False): TQueryBuilder;
    function Limit(ACount: Integer): TQueryBuilder;
    function Build: string;
  end;

implementation

constructor TQueryBuilder.Create;
begin
  inherited Create;
  FWheres := TStringList.Create;
  FLimit := 0;
end;

destructor TQueryBuilder.Destroy;
begin
  FWheres.Free;
  inherited Destroy;
end;

function TQueryBuilder.Select(const AFields: string): TQueryBuilder;
begin
  FSelect := AFields;
  Result := Self;
end;

function TQueryBuilder.From(const ATable: string): TQueryBuilder;
begin
  FFrom := ATable;
  Result := Self;
end;

function TQueryBuilder.Where(const ACondition: string): TQueryBuilder;
begin
  FWheres.Add(ACondition);
  Result := Self;
end;

function TQueryBuilder.OrderBy(const AField: string; ADesc: Boolean): TQueryBuilder;
begin
  FOrderBy := AField;
  if ADesc then FOrderBy := FOrderBy + ' DESC';
  Result := Self;
end;

function TQueryBuilder.Limit(ACount: Integer): TQueryBuilder;
begin
  FLimit := ACount;
  Result := Self;
end;

function TQueryBuilder.Build: string;
var
  LSql: TStringBuilder;
begin
  LSql := TStringBuilder.Create;
  try
    LSql.Append('SELECT ').Append(FSelect);
    LSql.Append(' FROM ').Append(FFrom);
    if FWheres.Count > 0 then
      LSql.Append(' WHERE ').Append(String.Join(' AND ', FWheres.ToStringArray));
    if not FOrderBy.IsEmpty then
      LSql.Append(' ORDER BY ').Append(FOrderBy);
    if FLimit > 0 then
      LSql.Append(' LIMIT ').Append(FLimit.ToString);
    Result := LSql.ToString;
  finally
    LSql.Free;
  end;
end;
```

---

## 🔧 Padrões Estruturais (Structural)

### Adapter — Integração com Legado

```pascal
unit MeuApp.Infra.Payment.Adapter;

interface

type
  // Sistema legado — não pode ser alterado
  TLegacyPaymentGateway = class
    procedure ProcessarPagamento(AValor: Double; ACodigoCartao: string);
  end;

  // Interface esperada pelo domínio moderno
  IPaymentGateway = interface
    ['{C3D4-...}']
    procedure ProcessPayment(AAmount: Currency; const ACardToken: string);
  end;

  // Adapter: traduz a chamada nova para a legada
  TLegacyPaymentAdapter = class(TInterfacedObject, IPaymentGateway)
  private
    FLegacy: TLegacyPaymentGateway;
  public
    constructor Create(ALegacy: TLegacyPaymentGateway);
    destructor Destroy; override;
    procedure ProcessPayment(AAmount: Currency; const ACardToken: string);
  end;

implementation

constructor TLegacyPaymentAdapter.Create(ALegacy: TLegacyPaymentGateway);
begin
  inherited Create;
  if not Assigned(ALegacy) then
    raise EArgumentNilException.Create('ALegacy gateway cannot be nil');
  FLegacy := ALegacy;
end;

destructor TLegacyPaymentAdapter.Destroy;
begin
  FLegacy.Free;  // O adapter possui o legado
  inherited Destroy;
end;

procedure TLegacyPaymentAdapter.ProcessPayment(AAmount: Currency; const ACardToken: string);
begin
  FLegacy.ProcessarPagamento(AAmount, ACardToken);
end;
```

### Decorator — Extensão sem Herança

```pascal
unit MeuApp.Infra.Logger.Decorators;

interface

type
  ILogger = interface
    ['{D4E5-...}']
    procedure Log(const ALevel, AMessage: string);
  end;

  TConsoleLogger = class(TInterfacedObject, ILogger)
    procedure Log(const ALevel, AMessage: string);
  end;

  // Decorator: adiciona timestamp
  TTimestampDecorator = class(TInterfacedObject, ILogger)
  private
    FInner: ILogger;
  public
    constructor Create(AInner: ILogger);
    procedure Log(const ALevel, AMessage: string);
  end;

  // Decorator: filtra por nível mínimo
  TLevelFilterDecorator = class(TInterfacedObject, ILogger)
  private
    FInner: ILogger;
    FMinLevel: string;
  public
    constructor Create(AInner: ILogger; const AMinLevel: string);
    procedure Log(const ALevel, AMessage: string);
  end;

implementation

procedure TConsoleLogger.Log(const ALevel, AMessage: string);
begin
  Writeln(Format('[%s] %s', [ALevel, AMessage]));
end;

procedure TTimestampDecorator.Log(const ALevel, AMessage: string);
begin
  FInner.Log(ALevel, Format('%s | %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), AMessage]));
end;

procedure TLevelFilterDecorator.Log(const ALevel, AMessage: string);
begin
  if ALevel >= FMinLevel then // Filtra DEBUG em produção
    FInner.Log(ALevel, AMessage);
end;
```

### Facade — Simplificando Subsistemas

```pascal
unit MeuApp.Application.NFe.Facade;

interface

uses
  MeuApp.Domain.NFe.Entity,
  MeuApp.Domain.NFe.Repository.Intf;

type
  /// <summary>
  ///   Fachada que simplifica o processo completo de emissão de NF-e,
  ///   ocultando XML, assinatura digital e comunicação com SEFAZ.
  /// </summary>
  TNFeFacade = class
  private
    FXmlBuilder: TNFeXmlBuilder;
    FSigner: TDigitalSigner;
    FTransmitter: TSefazTransmitter;
    FRepository: INFeRepository;
    procedure GenerateXml(ANFe: TNFe);
    procedure SignXml(ANFe: TNFe);
    procedure TransmitToSefaz(ANFe: TNFe);
    procedure PersistResult(ANFe: TNFe);
  public
    constructor Create(ARepository: INFeRepository);
    destructor Destroy; override;
    /// <summary>Emite NF-e: gera XML → assina → transmite → persiste.</summary>
    procedure EmitirNFe(ANFe: TNFe);
    /// <summary>Cancela NF-e já emitida.</summary>
    procedure CancelarNFe(const AChaveAcesso: string; const AMotivo: string);
  end;
```

### Proxy — Controlo de Acesso

```pascal
unit MeuApp.Infra.Customer.Repository.Proxy;

interface

uses
  MeuApp.Domain.Customer.Entity,
  MeuApp.Domain.Customer.Repository.Intf,
  MeuApp.Domain.User.Entity;

type
  /// <summary>
  ///   Proxy de segurança que verifica permissões antes de delegar ao repositório real.
  /// </summary>
  TSecureCustomerRepositoryProxy = class(TInterfacedObject, ICustomerRepository)
  private
    FReal: ICustomerRepository;
    FCurrentUser: TUser;
    procedure CheckPermission(const AAction: string);
  public
    constructor Create(AReal: ICustomerRepository; ACurrentUser: TUser);
    function FindById(AId: Integer): TCustomer;
    function FindAll: TObjectList<TCustomer>;
    procedure Insert(ACustomer: TCustomer);
    procedure Update(ACustomer: TCustomer);
    procedure Delete(AId: Integer);
  end;

implementation

procedure TSecureCustomerRepositoryProxy.CheckPermission(const AAction: string);
begin
  if not FCurrentUser.HasPermission(AAction) then
    raise EAuthorizationException.CreateFmt(
      'User "%s" does not have permission: %s', [FCurrentUser.Login, AAction]);
end;

procedure TSecureCustomerRepositoryProxy.Delete(AId: Integer);
begin
  CheckPermission('CUSTOMER_DELETE');
  FReal.Delete(AId);
end;
```

---

## 🎭 Padrões Comportamentais (Behavioral)

### Strategy — Variação de Algoritmos

```pascal
unit MeuApp.Domain.Tax.Strategies;

interface

type
  ITaxStrategy = interface
    ['{E5F6-...}']
    function Calculate(ABaseValue: Currency): Currency;
    function GetDescription: string;
  end;

  TSimplesTaxStrategy = class(TInterfacedObject, ITaxStrategy)
  public
    function Calculate(ABaseValue: Currency): Currency;
    function GetDescription: string;
  end;

  TLucroPresumidoStrategy = class(TInterfacedObject, ITaxStrategy)
  public
    function Calculate(ABaseValue: Currency): Currency;
    function GetDescription: string;
  end;

  TIsencaoStrategy = class(TInterfacedObject, ITaxStrategy)
  public
    function Calculate(ABaseValue: Currency): Currency;
    function GetDescription: string;
  end;

implementation

const
  SIMPLES_RATE = 0.06;
  LUCRO_PRESUMIDO_RATE = 0.15;

function TSimplesTaxStrategy.Calculate(ABaseValue: Currency): Currency;
begin
  Result := ABaseValue * SIMPLES_RATE;
end;

function TSimplesTaxStrategy.GetDescription: string;
begin
  Result := 'Simples Nacional (6%)';
end;

function TIsencaoStrategy.Calculate(ABaseValue: Currency): Currency;
begin
  Result := 0;
end;

function TIsencaoStrategy.GetDescription: string;
begin
  Result := 'Isento de impostos';
end;
```

### Observer — Eventos de Domínio

```pascal
unit MeuApp.Domain.Order.Events;

interface

uses
  System.Generics.Collections,
  MeuApp.Domain.Order.Entity;

type
  IOrderEventObserver = interface
    ['{F6A7-...}']
    procedure OnOrderPlaced(AOrder: TOrder);
    procedure OnOrderCancelled(AOrder: TOrder);
  end;

  TOrderEventPublisher = class
  private
    FObservers: TList<IOrderEventObserver>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Subscribe(AObserver: IOrderEventObserver);
    procedure Unsubscribe(AObserver: IOrderEventObserver);
    procedure NotifyOrderPlaced(AOrder: TOrder);
    procedure NotifyOrderCancelled(AOrder: TOrder);
  end;

  // Observers concretos
  TEmailOrderNotifier = class(TInterfacedObject, IOrderEventObserver)
    procedure OnOrderPlaced(AOrder: TOrder);    // envia confirmação por e-mail
    procedure OnOrderCancelled(AOrder: TOrder); // envia aviso de cancelamento
  end;

  TStockReservationObserver = class(TInterfacedObject, IOrderEventObserver)
    procedure OnOrderPlaced(AOrder: TOrder);    // reserva estoque
    procedure OnOrderCancelled(AOrder: TOrder); // libera estoque
  end;

implementation

constructor TOrderEventPublisher.Create;
begin
  inherited Create;
  FObservers := TList<IOrderEventObserver>.Create;
end;

destructor TOrderEventPublisher.Destroy;
begin
  FObservers.Free;
  inherited Destroy;
end;

procedure TOrderEventPublisher.NotifyOrderPlaced(AOrder: TOrder);
var
  LObserver: IOrderEventObserver;
begin
  for LObserver in FObservers do
    LObserver.OnOrderPlaced(AOrder);
end;
```

### Command — Ações Encapsuláveis

```pascal
unit MeuApp.Application.Commands;

interface

uses
  MeuApp.Domain.Customer.Entity,
  MeuApp.Domain.Customer.Repository.Intf;

type
  ICommand = interface
    ['{A7B8-...}']
    procedure Execute;
    procedure Undo;
    function GetDescription: string;
  end;

  TCreateCustomerCommand = class(TInterfacedObject, ICommand)
  private
    FRepository: ICustomerRepository;
    FCustomerData: TCustomerDTO;
    FCreatedId: Integer;
  public
    constructor Create(ARepository: ICustomerRepository; AData: TCustomerDTO);
    procedure Execute;
    procedure Undo;
    function GetDescription: string;
  end;

  TDeleteCustomerCommand = class(TInterfacedObject, ICommand)
  private
    FRepository: ICustomerRepository;
    FCustomerId: Integer;
    FBackup: TCustomer;
  public
    constructor Create(ARepository: ICustomerRepository; ACustomerId: Integer);
    destructor Destroy; override;
    procedure Execute;
    procedure Undo;
    function GetDescription: string;
  end;

  // Histórico de Commands (para Undo/Redo)
  TCommandHistory = class
  private
    FHistory: TStack<ICommand>;
    FRedoStack: TStack<ICommand>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Execute(ACommand: ICommand);
    procedure Undo;
    procedure Redo;
    function CanUndo: Boolean;
    function CanRedo: Boolean;
  end;
```

### Template Method — Esqueleto de Algoritmo

```pascal
unit MeuApp.Application.Report.Generator;

interface

type
  TReportData = record
    Title: string;
    StartDate: TDate;
    EndDate: TDate;
  end;

  /// <summary>
  ///   Base abstrata que define o esqueleto do algoritmo de geração de relatório.
  ///   Subclasses implementam os passos variáveis.
  /// </summary>
  TReportGenerator = class abstract
  protected
    FData: TReportData;
    procedure LoadData; virtual; abstract;
    procedure ValidateData; virtual;           // hook com implementação padrão
    procedure ProcessData; virtual; abstract;
    procedure FormatOutput; virtual; abstract;
    procedure SaveOutput(const APath: string); virtual; abstract;
    procedure SendNotification; virtual;       // hook opcional — padrão: noop
  public
    // Template Method — não pode ser sobrescrito (final)
    procedure Generate(AData: TReportData; const ASavePath: string);
  end;

  TSalesReportGenerator = class(TReportGenerator)
  protected
    procedure LoadData; override;
    procedure ProcessData; override;
    procedure FormatOutput; override;
    procedure SaveOutput(const APath: string); override;
    procedure SendNotification; override;
  end;

implementation

procedure TReportGenerator.Generate(AData: TReportData; const ASavePath: string);
begin
  FData := AData;
  LoadData;
  ValidateData;
  ProcessData;
  FormatOutput;
  SaveOutput(ASavePath);
  SendNotification;
end;

procedure TReportGenerator.ValidateData;
begin
  if FData.Title.Trim.IsEmpty then
    raise EValidationException.Create('Report title cannot be empty');
  if FData.StartDate > FData.EndDate then
    raise EValidationException.Create('StartDate must be before EndDate');
end;

procedure TReportGenerator.SendNotification;
begin
  // Hook padrão: vazio. Subclasses podem sobrescrever para enviar e-mail etc.
end;
```

### Chain of Responsibility — Pipeline de Validação

```pascal
unit MeuApp.Application.Validation.Chain;

interface

uses
  MeuApp.Domain.Customer.Entity;

type
  TValidationResult = record
    IsValid: Boolean;
    ErrorMessage: string;
    class function Ok: TValidationResult; static;
    class function Fail(const AMessage: string): TValidationResult; static;
  end;

  IValidationHandler = interface
    ['{B8C9-...}']
    procedure SetNext(AHandler: IValidationHandler);
    function Validate(ACustomer: TCustomer): TValidationResult;
  end;

  TBaseValidationHandler = class(TInterfacedObject, IValidationHandler)
  private
    FNext: IValidationHandler;
  public
    procedure SetNext(AHandler: IValidationHandler);
    function Validate(ACustomer: TCustomer): TValidationResult; virtual;
  end;

  TNameValidationHandler = class(TBaseValidationHandler)
    function Validate(ACustomer: TCustomer): TValidationResult; override;
  end;

  TCpfValidationHandler = class(TBaseValidationHandler)
    function Validate(ACustomer: TCustomer): TValidationResult; override;
  end;

  TEmailValidationHandler = class(TBaseValidationHandler)
    function Validate(ACustomer: TCustomer): TValidationResult; override;
  end;

implementation

function TBaseValidationHandler.Validate(ACustomer: TCustomer): TValidationResult;
begin
  // Delega para o próximo handler se houver
  if Assigned(FNext) then
    Result := FNext.Validate(ACustomer)
  else
    Result := TValidationResult.Ok;
end;

function TNameValidationHandler.Validate(ACustomer: TCustomer): TValidationResult;
begin
  if ACustomer.Name.Trim.IsEmpty then
    Exit(TValidationResult.Fail('Nome é obrigatório'));
  if ACustomer.Name.Length < 3 then
    Exit(TValidationResult.Fail('Nome deve ter ao menos 3 caracteres'));
  Result := inherited Validate(ACustomer);  // continua a cadeia
end;
```

### State — Comportamento por Estado

```pascal
unit MeuApp.Domain.Order.States;

interface

uses
  MeuApp.Domain.Order.Entity;

type
  IOrderState = interface
    ['{C9D0-...}']
    procedure Confirm(AOrder: TOrder);
    procedure Ship(AOrder: TOrder);
    procedure Deliver(AOrder: TOrder);
    procedure Cancel(AOrder: TOrder);
    function GetStatusDescription: string;
  end;

  // Estado: Novo (a confirmar)
  TNewOrderState = class(TInterfacedObject, IOrderState)
  public
    procedure Confirm(AOrder: TOrder);
    procedure Ship(AOrder: TOrder);   // lança EInvalidOperationException
    procedure Deliver(AOrder: TOrder);
    procedure Cancel(AOrder: TOrder);
    function GetStatusDescription: string;
  end;

  // Estado: Confirmado (aguardando envio)
  TConfirmedOrderState = class(TInterfacedObject, IOrderState)
  public
    procedure Confirm(AOrder: TOrder);  // lança EInvalidOperationException
    procedure Ship(AOrder: TOrder);
    procedure Deliver(AOrder: TOrder);
    procedure Cancel(AOrder: TOrder);
    function GetStatusDescription: string;
  end;

  // Estado: Em trânsito
  TShippedOrderState = class(TInterfacedObject, IOrderState)
  public
    procedure Confirm(AOrder: TOrder);
    procedure Ship(AOrder: TOrder);
    procedure Deliver(AOrder: TOrder);
    procedure Cancel(AOrder: TOrder);  // requer chamada a transportadora
    function GetStatusDescription: string;
  end;

implementation

procedure TNewOrderState.Confirm(AOrder: TOrder);
begin
  AOrder.ConfirmedAt := Now;
  AOrder.SetState(TConfirmedOrderState.Create);  // transição
end;

procedure TNewOrderState.Ship(AOrder: TOrder);
begin
  raise EInvalidOperationException.Create('Pedido ainda não confirmado. Confirme antes de enviar.');
end;

function TNewOrderState.GetStatusDescription: string;
begin
  Result := 'Novo — aguardando confirmação';
end;
```

---

## 📌 Guia de Escolha do Padrão Correto

| Necessidade | Padrão |
|---|---|
| Criar objetos com variação de tipo | Factory Method / Abstract Factory |
| Criar objetos complexos passo a passo | Builder |
| Garantir instância única global | Singleton |
| Copiar objetos | Prototype |
| Adaptar interface incompatível | Adapter |
| Adicionar responsabilidades dinamicamente | Decorator |
| Simplificar sistema complexo | Facade |
| Controlar acesso a um objeto | Proxy |
| Compor objetos em estrutura de árvore | Composite |
| Variar algoritmo sem mudar o contexto | Strategy |
| Notificar múltiplos objetos sobre mudanças | Observer |
| Encapsular ações com undo/redo | Command |
| Algoritmo com variações | Template Method |
| Passar requisição por cadeia de handlers | Chain of Responsibility |
| Comportamento que muda com o estado | State |

## ✅ Checklist Final

- [ ] Toda dependência injetada via construtor (DIP)
- [ ] Toda implementação de interface usa `TInterfacedObject` (ARC)
- [ ] Nenhum `.Create` sem `try..finally` (exceto em interfaces ARC)
- [ ] Cada classe tem uma única responsabilidade (SRP)
- [ ] Testes DUnitX cobrem cada padrão com Fakes/Stubs
- [ ] XMLDoc em português nos métodos públicos
- [ ] Prefixos: `T` classe, `I` interface, `E` exception, `F` field, `A` param, `L` local
