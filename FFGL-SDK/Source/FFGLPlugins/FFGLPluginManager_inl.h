//
// Copyright (c) 2004 - InfoMus Lab - DIST - University of Genova
//
// InfoMus Lab (Laboratorio di Informatica Musicale)
// DIST - University of Genova 
//
// http://www.infomus.dist.unige.it
// news://infomus.dist.unige.it
// mailto:staff@infomus.dist.unige.it
//
// Developer: Gualtiero Volpe
// mailto:volpe@infomus.dist.unige.it
//
// Developer: Trey Harrison
// www.harrisondigitalmedia.com
//
// Last modified: Oct. 26 2006
//


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CFFGLPluginManager inline methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

inline bool CFFGLPluginManager::IsProcessFrameCopySupported() const
{
	return m_bIsProcessFrameCopySupported;
}

inline bool CFFGLPluginManager::IsProcessOpenGLSupported() const
{
	return m_bIsProcessOpenGLSupported;
}

inline DWORD CFFGLPluginManager::GetSupportedFormat() const
{
	return m_dwSupportedFormats;
}

inline DWORD CFFGLPluginManager::GetSupportedOptimization() const
{
	return m_dwSupportedOptimizations;
}

inline int CFFGLPluginManager::GetMinInputs() const
{
	return m_iMinInputs;
}

inline int CFFGLPluginManager::GetMaxInputs() const
{
	return m_iMaxInputs;
}

inline int CFFGLPluginManager::GetNumParams() const
{
	return m_NParams;
}

inline int CFFGLPluginManager::GetFrameWidth() const
{
	return int(m_VideoInfo.FrameWidth);
}

inline int CFFGLPluginManager::GetFrameHeight() const
{
	return int(m_VideoInfo.FrameHeight);
}

inline DWORD CFFGLPluginManager::GetFrameDepth() const
{
	return m_VideoInfo.BitDepth;
}

inline DWORD CFFGLPluginManager::GetFrameOrientation() const
{
	return m_VideoInfo.Orientation;
}
