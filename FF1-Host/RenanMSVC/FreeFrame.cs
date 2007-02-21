/// 
/// FreeFrame C# .NET Wrapper by Ben Baker
/// 

using System;
using System.Runtime.InteropServices;
using System.Drawing;
using System.Drawing.Imaging;

public class FreeFrame : IDisposable
{
	[StructLayout(LayoutKind.Sequential,CharSet=CharSet.Ansi)]
		private struct PluginInfoStruct
	{
		public uint APIMajorVersion;		// 32-bit unsigned integer
		public uint APIMinorVersion;		// 32-bit unsigned integer
		[MarshalAs(UnmanagedType.ByValArray,SizeConst=4)]
		public byte[] PluginUniqueID;	// 4 1-byte ASCII characters *not null terminated*
		[MarshalAs(UnmanagedType.ByValArray,SizeConst=16)]
		public byte[] PluginName;		// 16 1-byte ASCII characters *not null terminated*
		public uint PluginType;			// 32-bit unsigned integer
	}

	[StructLayout(LayoutKind.Sequential,CharSet=CharSet.Ansi)]
		private struct VideoInfoStruct
	{
		public uint FrameWidth;		// 32-bit unsigned integer
		public uint FrameHeight;		// 32-bit unsigned integer
		public uint BitDepth;		// 32-bit unsigned integer
		public uint Orientation;		// 32-bit unsigned integer
	}

	[StructLayout(LayoutKind.Sequential,CharSet=CharSet.Ansi)]
		private struct SetParameterStruct
	{
		public uint ParameterNumber;
		public uint NewParameterValue;
	}

	[StructLayout(LayoutKind.Sequential,CharSet=CharSet.Ansi)]
		private struct PluginExtendedInfoStruct
	{
		public uint PluginMajorVersion;	// 32-bit unsigned integer
		public uint PluginMinorVersion;	// 32-bit unsigned integer
		public uint Description;			// 32-bit pointer to null terminated string
		public uint About;				// 32-bit pointer to null terminated string
		public uint FreeFrameExtendedDataSize;	// 32-bit unsigned integer
		public uint FreeFrameExtendedDataBlock;	// 32-bit pointer
	}

	[StructLayout(LayoutKind.Sequential,CharSet=CharSet.Ansi)]
		private struct ProcessFrameCopyStruct
	{
		public uint numInputFrames;	// 32-bit unsigned integer
		public uint ppInputFrames;	// 32-bit pointer to array of pointers
		public uint pOutputFrame;	// 32-bit pointer
	}

	[StructLayout(LayoutKind.Explicit,CharSet=CharSet.Ansi)]
		private struct ConvertNumber
	{
		[FieldOffset(0)]
		public uint uint32;
		[FieldOffset(0)]
		public float float32;
	}

	public enum ReturnCode : uint
	{
		FF_SUCCESS = 0,
		FF_FAIL = 0xffffffff,
		FF_TRUE = 1,
		FF_FALSE = 0,
		FF_SUPPORTED = 1,
		FF_UNSUPPORTED = 0
	}

	public enum PluginTypes : uint
	{
		Effect = 0,
		Source = 1
	}

	public enum PixelFormat : uint
	{
		Format16bppRgb565 = 0,
		Format24bppRgb = 1,
		Format32bppArgb = 2
	}

	public enum Orientation : uint
	{
		OriginTopLeft = 1,
		OriginBottomLeft = 2
	}

	public enum PluginCapsIndex : uint
	{
		Format16bppRgb565 = 0,
		Format24bppRgb = 1,
		Format32bppArgb = 2,
		FrameCopySupport = 3,
		MinimumInputFrames = 10,
		MaximumInputFrames = 11,
		PluginOptimization = 15
	}

	public enum PluginOptimizationSettings : uint
	{
		NoPreference = 0,
		InPlaceProcFaster = 1,
		CopyProcFaster = 2,
		BothOptimized = 3
	}

	public enum ParameterType : uint
	{
		Boolean = 0,
		Event = 1,
		Red = 2,
		Green = 3,
		Blue = 4,
		XPos = 5,
		YPose = 6,
		Standard = 10,
		Text = 100
	}

	public enum InputStatus : uint
	{
		NotInUse = 0,
		InUse = 1
	}

	[DllImport("kernel32")]
	public extern static int LoadLibrary(string lpLibFileName);
	[DllImport("kernel32")]
	public extern static bool SetDllDirectory(string lpPathName);
	[DllImport("kernel32")]
	public extern static bool FreeLibrary(int hLibModule);
	[DllImport("kernel32", CharSet=CharSet.Ansi)]
	public extern static int GetProcAddress(int hModule, string lpProcName);
	[DllImport("Invoke", CharSet=CharSet.Unicode)]
	public extern static uint InvokeFunc(int funcptr, uint functionCode, uint inputValue, uint instanceID);

	private bool disposed = false;
	private String dllfile;
	private String dlldir;
	private int dll;
	private int plugMainAddr;
	private VideoInfoStruct vis;
	private PluginInfoStruct pif;
	private PluginExtendedInfoStruct peis;
	private System.Drawing.Imaging.PixelFormat pixelFormat;
	private Byte[] imageBytes;
	private BitmapData bmpData;
	private uint numParameters;
	public float[] parameterDefault;
	public String[] parameterName;
	public uint[] parameterType;
	public float elapsedTime;

	public FreeFrame(String DLLDirectory, String DLLFile)
	{
		dllfile = DLLFile;
		dlldir = DLLDirectory;
		SetDllDirectory(DLLDirectory);
		dll = LoadLibrary(dllfile);
		plugMainAddr = GetProcAddress(dll, "plugMain");

		initialise();
		pif = getInfo();
		peis = getExtendedInfo();
		numParameters = getNumParameters();
		parameterName = new String[numParameters];
		parameterDefault = new float[numParameters];
		parameterType = new uint[numParameters];

		for (int i=0;i<numParameters;i++)
		{
			parameterName[i] = getParameterName((uint) i);
			parameterDefault[i] = getParameterDefault((uint) i);
			parameterType[i] = getParameterType((uint) i);
		}
	}

	//~FreeFrame()
	//{
	//	deInitialise();
	//	FreeLibrary(dll);
	//	Dispose(false);
	//}

	public void Dispose()
	{
		Dispose(true);
		GC.SuppressFinalize(this); // remove this from gc finalizer list
	}

	private void Dispose(bool disposing)
	{
		if (!this.disposed) // dispose once only
		{
			if (disposing) // called from Dispose
			{
				// Dispose managed resources.
			}
			deInitialise();
			FreeLibrary(dll);
			// Clean up unmanaged resources here.
		}
		disposed = true;
	}

	public uint NumParameters
	{
		get { return numParameters; }
	}

	public uint APIMajorVersion
	{
		get { return pif.APIMajorVersion; }
	}

	public uint APIMinorVersion
	{
		get { return pif.APIMinorVersion; }
	}

	public String PluginUniqueID
	{
		get	{ return System.Text.Encoding.ASCII.GetString(pif.PluginUniqueID, 0, 4).Trim(); }
	}

	public String PluginName
	{
		get	{ return System.Text.Encoding.ASCII.GetString(pif.PluginName, 0, 16).Trim(); }
	}
 
	public uint PluginType
	{
		get { return pif.PluginType; }
	}

	public uint PluginMajorVersion
	{
		get { return peis.PluginMajorVersion; }
	}

	public uint PluginMinorVersion
	{
		get { return peis.PluginMinorVersion; }
	}

	public String Description
	{
		get { return Marshal.PtrToStringAnsi(new IntPtr(peis.Description)); }
	}

	public String About
	{
		get { return Marshal.PtrToStringAnsi(new IntPtr(peis.About)); }
	}

	public uint FreeFrameExtendedDataSize
	{
		get { return peis.FreeFrameExtendedDataSize; }
	}

	public uint FreeFrameExtendedDataBlock
	{
		get { return peis.FreeFrameExtendedDataBlock; }
	}

	public uint Supports16BitVideo
	{
		get { return getPluginCaps((uint)PluginCapsIndex.Format16bppRgb565); }
	}

	public uint Supports24BitVideo
	{
		get { return getPluginCaps((uint)PluginCapsIndex.Format24bppRgb); }
	}

	public uint Supports32BitVideo
	{
		get { return getPluginCaps((uint)PluginCapsIndex.Format32bppArgb); }
	}

	public uint SupportsFrameCopy
	{
		get { return getPluginCaps((uint)PluginCapsIndex.FrameCopySupport); }
	}

	public uint MinimumInputFrames
	{
		get { return getPluginCaps((uint)PluginCapsIndex.MinimumInputFrames); }
	}

	public uint MaximumInputFrames
	{
		get { return getPluginCaps((uint)PluginCapsIndex.MaximumInputFrames); }
	}

	public uint PluginOptimization
	{
		get { return getPluginCaps((uint)PluginCapsIndex.PluginOptimization); }
	}

	// Global functions

	private PluginInfoStruct getInfo()
	{
        uint ret = InvokeFunc(plugMainAddr, 0, 0, 0);
		object pts = Marshal.PtrToStructure(new IntPtr(ret), typeof(PluginInfoStruct));
		return (PluginInfoStruct) pts;
	}

	private uint initialise()
	{
		return InvokeFunc(plugMainAddr, 1, 0, 0);
	}

	private uint deInitialise()
	{
		return InvokeFunc(plugMainAddr, 2, 0, 0);
	}

	private uint getNumParameters()
	{
		return InvokeFunc(plugMainAddr, 4, 0, 0);
	}

	private String getParameterName(uint index) // 16 character
	{
		uint ret = InvokeFunc(plugMainAddr, 5, index, 0);
		byte[] paramName = new byte[16];
		Marshal.Copy(new IntPtr(ret), paramName, 0, 16);
		return System.Text.Encoding.ASCII.GetString(paramName, 0, 16).Trim();
	}

	private float getParameterDefault(uint index)
	{
		ConvertNumber cn;
		cn.float32 = 0;
		cn.uint32 = InvokeFunc(plugMainAddr, 6, index, 0);
		return cn.float32;
	}

	private uint getPluginCaps(uint capsIndex)
	{
		return InvokeFunc(plugMainAddr, 10, capsIndex, 0);
	}

	private PluginExtendedInfoStruct getExtendedInfo()
	{
		uint ret = InvokeFunc(plugMainAddr, 13, 0, 0);
		object peis = Marshal.PtrToStructure(new IntPtr(ret), typeof(PluginExtendedInfoStruct));
		return (PluginExtendedInfoStruct) peis;
	}

	private uint getParameterType(uint index)
	{
		return InvokeFunc(plugMainAddr, 15, index, 0);
	}

	// Instance specific functions

	public uint processFrame(uint instanceID, ref Bitmap bitmap)
	{
		uint ret;

		float time = GetTime();
		LockBitmap(ref bitmap);
		unsafe
		{
			fixed (byte* pImage = &imageBytes[0])
			{
				ret = InvokeFunc(plugMainAddr, 3, (uint) pImage, instanceID);
			}
		}
		UnlockBitmap(ref bitmap);
		elapsedTime = GetTime() - time;
		return ret;
	}

	public uint processFrame(uint instanceID, IntPtr bmpPtr)
	{
		uint ret;
		float time = GetTime();
		ret = InvokeFunc(plugMainAddr, 3, (uint) bmpPtr.ToInt32(), instanceID);
		elapsedTime = GetTime() - time;
		return ret;
	}

	public String getParameterDisplay(uint instanceID, uint index)
	{
		uint ret = InvokeFunc(plugMainAddr, 7, index, instanceID);
		byte[] paramDisplay = new byte[16];
		Marshal.Copy(new IntPtr(ret), paramDisplay, 0, 16);
		return System.Text.Encoding.ASCII.GetString(paramDisplay, 0, 16).Trim();
	}

	public uint setParameter(uint instanceID, uint ParameterNumber, float NewParameterValue)
	{
		ConvertNumber cn;
		cn.uint32 = 0;
		cn.float32 = NewParameterValue;
		SetParameterStruct setParam;
		setParam.ParameterNumber = ParameterNumber;
		setParam.NewParameterValue = cn.uint32;
		IntPtr ptr = Marshal.AllocCoTaskMem(Marshal.SizeOf(typeof(SetParameterStruct)));
		Marshal.StructureToPtr(setParam, ptr, true);
		uint ret = InvokeFunc(plugMainAddr, 8, (uint) ptr.ToInt32(), instanceID);
		Marshal.FreeCoTaskMem(ptr);
		return ret;
	}

	public float getParameter(uint instanceID, uint index)
	{
		ConvertNumber cn;
		cn.float32 = 0;
		cn.uint32 = InvokeFunc(plugMainAddr, 9, index, instanceID);
		return cn.float32;
	}

	public uint instantiate(uint FrameWidth, uint FrameHeight, uint BitDepth, uint Orientation)
	{
		VideoInfoStruct videoInfo;
		videoInfo.FrameWidth = FrameWidth;
		videoInfo.FrameHeight = FrameHeight;
		videoInfo.BitDepth = BitDepth;
		switch(BitDepth)
		{
			case (uint) PixelFormat.Format16bppRgb565:
				pixelFormat = System.Drawing.Imaging.PixelFormat.Format16bppRgb565;
				break;
			case (uint) PixelFormat.Format24bppRgb:
				pixelFormat = System.Drawing.Imaging.PixelFormat.Format24bppRgb;
				break;
			case (uint) PixelFormat.Format32bppArgb:
				pixelFormat = System.Drawing.Imaging.PixelFormat.Format32bppArgb;
				break;
			default:
				pixelFormat = System.Drawing.Imaging.PixelFormat.Format32bppArgb;
				break;
		}
		videoInfo.Orientation = Orientation;
		IntPtr ptr = Marshal.AllocCoTaskMem(Marshal.SizeOf(typeof(VideoInfoStruct)));
		Marshal.StructureToPtr(videoInfo, ptr, true);
		uint ret = InvokeFunc(plugMainAddr, 11,  (uint) ptr.ToInt32(), 0);
		Marshal.FreeCoTaskMem(ptr);
		return ret;
	}

	public uint deInstantiate(uint instanceID)
	{
		return InvokeFunc(plugMainAddr, 12, 0, instanceID);
	}

	unsafe public uint processFrameCopy(uint instanceID, uint numInputFrames, uint[] ppInputFrames, uint pOutputFrame)
	{
		uint ret;
		ProcessFrameCopyStruct copyStruct;
		copyStruct.numInputFrames = numInputFrames;
		fixed (uint* pInputFrame = &ppInputFrames[0])
		{
			copyStruct.ppInputFrames = (uint) pInputFrame;
			copyStruct.pOutputFrame = pOutputFrame;
			IntPtr ptr = Marshal.AllocCoTaskMem(Marshal.SizeOf(typeof(ProcessFrameCopyStruct)));
			Marshal.StructureToPtr(copyStruct, ptr, true);
			ret = InvokeFunc(plugMainAddr, 14, (uint) ptr.ToInt32(), instanceID);
			Marshal.FreeCoTaskMem(ptr);
		}
		return ret;
	}

	public uint getInputStatus(uint instanceID, uint channel)
	{
		return InvokeFunc(plugMainAddr, 16, channel, instanceID);
	}

	private float GetTime()
	{
		return System.Environment.TickCount;
	}

	private void LockBitmap(ref Bitmap bmp)
	{
		Rectangle bounds = new Rectangle(0, 0, bmp.Width, bmp.Height);
		bmpData = bmp.LockBits(bounds, ImageLockMode.ReadWrite, pixelFormat);

		int total_size = bmpData.Stride * bmpData.Height;
		imageBytes = new Byte[total_size];

		Marshal.Copy(bmpData.Scan0, imageBytes, 0, total_size);
	}

	private void UnlockBitmap(ref Bitmap bmp)
	{
		int total_size = bmpData.Stride * bmpData.Height;
		Marshal.Copy(imageBytes, 0, bmpData.Scan0, total_size);

		bmp.UnlockBits(bmpData);

		imageBytes = null;
		bmpData = null;
	}
}
