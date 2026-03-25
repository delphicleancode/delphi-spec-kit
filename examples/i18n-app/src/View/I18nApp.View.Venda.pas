unit I18nApp.View.Venda;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  I18nApp.Core.LanguageManager;

type
  TVendaForm = class(TForm, TLanguageObserver)
    pnlBottom: TPanel;
    btnNew: TButton;
    btnSave: TButton;
    btnDelete: TButton;
    lblId: TLabel;
    edtId: TEdit;
    lblClientId: TLabel;
    edtClientId: TEdit;
    lblDate: TLabel;
    edtDate: TEdit;
    lblTotal: TLabel;
    edtTotal: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    procedure UpdateCaptions;
  protected
    procedure LanguageChanged(const ALang: string);
  public
    { Public declarations }
  end;

var
  VendaForm: TVendaForm;

implementation

{$R *.dfm}

procedure TVendaForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  VendaForm := nil;
end;

procedure TVendaForm.FormCreate(Sender: TObject);
begin
  TLanguageManager.GetInstance.RegisterObserver(Self);
  UpdateCaptions;
end;

procedure TVendaForm.FormDestroy(Sender: TObject);
begin
  TLanguageManager.GetInstance.UnregisterObserver(Self);
end;

procedure TVendaForm.FormShow(Sender: TObject);
begin
  edtDate.Text := DateToStr(Now);
  edtTotal.Text := FloatToStrF(890.50, ffCurrency, 10, 2);
end;

procedure TVendaForm.LanguageChanged(const ALang: string);
begin
  UpdateCaptions;
  edtDate.Text := DateToStr(Now);
  edtTotal.Text := FloatToStrF(890.50, ffCurrency, 10, 2);
end;

procedure TVendaForm.UpdateCaptions;
var
  LLang: TLanguageManager;
begin
  LLang := TLanguageManager.GetInstance;
  
  if LLang.IsRTL then
    Self.BiDiMode := bdRightToLeft
  else
    Self.BiDiMode := bdLeftToRight;
    
  Caption := LLang.GetString('sale.title');
  lblId.Caption := LLang.GetString('sale.id');
  lblClientId.Caption := LLang.GetString('sale.client_id');
  lblDate.Caption := LLang.GetString('sale.date');
  lblTotal.Caption := LLang.GetString('sale.total');
  
  btnNew.Caption := LLang.GetString('sale.btn.new');
  btnSave.Caption := LLang.GetString('sale.btn.save');
  btnDelete.Caption := LLang.GetString('sale.btn.delete');
end;

end.

