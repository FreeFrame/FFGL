#include "../FFGLPluginInstance.h"
#include "../FFDebugMessage.h"

class WinPluginInstance :
public FFGLPluginInstance
{
public:
  WinPluginInstance();
  
  DWORD Load(const char *filename);
  DWORD Unload();
  
  virtual ~WinPluginInstance();

protected:
  HMODULE m_ffModule;
};

FFGLPluginInstance *FFGLPluginInstance::New()
{
  return new WinPluginInstance();
}

WinPluginInstance::WinPluginInstance()
:m_ffModule(NULL)
{}

DWORD WinPluginInstance::Load(const char *fname)
{
  //warning_printf("FreeFrame Plugin Load Failed: %s", fname);		
  if (fname==NULL || fname[0]==0)
    return FF_FAIL;

  Unload();
	
  m_ffModule = LoadLibrary(fname);

	if (m_ffModule==NULL)
    return FF_FAIL;

	FF_Main_FuncPtr pFreeFrameMain = (FF_Main_FuncPtr)GetProcAddress(m_ffModule, "plugMain");

	if (pFreeFrameMain==NULL)
  {
    FreeLibrary(m_ffModule);
    m_ffModule=NULL;
    return FF_FAIL;
  }
  
  m_ffPluginMain = pFreeFrameMain;

  DWORD rval = InitPluginLibrary();
  if (rval!=FF_SUCCESS)
    return rval;
  
  rval = CreatePluginInstance();

  return rval;
}

DWORD WinPluginInstance::Unload()
{
  DeletePluginInstance();
  DeinitPluginLibrary();
  
  if (m_ffModule!=NULL)
  {
		FreeLibrary(m_ffModule);
		m_ffModule=NULL;
	}

  return FF_SUCCESS;
}

WinPluginInstance::~WinPluginInstance()
{
  if (m_ffModule!=NULL)
  {
    FFDebugMessage("plugin deleted without calling Unload()");
  }
}
