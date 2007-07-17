---------------
FreeFrameGL SDK

Host and Plugin Binaries for OSX
compiled by Trey Harrison - www.harrisondigitalmedia.com
--------------------------------------------------------

To test the binaries on OSX, open a terminal window, navigate to the Binaries/OSX
folder, and run ./FFGLHost (for some reason, running FFGLHost from the finder does
not work because the finder doesnt start the application in its own directory)

The host assigns the mouse X position to  plugin #1 parameter #0 and 
the mouse Y position to plugin #2 parameter #0.

The host is hard-coded to use FFGLBrightness as plugin #1 and FFGLTile as
plugin #2. To use different plugins, you have to edit OSXMain.cpp and recompile.
