#include <FFGLFBO.h>
#include "../FFGLPluginInstance.h"
#include "../Timer.h"
#include "../FFDebugMessage.h"
#include "AVIReader.h"
#include <math.h>

//Globals
HINSTANCE g_hinst; // the process/application "instance"
HWND      g_hwnd;  // the output window
HGLRC     g_glrc;  // the opengl rendering context

//when the mouse moves, these values are updated according to the
//x/y position of the mosue. (0,0) corresponds to the lower left
//corner of the window, (1,1) corresponds to the upper right. the
//mouse values are then assigned to the plugins each time they draw
//x -> plugin 1 parameter 0
//y -> plugin 2 parameter 0
float mouseX = 0.5;
float mouseY = 0.5;

//window create function
BOOL CreateOpenGLWindow();

//texture allocate function
//(can only be called when there is an active opengl rendering context)
FFGLTextureStruct CreateOpenGLTexture(int textureWidth, int textureHeight);

//these are the default filenames used to load into the above plugin handlers
#ifdef _DEBUG
  const char *FFGLBrightnessFile = "FFGLBrightness_debug.dll";
  const char *FFGLMirrorFile     = "FFGLMirror_debug.dll";
  const char *FFGLTileFile       = "FFGLTile_debug.dll";
  const char *FFGLHeatFile       = "FFGLHeat_debug.dll";
#else
  const char *FFGLBrightnessFile = "FFGLBrightness.dll";
  const char *FFGLMirrorFile     = "FFGLMirror.dll";
  const char *FFGLTileFile       = "FFGLTile.dll";
  const char *FFGLHeatFile       = "FFGLHeat.dll";
#endif

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
  //store global instance handle
  g_hinst = hInstance;

  //init VideoForWindows
  WORD wVer = HIWORD(VideoForWindowsVersion());
  if (wVer>=0x010A)
    AVIFileInit();
  else
    return 0;

  //open the avi file 
  Win32AVIFile aviFile;
  if (!aviFile.LoadAVI("FFGLTest.avi"))
  {
    FFDebugMessage("AVI Init Failed");
    return 0;
  }

  //default for plugin file 1
  const char *pluginFile1 = FFGLBrightnessFile;

  //default for plugin file 2
  const char *pluginFile2 = FFGLTileFile;

  //if a plugin is provided on the command line this will be set to 1
  //and pluginFile2 will point to the name of the file on the command line
  int usingCustomPlugin = 0; 

  //see if a .dll is given on the command line
  if (szCmdLine!=NULL && szCmdLine[0]!=0 &&
      strstr(szCmdLine,".dll")!=NULL)
  {    
    //if there's quotes (probably from dragging-and-dropping with windows explorer)
    //around the .dll filename, avoid them
    if (szCmdLine[0]=='"')
      szCmdLine++;

    if (szCmdLine[strlen(szCmdLine)-1]=='"')
      szCmdLine[strlen(szCmdLine)-1] = 0;

    //use it in place of the 2nd plugin
    pluginFile2 = szCmdLine;
    usingCustomPlugin = 1;    
  }

  //init first plugin
  FFGLPluginInstance *plugin1 = FFGLPluginInstance::New();
  if (plugin1->Load(pluginFile1)==FF_FAIL)
  {
    FFDebugMessage("Couldn't open Brightness plugin .dll");
    return 0;
  }

  //init second plugin
  FFGLPluginInstance *plugin2 = FFGLPluginInstance::New();
  if (plugin2->Load(pluginFile2)==FF_FAIL)
  {
    FFDebugMessage("Couldn't open plugin .dll #2");
    return 0;
  }

  //create our window
  if (!CreateOpenGLWindow())
  {
    FFDebugMessage("Window Open Failed");
    return 0;
  }
  
  //////////////////
  //gl init
  /////////////////

  //to do the rest of the GL initialization, we have to have an active
  //GL context. so, activate rendering to the window
  
  //get the window's display context
  HDC hdc = GetDC(g_hwnd);
  
  //activate gl rendering to the window
  wglMakeCurrent(hdc, g_glrc);

  //first thing, we need to initialize the
  //gl extensions (without the extensions we can't do
  //swap control or framebuffer objects)
  FFGLExtensions glExtensions;

  glExtensions.Initialize();
  if (glExtensions.EXT_framebuffer_object==0)
  {
    FFDebugMessage("FBO not detected, cannot continue");
    return 0;
  }

  //set swap control so that the framerate is capped
  //at the monitor refresh rate
  if (glExtensions.WGL_EXT_swap_control)
    glExtensions.wglSwapIntervalEXT(1);

  //create the frame buffer object for intermediate / offscreen
  //rendering - make it the same size as the window
  RECT clientRect;
  GetClientRect(g_hwnd, &clientRect);
  int fboWidth = clientRect.right - clientRect.left;
  int fboHeight = clientRect.bottom - clientRect.top;

  FFGLFBO fbo;

  if (!fbo.Create(fboWidth, fboHeight, glExtensions))
  {
    FFDebugMessage("Framebuffer Object Init Failed");
    return 0;
  }

  //allocate a texture for the video stream
  FFGLTextureStruct aviTexture;

  aviTexture = CreateOpenGLTexture(aviFile.GetWidth(),aviFile.GetHeight());
  if (aviTexture.Handle==0)
  {
    FFDebugMessage("Texture allocation failed");
    return 0;
  }
  
  //deactivate rendering to the window
  wglMakeCurrent(NULL,NULL);

  //release the window's display context
  ReleaseDC(g_hwnd, hdc);

  //////////////////
  //end of gl init
  /////////////////

  //////////////
  //main loop
  //////////////
  int keepRunning = 1;

  //start the timer
  Timer *time = Timer::New();

  while (keepRunning)
  {
    //get the window's display context
    HDC hdc = GetDC(g_hwnd);

    //activate gl rendering to the window
    wglMakeCurrent(hdc, g_glrc);

    //whats the current time on the timer?
    double curFrameTime = time->GetElapsedTime();

    //get the next frame from the avi
    int curFrame = (int)(curFrameTime * aviFile.GetFramerate());
    void *bitmapData = aviFile.GetFrameData(curFrame);

    //bind the gl texture so we can upload the next video frame
    glBindTexture(aviTexture.Target, aviTexture.Handle);

    //upload it to the gl texture. use subimage because
    //the video frame size is probably smaller than the
    //size of the texture on the gpu hardware
    glTexSubImage2D(aviTexture.Target, 0,
                    0, 0,
                    aviFile.GetWidth(),
                    aviFile.GetHeight(),
                    GL_BGR_EXT,
                    GL_UNSIGNED_BYTE,
                    bitmapData);

    //unbind the gl texture
    glBindTexture(aviTexture.Target, 0);

    //activate the fbo as our render target
    if (!fbo.BindAsRenderTarget(glExtensions))
    {
      FFDebugMessage("FBO Bind As Render Target Failed");
      return 0;
    }

    //set the gl viewport to equal the size of the FBO
    glViewport(0,0, fbo.GetWidth(), fbo.GetHeight());

    //prepare gl state for rendering the first plugin (brightness)
    
    //make sure all the matrices are reset
    glMatrixMode(GL_TEXTURE);
    glLoadIdentity();
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    //clear the depth and color buffers
    glClearColor(0,0,0,0);
    glClearDepth(1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    //plugin 1 parameter #0 is mouse X
    plugin1->SetFloatParameter(0, mouseX);

    //prepare the structure used to call
    //the plugin's ProcessOpenGL method
    ProcessOpenGLStructTag processStruct;
  
    //provide the 1 input texture we allocated above
    processStruct.numInputTextures = 1;
    
    //create the array of OpenGLTextureStruct * to be passed
    //to the plugin
    FFGLTextureStruct *inputTextures[1];
    inputTextures[0] = &aviTexture;
    
    processStruct.inputTextures = inputTextures;

    //call the plugin's ProcessOpenGL
    if (plugin1->CallProcessOpenGL(processStruct)==FF_SUCCESS)
    {
      //if the plugin call succeeds, the drawning is complete
    }
    else
    {
      //the plugin call failed, exit
      FFDebugMessage("Plugin 1's ProcessOpenGL failed");
      return 0;
    }

    //deactivate rendering to the fbo
    //(this re-activates rendering to the window)
    fbo.UnbindAsRenderTarget(glExtensions);

    //set the gl viewport to equal the size of our output window
    RECT clientRect;
    GetClientRect(g_hwnd, &clientRect);
    int viewportWidth = clientRect.right - clientRect.left;
    int viewportHeight = clientRect.bottom - clientRect.top;

    glViewport(0, 0, viewportWidth, viewportHeight);

    //prepare to render the 2nd plugin (the mirror effect or the custom plugin)

    //reset all matrices
    glMatrixMode(GL_TEXTURE);
    glLoadIdentity();
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    //clear the color and depth buffers
    glClearColor(0,0,0,0);
    glClearDepth(1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    //now pass the contents of the FBO as a texture to the mirror plugin
    FFGLTextureStruct fboTexture = fbo.GetTextureInfo();

    //all we need to change in our processStruct
    //is where texture #0 points to (now it points to the FBO texture)
    inputTextures[0] = &fboTexture;

    //plugin 2 parameter #0 is mouse Y
    plugin2->SetFloatParameter(0, mouseY);

    //call the mirror plugin's ProcessOpenGL
    if (plugin2->CallProcessOpenGL(processStruct)==FF_SUCCESS)
    {
      //if the plugin call succeeds, the drawning is complete
    }
    else
    {
      //the plugin call failed, exit
      FFDebugMessage("Plugin 2's ProcessOpenGL failed");
      return 0;
    }
        
    //swapbuffers tells opengl to finish all of the pending
    //drawing instructions (which are to the "back" buffer)
    //and copy/swap them to the front buffer
    SwapBuffers(hdc);

    //deactivate rendering to the window
    wglMakeCurrent(NULL,NULL);

    //release the window's display context
    ReleaseDC(g_hwnd, hdc);

    //dispatch any pending windows msgs
    MSG msg;
    while (PeekMessage(&msg, 0, 0, 0, PM_REMOVE))
    {
      if (msg.message != WM_QUIT &&
          msg.message != WM_NULL)
      {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
      }
      else
      {
        keepRunning = 0;
        break;
      }
    }
  }

  //TODO: release the remaining gl resources
  //(aviTexture, fbo, plus whatever the plugins have allocated)
  //this is tricky because most of the gl resources require
  //an active gl context in order to free them.

  //delete the gl rendering context
  wglDeleteContext(g_glrc);

  //close the avi file
  aviFile.ReleaseAVI();

  //release the plugin dlls
  plugin1->Unload();
  delete plugin1;

  plugin2->Unload();
  delete plugin2;

  //release the timer
  delete time;

  //shutdown video for windows services
  AVIFileExit();

  return 0;
}

LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  RECT r;
  signed short mx,my;

  switch (message)
  {
  case WM_PAINT:
    //this basically ignores WM_PAINT because we
    //already redraw the whole window every frame in the main loop
    GetUpdateRect(hWnd, &r, 0);
    ValidateRect(hWnd, NULL);
    break;

  case WM_MOUSEMOVE:
    //be carefule using ints instead of shorts.. you would 
    //need to sign-extend mx and my with these macros
    mx = LOWORD(lParam);
    my = HIWORD(lParam);
    
    GetClientRect(hWnd, &r);

    if (mx<r.left) mx=r.left;
    else
    if (mx>r.right) mx = r.right;
    
    if (my<r.top) my=r.top;
    else
    if (my>r.bottom) mx = r.bottom;
    
    mouseX = (double)(mx - r.left) / (double)((r.right - r.left)-1);
    mouseY = 1.0 - ((double)(my - r.top) / (double)((r.bottom - r.top)-1));

    break;

  case WM_DESTROY:
    PostQuitMessage(0);
    break;

  default:
    return DefWindowProc(hWnd, message, wParam, lParam);
  }
  return 0;
}

void RegisterOpenGLWindowClass()
{
  static int alreadyRegistered = 0;
  
  if (alreadyRegistered)
    return;
  else
    alreadyRegistered = 1;

  WNDCLASSEX wcex;

  wcex.cbSize = sizeof(WNDCLASSEX);

  wcex.style = CS_OWNDC;
  wcex.lpfnWndProc = (WNDPROC)WndProc;
  wcex.cbClsExtra = 0;
  wcex.cbWndExtra = 0;
  wcex.hInstance = g_hinst;
  wcex.hIcon = NULL;
  wcex.hCursor = LoadCursor(NULL,IDC_ARROW);
  wcex.hbrBackground = NULL;
  wcex.lpszMenuName = NULL;
  wcex.lpszClassName = "FFGLHostWindowClass";
  wcex.hIconSm = NULL;

  RegisterClassEx(&wcex);
}

BOOL CreateOpenGLWindow()
{
  //before we create the window we have to register the "class" of the
  //window with the OS
  RegisterOpenGLWindowClass();

  g_hwnd = CreateWindow("FFGLHostWindowClass", "FFGL Host Sample", WS_OVERLAPPEDWINDOW,
     CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, NULL, NULL, g_hinst, NULL);

  if (!g_hwnd)
    return FALSE;

  //now we have to jump through some hoops to make the window support OpenGL
  HDC hdc = GetDC(g_hwnd);

  //get the bits-per-pixel of the window's device context (hdc).
  //hopefully its 32.. but the code should work with 24 or 16
  int hdc_bpp = GetDeviceCaps(hdc, BITSPIXEL);   
  
  int zBufferDepth = 16;

  PIXELFORMATDESCRIPTOR pfd;  
  memset(&pfd, 0, sizeof(PIXELFORMATDESCRIPTOR));  
  pfd.nSize = sizeof(PIXELFORMATDESCRIPTOR);  
  pfd.nVersion = 1;

  pfd.dwFlags = PFD_DOUBLEBUFFER |
                PFD_DRAW_TO_WINDOW |
                PFD_SUPPORT_OPENGL;
  
  pfd.iPixelType = PFD_TYPE_RGBA;
  pfd.cColorBits = hdc_bpp;
  pfd.cDepthBits = zBufferDepth;
  pfd.cAccumBits = 0;
  pfd.cStencilBits = 0;
  pfd.iLayerType = PFD_MAIN_PLANE;

  //only request 8 bits of alpha if the context supports 32bit pixels
  if (hdc_bpp==32)
    pfd.cAlphaBits = 8;
  else
    pfd.cAlphaBits = 0;

  int iPixelFormat = ChoosePixelFormat(hdc, &pfd); 
 
  //reset pfd for usage below
  memset(&pfd, 0, sizeof(PIXELFORMATDESCRIPTOR));  
  pfd.nSize = sizeof(PIXELFORMATDESCRIPTOR);
  pfd.nVersion = 1;

  if (DescribePixelFormat(hdc,
                          iPixelFormat,
                          sizeof(PIXELFORMATDESCRIPTOR),
                          &pfd))
  {
    if ((pfd.dwFlags & PFD_SUPPORT_OPENGL)==0)
    {
      FFDebugMessage("Can't support OpenGL");
      return FALSE;
    }
  }

  DWORD result = SetPixelFormat(hdc, iPixelFormat, &pfd);

  if (!result)
    return FALSE;

  //create the gl rendering context for the window
  g_glrc = wglCreateContext(hdc);

  if (g_glrc==NULL)
    return FALSE;

  //release the window's display context
  ReleaseDC(g_hwnd,hdc);

  ShowWindow(g_hwnd, SW_SHOWNORMAL);
  UpdateWindow(g_hwnd);

  return TRUE;
}

FFGLTextureStruct CreateOpenGLTexture(int textureWidth, int textureHeight)
{
  //note - there must be an active opengl context when this is called
  //ie, wglMakeCurrent(someHDC, someHGLRC)

  //find smallest power of two sized
  //texture that can contain the texture  
  int glTextureWidth = 1;
  while (glTextureWidth<textureWidth) glTextureWidth *= 2;

  int glTextureHeight = 1;
  while (glTextureHeight<textureHeight) glTextureHeight *= 2;

  //create and setup the gl texture
  GLuint glTextureHandle = 0;
  glGenTextures(1, &glTextureHandle);

  //bind this new texture so that glTex* calls apply to it
  glBindTexture(GL_TEXTURE_2D, glTextureHandle);
  
  //use bilinear interpolation when the texture is scaled larger
  //than its true size
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  
  //no mipmapping (for when the texture is scaled smaller than its
  //true size)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

  //no wrapping (for when texture coordinates reference outside the
  //bounds of the texture)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);

  //this allocates room for the gl texture, but doesn't fill it with any pixels
  //(the NULL would otherwise contain a pointer to the texture data)
  glTexImage2D(GL_TEXTURE_2D,
               0, 3, //we assume a 24bit image, which has 3 bytes per pixel
               glTextureWidth,
               glTextureHeight,
               0, GL_BGR_EXT,
               GL_UNSIGNED_BYTE,
               NULL);

  //unbind the texture
  glBindTexture(GL_TEXTURE_2D, 0);
  
  //fill the OpenGLTextureStruct
  FFGLTextureStruct t;

  t.Handle = glTextureHandle;
  t.Target = GL_TEXTURE_2D;

  t.Width = textureWidth;
  t.Height = textureHeight;
  
  t.HardwareWidth = glTextureWidth;
  t.HardwareHeight = glTextureHeight;

  t.Depth = 1;
  t.HardwareDepth = 1;

  return t;
}