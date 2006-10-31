#ifndef FFGLMirror_H
#define FFGLMirror_H

#include "../FFGLPluginSDK.h"

class FFGLMirror :
public CFreeFrameGLPlugin
{
public:
	FFGLMirror();
  ~FFGLMirror() {}

	///////////////////////////////////////////////////
	// FreeFrame plugin methods
	///////////////////////////////////////////////////
	
	DWORD	ProcessOpenGL(ProcessOpenGLStruct* pGL);

	///////////////////////////////////////////////////
	// Factory method
	///////////////////////////////////////////////////

	static DWORD __stdcall CreateInstance(void** ppInstance)
  {
  	*ppInstance = new FFGLMirror();
	  if (*ppInstance != NULL) return FF_SUCCESS;
	  return FF_FAIL;
  }
};


#endif
