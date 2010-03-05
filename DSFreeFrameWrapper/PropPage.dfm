object PropertyPage: TPropertyPage
  Left = 1042
  Top = 72
  Caption = 'Property Editor'
  ClientHeight = 486
  ClientWidth = 395
  Color = clSilver
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object ScrollBox: TScrollBox
    Left = 0
    Top = 225
    Width = 395
    Height = 261
    VertScrollBar.Smooth = True
    VertScrollBar.Tracking = True
    Align = alClient
    BorderStyle = bsNone
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 395
    Height = 225
    Align = alTop
    BevelOuter = bvNone
    Color = clSilver
    TabOrder = 1
    object Label2: TLabel
      Left = 0
      Top = 0
      Width = 261
      Height = 13
      Caption = 'DSFreeFrameWrapper 0.2 written by http://joreg.ath.cx'
    end
    object Label3: TLabel
      Left = 0
      Top = 16
      Width = 393
      Height = 13
      Caption = 
        'Based on DirectShow BaseClass translations provided by http://ww' +
        'w.progdigy.com'
    end
    object Label4: TLabel
      Left = 0
      Top = 48
      Width = 369
      Height = 13
      Caption = 
        'Latest version and sourcecode available from http://freeframe.so' +
        'urceforge.net'
    end
    object Reset: TSpeedButton
      Left = 0
      Top = 207
      Width = 395
      Height = 17
      Caption = 'Reset to Defaults'
      Flat = True
      OnClick = ResetClick
    end
    object Label1: TLabel
      Left = 0
      Top = 32
      Width = 388
      Height = 13
      Caption = 
        'OpenFolderDialog taken from: http://members.chello.be/ws36637/ps' +
        'vdialogs.html'
    end
    object Button1: TButton
      Left = 0
      Top = 64
      Width = 75
      Height = 21
      Caption = 'Browse...'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Edit1: TEdit
      Left = 80
      Top = 64
      Width = 315
      Height = 21
      TabOrder = 1
      Text = 'Plugin Folder'
    end
    object ComboBox: TComboBox
      Left = 0
      Top = 88
      Width = 200
      Height = 21
      ItemHeight = 13
      TabOrder = 2
      OnChange = ComboBoxChange
    end
    object Description: TMemo
      Left = 0
      Top = 112
      Width = 395
      Height = 97
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 3
    end
    object BypassCheckbox: TCheckBox
      Left = 206
      Top = 91
      Width = 75
      Height = 17
      Caption = 'bypass'
      TabOrder = 4
      OnClick = BypassCheckboxClick
    end
  end
end
