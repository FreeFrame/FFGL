{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
{            Code taken from:                           }
{            Windows Dialogs interface unit             }
{                    version 2.2                        }
{                                                       }
{ Author:                                               }
{ Serhiy Perevoznyk                                     }
{ serge_perevoznyk@hotmail.com                          }
{                                                       }
{Use, modification and distribution is allowed          }
{without limitation, warranty, or liability of any kind.}
{                                                       }
{get the whole code from: http://users.chello.be/ws36637}
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

unit psvFolderDialog;

interface

Uses ShellAPI,Windows,Classes,Forms,SysUtils,Graphics, Dialogs,
     Controls, ShlOBJ, ComObj, ActiveX, CommDlg;

type
  TpsvComponent = class(TComponent)
  private
    FAbout : string;
  public
    constructor Create(AOwner : TComponent); override;
  published
    property About : string read FAbout write FAbout;
  end;

  {selection folder from tree}
  TpsvBrowseFolderDialog = Class(TpsvComponent)
  private
    FFolderName : String;
    FCaption : String;
  public
    Constructor Create(AOwner : TComponent); override;
    function Execute : boolean; virtual;
    property FolderName : string read FFolderName;
  published
    property Caption : string read FCaption write FCaption;
  end;

//Tools routines
Type
  FreePIDLProc  =  procedure (PIDL: PItemIDList); stdcall;

var
 FreePIDL : FreePIDLProc = nil;


implementation

constructor TpsvBrowseFolderDialog.Create(AOwner : TComponent);
begin
  inherited;
  FFolderName := EmptyStr;
end;

function TpsvBrowseFolderDialog.Execute : boolean;
var
  BrowseInfo: TBrowseInfo;
  ItemIDList: PItemIDList;
  ItemSelected : PItemIDList;
  NameBuffer: array[0..MAX_PATH] of Char;
  WindowList: Pointer;
  ShellHandle: THandle;
begin
  itemIDList := nil;
  FillChar(BrowseInfo, SizeOf(BrowseInfo), 0);
  BrowseInfo.hwndOwner := Application.Handle;
  BrowseInfo.pidlRoot := ItemIDList;
  BrowseInfo.pszDisplayName := NameBuffer;
  BrowseInfo.lpszTitle := PChar(FCaption);
  BrowseInfo.ulFlags := BIF_RETURNONLYFSDIRS;
  WindowList := DisableTaskWindows(0);
  try
    ItemSelected := SHBrowseForFolder(BrowseInfo);
    Result := ItemSelected <> nil;
  finally
    EnableTaskWindows(WindowList);
  end;

  if Result then
   begin
    SHGetPathFromIDList(ItemSelected,NameBuffer);
    FFolderName := NameBuffer;
   end;

  ShellHandle := Windows.LoadLibrary(PChar(shell32));
  if ShellHandle <> 0 then
  begin
    FreePIDL :=              GetProcAddress(ShellHandle, PChar(155));
    Freepidl(BrowseInfo.pidlRoot);
  end
  else
    ShowMessage('Could not load ''Shell32.dll''');
end;


{ TpsvComponent }

constructor TpsvComponent.Create(AOwner: TComponent);
begin
  inherited;
  FAbout := 'psvDialogs 2.0';
end;

end.

