unit I18nApp.View.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ComCtrls,
  I18nApp.Core.LanguageManager;

type
  TMainForm = class(TForm, TLanguageObserver)
    MainMenu: TMainMenu;
    mnuFile: TMenuItem;
    mnuFileExit: TMenuItem;
    mnuCadastros: TMenuItem;
    mnuCadastrosClientes: TMenuItem;
    mnuCadastrosProdutos: TMenuItem;
    mnuVendas: TMenuItem;
    mnuVendasNova: TMenuItem;
    mnuConfig: TMenuItem;
    mnuConfigIdioma: TMenuItem;
    mnuIdiomaPTBR: TMenuItem;
    mnuIdiomaENUS: TMenuItem;
    mnuHelp: TMenuItem;
    mnuHelpAbout: TMenuItem;
    StatusBar: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure mnuIdiomaPTBRClick(Sender: TObject);
    procedure mnuIdiomaENUSClick(Sender: TObject);
    procedure mnuFileExitClick(Sender: TObject);
    procedure mnuCadastrosClientesClick(Sender: TObject);
    procedure mnuCadastrosProdutosClick(Sender: TObject);
    procedure mnuVendasNovaClick(Sender: TObject);
  private
    procedure UpdateCaptions;
  protected
    procedure LanguageChanged(const ALang: string);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  I18nApp.View.Cliente, I18nApp.View.Produto, I18nApp.View.Venda;

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  TLanguageManager.GetInstance.RegisterObserver(Self);
  UpdateCaptions;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TLanguageManager.GetInstance.UnregisterObserver(Self);
end;

procedure TMainForm.LanguageChanged(const ALang: string);
begin
  UpdateCaptions;
end;

procedure TMainForm.UpdateCaptions;
var
  LLang: TLanguageManager;
begin
  LLang := TLanguageManager.GetInstance;
  
  if LLang.IsRTL then
    Self.BiDiMode := bdRightToLeft
  else
    Self.BiDiMode := bdLeftToRight;

  Caption := LLang.GetString('app.title');
  
  mnuFile.Caption := LLang.GetString('menu.file');
  mnuFileExit.Caption := LLang.GetString('menu.file.exit');
  
  mnuCadastros.Caption := LLang.GetString('menu.cadastros');
  mnuCadastrosClientes.Caption := LLang.GetString('menu.cadastros.clientes');
  mnuCadastrosProdutos.Caption := LLang.GetString('menu.cadastros.produtos');
  
  mnuVendas.Caption := LLang.GetString('menu.sales');
  mnuVendasNova.Caption := LLang.GetString('menu.vendas.nova');
  
  mnuConfig.Caption := LLang.GetString('menu.config');
  mnuConfigIdioma.Caption := LLang.GetString('menu.config.language');
  mnuIdiomaPTBR.Caption := LLang.GetString('menu.config.idioma.ptbr');
  mnuIdiomaENUS.Caption := LLang.GetString('menu.config.language.enus');
  
  mnuHelp.Caption := LLang.GetString('menu.help');
  mnuHelpAbout.Caption := LLang.GetString('menu.help.about');
  
  StatusBar.SimpleText := LLang.GetString('status.lang_changed');
end;

procedure TMainForm.mnuIdiomaPTBRClick(Sender: TObject);
begin
  TLanguageManager.GetInstance.SetLanguage('pt-BR');
end;

procedure TMainForm.mnuIdiomaENUSClick(Sender: TObject);
begin
  TLanguageManager.GetInstance.SetLanguage('en-US');
end;

procedure TMainForm.mnuFileExitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.mnuCadastrosClientesClick(Sender: TObject);
begin
  if not Assigned(ClienteForm) then
    ClienteForm := TClienteForm.Create(Application);
  ClienteForm.Show;
end;

procedure TMainForm.mnuCadastrosProdutosClick(Sender: TObject);
begin
  if not Assigned(ProdutoForm) then
    ProdutoForm := TProdutoForm.Create(Application);
  ProdutoForm.Show;
end;

procedure TMainForm.mnuVendasNovaClick(Sender: TObject);
begin
  if not Assigned(VendaForm) then
    VendaForm := TVendaForm.Create(Application);
  VendaForm.Show;
end;

end.

