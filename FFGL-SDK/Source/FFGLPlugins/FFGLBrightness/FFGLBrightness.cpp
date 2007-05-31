#include <FFGL.h>
#include <FFGLLib.h>
#include "FFGLBrightness.h"

#define FFPARAM_BRIGHTNESS (0)

////////////////////////////////////////////////////////////////////////////////////////////////////
//  Plugin information
////////////////////////////////////////////////////////////////////////////////////////////////////

static CFFGLPluginInfo PluginInfo ( 
	FFGLBrightness::CreateInstance,	// Create method
	"GLPT",								// Plugin unique ID
	"FFGLBrightness",     // Plugin name											
	1,						   			// API major version number 													
	000,								  // API minor version number	
	1,										// Plugin major version number
	000,									// Plugin minor version number
	FF_EFFECT,						// Plugin type
	"Sample FFGL Brightness plugin",	// Plugin description
	"by Trey Harrison - www.treyharrison.com" // About
);


////////////////////////////////////////////////////////////////////////////////////////////////////
//  Constructor and destructor
////////////////////////////////////////////////////////////////////////////////////////////////////

FFGLBrightness::FFGLBrightness()
: CFreeFrameGLPlugin()
{
	// Input properties
	SetMinInputs(1);
	SetMaxInputs(1);

	// Parameters
	SetParamInfo(FFPARAM_BRIGHTNESS, "Brightness", FF_TYPE_STANDARD, 0.5f);
	m_brightness = 0.5f;
}

FFGLBrightness::~FFGLBrightness()
{
  
}
////////////////////////////////////////////////////////////////////////////////////////////////////
//  Methods
////////////////////////////////////////////////////////////////////////////////////////////////////

DWORD FFGLBrightness::ProcessOpenGL(ProcessOpenGLStruct *pGL)
{
  if (pGL->numInputTextures<1)
    return FF_FAIL;

  if (pGL->inputTextures[0]==NULL)
    return FF_FAIL;
  
  FFGLTextureStruct &Texture = *(pGL->inputTextures[0]);

  //bind the texture handle to its target
  glBindTexture(Texture.Target, Texture.Handle);

  //enable texturemapping
  glEnable(Texture.Target);

  //get the max s,t that correspond to the 
  //width,height of the used portion of the allocated texture space
  FFGLTexCoords maxCoords = GetMaxGLTexCoords(Texture);

  //set the gl rgb color to the brightness level
  //(default texturemapping behavior of OpenGL is to
  //multiply texture colors by the current gl color)
  glColor4f(m_brightness, m_brightness, m_brightness, 1.0);
  glBegin(GL_QUADS);

  //lower left
  glTexCoord2d(0.0, 0.0);
  glVertex2f(-1,-1);

  //upper left
  glTexCoord2d(0.0, maxCoords.t);
  glVertex2f(-1,1);

  //upper right
  glTexCoord2d(maxCoords.s, maxCoords.t);
  glVertex2f(1,1);

  //lower right
  glTexCoord2d(maxCoords.s, 0.0);
  glVertex2f(1,-1);
  glEnd();

  //unbind the texture
  glBindTexture(Texture.Target, 0);

  //disable texturemapping
  glDisable(Texture.Target);

  return FF_SUCCESS;
}

DWORD FFGLBrightness::GetParameter(DWORD dwIndex)
{
	DWORD dwRet;

	switch (dwIndex) {

	case FFPARAM_BRIGHTNESS:
    //sizeof(DWORD) must == sizeof(float)
    *((float *)(unsigned)(&dwRet)) = m_brightness;
		return dwRet;

	default:
		return FF_FAIL;
	}
}

DWORD FFGLBrightness::SetParameter(const SetParameterStruct* pParam)
{
	if (pParam != NULL) {
		
		switch (pParam->ParameterNumber) {

		case FFPARAM_BRIGHTNESS:
      //sizeof(DWORD) must == sizeof(float)
      m_brightness = *((float *)(unsigned)&(pParam->NewParameterValue));
			break;

		default:
			return FF_FAIL;
		}

		return FF_SUCCESS;
	
	}

	return FF_FAIL;
}
