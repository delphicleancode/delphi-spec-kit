unit MeuApp.Application.Billing.Service;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  { Domain Custom Exceptions }
  EBusinessRuleException = class(Exception);
  EInvalidCustomerException = class(EBusinessRuleException);
  EBillingException = class(Exception);

  { Infrastructure Exceptions }
  EDatabaseException = class(Exception);

  { Simple Entity }
  TCustomerInvoice = class
  private
    FId: Integer;
    FAmount: Double;
    FCustomerId: Integer;
  public
    constructor Create(AId, ACustomerId: Integer; AAmount: Double);
    procedure Validate;
    property Id: Integer read FId;
    property Amount: Double read FAmount;
    property CustomerId: Integer read FCustomerId;
  end;

  { Repository Interface (Pure Decoupling and Auto-Memory via ARC) }
  IInvoiceRepository = interface
    ['{F8D58814-1921-438B-B03F-EF8E9DDBB45E}']
    procedure Save(AInvoice: TCustomerInvoice);
  end;

  { Injected Dependency via ARC with Interface }
  IBillingProcessor = interface
    ['{B043BA16-AFBA-44C1-BF16-24835697D5CA}']
    procedure ProcessInvoice(ACustomerId: Integer; AAmount: Double);
    procedure ProcessBatch(AInvoices: TObjectList<TCustomerInvoice>);
  end;

  { Safe Implementation }
  TBillingProcessor = class(TInterfacedObject, IBillingProcessor)
  private
    FRepository: IInvoiceRepository;
  public
    constructor Create(ARepository: IInvoiceRepository);
    
    procedure ProcessInvoice(ACustomerId: Integer; AAmount: Double);
    procedure ProcessBatch(AInvoices: TObjectList<TCustomerInvoice>);
  end;

implementation

{ TCustomerInvoice }

constructor TCustomerInvoice.Create(AId, ACustomerId: Integer; AAmount: Double);
begin
  inherited Create;
  FId := AId;
  FCustomerId := ACustomerId;
  FAmount := AAmount;
end;

procedure TCustomerInvoice.Validate;
begin
  if FCustomerId <= 0 then
    raise EInvalidCustomerException.Create('Invalid or not informed Customer ID for Billing.');

  if FAmount <= 0 then
    raise EBusinessRuleException.Create('The billing amount must be greater than zero.');
end;

{ TBillingProcessor }

constructor TBillingProcessor.Create(ARepository: IInvoiceRepository);
begin
  inherited Create;
  if not Assigned(ARepository) then
    raise EArgumentNilException.Create('The IInvoiceRepository Repository is required.');
    
  FRepository := ARepository;
end;

procedure TBillingProcessor.ProcessInvoice(ACustomerId: Integer; AAmount: Double);
var
  LInvoice: TCustomerInvoice;
begin
  { CREATING OBJECT:
    Always allocate memory and immediately invoke try..finally }
  LInvoice := TCustomerInvoice.Create(0, ACustomerId, AAmount);
  try
    try
      LInvoice.Validate;

      { Isolated save protected by Interface/Refcounting }
      FRepository.Save(LInvoice);
      
    except
      { BUSINESS SPECIFIC CAPTURE }
      on E: EBusinessRuleException do
      begin
        { Domain/Business Rule Exceptions do not need to overflow application if they allow bypass }
        raise EBillingException.CreateFmt('Billing failed domain validations: %s', [E.Message]);
      end;

      { GENERIC SPECIFIC CAPTURE FOR LOG }
      on E: Exception do
      begin
        { Ex: LogError(E.Message); }
        raise; { Always re-raise system errors without swallowing to preserve the App Stack! }
      end;
    end;

  finally
    { Perfect Memory Leak Prevention: }
    LInvoice.Free;
  end;
end;

procedure TBillingProcessor.ProcessBatch(AInvoices: TObjectList<TCustomerInvoice>);
var
  LInvoice: TCustomerInvoice;
begin
  { As TObjectList already takes care of memory depending on the OwnsObjects flag,
    here we test the management of loops focused on try..except without leaks. }
  if not Assigned(AInvoices) then Exit;
  
  for LInvoice in AInvoices do
  begin
    try
      ProcessInvoice(LInvoice.CustomerId, LInvoice.Amount);
    except
      on E: EBusinessRuleException do
      begin
        { Batch Tolerance: just ignore the problematic one, but record }
        { LogWarning('Failed to process Batch Item. Skipping.'); }
        Continue;
      end;
      on E: Exception do
      begin
        { Serious errors break the batch }
        raise;
      end;
    end;
  end;
end;

end.
