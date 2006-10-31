#ifndef FFGLTile_H
#define FFGLTile_H

#include <FFGLShader.h>
#include "../FFGLPluginSDK.h"

class FFGLTile :
public CFreeFrameGLPlugin
{
public:
  FFGLTile();
  ~FFGLTile() {}

	///////////////////////////////////////////////////
	// FreeFrame plugin methods
	///////////////////////////////////////////////////
	
	DWORD	SetParameter(const SetParameterStruct* pParam);		
	DWORD	GetParameter(DWORD dwIndex);					
	DWORD	ProcessOpenGL(ProcessOpenGLStruct *pGL);

	///////////////////////////////////////////////////
	// Factory method
	///////////////////////////////////////////////////

	static DWORD __stdcall CreateInstance(void** ppInstance)
    {
  	  *ppInstance = new FFGLTile();
	  if (*ppInstance != NULL) return FF_SUCCESS;
	  return FF_FAIL;
    }

protected:	
	// Parameters
	float m_TileX;
	float m_TileY;
	
	int m_initResources;
	FFGLExtensions m_extensions;
    FFGLShader m_shader;
	GLint m_inputTextureLocation;
	GLint m_maxCoordsLocation;
	GLint m_tileAmountLocation;
};


#endif
