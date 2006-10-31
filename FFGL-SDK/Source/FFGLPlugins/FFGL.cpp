////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FFGL.cpp
//
// FreeFrame is an open-source cross-platform real-time video effects plugin system.
// It provides a framework for developing video effects plugins and hosts on Windows, 
// Linux and Mac OSX. 
// 
// FreeFrameGL (FFGL) is an extension to the FreeFrame spec to support video processing
// with OpenGL on Windows, Linux, and Mac OSX.
//
// Copyright (c) 2002, 2003, 2004, 2006 www.freeframe.org
// All rights reserved. 
//
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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// First version, Marcus Clements (marcus@freeframe.org) 
// www.freeframe.org
//
// FreeFrame 1.0 upgrade by Russell Blakeborough
// email: boblists@brightonart.org
//
// FreeFrame 1.0 - 03 upgrade 
// and implementation of FreeFrame SDK methods by Gualtiero Volpe
// email: Gualtiero.Volpe@poste.it
//
// FFGL upgrade by Trey Harrison
// email: trey@harrisondigitalmedia.com
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Includes 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "FFGLPluginSDK.h"
#include <memory.h>

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Static and extern variables used in the FreeFrame SDK 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

extern CFFGLPluginInfo* g_CurrPluginInfo;

static CFreeFrameGLPlugin* s_pPrototype = NULL;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FreeFrame SDK default implementation of the FreeFrame global functions. 
// Such function are called by the plugMain function, the only function a plugin exposes.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void *getInfo() 
{
	return (void *)(g_CurrPluginInfo->GetPluginInfo());
}

DWORD initialise()
{
	if ((g_CurrPluginInfo != NULL) && (s_pPrototype == NULL)) {
		DWORD dwRet = (*(g_CurrPluginInfo->GetFactoryMethod()))((void**)&s_pPrototype);
		return dwRet;
	}
	if (s_pPrototype != NULL) return FF_SUCCESS; 
	else return FF_FAIL;
}

DWORD deInitialise()
{
	if (s_pPrototype != NULL) {
		delete s_pPrototype;
		s_pPrototype = NULL;
	}
	return FF_SUCCESS;
}

DWORD getNumParameters() 
{
	if (s_pPrototype == NULL) {
		DWORD dwRet = initialise();
		if (dwRet == FF_FAIL) return FF_FAIL;
	}

	return (DWORD) s_pPrototype->GetNumParams();
}
							
char* getParameterName(DWORD index)
{
	if (s_pPrototype == NULL) {
		DWORD dwRet = initialise();
		if (dwRet == FF_FAIL) return NULL;
	}
	
	return s_pPrototype->GetParamName(index);
}

DWORD getParameterDefault(DWORD index)
{
	if (s_pPrototype == NULL) {
		DWORD dwRet = initialise();
		if (dwRet == FF_FAIL) return FF_FAIL;
	}

	void* pValue = s_pPrototype->GetParamDefault(index);
	if (pValue == NULL) return FF_FAIL;
	else {
		DWORD dwRet;
		memcpy(&dwRet, pValue, 4);
		return dwRet;
	}
}

DWORD getPluginCaps(DWORD index)
{
	int MinInputs = -1;
	int MaxInputs = -1;

	if (s_pPrototype == NULL) {
		DWORD dwRet = initialise();
		if (dwRet == FF_FAIL) return FF_FAIL;
	}

	switch (index) {

	case FF_CAP_16BITVIDEO:
		if (s_pPrototype->GetSupportedFormat() & CFFGLPluginManager::FF_RGB_16) return FF_TRUE;
		return FF_FALSE;

	case FF_CAP_24BITVIDEO:
		if (s_pPrototype->GetSupportedFormat() & CFFGLPluginManager::FF_RGB_24) return FF_TRUE;
		return FF_FALSE;

	case FF_CAP_32BITVIDEO:
		if (s_pPrototype->GetSupportedFormat() & CFFGLPluginManager::FF_RGB_32) return FF_TRUE;
		return FF_FALSE;

	case FF_CAP_PROCESSFRAMECOPY:
		if (s_pPrototype->IsProcessFrameCopySupported()) return FF_TRUE;
		return FF_FALSE;

  case FF_CAP_PROCESSOPENGL:
		if (s_pPrototype->IsProcessOpenGLSupported()) return FF_TRUE;
		return FF_FALSE;

	case FF_CAP_MINIMUMINPUTFRAMES:
		MinInputs = s_pPrototype->GetMinInputs();
		if (MinInputs < 0) return FF_FALSE;
		return DWORD(MinInputs);

	case FF_CAP_MAXIMUMINPUTFRAMES:
		MaxInputs = s_pPrototype->GetMaxInputs();
		if (MaxInputs < 0) return FF_FALSE;
		return DWORD(MaxInputs);

	case FF_CAP_COPYORINPLACE:
		if (s_pPrototype->GetSupportedFormat() & CFFGLPluginManager::FF_OPT_NONE)
			return FF_CAP_PREFER_NONE;
		else if (s_pPrototype->GetSupportedFormat() & CFFGLPluginManager::FF_OPT_INPLACE)
			return FF_CAP_PREFER_INPLACE;
		else if (s_pPrototype->GetSupportedFormat() & CFFGLPluginManager::FF_OPT_COPY)
			return FF_CAP_PREFER_COPY;
		else if (s_pPrototype->GetSupportedFormat() & CFFGLPluginManager::FF_OPT_BOTH)
			return FF_CAP_PREFER_BOTH;
		else
			return FF_FALSE;

	default:
		return FF_FALSE;
	}
	
	return FF_FAIL;
}

void *getExtendedInfo()
{
	return (void *)(g_CurrPluginInfo->GetPluginExtendedInfo());
}

DWORD getParameterType(DWORD index)
{
	if (s_pPrototype == NULL) {
		DWORD dwRet = initialise();
		if (dwRet == FF_FAIL) return FF_FAIL;
	}
	
	return s_pPrototype->GetParamType(index);
}

DWORD instantiate(const VideoInfoStruct* pVideoInfo)
{
	if (g_CurrPluginInfo != NULL) {

		// If the plugin is not initialized, initialize it
		if (s_pPrototype == NULL) {
			DWORD dwRet = initialise();
			if ((dwRet == FF_FAIL) || (s_pPrototype == NULL)) return FF_FAIL;
		}
		
		// Creating plugin instance
		CFreeFrameGLPlugin* pInstance = NULL;
		DWORD dwRet = (*(g_CurrPluginInfo->GetFactoryMethod()))((void**)&pInstance);
		if ((dwRet == FF_FAIL) || (pInstance == NULL)) return FF_FAIL;
		pInstance->m_pPlugin = pInstance;
		
		// Initializing instance with default values
		for (int i = 0; i < s_pPrototype->GetNumParams(); ++i) {
			DWORD dwType = s_pPrototype->GetParamType(DWORD(i));
			void* pValue = s_pPrototype->GetParamDefault(DWORD(i));
			SetParameterStruct ParamStruct;
			ParamStruct.ParameterNumber = DWORD(i);
			memcpy(&ParamStruct.NewParameterValue, pValue, 4);
			dwRet = pInstance->SetParameter(&ParamStruct);
			if (dwRet == FF_FAIL) return FF_FAIL;
		}

		// Saving data in the VideoInfoStruct in an internal data structure
		pInstance->SetVideoInfo(pVideoInfo);

		return DWORD(pInstance);
	}
	return FF_FAIL;
}

DWORD deInstantiate(void *instanceID)
{
	if ((CFreeFrameGLPlugin*)instanceID != NULL)
  {
		delete (CFreeFrameGLPlugin *)instanceID;
		instanceID = NULL;
		return FF_SUCCESS;
	}
	return FF_FAIL;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Implementation of plugMain, the one and only exposed function
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifdef WIN32

   plugMainUnion __stdcall plugMain(DWORD functionCode, DWORD inputValue, DWORD instanceID) 

#elif TARGET_OS_MAC

   plugMainUnion plugMain(DWORD functionCode, DWORD inputValue, DWORD instanceID) 

#elif LINUX

extern "C" {
   plugMainUnion plugMain(DWORD functionCode, DWORD inputValue, DWORD instanceID)
   
#endif	

{
	plugMainUnion retval;

	// declare pPlugObj - pointer to this instance
	CFreeFrameGLPlugin* pPlugObj;

	// typecast DWORD into pointer to a CFreeFrameGLPlugin
	pPlugObj = (CFreeFrameGLPlugin*) instanceID;

	switch (functionCode) {

	case FF_GETINFO:
		retval.PISvalue = (PluginInfoStruct*)getInfo();
		break;

	case FF_INITIALISE:
		retval.ivalue = initialise();
		break;

	case FF_DEINITIALISE:
		retval.ivalue = deInitialise();	
		break;

	case FF_GETNUMPARAMETERS:
		retval.ivalue = getNumParameters();
		break;

	case FF_GETPARAMETERNAME:
		retval.svalue = getParameterName(inputValue);
		break;
	
	case FF_GETPARAMETERDEFAULT:
		retval.ivalue = getParameterDefault(inputValue);
		break;

	case FF_GETPLUGINCAPS:
		retval.ivalue = getPluginCaps(inputValue);
		break;

	case FF_GETEXTENDEDINFO: 
		retval.ivalue = (DWORD) getExtendedInfo();
		break;

	case FF_GETPARAMETERTYPE:		
		retval.ivalue = getParameterType(inputValue);
		break;

	case FF_PROCESSFRAME:
		if (pPlugObj != NULL)
			retval.ivalue = pPlugObj->ProcessFrame((void*)inputValue);
		else
			retval.ivalue = FF_FAIL;
		break;

	case FF_GETPARAMETERDISPLAY:
		if (pPlugObj != NULL) 
			retval.svalue = pPlugObj->GetParameterDisplay(inputValue);
		else
			retval.svalue = (char*)FF_FAIL;
		break;
		
	case FF_SETPARAMETER:
		if (pPlugObj != NULL)
			retval.ivalue = pPlugObj->SetParameter((const SetParameterStruct*) inputValue);
		else
			retval.ivalue = FF_FAIL;
		break;
	
	case FF_GETPARAMETER:
		if (pPlugObj != NULL) 
			retval.ivalue = pPlugObj->GetParameter(inputValue);
		else 
			retval.ivalue = FF_FAIL;
		break;
	
	case FF_INSTANTIATE:
		retval.ivalue = (DWORD) instantiate((const VideoInfoStruct*) inputValue);
		break;
	
	case FF_DEINSTANTIATE:
		if (pPlugObj != NULL)
			retval.ivalue = deInstantiate(pPlugObj);
		else
			retval.ivalue = FF_FAIL;
		break;

	case FF_PROCESSFRAMECOPY:
		if (pPlugObj != NULL)
			retval.ivalue = pPlugObj->ProcessFrameCopy((ProcessFrameCopyStruct*) inputValue);
		else
			retval.ivalue = FF_FAIL;
		break;
	
	case FF_GETIPUTSTATUS:
		if (pPlugObj != NULL)
			retval.ivalue = pPlugObj->GetInputStatus(inputValue);
		else
			retval.ivalue = FF_FAIL;
		break;

  case FF_PROCESSOPENGL:
    if (pPlugObj != NULL)
    {
      ProcessOpenGLStruct *pogls = (ProcessOpenGLStruct *)inputValue;
      if (pogls!=NULL)
        retval.ivalue = pPlugObj->ProcessOpenGL(pogls);
      else
        retval.ivalue = FF_FAIL;
    }
		else
			retval.ivalue = FF_FAIL;
		break;

	default:
		retval.ivalue = FF_FAIL;
		break;
	}
	
	return retval;
}

#ifdef LINUX	
} /* extern "C" */
#endif
