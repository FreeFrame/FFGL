{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
{ DSFreeFrameWrapper                                               }
{       a filter for using freeframe (http://www.freeframe.org)    }
{       plugins in a directshow graph                              }
{                                                                  }
{                                                                  }
{ author: joreg@joreg.ath.cx                                       }
{         http://joreg.ath.cx                                      }
{                                                                  }
{ based on: FreeFrame Delphi interface definitions by              }
{           Russell Blakeborough - boblists@brightonart.org        }
{                                                                  }
{           directshow baseclass translations for delphi           }
{           provided by http://www.progdigy.com                    }
{           (need to be included in the searchpath if you          }
{           want to compile this filter)                           }
{                                                                  }
{                                                                  }
{ The contents of this file are used with permission, subject to   }
{ the Mozilla Public License Version 1.1 (the "License"); you may  }
{ not use this file except in compliance with the License. You may }
{ obtain a copy of the License at                                  }
{ http://www.mozilla.org/MPL/MPL-1.1.html                          }
{                                                                  }
{ Software distributed under the License is distributed on an      }
{ "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or   }
{ implied. See the License for the specific language governing     }
{ rights and limitations under the License.                        }
{                                                                  }
{ change log see: DSFreeFrameWrapper.dpr                           }
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}


unit PropPage;

interface

uses Windows, SysUtils, Messages, Classes, Graphics, Controls, StdCtrls,
  ExtCtrls, Forms, BaseClass, ComObj, StdVcl, AxCtrls, DirectShow9, dsutil,
  Dialogs, ComCtrls, psvFolderDialog, Buttons;

type
  TPropertyPage = class(TFormPropertyPage)
    ScrollBox: TScrollBox;
    Panel1: TPanel;
    Button1: TButton;
    Edit1: TEdit;
    ComboBox: TComboBox;
    Description: TMemo;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Reset: TSpeedButton;
    Label1: TLabel;
    BypassCheckbox: TCheckBox;
    procedure Button1Click(Sender: TObject);
    procedure BypassCheckboxClick(Sender: TObject);
    procedure ComboBoxChange(Sender: TObject);
    procedure TrackBarChange(Sender: TObject);
    procedure ResetClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FLabels: array of TLabel;
    FTrackBars: array of TTrackBar;
    FPluginPath: string;
    FOpenFolderDialog: TpsvBrowseFolderDialog;
    procedure GetPlugins;
  public
    pin: IPin;
    Enum: TEnumMediaType;
    function OnConnect(Unknown: IUnknown): HRESULT; override;
    function OnDisconnect: HRESULT; override;
    function OnApplyChanges: HRESULT; override;
  end;

const
    CLSID_FreeFrameWrapperPropertyPage : TGUID = '{E159C0E9-6BE6-41E9-BF43-93C10D15146F}';

implementation
uses main;

{$R *.DFM}
var
  FFPlugin: IFFPlugin;
  FFParameters: IFFParameters;
  FFPropertySaves: IFFPropertySaves;

function TPropertyPage.OnConnect(Unknown: IUnKnown): HRESULT;
begin
  FFPlugin := Unknown as IFFPlugIn;
  FFParameters := Unknown as IFFParameters;
  FFPropertySaves := Unknown as IFFPropertySaves;

  result := NOERROR;
end;

function TPropertyPage.OnDisconnect: HRESULT;
begin
  result := NOERROR;
end;

function TPropertyPage.OnApplyChanges: HRESULT;
begin
  FFPropertySaves.SetPluginPath(FPluginPath);
  FFPropertySaves.SetCurrentPlugin(ComboBox.Items[ComboBox.ItemIndex]);
  result := NOERROR;
end;

procedure TPropertyPage.Button1Click(Sender: TObject);
begin
  if FOpenFolderDialog.Execute then
  begin
    FPluginPath := FOpenFolderDialog.FolderName + '\';
    Edit1.Text := FPluginPath;
    GetPlugins;
  end;
end;

procedure TPropertyPage.BypassCheckboxClick(Sender: TObject);
begin
  FFPlugin.SetEnabled(not BypassCheckbox.Checked);
end;

procedure TPropertyPage.GetPlugins;
  function checkValid(name: string):boolean;
  const
    functionName = 'plugMain';
  var
    h: thandle;
    proc: pointer;
  begin
    result:=false;
    if not (compareText(copy(name, Length(name) - 3, 4), '.dll') = 0) then exit;
    h := LoadLibrary(PChar(name));
    if h <> 0 then begin //its a dll!
      Proc := GetProcAddress(h, functionName);
      if Proc <> nil then
        result := true;
      FreeLibrary(h);
    end;
  end;
var
  sr: TSearchRec;
begin
  ComboBox.Items.Clear;

  if FindFirst(FPluginPath + '*.dll', faAnyFile, sr) = 0 then
  begin
    if checkValid(FPluginPath + sr.name) then
      ComboBox.Items.Add(sr.name);
    while FindNext(sr) = 0 do
      if checkValid(FPluginPath + sr.name) then
        ComboBox.Items.add(sr.name);
    FindClose(sr);
  end;

  if ComboBox.Items.Count > 0 then
  begin
    ComboBox.ItemIndex:=0;
    ComboBoxChange(nil);
    FFPlugin.SetEnabled(not BypassCheckbox.Checked);
  end;
end;


procedure TPropertyPage.ComboBoxChange(Sender: TObject);
var
  tmpWord: DWord;
  tmpStr, tmpStr2: String;
  tmpSingle: Single;
  i: Integer;
begin
  if ComboBox.itemindex<0 then
    exit;

  FFPlugIn.SetPlugin(FPluginPath + ComboBox.Items[ComboBox.ItemIndex]);

  Description.Lines.Clear;

  try
    FFPlugIn.GetPluginName(tmpStr);
    Description.Lines.Add('Name: ' + tmpStr);

    FFPlugin.GetPluginType(tmpWord);
    if tmpWord = 0 then
      Description.Lines.Add('PluginType: Effect')
    else if tmpWord = 1 then
      Description.Lines.Add('PluginType: Source')
    else
      Description.Lines.Add('PluginType: Unknown');

    FFPlugin.GetVersion(tmpStr);
    Description.Lines.Add('Version: ' + tmpStr);

    FFPlugin.GetUniqueID(tmpStr);
    Description.Lines.Add('Unique ID: ' + tmpStr);

    FFPlugin.GetAbout(tmpStr);
    Description.Lines.Add('About: ' + tmpStr);

    FFPlugin.GetDescription(tmpStr);
    Description.Lines.Add(tmpStr);
  except
  end;

  try
    LockWindowUpdate(ScrollBox.Handle);

    for i := ScrollBox.ControlCount - 1 downto 0 do
    ScrollBox.Controls[i].Free;
    SetLength(FLabels, 0);
    SetLength(FTrackBars, 0);

    FFParameters.GetCount(tmpWord);
    SetLength(FLabels, tmpWord);
    SetLength(FTrackBars, tmpWord);

    if tmpWord = 0 then
      exit;

    for i := tmpWord - 1 downto 0 do
    begin
      FTrackBars[i] := TTrackBar.Create(ScrollBox);
      FTrackBars[i].Parent := ScrollBox;
      FTrackBars[i].OnChange := TrackBarChange;
      FTrackBars[i].Align := alTop;
      FTrackBars[i].Tag := i;
      FTrackBars[i].Height := 25;

      FFParameters.GetType(i, tmpWord);
      if tmpWord = 0 then
        FTrackBars[i].Max := 1
      else
        FTrackBars[i].Max := 100;

      FFParameters.GetDefault(i, tmpSingle);
      FTrackBars[i].Position := round(tmpSingle * 100);

      FLabels[i] := TLabel.Create(ScrollBox);
      FLabels[i].Parent := ScrollBox;
      FLabels[i].Align := alTop;
      FLabels[i].Tag := i;

      FFParameters.GetName(i, tmpStr);
      FFParameters.GetDisplayValue(i, tmpStr2);
      FLabels[i].Caption := tmpStr + ': ' + tmpStr2;
    end;
  finally
    LockWindowUpdate(0);
  end;     

  PropertyPage.SetPageDirty;
end;

procedure TPropertyPage.TrackBarChange(Sender: TObject);
var
  index: Integer;
  tmpStr, tmpStr2: String;
begin
  index := (Sender as TTrackBar).Tag;
  FFParameters.SetValue(index, (Sender as TTrackBar).Position / 100);
  FFParameters.GetName(index, tmpStr);
  FFParameters.GetDisplayValue(index, tmpStr2);
  FLabels[index].Caption := tmpStr + ': ' + tmpStr2;

  PropertyPage.SetPageDirty;
end;

procedure TPropertyPage.ResetClick(Sender: TObject);
var
  tmpDWord: DWord;
  tmpSingle: Single;
  i: Integer;
begin
  FFParameters.GetCount(tmpDWord);
  if tmpDWord = 0 then
    exit;

  for i := 0 to tmpDWord - 1 do
  begin
    FFParameters.GetDefault(i, tmpSingle);
    FTrackBars[i].Position := round(tmpSingle * 100);
    TrackBarChange(FTrackBars[i]);
  end;
end;

procedure TPropertyPage.FormActivate(Sender: TObject);
var
  tmpStr: String;
  tmpIndex: Integer;
begin
  FFPropertySaves.GetPluginPath(FPluginPath);
  if FPluginPath = '' then
    exit;

  Edit1.Text := FPluginPath;
  GetPlugins;

  FFPropertySaves.GetCurrentPlugin(tmpStr);
  tmpIndex := ComboBox.Items.IndexOf(tmpStr);
  if tmpIndex >= 0 then
    ComboBox.ItemIndex := tmpIndex;

  ComboBoxChange(nil);
end;

procedure TPropertyPage.FormCreate(Sender: TObject);
begin
  FOpenFolderDialog := TpsvBrowseFolderDialog.Create(Self);
  FOpenFolderDialog.Caption := 'Select a folder with freeframe plugins';
end;

procedure TPropertyPage.FormDestroy(Sender: TObject);
begin
  FOpenFolderDialog.Free;
end;

initialization

TBCClassFactory.CreatePropertyPage(TPropertyPage, CLSID_FreeFrameWrapperPropertyPage);

end.

