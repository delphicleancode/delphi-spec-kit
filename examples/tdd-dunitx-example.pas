unit MeuApp.Application.Order.ServiceTest;

// =========================================================================
// Canonical example of TDD in Delphi with DUnitX
// Setup Demonstration, Dependency Injection with local Mocks
// and advanced use of Assertion metrics
// =========================================================================

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  {===================================================================
    SUT (System Under Test) and Domain Dependencies
    In a real scenario, these declarations would be in their own units.
   ===================================================================}

  { Exceptions mapped for use with Assert.WillRaise }
  EOrderProcessingException = class(Exception);
  EInvalidCustomerException = class(EOrderProcessingException);
  EStockUnavailableException = class(EOrderProcessingException);

  { Simplified Entity }
  TOrder = class
  public
    Id: Integer;
    CustomerId: Integer;
    Total: Double;
  end;

  { Isolated Infrastructure Dependency (Abstract) }
  IInventoryService = interface
    ['{DA47FFEA-5887-4340-8FDB-8F9E4DEF5305}']
    function CheckStock(AOrderId: Integer): Boolean;
    procedure DecreaseStock(AOrderId: Integer);
  end;

  IOrderRepository = interface
    ['{849ACD9B-F42D-4E38-AEF1-44B9E90F4FC3}']
    procedure Save(AOrder: TOrder);
  end;

  { Class that will effectively be the Test Focus (Target/SUT) }
  TOrderProcessor = class
  private
    FInventoryService: IInventoryService;
    FOrderRepository: IOrderRepository;
  public
    constructor Create(AInventory: IInventoryService; ARepository: IOrderRepository);
    procedure Process(AOrder: TOrder);
  end;

  {===================================================================
    Start of DUnitX Test Environment
   ===================================================================}
   
  [TestFixture]
  TOrderProcessorTests = class
  private
    FSut: TOrderProcessor;
    FOrder: TOrder;
    // References stored for behavioral simulation
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
  Implementation of TEST DOUBLE Classes (Fakes / Mocks)
  Disposable classes scoped to this unit's implementation
  to simulate Infrastructure without touching the database.
 ===================================================================}

type
  TFakeInventoryService = class(TInterfacedObject, IInventoryService)
  public
    // Control Variables (Spies) for Assert
    HasStock: Boolean;          // Allows mocking the infrastructure result
    DecreasedOrderId: Integer;  // Spy: tracks which order ID was updated
    
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
  Implementation of the SUT Business Class
 ===================================================================}

constructor TOrderProcessor.Create(AInventory: IInventoryService; ARepository: IOrderRepository);
begin
  inherited Create;
  FInventoryService := AInventory;
  FOrderRepository := ARepository;
end;

procedure TOrderProcessor.Process(AOrder: TOrder);
begin
  // Guard Clauses (Tested via WillRaise)
  if not Assigned(AOrder) then
    raise EArgumentNilException.Create('Order cannot be empty');
    
  if AOrder.CustomerId <= 0 then
    raise EInvalidCustomerException.Create('Invalid client');

  if not FInventoryService.CheckStock(AOrder.Id) then
    raise EStockUnavailableException.Create('Lack of stock for order');

  // Core Persistence Logic Interacting with Mocks
  FOrderRepository.Save(AOrder);
  FInventoryService.DecreaseStock(AOrder.Id);
end;

{===================================================================
  Implementation of DUnitX Test Scenarios
 ===================================================================}

procedure TOrderProcessorTests.Setup;
begin
  // Arrange global to avoid repetition
  FFakeInventory := TFakeInventoryService.Create;
  FFakeRepository := TFakeOrderRepository.Create;
  
  // Inject Mocks into the Real Class
  FSut := TOrderProcessor.Create(FFakeInventory, FFakeRepository);
  
  // Base Date Standard
  FOrder := TOrder.Create;
  FOrder.Id := 999;
  FOrder.CustomerId := 50;
  FOrder.Total := 150.00;
end;

procedure TOrderProcessorTests.TearDown;
begin
  // Clean Up Manual for TObject leaks
  // Fake interfaces are cleaned up natively by ARC
  FOrder.Free;
  FSut.Free; 
end;

procedure TOrderProcessorTests.Process_ValidOrderInStock_SavesAndDecreasesStock;
begin
  // Specific Arrange: Pretend there is stock
  (FFakeInventory as TFakeInventoryService).HasStock := True;

  // Act
  FSut.Process(FOrder);

  //Assert
  // Checks if the Database Mock was called precisely 1x
  Assert.AreEqual(1, (FFakeRepository as TFakeOrderRepository).SavedCallCount, 'Repository Save was not called 1 time');
  // Checks if the correct OrderId was passed to reduce stock
  Assert.AreEqual(999, (FFakeInventory as TFakeInventoryService).DecreasedOrderId, 'Stock was not written off for Order 999');
end;

procedure TOrderProcessorTests.Process_ZeroCustomerId_RaisesInvalidCustomerException;
begin
  // Arrange
  FOrder.CustomerId := 0; // Sets up the failure scenario

  // Simultaneous Act & Assert using Anonymous Method
  Assert.WillRaise(
    procedure
    begin
      FSut.Process(FOrder);
    end,
    EInvalidCustomerException, 'Did not reject order without valid customer'
  );
end;

procedure TOrderProcessorTests.Process_OutOfStock_RaisesStockUnavailableException;
begin
  // Arrange
  (FFakeInventory as TFakeInventoryService).HasStock := False; // No stock available

  // Act & Assert
  Assert.WillRaise(
    procedure
    begin
      FSut.Process(FOrder); // The Processor must evaluate CheckStock() = False and raise exception
    end,
    EStockUnavailableException, 'Allowed to process orders without stock'
  );
end;

initialization
  // Automatic Fixture Registration in DUnitX Core
  TDUnitX.RegisterTestFixture(TOrderProcessorTests);

end.

