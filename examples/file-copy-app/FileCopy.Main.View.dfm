object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'File Copy - Copiar Arquivos'
  ClientHeight = 480
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 640
    Height = 120
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblSource: TLabel
      Left = 16
      Top = 12
      Width = 90
      Height = 15
      Caption = 'Pasta de Origem:'
    end
    object lblDest: TLabel
      Left = 16
      Top = 64
      Width = 96
      Height = 15
      Caption = 'Pasta de Destino:'
    end
    object edtSource: TEdit
      Left = 16
      Top = 30
      Width = 520
      Height = 23
      ReadOnly = True
      TabOrder = 0
    end
    object btnSelectSource: TButton
      Left = 544
      Top = 29
      Width = 80
      Height = 25
      Caption = 'Selecionar...'
      TabOrder = 1
      OnClick = btnSelectSourceClick
    end
    object edtDest: TEdit
      Left = 16
      Top = 82
      Width = 520
      Height = 23
      ReadOnly = True
      TabOrder = 2
    end
    object btnSelectDest: TButton
      Left = 544
      Top = 81
      Width = 80
      Height = 25
      Caption = 'Selecionar...'
      TabOrder = 3
      OnClick = btnSelectDestClick
    end
  end
  object pnlCenter: TPanel
    Left = 0
    Top = 120
    Width = 640
    Height = 280
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lblFiles: TLabel
      Left = 16
      Top = 4
      Width = 140
      Height = 15
      Caption = 'Arquivos na pasta de origem:'
    end
    object lbxFiles: TListBox
      Left = 16
      Top = 22
      Width = 608
      Height = 250
      Anchors = [akLeft, akTop, akRight, akBottom]
      TabOrder = 0
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 400
    Width = 640
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnCopy: TButton
      Left = 16
      Top = 8
      Width = 120
      Height = 36
      Caption = 'Copiar Arquivos'
      TabOrder = 0
      OnClick = btnCopyClick
    end
    object prgCopy: TProgressBar
      Left = 152
      Top = 16
      Width = 472
      Height = 20
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
    end
  end
  object stbMain: TStatusBar
    Left = 0
    Top = 456
    Width = 640
    Height = 24
    Panels = <
      item
        Width = 640
      end>
  end
  object dlgSelectFolder: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = [fdoPickFolders, fdoPathMustExist]
    Title = 'Selecionar Pasta'
    Left = 296
    Top = 232
  end
end
