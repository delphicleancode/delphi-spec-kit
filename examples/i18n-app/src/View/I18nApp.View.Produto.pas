unit I18nApp.View.Produto;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  I18nApp.Core.LanguageManager;

type
  TProdutoForm = class(TForm, TLanguageObserver)
    pnlBottom: TPanel;
    btnNew: TButton;
    btnSave: TButton;
    btnDelete: TButton;
    lblId: TLabel;
    edtId: TEdit;
    lblName: TLabel;
    edtName: TEdit;
    lblPrice: TLabel;
    edtPrice: TEdit;
    lblCreated: TLabel;
    edtCreated: TEdit;
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
  ProdutoForm: TProdutoForm;

implementation

{$R *.dfm}

procedure TProdutoForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  ProdutoForm := nil;
end;

procedure TProdutoForm.FormCreate(Sender: TObject);
begin
  TLanguageManager.GetInstance.RegisterObserver(Self);
  UpdateCaptions;
end;

procedure TProdutoForm.FormDestroy(Sender: TObject);
begin
  TLanguageManager.GetInstance.UnregisterObserver(Self);
end;

procedure TProdutoForm.FormShow(Sender: TObject);
begin
  // Example formatting
  edtPrice.Text := FloatToStrF(1234.56, ffCurrency, 10, 2);
end;

procedure TProdutoForm.LanguageChanged(const ALang: string);
begin
  UpdateCaptions;
  // Format based on culturally changed settings by LM
  edtPrice.Text := FloatToStrF(1234.56, ffCurrency, 10, 2);
end;

procedure TProdutoForm.UpdateCaptions;
var
  LLang: TLanguageManager;
begin
  LLang := TLanguageManager.GetInstance;
  
  if LLang.IsRTL then
    Self.BiDiMode := bdRightToLeft
  else
    Self.BiDiMode := bdLeftToRight;
    
  Caption := LLang.GetString('product.title');
  lblId.Caption := LLang.GetString('product.id');
  lblName.Caption := LLang.GetString('product.name');
  lblPrice.Caption := LLang.GetString('product.price');
  lblCreated.Caption := LLang.GetString('product.created');
  
  btnNew.Caption := LLang.GetString('product.btn.new');
  btnSave.Caption := LLang.GetString('product.btn.save');
  btnDelete.Caption := LLang.GetString('product.btn.delete');
end;

end.

