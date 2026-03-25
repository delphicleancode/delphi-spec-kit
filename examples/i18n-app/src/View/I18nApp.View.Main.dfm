object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'International Sales System'
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
      Caption = 'File'
      object mnuFileExit: TMenuItem
        Caption = 'To go out'
        ShortCut = 32883
        OnClick = mnuFileExitClick
      end
    end
    object mnuCadastros: TMenuItem
      Caption = 'Registrations'
      object mnuCadastrosClientes: TMenuItem
        Caption = 'Customers'
        OnClick = mnuCadastrosClientesClick
      end
      object mnuCadastrosProdutos: TMenuItem
        Caption = 'Products'
        OnClick = mnuCadastrosProdutosClick
      end
    end
    object mnuVendas: TMenuItem
      Caption = 'Sales'
      object mnuVendasNova: TMenuItem
        Caption = 'New Sale'
        OnClick = mnuVendasNovaClick
      end
    end
    object mnuConfig: TMenuItem
      Caption = 'Configure'#231#245'is'
      object mnuConfigIdioma: TMenuItem
        Caption = 'Language'
        object mnuIdiomaPTBR: TMenuItem
          Caption = 'Portugu'#234's (Brazil)'
          OnClick = mnuIdiomaPTBRClick
        end
        object mnuIdiomaENUS: TMenuItem
          Caption = 'English'#234's (USA)'
          OnClick = mnuIdiomaENUSClick
        end
      end
    end
    object mnuHelp: TMenuItem
      Caption = 'Ajuda'
      object mnuHelpAbout: TMenuItem
        Caption = 'On'
      end
    end
  end
end

