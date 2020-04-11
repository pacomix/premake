globalScriptDir = os.getcwd()

if buildSystem == "vs2008" or buildSystem == "vs2010" or buildSystem == "vs2012" then
projectLocation = "."	-- Specifies where the project file should be generated.
projectBaseName = tempSlnPrefix .. ""
projectName = projectBaseName .. buildSystemSuffix -- NOTE: For solutions/projects that shouldn't need a suffix ( ending in 90/100) just delete the buildSystemSuffix variable here.
projectGUID = ""
projectAssemblyName = "" -- Only C#. Specifies the Project's AssemblyName
outputFolder = "" -- If this variable is not used the specific ones (vars: outputFolderXXXXXXXXXXXXXXXXXX) will be the used instead. 
                  -- Tipically this field will contain the path to the brunch-trunk/shared folder.
                  -- When using this variable to specify the output path an additional subdirectory is added based on the output type 
                  -- (SharedLib, StaticLib, ConsoleApp), platform (x64, x32/Win32, Xbox360, etc) and build configuration.
outputTarget = projectName -- If this variable is not used the specific ones (vars: outputTargetXXXXXX) will be the used instead. Tipically this field will contain: projectName

projectPropertySheet = ""  -- Property sheet filename. The filename should be only the path + suffix of the filename. Based in the build configuration the correct file is later 
													  -- generated for each one. IE: "../../shared/property/VisionApp" would generate for a Debug|Xbox360 config the next filename: "../../shared/property/VisionAppDebugXbox360.vsprops"

-- IMPORTANT: Build configs for this project. These are the configurations that will be marked to be built. IE:
local projectBuildConfigsWin = { "Debug|x32", "Debug DX11|x32", "Release|x32", "Release DX11|x32", "Debug|x64", "Debug DX11|x64",  "Release|x64", "Release DX11|x64" }
local projectBuildConfigsConsoles = { "Debug|PS3", "Release|PS3", "Debug|PSVita", "Release|PSVita", "Debug|Xbox360", "Release|Xbox360" }

-- IMPORTANT: Build configurations that composes the project. IE:
local buildConfigsForProjectWin = { "Debug", "Debug DX11", "Release", "Release DX11" }
local buildConfigsForProjectConsoles = { }

-- IMPORTANT: Target platforms that composes the project. NOTE: PS3 and PSP2 are treated as build configurations. IE:
local buildPlatformsForProjectWin = { "x32", "x64" }
local buildPlatformsForProjectConsoles = { "Xbox360", "PS3", "PSVita" }

if buildSystem == "vs2008" then
  projectBuildConfigs = { projectBuildConfigsWin, projectBuildConfigsConsoles }
  buildConfigsForProject = { buildConfigsForProjectWin, buildConfigsForProjectConsoles }
  buildPlatformsForProject = { buildPlatformsForProjectWin, buildPlatformsForProjectConsoles }
elseif buildSystem == "vs2010" then
  projectBuildConfigs = { projectBuildConfigsWin, "Debug|PS3", "Release|PS3", "Debug|PSVita", "Release|PSVita", "Debug|Xbox360", "Release|Xbox360" }
  buildConfigsForProject = { buildConfigsForProjectWin }
  buildPlatformsForProject = { buildPlatformsForProjectWin, buildPlatformsForProjectConsoles }
elseif buildSystem == "vs2012" then
  projectBuildConfigs = { projectBuildConfigsWin, "Debug|arm", "Release|arm"}
  buildConfigsForProject = { buildConfigsForProjectWin }
  buildPlatformsForProject = { buildPlatformsForProjectWin, "Arm" }
end

projectLanguage = "Default" -- Project's language: C, C++, Default

projectReferences = { }

if includeBuildConfigs == nil or includeBuildConfigs == "" then
  includeBuildConfigs = projectBuildConfigs
end

-- Specific output folders. See description of variable outputFolder
outputFolderDebugWin32 = ""
outputFolderDebugDX11Win32 = ""
outputFolderDebugNoXIWin32 = ""
outputFolderDebugStaticWin32 = ""
outputFolderDebugX64 = ""
outputFolderDebugDX11X64 = ""
outputFolderDebugNoXIX64 = ""
outputFolderDebugStaticX64 = ""
outputFolderReleaseWin32 = ""
outputFolderReleaseDX11Win32 = ""
outputFolderReleaseNoXIWin32 = ""
outputFolderReleaseStaticWin32 = ""
outputFolderReleaseX64 = ""
outputFolderReleaseDX11X64 = ""
outputFolderReleaseNoXIX64 = ""
outputFolderReleaseStaticX64 = ""
outputFolderDebugPS3 = ""
outputFolderReleasePS3 = ""
outputFolderDebugPSP2 = ""
outputFolderReleasePSP2 = ""
outputFolderDebugXbox360 = ""
outputFolderReleaseXbox360 = ""

-- Specific output target name. See description of variable outputTarget
outputTargetDebugWin32 = ""
outputTargetDebugDX11Win32 = ""
outputTargetDebugNoXIWin32 = ""
outputTargetDebugStaticWin32 = ""
outputTargetDebugStaticMTWin32 = ""
outputTargetDebugX64 = ""
outputTargetDebugDX11X64 = ""
outputTargetDebugNoXIX64 = ""
outputTargetDebugStaticX64 = ""
outputTargetDebugStaticMTX64 = ""
outputTargetReleaseWin32 = ""
outputTargetReleaseDX11Win32 = ""
outputTargetReleaseNoXIWin32 = ""
outputTargetReleaseStaticWin32 = ""
outputTargetReleaseStaticMTWin32 = ""
outputTargetReleaseX64 = ""
outputTargetReleaseDX11X64 = ""
outputTargetReleaseNoXIX64 = ""
outputTargetReleaseStaticX64 = ""
outputTargetReleaseStaticMTX64 = ""
outputTargetDebugPS3 = ""
outputTargetReleasePS3 = ""
outputTargetDebugPSP2 = ""
outputTargetReleasePSP2 = ""
outputTargetDebugXbox360 = ""
outputTargetReleaseXbox360 = ""

printf("\tProcessing: %s", projectName)

-- PREPROCESSOR DEFINITIONS -------- PROCESSED BY VS2PREMAKE.-------------------------
-- Platform defines
definesPS3 = "" -- Defines for PS3 platform
definesPSP2 = "" -- Defines for PSP2 platform
definesX86 = "" -- Defines for Windows platform
definesX64 = "" -- Defines for Windows x64 platform
definesXbox360 = "" -- Defines for Xbox360 platform

-- Build configurations defines
definesSharedLib = ""	-- Defines for a .dll output type
definesStaticLib = ""   -- Defines for a .lib output type
definesStaticLibMT = ""
definesDebug = ""       -- Defines for all Debug builds
definesRelease = ""     -- Defines for all Release builds
definesDX11 = ""        -- Defines for DX11 builds

definesDebugX86 = ""    -- Defines for Debug Windows 32bits platforms only
definesReleaseX86 = ""  -- Defines for Release Windows 32bits platforms only

definesDebugX64 = ""    -- Defines for Debug Windows 64bits platforms only
definesReleaseX64 = ""  -- Defines for Release Windows 64bits platforms only

definesDebugPS3 = ""  	-- Defines for Debug PS3 builds
definesReleasePS3 = ""  -- Defines for Release PS3 builds

definesDebugPSP2 = "" 	-- Defines for Debug PSP2 builds
definesReleasePSP2 = "" -- Defines for Release PSP2 builds

definesDebugXbox360 = ""	-- Defines for Debug Xbox360 builds
definesReleaseXbox360 = ""  -- Defines for Release Xbox360 builds

-- Output Type. Can be SharedLib, StaticLib, ConsoleApp, WindowedApp
bIsEnginePlugin = false
outputTypeWin = ""
outputTypeXbox360 = ""
outputTypePS3 = ""
outputTypePSP2 = ""

-- Specific PS3 section
bIsSPU = false -- Indicates that the project is a SPU project

-- Include dirs  -- PROCESSED BY VS2PREMAKE.
includeDirsCommon   = ""
includeDirsWin32    = ""
includeDirsX64      = ""
includeDirsXbox360  = ""
includeDirsPS3      = ""
includeDirsPSP2     = ""

-- Lib dirs -- PROCESSED BY VS2PREMAKE.
libDirsCommon        = { } -- this line is ignored by VS2Premake.
libDirsAllWin32      = ""
libDirsAllX64        = ""
libDirsStaticWin32   = ""
libDirsWin32         = ""
libDirsStaticX64     = ""
libDirsX64           = ""

local libDirsDebugAllWin    = { }
local libDirsReleaseAllWin  = { }
libDirsDebugWin32	 = { libDirsDebugAllWin }
libDirsReleaseWin32  = { libDirsReleaseAllWin }
libDirsDebugX64 	 = { libDirsDebugAllWin }
libDirsReleaseX64    = { libDirsReleaseAllWin }

libDirsDebugXbox360   = ""
libDirsReleaseXbox360 = ""
libDirsXbox360       = ""
libDirsPS3           = ""
libDirsDebugPS3      = ""
libDirsReleasePS3    = ""
libDirsPSP2          = ""
libDirsDebugPSP2     = ""
libDirsReleasePSP2   = ""

-- Link libs -- PROCESSED BY VS2PREMAKE.
libLinkAllWindows          = ""  -- For C# projects this is the variable used for the references.
libLinkShared              = "" 
libLinkDx11                = "" 

libLinkDebugAllWin32       = "" 
libLinkDebugAllx64         = "" 
libLinkReleaseAllWin32     = "" 
libLinkReleaseAllx64       = "" 
--
libLinkDebugStaticWin32    = "" 
libLinkDebugDx9Win32       = "" 
libLinkDebugDx11Win32      = "" 
libLinkDebugNoXIWin32      = "" 

libLinkReleaseStaticWin32  = "" 
libLinkReleaseDx9Win32     = "" 
libLinkReleaseDx11Win32    = "" 
libLinkReleaseNoXIWin32    = "" 

libLinkDebugStaticX64      = "" 
libLinkDebugDx9x64         = "" 
libLinkDebugDx11x64        = "" 
libLinkDebugNoXIx64        = "" 

libLinkReleaseStaticX64    = "" 
libLinkReleaseDx9x64       = "" 
libLinkReleaseDx11x64      = "" 
libLinkReleaseNoXIx64      = "" 

libLinkDebugXbox360        = ""
libLinkReleaseXbox360      = ""

libLinkDebugPS3            = ""
libLinkReleasePS3          = ""

libLinkDebugPSP2            = ""
libLinkReleasePSP2          = ""
------

-- Stack Reserve/Commit size.
stackReserveDebugWin32 = ""
stackReserveDebugDX11Win32 = ""
stackReserveDebugNoXIWin32 = ""
stackReserveDebugStaticWin32 = ""
stackReserveDebugX64 = ""
stackReserveDebugDX11X64 = ""
stackReserveDebugNoXIX64 = ""
stackReserveDebugStaticX64 = ""
stackReserveReleaseWin32 = ""
stackReserveReleaseDX11Win32 = ""
stackReserveReleaseNoXIWin32 = ""
stackReserveReleaseStaticWin32 = ""
stackReserveReleaseX64 = ""
stackReserveReleaseDX11X64 = ""
stackReserveReleaseNoXIX64 = ""
stackReserveReleaseStaticX64 = ""
stackReserveDebugPS3 = ""
stackReserveReleasePS3 = ""
stackReserveDebugPSP2 = ""
stackReserveReleasePSP2 = ""
stackReserveDebugXbox360 = ""
stackReserveReleaseXbox360 = ""

stackCommitDebugWin32 = ""
stackCommitDebugDX11Win32 = ""
stackCommitDebugNoXIWin32 = ""
stackCommitDebugStaticWin32 = ""
stackCommitDebugX64 = ""
stackCommitDebugDX11X64 = ""
stackCommitDebugNoXIX64 = ""
stackCommitDebugStaticX64 = ""
stackCommitReleaseWin32 = ""
stackCommitReleaseDX11Win32 = ""
stackCommitReleaseNoXIWin32 = ""
stackCommitReleaseStaticWin32 = ""
stackCommitReleaseX64 = ""
stackCommitReleaseDX11X64 = ""
stackCommitReleaseNoXIX64 = ""
stackCommitReleaseStaticX64 = ""
stackCommitDebugPS3 = ""
stackCommitReleasePS3 = ""
stackCommitDebugPSP2 = ""
stackCommitReleasePSP2 = ""
stackCommitDebugXbox360 = ""
stackCommitReleaseXbox360 = ""

buildTempDir = "intermediates"
callConvention = "" -- cdecl, fastcall, or stdcall

-- Flags ------------------------------------------------------------------------------------------------
--[[
   EnableSSE, EnableSSE2
      Use the SSE instruction sets for floating point math.
   ExtraWarnings                                FatalWarnings
   Sets the compiler's maximum warning level.   Treat warnings as errors.
   
   FloatFast                                                         FloatStrict
   Enable floating point optimizations at the expense of accuracy.   Improve floating point consistency at the expense of performance.
   
   Managed
      Enable Managed C++ (.NET).
   MFC
      Enable support for Microsoft Foundation Classes.
   NativeWChar, NoNativeWChar
      Enable or disable support for the wchar data type. If no flag is specified, the toolset default will be used.
   No64BitChecks
      Disable 64-bit portability warnings.
   NoEditAndContinue
      Disable support for Visual Studio's Edit-and-Continue feature.
   NoExceptions
      Disable C++ exception support.
   NoFramePointer
      Disable the generation of stack frame pointers.
   NoIncrementalLink
      Disable support for Visual Studio's incremental linking feature.
   NoImportLib
      Prevent the generation of an import library for a Windows DLL.
   NoManifest
      Prevent the generation of a manifest for Windows executables and shared libraries.
   NoMinimalRebuild
      Disable Visual Studio's minimal rebuild feature.
   NoPCH
      Disable precompiled header support. If not specified, the toolset default behavior will be used. Also see pchheader and pchsource.
   NoRTTI
      Disable C++ runtime type information.
      
   Optimize                                  OptimizeSize                           OptimizeSpeed
   Perform a balanced set of optimizations.  Optimize for the smallest file size.   Optimize for the best performance.
   
   SEH
      Enable structured exception handling.
   StaticRuntime
      Perform a static link against the standard runtime libraries.
   Symbols
      Generate debugging information.
   Unicode
      Enable Unicode strings. If not specified, the default toolset behavior is used.
   Unsafe
      Enable the use of unsafe code in .NET applications.
   WinMain
      Use WinMain() as the program entry point for Windows applications, rather than the default main().
      
   -- Added by Trinigy
   NoIncrementalLink
   VSBufferSecurityCheck
   VSNoBasicRuntimeCheck
   VSEnableFunctionLevelLinking
   VSEnableIntrinsicFunctions
   VSFavorSpeed or VSFavorSize
   VSNoStringPooling
   VSNoOptimizeReferences
   VSNoCOMDATFolding
   VSNoTargetMachine
   VSNoSubSystem
   VSUseReferencesInProjects
   Build  -- Whether build or not the project for the configuration
   MinWarnings -- Warning Level1
   GenerateStrippedSymbols - Enables the output of the .pdb file without private symbols
   NoLinkLibDependencies - Do not link against dependent projects.
   CSTargetAnyCPU -- Make C# projects target AnyCPU instead of the current selected platform for the build configuration.
   CSGenerateDoc -- Generates a .doc.xml file with the code documentation in the target directory with the same name as the assembly.
--]]

-- Link flags variable helpers
flagsStatic = { "StaticRuntime", "NoLinkLibDependencies" }  -- <--- Only an example.

flagsAllWindows = { "Symbols", "NoEditAndContinue", "FatalWarnings", "NoImportLib" }
flagsDebugAllWindows = ""
flagsReleaseAllWindows = { "Optimize", "FloatFast", "VSNoBasicRuntimeCheck", "VSEnableFunctionLevelLinking", 
							"VSEnableIntrinsicFunctions", "VSFavorSpeed", "NoFramePointer" } -- default project optimizations. These are required for every project.

-- Link flags for the different build configurations/platforms.
flagsDebugWin32 = { flagsAllWindows, flagsDebugAllWindows, "" }
flagsReleaseWin32 = { flagsAllWindows, flagsReleaseAllWindows, "" }
flagsDebugX64 = { flagsAllWindows, flagsDebugAllWindows, "" }
flagsReleaseX64 = { flagsAllWindows, flagsReleaseAllWindows, "" }
flagsStaticWin = flagsStatic
flagsStaticMTWin = flagsStatic

flagsAllXbox360 = ""
flagsDebugXbox360 = ""
flagsReleaseXbox360 = ""

flagsAllPS3 = ""
flagsDebugPS3 = ""
flagsReleasePS3 = ""

flagsAllPSP2 = ""
flagsDebugPSP2 = ""
flagsReleasePSP2 = ""

-- additional build options ---
buildOptAllWin = "/MP" -- Typical build option
buildOptAllDebugWin =   ""
buildOptAllReleaseWin = ""

buildOptDebugStaticWin32 =    ""
buildOptDebugStaticMTWin32 =  ""
buildOptDebugWin32 =          ""

buildOptDebugStaticX64 =   ""
buildOptDebugStaticMTX64 = ""
buildOptDebugX64 =         ""

buildOptReleaseStaticWin32 =     ""
buildOptReleaseStaticMTWin32 =   ""
buildOptReleaseWin32 =           ""

buildOptReleaseStaticX64 =    ""
buildOptReleaseStaticMTX64 =  ""
buildOptReleaseX64 =          ""

buildOptAllXbox360 = ""
buildOptDebugXbox360 =     ""
buildOptReleaseXbox360 =   ""

buildOptAllPS3 = ""
buildOptDebugPS3 =   ""
buildOptReleasePS3 = ""

buildOptAllPSP2 = ""
buildOptDebugPSP2 =   ""
buildOptReleasePSP2 = ""

-- Pre-build commands
preBuildDebugWin = ""
preBuildReleaseWin = ""
preBuildDebugWinX64 = ""
preBuildReleaseWinX64 = ""
preBuildXbox360 = ""
preBuildPS3 = ""
preBuildPSP2 = ""

preBuildDescWin = "Executing Pre-Build Step..."
preBuildDescWinX64 = "Executing Pre-Build Step..."
preBuildDescXbox360 = "Executing Pre-Build Step..."
preBuildDescPS3 = "Executing Pre-Build Step..."
preBuildDescPSP2 = "Executing Pre-Build Step..."

-- Post-build commands
postBuildWin = ""
postBuildNoXI = ""
postBuildNoXIX64 = ""
postBuildXbox360 = ""
postBuildPS3 = ""
postBuildPSP2 = ""

postBuildDescWin = ""
postBuildDescNoXI = ""
postBuildDescXbox360 = ""
postBuildDescPS3 = ""
postBuildDescPSP2 = ""

-- additional linker options ---
linkOptAllStaticWin = ""
linkOptDebugNonStaticWin = ""
linkOptDebugStaticWin32 =  ""
linkOptDebugWin32 =        ""

linkOptReleaseNonStaticWin = ""
linkOptReleaseStaticWin32 = ""
linkOptReleaseWin32 = ""

linkOptDebugStaticX64 = ""
linkOptDebugX64 = ""

linkOptReleaseStaticX64 = ""
linkOptReleaseX64 = ""

linkOptDebugXbox360 = ""
linkOptReleaseXbox360 = ""

linkOptDebugPS3 = ""
linkOptReleasePS3 = ""

linkOptDebugPSP2 = ""
linkOptReleasePSP2 = ""

-- Disable warnings ---------------------------------------
disableWarningsDebugWin32 = ""
disableWarningsReleaseWin32 = ""

disableWarningsDebugX64 = ""
disableWarningsReleaseX64 = ""

disableWarningsDebugXbox360 = ""
disableWarningsReleaseXbox360 = ""

disableWarningsDebugPS3 = ""
disableWarningsReleasePS3 = ""

disableWarningsDebugPSP2 = ""
disableWarningsReleasePSP2 = ""

-- ForcedUsingFiles ---------------------------------------
forcedUsingFilesDebugWin32 = ""
forcedUsingFilesReleaseWin32 = ""

forcedUsingFilesDebugX64 = ""
forcedUsingFilesReleaseX64 = ""

forcedUsingFilesDebugXbox360 = ""
forcedUsingFilesReleaseXbox360 = ""

forcedUsingFilesDebugPS3 = ""
forcedUsingFilesReleasePS3 = ""

forcedUsingFilesDebugPSP2 = { }
forcedUsingFilesReleasePSP2 = { }

-----------------------------------------------------------

------------------------------------
---- Windows specific --------------
-- Delayed .dll loads
delayDllCommon    =     ""
delayDllXICommon  =     ""
delayDebugWin32   =     ""
delayDebugDX11Win32 =   ""
delayDebugNoXIWin32 =   ""

delayReleaseWin32   =    ""
delayReleaseDX11Win32 =  ""
delayReleaseNoXIWin32 =  ""

delayDebugX64   =      ""
delayDebugDX11X64 =    ""
delayDebugNoXIX64 =    ""

delayReleaseX64   =    ""
delayReleaseDX11X64 =  ""
delayReleaseNoXIX64 =  ""

-- Ignored libs
ignoreDefaultLibsAll = ""
ignoreDefaultLibsDebug = { ignoreDefaultLibsAll }
ignoreDefaultLibsRelease = { ignoreDefaultLibsAll }
ignoreDefaultLibsDebugX64 = { ignoreDefaultLibsAll }
ignoreDefaultLibsReleaseX64 = { ignoreDefaultLibsAll }
ignoreDefaultLibsStaticDebug = { ignoreDefaultLibsAll }
ignoreDefaultLibsStaticRelease = { ignoreDefaultLibsAll }
ignoreDefaultLibsStaticDebugX64 = { ignoreDefaultLibsAll }
ignoreDefaultLibsStaticReleaseX64 = { ignoreDefaultLibsAll }
ignoreDefaultLibsDebugXbox = { ignoreDefaultLibsAll }
ignoreDefaultLibsReleaseXbox = { ignoreDefaultLibsAll }
---- Windows Specific --------------
------------------------------------

-- Misc
culture = "1031" -- for the resource compiler 1031 == 0x407 Germany. Usually not used.

-- Define here the file list that is used by the project.
-- For every subfolder a new filter is automatically created for the projects.
-- You can use as many variables you need to better organize the file list
-- but at the end the variable that is used to define the whole source files is
-- 'sourceFiles'. So you always need at the end to fill that variable with the
-- whole file list.

-- You also may define the excluded files variables for the different platforms:
--    excludedSourcesWindows
--    excludedSourcesXbox360
--    excludedSourcesPS3
--    excludedSourcesPSP2

-- WARNING: Be sure that the filename casing matches the filename you write here.

sourceHeaderPCHXbox360 = "" -- Sets the correct precompiled header option for Xbox360 when using property sheets.
sourceHeaderPCH = "StdAfx.h"
sourcePCH = "./src/StdAfx.cpp"
sourcesNotUsingPCH = { "" }

excludedSourcesWindows = { "" } 
excludedSourcesWindowsNoXI = { "" }
excludedSourcesXbox360 = { "" }
excludedSourcesPS3 = { "" }
excludedSourcesPSP2 = { "" }
excludedSourcesMac = { "" }

sourceFiles = { "" }

resourceFiles = { "" }

end

ConfigureBuild("Project") -- Calls the script file that generates the project.