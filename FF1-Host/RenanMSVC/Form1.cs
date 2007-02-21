using System;
using System.IO;
using System.Collections;
using System.ComponentModel;
using System.Windows.Forms;
using System.Data;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

namespace FreeFrameTest
{
	/// <summary>
	/// Summary description for Form1.
	/// </summary>
	public class Form1 : System.Windows.Forms.Form
	{
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;

		private System.Windows.Forms.PictureBox pictureBox1;
		private System.Windows.Forms.PictureBox pictureBox2;
		private System.Windows.Forms.Label label1;
		private System.Windows.Forms.ListBox listBox1;
		private System.Windows.Forms.ListBox listBox2;
		private System.Windows.Forms.Label lblParam;
		private System.Windows.Forms.TextBox txtVideoFile;
		private System.Windows.Forms.Label lblVideoFile;
		private System.Windows.Forms.Button btnVideoBrowse;
		private System.Windows.Forms.TrackBar trkParam;
		private System.Windows.Forms.Button btnPlay;
		private System.Windows.Forms.RadioButton rdoVideoInput;
		private System.Windows.Forms.RadioButton rdoWebcamInput;

		private uint instanceID;
		private FreeFrame freeframe;
		private WebCam webcam = null;
		private Video video = null;
		private bool bPluginLoaded = false;
		private int selectedParam = -1;
		private float selectedParamValue = 0;

		public Form1()
		{
			//
			// Required for Windows Form Designer support
			//
			InitializeComponent();

			GetPlugins();
			webcam = new WebCam(0, 0, 320, 240, null);
		}

		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		protected override void Dispose( bool disposing )
		{
			if( disposing )
			{
				if (components != null) 
				{
					components.Dispose();
				}
			}
			base.Dispose( disposing );
			if(bPluginLoaded)
			{
				freeframe.deInstantiate(instanceID);
				freeframe.Dispose();
			}
			if(webcam != null)
			{
				webcam.Dispose();
				webcam = null;
			}
			if(video != null)
			{
				video.Dispose();
				video = null;
			}
		}

		#region Windows Form Designer generated code
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{
			this.pictureBox1 = new System.Windows.Forms.PictureBox();
			this.pictureBox2 = new System.Windows.Forms.PictureBox();
			this.label1 = new System.Windows.Forms.Label();
			this.listBox1 = new System.Windows.Forms.ListBox();
			this.trkParam = new System.Windows.Forms.TrackBar();
			this.listBox2 = new System.Windows.Forms.ListBox();
			this.lblParam = new System.Windows.Forms.Label();
			this.txtVideoFile = new System.Windows.Forms.TextBox();
			this.rdoVideoInput = new System.Windows.Forms.RadioButton();
			this.rdoWebcamInput = new System.Windows.Forms.RadioButton();
			this.lblVideoFile = new System.Windows.Forms.Label();
			this.btnVideoBrowse = new System.Windows.Forms.Button();
			this.btnPlay = new System.Windows.Forms.Button();
			((System.ComponentModel.ISupportInitialize)(this.trkParam)).BeginInit();
			this.SuspendLayout();
			// 
			// pictureBox1
			// 
			this.pictureBox1.BackColor = System.Drawing.Color.Black;
			this.pictureBox1.Location = new System.Drawing.Point(8, 8);
			this.pictureBox1.Name = "pictureBox1";
			this.pictureBox1.Size = new System.Drawing.Size(320, 240);
			this.pictureBox1.TabIndex = 1;
			this.pictureBox1.TabStop = false;
			// 
			// pictureBox2
			// 
			this.pictureBox2.BackColor = System.Drawing.Color.Black;
			this.pictureBox2.Location = new System.Drawing.Point(336, 8);
			this.pictureBox2.Name = "pictureBox2";
			this.pictureBox2.Size = new System.Drawing.Size(320, 240);
			this.pictureBox2.TabIndex = 2;
			this.pictureBox2.TabStop = false;
			this.pictureBox2.Paint += new System.Windows.Forms.PaintEventHandler(this.pictureBox2_Paint);
			// 
			// label1
			// 
			this.label1.Location = new System.Drawing.Point(704, 352);
			this.label1.Name = "label1";
			this.label1.Size = new System.Drawing.Size(96, 16);
			this.label1.TabIndex = 3;
			// 
			// listBox1
			// 
			this.listBox1.Location = new System.Drawing.Point(664, 8);
			this.listBox1.Name = "listBox1";
			this.listBox1.Size = new System.Drawing.Size(136, 238);
			this.listBox1.TabIndex = 4;
			this.listBox1.SelectedIndexChanged += new System.EventHandler(this.listBox1_SelectedIndexChanged);
			// 
			// trkParam
			// 
			this.trkParam.Location = new System.Drawing.Point(160, 256);
			this.trkParam.Maximum = 100;
			this.trkParam.Name = "trkParam";
			this.trkParam.Size = new System.Drawing.Size(424, 45);
			this.trkParam.TabIndex = 10;
			this.trkParam.TickFrequency = 10;
			this.trkParam.Scroll += new System.EventHandler(this.trkParam_Scroll);
			// 
			// listBox2
			// 
			this.listBox2.Location = new System.Drawing.Point(8, 256);
			this.listBox2.Name = "listBox2";
			this.listBox2.Size = new System.Drawing.Size(144, 108);
			this.listBox2.TabIndex = 8;
			this.listBox2.SelectedIndexChanged += new System.EventHandler(this.listBox2_SelectedIndexChanged);
			// 
			// lblParam
			// 
			this.lblParam.Location = new System.Drawing.Point(584, 264);
			this.lblParam.Name = "lblParam";
			this.lblParam.Size = new System.Drawing.Size(56, 16);
			this.lblParam.TabIndex = 11;
			// 
			// txtVideoFile
			// 
			this.txtVideoFile.Location = new System.Drawing.Point(168, 320);
			this.txtVideoFile.Name = "txtVideoFile";
			this.txtVideoFile.Size = new System.Drawing.Size(416, 20);
			this.txtVideoFile.TabIndex = 12;
			this.txtVideoFile.Text = "";
			// 
			// rdoVideoInput
			// 
			this.rdoVideoInput.Checked = true;
			this.rdoVideoInput.Location = new System.Drawing.Point(656, 264);
			this.rdoVideoInput.Name = "rdoVideoInput";
			this.rdoVideoInput.Size = new System.Drawing.Size(144, 16);
			this.rdoVideoInput.TabIndex = 13;
			this.rdoVideoInput.TabStop = true;
			this.rdoVideoInput.Text = "Video Input";
			// 
			// rdoWebcamInput
			// 
			this.rdoWebcamInput.Location = new System.Drawing.Point(656, 288);
			this.rdoWebcamInput.Name = "rdoWebcamInput";
			this.rdoWebcamInput.Size = new System.Drawing.Size(144, 16);
			this.rdoWebcamInput.TabIndex = 14;
			this.rdoWebcamInput.Text = "Webcam Input";
			// 
			// lblVideoFile
			// 
			this.lblVideoFile.Location = new System.Drawing.Point(168, 304);
			this.lblVideoFile.Name = "lblVideoFile";
			this.lblVideoFile.Size = new System.Drawing.Size(208, 16);
			this.lblVideoFile.TabIndex = 15;
			this.lblVideoFile.Text = "Video File";
			// 
			// btnVideoBrowse
			// 
			this.btnVideoBrowse.Location = new System.Drawing.Point(592, 320);
			this.btnVideoBrowse.Name = "btnVideoBrowse";
			this.btnVideoBrowse.Size = new System.Drawing.Size(40, 24);
			this.btnVideoBrowse.TabIndex = 16;
			this.btnVideoBrowse.Text = "...";
			this.btnVideoBrowse.Click += new System.EventHandler(this.btnVideoBrowse_Click);
			// 
			// btnPlay
			// 
			this.btnPlay.Location = new System.Drawing.Point(168, 344);
			this.btnPlay.Name = "btnPlay";
			this.btnPlay.Size = new System.Drawing.Size(104, 24);
			this.btnPlay.TabIndex = 17;
			this.btnPlay.Text = "Play";
			this.btnPlay.Click += new System.EventHandler(this.btnPlay_Click);
			// 
			// Form1
			// 
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(808, 374);
			this.Controls.Add(this.btnPlay);
			this.Controls.Add(this.btnVideoBrowse);
			this.Controls.Add(this.lblVideoFile);
			this.Controls.Add(this.rdoWebcamInput);
			this.Controls.Add(this.rdoVideoInput);
			this.Controls.Add(this.txtVideoFile);
			this.Controls.Add(this.lblParam);
			this.Controls.Add(this.listBox2);
			this.Controls.Add(this.trkParam);
			this.Controls.Add(this.listBox1);
			this.Controls.Add(this.label1);
			this.Controls.Add(this.pictureBox2);
			this.Controls.Add(this.pictureBox1);
			this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
			this.MaximizeBox = false;
			this.Name = "Form1";
			this.Text = "FreeFrame .NET Test";
			((System.ComponentModel.ISupportInitialize)(this.trkParam)).EndInit();
			this.ResumeLayout(false);

		}
		#endregion

		/// <summary>
		/// The main entry point for the application.
		/// </summary>
		[STAThread]
		static void Main() 
		{
			Application.Run(new Form1());
		}

		private void GetPlugins()
		{
			DirectoryInfo di = new DirectoryInfo(Application.StartupPath + "\\plugins");
			foreach(FileInfo fi in di.GetFiles("*.dll")) 
			{
				listBox1.Items.Add(System.IO.Path.GetFileName(fi.FullName));
			}
		}

		private void listBox1_SelectedIndexChanged(object sender, System.EventArgs e)
		{
			if (bPluginLoaded)
			{
				freeframe.deInstantiate(instanceID);
				freeframe.Dispose();
				bPluginLoaded = false;
			}

			freeframe = new FreeFrame(Application.StartupPath + "\\plugins", listBox1.SelectedItem.ToString()); // "MultipleStripsNEW.dll" "PeteLiveFeed2.dll"
			
			//if((int) freeframe.Supports32BitVideo == (int) FreeFrame.ReturnCode.FF_SUPPORTED)
			//{
			//	instanceID = freeframe.instantiate(320, 240, (uint) FreeFrame.PixelFormat.Format32bppArgb,(uint) FreeFrame.Orientation.OriginTopLeft);
			//	webcam.PixelFormat = PixelFormat.Format32bppArgb;
			//}
			//else
			if((int) freeframe.Supports24BitVideo == (int) FreeFrame.ReturnCode.FF_SUPPORTED)
			{
				instanceID = freeframe.instantiate(320, 240, (uint) FreeFrame.PixelFormat.Format24bppRgb,(uint) FreeFrame.Orientation.OriginTopLeft);
				webcam.PixelFormat = PixelFormat.Format24bppRgb;
			}
			else
			{
				freeframe.Dispose();
				return;
			}

			listBox2.Items.Clear();
			foreach (String param in freeframe.parameterName)
			{
				listBox2.Items.Add(param);
			}

			bPluginLoaded = true;
			pictureBox2.Refresh();
		}

		protected void RenderVideo()
		{
			IntPtr ip = IntPtr.Zero;
			ip = video.GetBitmap();
			if(ip != IntPtr.Zero)
			{
				Bitmap bmp = video.IPToBmp(ip);
				pictureBox1.Image = bmp;
				freeframe.processFrame(instanceID, ref bmp);
				label1.Text = freeframe.elapsedTime.ToString() + " msec/frame";
				pictureBox2.Image = bmp;
				System.Runtime.InteropServices.Marshal.FreeCoTaskMem(ip);
				ip = IntPtr.Zero;
				pictureBox1.Refresh();
			}
		}

		protected void RenderWebcam()
		{
			IntPtr ip = IntPtr.Zero;
			ip = webcam.GetBitmap();
			if(ip != IntPtr.Zero)
			{
				Bitmap bmp = webcam.IPToBmp(ip);
				pictureBox1.Image = bmp;
				freeframe.processFrame(instanceID, ref bmp);
				label1.Text = freeframe.elapsedTime.ToString() + " msec/frame";
				pictureBox2.Image = bmp;
				System.Runtime.InteropServices.Marshal.FreeCoTaskMem(ip);
				ip = IntPtr.Zero;
				pictureBox1.Refresh();
			}
		}

		private void pictureBox2_Paint(System.Object sender, System.Windows.Forms.PaintEventArgs e)
		{
			try
			{
				if(bPluginLoaded)
				{
					if(rdoVideoInput.Checked)
						RenderVideo();
					else
						RenderWebcam();
				}
			}
			catch
			{
			}
		}

		protected void video_StopPlay(Object o)
		{
			video.Rewind();
			video.Start();
		}

		private void listBox2_SelectedIndexChanged(object sender, System.EventArgs e)
		{
			if (listBox2.SelectedIndex != -1)
			{
				selectedParam = listBox2.SelectedIndex;
				selectedParamValue = freeframe.getParameter(instanceID, (uint) selectedParam);
				if (selectedParamValue <= 1)
				{
					trkParam.Value = (int) (selectedParamValue * 100);
					lblParam.Text = freeframe.getParameterDisplay(instanceID, (uint) selectedParam);
				}
			}
		}

		private void trkParam_Scroll(object sender, System.EventArgs e)
		{
			if(selectedParam != -1)
			{
				selectedParamValue = (float) trkParam.Value / 100;
				freeframe.setParameter(instanceID, (uint) selectedParam, selectedParamValue);
				lblParam.Text = freeframe.getParameterDisplay(instanceID, (uint) selectedParam);
			}
		}

		private void btnVideoBrowse_Click(object sender, System.EventArgs e)
		{
			OpenFileDialog fd = new OpenFileDialog();

			fd.InitialDirectory = Application.StartupPath;
			fd.Filter = "Video Files (*.mpg; *.avi; *.mpeg;)|*.mpg; *.mpeg; *.avi; | All Files (*.*)|*.*";

			if(fd.ShowDialog(null) == DialogResult.OK)
			{
				if(fd.CheckFileExists)
					txtVideoFile.Text = fd.FileName;
			}
		}

		private void btnPlay_Click(object sender, System.EventArgs e)
		{
			if(video != null)
			{
				video.Dispose();
				video = null;
			}
			video = new Video(txtVideoFile.Text);
			video.Start();
			video.StopPlay += new Video.DxPlayEvent(video_StopPlay);
		}
	}
}
