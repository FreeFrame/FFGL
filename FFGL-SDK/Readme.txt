---------------
FreeFrameGL SDK

Host and Plugin Samples (w/source code) for Windows and OSX
by Trey Harrison - www.harrisondigitalmedia.com

FFGLHeat and FFGLTile Plugins by Edwin De Konig - www.resolume.com

Many .h and .cpp's were taken from the FreeFrame SDK by Gualtiero Volpe (Gualtiero.Volpe@unige.it) and
extended / modified to support the new processing function, ProcessOpenGL.
--------------------------------------------------------------------------

--------------------
Windows Instructions
--------------------

The source code was written and compiled with MSVC++ 2003. The project files probably won't
open with anything older than that.

To test the FFGL host and sample plugins, go to the Binaries folder and run FFGLHost.exe.

You can also drag-and-drop a FFGL .dll onto FFGLHost.exe for testing your own DLL's.

Mouse movement is used to assign values to plugin #1 parameter #0 and plugin #2 parameter #0.

----------------
OSX Instructions
----------------

The source code was written and compiled with XCode 2.4. The project files probably won't
open with anything older than that.

To test the FFGL host and sample plugins, open a terminal window, navigate to the Binaries/OSX
folder, and run ./FFGLHost (for some reason, running FFGLHost from the finder does not work because
the finder doesnt start the application in its own directory)

Mouse movement is used to assign values to plugin #1 parameter #0 and plugin #2 parameter #0.

------------
SDK Contents
------------

Binaries/
  OSX/
    Sample host and plugin files ready to run on OSX

  Win32/
    Sample host and plugin files ready to run on Windows


Include/
  FreeFrame.h
    Slightly modified FreeFrame.h to compile nicely on Win & Mac (no FFGL info in here)

  FFGL.h
    FFGL header

  FFGLExtensions
    Cross-platform OpenGL extension access

  FFGLFbo.h
    Cross-platform Frame Buffer Objects (requires FFGLExtensions)

  FFGLShader.h
    Cross-platform GLSL shader objects (requires FFGLExtensions)


Source/

  Common/

    FFGLExtensions.cpp
    FFGLFBO.cpp
    FFGLShader.cpp
      Implementations of the cross-platform FFGL* helper classes


  FFGLHost/

    FFGLPluginInstance.h/.cpp
      Shared base class for loading and working with FFGL plugin instances

    Timer.h
      Shared base class for accurate timing

    FFDebugMessage.h
      Shared method for sending messages to the debugger

    OSX/
      Files specific to OSX implementation of the host

    Win32/
      Files specific to Win32 implementation of the host


  FFGLPlugins/

    FFGLPluginSDK.h
      Header used by sample plugins to simplify plugin development

    FFGL.cpp
      plugMain handler

    FFGLPluginInfo.h/.cpp
    FFGLPluginInfoData.h/.cpp
    FFGLPluginManager.h/.cpp
      Helper classes adapted from Gualtiero Volpe's SDK


    FFGLBrightness/
    FFGLMirror/
    FFGLTile/
    FFGLHeat/
      Source code for sample plugins


Projects/

  FFGLHost/

    XCode/
      XCode project files for FFGLHost

    MSVC/
      MSVC project files for FFGLHost

  FFGLPlugins/

    MSVC/
      MSVC project files for FFGLPlugins

    XCode/
      XCode project files for FFGLPlugins


