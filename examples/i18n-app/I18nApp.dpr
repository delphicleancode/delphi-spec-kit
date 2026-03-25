program I18nApp;

uses
  Vcl.Forms,
  I18nApp.Core.LanguageManager in 'src\Core\I18nApp.Core.LanguageManager.pas',
  I18nApp.Core.Resources in 'src\Core\I18nApp.Core.Resources.pas',
  I18nApp.Model.Connection in 'src\Model\I18nApp.Model.Connection.pas' {Connection: TDataModule},
  I18nApp.View.Main in 'src\View\I18nApp.View.Main.pas' {MainForm},
  I18nApp.View.Cliente in 'src\View\I18nApp.View.Cliente.pas' {ClienteForm},
  I18nApp.View.Produto in 'src\View\I18nApp.View.Produto.pas' {ProdutoForm},
  I18nApp.View.Venda in 'src\View\I18nApp.View.Venda.pas' {VendaForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TConnection, Connection);
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

