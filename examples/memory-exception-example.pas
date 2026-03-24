unit MeuApp.Application.Billing.Service;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  { Exceções de Domínio Personalizadas }
  EBusinessRuleException = class(Exception);
  EInvalidCustomerException = class(EBusinessRuleException);
  EBillingException = class(Exception);

  { Exceções de Infraestrutura }
  EDatabaseException = class(Exception);

  { Entidade Simples }
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

  { Interface de Repositório (Desacoplamento puro e Auto-Memória via ARC) }
  IInvoiceRepository = interface
    ['{F8D58814-1921-438B-B03F-EF8E9DDBB45E}']
    procedure Save(AInvoice: TCustomerInvoice);
  end;

  { Dependência Injetada via ARC com Interface }
  IBillingProcessor = interface
    ['{B043BA16-AFBA-44C1-BF16-24835697D5CA}']
    procedure ProcessInvoice(ACustomerId: Integer; AAmount: Double);
    procedure ProcessBatch(AInvoices: TObjectList<TCustomerInvoice>);
  end;

  { Implementação Segura }
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
    raise EInvalidCustomerException.Create('Customer ID inválido ou não informado para Billing.');

  if FAmount <= 0 then
    raise EBusinessRuleException.Create('O valor do faturamento deve ser maior que zero.');
end;

{ TBillingProcessor }

constructor TBillingProcessor.Create(ARepository: IInvoiceRepository);
begin
  inherited Create;
  if not Assigned(ARepository) then
    raise EArgumentNilException.Create('O Repositório IInvoiceRepository é obrigatório.');
    
  FRepository := ARepository;
end;

procedure TBillingProcessor.ProcessInvoice(ACustomerId: Integer; AAmount: Double);
var
  LInvoice: TCustomerInvoice;
begin
  // CRIANDO OBJETO: 
  // Sempre aloque memória e imediatamente invoque try..finally
  LInvoice := TCustomerInvoice.Create(0, ACustomerId, AAmount);
  try
    try
      LInvoice.Validate;

      // Salvamento isolado protegido por Interface/Refcounting
      FRepository.Save(LInvoice);
      
    except
      // CAPTURA ESPECÍFICA DE NEGÓCIO
      on E: EBusinessRuleException do
      begin
        // Exceções de Domínio/Business Rule não precisam estourar aplicação se permitirem contorno
        raise EBillingException.CreateFmt('Billing falhou nas validações de domínio: %s', [E.Message]);
      end;

      // CAPTURA ESPECÍFICA GENÉRICA PARA LOG
      on E: Exception do
      begin
        // Ex: LogError(E.Message);
        raise; // Sempre relance os erros sistêmicos sem engolir pra preservar o App Stack!
      end;
    end;

  finally
    // Prevenção Perfeita contra Memory Leak:
    LInvoice.Free;
  end;
end;

procedure TBillingProcessor.ProcessBatch(AInvoices: TObjectList<TCustomerInvoice>);
var
  LInvoice: TCustomerInvoice;
begin
  // Como TObjectList já cuida da memória dependendo da flag OwnsObjects, 
  // aqui testamos a gestão sobre laços focados em try..except sem leak.
  if not Assigned(AInvoices) then Exit;
  
  for LInvoice in AInvoices do
  begin
    try
      ProcessInvoice(LInvoice.CustomerId, LInvoice.Amount);
    except
      on E: EBusinessRuleException do
      begin
        // Tolerância em Lote: apenas ignore o problemático, mas registre
        // LogWarning('Falha ao processar Batch Item. Skipping.');
        Continue;
      end;
      on E: Exception do
      begin
        // Erros graves quebram o batch
        raise;
      end;
    end;
  end;
end;

end.
