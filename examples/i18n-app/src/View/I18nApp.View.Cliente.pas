unit I18nApp.View.Cliente;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  I18nApp.Core.LanguageManager;

type
  TClienteForm = class(TForm, TLanguageObserver)
    pnlBottom: TPanel;
    btnNew: TButton;
    btnSave: TButton;
    btnDelete: TButton;
    lblId: TLabel;
    edtId: TEdit;
    lblName: TLabel;
    edtName: TEdit;
    lblEmail: TLabel;
    edtEmail: TEdit;
    lblCreated: TLabel;
    edtCreated: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    procedure UpdateCaptions;
  protected
    procedure LanguageChanged(const ALang: string);
  public
    { Public declarations }
  end;

var
  ClienteForm: TClienteForm;

implementation

{$R *.dfm}

procedure TClienteForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  ClienteForm := nil;
end;

procedure TClienteForm.FormCreate(Sender: TObject);
begin
  TLanguageManager.GetInstance.RegisterObserver(Self);
  UpdateCaptions;
end;

procedure TClienteForm.FormDestroy(Sender: TObject);
begin
  TLanguageManager.GetInstance.UnregisterObserver(Self);
end;

procedure TClienteForm.LanguageChanged(const ALang: string);
begin
  UpdateCaptions;
end;

procedure TClienteForm.UpdateCaptions;
var
  LLang: TLanguageManager;
begin
  LLang := TLanguageManager.GetInstance;
  
  if LLang.IsRTL then
    Self.BiDiMode := bdRightToLeft
  else
    Self.BiDiMode := bdLeftToRight;
    
  Caption := LLang.GetString('client.title');
  lblId.Caption := LLang.GetString('client.id');
  lblName.Caption := LLang.GetString('client.name');
  lblEmail.Caption := LLang.GetString('client.email');
  lblCreated.Caption := LLang.GetString('client.created');
  
  btnNew.Caption := LLang.GetString('client.btn.new');
  btnSave.Caption := LLang.GetString('client.btn.save');
  btnDelete.Caption := LLang.GetString('client.btn.delete');
end;

end.

