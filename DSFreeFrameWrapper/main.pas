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

 {
 todo:
 - request a mediaformat for the connections that is available from the current plugin
 - save propertypage info per instance
 - still crashes with certain formats (analog rgb32 786x576)
 }

unit main;

interface
uses BaseClass, ActiveX, DirectShow9, Windows, DSUtil, PropPage;

const
  CLSID_DSFreeFrameWrapper : TGUID = '{DA700236-F7FF-43CA-9B21-1819B4308EE6}';
  IID_FFParameters: TGUID = '{9EB75574-7A2F-4227-93FF-39BE75BC883C}';
  IID_FFOutputs: TGUID = '{3F671C2A-91DF-4624-921E-7D70C84F3ACE}';
  IID_FFPlugIn: TGUID = '{88C2A7B8-8C17-4BB4-B91A-F03EE1480DAA}';
  IID_FFPlugIn2: TGUID = '{0B3E63CA-3E99-443D-9C8E-5E18BCDB6ACD}';
  IID_FFPropertySaves: TGUID = '{D75D285D-3956-441D-99E5-768B940A105B}';

  FF_SUCCESS = 0;
  FF_FAIL = $FFFFFFFF;
  FF_TRUE = 1;
  FF_FALSE = 0;
  FF_SUPPORTED = 1;
  FF_UNSUPPORTED = 0;

  FF_GETINFO = 0;
  FF_INITIALISE = 1;
  FF_DEINITIALISE = 2;
  FF_PROCESSFRAME = 3;
  FF_GETNUMPARAMETERS = 4;
  FF_GETPARAMETERNAME = 5;
  FF_GETPARAMETERDEFAULT = 6;
  FF_GETPARAMETERDISPLAY = 7;
  FF_SETPARAMETER = 8;
  FF_GETPARAMETER = 9;
  FF_GETPLUGINCAPS = 10;
  FF_INSTANTIATE = 11;
  FF_DEINSTANTIATE = 12;
  FF_GETEXTENDEDINFO = 13;
  FF_PROCESSFRAMECOPY = 14;
  FF_GETPARAMETERTYPE = 15;

  //additions to FF specs
  FF_SETTRHEADLOCK = 19;

  //for outputs
  FF_GETNUMOUTPUTS = 20;
  FF_GETOUTPUTNAME = 21;
  FF_GETOUTPUTTYPE = 22;
  FF_GETOUTPUTSLICECOUNT = 23;
  FF_GETOUTPUT = 24;

  //for spreaded inputs
  FF_SETINPUT = 30;

  //for compatibility
  FF_HANDLESINVALIDCODES = 999;

  FreeFramePinTypes : TRegPinTypes =
    (clsMajorType: @MEDIATYPE_Video;
     clsMinorType: @MEDIASUBTYPE_RGB24);

  FreeFramePins : array[0..1] of TRegFilterPins =
    ((strName: 'Input'; bRendered: FALSE; bOutput: FALSE; bZero: FALSE; bMany: FALSE; oFilter: nil; strConnectsToPin: nil; nMediaTypes: 1; lpMediaType: @FreeFramePinTypes),
     (strName: 'Output'; bRendered: FALSE; bOutput: TRUE; bZero: FALSE; bMany: FALSE; oFilter: nil; strConnectsToPin: nil; nMediaTypes: 1; lpMediaType: @FreeFramePinTypes));


type
  IFFParameters = interface
    ['{9EB75574-7A2F-4227-93FF-39BE75BC883C}']
    function GetCount(out Count: DWord): HResult; stdcall;
    function GetName(Index: Integer; out Name: String): HResult; stdcall;
    function GetType(Index: Integer; out Typ: DWord): HResult; stdcall;
    function GetDefault(Index: Integer; out Default: Single): HResult; stdcall;
    function GetValue(Index: Integer; out Value: Single): HResult; stdcall;
    function GetDisplayValue(Index: Integer; out DisplayValue: String): HResult; stdcall;
    function SetValue(Index: Integer; Value: Single): HResult; stdcall;
    function SetInput(Index, SliceCount: Integer; Value: Pointer): HResult; stdcall;
  end;

  IFFOutputs = interface
    ['{3F671C2A-91DF-4624-921E-7D70C84F3ACE}']
    function GetOutputCount(out Count: DWord): HResult; stdcall;
    function GetOutputName(Index: Integer; out Name: String): HResult; stdcall;
    function GetOutputType(Index: Integer; out Typ: DWord): HResult; stdcall;
    function GetOutputSliceCount(Index: Integer; out Slicecount: DWord): HResult; stdcall;
    function GetOutput(Index: Integer; out Value: PSingle): HResult; stdcall;
  end;

  IFFPlugIn = interface
    ['{88C2A7B8-8C17-4BB4-B91A-F03EE1480DAA}']
    function SetPlugin(Filename: String): HResult; stdcall;
    function GetVersion(out Version: String): HResult; stdcall;
    function GetUniqueID(out ID: String): HResult; stdcall;
    function GetPluginName(out Name: String): HResult; stdcall;
    function GetPluginType(out Typ: DWord): HResult; stdcall;
    function GetDescription(out Description: String): HResult; stdcall;
    function GetAbout(out About: String): HResult; stdcall;
    function GetCaps(CapsIndex: Integer; out CapsResult: DWord): HResult; stdcall;
    function SetEnabled(Enabled: Boolean): HResult; stdcall;
    function GetHandlesInvalidCodes: HResult; stdcall;
  end;

  IFFPlugIn2 = interface
    ['{0B3E63CA-3E99-443D-9C8E-5E18BCDB6ACD}']
    function SetThreadLock(Enabled: Boolean): HResult; stdcall;
  end;

  IFFPropertySaves = interface
    ['{D75D285D-3956-441D-99E5-768B940A105B}']
    function SetPluginPath(Path: String): HResult; stdcall;
    function SetCurrentPlugin(Filename: String): HResult; stdcall;
    function GetPluginPath(out Path: String): HResult; stdcall;
    function GetCurrentPlugin(out Filename: String): HResult; stdcall;
  end;

  TPlugMainFunction = function(FunctionCode: DWord; pParam: Pointer; InstanceID: DWord): Pointer; stdcall;

  TVideoInfoStruct = record
    FrameWidth: DWord;
    FrameHeight: DWord;
    BitDepth: DWord;
    orientation: DWord;
  end;

  TPluginInfoStruct = record
    APIMajorVersion: DWord;
    APIMinorVersion: DWord;
    PluginUniqueID: array [0..3] of Char;
    PluginName: array [0..15] of Char;
    PluginType: DWord;
  end;

  TInputStruct = record
    Index: DWord;
    SliceCount: DWord;
    Spread: Pointer;
  end;

  TSetParameterStruct = record
    ParameterNumber: DWord;
    NewParameterValue: DWord;
  end;

  TPluginExtendedInfoStruct = record
    PluginMajorVersion: dword;
    PluginMinorVersion: dword;
    pDescription: pointer;
    pAbout: pointer;
    FreeFrameExtendedDataSize: dword;
    FreeFrameExtendedDataBlock: pointer;
  end;

  PDWord = ^dword;

  TFreeFrameWrapperFilter = class(TBCTransformFilter, IFFPlugIn, IFFPlugIn2, IFFParameters, IFFOutputs,
      ISpecifyPropertyPages, IFFPropertySaves)
  private
    FCurrentPlug: THandle;
    FPlugMain: TPlugMainFunction;
    FVideoInfoStruct: TVideoInfoStruct;
    FPlugInstance: DWord;
    FInitialized: Boolean;
    FCritSec: TBCCritSec;
    FCurrentPlugin: string;
    FPluginPath: string;
    FInstantiated: Boolean;
    FEnabled: Boolean;
    procedure InitializePlugin;
    procedure DeInitializePlugin;
    function CanTransform(mtIn: PAMMediaType): Boolean;
    procedure InstantiatePlugin;
    procedure DeInstantiatePlugin;
  public
    constructor Create(Unk: IUnKnown; out hr: HRESULT);
    destructor Destroy; override;
    constructor CreateFromFactory(Factory: TBCClassFactory; const Controller: IUnknown); override;
    function Transform(pIn, pOut: IMediaSample): HRESULT; overload; override;
    function Copy(Source, dest: IMediaSample): HRESULT;
    function CheckInputType(mtIn: PAMMediaType): HRESULT; override;
    function CheckTransform(mtIn, mtOut: PAMMediaType): HRESULT; override;
    function GetMediaType(Position: integer; out MediaType: PAMMediaType): HRESULT; override;
    function DecideBufferSize(Alloc: IMemAllocator; Properties: PAllocatorProperties): HRESULT; override;
    function CompleteConnect(direction: TPinDirection; ReceivePin: IPin): HRESULT; override;
    function GetPages(out pages: TCAGUID): HResult; stdcall;

    //IFFParameters
    function GetCount(out Count: DWord): HResult; stdcall;
    function GetName(Index: Integer; out Name: String): HResult; stdcall;
    function GetType(Index: Integer; out Typ: DWord): HResult; stdcall;
    function GetDefault(Index: Integer; out Default: Single): HResult; stdcall;
    function GetValue(Index: Integer; out Value: Single): HResult; stdcall;
    function GetDisplayValue(Index: Integer; out DisplayValue: String): HResult; stdcall;
    function SetValue(Index: Integer; Value: Single): HResult; stdcall;
    function SetInput(Index, SliceCount: Integer; Value: Pointer): HResult; stdcall;

    //IFFOutputs
    function GetOutputCount(out Count: DWord): HResult; stdcall;
    function GetOutputName(Index: Integer; out Name: String): HResult; stdcall;
    function GetOutputType(Index: Integer; out Typ: DWord): HResult; stdcall;
    function GetOutputSliceCount(Index: Integer; out SliceCount: DWord): HResult; stdcall;
    function GetOutput(Index: Integer; out Value: PSingle): HResult; stdcall;

    // IFFPlugIn
    function SetPlugin(Filename: String): HResult; stdcall;
    function GetVersion(out Version: String): HResult; stdcall;
    function GetUniqueID(out ID: String): HResult; stdcall;
    function GetPluginName(out Name: String): HResult; stdcall;
    function GetPluginType(out Typ: DWord): HResult; stdcall;
    function GetDescription(out Description: String): HResult; stdcall;
    function GetAbout(out About: String): HResult; stdcall;
    function GetCaps(CapsIndex: Integer; out CapsResult: DWord): HResult; stdcall;
    function SetEnabled(Enabled: Boolean): HResult; stdcall;
    function GetHandlesInvalidCodes: HResult; stdcall;

    // IFFPlugIn2
    function SetThreadLock(Enabled: Boolean): HResult; stdcall;

    // IFFPropertySaves
    function SetPluginPath(Path: String): HResult; stdcall;
    function SetCurrentPlugin(Filename: String): HResult; stdcall;
    function GetPluginPath(out Path: String): HResult; stdcall;
    function GetCurrentPlugin(out Filename: String): HResult; stdcall;
  end;

implementation

uses Dialogs, SysUtils, Forms;


//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------


procedure TFreeFrameWrapperFilter.InitializePlugin;
begin
  if not FInitialized then
    if DWord(FPlugMain(FF_INITIALISE, nil, 0)) = FF_SUCCESS then
      FInitialized := true;
end;

procedure TFreeFrameWrapperFilter.InstantiatePlugin;
var
  pVideoInfoStruct: Pointer;
begin
  DeInstantiatePlugin;

  pVideoInfoStruct := Pointer(@FVideoInfoStruct);
  FPlugInstance := DWord(FPlugMain(FF_INSTANTIATE, pVideoInfoStruct, 0));
  if FPlugInstance <> FF_FAIL then
    FInstantiated := true;
end;

procedure TFreeFrameWrapperFilter.DeInitializePlugin;
begin
  DeInstantiatePlugin;

  if FInitialized then
    try
      FPlugMain(FF_DEINITIALISE, nil, 0);
    finally
      FInitialized := false;
      FPlugMain := nil;
      FreeLibrary(FCurrentPlug);
    end;
end;

procedure TFreeFrameWrapperFilter.DeInstantiatePlugin;
begin
  if FInstantiated then
    if DWord(FPlugMain(FF_DEINSTANTIATE, nil, FPlugInstance)) = FF_SUCCESS then  //deinstantiate
      FInstantiated := false;
end;

constructor TFreeFrameWrapperFilter.Create(Unk: IUnknown; out hr: HRESULT);
begin
  inherited Create('DirectShow FreeFrameWrapper Filter', Unk, CLSID_DSFreeFrameWrapper);

  FCritSec := TBCCritSec.Create;

  ASSERT(FOutput = nil, 'WrapperFilterCreate');

  FInitialized := false;
  FInstantiated := false;

  FPluginPath := '';
  FEnabled := true;
end;

destructor TFreeFrameWrapperFilter.Destroy;
begin
  DeInitializePlugin;
  FCritSec.Free;
  inherited;
end;

constructor TFreeFrameWrapperFilter.CreateFromFactory(Factory: TBCClassFactory; const Controller: IUnknown);
var hr: HRESULT;
begin
  Create(Controller, hr);
end;

function TFreeFrameWrapperFilter.Transform(pIn, pOut: IMediaSample): HRESULT;
var
  pData: PByte;
begin
  FCritSec.Lock;
  try
    result := Copy(pIn, pOut);
    if FEnabled then
    begin
      pOut.GetPointer(pData);
      if FInstantiated then
        FPlugMain(FF_PROCESSFRAME, Pointer(pData), FPlugInstance);
    end;
  finally
    FCritSec.UnLock;
  end;
end;

function TFreeFrameWrapperFilter.Copy(Source, dest: IMediaSample): HRESULT;
var
  SourceBuffer, DestBuffer: PBYTE;
  SourceSize: LongInt;
  TimeStart, TimeEnd: TReferenceTime;
  MediaStart, MediaEnd: int64;
  MediaType: PAMMediaType;
  DataLength: Integer;
begin
  // Copy the sample data
  SourceSize := Source.GetActualDataLength;

  Source.GetPointer(SourceBuffer);
  Dest.GetPointer(DestBuffer);

  CopyMemory(DestBuffer, SourceBuffer, SourceSize);

  // Copy the sample times
  if (NOERROR = Source.GetTime(TimeStart, TimeEnd)) then
    Dest.SetTime(@TimeStart, @TimeEnd);

  if (Source.GetMediaTime(MediaStart,MediaEnd) = NOERROR) then
    Dest.SetMediaTime(@MediaStart, @MediaEnd);

  // Copy the media type
  Source.GetMediaType(MediaType);
  Dest.SetMediaType(MediaType);
  DeleteMediaType(MediaType);

  // Copy the actual data length
  DataLength := Source.GetActualDataLength;
  Dest.SetActualDataLength(DataLength);
  result := NOERROR;
end;

function TFreeFrameWrapperFilter.CheckInputType(mtIn: PAMMediaType): HRESULT;
begin
  //The Input.CheckMediaType member function is implemented to call the CheckInputType member function of the derived filter class
  if not IsEqualGUID(mtIn.formattype, FORMAT_None)
  and not IsEqualGUID(mtIn.formattype, FORMAT_WaveFormatEx)
  and not IsEqualGUID(mtIn.formattype, GUID_NULL)
  and CanTransform(mtIn) then
    Result := S_OK
  else
    Result := VFW_E_TYPE_NOT_ACCEPTED;
end;

function TFreeFrameWrapperFilter.CheckTransform(mtIn,
  mtOut: PAMMediaType): HRESULT;
begin
  //called when
  //    Output is already connected during connection of input
  //    Output.CheckMediaType is called

  Result := CheckInputType(mtOut);
  if Result = VFW_E_TYPE_NOT_ACCEPTED then
    exit;

  Result := NOERROR;
end;

function TFreeFrameWrapperFilter.GetMediaType(Position: integer;
  out MediaType: PAMMediaType): HRESULT;
begin
  ASSERT((Position = 0) or (Position = 1), 'GetMediaType');
  if(Position = 0) then
  begin
    CopyMediaType(MediaType, FInput.CurrentMediaType.MediaType);
    result := S_OK;
    exit;
  end;
  result := VFW_S_NO_MORE_ITEMS;   
end;

function TFreeFrameWrapperFilter.DecideBufferSize(Alloc: IMemAllocator;
  Properties: PAllocatorProperties): HRESULT;
var
  InProps, Actual: TAllocatorProperties;
  InAlloc: IMemAllocator;
begin
  // Is the input pin connected
  if not FInput.IsConnected then
    begin
      result := E_UNEXPECTED;
      exit;
    end;

  ASSERT(Alloc <> nil, 'DecideBufferSize');
  ASSERT(Properties <> nil, 'DecideBufferSize');

  Properties.cBuffers := 1;
  Properties.cbBuffer := FInput.AMMediaType.lSampleSize;

  // Get input pin's allocator size and use that
  result := FInput.GetAllocator(InAlloc);
  if SUCCEEDED(result) then
  begin
    result := InAlloc.GetProperties(InProps);
    if SUCCEEDED(result) then
      Properties.cbBuffer := InProps.cbBuffer;
    InAlloc := nil;
  end;

  if FAILED(result) then exit;

  ASSERT(Properties.cbBuffer <> 0, 'DecideBufferSize');

  // Ask the allocator to reserve us some sample memory, NOTE the function
  // can succeed (that is return NOERROR) but still not have allocated the
  // memory that we requested, so we must check we got whatever we wanted

  result := Alloc.SetProperties(Properties^, Actual);
  if FAILED(result) then exit;

  ASSERT(Actual.cBuffers = 1, 'DecideBufferSize');

  if (Properties.cBuffers > Actual.cBuffers)
  or (Properties.cbBuffer > Actual.cbBuffer) then
    result := E_FAIL
  else
    result := NOERROR;     
end;

function TFreeFrameWrapperFilter.CompleteConnect(direction: TPinDirection;
  ReceivePin: IPin): HRESULT;
var
  mType: TAMMediaType;
  vIH: TVideoInfoHeader;
  bIH: TBitmapInfoHeader;
begin
  result := S_OK;

  ReceivePin.ConnectionMediaType(mType);
  if not Assigned(mType.pbFormat) then
    exit;

  vIH := TVideoInfoHeader(mType.pbFormat^);
  bIH := TBitmapInfoHeader(vIH.bmiHeader);

  FVideoInfoStruct.FrameWidth := bIH.biWidth;
  FVideoInfoStruct.FrameHeight := abs(bIH.biHeight);

  if bIH.biBitCount = 16 then
    FVideoInfoStruct.BitDepth := 0
  else if bIH.biBitCount = 24 then
    FVideoInfoStruct.BitDepth := 1
  else if bIH.biBitCount = 32 then
    FVideoInfoStruct.BitDepth := 2;

  if bIH.biHeight < 0 then
    FVideoInfoStruct.orientation := 1
  else
    FVideoInfoStruct.orientation := 2;

  if FInitialized then
    InstantiatePlugin;
end;

function TFreeFrameWrapperFilter.GetPages(out pages: TCAGUID): HResult; stdcall;
begin
  Pages.cElems := 1;
  Pages.pElems := CoTaskMemAlloc(sizeof(TGUID));
  if (Pages.pElems = nil) then
  begin
    result := E_OUTOFMEMORY;
    exit;
  end;

  Pages.pElems^[0] := CLSID_FreeFrameWrapperPropertyPage;
  Result := NOERROR;
end;

function TFreeFrameWrapperFilter.GetCount(out Count: DWord): HResult; stdcall;
begin
  if FInitialized then
  begin
    Count := DWord(FPlugMain(FF_GETNUMPARAMETERS, nil, 0));
    Result := S_OK;
  end
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.GetName(Index: Integer; out Name: String): HResult; stdcall;
var
  tempParamDisplay: array [0..15] of Char;
  tempSourcePointer: PDWord;
  tempDestPointer: PDWord;
  i: Integer;
begin
  if FInitialized then
  begin
    tempSourcePointer := PDWord(FPlugMain(FF_GETPARAMETERNAME, Pointer(Index), 0));
    tempDestPointer := PDWord(@tempParamDisplay);

    for i := 0 to 3 do
    begin
      tempDestPointer^ := tempSourcePointer^;
      inc(tempSourcePointer);
      inc(tempDestPointer);
    end;

    Name := Trim(String(tempParamDisplay));
    Result := S_OK;
  end
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.GetType(Index: Integer; out Typ: DWord): HResult; stdcall;
begin
  if FInitialized then
  begin
    Typ := DWord(FPlugMain(FF_GETPARAMETERTYPE, Pointer(Index), 0));
    Result := S_OK;
  end
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.GetDefault(Index: Integer; out Default: Single): HResult; stdcall;
var
  tempDWord: DWord;
begin
 if FInitialized then
 begin
   tempDWord := DWord(FPlugMain(FF_GETPARAMETERDEFAULT, Pointer(Index), 0));
   CopyMemory(@Default, @tempDword, 4);

   Result := S_OK;
 end
 else
   Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.GetValue(Index: Integer; out Value: Single): HResult; stdcall;
var
  tempDWord: DWord;
begin
 if FInstantiated then
 begin
    tempDword := DWord(FPlugMain(FF_GETPARAMETER, pointer(Index), FPlugInstance));
    CopyMemory(@Value, @tempDword, 4);
    Result := S_OK;
 end
 else
   Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.GetDisplayValue(Index: Integer; out DisplayValue: String): HResult; stdcall;
var
  tempParamDisplay: array [0..15] of Char;
  tempSourcePointer: PDWord;
  tempDestPointer: PDWord;
  i: Integer;
begin
  if FInstantiated then
  begin
    tempSourcePointer := PDWord(FPlugMain(FF_GETPARAMETERDISPLAY, Pointer(Index), FPlugInstance));
    tempDestPointer := PDWord(@tempParamDisplay);

    for i := 0 to 3 do
    begin
      tempDestPointer^ := tempSourcePointer^;
      inc(tempSourcePointer);
      inc(tempDestPointer);
    end;

    DisplayValue := Trim(tempParamDisplay);
    Result := S_OK;
  end
  else
     Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.SetValue(Index: Integer; Value: Single): HResult; stdcall;
var
  paramStruct: TSetParameterStruct;
  tempPDWord: PDWord;
begin
  paramStruct.ParameterNumber := Index;
  tempPDWord := @Value;
  paramStruct.NewParameterValue := tempPDWord^;

  if FInstantiated then
  begin
    if DWord(FPlugMain(FF_SETPARAMETER, @paramStruct, FPlugInstance)) = FF_SUCCESS then
      Result := S_OK
    else
      Result := E_FAIL;
  end
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.SetPlugin(Filename: String): HResult; stdcall;
begin
  FCritSec.Lock;
  try
    DeInitializePlugin;
    Result := E_FAIL;

    FCurrentPlug := LoadLibrary(PChar(Filename));
    if FCurrentPlug <> 0 then
    begin
      FPlugMain := GetProcAddress(FCurrentPlug, 'plugMain');
      if @FPlugMain = nil then
      begin
        FreeLibrary(FCurrentPlug);
        FCurrentPlug := 0;
      end
      else
        Result := S_OK;
    end;

    InitializePlugin;
    InstantiatePlugin;
  finally
    FCritSec.UnLock;
  end;
end;

function TFreeFrameWrapperFilter.GetVersion(out Version: String): HResult; stdcall;
var
  pPluginInfoStruct: Pointer;
begin
  if FInitialized then
  begin
    pPluginInfoStruct := FPlugMain(FF_GETINFO, nil, 0);
    if pPluginInfoStruct <> nil then
    begin
      Result := S_OK;
      Version := FloatToStr(TPluginInfoStruct(pPluginInfoStruct^).APIMajorVersion + TPluginInfoStruct(pPluginInfoStruct^).APIMinorVersion / 1000);
    end
    else
      Result := E_FAIL;
  end
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.GetUniqueID(out ID: String): HResult; stdcall;
var
  pPluginInfoStruct: Pointer;
begin
  if FInitialized then
  begin
    pPluginInfoStruct := FPlugMain(FF_GETINFO, nil, 0);
    if pPluginInfoStruct <> nil then
    begin
      Result := S_OK;
      ID := TPluginInfoStruct(pPluginInfoStruct^).PluginUniqueID;
    end
    else
      Result := E_FAIL;
  end
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.GetPluginName(out Name: String): HResult; stdcall;
var
  pPluginInfoStruct: Pointer;
begin
  if FInitialized then
  begin
    pPluginInfoStruct := FPlugMain(FF_GETINFO, nil, 0);
    if pPluginInfoStruct <> nil then
    begin
      Result := S_OK;
      Name := TPluginInfoStruct(pPluginInfoStruct^).PluginName;
    end
    else
      Result := E_FAIL;
  end
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.GetPluginType(out Typ: DWord): HResult; stdcall;
var
  pPluginInfoStruct: Pointer;
begin
  if FInitialized then
  begin
    pPluginInfoStruct := FPlugMain(FF_GETINFO, nil, 0);
    if pPluginInfoStruct <> nil then
    begin
      Result := S_OK;
      Typ := TPluginInfoStruct(pPluginInfoStruct^).PluginType;
    end
    else
      Result := E_FAIL;
  end
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.GetDescription(out Description: String): HResult; stdcall;
var
  pPluginExtendedInfoStruct: Pointer;
begin
  if FInitialized then
  begin
    pPluginExtendedInfoStruct := FPlugMain(FF_GETEXTENDEDINFO, nil, 0);
    if pPluginExtendedInfoStruct <> nil then
    begin
      Result := S_OK;
      Description := PChar(TPluginExtendedInfoStruct(pPluginExtendedInfoStruct^).pDescription);
    end
    else
      Result := E_FAIL;
  end
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.GetAbout(out About: String): HResult; stdcall;
var
  pPluginExtendedInfoStruct: Pointer;
begin
  if FInitialized then
  begin
    pPluginExtendedInfoStruct := FPlugMain(FF_GETEXTENDEDINFO, nil, 0);
    if pPluginExtendedInfoStruct <> nil then
    begin
      Result := S_OK;
      About := PChar(TPluginExtendedInfoStruct(pPluginExtendedInfoStruct^).pAbout);
    end
    else
      Result := E_FAIL;
  end
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.GetCaps(CapsIndex: Integer; out CapsResult: DWord): HResult; stdcall;
begin
  if FInitialized then
  begin
    Result := S_OK;
    if CapsIndex <= 3 then
      CapsResult := DWord(FPlugMain(FF_GETPLUGINCAPS, Pointer(CapsIndex), 0));
  end
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.SetPluginPath(Path: String): HResult;
begin
  //should save that per instance
  FPluginPath := Path;
  Result := S_OK;
end;

function TFreeFrameWrapperFilter.SetCurrentPlugin(
  Filename: String): HResult;
begin
  //should save that per instance
  FCurrentPlugin := Filename;
  Result := S_OK;
end;

function TFreeFrameWrapperFilter.GetPluginPath(out Path: String): HResult;
begin
  Path := FPluginPath;
  Result := S_OK;
end;

function TFreeFrameWrapperFilter.GetCurrentPlugin(
  out Filename: String): HResult;
begin
  Filename := FCurrentPlugin;
  Result := S_OK;
end;

function TFreeFrameWrapperFilter.CanTransform(mtIn: PAMMediaType): Boolean;
var
  vIH: TVideoInfoHeader;
begin
  vIH := TVideoInfoHeader(mtIn.pbFormat^);

  if IsEqualGUID(mtIn.majortype, MEDIATYPE_Video)
  and IsEqualGUID(mtIn.subtype, MEDIASUBTYPE_RGB24)
  and (vIH.bmiHeader.biBitCount = 24) then
    Result := true
  else
    Result := false;
end;

function TFreeFrameWrapperFilter.GetOutputCount(out Count: DWord): HResult;
begin
  if FInitialized then
  begin
    Count := DWord(FPlugMain(FF_GETNUMOUTPUTS, nil, 0));
    if Count = FF_FAIL then
      Result := E_FAIL
    else
      Result := S_OK;
  end
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.GetOutputName(Index: Integer;
  out Name: String): HResult;
var
  tempParamDisplay: array [0..15] of Char;
  tempSourcePointer: PDWord;
  tempDestPointer: PDWord;
  i: Integer;
begin
  if FInitialized then
  begin
    tempSourcePointer := PDWord(FPlugMain(FF_GETOUTPUTNAME, Pointer(Index), 0));
    tempDestPointer := PDWord(@tempParamDisplay);

    for i := 0 to 3 do
    begin
      tempDestPointer^ := tempSourcePointer^;
      inc(tempSourcePointer);
      inc(tempDestPointer);
    end;

    Name := Trim(String(tempParamDisplay));
    Result := S_OK;
  end
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.GetOutputType(Index: Integer;
  out Typ: DWord): HResult;
begin
  if FInitialized then
  begin
    Typ := DWord(FPlugMain(FF_GETOUTPUTTYPE, Pointer(Index), 0));
    Result := S_OK;
  end
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.GetOutputSliceCount(Index: Integer;
  out SliceCount: DWord): HResult;
begin
 if FInstantiated then
 begin
    SliceCount := DWord(FPlugMain(FF_GETOUTPUTSLICECOUNT, pointer(Index), FPlugInstance));
    Result := S_OK;
 end
 else
   Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.GetOutput(Index: Integer;
  out Value: PSingle): HResult;
begin
 if FInstantiated then
 begin
    Value := PSingle(FPlugMain(FF_GETOUTPUT, pointer(Index), FPlugInstance));
    Result := S_OK;
 end
 else
   Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.SetEnabled(Enabled: Boolean): HResult;
begin
  FEnabled := Enabled;
  Result := S_OK;
end;

function TFreeFrameWrapperFilter.GetHandlesInvalidCodes: HResult;
var
  res: DWord;
begin
  res := DWord(FPlugMain(FF_HANDLESINVALIDCODES, nil, 0));
  if res = FF_FAIL then
    Result := S_OK
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.SetThreadLock(Enabled: Boolean): HResult;
begin
  if FInstantiated then
  begin
    if DWord(FPlugMain(FF_SETTRHEADLOCK, @Enabled, FPlugInstance)) = FF_SUCCESS then
      Result := S_OK
    else
      Result := E_FAIL;
  end
  else
    Result := E_FAIL;
end;

function TFreeFrameWrapperFilter.SetInput(Index, SliceCount: Integer; Value:
    Pointer): HResult;
var
  inputStruct: TInputStruct;
begin
  inputStruct.Index := Index;
  inputStruct.SliceCount := SliceCount;
  inputStruct.Spread := Value;

  if FInstantiated then
  begin
    if DWord(FPlugMain(FF_SETINPUT, pointer(@inputStruct), FPlugInstance)) = FF_SUCCESS then
      Result := S_OK
    else
      Result := E_FAIL;
  end
  else
    Result := E_FAIL;
end;

initialization
  TBCClassFactory.CreateFilter(TFreeFrameWrapperFilter, 'DSFreeFrameWrapper', CLSID_DSFreeFrameWrapper,
    CLSID_LegacyAmFilterCategory, MERIT_DO_NOT_USE, 2, @FreeFramePins);
end.

