/****************************************************************************
While the underlying libraries are covered by LGPL, this sample is released 
as public domain.  It is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
or FITNESS FOR A PARTICULAR PURPOSE.  
*****************************************************************************/

// Two very important things to know when using this class:
// 1) Make sure you DxPlay.Dispose before shutting down the app (to avoid hanging)
// 2) Make sure you Marshal.FreeCoTaskMem items returned from DxPlay.SnapShot (to avoid leaking)

using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Collections;
using System.Runtime.InteropServices;
using System.Diagnostics;
using System.Windows.Forms;
using System.Threading;

using DirectShowLib;

internal class Video : IDisposable
{
    enum GraphState
    {
        Stopped,
        Paused,
        Running,
        Exiting
    }

    #region Member variables

    // File name we are playing
    private string m_sFileName;

    // graph builder interfaces
    private DirectShowLib.IFilterGraph2 m_graphBuilder;
    private DirectShowLib.IMediaControl m_mediaCtrl;
    private DirectShowLib.IMediaEvent m_mediaEvent;

    // Used to grab current snapshots
    DirectShowLib.ISampleGrabber m_sampGrabber = null;

    // Grab once.  Used to create bitmap
    private int m_videoWidth;
    private int m_videoHeight;
    private int m_stride;
    private int m_ImageSize; // In bytes

    // Event used by Media Event thread
    private ManualResetEvent m_mre;

    // Current state of the graph (can change async)
    volatile private GraphState m_State = GraphState.Stopped;

#if DEBUG
    // Allow you to "Connect to remote graph" from GraphEdit
    DsROTEntry m_DsRot;
#endif

    #endregion

    // Release everything.
    public void Dispose()
    {
        CloseInterfaces();
    }

    ~Video()
    {
        CloseInterfaces();
    }

    // Event that is called when a clip finishs playing
    public event DxPlayEvent StopPlay;
    public delegate void DxPlayEvent(Object sender);

    // Play an avi file into a window.  Allow for snapshots.
    // (Control to show video in, Avi file to play
    //public Video(Control hWin, string FileName)
	public Video(string FileName)
    {
        try
        {
            int hr;
            IntPtr hEvent;

            // Save off the file name
            m_sFileName = FileName;

            // Set up the graph
            SetupGraph(FileName);

            // Get the event handle the graph will use to signal
            // when events occur
            hr = m_mediaEvent.GetEventHandle(out hEvent);
            DsError.ThrowExceptionForHR(hr);

            // Wrap the graph event with a ManualResetEvent
            m_mre = new ManualResetEvent(false);
            m_mre.Handle = hEvent;

            // Create a new thread to wait for events
            Thread t = new Thread(new ThreadStart(this.EventWait));
            t.Name = "Media Event Thread";
            t.Start();
        }
        catch
        {
            Dispose();
            throw;
        }
    }

    // Wait for events to happen.  This approach uses waiting on an event handle.
    // The nice thing about doing it this way is that you aren't in the windows message
    // loop, and don't have to worry about re-entrency or taking too long.  Plus, being
    // in a class as we are, we don't have access to the message loop.
    // Alternately, you can receive your events as windows messages.  See
    // IMediaEventEx.SetNotifyWindow.
    private void EventWait()
    {
        // Returned when GetEvent is called but there are no events
        const int E_ABORT = unchecked((int)0x80004004);

        int hr;
        int p1, p2;
        EventCode ec;

        do
        {
            // Wait for an event
            m_mre.WaitOne(-1, true);

            // Avoid contention for m_State
            lock(this)
            {
                // If we are not shutting down
                if (m_State != GraphState.Exiting)
                {
                    // Read the event
                    for (
                        hr = m_mediaEvent.GetEvent(out ec, out p1, out p2, 0);
                        hr >= 0;
                        hr = m_mediaEvent.GetEvent(out ec, out p1, out p2, 0)
                        )
                    {
                        // Write the event name to the debug window
                        Debug.WriteLine(ec.ToString());

                        // If the clip is finished playing
                        if (ec == EventCode.Complete)
                        {
                            // Call Stop() to set state
                            Stop();

                            // Throw event
                            if (StopPlay != null)
                            {
                                StopPlay(this);
                            }
                        }

                        // Release any resources the message allocated
                        hr = m_mediaEvent.FreeEventParams(ec, p1, p2);
                        DsError.ThrowExceptionForHR(hr);
                    }

                    // If the error that exited the loop wasn't due to running out of events
                    if (hr != E_ABORT)
                    {
                        DsError.ThrowExceptionForHR(hr);
                    }
                }
                else
                {
                    // We are shutting down
                    break;
                }
            }
        } while (true);
    }

	// Return the width of video
	public int Width
	{
		get
		{
			return m_videoWidth;
		}
	}

	// Return the width of video
	public int Height
	{
		get
		{
			return m_videoHeight;
		}
	}

    // Return the currently playing file name
    public string FileName
    {
        get
        {
            return m_sFileName;
        }
    }

    // start playing
    public void Start()
    {
        // If we aren't already playing (or shutting down)
        if (m_State == GraphState.Stopped || m_State == GraphState.Paused)
        {
            int hr = m_mediaCtrl.Run();
            DsError.ThrowExceptionForHR( hr );

            m_State = GraphState.Running;
        }
    }

    // Pause the capture graph.
    public void Pause()
    {
        // If we are playing
        if (m_State == GraphState.Running)
        {
            int hr = m_mediaCtrl.Pause();
            DsError.ThrowExceptionForHR( hr );

            m_State = GraphState.Paused;
        }
    }
    // Pause the capture graph.
    public void Stop()
    {
        // Can only Stop when playing or paused
        if (m_State == GraphState.Running || m_State == GraphState.Paused)
        {
            int hr = m_mediaCtrl.Stop();
            DsError.ThrowExceptionForHR( hr );

            m_State = GraphState.Stopped;
        }
    }

    // Reset the clip back to the beginning
    public void Rewind()
    {
        int hr;

        DirectShowLib.IMediaPosition imp = m_graphBuilder as DirectShowLib.IMediaPosition;
        hr = imp.put_CurrentPosition(0);
    }

    // Grab a snapshot of the most recent image played.
    // Returns A pointer to the raw pixel data. Caller must release this memory with
    // Marshal.FreeCoTaskMem when it is no longer needed.
    public IntPtr GetBitmap()
    {
        int hr;
        IntPtr ip = IntPtr.Zero;
        int iBuffSize = 0;

        // Read the buffer size
		hr = m_sampGrabber.GetCurrentBuffer(ref iBuffSize, ip);
		//DsError.ThrowExceptionForHR( hr );

		//Debug.Assert(iBuffSize == m_ImageSize, "Unexpected buffer size");

		// Allocate the buffer and read it
		ip = Marshal.AllocCoTaskMem(iBuffSize);

		hr = m_sampGrabber.GetCurrentBuffer(ref iBuffSize, ip);
		DsError.ThrowExceptionForHR( hr );

        return ip;
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

		/* int iBufSize = 256 * 256 * 3;

		return (Bitmap) new Bitmap(
			256,
			256,
			-m_stride,
			PixelFormat.Format24bppRgb,
			(IntPtr)(ip.ToInt32() + iBufSize - m_stride)
			); */
    }

	// Build the capture graph for grabber and renderer.</summary>
	// (Control to show video in, Filename to play)
	private void SetupGraph(string FileName)
	{
		int hr;

		// Get the graphbuilder object
		m_graphBuilder = new DirectShowLib.FilterGraph() as DirectShowLib.IFilterGraph2;

		// Get a ICaptureGraphBuilder2 to help build the graph
		DirectShowLib.ICaptureGraphBuilder2 icgb2 = new DirectShowLib.CaptureGraphBuilder2() as DirectShowLib.ICaptureGraphBuilder2;

		try
		{
			// Link the ICaptureGraphBuilder2 to the IFilterGraph2
			hr = icgb2.SetFiltergraph(m_graphBuilder);
			DsError.ThrowExceptionForHR( hr );

#if DEBUG
			// Allows you to view the graph with GraphEdit File/Connect
			m_DsRot = new DsROTEntry(m_graphBuilder);
#endif

			// Add the filters necessary to render the file.  This function will
			// work with a number of different file types.
			IBaseFilter	sourceFilter = null;
			hr = m_graphBuilder.AddSourceFilter(FileName, FileName, out sourceFilter);
			DsError.ThrowExceptionForHR( hr );

			// Get the SampleGrabber interface
			m_sampGrabber = (DirectShowLib.ISampleGrabber) new DirectShowLib.SampleGrabber();
			DirectShowLib.IBaseFilter baseGrabFlt = (DirectShowLib.IBaseFilter)	m_sampGrabber;

			// Configure the Sample Grabber
			ConfigureSampleGrabber(m_sampGrabber);

			// Add it to the filter
			hr = m_graphBuilder.AddFilter( baseGrabFlt, "Ds.NET Grabber" );
			DsError.ThrowExceptionForHR( hr );

			// System.Windows.Forms.MessageBox.Show(Width.ToString(), Height.ToString(), System.Windows.Forms.MessageBoxButtons.OK);

			// A Null Renderer does not display the video
			// But it allows the Sample Grabber to run
			// And it will keep proper playback timing
			// Unless specified otherwise.
			DirectShowLib.NullRenderer nullRenderer = new DirectShowLib.NullRenderer();

			m_graphBuilder.AddFilter((DirectShowLib.IBaseFilter) nullRenderer, "Null Renderer");

			// Connect the pieces together, use the default renderer
			hr = icgb2.RenderStream(null, null, sourceFilter, baseGrabFlt, (DirectShowLib.IBaseFilter) nullRenderer);
			DsError.ThrowExceptionForHR( hr );

			// Now that the graph is built, read the dimensions of the bitmaps we'll be getting
			SaveSizeInfo(m_sampGrabber);

			// Configure the Video Window
			//DirectShowLib.IVideoWindow videoWindow = m_graphBuilder as DirectShowLib.IVideoWindow;
			//ConfigureVideoWindow(videoWindow, hWin);

			// Grab some other interfaces
			m_mediaEvent = m_graphBuilder as DirectShowLib.IMediaEvent;
			m_mediaCtrl = m_graphBuilder as DirectShowLib.IMediaControl;
		}
		finally
		{
			if (icgb2 != null)
			{
				Marshal.ReleaseComObject(icgb2);
				icgb2 = null;
			}
		}
#if DEBUG
		// Double check to make sure we aren't releasing something
		// important.
		GC.Collect();
		GC.WaitForPendingFinalizers();
#endif
	}

    // Configure the video window
    private void ConfigureVideoWindow(DirectShowLib.IVideoWindow videoWindow, Control hWin)
    {
        int hr;

        // Set the output window
        hr = videoWindow.put_Owner( hWin.Handle );
        DsError.ThrowExceptionForHR( hr );

        // Set the window style
        hr = videoWindow.put_WindowStyle( (WindowStyle.Child | WindowStyle.ClipChildren | WindowStyle.ClipSiblings) );
        DsError.ThrowExceptionForHR( hr );

        // Make the window visible
        hr = videoWindow.put_Visible( OABool.True );
        DsError.ThrowExceptionForHR( hr );

		// Make the window visible
		//hr = videoWindow.put_Visible( OABool.False );
		//DsError.ThrowExceptionForHR( hr );

        // Position the playing location
        Rectangle rc = hWin.ClientRectangle;
        hr = videoWindow.SetWindowPosition( 0, 0, rc.Right, rc.Bottom );
        DsError.ThrowExceptionForHR( hr );

		//Rectangle rc = hWin.ClientRectangle;
		//hr = videoWindow.SetWindowPosition( 0, 0, 0, 0 );
		//DsError.ThrowExceptionForHR( hr );
    }

    // Set the options on the sample grabber
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
        hr = sampGrabber.SetBufferSamples( true );
        DsError.ThrowExceptionForHR( hr );
    }

    // Save the size parameters for use in SnapShot
    private void SaveSizeInfo(DirectShowLib.ISampleGrabber sampGrabber)
    {
        int hr;

        // Get the media type from the SampleGrabber
        DirectShowLib.AMMediaType media = new DirectShowLib.AMMediaType();

        hr = sampGrabber.GetConnectedMediaType( media );
		
		hr = sampGrabber.SetMediaType(media);
        DsError.ThrowExceptionForHR( hr );

        try
        {

            if( (media.formatType != FormatType.VideoInfo) || (media.formatPtr == IntPtr.Zero) )
            {
                throw new NotSupportedException( "Unknown Grabber Media Format" );
            }

            // Get the struct
            DirectShowLib.VideoInfoHeader videoInfoHeader = new DirectShowLib.VideoInfoHeader();
            Marshal.PtrToStructure( media.formatPtr, videoInfoHeader);

            // Grab the size info
            m_videoWidth = videoInfoHeader.BmiHeader.Width;
            m_videoHeight = videoInfoHeader.BmiHeader.Height;
            m_stride = m_videoWidth * (videoInfoHeader.BmiHeader.BitCount / 8);
            m_ImageSize = m_videoWidth * m_videoHeight * 3;
		}
        finally
        {
            DirectShowLib.DsUtils.FreeAMMediaType(media);
            media = null;
        }
    }

    // Shut down capture
    private void CloseInterfaces()
    {
        int hr;

        lock (this)
        {
            if (m_State != GraphState.Exiting)
            {
                m_State = GraphState.Exiting;

                // Release the thread (if the thread was started)
                if (m_mre != null)
                {
                    m_mre.Set();
                }
            }

            if( m_mediaCtrl != null )
            {
                // Stop the graph
                hr = m_mediaCtrl.Stop();
                m_mediaCtrl = null;
            }

            if (m_sampGrabber != null)
            {
                Marshal.ReleaseComObject(m_sampGrabber);
                m_sampGrabber = null;
            }

#if DEBUG
            if (m_DsRot != null)
            {
                m_DsRot.Dispose();
            }
#endif

            if (m_graphBuilder != null)
            {
                Marshal.ReleaseComObject(m_graphBuilder);
                m_graphBuilder = null;
            }
        }
        GC.Collect();
    }
}

