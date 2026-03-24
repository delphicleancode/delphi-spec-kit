object VendaForm: TVendaForm
  Left = 0
  Top = 0
  Caption = 'Registro de Vendas'
  ClientHeight = 300
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lblId: TLabel
    Left = 24
    Top = 24
    Width = 11
    Height = 13
    Caption = 'ID'
  end
  object lblClientId: TLabel
    Left = 24
    Top = 72
    Width = 63
    Height = 13
    Caption = 'ID Cliente *'
  end
  object lblDate: TLabel
    Left = 24
    Top = 120
    Width = 83
    Height = 13
    Caption = 'Data da Venda *'
  end
  object lblTotal: TLabel
    Left = 24
    Top = 168
    Width = 33
    Height = 13
    Caption = 'Total *'
  end
  object edtId: TEdit
    Left = 24
    Top = 43
    Width = 100
    Height = 21
    ReadOnly = True
    TabOrder = 0
  end
  object edtClientId: TEdit
    Left = 24
    Top = 91
    Width = 150
    Height = 21
    TabOrder = 1
  end
  object edtDate: TEdit
    Left = 24
    Top = 139
    Width = 150
    Height = 21
    TabOrder = 2
  end
  object edtTotal: TEdit
    Left = 24
    Top = 187
    Width = 150
    Height = 21
    TabOrder = 3
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 259
    Width = 400
    Height = 41
    Align = alBottom
    TabOrder = 4
    object btnNew: TButton
      Left = 144
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Nova'
      TabOrder = 0
    end
    object btnSave: TButton
      Left = 225
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Salvar Venda'
      TabOrder = 1
    end
    object btnDelete: TButton
      Left = 306
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Cancelar'
      TabOrder = 2
    end
  end
end
