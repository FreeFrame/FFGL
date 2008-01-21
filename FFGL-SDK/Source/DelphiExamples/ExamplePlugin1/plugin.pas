// FreeFrame Open Video Plugin GL Example
// www.freeframe.org
// johnday@camart.co.uk

{
Copyright (c) 2007 John Day
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

   * Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in
     the documentation and/or other materials provided with the
     distribution.
   * Neither the name of FreeFrame nor the names of its
     contributors may be used to endorse or promote products derived
     from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

}

unit plugin;

interface

uses
  sysutils,syncobjs,classes,
  gl,glu, ffstructs,math,
{$IFDEF LINUX} Types;{$ENDIF}
{$IFDEF WIN32} windows;{$ENDIF}

const
  NumberOfParameters=10;

type

  pdw = ^Dword;
  pw = ^word;
  pb = ^byte;

type
  TBlockPoint=record
    x,y:integer;
    u,v:single;
  end;

  TBlock=record
    p1,p2,p3,p4:TBlockPoint;
    //x1,y1,x2,y2:integer;
    //u1,v1,u2,v2:single;
    fadestate:integer;
    fadetargettime:single;
    fadevalue,fadespeed:single;
    r,g,b:single;
  end;

  TFreeFramePlugin = class(TObject)
  private
    // standard FreeFrame
    VideoInfoStruct: TVideoInfoStruct;

    // openGL FreeFrame
    ViewPortStruct:TPLuginGLViewportStruct;
    ProcessOpenGLStruct:TProcessOpenGLStruct;

    // Plugin Parameters
    ParameterArray: array [0..NumberOfParameters] of single;
    ParameterDisplayValue: array [0..NumberOfParameters,0..15] of char;

    // this plugins local vars
    Perspective:single;

    blocks:array of TBlock;
    totalblocks:integer;
    alphaorder:array of integer;

    prevtime:double;
    absoluteTime:double;

    hardwidth,hardheight:integer;

    procedure NewBlock(id:integer);
    function  DisallowOverlap(id,x1,y1,x2,y2:integer):boolean;
    procedure MakeFunky(id:integer);
    procedure UpdateFilters;
    procedure UpdateFilter(id:integer);
  protected
  public
    constructor Create;
    destructor Destroy;

    // functions that are instance specific
    function InitialiseInstance(pParam: pointer): pointer;
    function DeInitialiseInstance: pointer;

    function InitialiseGLInstance(pParam: pointer):pointer;
    function DeInitialiseGLInstance: pointer;

    function GetParameterDisplay(pParam: pointer): pointer;
    function SetParameter(pParam: pointer): pointer;
    function GetParameter(pParam: pointer): pointer;

    function ProcessFrame(pParam: pointer): pointer;
    function ProcessOpenGl(pParam:pointer):pointer;

    function SetTime(pParam:pointer):pointer;
  end;

// Global functions that are not instance specific ...

function InitilisePlugin:pointer;
function DeInitilisePlugin:pointer;
function GetInfo:pointer;
function GetExtendedInfo:pointer;
function GetNumParameters(pParam: pointer): pointer;
function GetParameterName(pParam: pointer): pointer;
function GetParameterType(pParam: pointer): pointer;
function GetParameterDefault(pParam: pointer): pointer;
function GetPluginCaps(pParam: pointer): pointer;

var
  PluginInfoStruct: TPluginInfoStruct;
  PluginExtendedInfoStruct: TPluginExtendedInfoStruct;

  ParameterNames: array [0..NumberOfParameters,0..15] of char;
  ParameterDefaults: array [0..NumberOfParameters] of single;
  ParameterTypes: array [0..NumberOfParameters] of dword;

implementation

//------------------------------------------------------------------------------
//
// GLOBAL FUNCTIONS
//
//------------------------------------------------------------------------------

function InitilisePlugin:pointer;
begin
  ParameterNames[0]:='Block Count    ';    // MUST be 15 chars
  ParameterNames[1]:='Fade Time      ';    // MUST be 15 chars
  ParameterNames[2]:='Fade TimeRandom';    // MUST be 15 chars
  ParameterNames[3]:='Block Max Size ';    // MUST be 15 chars
  ParameterNames[4]:='Block Min Size ';    // MUST be 15 chars
  ParameterNames[5]:='Filter Mode    ';    // MUST be 15 chars
  ParameterNames[6]:='Enable Overlap ';    // MUST be 15 chars
  ParameterNames[7]:='Enable Borders ';    // MUST be 15 chars
  ParameterNames[8]:='Border Size    ';    // MUST be 15 chars
  ParameterNames[9]:='Funky          ';    // MUST be 15 chars

  ParameterTypes[0]:=10;
  ParameterTypes[1]:=10;
  ParameterTypes[2]:=10;
  ParameterTypes[3]:=10;
  ParameterTypes[4]:=10;
  ParameterTypes[5]:=10;
  ParameterTypes[6]:=10;
  ParameterTypes[7]:=10;
  ParameterTypes[8]:=10;
  ParameterTypes[9]:=10;

  ParameterDefaults[0]:=0.05;
  ParameterDefaults[1]:=0.05;
  ParameterDefaults[2]:=0.5;
  ParameterDefaults[3]:=0.5;
  ParameterDefaults[4]:=0.3;
  ParameterDefaults[5]:=0.0;
  ParameterDefaults[6]:=1.0;
  ParameterDefaults[7]:=0.0;
  ParameterDefaults[8]:=0.1;
  ParameterDefaults[9]:=0.0;

  result:=pointer(0);
end;

function DeInitilisePlugin:pointer;
begin
  result:=pointer(0);
end;

//------------------------------------------------------------------------------
function GetInfo:pointer;
begin
  with PluginInfoStruct do begin
    APIMajorVersion:=1;
    APIMinorVersion:=0;
    PluginUniqueID:='GLX1';
    PluginName:='JD-FilterBoards';
    PluginType:=0;   // 0 = effect - 1 = source
  end;
  result:=@PluginInfoStruct;
end;
//------------------------------------------------------------------------------
function GetExtendedInfo:pointer;
begin
  with PluginExtendedInfoStruct do begin
    PluginMajorVersion:=1;
    PluginMinorVersion:=0;
    pDescription:= nil;
    pAbout:= nil;
    FreeFrameExtendedDataSize:= 0;
    FreeFrameExtendedDataBlock:= nil;
  end;
  result:=@pluginExtendedInfoStruct;
end;
//------------------------------------------------------------------------------
function GetPluginCaps(pParam: pointer): pointer;
begin
  case integer(pParam) of
    0: result:=pointer(0);   // 0=16bit - not yet supported in this sample plugin
    1: result:=pointer(0);   // 1=24bit - supported
    2: result:=pointer(0);   // 2=32bit
    3: result:=pointer(0);   // this plugin dosen't support copy yet
    4: result:=pointer(1);   // is an opengl plugin
    5: result:=pointer(1);   // this plugin supports setTime
    10: result:=pointer(1);  // minimum number of inputs
    11: result:=pointer(1);  // maximum number of inputs
    15: result:=pointer(0);  // optimization
                             // 0 (FF_CAP_PREFER_NONE) = no preference (GL plugins must return 0)
                             // 1 (FF_CAP_PREFER_INPLACE) = InPlace processing is faster
                             // 2 (FF_CAP_PREFER_COPY) = Copy processing is faster
                             // 3 (FF_CAP_PREFER_BOTH) = Both are optimized
    else result:=pointer($FFFFFFFF)   // unknown PluginCapsIndex
  end;
end;
//------------------------------------------------------------------------------
function GetNumParameters(pParam: pointer): pointer;
begin
  result:=pointer(NumberOfParameters);
end;
//------------------------------------------------------------------------------
function GetParameterName(pParam: pointer): pointer;
begin
  if integer(pParam)<NumberOfParameters then result:=@ParameterNames[integer(pParam)][0]
  else result:=pointer($FFFFFFFF);
end;
//------------------------------------------------------------------------------
function GetParameterType(pParam: pointer): pointer;
begin
  if integer(pParam)<NumberOfParameters then result:=@ParameterTypes[integer(pParam)]
  else result:=pointer($FFFFFFFF);
end;
//------------------------------------------------------------------------------
function GetParameterDefault(pParam: pointer): pointer;
begin
  if integer(pParam)<NumberOfParameters then result:=@ParameterDefaults[integer(pParam)]
  else result:=pointer($FFFFFFFF);
end;


//------------------------------------------------------------------------------
//
// INSTANCE FUNCTIONS
//
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
constructor TFreeFramePlugin.Create;
begin
  setlength(blocks,20);
  setlength(alphaorder,20);
  totalblocks:=0;

  absoluteTime:=0;
end;

destructor TFreeFramePlugin.Destroy;
begin
  //
end;


//------------------------------------------------------------------------------
function TFreeFramePlugin.InitialiseInstance(pParam: pointer):pointer;
begin
  result:=pointer($FFFFFFFF);          // this is an opengl plugin so return error
end;
//------------------------------------------------------------------------------
function TFreeFramePlugin.DeInitialiseInstance: pointer;
begin
  result:=pointer($FFFFFFFF);          // this is an opengl plugin so return error
end;
//------------------------------------------------------------------------------
function TFreeFramePlugin.InitialiseGLInstance(pParam: pointer):pointer;
var
  tempPointer: pDw;
  i:integer;
begin
  tempPointer:=pDw(pParam);
  ViewPortStruct.x:=tempPointer^;       // x
  inc(tempPointer);
  ViewPortStruct.y:=tempPointer^;       // y
  inc(tempPointer);
  ViewPortStruct.Width:=tempPointer^;   // width
  inc(tempPointer);
  ViewPortStruct.Height:=tempPointer^;  // height

  Perspective:=ViewPortStruct.width/ViewPortStruct.height;

  // load parameters with defaults here
  for i:=0 to NumberOfParameters-1 do ParameterArray[i]:=ParameterDefaults[i];

  // not going to update these in this example
  ParameterDisplayValue[0]:='Block Count    ';   // MUST be 15 chars
  ParameterDisplayValue[1]:='Fade Time      ';   // MUST be 15 chars
  ParameterDisplayValue[2]:='Fade TimeRandom';   // MUST be 15 chars
  ParameterDisplayValue[3]:='Block Max Size ';   // MUST be 15 chars
  ParameterDisplayValue[4]:='Block Min Size ';   // MUST be 15 chars
  ParameterDisplayValue[5]:='Filter Mode    ';    // MUST be 15 chars
  ParameterDisplayValue[6]:='Enable Overlap ';    // MUST be 15 chars
  ParameterDisplayValue[7]:='Enable Borders ';    // MUST be 15 chars
  ParameterDisplayValue[8]:='Border Size    ';    // MUST be 15 chars
  ParameterDisplayValue[9]:='Funky          ';    // MUST be 15 chars

  prevtime:=0;

  totalblocks:=0;
  //for i:=0 to 2 do begin  // default 3 blocks
    NewBlock(i);
    blocks[totalblocks].fadestate:=0;
    blocks[totalblocks].fadetargettime:=0;
    blocks[totalblocks].fadevalue:=0;
    inc(totalblocks);
  //end;

  result:=pointer(0);
end;
//------------------------------------------------------------------------------
function TFreeFramePlugin.DeInitialiseGLInstance: pointer;
begin
  result:=pointer(0);
end;

//------------------------------------------------------------------------------
function TFreeFramePlugin.GetParameterDisplay(pParam: pointer): pointer;
var
  paramindex:dword;
begin
  paramindex:=dword(pParam);
  if paramIndex<NumberOfParameters then begin
    result:=@ParameterDisplayValue[paramindex];
  end else begin
    result:=pointer($FFFFFFFF);
  end;
end;
//------------------------------------------------------------------------------
function TFreeFramePlugin.SetParameter(pParam: pointer): pointer;
var
  paramIndex:dword;
  prevblockcount:integer;
begin
  paramIndex:=dword(pParam^);
  if paramIndex<NumberOfParameters then begin
    pParam:=pointer(integer(pParam)+4);
    ParameterArray[paramIndex]:=single(pParam^);

    // add blocks on fly
    if paramIndex=0 then begin
      prevblockcount:=totalblocks;
      totalblocks:=round(ParameterArray[paramIndex]*20);
      while prevblockcount<totalblocks do begin
        NewBlock(prevblockcount);
        inc(prevblockcount);
      end;
    end;

    // update filters on fly
    if paramindex=5 then UpdateFilters;

    result:=pointer(0);
  end else
    result:=pointer($FFFFFFFF);
end;
//------------------------------------------------------------------------------
function TFreeFramePlugin.GetParameter(pParam: pointer): pointer;
var
  tempSingle: single;
begin
  tempSingle:=ParameterArray[integer(pParam)];
  result:=pointer(tempSingle);
end;
//------------------------------------------------------------------------------
//
//------------------------------------------------------------------------------
function TFreeFramePlugin.ProcessFrame(pParam: pointer): pointer;
begin
  result:=pointer($FFFFFFFF);  // gl plugin so return false
end;
//------------------------------------------------------------------------------
function TFreeFramePlugin.ProcessOpenGl(pParam:pointer):pointer;
var
  tempPointer,pInTex: pDw;
  pInTexArray:pointer;

  InputTexture:TPluginGLTextureStruct; // just one texture input for this plugin
  numInputTextures:dword;
  hostFBO:dword;

  now,delta:double;
  xratio,yratio:single;
  i,b:integer;
  done:boolean;

  bordersize:single;
begin
  tempPointer:=pDw(pParam);

  numInputTextures:=tempPointer^;
  if numInputTextures<1 then begin       // must have at least one input texture
    result:=pointer($FFFFFFFF);
    exit;
  end;
  inc(tempPointer);

  pInTexArray:=pointer(tempPointer^);      // 32-bit pointer to array of pointers to FFGLTextureStruct
  inc(tempPointer);

  HostFBO:=tempPointer^;                   // if you are using any fbo's reattach this at the end of function

  // possible loop if using more then 1 input texture
    pInTex:=pDw(pInTexArray^);
    InputTexture.Width:=pInTex^;
    inc(pInTex);
    InputTexture.Height:=pInTex^;
    inc(pInTex);
    InputTexture.HardwareWidth:=pInTex^;
    inc(pInTex);
    InputTexture.HardwareHeight:=pInTex^;
    inc(pInTex);
    InputTexture.Handle:=pInTex^; // (GLuint)
  //
  hardwidth:=InputTexture.HardwareWidth;
  hardheight:=InputTexture.HardwareHeight;

  // use timebased controls, allows effect to stay in time even if host slow frames
  now:=absoluteTime*1000;// convert from secs to msecs
  delta:=(now-prevtime);
  prevtime:=now;                   // store time for use in next call

  // progress blocks states
  for i:=0 to totalblocks-1 do begin

    if now>blocks[i].fadetargettime then begin
      blocks[i].fadetargettime:=now+(ParameterArray[1]*5000)+(random(round(ParameterArray[2]*5))*1000);
      blocks[i].fadespeed:=100/(blocks[i].fadetargettime-now);
      inc(blocks[i].fadestate);
      if blocks[i].fadestate=3 then begin
        blocks[i].fadestate:=0;
        blocks[i].fadevalue:=0;
        NewBlock(i);
      end;
    end;
    case blocks[i].fadestate of
    0: blocks[i].fadevalue:=blocks[i].fadevalue+blocks[i].fadespeed;
    1: blocks[i].fadevalue:=1.0;
    2: blocks[i].fadevalue:=blocks[i].fadevalue-blocks[i].fadespeed;
    end;


  end;

  // dont play with viewport (unless you stay within current and reset afterwards)
  //glViewport(ViewportStruct.x,ViewportStruct.y,ViewportStruct.Width,ViewportStruct.Height);

  // gl should have been set to default state by host before this point

  // setup required projection (host will not know what you want so set it up yourself)
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(0,ViewportStruct.Width,0,ViewportStruct.Height,1,-1);

  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D,InputTexture.Handle);

  // sort into alpha order (crappy bubble sort)
  for i:=0 to totalblocks-1 do alphaorder[i]:=i;
  done:=false;
  i:=0;
  while (not done) do begin
    if i<totalblocks-1 then begin
      if blocks[alphaorder[i+1]].fadevalue<blocks[alphaorder[i]].fadevalue then begin
        b:=alphaorder[i];
        alphaorder[i]:=alphaorder[i+1];
        alphaorder[i+1]:=b;
        i:=0;
      end else inc(i);
    end else done:=true;
  end;

  // shouldn't really blend (but for this testbed does)
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  bordersize:=ParameterArray[8]*32;
  for i:=0 to totalblocks-1 do begin
    b:=alphaorder[i];

    glColor4f(blocks[b].r,blocks[b].g,blocks[b].b,blocks[b].fadevalue);

    glBegin(GL_TRIANGLES);
      glTexCoord2f(blocks[b].p1.u,blocks[b].p1.v); glVertex2f(blocks[b].p1.x,blocks[b].p1.y);
      glTexCoord2f(blocks[b].p2.u,blocks[b].p2.v); glVertex2f(blocks[b].p2.x,blocks[b].p2.y);
      glTexCoord2f(blocks[b].p4.u,blocks[b].p4.v); glVertex2f(blocks[b].p4.x,blocks[b].p4.y);
      
      glTexCoord2f(blocks[b].p2.u,blocks[b].p2.v); glVertex2f(blocks[b].p2.x,blocks[b].p2.y);
      glTexCoord2f(blocks[b].p3.u,blocks[b].p3.v); glVertex2f(blocks[b].p3.x,blocks[b].p3.y);
      glTexCoord2f(blocks[b].p4.u,blocks[b].p4.v); glVertex2f(blocks[b].p4.x,blocks[b].p4.y);
    glEnd();

    if ParameterArray[7]=1.0 then begin
      glDisable(GL_TEXTURE_2D);
      glColor4f(0.0,0.0,0.0,blocks[b].fadevalue);
      glBegin(GL_TRIANGLES);
        // top
        glVertex2f(blocks[b].p1.x-bordersize,blocks[b].p1.y-bordersize);
        glVertex2f(blocks[b].p2.x+bordersize,blocks[b].p2.y-bordersize);
        glVertex2f(blocks[b].p1.x,blocks[b].p1.y);

        glVertex2f(blocks[b].p1.x,blocks[b].p1.y);
        glVertex2f(blocks[b].p2.x+bordersize,blocks[b].p2.y-bordersize);
        glVertex2f(blocks[b].p2.x,blocks[b].p2.y);

        // bottom
        glVertex2f(blocks[b].p4.x,blocks[b].p4.y);
        glVertex2f(blocks[b].p3.x+bordersize,blocks[b].p3.y);
        glVertex2f(blocks[b].p4.x-bordersize,blocks[b].p4.y+bordersize);

        glVertex2f(blocks[b].p4.x-bordersize,blocks[b].p4.y+bordersize);
        glVertex2f(blocks[b].p3.x,blocks[b].p3.y);
        glVertex2f(blocks[b].p3.x+bordersize,blocks[b].p3.y++bordersize);

        // left
        glVertex2f(blocks[b].p1.x-bordersize,blocks[b].p1.y-bordersize);
        glVertex2f(blocks[b].p1.x,blocks[b].p1.y);
        glVertex2f(blocks[b].p4.x-bordersize,blocks[b].p4.y+bordersize);

        glVertex2f(blocks[b].p4.x-bordersize,blocks[b].p4.y+bordersize);
        glVertex2f(blocks[b].p1.x,blocks[b].p1.y);
        glVertex2f(blocks[b].p4.x,blocks[b].p4.y);

        // right
        glVertex2f(blocks[b].p2.x,blocks[b].p2.y);
        glVertex2f(blocks[b].p2.x+bordersize,blocks[b].p2.y-bordersize);
        glVertex2f(blocks[b].p3.x,blocks[b].p3.y);

        glVertex2f(blocks[b].p3.x,blocks[b].p3.y);
        glVertex2f(blocks[b].p2.x+bordersize,blocks[b].p2.y-bordersize);
        glVertex2f(blocks[b].p3.x+bordersize,blocks[b].p3.y+bordersize);

      glEnd();
      glEnable(GL_TEXTURE_2D);
    end;
    
  end;

  result:=pointer(0);

  // reset gl to default state here (possible missing or incomplete at mo)
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;

  glDisable(GL_BLEND);
  glDisable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D,0);
  glColor4f(1.0,1.0,1.0,1.0);
end;
//------------------------------------------------------------------------------
procedure TFreeFramePlugin.NewBlock(id:integer);
var
  maxwidth,minwidth:integer;
  maxheight,minheight:integer;
  newwidth,newheight:integer;
  xratio,yratio:single;
  x1,y1,x2,y2:integer;
begin
  Randomize;

  blocks[id].fadestate:=0;

  maxwidth:=round(ViewPortStruct.width*ParameterArray[3]);
  maxheight:=round(ViewPortStruct.height*ParameterArray[3]);

  if ParameterArray[4]<ParameterArray[3] then begin
    minwidth:=round(ViewPortStruct.width*ParameterArray[4]);
    minheight:=round(ViewPortStruct.height*ParameterArray[4]);
  end else begin
    minwidth:=maxwidth;
    minheight:=maxheight;
  end;

  newwidth:=minwidth+random(maxwidth-minwidth);
  newheight:=minheight+random(maxheight-minheight);

  x1:=random(ViewPortStruct.width-newwidth);
  y1:=random(ViewPortStruct.height-newheight);
  x2:=x1+newwidth;
  y2:=y1+newheight;

  blocks[id].p1.x:=x1;blocks[id].p1.y:=y1;
  blocks[id].p2.x:=x2;blocks[id].p2.y:=y1;
  blocks[id].p3.x:=x2;blocks[id].p3.y:=y2;
  blocks[id].p4.x:=x1;blocks[id].p4.y:=y2;

  if ParameterArray[6]=0.0 then begin
    if DisallowOverlap(id,x1,y1,x2,y2) then begin
      // else move off screen
      blocks[id].p1.x:=-2;blocks[id].p1.y:=-2;
      blocks[id].p2.x:=-1;blocks[id].p2.y:=-2;
      blocks[id].p3.x:=-1;blocks[id].p3.y:=-1;
      blocks[id].p4.x:=-2;blocks[id].p4.y:=-1;
      exit;
    end;
  end;

  // should update texture cords, since these may change frame to frame,
  if ParameterArray[9]>0.0 then begin   // funky
    MakeFunky(id);
  end else begin
    blocks[id].p1.u:=0;blocks[id].p1.v:=0;
    blocks[id].p2.u:=1;blocks[id].p2.v:=0;
    blocks[id].p3.u:=1;blocks[id].p3.v:=1;
    blocks[id].p4.u:=0;blocks[id].p4.v:=1;
  end;

  UpdateFilter(id);
end;
//------------------------------------------------------------------------------
// simple version for now
function TFreeFramePlugin.DisallowOverlap(id,x1,y1,x2,y2:integer):boolean;
var
  i:integer;
  oleft,oright,otop,obottom:integer;
  overlapped:boolean;
  dx1,dy1,dx2,dy2:integer;
begin
  overlapped:=false;
  i:=0;
  while ((i<totalblocks) and (not overlapped)) do begin
    if i<>id then begin
      if blocks[i].p1.x<blocks[i].p4.x then dx1:=blocks[i].p1.x else dx1:=blocks[i].p4.x;
      if blocks[i].p2.x>blocks[i].p3.x then dx2:=blocks[i].p2.x else dx2:=blocks[i].p3.x;
      if blocks[i].p1.y<blocks[i].p2.y then dy1:=blocks[i].p1.y else dy1:=blocks[i].p2.y;
      if blocks[i].p4.y>blocks[i].p3.y then dy2:=blocks[i].p4.y else dy2:=blocks[i].p3.y;

      if ((x1>=dx1) and (x1<=dx2)) then overlapped:=true
      else if ((x2>=dx1) and (x2<=dx2)) then overlapped:=true
      else if ((y1>=dy1) and (y1<=dy2)) then overlapped:=true
      else if ((y2>=dy1) and (y2<=dy2)) then overlapped:=true;
    end;
    inc(i);
  end;
  result:=overlapped;
end;
//------------------------------------------------------------------------------
// will be square comming in
procedure TFreeFramePlugin.MakeFunky(id:integer);
var
  funky:integer;
  funkypos:integer;
  funkyamount:single;
  u,v:single;
  xratio,yratio:single;

  p:array[0..3] of integer;
  x1,y1,x2,y2:integer;
  w,h:integer;
begin
  xratio:=1/HardWidth;
  yratio:=1/HardHeight;

  x1:=blocks[id].p1.x;
  y1:=blocks[id].p1.y;
  x2:=blocks[id].p3.x;
  y2:=blocks[id].p3.y;
  w:=x2-x1;
  h:=y2-y1;
  xratio:=1/w;
  yratio:=1/h;
  w:=w div 2;
  h:=h div 2;

  funkyamount:=0.1+ParameterArray[9];
  w:=round(w*funkyamount);
  h:=round(h*funkyamount);

  if funkyamount>=1.0 then funky:=15 else funky:=Random(16);

  if (funky and 1)=1 then begin
    blocks[id].p1.x:=x1+random(w);
    blocks[id].p1.y:=y1+random(h);
    blocks[id].p1.u:=(blocks[id].p1.x-x1)*xratio;
    blocks[id].p1.v:=(blocks[id].p1.y-y1)*yratio;
  end;

  if (funky and 2)=2 then begin
    blocks[id].p2.x:=x2-random(w);
    blocks[id].p2.y:=y1+random(h);
    blocks[id].p2.u:=(blocks[id].p2.x-x1)*xratio;
    blocks[id].p2.v:=(blocks[id].p2.y-y1)*yratio;
  end;

  if (funky and 4)=4 then begin
    blocks[id].p3.x:=x2-random(w);
    blocks[id].p3.y:=y2-random(h);
    blocks[id].p3.u:=(blocks[id].p3.x-x1)*xratio;
    blocks[id].p3.v:=(blocks[id].p3.y-y1)*yratio;
  end;

  if (funky and 8)=8 then begin
    blocks[id].p4.x:=x1+random(w);
    blocks[id].p4.y:=y2-random(h);
    blocks[id].p4.u:=(blocks[id].p4.x-x1)*xratio;
    blocks[id].p4.v:=(blocks[id].p4.y-y1)*yratio;
  end;
end;
//------------------------------------------------------------------------------
procedure TFreeFramePlugin.UpdateFilters;
var
  i:integer;
begin
  for i:=0 to totalblocks-1 do UpdateFilter(i);
end;
//------------------------------------------------------------------------------
procedure TFreeFramePlugin.UpdateFilter(id:integer);
begin
  case floor(ParameterArray[5]*3) of
  0: begin
      blocks[id].r:=1;
      blocks[id].g:=1;
      blocks[id].b:=1;
    end;
  1: begin
      blocks[id].r:=0.25+(random(100)*0.01);
      blocks[id].g:=0.25+(random(100)*0.01);
      blocks[id].b:=0.25+(random(100)*0.01);
    end;
  2: begin
      case floor(random(6)) of
      0: begin blocks[id].r:=1.0;blocks[id].g:=0.0;blocks[id].b:=0.0;end;
      1: begin blocks[id].r:=1.0;blocks[id].g:=1.0;blocks[id].b:=0.0;end;
      2: begin blocks[id].r:=1.0;blocks[id].g:=0.0;blocks[id].b:=1.0;end;
      3: begin blocks[id].r:=0.0;blocks[id].g:=1.0;blocks[id].b:=0.0;end;
      4: begin blocks[id].r:=0.0;blocks[id].g:=1.0;blocks[id].b:=1.0;end;
      5: begin blocks[id].r:=0.0;blocks[id].g:=0.0;blocks[id].b:=1.0;end;
      end;
    end;
  3: begin
      case floor(random(3)) of
      0: begin blocks[id].r:=1.0;blocks[id].g:=0.0;blocks[id].b:=0.0;end;
      1: begin blocks[id].r:=0.0;blocks[id].g:=1.0;blocks[id].b:=0.0;end;
      2: begin blocks[id].r:=0.0;blocks[id].g:=0.0;blocks[id].b:=1.0;end;
      end;
    end;
  end;
end;
//------------------------------------------------------------------------------
function TFreeFramePlugin.SetTime(pParam:pointer):pointer;
begin
  absoluteTime:=double(pParam^);
  if absoluteTime=0 then prevtime:=0;
  result:=pointer(0);
end;
//------------------------------------------------------------------------------

end.
