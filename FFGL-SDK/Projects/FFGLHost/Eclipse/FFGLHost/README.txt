Eclipse Project setup for Windows with MinGW

Setup:
1. Make sure you have your Toolchain for cdt setup. Some good information
can be found with a little googling. This was a good resource as well:
http://www.ritgamedev.com/tutorials/glutEclipse/. My environment uses 
the following:
- MinGW 5.1.4
- MSys 1.0.10
- GDB 6.3 (I had issues with the newer versions of GBD + CDT)
- GLUT MinGW

2. The current project setup requires the Ant plugins for Eclipse which do not
come with the Ganymede CDT project by default. The easiest way to install
this is to add it from the Ganymede update site (or the update site for your
version of eclipse):
- Help > Software Updates... > Available Softare 
  - select Ganymede Update Site > Java Development > Eclipse Java Development Tools
  - click install and follow the installation instructions.
Otherwise, you can deselect the Ant builders that move files into the SDK
binaries folders. See the notes for more information.

3. Set your Eclipse workspace to the FFGL SDK Eclipse folder
- File > Switch Workspace... > Other
  - set the workspace directory to [FFGL_SDK_root]/Projects/FFGLHost/Eclipse 

4. You will need to change the FFGLSDKHome variable path for the project to match
the location of your FFGL SDK checkout. You can do this by changing the FFGLSDKHome
path variable that is already setup:
- Project > Properties > C/C++ General > Paths and Symbols
  - Select the Source Location tab
  - Click Link Folder
  - Check Link to folder in the file system
  - Click on Variables
  - Edit the path variable in the list
  - Change the value of the variable to the root folder path to the FFGL SDK on your 
    system (ex. C:\path\to\FFGL-SDK)
  - Click Ok, Ok, Cancel (this is the New Folder dialog), Ok
Alternatively you can just relink each of the source code folders to match your
system or you can edit the Eclipse properties file directly by opening (Advanced users):
- [FFGLSDK_Eclipse_Project_Folder]/.metadata/.plugins/org.eclipse.core.runtime
  /.settings/org.eclipse.core.resources.prefs
  - Change the pathvariable.FFGLSDKHome path to match the folder path where your
    FFGL SDK root folder is. Any colons need to be escaped with a backslash and
    you should use forward slashes for folder separators (ex. C\:/path/to/SDK/root)
  - If the source code folders do not show any content when you open the FFGLHost
    project, try refreshing the project from the context menu. 

5. When you want to run the project, there is an FFGLHost run/debug configuration.
However, you will need to edit the source code mapping to match the 
location of your code:
- Run > Run Configurations > C++/C Local Application > FFGLHost
  - Click on the Source tab
  - Click Path Mappings : Found Mappings
  - Click Edit
  - Click on the mapping in the list and click Edit to change it.
  - Change the location to match the root of your FFGL SDK checkout.
  - Repeat for both run/debug configurations 
Alternatively, you can open the open the *.launch configuration files with a text
editor and replace references to PATH_TO_FFGL_SDK with the path to the root of your 
SDK install.

Notes:
I've added a builder that moves both the Debug and Release versions
of the output executable into the binaries folder of the FFGLSDK
on successful builds. You can deactivate these by:
- Project > Properties > Builders
  - Deselect the Move FFGLHost

This FFGLHost project was created and tested on Windows Vista using 
the MinGW ToolChain. You should be able to use it with Cygwin or other
tool chains but you may need to change the tool chain settings from
the project properties menu. You may also find that the FreeFrame SDK is
is not compatible with other compiler types. See the FreeFrame SourceForge
site for more details.  

TODO:
Find a way to make the source folder paths relative.

Create a FreeFrame Eclipse plugin that makes setting up these projects simpler.

Log a CDT feature request to be able to utilize environment variables in the 
Source Path urls.

Create OSX and Linux project versions of these Eclipse projects.