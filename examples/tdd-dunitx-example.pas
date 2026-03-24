unit MeuApp.Application.Order.ServiceTest;

// =========================================================================
// Exemplo canônico de TDD em Delphi com DUnitX
// Demonstração de Setup, Injeção de Dependências com Fakes (Mocks) locais
// e uso avançado de métricas de Asserção
// =========================================================================

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  {===================================================================
    SUT (System Under Test) e Dependências do Domínio
    Em um cenário real, estas declarações estariam nas units oficiais.
   ===================================================================}

  { Exceções mapeadas para uso com Assert.WillRaise }
  EOrderProcessingException = class(Exception);
  EInvalidCustomerException = class(EOrderProcessingException);
  EStockUnavailableException = class(EOrderProcessingException);

  { Entidade Simplificada }
  TOrder = class
  public
    Id: Integer;
    CustomerId: Integer;
    Total: Double;
  end;

  { Dependência de Infraestrutura Isolada (Abstract) }
  IInventoryService = interface
    ['{DA47FFEA-5887-4340-8FDB-8F9E4DEF5305}']
    function CheckStock(AOrderId: Integer): Boolean;
    procedure DecreaseStock(AOrderId: Integer);
  end;

  IOrderRepository = interface
    ['{849ACD9B-F42D-4E38-AEF1-44B9E90F4FC3}']
    procedure Save(AOrder: TOrder);
  end;

  { Classe que será efetivamente o Foco dos Testes (Target/SUT) }
  TOrderProcessor = class
  private
    FInventoryService: IInventoryService;
    FOrderRepository: IOrderRepository;
  public
    constructor Create(AInventory: IInventoryService; ARepository: IOrderRepository);
    procedure Process(AOrder: TOrder);
  end;

  {===================================================================
    Início do Ambiente de Teste DUnitX
   ===================================================================}
   
  [TestFixture]
  TOrderProcessorTests = class
  private
    FSut: TOrderProcessor;
    FOrder: TOrder;
    // Referências armazenadas para simulação comportamental
    FFakeInventory: IInventoryService;
    FFakeRepository: IOrderRepository;
  public
    [Setup]
    procedure Setup;
    
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Process_ValidOrderInStock_SavesAndDecreasesStock;

    [Test]
    procedure Process_ZeroCustomerId_RaisesInvalidCustomerException;

    [Test]
    procedure Process_OutOfStock_RaisesStockUnavailableException;
  end;

implementation

{===================================================================
  Implementação das Classes DUBLES DE TESTE (Fakes / Mocks)
  Criamos classes descartáveis apenas no escopo de implementação 
  desta Unit para fingir a Infraestrutura sem tocar o Banco
 ===================================================================}

type
  TFakeInventoryService = class(TInterfacedObject, IInventoryService)
  public
    // Variáveis de Controle (Spies) para Assert
    HasStock: Boolean;          // Permite mockar o resultado da infra
    DecreasedOrderId: Integer;  // Espia quem foi atualizado
    
    function CheckStock(AOrderId: Integer): Boolean;
    procedure DecreaseStock(AOrderId: Integer);
  end;

  TFakeOrderRepository = class(TInterfacedObject, IOrderRepository)
  public
    SavedCallCount: Integer;
    
    procedure Save(AOrder: TOrder);
  end;

{ TFakeInventoryService }

function TFakeInventoryService.CheckStock(AOrderId: Integer): Boolean;
begin
  Result := HasStock;
end;

procedure TFakeInventoryService.DecreaseStock(AOrderId: Integer);
begin
  DecreasedOrderId := AOrderId;
end;

{ TFakeOrderRepository }

procedure TFakeOrderRepository.Save(AOrder: TOrder);
begin
  Inc(SavedCallCount);
end;

{===================================================================
  Implementação da Classe de Negócio SUT
 ===================================================================}

constructor TOrderProcessor.Create(AInventory: IInventoryService; ARepository: IOrderRepository);
begin
  inherited Create;
  FInventoryService := AInventory;
  FOrderRepository := ARepository;
end;

procedure TOrderProcessor.Process(AOrder: TOrder);
begin
  // Guard Clauses (Testadas via WillRaise)
  if not Assigned(AOrder) then
    raise EArgumentNilException.Create('Order não pode ser vazia');
    
  if AOrder.CustomerId <= 0 then
    raise EInvalidCustomerException.Create('Cliente inválido');

  if not FInventoryService.CheckStock(AOrder.Id) then
    raise EStockUnavailableException.Create('Falta de Estoque para o Pedido');

  // Lógica de Persistência Core Interagindo com Mocks
  FOrderRepository.Save(AOrder);
  FInventoryService.DecreaseStock(AOrder.Id);
end;

{===================================================================
  Implementação dos Cenários de Teste DUnitX
 ===================================================================}

procedure TOrderProcessorTests.Setup;
begin
  // Arrange global para evitar repetição
  FFakeInventory := TFakeInventoryService.Create;
  FFakeRepository := TFakeOrderRepository.Create;
  
  // Injeta Mocks na Classe Real
  FSut := TOrderProcessor.Create(FFakeInventory, FFakeRepository);
  
  // Base Data Padrão
  FOrder := TOrder.Create;
  FOrder.Id := 999;
  FOrder.CustomerId := 50;
  FOrder.Total := 150.00;
end;

procedure TOrderProcessorTests.TearDown;
begin
  // Clean Up Manual para vazamentos em TObject
  // As interfaces de Fake são limpas nativamente por ARC
  FOrder.Free;
  FSut.Free; 
end;

procedure TOrderProcessorTests.Process_ValidOrderInStock_SavesAndDecreasesStock;
begin
  // Arrange Específico: Finge que há estoque
  (FFakeInventory as TFakeInventoryService).HasStock := True;

  // Act
  FSut.Process(FOrder);

  // Assert
  // Verifica se o Mock de Banco de Dados foi chamado precisamente 1x
  Assert.AreEqual(1, (FFakeRepository as TFakeOrderRepository).SavedCallCount, 'Repository Save não foi chamado 1 vez');
  // Verifica se o OrderId correto foi passado par diminuir o estoque
  Assert.AreEqual(999, (FFakeInventory as TFakeInventoryService).DecreasedOrderId, 'O Estoque não foi baixado para o Pedido 999');
end;

procedure TOrderProcessorTests.Process_ZeroCustomerId_RaisesInvalidCustomerException;
begin
  // Arrange
  FOrder.CustomerId := 0; // Configura o cenário de falha

  // Act & Assert Simultâneos usando Anonymous Method
  Assert.WillRaise(
    procedure
    begin
      FSut.Process(FOrder);
    end,
    EInvalidCustomerException, 'Não rejeitou pedido sem cliente válido'
  );
end;

procedure TOrderProcessorTests.Process_OutOfStock_RaisesStockUnavailableException;
begin
  // Arrange
  (FFakeInventory as TFakeInventoryService).HasStock := False; // Falta estoque

  // Act & Assert
  Assert.WillRaise(
    procedure
    begin
      FSut.Process(FOrder); // O Processor deve avaliar CheckStock() = False e disparar exceção
    end,
    EStockUnavailableException, 'Permitiu processar pedido sem estoque'
  );
end;

initialization
  // Registro Automático do Fixture no DUnitX Core
  TDUnitX.RegisterTestFixture(TOrderProcessorTests);

end.
