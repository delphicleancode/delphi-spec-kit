/// <summary>
///   Exemplo conceitual mostrando como isolar um componente nativo (TACBrNFe)
///   em uma classe de serviço, seguindo o padrão Adapter e princípios SOLID sem acoplar a UI.
/// </summary>
unit App.Infrastructure.Fiscal.NFe;

interface

uses
  System.SysUtils,
  System.Classes,
  // Simulando a unit do ACBr
  ACBrNFe, pcnConversao, pcnConversaoNFe;

type
  // DTO Agnóstico do Domínio (Não conhece o componente VCL do ACBr)
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

  // Interface do Domínio Application
  INFeService = interface
    ['{D7A0AE5D-EEDA-4C72-AF20-9D727ED9C133}']
    function SendInvoice(const AInvoice: TInvoiceModel): TInvoiceResult;
  end;

  // Interface de Configuração Externa (Injection)
  IAppConfig = interface
    function GetCertificateSerial: string;
    function GetEnvironment: Integer; // 1-Producao, 2-Homologacao
  end;

  // Implementação - Gateway para o Componente de Terceiro (ACBr)
  TACBrNFeService = class(TInterfacedObject, INFeService)
  private
    FConfig: IAppConfig;
    // O Componente existe na Camada Infra, gerenciado internamente
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
  
  // O componente é gerado de forma desvinculada de Form/DataModule visual.
  // Permite uso em APIs REST, Windows Services ou Daemons.
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
  // Configurações via código limpo, lidas de fonte externa confiável
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
    // Mapeamento Domínio DTO -> Objeto ACBrNat
    Ide.natOp := 'VENDA DE MERCADORIA';
    Ide.nNF := AInvoice.InvoiceNumber;
    
    Dest.xNome := AInvoice.CustomerName;
    Dest.CNPJCPF := AInvoice.CustomerTaxId;
    
    Total.ICMSTot.vNF := AInvoice.TotalAmount;
    
    // etc... em ambiente real isso seria longo
  end;
end;

function TACBrNFeService.SendInvoice(const AInvoice: TInvoiceModel): TInvoiceResult;
begin
  try
    BuildXml(AInvoice);
    
    // Lote 1 para enviar Assinado e Valido
    FAcbrNFe.Enviar(1, False, True); 
    
    // Tratando a resposta agnósticamente
    Result.Success := True;
    Result.ReceiptNumber := FAcbrNFe.WebServices.Retorno.Recibo;
    Result.XmlPath := FAcbrNFe.NotasFiscais.Items[0].NomeArq;
  
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := 'Erro na emissão ACBr: ' + E.Message;
      // Ideal é possuir LoggerService aqui para auditoria
    end;
  end;
end;

end.
