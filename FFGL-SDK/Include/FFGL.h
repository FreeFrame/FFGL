////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FFGL.h
//
// FreeFrame is an open-source cross-platform real-time video effects plugin system.
// It provides a framework for developing video effects plugins and hosts on Windows, 
// Linux and Mac OSX. 
// 
// Copyright (c) 2006 www.freeframe.org
// All rights reserved. 
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FFGL.h by Trey Harrison
// www.harrisondigitalmedia.com
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Redistribution and use in source and binary forms, with or without modification, 
//	are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//  * Neither the name of FreeFrame nor the names of its
//    contributors may be used to endorse or promote products derived
//    from this software without specific prior written permission.
//
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
//	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
//	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
//	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//	DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
//	OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
//	OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
//	OF THE POSSIBILITY OF SUCH DAMAGE. 
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef __FFGL_H__
#define __FFGL_H__

//////////////////////////////////////////////////////////////////////////////////////
// Includes
/////////////////////////////////////////////////////////////////////////////////////

//include the appropriate OpenGL headers for the compiler

#ifdef _WIN32

#include <windows.h>
#include <gl/gl.h>

#else

#ifdef TARGET_OS_MAC
//on osx, <OpenGl/gl.h> auto-includes gl_ext.h for OpenGL extensions, which will interfere
//with the FFGL SDK's own FFGLExtensions headers (included below). this #define disables
//the auto-inclusion of gl_ext.h in OpenGl.h on OSX
#define GL_GLEXT_LEGACY
#include <OpenGL/gl.h>

#else

#error define this for your OS

#endif
#endif

/////////////////////////////////////////////////////////////////////////////
//FreeFrameGL defines numerically extend FreeFrame defines (see FreeFrame.h)
/////////////////////////////////////////////////////////////////////////////
#include "FreeFrame.h"

// Function codes
#define FF_PROCESSOPENGL          17

// Plugin capabilities
#define FF_CAP_PROCESSOPENGL      4

//FFGLTextureStruct (for ProcessOpenGLStruct)
typedef struct FFGLTextureStructTag
{
  DWORD Width, Height, Depth;
  DWORD HardwareWidth, HardwareHeight, HardwareDepth;
  GLuint Target; //GL_TEXTURE_1D, GL_TEXTURE_2D, GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_3D, maybe more?
  GLuint Handle; //the actual texture handle, from glGenTextures()
} FFGLTextureStruct;

// ProcessOpenGLStruct
typedef struct ProcessOpenGLStructTag {
  DWORD numInputTextures;
  FFGLTextureStruct **inputTextures;
} ProcessOpenGLStruct;

//FFGLTexCoords (for helper function below)
typedef struct FFGLTexCoordsTag
{
  GLdouble s,t,r;
} FFGLTexCoords;

//helper function to return the s,t,r coordinate
//that cooresponds to the width,height,depth of the used
//portion of the texture
static FFGLTexCoords GetMaxGLTexCoords(FFGLTextureStruct t)
{
  //these are some basic OpenGL extensions we need 
  const GLuint _GL_TEXTURE_3D = 0x806F;
  
  //if other code uses RECTANGLE_ARB or RECTANGLE_NV in t.Target,
  //it should be compatible because the numeric values for _NV and
  //_ARB are the same as _EXT
  const GLuint _GL_TEXTURE_RECTANGLE_EXT = 0x84F5;

  FFGLTexCoords texCoords;

  //the texture may only occupy a portion
  //of the allocated hardware texture memory. and, depending
  //on the texture target, the coordinate range may be
  //(0..1), (0..1)  - or (0..width), (0..Height)
  switch (t.Target)
  {
  case GL_TEXTURE_1D:
    //normalized (0..1) coords
    texCoords.s = ((GLdouble)t.Width) / (GLdouble)t.HardwareWidth;
    texCoords.t = 0.0;
    texCoords.r = 0.0;
    break;

  case GL_TEXTURE_2D:
    //normalized (0..1) S and T coords
    texCoords.s = ((GLdouble)t.Width) / (GLdouble)t.HardwareWidth;
    texCoords.t = ((GLdouble)t.Height) / (GLdouble)t.HardwareHeight;
    texCoords.r = 0.0;
    break;
    
  case _GL_TEXTURE_RECTANGLE_EXT:
    //non-normalized (0..width), (0..height) S and T coords
    texCoords.s = (GLdouble)t.Width;
    texCoords.t = (GLdouble)t.Height;
    texCoords.r = 0.0;
    break;

  case _GL_TEXTURE_3D:
    //normalized (0..1) coords
    texCoords.s = ((GLdouble)t.Width) / (GLdouble)t.HardwareWidth;
    texCoords.t = ((GLdouble)t.Height) / (GLdouble)t.HardwareHeight;
    texCoords.r = ((GLdouble)t.Depth) / (GLdouble)t.HardwareDepth;
    break;

  default:
    //unknown target
    texCoords.s = 0.0;
    texCoords.t = 0.0;
    texCoords.r = 0.0;
    break;
  }

  return texCoords;
}

#endif