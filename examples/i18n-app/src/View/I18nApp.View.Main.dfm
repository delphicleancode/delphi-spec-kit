object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Sistema de Vendas Internacional'
  ClientHeight = 400
  ClientWidth = 600
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object StatusBar: TStatusBar
    Left = 0
    Top = 381
    Width = 600
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object MainMenu: TMainMenu
    Left = 32
    Top = 24
    object mnuFile: TMenuItem
      Caption = 'Arquivo'
      object mnuFileExit: TMenuItem
        Caption = 'Sair'
        ShortCut = 32883
        OnClick = mnuFileExitClick
      end
    end
    object mnuCadastros: TMenuItem
      Caption = 'Cadastros'
      object mnuCadastrosClientes: TMenuItem
        Caption = 'Clientes'
        OnClick = mnuCadastrosClientesClick
      end
      object mnuCadastrosProdutos: TMenuItem
        Caption = 'Produtos'
        OnClick = mnuCadastrosProdutosClick
      end
    end
    object mnuVendas: TMenuItem
      Caption = 'Vendas'
      object mnuVendasNova: TMenuItem
        Caption = 'Nova Venda'
        OnClick = mnuVendasNovaClick
      end
    end
    object mnuConfig: TMenuItem
      Caption = 'Configura'#231#245'es'
      object mnuConfigIdioma: TMenuItem
        Caption = 'Idioma'
        object mnuIdiomaPTBR: TMenuItem
          Caption = 'Portugu'#234's (Brasil)'
          OnClick = mnuIdiomaPTBRClick
        end
        object mnuIdiomaENUS: TMenuItem
          Caption = 'Ingl'#234's (EUA)'
          OnClick = mnuIdiomaENUSClick
        end
      end
    end
    object mnuHelp: TMenuItem
      Caption = 'Ajuda'
      object mnuHelpAbout: TMenuItem
        Caption = 'Sobre'
      end
    end
  end
end
