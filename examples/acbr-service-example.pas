/// <summary>
/// Conceptual example showing how to isolate a native component (TACBrNFe)
/// in a service class, following the Adapter pattern and SOLID principles without coupling the UI.
/// </summary>
unit App.Infrastructure.Fiscal.NFe;

interface

uses
  System.SysUtils,
  System.Classes,
  // Simulating the ACBr unit
  ACBrNFe, pcnConversao, pcnConversaoNFe;

type
  // Domain Agnostic DTO (Does not know the ACBr VCL component)
  TInvoiceModel = record
    GuidId: string;
    InvoiceNumber: Integer;
    CustomerName: string;
    CustomerTaxId: string;
    TotalAmount: Double;
  end;

  TInvoiceResult = record
    Success: Boolean;
    ReceiptNumber: string;
    XmlPath: string;
    ErrorMessage: string;
  end;

  // Application Domain Interface
  INFeService = interface
    ['{D7A0AE5D-EEDA-4C72-AF20-9D727ED9C133}']
    function SendInvoice(const AInvoice: TInvoiceModel): TInvoiceResult;
  end;

  // External Configuration Interface (Injection)
  IAppConfig = interface
    function GetCertificateSerial: string;
    function GetEnvironment: Integer; // 1-Producao, 2-Homologacao
  end;

  // Implementation - Gateway to the Third Party Component (ACBr)
  TACBrNFeService = class(TInterfacedObject, INFeService)
  private
    FConfig: IAppConfig;
    // The Component exists in the Infra Layer, managed internally
    FAcbrNFe: TACBrNFe;
    
    procedure ApplySettings;
    procedure BuildXml(const AInvoice: TInvoiceModel);
  public
    constructor Create(AConfig: IAppConfig);
    destructor Destroy; override;
    
    function SendInvoice(const AInvoice: TInvoiceModel): TInvoiceResult;
  end;

implementation

{ TACBrNFeService }

constructor TACBrNFeService.Create(AConfig: IAppConfig);
begin
  inherited Create;
  FConfig := AConfig;
  
  // The component is generated independently of the visual Form/DataModule.
  // Allows use in REST APIs, Windows Services or Daemons.
  FAcbrNFe := TACBrNFe.Create(nil);
  ApplySettings;
end;

destructor TACBrNFeService.Destroy;
begin
  FAcbrNFe.Free;
  inherited;
end;

procedure TACBrNFeService.ApplySettings;
begin
  // Settings via clean code, read from trusted external source
  FAcbrNFe.Configuracoes.Certificados.NumeroSerie := FConfig.GetCertificateSerial;
  FAcbrNFe.Configuracoes.Geral.SSLLib := libWinCrypt;
  FAcbrNFe.Configuracoes.Geral.Salvar := True;
  
  if FConfig.GetEnvironment = 1 then
    FAcbrNFe.Configuracoes.WebServices.Ambiente := taProducao
  else
    FAcbrNFe.Configuracoes.WebServices.Ambiente := taHomologacao;
end;

procedure TACBrNFeService.BuildXml(const AInvoice: TInvoiceModel);
begin
  FAcbrNFe.NotasFiscais.Clear;
  
  with FAcbrNFe.NotasFiscais.Add.NFe do
  begin
    // DTO Domain Mapping -> ACBrNat Object
    Ide.natOp := 'MERCHANDISE SALE';
    Ide.nNF := AInvoice.InvoiceNumber;
    
    Dest.xNome := AInvoice.CustomerName;
    Dest.CNPJCPF := AInvoice.CustomerTaxId;
    
    Total.ICMSTot.vNF := AInvoice.TotalAmount;
    
    // etc... in a real environment this would be long
  end;
end;

function TACBrNFeService.SendInvoice(const AInvoice: TInvoiceModel): TInvoiceResult;
begin
  try
    BuildXml(AInvoice);
    
    // Batch 1 to send Signed and Valid
    FAcbrNFe.Enviar(1, False, True); 
    
    // Treating the response agnostically
    Result.Success := True;
    Result.ReceiptNumber := FAcbrNFe.WebServices.Retorno.Recibo;
    Result.XmlPath := FAcbrNFe.NotasFiscais.Items[0].NomeArq;
  
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := 'Error in ACBr emission:' + E.Message;
      // Ideally, you should have LoggerService here for auditing
    end;
  end;
end;

end.

