object ClienteForm: TClienteForm
  Left = 0
  Top = 0
  Caption = 'Cadastro de Clientes'
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
  PixelsPerInch = 96
  TextHeight = 13
  object lblId: TLabel
    Left = 24
    Top = 24
    Width = 11
    Height = 13
    Caption = 'ID'
  end
  object lblName: TLabel
    Left = 24
    Top = 72
    Width = 38
    Height = 13
    Caption = 'Nome *'
  end
  object lblEmail: TLabel
    Left = 24
    Top = 120
    Width = 39
    Height = 13
    Caption = 'E-mail *'
  end
  object lblCreated: TLabel
    Left = 24
    Top = 168
    Width = 47
    Height = 13
    Caption = 'Criado em'
  end
  object edtId: TEdit
    Left = 24
    Top = 43
    Width = 100
    Height = 21
    ReadOnly = True
    TabOrder = 0
  end
  object edtName: TEdit
    Left = 24
    Top = 91
    Width = 350
    Height = 21
    TabOrder = 1
  end
  object edtEmail: TEdit
    Left = 24
    Top = 139
    Width = 350
    Height = 21
    TabOrder = 2
  end
  object edtCreated: TEdit
    Left = 24
    Top = 187
    Width = 150
    Height = 21
    ReadOnly = True
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
      Caption = 'Novo'
      TabOrder = 0
    end
    object btnSave: TButton
      Left = 225
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Salvar'
      TabOrder = 1
    end
    object btnDelete: TButton
      Left = 306
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Excluir'
      TabOrder = 2
    end
  end
end
