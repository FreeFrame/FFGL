#ifndef FFGLHeat_H
#define FFGLHeat_H

#include <FFGLShader.h>
#include "../FFGLPluginSDK.h"

class FFGLHeat :
public CFreeFrameGLPlugin
{
public:
	FFGLHeat();
  ~FFGLHeat() {}

	///////////////////////////////////////////////////
	// FreeFrame plugin methods
	///////////////////////////////////////////////////
	
	DWORD	SetParameter(const SetParameterStruct* pParam);		
	DWORD	GetParameter(DWORD dwIndex);					
	DWORD	ProcessOpenGL(ProcessOpenGLStruct* pGL);

	///////////////////////////////////////////////////
	// Factory method
	///////////////////////////////////////////////////

	static DWORD __stdcall CreateInstance(void** ppInstance)
  {
  	*ppInstance = new FFGLHeat();
	  if (*ppInstance != NULL) return FF_SUCCESS;
	  return FF_FAIL;
  }

protected:	
	// Parameters
	float m_Heat;
	float m_HeatY;
	
	int m_initResources;

	GLuint m_heatTextureId;

	FFGLExtensions m_extensions;
    FFGLShader m_shader;
	GLint m_inputTextureLocation;
	GLint m_heatTextureLocation;
	GLint m_maxCoordsLocation;
	GLint m_heatAmountLocation;
};


#endif
