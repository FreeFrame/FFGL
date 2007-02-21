/****************************************************************************
While the underlying libraries are covered by LGPL, this sample is released 
as public domain.  It is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
or FITNESS FOR A PARTICULAR PURPOSE.  
*****************************************************************************/

using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Collections;
using System.Runtime.InteropServices;
using System.Threading;
using System.Diagnostics;
using System.Windows.Forms;

using DirectShowLib;

/// <summary> Summary description for MainForm. </summary>
internal class WebCam : DirectShowLib.ISampleGrabberCB, IDisposable
{
    #region Member variables

    /// <summary> graph builder interface. </summary>
    private DirectShowLib.IFilterGraph2 m_graphBuilder = null;
    private DirectShowLib.IMediaControl m_mediaCtrl = null;

	// ------------------------------------
	private IBaseFilter theCompressor = null;
	// ------------------------------------

    /// <summary> so we can wait for the async job to finish </summary>
    private ManualResetEvent m_PictureReady = null;

    /// <summary> Set by async routine when it captures an image </summary>
    private volatile bool m_bGotOne = false;

    /// <summary> Indicates the status of the graph </summary>
    private bool m_bRunning = false;

    /// <summary> Dimensions of the image, calculated once in constructor. </summary>
    private IntPtr m_handle = IntPtr.Zero;
    private int m_videoWidth;
    private int m_videoHeight;
    private int m_stride;
	private PixelFormat m_pixelformat;
    public int m_Dropped = 0;

    #endregion

    #region API

    [DllImport("Kernel32.dll", EntryPoint="RtlMoveMemory")]
    private static extern void CopyMemory(IntPtr Destination, IntPtr Source, int Length);

    #endregion

    /// <summary> Use capture device zero, default frame rate and size</summary>
    public WebCam(Control hControl)
    {
        _Capture(0, 0, 0, 0, hControl);
    }
    /// <summary> Use specified capture device, default frame rate and size</summary>
    public WebCam(int iDeviceNum, Control hControl)
    {
        _Capture(iDeviceNum, 0, 0, 0, hControl);
    }
    /// <summary> Use specified capture device, specified frame rate and default size</summary>
    public WebCam(int iDeviceNum, int iFrameRate, Control hControl)
    {
        _Capture(iDeviceNum, iFrameRate, 0, 0, hControl);
    }
    /// <summary> Use specified capture device, specified frame rate and size</summary>
    public WebCam(int iDeviceNum, int iFrameRate, int iWidth, int iHeight, Control hControl)
    {
        _Capture(iDeviceNum, iFrameRate, iWidth, iHeight, hControl);
    }
    /// <summary> release everything. </summary>
    public void Dispose()
    {
        CloseInterfaces();
        if (m_PictureReady != null)
        {
            m_PictureReady.Close();
            m_PictureReady = null;
        }
    }
    // Destructor
    ~WebCam()
    {
        Dispose();
    }

    public int Width
    {
        get
        {
            return m_videoWidth;
        }
    }
    public int Height
    {
        get
        {
            return m_videoHeight;
        }
    }
    public int Stride
    {
        get
        {
            return m_stride;
        }
    }
	public PixelFormat PixelFormat
	{
		get
		{
			return m_pixelformat;
		}
		set
		{
			m_pixelformat = value;
		}
	}

	/// <summary> capture the next image </summary>
	public IntPtr GetBitmap()
	{
		m_handle = Marshal.AllocCoTaskMem(m_stride * m_videoHeight);

		try
		{
			// get ready to wait for new image
			m_PictureReady.Reset();
			m_bGotOne = false;

			// If the graph hasn't been started, start it.
			Start();

			// Start waiting
			if ( ! m_PictureReady.WaitOne(5000, false) )
			{
				//throw new Exception("Timeout waiting to get picture");
				m_handle = IntPtr.Zero;
			}
		}
		catch
		{
			Marshal.FreeCoTaskMem(m_handle);
			//throw;
			m_handle = IntPtr.Zero;
		}

		// Got one
		return m_handle;
	}

	// Convert a point to the raw pixel data to a .NET bitmap
	public Bitmap IPToBmp(IntPtr ip)
	{
		// We know the Bits Per Pixel is 24 (3 bytes) because we forced it 
		// to be with sampGrabber.SetMediaType()
		int iBufSize = m_videoWidth * m_videoHeight * 3;

		return (Bitmap) new Bitmap(
			m_videoWidth, 
			m_videoHeight, 
			-m_stride, 
			PixelFormat.Format24bppRgb, 
			(IntPtr)(ip.ToInt32() + iBufSize - m_stride)
			).GetThumbnailImage(320, 240, null, IntPtr.Zero);
	}

    // Start the capture graph
    public void Start()
    {
        if (!m_bRunning)
        {
            int hr = m_mediaCtrl.Run();
            DsError.ThrowExceptionForHR( hr );

            m_bRunning = true;
        }
    }
    // Pause the capture graph.
    // Running the graph takes up a lot of resources.  Pause it when it
    // isn't needed.
    public void Pause()
    {
        if (m_bRunning)
        {
            int hr = m_mediaCtrl.Pause();
            DsError.ThrowExceptionForHR( hr );

            m_bRunning = false;
        }
    }


    // Internal capture
	private void _Capture(int iDeviceNum, int iFrameRate, int iWidth, int iHeight, Control hControl)
	{
		DsDevice[] capDevices;

		// Get the collection of video devices
		capDevices = DsDevice.GetDevicesOfCat( DirectShowLib.FilterCategory.VideoInputDevice );

		if (iDeviceNum + 1 > capDevices.Length)
		{
			throw new Exception("No video capture devices found at that index!");
		}

		try
		{
			// Set up the capture graph
			SetupGraph( capDevices[iDeviceNum], iFrameRate, iWidth, iHeight, hControl);

			// tell the callback to ignore new images
			m_PictureReady = new ManualResetEvent(false);
			m_bGotOne = true;
			m_bRunning = false;
		}
		catch
		{
			Dispose();
			throw;
		}
	}

    /// <summary> build the capture graph for grabber. </summary>
    private void SetupGraph(DsDevice dev, int iFrameRate, int iWidth, int iHeight, Control hControl)
    {
        int hr;

        DirectShowLib.ISampleGrabber sampGrabber = null;
        DirectShowLib.IBaseFilter capFilter = null;
        DirectShowLib.ICaptureGraphBuilder2 capGraph = null;

        // Get the graphbuilder object
        m_graphBuilder = (DirectShowLib.IFilterGraph2) new FilterGraph();
        m_mediaCtrl = m_graphBuilder as DirectShowLib.IMediaControl;
        try
        {
            // Get the ICaptureGraphBuilder2
            capGraph = (DirectShowLib.ICaptureGraphBuilder2) new DirectShowLib.CaptureGraphBuilder2();

            // Get the SampleGrabber interface
            sampGrabber = (DirectShowLib.ISampleGrabber) new DirectShowLib.SampleGrabber();

            // Start building the graph
            hr = capGraph.SetFiltergraph( m_graphBuilder );
            DsError.ThrowExceptionForHR( hr );

            // Add the video device
            hr = m_graphBuilder.AddSourceFilterForMoniker(dev.Mon, null, "Video input", out capFilter);
            DsError.ThrowExceptionForHR( hr );

            DirectShowLib.IBaseFilter baseGrabFlt = (DirectShowLib.IBaseFilter)	sampGrabber;
            ConfigureSampleGrabber(sampGrabber);

            // Add the frame grabber to the graph
            hr = m_graphBuilder.AddFilter( baseGrabFlt, "Ds.NET Grabber" );
            DsError.ThrowExceptionForHR( hr );

            // If any of the default config items are set
            if (iFrameRate + iHeight + iWidth > 0)
            {
                SetConfigParms(capGraph, capFilter, iFrameRate, iWidth, iHeight);
            }

			// ------------------------------------

			if (false) 
			{
				if (false)
				{
					hr = capGraph.RenderStream(DirectShowLib.PinCategory.Preview, DirectShowLib.MediaType.Video, capFilter, null, baseGrabFlt);
					DsError.ThrowExceptionForHR(hr);
				}
				theCompressor = CreateFilter(FilterCategory.VideoCompressorCategory, "Microsoft MPEG-4 Video Codec V2");

				// Add the Video compressor filter to the graph
				if (theCompressor != null)
				{
					hr = m_graphBuilder.AddFilter(theCompressor, "Compressor Filter");
					DsError.ThrowExceptionForHR(hr);
				}

				// Create the file writer part of the graph. SetOutputFileName does this for us, and returns the mux and sink
				DirectShowLib.IBaseFilter mux;
				DirectShowLib.IFileSinkFilter sink;
				hr = capGraph.SetOutputFileName(DirectShowLib.MediaSubType.Avi, "C:\\Test.avi", out mux, out sink);
				DsError.ThrowExceptionForHR(hr);

				hr = capGraph.RenderStream(DirectShowLib.PinCategory.Capture, DirectShowLib.MediaType.Video, capFilter, theCompressor, mux);
				DsError.ThrowExceptionForHR(hr);

				Marshal.ReleaseComObject(mux);
				Marshal.ReleaseComObject(sink);

				hr = capGraph.RenderStream(DirectShowLib.PinCategory.Preview, DirectShowLib.MediaType.Video, capFilter, null, null);
				DsError.ThrowExceptionForHR(hr);

				//ShowVideoWindow(hControl);
			}
			else
			{
				hr = capGraph.RenderStream(DirectShowLib.PinCategory.Capture, DirectShowLib.MediaType.Video, capFilter, null, baseGrabFlt);
				DsError.ThrowExceptionForHR(hr);

				//hr = capGraph.RenderStream(DirectShowLib.PinCategory.Preview, DirectShowLib.MediaType.Video, capFilter, null, null);
				//DsError.ThrowExceptionForHR(hr);

				//ShowVideoWindow(hControl);
			}

            // --------------------------------------

            //hr = capGraph.RenderStream( DirectShowLib.PinCategory.Capture, DirectShowLib.MediaType.Video, capFilter, null, baseGrabFlt );
            //DsError.ThrowExceptionForHR( hr );

            SaveSizeInfo(sampGrabber);
        }
        finally
        {
            if (capFilter != null)
            {
                Marshal.ReleaseComObject(capFilter);
                capFilter = null;
            }
            if (sampGrabber != null)
            {
                Marshal.ReleaseComObject(sampGrabber);
                sampGrabber = null;
            }
            if (capGraph != null)
            {
                Marshal.ReleaseComObject(capGraph);
                capGraph = null;
            }
        }
    }

	private void ShowVideoWindow(Control hControl)
	{
		int hr;
		// get the video window from the graph
		IVideoWindow videoWindow = (DirectShowLib.IVideoWindow) m_graphBuilder;

		//IBasicVideo basicFilter = (IBasicVideo) m_graphBuilder; 
		//basicFilter.put_DestinationWidth(320); 
		//basicFilter.put_DestinationHeight(240);

		// Set the owener of the videoWindow to an IntPtr of some sort (the Handle of any control - could be a form / button etc.)
		hr = videoWindow.put_Owner(hControl.Handle);
		DsError.ThrowExceptionForHR(hr);

		// Set the style of the video window
		hr = videoWindow.put_WindowStyle(WindowStyle.Child | WindowStyle.ClipChildren);
		DsError.ThrowExceptionForHR(hr);

		// Position video window in client rect of main application window
		hr = videoWindow.SetWindowPosition(0, 0, hControl.Width, hControl.Height);
		DsError.ThrowExceptionForHR(hr);

		// Make the video window visible
		hr = videoWindow.put_Visible(OABool.True);
		DsError.ThrowExceptionForHR(hr);

		Start();
	}

	private IBaseFilter CreateFilter(Guid category, string friendlyname)
	{
		object source = null;
		Guid iid = typeof(IBaseFilter).GUID;
		foreach (DsDevice device in DsDevice.GetDevicesOfCat(category))
		{
			if (device.Name.CompareTo(friendlyname) == 0)
			{
				device.Mon.BindToObject(null, null, ref iid, out source);
				break;
			}
		}

		return (IBaseFilter)source;
	}

    private void SaveSizeInfo(DirectShowLib.ISampleGrabber sampGrabber)
    {
        int hr;

        // Get the media type from the SampleGrabber
        DirectShowLib.AMMediaType media = new DirectShowLib.AMMediaType();
        hr = sampGrabber.GetConnectedMediaType( media );
        DsError.ThrowExceptionForHR( hr );

        if( (media.formatType != FormatType.VideoInfo) || (media.formatPtr == IntPtr.Zero) )
        {
            throw new NotSupportedException( "Unknown Grabber Media Format" );
        }

        // Grab the size info
        VideoInfoHeader videoInfoHeader = (VideoInfoHeader) Marshal.PtrToStructure( media.formatPtr, typeof(VideoInfoHeader) );
        m_videoWidth = videoInfoHeader.BmiHeader.Width;
        m_videoHeight = videoInfoHeader.BmiHeader.Height;
        m_stride = m_videoWidth * (videoInfoHeader.BmiHeader.BitCount / 8);

        DsUtils.FreeAMMediaType(media);
        media = null;
    }

    private void ConfigureSampleGrabber(DirectShowLib.ISampleGrabber sampGrabber)
    {
        DirectShowLib.AMMediaType media;
        int hr;

        // Set the media type to Video/RBG24
        media = new DirectShowLib.AMMediaType();
        media.majorType	= DirectShowLib.MediaType.Video;
        media.subType	= DirectShowLib.MediaSubType.RGB24;
        media.formatType = DirectShowLib.FormatType.VideoInfo;
        hr = sampGrabber.SetMediaType( media );
        DsError.ThrowExceptionForHR( hr );

        DirectShowLib.DsUtils.FreeAMMediaType(media);
        media = null;

        // Configure the samplegrabber
        hr = sampGrabber.SetCallback( this, 1 );
        DsError.ThrowExceptionForHR( hr );
    }

    // Set the Framerate, and video size
    private void SetConfigParms(DirectShowLib.ICaptureGraphBuilder2 capGraph, DirectShowLib.IBaseFilter capFilter, int iFrameRate, int iWidth, int iHeight)
    {
        int hr;
        object o;
        DirectShowLib.AMMediaType media;

        // Find the stream config interface
        hr = capGraph.FindInterface(
            DirectShowLib.PinCategory.Capture, DirectShowLib.MediaType.Video, capFilter, typeof(DirectShowLib.IAMStreamConfig).GUID, out o );

        DirectShowLib.IAMStreamConfig videoStreamConfig = o as DirectShowLib.IAMStreamConfig;
        if (videoStreamConfig == null)
        {
            throw new Exception("Failed to get IAMStreamConfig");
        }

        // Get the existing format block
        hr = videoStreamConfig.GetFormat( out media);
        DsError.ThrowExceptionForHR( hr );

        // copy out the videoinfoheader
        DirectShowLib.VideoInfoHeader v = new DirectShowLib.VideoInfoHeader();
        Marshal.PtrToStructure( media.formatPtr, v );

        // if overriding the framerate, set the frame rate
        if (iFrameRate > 0)
        {
            v.AvgTimePerFrame = 10000000 / iFrameRate;
        }

        // if overriding the width, set the width
        if (iWidth > 0)
        {
            v.BmiHeader.Width = iWidth;
        }

        // if overriding the Height, set the Height
        if (iHeight > 0)
        {
            v.BmiHeader.Height = iHeight;
        }

        // Copy the media structure back
        Marshal.StructureToPtr( v, media.formatPtr, false );

        // Set the new format
        hr = videoStreamConfig.SetFormat( media );
        DsError.ThrowExceptionForHR( hr );

        DirectShowLib.DsUtils.FreeAMMediaType(media);
        media = null;
    }

    /// <summary> Shut down capture </summary>
    private void CloseInterfaces()
    {
        int hr;

        try
        {
            if( m_mediaCtrl != null )
            {
                // Stop the graph
                hr = m_mediaCtrl.Stop();
                m_bRunning = false;
            }
        }
        catch (Exception ex)
        {
            Debug.WriteLine(ex);
        }

        if (m_graphBuilder != null)
        {
            Marshal.ReleaseComObject(m_graphBuilder);
            m_graphBuilder = null;
        }
    }

    /// <summary> sample callback, NOT USED. </summary>
    int DirectShowLib.ISampleGrabberCB.SampleCB( double SampleTime, DirectShowLib.IMediaSample pSample )
    {
        if (!m_bGotOne)
        {
            // Set bGotOne to prevent further calls until we
            // request a new bitmap.
            m_bGotOne = true;
            IntPtr pBuffer;

            pSample.GetPointer(out pBuffer);
            int iBufferLen = pSample.GetSize();

            if (pSample.GetSize() > m_stride * m_videoHeight)
            {
                throw new Exception("Buffer is wrong size");
            }

            CopyMemory(m_handle, pBuffer, m_stride * m_videoHeight);

            // Picture is ready.
            m_PictureReady.Set();
        }

        Marshal.ReleaseComObject(pSample);
        return 0;
    }

    /// <summary> buffer callback, COULD BE FROM FOREIGN THREAD. </summary>
    int ISampleGrabberCB.BufferCB( double SampleTime, IntPtr pBuffer, int BufferLen )
    {
        if (!m_bGotOne)
        {
            // The buffer should be long enought
            if(BufferLen <= m_stride * m_videoHeight)
            {
                // Copy the frame to the buffer
                CopyMemory(m_handle, pBuffer, m_stride * m_videoHeight);
            }
            else
            {
                throw new Exception("Buffer is wrong size");
            }

            // Set bGotOne to prevent further calls until we
            // request a new bitmap.
            m_bGotOne = true;

            // Picture is ready.
            m_PictureReady.Set();
        }
        else
        {
            m_Dropped++;
        }
        return 0;
    }
}

