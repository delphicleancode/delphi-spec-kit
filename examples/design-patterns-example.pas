unit MeuApp.Examples.DesignPatterns;
{
  DESIGN PATTERNS EM DELPHI — Exemplo Prático Completo
  =====================================================
  Este arquivo demonstra os principais padrões GoF aplicados em Object Pascal,
  seguindo todas as conveções do Delphi AI Spec-Kit:
  - Prefixos: T (classes), I (interfaces), E (exceptions), F (fields), A (params), L (locals)
  - Memory management: try..finally para TObject sem ARC
  - Interfaces com TInterfacedObject para ARC automático
  - Constructor Injection (DIP)
  - Guard clauses
  - XMLDoc em português
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
// PADRÃO: STRATEGY
// Varia algoritmos de desconto sem mudar o contexto (TOrderCalculator).
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
  ///   Contexto que delega o cálculo de desconto para a strategy configurada.
  ///   Troque a strategy sem modificar este código (OCP).
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
// PADRÃO: OBSERVER
// Notifica múltiplos listeners sobre eventos de pedido.
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
  ///   Publisher de eventos de pedido. Notifica todos os listeners inscritos.
  ///   Listeners são referenciados por interface — sem gerenciamento manual de memória.
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
// PADRÃO: DECORATOR
// Adiciona comportamento ao logger sem herança.
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
// PADRÃO: BUILDER (Fluent Interface)
// Constrói queries SQL sem concatenação de strings.
// ============================================================================

type
  /// <summary>
  ///   Builder fluente para queries SQL parametrizadas.
  ///   Uso: TQueryBuilder.Create.Select('*').From('customers').Where('active=1').Build
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

    /// <summary>Finaliza e retorna a query SQL montada.</summary>
    /// <exception cref="EValidationException">Se SELECT ou FROM não foram configurados.</exception>
    function Build: string;
  end;

// ============================================================================
// PADRÃO: CHAIN OF RESPONSIBILITY
// Pipeline de validação de cliente.
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
// PADRÃO: FACTORY METHOD
// Cria exportadores de relatório por tipo.
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
  ///   Factory Method: cria o exportador correto baseado no formato solicitado.
  /// </summary>
  TReportExporterFactory = class
  public
    class function CreateExporter(const AFormat: string): IReportExporter;
  end;

implementation

// ============================================================================
// STRATEGY — Implementação
// ============================================================================

{ TNoDiscountStrategy }

function TNoDiscountStrategy.Apply(ABasePrice: Currency): Currency;
begin
  Result := ABasePrice;
end;

function TNoDiscountStrategy.GetDescription: string;
begin
  Result := 'Sem desconto';
end;

{ TPercentageDiscountStrategy }

constructor TPercentageDiscountStrategy.Create(APercentage: Double);
begin
  inherited Create;
  if (APercentage < 0) or (APercentage > 100) then
    raise EValidationException.Create('Percentual deve estar entre 0 e 100');
  FPercentage := APercentage;
end;

function TPercentageDiscountStrategy.Apply(ABasePrice: Currency): Currency;
begin
  Result := ABasePrice * (1 - FPercentage / 100);
end;

function TPercentageDiscountStrategy.GetDescription: string;
begin
  Result := Format('Desconto de %.0f%%', [FPercentage]);
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
  Result := 'Black Friday — 50% de desconto';
end;

{ TOrderCalculator }

constructor TOrderCalculator.Create(AStrategy: IDiscountStrategy);
begin
  inherited Create;
  if not Assigned(AStrategy) then
    raise EArgumentNilException.Create('AStrategy não pode ser nil');
  FStrategy := AStrategy;
end;

function TOrderCalculator.CalculateFinalPrice(ABasePrice: Currency): Currency;
begin
  if ABasePrice < 0 then
    raise EValidationException.Create('Preço base não pode ser negativo');
  Result := FStrategy.Apply(ABasePrice);
end;

// ============================================================================
// OBSERVER — Implementação
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
    raise EArgumentNilException.Create('AListener não pode ser nil');
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
  // Em produção: enviar e-mail de confirmação para AArgs.CustomerEmail
  Writeln(Format('[EMAIL] Pedido #%d confirmado — enviando para %s',
    [AArgs.OrderId, AArgs.CustomerEmail]));
end;

procedure TEmailNotificationListener.OnOrderCancelled(const AArgs: TOrderEventArgs);
begin
  Writeln(Format('[EMAIL] Pedido #%d cancelado — notificando %s',
    [AArgs.OrderId, AArgs.CustomerEmail]));
end;

{ TStockUpdateListener }

procedure TStockUpdateListener.OnOrderPlaced(const AArgs: TOrderEventArgs);
begin
  Writeln(Format('[ESTOQUE] Reservando itens do pedido #%d', [AArgs.OrderId]));
end;

procedure TStockUpdateListener.OnOrderCancelled(const AArgs: TOrderEventArgs);
begin
  Writeln(Format('[ESTOQUE] Liberando itens do pedido #%d cancelado', [AArgs.OrderId]));
end;

// ============================================================================
// DECORATOR — Implementação
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
    raise EArgumentNilException.Create('AInner logger não pode ser nil');
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
    raise EArgumentNilException.Create('AInner logger não pode ser nil');
  FInner := AInner;
  FMinLevel := AMinLevel.ToUpper;
end;

procedure TLevelFilterLogDecorator.Log(const ALevel, AMessage: string);
begin
  if ALevel.ToUpper >= FMinLevel then
    FInner.Log(ALevel, AMessage);
end;

// ============================================================================
// BUILDER — Implementação
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
    raise EValidationException.Create('Limit deve ser maior que zero');
  FLimitValue := ACount;
  Result := Self;
end;

procedure TQueryBuilder.ValidateBeforeBuild;
begin
  if FSelectClause.Trim.IsEmpty then
    raise EValidationException.Create('SELECT clause é obrigatória');
  if FFromClause.Trim.IsEmpty then
    raise EValidationException.Create('FROM clause é obrigatória');
end;

function TQueryBuilder.Build: string;
var
  LResult: TStringBuilder;
begin
  ValidateBeforeBuild;

  LResult := TStringBuilder.Create;
  try
    LResult.Append('SELECT ').Append(FSelectClause);
    LResult.Append(' FROM ').Append(FFromClause);

    if FWhereConditions.Count > 0 then
      LResult.Append(' WHERE ').Append(String.Join(' AND ', FWhereConditions.ToStringArray));

    if not FOrderByClause.IsEmpty then
      LResult.Append(' ORDER BY ').Append(FOrderByClause);

    if FLimitValue > 0 then
      LResult.Append(' LIMIT ').Append(FLimitValue.ToString);

    Result := LResult.ToString;
  finally
    LResult.Free;
  end;
end;

// ============================================================================
// CHAIN OF RESPONSIBILITY — Implementação
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
    Exit(TValidationResult.Fail('Nome é obrigatório'));
  if ADto.Name.Trim.Length < MIN_NAME_LENGTH then
    Exit(TValidationResult.Fail('Nome deve ter ao menos 3 caracteres'));
  Result := inherited Validate(ADto);
end;

{ TEmailValidator }

function TEmailValidator.Validate(const ADto: TCustomerDTO): TValidationResult;
begin
  if ADto.Email.Trim.IsEmpty then
    Exit(TValidationResult.Fail('E-mail é obrigatório'));
  if not ADto.Email.Contains('@') then
    Exit(TValidationResult.Fail('E-mail inválido'));
  Result := inherited Validate(ADto);
end;

{ TCpfValidator }

function TCpfValidator.Validate(const ADto: TCustomerDTO): TValidationResult;
const
  CPF_LENGTH = 11;
begin
  if ADto.Cpf.Trim.IsEmpty then
    Exit(TValidationResult.Fail('CPF é obrigatório'));
  if ADto.Cpf.Trim.Length <> CPF_LENGTH then
    Exit(TValidationResult.Fail('CPF deve ter 11 dígitos'));
  Result := inherited Validate(ADto);
end;

{ TAgeValidator }

function TAgeValidator.Validate(const ADto: TCustomerDTO): TValidationResult;
const
  MINIMUM_AGE = 18;
begin
  if ADto.Age < MINIMUM_AGE then
    Exit(TValidationResult.Fail(Format('Idade mínima: %d anos', [MINIMUM_AGE])));
  Result := inherited Validate(ADto);
end;

// ============================================================================
// FACTORY METHOD — Implementação
// ============================================================================

{ TPdfReportExporter }

procedure TPdfReportExporter.Export(const AData: TReportData; const AOutputPath: string);
begin
  // Em produção: geração real do PDF
  Writeln(Format('[PDF] Exportando "%s" para %s', [AData.Title, AOutputPath]));
end;

function TPdfReportExporter.GetExtension: string;
begin
  Result := '.pdf';
end;

{ TExcelReportExporter }

procedure TExcelReportExporter.Export(const AData: TReportData; const AOutputPath: string);
begin
  Writeln(Format('[EXCEL] Exportando "%s" para %s', [AData.Title, AOutputPath]));
end;

function TExcelReportExporter.GetExtension: string;
begin
  Result := '.xlsx';
end;

{ TCsvReportExporter }

procedure TCsvReportExporter.Export(const AData: TReportData; const AOutputPath: string);
begin
  Writeln(Format('[CSV] Exportando "%s" para %s', [AData.Title, AOutputPath]));
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
    raise EArgumentException.CreateFmt('Formato de exportação não suportado: "%s"', [AFormat]);
  end;
end;

// ============================================================================
// DEMONSTRAÇÃO DE USO — Como orquestrar os padrões
// ============================================================================

procedure DemoStrategyPattern;
var
  LCalc: TOrderCalculator;
  LPrice: Currency;
begin
  Writeln('=== STRATEGY PATTERN ===');

  // Sem desconto (padrão)
  LCalc := TOrderCalculator.Create(TNoDiscountStrategy.Create);
  try
    LPrice := LCalc.CalculateFinalPrice(100);
    Writeln(Format('Sem desconto: R$ %.2f', [LPrice]));   // 100.00

    // Troca a strategy em runtime — sem alterar TOrderCalculator
    LCalc.Strategy := TPercentageDiscountStrategy.Create(20);
    LPrice := LCalc.CalculateFinalPrice(100);
    Writeln(Format('20%% de desconto: R$ %.2f', [LPrice])); // 80.00

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
    // Inscreve listeners — interfaces gerenciadas por ARC
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

  // Composição: ConsoleLogger → Timestamp → LevelFilter
  LLogger :=
    TLevelFilterLogDecorator.Create(
      TTimestampLogDecorator.Create(
        TConsoleLogger.Create
      ),
      'WARN'  // Filtra DEBUG e INFO em produção
    );

  LLogger.Log('DEBUG', 'Iniciando conexão');   // filtrado, não aparece
  LLogger.Log('INFO',  'Serviço iniciado');     // filtrado
  LLogger.Log('WARN',  'Tentativa 2 de 3');    // aparece com timestamp
  LLogger.Log('ERROR', 'Falha na conexão');    // aparece com timestamp
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
  Writeln('=== CHAIN OF RESPONSIBILITY ===');

  // Monta a cadeia de validação
  LNameValidator  := TNameValidator.Create;
  LEmailValidator := TEmailValidator.Create;
  LCpfValidator   := TCpfValidator.Create;
  LAgeValidator   := TAgeValidator.Create;

  LNameValidator.SetNext(LEmailValidator);
  LEmailValidator.SetNext(LCpfValidator);
  LCpfValidator.SetNext(LAgeValidator);

  // Teste 1: dados inválidos
  LCustomer.Name  := 'Jo';           // muito curto
  LCustomer.Email := 'invalido';
  LCustomer.Cpf   := '12345678901';
  LCustomer.Age   := 25;

  LResult := LNameValidator.Validate(LCustomer);
  Writeln(Format('Válido: %s — %s', [BoolToStr(LResult.IsValid, True), LResult.ErrorMessage]));

  // Teste 2: dados válidos
  LCustomer.Name  := 'João Silva';
  LCustomer.Email := 'joao@email.com';
  LCustomer.Cpf   := '12345678901';
  LCustomer.Age   := 25;

  LResult := LNameValidator.Validate(LCustomer);
  Writeln(Format('Válido: %s — %s', [BoolToStr(LResult.IsValid, True), LResult.ErrorMessage]));
end;

procedure DemoFactoryMethodPattern;
var
  LExporter: IReportExporter;
  LData: TReportData;
begin
  Writeln('=== FACTORY METHOD ===');

  LData.Title := 'Relatório de Vendas';
  LData.Lines := ['Item 1', 'Item 2', 'Total: R$ 1.500,00'];

  // Cria o exportador correto sem conhecer a classe concreta
  LExporter := TReportExporterFactory.CreateExporter('pdf');
  LExporter.Export(LData, 'C:\relatorios\vendas' + LExporter.GetExtension);

  LExporter := TReportExporterFactory.CreateExporter('excel');
  LExporter.Export(LData, 'C:\relatorios\vendas' + LExporter.GetExtension);

  LExporter := TReportExporterFactory.CreateExporter('csv');
  LExporter.Export(LData, 'C:\relatorios\vendas' + LExporter.GetExtension);
end;

end.
