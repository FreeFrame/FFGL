#ifndef FFGLGradients_H
#define FFGLGradients_H

#include "../FFGLPluginSDK.h"
#include "FFGLExtensions.h"


class FFGLGradients : public CFreeFrameGLPlugin
{
public:
	FFGLGradients();
  ~FFGLGradients() {}

	///////////////////////////////////////////////////
	// FreeFrame plugin methods
	///////////////////////////////////////////////////
	
	FFResult	SetFloatParameter(unsigned int index, float value);		
	float		GetFloatParameter(unsigned int index);					
	FFResult	ProcessOpenGL(ProcessOpenGLStruct* pGL);
	FFResult	InitGL(const FFGLViewportStruct *vp);
	FFResult	DeInitGL();

	///////////////////////////////////////////////////
	// Factory method
	///////////////////////////////////////////////////

	static FFResult __stdcall CreateInstance(CFreeFrameGLPlugin **ppOutInstance)
  {
  	*ppOutInstance = new FFGLGradients();
	  if (*ppOutInstance != NULL)
      return FF_SUCCESS;
	  return FF_FAIL;
  }


protected:	

	float m_Hue1;
	float m_Hue2;
	float m_Saturation;
	float m_Brightness;
	
};

void HSVtoRGB(double h, double s, double v, double* r, double* g, double* b);

#endif
