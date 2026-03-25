unit MeuApp.Presentation.Customer.IntrawebForm;

interface

uses
  System.SysUtils, System.Classes, IWAppForm, IWApplication, IWColor, IWTypes,
  Vcl.Controls, IWVCLBaseControl, IWBaseControl, IWBaseHTMLControl, IWControl,
  IWCompButton, IWCompEdit, IWCompLabel, ServerController, 
  MeuApp.Application.Customer.Service; // Injects clean business rules

type
  { Forma Intraweb - UI do WebApp (Stateful VCL-Like) }
  TIwFormCustomerEdit = class(TIWAppForm)
    iwRegMain: TIWRegion;
    iwLblTitle: TIWLabel;
    iwEdtName: TIWEdit;
    iwBtnSave: TIWButton;
    iwLblMessage: TIWLabel;
    // Optional: TTimer (Interruptions and auto rendering), Callbacks, etc.
    procedure iwBtnSaveAsyncClick(Sender: TObject; EventParams: TStringList);
    procedure IWAppFormCreate(Sender: TObject);
  private
    FCustomerService: ICustomerService;
  public
    // Rudimentary dependency injection if not using Container DI
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
  // Security check using clean ServerController / Session
  if UserSession.LoggedUserId <= 0 then
    WebApplication.Terminate('Access Denied or Invalid Session. Relog.');
    
  iwLblMessage.Caption := '';
end;

{ The click is captured asynchronously (Async), preventing a full page reload
  (classic Postback). Renders the interface locally (AJAX) }
procedure TIwFormCustomerEdit.iwBtnSaveAsyncClick(Sender: TObject; EventParams: TStringList);
begin
  if Trim(iwEdtName.Text) = '' then
  begin
    iwLblMessage.Font.Color := clWebRED;
    iwLblMessage.Caption := 'Fill in the customer''''s name correctly!';
    Exit;
  end;
  
  try
    // We invoke application logic not coupled to the Intraweb library
    FCustomerService.UpdateCustomerName(UserSession.LoggedUserId, iwEdtName.Text);
    
    // We show the user that it worked (Render via AJAX).
    iwLblMessage.Font.Color := clWebGREEN;
    iwLblMessage.Caption := 'Client successfully saved via AJAX!';
    
    WebApplication.ShowMessage('Action completed successfully!');
  except
    on E: Exception do
    begin
      iwLblMessage.Font.Color := clWebRED;
      iwLblMessage.Caption := 'An error occurred: ' + E.Message;
    end;
  end;
end;

end.

