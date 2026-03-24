unit MeuApp.Presentation.Customer.IntrawebForm;

interface

uses
  System.SysUtils, System.Classes, IWAppForm, IWApplication, IWColor, IWTypes,
  Vcl.Controls, IWVCLBaseControl, IWBaseControl, IWBaseHTMLControl, IWControl,
  IWCompButton, IWCompEdit, IWCompLabel, ServerController, 
  MeuApp.Application.Customer.Service; // Injeção das regras de negócio limpas

type
  { Forma Intraweb - UI do WebApp (Stateful VCL-Like) }
  TIwFormCustomerEdit = class(TIWAppForm)
    iwRegMain: TIWRegion;
    iwLblTitle: TIWLabel;
    iwEdtName: TIWEdit;
    iwBtnSave: TIWButton;
    iwLblMessage: TIWLabel;
    // Opcional: TTimer (Interrupções e auto renderizações), Callbacks, etc.
    procedure iwBtnSaveAsyncClick(Sender: TObject; EventParams: TStringList);
    procedure IWAppFormCreate(Sender: TObject);
  private
    FCustomerService: ICustomerService;
  public
    // Injeção de dependência rudimentar se não usar Container DI
    constructor Create(AOwner: TComponent; ACustomerService: ICustomerService); reintroduce; overload;
  end;

implementation

{$R *.dfm}

{ TIwFormCustomerEdit }

constructor TIwFormCustomerEdit.Create(AOwner: TComponent; ACustomerService: ICustomerService);
begin
  inherited Create(AOwner);
  FCustomerService := ACustomerService;
end;

procedure TIwFormCustomerEdit.IWAppFormCreate(Sender: TObject);
begin
  // Verificação de segurança utilizando ServerController de ambiente limpo / Sessão
  if UserSession.LoggedUserId <= 0 then
    WebApplication.Terminate('Acesso Negado ou Sessão Inválida. Relogue.');
    
  iwLblMessage.Caption := '';
end;

{ O clique é capturado de forma Assíncrona (Async), prevenindo o "reload" 
  da página completa (Postback clássico). Renderiza a interface localmente (AJAX) }
procedure TIwFormCustomerEdit.iwBtnSaveAsyncClick(Sender: TObject; EventParams: TStringList);
begin
  if Trim(iwEdtName.Text) = '' then
  begin
    iwLblMessage.Font.Color := clWebRED;
    iwLblMessage.Caption := 'Preencha o nome do cliente corretamente!';
    Exit;
  end;
  
  try
    // Invocamos a lógica de aplicação não acoplada à biblioteca Intraweb
    FCustomerService.UpdateCustomerName(UserSession.LoggedUserId, iwEdtName.Text);
    
    // Mostramos ao usuário que deu certo (Render via AJAX).
    iwLblMessage.Font.Color := clWebGREEN;
    iwLblMessage.Caption := 'Cliente salvo com sucesso via AJAX!';
    
    WebApplication.ShowMessage('Ação concluída com sucesso!');
  except
    on E: Exception do
    begin
      iwLblMessage.Font.Color := clWebRED;
      iwLblMessage.Caption := 'Houve um erro: ' + E.Message;
    end;
  end;
end;

end.
