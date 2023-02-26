globalScriptDir = os.getcwd()

if buildSystem == "vs2008" or buildSystem == "vs2010" then
projectLocation = "."
projectBaseName = tempSlnPrefix .. "vBase"
projectName = projectBaseName .. buildSystemSuffix -- NOTE: For solutions/projects that shouldn
projectGUID = "03D610D2-8C32-4A62-BAB3-DA28561AC7B7"
outputFolder = "../../shared/"
outputTarget = projectName -- If this variable is not used the specific ones will be the used instead. Tipically this field will contain: projectName

if buildSystem == "vs2008" then
  projectReferences = { tempSlnPrefix .. "SPUSyncEvent" .. buildSystemSuffix }
  projectLanguage = "C++"
  projectBuildConfigs = {
      "Debug|x32",    "Debug DX11|x32",   "Debug NoXI|x32", "Debug|PSVita", "StaticLib Debug|x32",   "StaticLib MT Debug|x32",
      "Release|x32",  "Release DX11|x32", "Release NoXI|x32", "Release|PSVita", "StaticLib Release|x32", "StaticLib MT Release|x32",
      "Debug|x64",    "Debug DX11|x64",   "Debug NoXI|x64",   "StaticLib Debug|x64",   "StaticLib MT Debug|x64",
      "Release|x64",  "Release DX11|x64", "Release NoXI|x64", "StaticLib Release|x64", "StaticLib MT Release|x64",
      "Debug|Xbox360", "Release|Xbox360", "Debug|PS3", "Release|PS3" }
  buildConfigsForProject = { "Debug", "Debug DX11", "Release", "Release DX11", "StaticLib Debug", "StaticLib Release", "StaticLib MT Debug", "StaticLib MT Release", "Debug NoXI", "Release NoXI" }
  buildPlatformsForProject = {  "x32", "x64", "Xbox360", "PS3", "PSVita" }
elseif buildSystem == "vs2010" then
  projectReferences = { }
  projectLanguage = "Default"
  projectBuildConfigs = {
    "Debug|x32",    "Debug DX11|x32",   "Debug NoXI|x32",   "StaticLib Debug|x32",   "StaticLib MT Debug|x32",
    "Release|x32",  "Release DX11|x32", "Release NoXI|x32", "StaticLib Release|x32", "StaticLib MT Release|x32",
    "Debug|x64",    "Debug DX11|x64",   "Debug NoXI|x64",   "StaticLib Debug|x64",   "StaticLib MT Debug|x64",
    "Release|x64",  "Release DX11|x64", "Release NoXI|x64", "StaticLib Release|x64", "StaticLib MT Release|x64",
    "Debug|Xbox360", "Release|Xbox360", "Debug|PS3", "Release|PS3", "Debug|PSVita", "Release|PSVita"
  }
  
  buildConfigsForProject = { "Debug", "Debug DX11", "Release", "Release DX11", "StaticLib Debug", "StaticLib Release", "StaticLib MT Debug", "StaticLib MT Release", "Debug NoXI", "Release NoXI" }
  buildPlatformsForProject = { "x32", "x64", "Xbox360", "PS3", "PSVita" }
  
end

if includeBuildConfigs == nil or includeBuildConfigs == "" then
  includeBuildConfigs = projectBuildConfigs
end

includePathResCompilerWindows = { "./", "include", "./tinyXML" }
-- Specific output folders.
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

-- Specific output target name.
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

-- PREPROCESSOR DEFINITIONS ----------------------------------------------------------
-- Platform defines
definesPS3 = { "SN_TARGET_PS3", "__SNC__", "_VISION_PS3" }                                               -- Defines for PS3 platform
definesPSP2 = { "SN_TARGET_PSP2", "__SNC__", "_VISION_PSP2" }                                            -- Defines for PSP2 platform
definesX86 = { "WIN32", "_WINDOWS", "_USRDLL", "_CRT_SECURE_NO_DEPRECATE", "_CRT_NONSTDC_NO_DEPRECATE" } -- Defines for Windows platform
definesX64 = { "WIN64", definesX86 }                                                                                    -- Defines for Windows x64 platform
definesXbox360 = { "_XBOX", "_VISION_XENON", "_VISION_NO_WARNING_IMAGE_FORMAT" }                         -- Defines for Xbox360 platform

-- Build configurations defines
definesSharedLib = "VBASE_EXPORTS"  -- Defines for a .dll output type
definesStaticLib = "VBASE_LIB"      -- Defines for a .lib output type
definesStaticLibMT = "NO_NEW_OVERRIDE"  -- Defines for a .lib output type
definesDebug = { "_DEBUG", "HK_DEBUG" }             -- Defines for all Debug builds
definesRelease = "NDEBUG"           -- Defines for all Release builds
definesDX11 = "_VR_DX11"            -- Defines for DX11 builds

definesDebugX86 = {}                -- Defines for Debug Windows 32bits platforms only
definesReleaseX86 = {}              -- Defines for Release Windows 32bits platforms only

definesDebugX64 = {}                -- Defines for Debug Windows 64bits platforms only
definesReleaseX64 = {}              -- Defines for Release Windows 64bits platforms only

definesDebugPS3 = { "CELL_GCM_DEBUG", "__CELLOS_LV2__" }  -- Defines for Debug PS3 builds
definesReleasePS3 = { "__CELLOS_LV2__" }              -- Defines for Release PS3 builds

definesDebugPSP2 = ""   -- Defines for Debug PSP2 builds
definesReleasePSP2 = "" -- Defines for Release PSP2 builds

definesDebugXbox360 = ""            -- Defines for Debug Xbox360 builds
definesReleaseXbox360 = ""          -- Defines for Release Xbox360 builds
--------------------------------------------------------------------------------------

-- Output Type. Can be SharedLib, StaticLib, ConsoleApp
bIsEnginePlugin = false
outputTypeWin = "SharedLib"
outputTypeXbox360 = "StaticLib"
outputTypePS3 = "StaticLib"
outputTypePSP2 = "StaticLib"

-- Specific PS3 section
bIsSPU = false -- Indicates that the project is a SPU project

-- Include dirs
includeDirsCommon    = { "./", "include", "../../shared/include/vBase", "./zlib", "./tinyXML", "../../", JPEGLibIncludeDirs, PNGLibIncludeDirs, havokIncludeDirs }
includeDirsWin32     = { includeDirsCommon, "\"$(DXSDK_DIR)/Include\"", "../vPlatformHandlerDX9/include", "../vPlatformHandlerXbox360/include", "../vPlatformHandlerDX11/include" }
includeDirsX64       = includeDirsWin32
includeDirsXbox360   = includeDirsCommon
includeDirsPS3       = { includeDirsCommon, "\"$(SN_PS3_PATH)/ppu/include/sn\"", "\"$(SCE_PS3_ROOT)/target/ppu/include\"", "\"$(SCE_PS3_ROOT)/target/common/include\"" }
includeDirsPSP2     = { includeDirsCommon, "\"$(SCE_PSP2_SDK_DIR)/target/include\"" }

-- Lib dirs 
libDirsCommon        = { } -- this line is ignored by VS2Premake.
libDirsAllWin32      = { JPEGLibLibDirs, PNGLibLibDirs, "$(DXSDK_DIR)/Lib/x86" }
libDirsAllX64        = { JPEGLibLibDirs, PNGLibLibDirs, "$(DXSDK_DIR)/Lib/x64" }
libDirsStaticWin32   = { libDirsAllWin32, "" }
libDirsWin32         = { libDirsAllWin32, "../../shared/lib" }
libDirsStaticX64     = { libDirsAllX64, "" }
libDirsX64           = { libDirsAllX64, "../../shared/lib/x64" }

libDirsDebugXbox360       = { havokLibDirsDebugXbox360 }
libDirsReleaseXbox360     = { havokLibDirsReleaseXbox360 }
libDirsXbox360            = { }
libDirsDebugPS3           = { havokLibDirsDebugPS3 }
libDirsReleasePS3         = { havokLibDirsReleasePS3 }
libDirsPS3                = { }
libDirsDebugPSP2          = { havokLibDirsDebugPSP2 }
libDirsReleasePSP2        = { havokLibDirsReleasePSP2 }
libDirsPSP2               = { }

if buildSystem == "vs2008" then
  libDirsDebugWin32	    = { havoklibDirsDebug90 }
  libDirsReleaseWin32   = { havoklibDirsRelease90 }
  libDirsDebugX64 	    = { havoklibDirsDebug90 }
  libDirsReleaseX64     = { havoklibDirsRelease90}
  libDirsStaticWin32    = { libDirsStaticWin32, libDirsReleaseWin32 }
  libDirsStaticX64      = { libDirsStaticX64,   libDirsReleaseX64 }
elseif buildSystem == "vs2010" then
  libDirsDebugWin32	    = { havoklibDirsDebug100 }
  libDirsReleaseWin32   = { havoklibDirsRelease100 }
  libDirsDebugX64 	    = { havoklibDirsDebug100 }
  libDirsReleaseX64     = { havoklibDirsRelease100 }
  libDirsStaticWin32    = { libDirsStaticWin32, libDirsReleaseWin32 }
  libDirsStaticX64      = { libDirsStaticX64,   libDirsReleaseX64 }
end

-- Link libs
libLinkAllWindows          = { "dinput8.lib", "dxguid.lib", "shlwapi.lib", "ws2_32.lib", "hkBase.lib" }
libLinkShared              = { "Delayimp.lib", "Winmm.lib", "comctl32.lib", "hkBase.lib" }
libLinkDx11                = { "d3d11.lib", "dxgi.lib" }

libLinkDebugAllWin32      = { "libpng" .. buildSystemSuffix .. "d.lib", "libjpeg" .. buildSystemSuffix .. "D.lib" }
libLinkDebugAllx64        = { "libpng" .. buildSystemSuffix .. "D-64.lib", "libjpeg" .. buildSystemSuffix .. "D-64.lib" }
libLinkReleaseAllWin32    = { "libpng" .. buildSystemSuffix .. ".lib", "libjpeg" .. buildSystemSuffix .. ".lib" }
libLinkReleaseAllx64      = { "libpng" .. buildSystemSuffix .. "-64.lib", "libjpeg" .. buildSystemSuffix .. "-64.lib" }

local libLinkDebugMT32    = { libLinkAllWindows, "libpng" .. buildSystemSuffix .. "MTD.lib", "libjpeg" .. buildSystemSuffix .. "D.lib", "d3d9.lib" }
local libLinkDebugMT64    = { libLinkAllWindows, "libpng" .. buildSystemSuffix .. "MTD-64.lib", "libjpeg" .. buildSystemSuffix .. "D-64.lib", "d3d9.lib" }
local libLinkReleaseMT32  = { libLinkAllWindows, "libpng" .. buildSystemSuffix .. "MT.lib", "libjpeg" .. buildSystemSuffix .. ".lib", "d3d9.lib" }
local libLinkReleaseMT64  = { libLinkAllWindows, "libpng" .. buildSystemSuffix .. "MT-64.lib", "libjpeg" .. buildSystemSuffix .. "-64.lib", "d3d9.lib" }
--
libLinkDebugStaticWin32    = { libLinkAllWindows, libLinkDebugAllWin32, "xinput.lib", "d3d9.lib" } 
libLinkDebugStaticMTWin32  = { libLinkDebugMT32 } 
libLinkDebugDx9Win32       = { libLinkAllWindows, libLinkDebugAllWin32, libLinkShared, "xinput.lib", "d3d9.lib" } 
libLinkDebugDx11Win32      = { libLinkAllWindows, libLinkDebugAllWin32, libLinkShared, libLinkDx11, "xinput.lib" } 
libLinkDebugNoXIWin32      = { libLinkAllWindows, libLinkDebugAllWin32, libLinkShared, "d3d9.lib" } 

libLinkReleaseStaticWin32  = { libLinkAllWindows, libLinkReleaseAllWin32, "xinput.lib", "d3d9.lib" } 
libLinkReleaseStaticMTWin32= { libLinkReleaseMT32 } 
libLinkReleaseDx9Win32     = { libLinkAllWindows, libLinkReleaseAllWin32, libLinkShared, "xinput.lib", "d3d9.lib" } 
libLinkReleaseDx11Win32    = { libLinkAllWindows, libLinkReleaseAllWin32, libLinkShared, libLinkDx11, "xinput.lib" } 
libLinkReleaseNoXIWin32    = { libLinkAllWindows, libLinkReleaseAllWin32, libLinkShared, "d3d9.lib" } 

libLinkDebugStaticX64      = { libLinkAllWindows, libLinkDebugAllx64, "xinput.lib", "d3d9.lib" } 
libLinkDebugStaticMTX64    = { libLinkDebugMT64 } 
libLinkDebugDx9x64         = { libLinkAllWindows, libLinkDebugAllx64, libLinkShared, "xinput.lib", "d3d9.lib" } 
libLinkDebugDx11x64        = { libLinkAllWindows, libLinkDebugAllx64, libLinkShared, libLinkDx11, "xinput.lib" } 
libLinkDebugNoXIx64        = { libLinkAllWindows, libLinkDebugAllx64, libLinkShared, "d3d9.lib" } 

libLinkReleaseStaticX64    = { libLinkAllWindows, libLinkReleaseAllx64, "xinput.lib", "d3d9.lib" } 
libLinkReleaseStaticMTX64  = { libLinkReleaseMT64 } 
libLinkReleaseDx9x64       = { libLinkAllWindows, libLinkReleaseAllx64, libLinkShared, "xinput.lib", "d3d9.lib" } 
libLinkReleaseDx11x64      = { libLinkAllWindows, libLinkReleaseAllx64, libLinkShared, libLinkDx11, "xinput.lib" } 
libLinkReleaseNoXIx64      = { libLinkAllWindows, libLinkReleaseAllx64, libLinkShared, "d3d9.lib" } 

libLinkDebugXbox360        = { }
libLinkReleaseXbox360      = { }

local libLinkReferencesPS3 = {
-- Required by the new VSI for VS2010
  "../../shared/lib/spu/$(ConfigurationName)/SPUSyncEvent.ppu.obj"
}
libLinkDebugPS3 = { iif(buildSystem == "vs2010", libLinkReferencesPS3, "") }
libLinkReleasePS3 = { iif(buildSystem == "vs2010", libLinkReferencesPS3, "") }

libLinkDebugPSP2            = { "\"$(SCE_PSP2_SDK_DIR)/target/lib/libSceFpu.a\"", "\"$(SCE_PSP2_SDK_DIR)/target/lib/libSceRazorCapture_stub_weak.a\"", "\"$(SCE_PSP2_SDK_DIR)/target/lib/libSceRazorHud_stub_weak.a\"" }
libLinkReleasePSP2          = { "\"$(SCE_PSP2_SDK_DIR)/target/lib/libSceFpu.a\"", "\"$(SCE_PSP2_SDK_DIR)/target/lib/libSceRazorCapture_stub_weak.a\"", "\"$(SCE_PSP2_SDK_DIR)/target/lib/libSceRazorHud_stub_weak.a\"" }
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
--]]
flagsStatic = { "StaticRuntime" }

flagsAllWindows = { "Symbols", "NoEditAndContinue", "FatalWarnings", "NoMinimalRebuild", "NoIncrementalLink", "VSNoSubSystem", "VSEnableStaticCodeAnalysis" }
flagsDebugAllWindows = { "VSBufferSecurityCheck" }
flagsReleaseAllWindows = { "Optimize", "FloatFast", "VSNoBasicRuntimeCheck", "VSEnableFunctionLevelLinking", "VSEnableIntrinsicFunctions", "VSFavorSpeed", "NoFramePointer" }

flagsDebugWin32 = { flagsAllWindows, flagsDebugAllWindows }
flagsReleaseWin32 = { flagsAllWindows, flagsReleaseAllWindows, "EnableSSE" }
flagsDebugX64 = { flagsAllWindows, flagsDebugAllWindows }
flagsReleaseX64 = { flagsAllWindows, flagsReleaseAllWindows }
flagsStaticWin = ""
flagsStaticMTWin = { flagsStatic }

flagsAllXbox360 = { "Symbols", "NoEditAndContinue", "FatalWarnings", "NoExceptions", "NoMinimalRebuild", "VSNoSubSystem"  }
flagsDebugXbox360 = { flagsAllXbox360, flagsStatic, "VSNoStringPooling" }
flagsReleaseXbox360 = { flagsAllXbox360, flagsStatic, "OptimizeSpeed", "VSEnableFunctionLevelLinking", "VSNoBasicRuntimeCheck" }

flagsAllPS3 = { "VSNoBasicRuntimeCheck", "VSBufferSecurityCheck", "MinWarnings", "NoPCH", "VSNoSubSystem" }
flagsDebugPS3 = { flagsAllPS3, flagsStatic, "Symbols", "NoEditAndContinue", "NoMinimalRebuild" }
flagsReleasePS3 = { flagsAllPS3, flagsStatic, "OptimizeSpeed" }

flagsAllPSP2 = { "NoPCH", "VSNoBasicRuntimeCheck", "VSBufferSecurityCheck", "FatalWarnings", "NoLinkLibDependencies", "VSNoSubSystem" }
flagsDebugPSP2 = { flagsAllPSP2, flagsStatic, "Symbols", "NoEditAndContinue", "NoMinimalRebuild" }
flagsReleasePSP2 = { flagsAllPSP2, flagsStatic, "OptimizeSpeed" }

-- additional build options ---
if buildSystem == "vs2010" then
  --increase stacksize for static code analysis
  buildOptAllWin = { "/analyze:stacksize270000" }
else
  buildOptAllWin = { } 
end
buildOptAllDebugWin =   { buildOptAllWin }
buildOptAllReleaseWin = { buildOptAllWin }

buildOptDebugStaticWin32 =    { buildOptAllDebugWin }
buildOptDebugStaticMTWin32 =  { buildOptAllDebugWin }
buildOptDebugWin32 =          { buildOptAllDebugWin }

buildOptDebugStaticX64 =   { buildOptAllDebugWin }
buildOptDebugStaticMTX64 = { buildOptAllDebugWin }
buildOptDebugX64 =         { buildOptAllDebugWin }

buildOptReleaseStaticWin32 =     { buildOptAllReleaseWin }
buildOptReleaseStaticMTWin32 =   { buildOptAllReleaseWin }
buildOptReleaseWin32 =           { buildOptAllReleaseWin }

buildOptReleaseStaticX64 =    { buildOptAllReleaseWin }
buildOptReleaseStaticMTX64 =  { buildOptAllReleaseWin }
buildOptReleaseX64 =          { buildOptAllReleaseWin }

buildOptAllXbox360 = { }
buildOptDebugXbox360 =     { buildOptAllXbox360 }
buildOptReleaseXbox360 =   { buildOptAllXbox360 }

buildOptAllPS3 = { "-Xc-=rtti -Xquit=1 -Xsingleconst=0" }
buildOptDebugPS3 =   { "-g", buildOptAllPS3 }
buildOptReleasePS3 = { "-O2", buildOptAllPS3, "-Xfastmath=1 -Xassumecorrectalignment=1 -Xassumecorrectsign=1 -Xnotocrestore=2 -Xbranchless=1 -Xunrollssa=10" }

buildOptAllPSP2 = { "-Xc-=rtti -Xquit=1" }
buildOptDebugPSP2 = { "-g", buildOptAllPSP2 }
buildOptReleasePSP2 = { "-O2", buildOptAllPSP2, "-Xfastmath=1" }

-- Post-build command
postBuildWin = ""
postBuildNoXI =
  { 
    'echo on', 
    'xcopy /y $(TargetPath) "$(OutDir)\\..\\.."', 
    'xcopy /y "$(OutDir)\\..\\..\\..\\lib\\builds\\noXInput\\$(TargetName).lib" "$(OutDir)\\..\\.."',
    'xcopy /y "$(OutDir)\\..\\..\\..\\lib\\builds\\noXInput\\$(TargetName).exp" "$(OutDir)\\..\\.."'
  }
  
postBuildNoXIX64 =
  { 
    'echo on', 
    'xcopy /y $(TargetPath) "$(OutDir)\\..\\.."', 
    'xcopy /y "$(OutDir)\\..\\..\\..\\lib\\x64\\builds\\noXInput\\$(TargetName).lib" "$(OutDir)\\..\\.."',
    'xcopy /y "$(OutDir)\\..\\..\\..\\lib\\x64\\builds\\noXInput\\$(TargetName).exp" "$(OutDir)\\..\\.."'
  }
    
postBuildXbox360 = ""
postBuildPS3 = ""
postBuildPSP2 = ""

postBuildDescWin = ""
postBuildDescNoXI = "Performing post-build Step..."
postBuildDescXbox360 = ""
postBuildDescPS3 = "Executing Post-Build Step..."
postBuildDescPSP2 = ""

-- additional linker options ---
linkOptAllStaticWin = { "/ignore:4006", "/ignore:4221" }
linkOptDebugNonStaticWin = { "" }
linkOptDebugStaticWin32 =  { linkOptAllStaticWin }
linkOptDebugWin32 =        { linkOptDebugNonStaticWin }

linkOptReleaseNonStaticWin = { "" }
linkOptReleaseStaticWin32 = { linkOptAllStaticWin }
linkOptReleaseWin32 = { linkOptReleaseNonStaticWin }

linkOptDebugStaticX64 = { linkOptAllStaticWin }
linkOptDebugX64 = { linkOptDebugNonStaticWin }

linkOptReleaseStaticX64 = { linkOptAllStaticWin }
linkOptReleaseX64 = { linkOptReleaseNonStaticWin }

linkOptDebugXbox360 = ""
linkOptReleaseXbox360 = ""

linkOptDebugPS3 = ""
linkOptReleasePS3 = ""

linkOptDebugPSP2 = ""
linkOptReleasePSP2 = ""

-- Disable warnings ---------------------------------------
if buildSystem == "vs2010" then
  -- disable ignored return value on sscanf warning caused by static code analysis
  disableWarningsDebugWin32 = "6031"
  disableWarningsReleaseWin32 = "6031"	
else
  disableWarningsDebugWin32 = ""
  disableWarningsReleaseWin32 = ""
end

disableWarningsDebugX64 = ""
disableWarningsReleaseX64 = ""

disableWarningsDebugXbox360 = ""
disableWarningsReleaseXbox360 = ""

local disableWarningsPS3 = { "112,178,552" } 
disableWarningsDebugPS3 = { disableWarningsPS3 } 
disableWarningsReleasePS3 = { disableWarningsPS3 }

local disableWarningsPSP2 = { "1786", "1783", "178", "1437", "237", "552", "112" }
disableWarningsDebugPSP2 = { disableWarningsPSP2 } 
disableWarningsReleasePSP2 = { disableWarningsPSP2 } 

-----------------------------------------------------------

------------------------------------
---- Windows specific --------------
-- Delayed .dll loads
delayDllCommon    =     { "winmm.dll", "user32.dll", "gdi32.dll", "advapi32.dll", "version.dll", "dinput8.dll", "shlwapi.dll" }
delayDllXICommon  =     { "ole32.dll", "xinput1_3.dll" }
delayDebugWin32   =     { delayDllCommon, delayDllXICommon, "d3d9.dll" }
delayDebugDX11Win32 =   { delayDllCommon, delayDllXICommon, "d3d11.dll" }
delayDebugNoXIWin32 =   { delayDllCommon, "d3d9.dll" }

delayReleaseWin32   =    { delayDllCommon, delayDllXICommon, "d3d9.dll" }
delayReleaseDX11Win32 =  { delayDllCommon, delayDllXICommon, "d3d11.dll" }
delayReleaseNoXIWin32 =  { delayDllCommon, "d3d9.dll" }

delayDebugX64   =      { delayDllCommon, delayDllXICommon, "d3d9.dll" }
delayDebugDX11X64 =    { delayDllCommon, delayDllXICommon, "d3d11.dll" }
delayDebugNoXIX64 =    { delayDllCommon, "d3d9.dll" }

delayReleaseX64   =    { delayDllCommon, delayDllXICommon, "d3d9.dll" }
delayReleaseDX11X64 =  { delayDllCommon, delayDllXICommon, "d3d11.dll" }
delayReleaseNoXIX64 =  { delayDllCommon, "d3d9.dll" }

-- Ignored libs
ignoreDefaultLibsAll = { "libc" }
ignoreDefaultLibsDebug = { ignoreDefaultLibsAll, "libcmtd" }
ignoreDefaultLibsRelease = { ignoreDefaultLibsAll, "libcmt" }
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
culture = "" -- for the resource compiler 1031 == 0x407 Germany

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

excludedSourcesWindows = { 
    "./src/VPlatformPS3.cpp",
    "./src/VPlatformPSP2.cpp",
    "./src/VGL/XenonController.cpp",
    "./src/VGL/Xboxcontroller.cpp", 
    "./src/VHAL/VDevCapsHandler.cpp",
    "./src/VHAL/VGraphicsMemoryPS3.cpp",
    "./src/VHAL/VGraphicsMemoryPSP2.cpp",
    "./src/VHAL/VInputPS3.cpp",
    "./src/VHAL/VInputPSP2.cpp",
    "./src/VHAL/VInputXenon.cpp",
    "./src/VHAL/VMemoryBasePS3.cpp",
    "./src/VHAL/VOpenGLExtHelper.cpp",
    "./src/VHAL/VPerfMetricsPSP2.cpp",
    "./src/VHAL/VSuspendedRenderingPS3.cpp",
    "./src/vShader/vShaderPassResourceGLES2.cpp",
    "./src/vShader/vShaderProgramResourcePSP2.cpp",
    "./src/vShader/vShaderProgramResourcePS3.cpp",
    "./src/vShader/vShaderProgramResourceGLES2.cpp",
    "./src/VSpursHandler/VSpuPrintfService.cpp",
    "./src/VSpursHandler/VSpursHandler.cpp",
    "../../shared/include/vBase/VHAL/VGraphicsMemoryPS3.hpp",
    "../../shared/include/vBase/VHAL/VMemoryBasePS3.hpp"
  } 

 
excludedSourcesWindowsNoXI = { 
    "./src/VPlatformPS3.cpp",
    "./src/VPlatformPSP2.cpp",
    "./src/VGL/XenonController.cpp",
    "./src/VGL/Xboxcontroller.cpp",
    "./src/VHAL/VDevCapsHandler.cpp",
    "./src/VHAL/VGraphicsMemoryPS3.cpp",
    "./src/VHAL/VGraphicsMemoryPSP2.cpp",
    "./src/VHAL/VInputPS3.cpp",
    "./src/VHAL/VInputPSP2.cpp",
    "./src/VHAL/VInputXenon.cpp",
    "./src/VHAL/VInputXI.cpp",
    "./src/VHAL/VMemoryBasePS3.cpp",
    "./src/VHAL/VOpenGLExtHelper.cpp",
    "./src/VHAL/VPerfMetricsPSP2.cpp",
    "./src/VHAL/VSuspendedRenderingPS3.cpp",
    "./src/vShader/vShaderPassResourceGLES2.cpp",
    "./src/vShader/vShaderProgramResourcePSP2.cpp",
    "./src/vShader/vShaderProgramResourcePS3.cpp",
    "./src/vShader/vShaderProgramResourceGLES2.cpp",
    "./src/VSpursHandler/VSpuPrintfService.cpp",
    "./src/VSpursHandler/VSpursHandler.cpp",
    "../../shared/include/vBase/VHAL/VGraphicsMemoryPS3.hpp",
    "../../shared/include/vBase/VHAL/VMemoryBasePS3.hpp"
  }

 
excludedSourcesXbox360 = { 
    "./src/VModuleInfo.cpp",
    "./src/VModuleInfoList.cpp",
    "./src/VPlatformPS3.cpp",
    "./src/VPlatformPSP2.cpp",
    "./src/private/ModuleListClasses.cpp",
    "./src/private/ModuleListOSCode.cpp",
    "./src/private/VReportDialog.cpp",
    "./src/VGL/directinput.cpp",
    "./src/VGL/logwindow.cpp",
    "./src/VGL/Reg.cpp",
    "./src/VHAL/VDevCapsHandler.cpp",
    "./src/VHAL/VGraphicsMemoryPS3.cpp",
    "./src/VHAL/VGraphicsMemoryPSP2.cpp",
    "./src/VHAL/VInputPC.cpp",
    "./src/VHAL/VInputPCMultitouch.cpp",
    "./src/VHAL/VInputPCMotion.cpp",
    "./src/VHAL/VInputPS3.cpp",
    "./src/VHAL/VInputPSP2.cpp",
    "./src/VHAL/VMemoryBasePS3.cpp",
    "./src/VHAL/VOpenGLExtHelper.cpp",
    "./src/VHAL/VPerfMetricsPSP2.cpp",
    "./src/VHAL/VSuspendedRenderingPS3.cpp",
    "./src/VHAL/WGLWnd.cpp",
    "./src/vShader/vShaderPassResourceGLES2.cpp",
    "./src/vShader/vShaderProgramResourcePSP2.cpp",
    "./src/vShader/vShaderProgramResourcePS3.cpp",
    "./src/vShader/vShaderProgramResourceGLES2.cpp",
    "./src/vPlatformStub/vPlatformStubBase.cpp",
    "./src/vPlatformStub/vPlatformStubDX11.cpp",
    "./src/vPlatformStub/vPlatformStubDX9.cpp",
    "./src/vPlatformStub/vPlatformStubGLES2.cpp",
    "./src/vPlatformStub/vPlatformStubLinux.cpp",
    "./src/vPlatformStub/vPlatformStubPS3.cpp",
    "./src/vPlatformStub/vPlatformStubPSP2.cpp",
    "./src/vPlatformStub/vPlatformStubXbox360.cpp",
    "./src/vPlatformStub/vPlatformStubCafe.cpp",
    "./src/VSpursHandler/VSpuPrintfService.cpp",
    "./src/VSpursHandler/VSpursHandler.cpp",
    "../../shared/include/vBase/vShader/VOpenGLextheader.hpp",
    "../../shared/include/vBase/VHAL/VInputPC.hpp",
    "../../shared/include/vBase/VHAL/VInputPS3.hpp",
    "../../shared/include/vBase/VHAL/VInputPSP2.hpp",
    "./resource.h",
    "./vBase.rc",
    "./vBase.rc2",
    "./src/VGL/Xboxcontroller.cpp",
    "./src/VStackWalker.cpp",	}

excludedSourcesPS3 = { 
    "./src/VModuleInfo.cpp",
    "./src/VModuleInfoList.cpp",
    "./src/VPlatformPSP2.cpp",
    "./src/private/ModuleListClasses.cpp",
    "./src/private/ModuleListOSCode.cpp",
    "./src/private/VReportDialog.cpp",
    "./src/VGL/directinput.cpp",
    "./src/VGL/directx.cpp",
    "./src/VGL/logwindow.cpp",
    "./src/VGL/Reg.cpp",
    "./src/VGL/XenonController.cpp",
    "./src/VHAL/VDevCapsHandler.cpp",
    "./src/VHAL/VGraphicsMemoryPSP2.cpp",
    "./src/VHAL/VInputPC.cpp",
    "./src/VHAL/VInputPCMultitouch.cpp",
    "./src/VHAL/VInputPCMotion.cpp",
    "./src/VHAL/VInputPSP2.cpp",
    "./src/VHAL/VInputXenon.cpp",
    "./src/VHAL/VInputXI.cpp",
    "./src/VHAL/VOpenGLExtHelper.cpp",
    "./src/VHAL/VPerfMetricsPSP2.cpp",
    "./src/VHAL/WGLWnd.cpp",
    "./src/vShader/vShaderPassResourceGLES2.cpp",
    "./src/vShader/vShaderProgramResourcePSP2.cpp",
    "./src/vShader/vShaderProgramResourceGLES2.cpp",
    "./src/vPlatformStub/vPlatformStubBase.cpp",
    "./src/vPlatformStub/vPlatformStubDX11.cpp",
    "./src/vPlatformStub/vPlatformStubDX9.cpp",
    "./src/vPlatformStub/vPlatformStubGLES2.cpp",
    "./src/vPlatformStub/vPlatformStubLinux.cpp",
    "./src/vPlatformStub/vPlatformStubPS3.cpp",
    "./src/vPlatformStub/vPlatformStubPSP2.cpp",
    "./src/vPlatformStub/vPlatformStubXbox360.cpp",
    "./src/vPlatformStub/vPlatformStubCafe.cpp",
    "./src/VGL/Xboxcontroller.cpp",
    "./src/VStackWalker.cpp",	}

excludedSourcesPSP2 = { 
    "./src/VModuleInfo.cpp",
    "./src/VModuleInfoList.cpp",
    "./src/VPlatformPS3.cpp",
    "./src/private/ModuleListClasses.cpp",
    "./src/private/ModuleListOSCode.cpp",
    "./src/private/VReportDialog.cpp",
    "./src/VGL/directinput.cpp",
    "./src/VGL/directx.cpp",
    "./src/VGL/logwindow.cpp",
    "./src/VGL/Reg.cpp",
    "./src/VGL/XenonController.cpp",
    "./src/VHAL/VDevCapsHandler.cpp",
    "./src/VHAL/VGraphicsMemoryPS3.cpp",
    "./src/VHAL/VInputPC.cpp",
    "./src/VHAL/VInputPCMultitouch.cpp",
    "./src/VHAL/VInputPCMotion.cpp",
    "./src/VHAL/VInputPS3.cpp",
    "./src/VHAL/VInputXenon.cpp",
    "./src/VHAL/VInputXI.cpp",
    "./src/VHAL/VMemoryBasePS3.cpp",
    "./src/VHAL/VOpenGLExtHelper.cpp",
    "./src/VHAL/VSuspendedRenderingPS3.cpp",
    "./src/VHAL/WGLWnd.cpp",
    "./src/VClipboardHelper.cpp",
    "./src/vShader/vShaderPassResourceGLES2.cpp",
    "./src/vShader/vShaderProgramResourcePS3.cpp",
    "./src/vShader/vShaderProgramResourceGLES2.cpp",
    "./src/vPlatformStub/vPlatformStubDX11.cpp",
    "./src/vPlatformStub/vPlatformStubDX9.cpp",
    "./src/vPlatformStub/vPlatformStubGLES2.cpp",
    "./src/vPlatformStub/vPlatformStubLinux.cpp",
    "./src/vPlatformStub/vPlatformStubPS3.cpp",
    "./src/vPlatformStub/vPlatformStubPSP2.cpp",
    "./src/vPlatformStub/vPlatformStubXbox360.cpp",
    "./src/vPlatformStub/vPlatformStubCafe.cpp",
    "./src/VSpursHandler/VSpuPrintfService.cpp",
    "./src/VSpursHandler/VSpursHandler.cpp",
    "./src/VGL/Xboxcontroller.cpp",
    "./src/VStackWalker.cpp",	}

excludedSourcesMac = { "" }

 
sourcesNotUsingPCH = { 
    "./zLib/adler32.c",
    "./zLib/compress.c",
    "./zLib/crc32.c",
    "./zLib/deflate.c",
    "./zLib/infback.c",
    "./zLib/inffast.c",
    "./zLib/inflate.c",
    "./zLib/inftrees.c",
    "./zLib/contrib/minizip/ioapi.c",
    "./zLib/trees.c",
    "./zLib/uncompr.c",
    "./zLib/contrib/minizip/unzip.c",
    "./zLib/zutil.c",
    "./tinyXML/tinystr.cpp",
    "./tinyXML/tinyxml.cpp",
    "./tinyXML/tinyxmlerror.cpp",
    "./tinyXML/TinyXMLHelper.cpp",
    "./tinyXML/tinyxmlparser.cpp" }

 
sourceFiles = { 
    sourcesNotUsingPCH,
    "./src/StdAfx.cpp",
    "./src/svdebugfile.cpp",
    "./src/svfile.cpp",
    "./src/VAction.cpp",
    "./src/VActionManager.cpp",
    "./src/VArgList.cpp",
    "./src/vBase.cpp",
    "./src/VCallbacks.cpp",
    "./src/VColor.cpp",
    "./src/VCommand.cpp",
    "./src/VCommandManager.cpp",
    "./src/VCRC.cpp",
    "./src/VEndianSwitch.cpp",
    "./src/VExceptions.cpp",
    "./src/VFileLib/VFileAccess.cpp",
    "./src/VFileLib/VFileAccessPS3.inl",
    "./src/VFileLib/VFileAccessPOSIX.inl",
    "./src/VFileLib/VFileAccessPSP2.inl",
    "./src/VFileLib/VFileAccessXenon.inl",
    "./src/VFileLib/VFileAccessPC.inl",
    "./src/VFileLib/VFileAccessiOS.inl",
    "./src/VGuid.cpp",
    "./src/VLocale.cpp",
    "./src/vLog.cpp",
    "./src/VModule.cpp",
    "./src/VModuleInfo.cpp",
    "./src/VModuleInfoList.cpp",
    "./src/VPlatformPS3.cpp",
    "./src/VPlatformPSP2.cpp",
    "./src/VReceiver.cpp",
    "./src/VRefTarget.cpp",
    "./src/VReportMessage.cpp",
    "./src/VSenderReceiver.cpp",
    "./src/VString.cpp",
    "./src/VStringTokenizer.cpp",
    "./src/VStringTokenizerInPlace.cpp",
    "./src/VStringUtil.cpp",
    "./src/VTex.cpp",
    "./src/VType.cpp",
    "./src/VTypedObjectReference.cpp",
    "./src/VTypeManager.cpp",
    "./src/VUndoRedoStack.cpp",
    "./src/VWindow.cpp",
    "./src/VFileLib/VArchive.cpp",
    "./src/VFileLib/VChunkFile.cpp",
    "./src/VFileLib/VFileTime.cpp",
    "./src/VFileLib/VSerializationProxy.cpp",
    "./src/VADT/VBitField.cpp",
    "./src/VADT/VDictionary.cpp",
    "./src/VADT/VLink.cpp",
    "./src/VADT/VMapcpp.inc",
    "./src/VADT/VMaps.cpp",
    "./src/VADT/VMapStrToPtr.cpp",
    "./src/VADT/VPList.cpp",
    "./src/VADT/VRawDataBlock.cpp",
    "./src/VADT/vstrlist.cpp",
    "./src/VParam/VParam.cpp",
    "./src/VParam/VParamArray.cpp",
    "./src/VParam/VParamBlock.cpp",
    "./src/VParam/VParamComposite.cpp",
    "./src/VParam/VParamContainer.cpp",
    "./src/VParam/VParamDesc.cpp",
    "./src/VParam/VParamExpression.cpp",
    "./src/hkvMath/hkvMath.cpp",
    "./src/hkvMath/hkvVec2.cpp",
    "./src/hkvMath/hkvVec3.cpp",
    "./src/hkvMath/hkvVec4.cpp",
    "./src/hkvMath/hkvMat3.cpp",
    "./src/hkvMath/hkvMat4.cpp",
    "./src/hkvMath/hkvPlane.cpp",
    "./src/hkvMath/hkvQuat.cpp",
    "./src/hkvMath/hkvEulerUtil.cpp",
    "./src/hkvMath/hkvAlignedBBox.cpp",
    "./src/hkvMath/hkvBoundingSphere.cpp",
    "./src/VMath/VBBox.cpp",
    "./src/VMath/VBBoxOctree.cpp",
    "./src/VMath/VCollisionData.cpp",
    "./src/VMath/VCollisionMesh.cpp",
    "./src/VMath/VCollisionMesh32.cpp",
    "./src/VMath/VCollisionMeshBase.cpp",
    "./src/VMath/VCollisionNode.cpp",
    "./src/VMath/VCollisionSurface.cpp",
    "./src/VMath/VIntersect.cpp",
    "./src/VMath/VLine.cpp",
    "./src/VMath/VMappingVertex.cpp",
    "./src/VMath/VMathHelpers.cpp",
    "./src/VMath/VMatrix4.cpp",
    "./src/VMath/VMatrix4cpp.inc",
    "./src/VMath/VPlane.cpp",
    "./src/VMath/VRectanglef.cpp",
    "./src/VMath/VTriangle.cpp",
    "./src/VMath/VVertex2.cpp",
    "./src/VMath/VVertex3.cpp",
    "./src/VMath/VVertex3cpp.inc",
    "./src/private/ModuleListClasses.cpp",
    "./src/private/ModuleListOSCode.cpp",
    "./src/private/VReport.cpp",
    "./src/private/VReportDialog.cpp",
    "./src/VTex/VCompressionHelper.cpp",
    "./src/VTex/VTex_bmp.cpp",
    "./src/VTex/VTex_dds.cpp",
    "./src/VTex/VTex_dem.cpp",
    "./src/VTex/VTex_jpeg.cpp",
    "./src/VTex/VTex_jpg_datadst.cpp",
    "./src/VTex/VTex_jpg_datasrc.cpp",
    "./src/VTex/VTex_png.cpp",
    "./src/VTex/VTex_tex.cpp",
    "./src/VTex/VTex_tga.cpp",
    "./src/VTex/VTex_tiff.cpp",
    "./src/VTex/VTextureLoader.cpp",
    "./src/VTest/VImageComparison.cpp",
    "./src/VTest/vTestClass.cpp",
    "./src/VTest/vTestUnit.cpp",
    "./src/VGL/directinput.cpp",
    "./src/VGL/directx.cpp",
    "./src/VGL/keyboard.cpp",
    "./src/VGL/logwindow.cpp",
    "./src/VGL/Misc.cpp",
    "./src/VGL/VGLMiscPS3.inl",
    "./src/VGL/VGLMiscPSP2.inl",
    "./src/VGL/VGLMiscXenon.inl",
    "./src/VGL/VGLMiscPOSIX.inl",
    "./src/VGL/VGLMiscPC.inl",
    "./src/VGL/mouse.cpp",
    "./src/VGL/Reg.cpp",
    "./src/VGL/ResourceViewerConsoles.cpp",
    "./src/VGL/Vgl.cpp",
    "./src/VGL/XenonController.cpp",
    "./src/vShader/vCompiledEffect.cpp",
    "./src/vShader/vCompiledShaderManager.cpp",
    "./src/vShader/vCompiledShaderPass.cpp",
    "./src/vShader/vConstantBuffer.cpp",
    "./src/vShader/vEffectAssignment.cpp",
    "./src/vShader/vLightGrid.cpp",
    "./src/vShader/vLightmapHelper.cpp",
    "./src/vShader/vShaderEffectLib.cpp",
    "./src/vShader/vShaderFXParser.cpp",
    "./src/vShader/vShaderIncludeManager.cpp",
    "./src/vShader/vShaderParam.cpp",
    "./src/vShader/vShaderPassResource.cpp",
    "./src/vShader/vShaderPassResourceGLES2.cpp",
    "./src/vShader/vRenderStateContainer.cpp",
    "./src/vShader/vShaderProgramResource.cpp",
    "./src/vShader/vShaderProgramResourceDX9.cpp",
    "./src/vShader/vShaderProgramResourceDX11.cpp",
    "./src/vShader/vShaderProgramResourceGLES2.cpp",
    "./src/vShader/vShaderProgramResourcePS3.cpp",
    "./src/vShader/vShaderProgramResourcePSP2.cpp",
    "./src/vShader/vStateGroups.cpp",
    "./src/vShader/vTechniqueConfig.cpp",
    "./src/IO/IVFileStream.cpp",
    "./src/IO/IVFileStreamPS3.inl",
    "./src/IO/IVFileStreamPosix.inl",
    "./src/IO/IVFileStreamPC.inl",
    "./src/IO/IVFileStreamPSP2.inl",
    "./src/IO/IVFileStreamXenon.inl",
    "./src/IO/IVRevisionControlSystem.cpp",
    "./src/IO/VClipboard.cpp",
    "./src/IO/VDiskFileStreamManager.cpp",
    "./src/IO/VFileAccessManager.cpp",
    "./src/IO/VFileCopyList.cpp",
    "./src/IO/VMemoryStream.cpp",
    "./src/IO/VZipFileStreamManager.cpp",
    "./src/IO/VPackageFileStreamManager.cpp",
    "./src/IO/hkvAssetUIDLookUpTable.cpp",
    "./src/vResource/vResource.cpp",
    "./src/vResource/vResourceManager.cpp",
    "./src/vResource/vResourceSnapshot.cpp",
    "./src/vResource/VTextureManager.cpp",
    "./src/vResource/VTextureObject.cpp",
    "./src/vResource/VTextureObjectGLES2.inl",
    "./src/vResource/VTextureObjectPC.inl",
    "./src/vResource/VTextureObjectPS3.inl",
    "./src/vResource/VTextureObjectPSP2.inl",
    "./src/vResource/VTextureObjectXenon.inl",
    "./src/VHAL/VDevCapsHandler.cpp",
    "./src/VHAL/VGraphicsMemoryPS3.cpp",
    "./src/VHAL/VGraphicsMemoryPSP2.cpp",
    "./src/VHAL/VInput.cpp",
    "./src/VHAL/VInputPC.cpp",
    "./src/VHAL/VInputPCMultitouch.cpp",
    "./src/VHAL/VInputPCMotion.cpp",
    "./src/VHAL/VInputPS3.cpp",
    "./src/VHAL/VInputPSP2.cpp",
    "./src/VHAL/VInputTouch.cpp",
    "./src/VHAL/VInputXenon.cpp",
    "./src/VHAL/VInputXI.cpp",
    "./src/VHAL/VMemoryBasePS3.cpp",
    "./src/VHAL/VOpenGLExtHelper.cpp",
    "./src/VHAL/VPerfMetricsPSP2.cpp",
    "./src/VHAL/VRenderInterface.cpp",
    "./src/VHAL/VSuspendedRenderingPS3.cpp",
    "./src/VHAL/VVertexDescriptor.cpp",
    "./src/VHAL/VVideo.cpp",
    "./src/VHAL/VVideoCaps.cpp",
    "./src/VHAL/VVideoPS3.inl",
    "./src/VHAL/VVideoXBox360.inl",
    "./src/VHAL/VVideoPSP2.inl",
    "./src/VHAL/VVideoIOS.inl",
    "./src/VHAL/VVideoAndroid.inl",
    "./src/VHAL/VVideoGLES2.inl",
    "./src/VHAL/VVideoWindows.inl",
    "./src/VHAL/WGLWnd.cpp",
    "./src/VClipboardHelper.cpp",
    "./src/VProfiling.cpp",
    "./src/VProgressStatus.cpp",
    "./src/vPlatformStub/vPlatformStubBase.cpp",
    "./src/vPlatformStub/vPlatformStubDX11.cpp",
    "./src/vPlatformStub/vPlatformStubDX9.cpp",
    "./src/vPlatformStub/vPlatformStubGLES2.cpp",
    "./src/vPlatformStub/vPlatformStubLinux.cpp",
    "./src/vPlatformStub/vPlatformStubPS3.cpp",
    "./src/vPlatformStub/vPlatformStubPSP2.cpp",
    "./src/vPlatformStub/vPlatformStubXbox360.cpp",
    "./src/vPlatformStub/vPlatformStubCafe.cpp",
    "./src/VThreadManager/VBackgroundThread.cpp",
    "./src/VThreadManager/VManagedThread.cpp",
    "./src/VThreadManager/VThreadedTask.cpp",
    "./src/VThreadManager/VThreadManager.cpp",
    "./src/VSpursHandler/VSpuPrintfService.cpp",
    "./src/VSpursHandler/VSpursHandler.cpp",
    "./src/VStreamProcessor/VStreamProcessingTask.cpp",
    "./src/VStreamProcessor/VStreamProcessor.cpp",
    "./src/VRemoteCommunication/VConnection.cpp",
    "./src/VRemoteCommunication/VMessage.cpp",
    "./src/VRemoteCommunication/VTarget.cpp",
    "./src/VBaseMem.cpp",
    "./src/VMemDump.cpp",
    "./src/VMemoryManager.cpp",
    "./src/VSmallBlockMemoryManager.cpp",
	"./src/VStackWalker.cpp",
    "../../shared/include/vBase/dynarray.hpp",
    "../../shared/include/vBase/stack.hpp",
    "./StdAfx.h",
    "../../shared/include/vBase/svdebugfile.hpp",
    "../../shared/include/vBase/svfile.hpp",
    "../../shared/include/vBase/VAction.hpp",
    "../../shared/include/vBase/VActionManager.hpp",
    "../../shared/include/vBase/VArgList.hpp",
    "../../shared/include/vBase/vBaseImpExp.hpp",
    "../../shared/include/vBase/VBaseVersion.hpp",
    "../../shared/include/vBase/VColor.hpp",
    "../../shared/include/vBase/VCommand.hpp",
    "../../shared/include/vBase/VCommandManager.hpp",
    "../../shared/include/vBase/VCRC.hpp",
    "../../shared/include/vBase/vEndianSwitch.h",
    "../../shared/include/vBase/VExceptions.hpp",
	"../../shared/include/vBase/VStackWalker.hpp",
    "../../shared/include/vBase/VFileLib/VFileAccess.hpp",
    "../../shared/include/vBase/VFileExtDefinitions.hpp",
    "../../shared/include/vBase/VGuid.hpp",
    "../../shared/include/vBase/VLocale.hpp",
    "../../shared/include/vBase/vLog.hpp",
    "../../shared/include/vBase/VModule.hpp",
    "../../shared/include/vBase/VModuleInfo.hpp",
    "../../shared/include/vBase/VModuleInfoList.hpp",
    "../../shared/include/vBase/VReceiver.hpp",
    "../../shared/include/vBase/VMath/VRectanglef.hpp",
    "../../shared/include/vBase/VRefCounter.hpp",
    "../../shared/include/vBase/VRefTarget.hpp",
    "../../shared/include/vBase/VReport.hpp",
    "../../shared/include/vBase/VReportMessage.hpp",
    "../../shared/include/vBase/VSenderReceiver.hpp",
    "../../shared/include/vBase/VSerialX.hpp",
    "../../shared/include/vBase/VString.hpp",
    "../../shared/include/vBase/VStringTokenizer.hpp",
    "../../shared/include/vBase/VStringTokenizerInPlace.hpp",
    "../../shared/include/vBase/VStringUtil.hpp",
    "../../shared/include/vBase/VStrRef.hpp",
    "../../shared/include/vBase/VTex.hpp",
    "../../shared/include/vBase/VType.hpp",
    "../../shared/include/vBase/VTypedObjectReference.hpp",
    "../../shared/include/vBase/VTypeManager.hpp",
    "../../shared/include/vBase/Vulpine.hpp",
    "../../shared/include/vBase/VUndoRedoStack.hpp",
    "../../shared/include/vBase/VVarType.hpp",
    "../../shared/include/vBase/VWeakPtr.hpp",
    "../../shared/include/vBase/VWindow.hpp",
    "../../shared/include/vBase/VFileLib/VArchive.hpp",
    "../../shared/include/vBase/VFileLib/VChunkFile.hpp",
    "../../shared/include/vBase/VFileLib/VFileData.hpp",
    "../../shared/include/vBase/VFileLib/VFileTime.hpp",
    "../../shared/include/vBase/VFileLib/VSerializationProxy.hpp",
    "../../shared/include/vBase/VADT/VArray.hpp",
    "../../shared/include/vBase/VADT/VStack.hpp",
    "../../shared/include/vBase/VADT/VBitField.hpp",
    "../../shared/include/vBase/VADT/VCollection.hpp",
    "../../shared/include/vBase/VADT/VDictionary.hpp",
    "../../shared/include/vBase/VADT/VKDTree.hpp",
    "../../shared/include/vBase/VADT/VLink.hpp",
    "../../shared/include/vBase/VADT/VLinkedList.hpp",
    "../../shared/include/vBase/VADT/VMaphpp.inc",
    "../../shared/include/vBase/VADT/VMaps.hpp",
    "../../shared/include/vBase/VADT/VMapStrToPtr.hpp",
    "../../shared/include/vBase/VADT/VPList.hpp",
    "../../shared/include/vBase/VADT/VPListStack.hpp",
    "../../shared/include/vBase/VADT/VRingBuffer.hpp",
    "../../shared/include/vBase/VADT/VSet.hpp",
    "../../shared/include/vBase/VADT/vstrlist.hpp",
    "../../shared/include/vBase/VADT/VTraits.hpp",
    "../../shared/include/vBase/VParam/VParam.hpp",
    "../../shared/include/vBase/VParam/VParamArray.hpp",
    "../../shared/include/vBase/VParam/VParamBlock.hpp",
    "../../shared/include/vBase/VParam/VParamComposite.hpp",
    "../../shared/include/vBase/VParam/VParamContainer.hpp",
    "../../shared/include/vBase/VParam/VParamContainerBase.hpp",
    "../../shared/include/vBase/VParam/VParamDesc.hpp",
    "../../shared/include/vBase/VParam/VParamExpression.hpp",
    "../../shared/include/vBase/hkvMath/hkvMath.h",
    "../../shared/include/vBase/hkvMath/hkvMathConfig.h",
    "../../shared/include/vBase/hkvMath/hkvVec2.h",
    "../../shared/include/vBase/hkvMath/hkvVec3.h",
    "../../shared/include/vBase/hkvMath/hkvVec4.h",
    "../../shared/include/vBase/hkvMath/hkvMat3.h",
    "../../shared/include/vBase/hkvMath/hkvMat4.h",
    "../../shared/include/vBase/hkvMath/hkvPlane.h",
    "../../shared/include/vBase/hkvMath/hkvQuat.h",
    "../../shared/include/vBase/hkvMath/hkvEulerUtil.h",
    "../../shared/include/vBase/hkvMath/hkvFrustum.h",
    "../../shared/include/vBase/hkvMath/hkvAlignedBBox.h",
    "../../shared/include/vBase/hkvMath/hkvBoundingSphere.h",
    "../../shared/include/vBase/hkvMath/Inlines/hkvMatHelpers.h",
    "../../shared/include/vBase/hkvMath/Inlines/hkvMat3Helpers.h",
    "../../shared/include/vBase/hkvMath/Inlines/hkvMat4Helpers.h",
    "../../shared/include/vBase/hkvMath/Inlines/hkvMath.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvVec2.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvVec3.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvVec4.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvMat3.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvMat4.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvPlane.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvQuat.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvFrustum.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvAlignedBBox.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvBoundingSphere.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvEulerUtil.inl",
    "../../shared/include/vBase/VMath/VBBox.hpp",
    "./src/VMath/VBBoxcpp.inc",
    "../../shared/include/vBase/VMath/VBBoxf.hpp",
    "../../shared/include/vBase/VMath/VBBoxhpp.inc",
    "../../shared/include/vBase/VMath/VBBoxOctree.hpp",
    "../../shared/include/vBase/VMath/VCollisionData.hpp",
    "../../shared/include/vBase/VMath/VCollisionMesh.hpp",
    "../../shared/include/vBase/VMath/VCollisionMesh32.hpp",
    "../../shared/include/vBase/VMath/VCollisionMeshBase.hpp",
    "../../shared/include/vBase/VMath/VCollisionNode.hpp",
    "../../shared/include/vBase/VMath/VCollisionSurface.hpp",
    "../../shared/include/vBase/VMath/VFloat16.hpp",
    "../../shared/include/vBase/VMath/VIntersect.hpp",
    "../../shared/include/vBase/VMath/VLine.hpp",
    "../../shared/include/vBase/VMath/VMappingVertex.hpp",
    "../../shared/include/vBase/VMath/VMathHelpers.hpp",
    "../../shared/include/vBase/VMath/VMatrix4.hpp",
    "../../shared/include/vBase/VMath/VMatrix4hpp.inc",
    "../../shared/include/vBase/VMath/VMatrixUtils.hpp",
    "../../shared/include/vBase/VMath/VPlane.hpp",
    "../../shared/include/vBase/VMath/VPlanef.hpp",
    "../../shared/include/vBase/VMath/VTriangle.hpp",
    "../../shared/include/vBase/VMath/VVertex.hpp",
    "../../shared/include/vBase/VMath/VVertex2.hpp",
    "../../shared/include/vBase/VMath/VVertex3.hpp",
    "../../shared/include/vBase/VMath/VVertex3f.hpp",
    "../../shared/include/vBase/VMath/VVertex3hpp.inc",
    "../../shared/include/vBase/VMath/VVertex4.hpp",
    "./include/VGL/controller.hpp",
    "./include/VGL/crashhandler.hpp",
    "./include/VGL/directdraw.hpp",
    "./include/VGL/directinput.hpp",
    "./include/modulelistclasses.h",
    "./include/modulelistoscode.h",
    "./include/VGL/screen.hpp",
    "../../shared/include/vBase/VParam/VParamType.hpp",
    "./include/VReportDialog.hpp",
    "./include/vtex_imp.hpp",
    "./include/vResource/VTextureFormatMap.hpp",
    "../../shared/include/vBase/MFC/VCVersionListCtrl.h",
    "../../shared/include/vBase/VTest/VImageComparison.hpp",
    "../../shared/include/vBase/VTest/vTestClass.hpp",
    "../../shared/include/vBase/VTest/vTestUnit.hpp",
    "./include/VGL/directx.hpp",
    "./include/VGL/keyboard.hpp",
    "./include/VGL/logwindow.hpp",
    "./include/VGL/mouse.hpp",
    "./include/VGL/reg.hpp",
    "../../shared/include/vBase/vShader/vEffectAssignment.hpp",
    "../../shared/include/vBase/vShader/vLightGrid.hpp",
    "../../shared/include/vBase/vShader/VOpenGLextheader.hpp",
    "../../shared/include/vBase/vShader/vShaderFXParser.hpp",
    "../../shared/include/vBase/Io/IVFileStream.hpp",
    "../../shared/include/vBase/Io/VClipboard.hpp",
    "../../shared/include/vBase/Io/VDiskFileStreamManager.hpp",
    "../../shared/include/vBase/Io/VFileHelper.hpp",
    "../../shared/include/vBase/Io/VMemoryStream.hpp",
    "../../shared/include/vBase/Io/VZipFileStreamManager.hpp",
    "../../shared/include/vBase/Io/VPackageFileStreamManager.hpp",
    "../../shared/include/vBase/Io/hkvAssetUIDLookUpTable.hpp",
    "../../shared/include/vBase/vResource/VResource.hpp",
    "../../shared/include/vBase/vResource/VResourceManager.hpp",
    "../../shared/include/vBase/vResource/VResourceSnapshot.hpp",
    "../../shared/include/vBase/vTex/VTextureLoader.hpp",
    "../../shared/include/vBase/vResource/VTextureManager.hpp",
    "../../shared/include/vBase/vResource/VTextureObject.hpp",
    "../../shared/include/vBase/vResource/VTextureObject.inl",
    "../../shared/include/vBase/VHAL/VDevCapsHandler.hpp",
    "../../shared/include/vBase/VHAL/VGraphicsMemoryPS3.hpp",
    "../../shared/include/vBase/VHAL/VInput.hpp",
    "../../shared/include/vBase/VHAL/VInputPC.hpp",
    "../../shared/include/vBase/VHAL/VInputPS3.hpp",
    "../../shared/include/vBase/VHAL/VInputPSP2.hpp",
    "../../shared/include/vBase/VHAL/VInputXenon.hpp",
    "../../shared/include/vBase/VHAL/VInputXI.hpp",
    "../../shared/include/vBase/VHAL/VLockableMemoryPSP2.inl",
    "../../shared/include/vBase/VHAL/VMemoryBasePS3.hpp",
    "../../shared/include/vBase/VHAL/VOpenGLExtHelper.hpp",
    "../../shared/include/vBase/VHAL/VPerfMetricsPSP2.hpp",
    "../../shared/include/vBase/VADT/VRawDataBlock.hpp",
    "../../shared/include/vBase/VHAL/VRenderInterface.hpp",
    "../../shared/include/vBase/VHAL/VShaderDefines.hpp",
    "../../shared/include/vBase/VHAL/VSuspendedRenderingPS3.hpp",
    "../../shared/include/vBase/VHAL/VTagMemoryManagmentPS3.inc",
    "../../shared/include/vBase/VHAL/VVertexDescriptor.hpp",
    "../../shared/include/vBase/VHAL/VVideo.hpp",
    "../../shared/include/vBase/VHAL/VVideoCaps.hpp",
    "../../shared/include/vBase/VHAL/WGLWnd.h",
    "../../shared/include/vBase/VClipboardHelper.hpp",
    "../../shared/include/vBase/VProfiling.hpp",
    "../../shared/include/vBase/VProgressStatus.hpp",
    "../../shared/include/vBase/VUserDataObj.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubBase.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubDX11.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubDX9.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubGLES2.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubLinux.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubPS3.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubPSP2.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubXbox360.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubCafe.hpp",
    "../../shared/include/vBase/VThreadManager/VBackgroundThread.hpp",
    "../../shared/include/vBase/VThreadManager/VManagedThread.hpp",
    "../../shared/include/vBase/VThreadManager/VThreadedTask.hpp",
    "../../shared/include/vBase/VThreadManager/VThreadManager.hpp",
    "../../shared/include/vBase/VThreadManager/VThreadVariable.hpp",
    "../../shared/include/vBase/VThreadManager/VMutex.hpp",
    "../../shared/include/vBase/VThreadManager/VMutexPC.inl",
    "../../shared/include/vBase/VThreadManager/VMutexPOSIX.inl",
    "../../shared/include/vBase/VThreadManager/VMutexXenon.inl",
    "../../shared/include/vBase/VThreadManager/VMutexPSP2.inl",
    "../../shared/include/vBase/VThreadManager/VMutexPS3.inl",
    "../../shared/include/vBase/VThreadManager/VEvent.hpp",
    "../../shared/include/vBase/VThreadManager/VEventPC.inl",
    "../../shared/include/vBase/VThreadManager/VEventPOSIX.inl",
    "../../shared/include/vBase/VThreadManager/VEventXenon.inl",
    "../../shared/include/vBase/VThreadManager/VEventPSP2.inl",
    "../../shared/include/vBase/VThreadManager/VEventPS3.inl",
    "../../shared/include/vBase/VThreadManager/VThread.hpp",
    "../../shared/include/vBase/VThreadManager/VThreadPC.inl",
    "../../shared/include/vBase/VThreadManager/VThreadPOSIX.inl",
    "../../shared/include/vBase/VThreadManager/VThreadXenon.inl",
    "../../shared/include/vBase/VThreadManager/VThreadPSP2.inl",
    "../../shared/include/vBase/VThreadManager/VThreadPS3.inl",
    "../../shared/include/vBase/vShader/vCompiledEffect.hpp",
    "../../shared/include/vBase/vShader/vCompiledShaderManager.hpp",
    "../../shared/include/vBase/vShader/vCompiledShaderPass.hpp",
    "../../shared/include/vBase/vShader/vConstantBuffer.hpp",
    "../../shared/include/vBase/vShader/VLightmapHelper.hpp",
    "../../shared/include/vBase/vShader/vShaderConstants.hpp",
    "../../shared/include/vBase/vShader/vShaderEffectLib.hpp",
    "../../shared/include/vBase/vShader/vShaderIncludeManager.hpp",
    "../../shared/include/vBase/vShader/vShaderIncludes.hpp",
    "../../shared/include/vBase/vShader/vShaderParam.hpp",
    "../../shared/include/vBase/vShader/vShaderPassResource.hpp",
    "../../shared/include/vBase/vShader/vRenderStateContainer.hpp",
    "../../shared/include/vBase/vShader/vShaderDeclarations.hpp",
    "../../shared/include/vBase/vShader/vShaderProgramResource.hpp",
    "../../shared/include/vBase/vShader/vSimpleRenderState.hpp",
    "../../shared/include/vBase/vShader/vStateGroups.hpp",
    "../../shared/include/vBase/vShader/vStateGroupSampler.hpp",
    "../../shared/include/vBase/vShader/vTechniqueConfig.hpp",
    "./tinyXML/tinystr.h",
    "./tinyXML/tinyxml.h",
    "./tinyXML/TinyXMLHelper.hpp",
    "../../shared/include/vBase/VSpursHandler/VSpuPrintfService.h",
    "../../shared/include/vBase/VSpursHandler/VSpursHandler.hpp",
    "../../shared/include/vBase/VStreamProcessor/VDataStream.hpp",
    "../../shared/include/vBase/VStreamProcessor/VStreamIterator_SPURS_PS3.hpp",
    "../../shared/include/vBase/VStreamProcessor/vstreamiterator_threadedtask.hpp",
    "../../shared/include/vBase/VStreamProcessor/VStreamProcessingHelpers_SPURS_PS3.hpp",
    "../../shared/include/vBase/VStreamProcessor/VStreamProcessingHelpers_ThreadedTask.hpp",
    "../../shared/include/vBase/VStreamProcessor/VStreamProcessingTask.hpp",
    "../../shared/include/vBase/VStreamProcessor/vstreamprocessor.hpp",
    "../../shared/include/vBase/VRemoteCommunication/VConnection.hpp",
    "../../shared/include/vBase/VRemoteCommunication/VMessage.hpp",
    "../../shared/include/vBase/VRemoteCommunication/VTarget.hpp",
    "../../shared/include/vBase/VBaseMem.hpp",
    "../../shared/include/vBase/VMemCheck.hpp",
    "../../shared/include/vBase/VMemDbg.hpp",
    "../../shared/include/vBase/VMemDump.hpp",
    "../../shared/include/vBase/VMemoryManager.hpp",
    "../../shared/include/vBase/VSmallBlockMemoryManager.hpp",
    "./resource.h",
    "./vBase.rc",
    "./vBase.rc2",
    "./src/VGL/Xboxcontroller.cpp",
    "../../shared/include/vBase/VBase.hpp",
    "../../shared/include/vBase/VBroadcaster.hpp",
    "../../shared/include/vBase/VGL.hpp" }

resourceFiles = { "" }

elseif buildSystem == "xcode3" or buildSystem == "xcode4" then

  projectLocation = "."
projectBaseName = tempSlnPrefix .. "vBase"
  projectName = projectBaseName .. buildSystemSuffix -- NOTE: For solutions/projects that shouldn
  projectGUID = "03D610D2-8C32-4A62-BAB3-DA28561AC7B7"
  outputFolder = ""
  outputTarget = projectName -- If this variable is not used the specific ones will be the used instead. Tipically this field will contain: projectName
  projectReferences = ""
  projectLanguage = "C++"
  
  buildTempDir = "intermediate/$(PLATFORM_NAME)/$(CONFIGURATION)"
  
  sourcePCH = "../vBase-Prefix.pch"
  sourceHeaderPCHXbox360 = "" -- Sets the correct precompiled header option for Xbox360 when using property sheets.
sourceHeaderPCH = "../vBase-Prefix.pch"
  
  definesAll = { "VBASE_LIB", "_VISION_IOS", "_VISION_POSIX", "_VR_GLES2" }
  definesDebug = { definesAll, "DEBUG", "_DEBUG" }
  definesRelease = { definesAll }

  -- Specific output folders.
  outputFolderDebugWin32 = "../../shared/lib/$(PLATFORM_NAME)/$(CONFIGURATION)"
  outputFolderReleaseWin32 = "../../shared/lib/$(PLATFORM_NAME)/$(CONFIGURATION)"
  
  includeDirsCommon = { "./", "./include", "../../shared/include/vBase", "./zlib", "./tinyXML", "../../", JPEGLibIncludeDirs, PNGLibIncludeDirs }
  includeDirsWin32 = { includeDirsCommon }
  
  libDirsWin32 = { }
  libLinkDebugDx9Win32 = { }
  libLinkReleaseDx9Win32 = { }
    
  bIsEnginePlugin = false
outputTypeWin = "StaticLib"

  flagsDebugWin32     = { "Symbols" }  
  buildOptReleaseWin32  = { "-DNS_BLOCK_ASSERTIONS=1" }
  flagsReleaseWin32     = { "Optimize" }
  
  excludedSourcesWindows = { "" }

  sourceFilesTinyXML = { 
    "./tinyXML/tinystr.cpp",
    "./tinyXML/tinyxml.cpp",
    "./tinyXML/tinyxmlerror.cpp",
    "./tinyXML/TinyXMLHelper.cpp",
    "./tinyXML/tinyxmlparser.cpp",
  }

  sourceFilesZLib = {
    "./zLib/adler32.c",
    "./zLib/compress.c",
    "./zLib/crc32.c",
    "./zLib/deflate.c",
    "./zLib/infback.c",
    "./zLib/inffast.c",
    "./zLib/inflate.c",
    "./zLib/inftrees.c",
    "./zLib/trees.c",
    "./zLib/uncompr.c",
    "./zLib/zutil.c",
    "./zLib/contrib/minizip/unzip.c",
    "./zLib/contrib/minizip/ioapi.c"
  }
  
  sourcesNotUsingPCH = { 
    sourceFilesTinyXML,
    sourceFilesZLib
  }

  excludedSourcesMac = { }
  
  sourceFiles = {
    sourceFilesTinyXML,
    sourceFilesZLib,
    "./src/StdAfx.cpp",
    "./src/VHAL/IOSBridge.m",
    "./src/VHAL/IOSTouch.mm",
    "./src/IO/IVFileStream.cpp",
    "./src/IO/IVFileStreamPS3.inl",
    "./src/IO/IVFileStreamPosix.inl",
    "./src/IO/IVFileStreamPC.inl",
    "./src/IO/IVFileStreamPSP2.inl",
    "./src/IO/IVFileStreamXenon.inl",
    "./src/IO/IVRevisionControlSystem.cpp",
    "./src/IO/VClipboard.cpp",
    "./src/IO/VDiskFileStreamManager.cpp",
    "./src/IO/VFileAccessManager.cpp",
    "./src/IO/VFileCopyList.cpp",
    "./src/IO/VMemoryStream.cpp",
    "./src/IO/VZipFileStreamManager.cpp",
    "./src/IO/VPackageFileStreamManager.cpp",
    "./src/IO/hkvAssetUIDLookUpTable.cpp",
    "./src/private/VReport.cpp",
    "./src/svdebugfile.cpp",
    "./src/svfile.cpp",
    "./src/VAction.cpp",
    "./src/VActionManager.cpp",
    "./src/VADT/VBitField.cpp",
    "./src/VADT/VDictionary.cpp",
    "./src/VADT/VLink.cpp",
    "./src/VADT/VMaps.cpp",
    "./src/VADT/VMapStrToPtr.cpp",
    "./src/VADT/VPList.cpp",
    "./src/VADT/VRawDataBlock.cpp",
    "./src/VADT/vstrlist.cpp",
    "./src/VArgList.cpp",
    "./src/vBase.cpp",
    "./src/VBaseMem.cpp",
    "./src/VCallbacks.cpp",
    "./src/VClipboardHelper.cpp",
    "./src/VColor.cpp",
    "./src/VCommand.cpp",
    "./src/VCommandManager.cpp",
    "./src/VCRC.cpp",
    "./src/VEndianSwitch.cpp",
    "./src/VExceptions.cpp",
    "./src/VFileLib/VFileAccess.cpp",
    "./src/VFileLib/VFileAccessPS3.inl",
    "./src/VFileLib/VFileAccessPOSIX.inl",
    "./src/VFileLib/VFileAccessPSP2.inl",
    "./src/VFileLib/VFileAccessXenon.inl",
    "./src/VFileLib/VFileAccessPC.inl",
    "./src/VFileLib/VFileAccessiOS.inl",
    "./src/VFileLib/VArchive.cpp",
    "./src/VFileLib/VChunkFile.cpp",
    "./src/VFileLib/VFileTime.cpp",
    "./src/VFileLib/VSerializationProxy.cpp",
    "./src/VGL/Misc.cpp",
    "./src/VGL/VGLMiscPS3.inl",
    "./src/VGL/VGLMiscPSP2.inl",
    "./src/VGL/VGLMiscXenon.inl",
    "./src/VGL/VGLMiscPOSIX.inl",
    "./src/VGL/VGLMiscPC.inl",
    "./src/VGL/mouse.cpp",
    "./src/VGL/ResourceViewerConsoles.cpp",
    "./src/VGL/Vgl.cpp",
    "./src/VGuid.cpp",
    "./src/VHAL/VInput.cpp",
    "./src/VHAL/VInputIOS.cpp",
    "./src/VHAL/VInputTouch.cpp",
    "./src/VHAL/VRenderInterface.cpp",
    "./src/VHAL/VVertexDescriptor.cpp",
    "./src/VHAL/VVideo.cpp",
    "./src/VHAL/VVideoCaps.cpp",
    "./src/VHAL/VVideoPS3.inl",
    "./src/VHAL/VVideoXBox360.inl",
    "./src/VHAL/VVideoPSP2.inl",
    "./src/VHAL/VVideoIOS.inl",
	"./src/VHAL/VVideoWindows.inl",
    "./src/vLog.cpp",
    "./src/hkvMath/hkvMath.cpp",
    "./src/hkvMath/hkvVec3.cpp",
    "./src/hkvMath/hkvVec4.cpp",
    "./src/hkvMath/hkvMat3.cpp",
    "./src/hkvMath/hkvMat4.cpp",
    "./src/hkvMath/hkvPlane.cpp",
    "./src/hkvMath/hkvQuat.cpp",
    "./src/hkvMath/hkvEulerUtil.cpp",
    "./src/hkvMath/hkvAlignedBBox.cpp",    
    "./src/hkvMath/hkvBoundingSphere.cpp",
    "./src/VMath/VBBox.cpp",
    "./src/VMath/VBBoxcpp.inc",
    "./src/VMath/VBBoxOctree.cpp",
    "./src/VMath/VCollisionData.cpp",
    "./src/VMath/VCollisionMesh.cpp",
    "./src/VMath/VCollisionMesh32.cpp",
    "./src/VMath/VCollisionMeshBase.cpp",
    "./src/VMath/VCollisionNode.cpp",
    "./src/VMath/VCollisionSurface.cpp",
    "./src/VMath/VIntersect.cpp",
    "./src/VMath/VLine.cpp",
    "./src/VMath/VMappingVertex.cpp",
    "./src/VMath/VMathHelpers.cpp",
    "./src/VMath/VMatrix4.cpp",
    "./src/VMath/VMatrix4cpp.inc",
    "./src/VMath/VPlane.cpp",
    "./src/VMath/VPlane4cpp.inc",
    "./src/VMath/VRectanglef.cpp",
    "./src/VMath/VTriangle.cpp",
    "./src/VMath/VVertex2.cpp",
    "./src/VMath/VVertex3.cpp",
    "./src/VMath/VVertex3cpp.inc",
    "./src/VMemDump.cpp",
    "./src/VMemoryManager.cpp",
    "./src/VModule.cpp",
    "./src/VParam/VParam.cpp",
    "./src/VParam/VParamArray.cpp",
    "./src/VParam/VParamBlock.cpp",
    "./src/VParam/VParamComposite.cpp",
    "./src/VParam/VParamContainer.cpp",
    "./src/VParam/VParamDesc.cpp",
    "./src/VParam/VParamExpression.cpp",
    "./src/vPlatformStub/vPlatformStubBase.cpp",
    "./src/VProfiling.cpp",
    "./src/VProgressStatus.cpp",
    "./src/VReceiver.cpp",
    "./src/VRefTarget.cpp",
    "./src/VRemoteCommunication/VConnection.cpp",
    "./src/VRemoteCommunication/VMessage.cpp",
    "./src/VRemoteCommunication/VTarget.cpp",
    "./src/VReportMessage.cpp",
    "./src/vResource/vResource.cpp",
    "./src/vResource/vResourceManager.cpp",
    "./src/vResource/vResourceSnapshot.cpp",
    "./src/vResource/VTextureManager.cpp",
    "./src/vResource/VTextureObject.cpp",
    "./src/vResource/VTextureObjectGLES2.inl",
    "./src/vResource/VTextureObjectPC.inl",
    "./src/vResource/VTextureObjectPS3.inl",
    "./src/vResource/VTextureObjectPSP2.inl",
    "./src/vResource/VTextureObjectXenon.inl",
    "./src/VSenderReceiver.cpp",
    "./src/vShader/vCompiledEffect.cpp",
    "./src/vShader/vCompiledShaderManager.cpp",
    "./src/vShader/vCompiledShaderPass.cpp",
    "./src/vShader/vConstantBuffer.cpp",
    "./src/vShader/vEffectAssignment.cpp",
    "./src/vShader/vLightGrid.cpp",
    "./src/vShader/vLightmapHelper.cpp",
    "./src/vShader/vShaderEffectLib.cpp",
    "./src/vShader/vShaderFXParser.cpp",
    "./src/vShader/vShaderIncludeManager.cpp",
    "./src/vShader/vShaderParam.cpp",
    "./src/vShader/vShaderPassResource.cpp",
    "./src/vShader/vShaderPassResourceGLES2.cpp",
    "./src/vShader/vTechniqueConfig.cpp",
    "./src/VSmallBlockMemoryManager.cpp",
    "./src/VStreamProcessor/VStreamProcessingTask.cpp",
    "./src/VStreamProcessor/VStreamProcessor.cpp",
    "./src/VString.cpp",
    "./src/VStringTokenizer.cpp",
    "./src/VStringTokenizerInPlace.cpp",
    "./src/VStringUtil.cpp",
    "./src/VTest/VImageComparison.cpp",
    "./src/VTest/vTestClass.cpp",
    "./src/VTest/vTestUnit.cpp",
    "./src/VTex/VCompressionHelper.cpp",
    "./src/VTex/VTex_bmp.cpp",
    "./src/VTex/VTex_dds.cpp",
    "./src/VTex/VTex_dem.cpp",
    "./src/VTex/VTex_jpeg.cpp",
    "./src/VTex/VTex_jpg_datadst.cpp",
    "./src/VTex/VTex_jpg_datasrc.cpp",
    "./src/VTex/VTex_tex.cpp",
    "./src/VTex/VTex_tga.cpp",
    "./src/VTex/VTex_tiff.cpp",
    "./src/VTex/VTextureLoader.cpp",
    "./src/VTex.cpp",
    "./src/VThreadManager/VBackgroundThread.cpp",
    "./src/VThreadManager/VManagedThread.cpp",
    "./src/VThreadManager/VThreadedTask.cpp",
    "./src/VThreadManager/VThreadManager.cpp",
    "./src/VType.cpp",
    "./src/VTypedObjectReference.cpp",
    "./src/VTypeManager.cpp",
    "./src/VUndoRedoStack.cpp",
    "./src/VPlatformPosix.cpp",
	"./src/VStackWalker.cpp",

    "../../shared/include/vBase/VHAL/IOSBridge.h",
    "../../shared/include/vBase/IO/IVFileStream.hpp",
    "../../shared/include/vBase/IO/IVRevisionControlSystem.hpp",
    "../../shared/include/vBase/IO/VClipboard.hpp",
    "../../shared/include/vBase/IO/VDiskFileStreamManager.hpp",
    "../../shared/include/vBase/IO/VFileAccessManager.hpp",
    "../../shared/include/vBase/IO/VFileCopyList.hpp",
    "../../shared/include/vBase/IO/VMemoryStream.hpp",
    "../../shared/include/vBase/IO/VZipFileStreamManager.hpp",
    "../../shared/include/vBase/IO/VPackageFileStreamManager.hpp",
    "../../shared/include/vBase/IO/hkvAssetUIDLookUpTable.hpp",
    "../../shared/include/vBase/VReport.hpp",
    "../../shared/include/vBase/svdebugfile.hpp",
    "../../shared/include/vBase/svfile.hpp",
    "../../shared/include/vBase/VAction.hpp",
    "../../shared/include/vBase/VActionManager.hpp",
    "../../shared/include/vBase/VADT/VBitField.hpp",
    "../../shared/include/vBase/VADT/VDictionary.hpp",
    "../../shared/include/vBase/VADT/VLink.hpp",
    "../../shared/include/vBase/VADT/VMaps.hpp",
    "../../shared/include/vBase/VADT/VMapStrToPtr.hpp",
    "../../shared/include/vBase/VADT/VPList.hpp",
    "../../shared/include/vBase/VADT/VRawDataBlock.hpp",
    "../../shared/include/vBase/VADT/vstrlist.hpp",
	"../../shared/include/vBase/VADT/VScopedArray.hpp",
	"../../shared/include/vBase/VADT/VScopedPtr.hpp",
    "../../shared/include/vBase/VArgList.hpp",
    "../../shared/include/vBase/vBase.hpp",
    "../../shared/include/vBase/VBaseMem.hpp",
    "../../shared/include/vBase/VCallbacks.hpp",
    "../../shared/include/vBase/VClipboardHelper.hpp",
    "../../shared/include/vBase/VColor.hpp",
    "../../shared/include/vBase/VCommand.hpp",
    "../../shared/include/vBase/VCommandManager.hpp",
    "../../shared/include/vBase/VCRC.hpp",
	"../../shared/include/vBase/DisableStaticAnalysis.hpp",
    "../../shared/include/vBase/vEndianSwitch.h",
    "../../shared/include/vBase/VExceptions.hpp",
    "../../shared/include/vBase/VFileLib/VArchive.hpp",
    "../../shared/include/vBase/VFileLib/VChunkFile.hpp",
    "../../shared/include/vBase/VFileLib/VFileData.hpp",
    "../../shared/include/vBase/VFileLib/VFileTime.hpp",
    "../../shared/include/vBase/VFileLib/VSerializationProxy.hpp",
    "./include/VGL/mouse.hpp",
    "../../shared/include/vBase/VGuid.hpp",
	"../../shared/include/vBase/VSafeStringFunctions.hpp",
	"../../shared/include/vBase/VStackWalker.hpp",
    "../../shared/include/vBase/VHAL/VInputIOS.hpp",
    "../../shared/include/vBase/VHAL/VInputPC.hpp",
    "../../shared/include/vBase/VHAL/VInputPS3.hpp",
    "../../shared/include/vBase/VHAL/VInputX.hpp",
    "../../shared/include/vBase/VHAL/VInputXenon.hpp",
    "../../shared/include/vBase/VHAL/VInputXI.hpp",
    "../../shared/include/vBase/VHAL/VMemoryBasePS3.hpp",
    "../../shared/include/vBase/VHAL/VOpenGLExtHelper.hpp",
    "../../shared/include/vBase/VHAL/VRenderInterface.hpp",
    "../../shared/include/vBase/VHAL/VShaderDefines.hpp",
    "../../shared/include/vBase/VHAL/VSuspendedRenderingPS3.hpp",
    "../../shared/include/vBase/VHAL/VVertexDescriptor.hpp",
    "../../shared/include/vBase/VHAL/VVideo.hpp",
    "../../shared/include/vBase/VHAL/VVideoCaps.hpp",
    "../../shared/include/vBase/VHAL/wglext.h",
    "../../shared/include/vBase/VHAL/WGLWnd.h",
    "../../shared/include/vBase/hkvMath/hkvMath.h",
    "../../shared/include/vBase/hkvMath/hkvMathConfig.h",
    "../../shared/include/vBase/hkvMath/hkvVec3.h",
    "../../shared/include/vBase/hkvMath/hkvVec4.h",
    "../../shared/include/vBase/hkvMath/hkvMat3.h",
    "../../shared/include/vBase/hkvMath/hkvMat4.h",
    "../../shared/include/vBase/hkvMath/hkvPlane.h",
    "../../shared/include/vBase/hkvMath/hkvQuat.h",
    "../../shared/include/vBase/hkvMath/hkvEulerUtil.h",
    "../../shared/include/vBase/hkvMath/hkvFrustum.h",
    "../../shared/include/vBase/hkvMath/hkvAlignedBBox.h",
    "../../shared/include/vBase/hkvMath/hkvBoundingSphere.h",
    "../../shared/include/vBase/hkvMath/Inlines/hkvMatHelpers.h",
    "../../shared/include/vBase/hkvMath/Inlines/hkvMat3Helpers.h",
    "../../shared/include/vBase/hkvMath/Inlines/hkvMat4Helpers.h",
    "../../shared/include/vBase/hkvMath/Inlines/hkvMath.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvVec3.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvVec4.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvMat3.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvMat4.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvPlane.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvQuat.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvEulerUtil.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvFrustum.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvAlignedBBox.inl",
    "../../shared/include/vBase/hkvMath/Inlines/hkvBoundingSphere.inl",
    "../../shared/include/vBase/VMath/VBBox.hpp",
    "../../shared/include/vBase/VMath/VBBoxf.hpp",
    "../../shared/include/vBase/VMath/VBBoxOctree.hpp",
    "../../shared/include/vBase/VMath/VCollisionData.hpp",
    "../../shared/include/vBase/VMath/VCollisionMesh.hpp",
    "../../shared/include/vBase/VMath/VCollisionMesh32.hpp",
    "../../shared/include/vBase/VMath/VCollisionMeshBase.hpp",
    "../../shared/include/vBase/VMath/VCollisionNode.hpp",
    "../../shared/include/vBase/VMath/VCollisionSurface.hpp",
    "../../shared/include/vBase/VMath/VFloat16.hpp",
    "../../shared/include/vBase/VMath/VIntersect.hpp",
    "../../shared/include/vBase/VMath/VLine.hpp",
    "../../shared/include/vBase/VMath/VMappingVertex.hpp",
    "../../shared/include/vBase/VMath/VMathHelpers.hpp",
    "../../shared/include/vBase/VMath/VMatrix4.hpp",
    "../../shared/include/vBase/VMath/VMatrixUtils.hpp",
    "../../shared/include/vBase/VMath/VPlane.hpp",
    "../../shared/include/vBase/VMath/VPlanef.hpp",
    "../../shared/include/vBase/VMath/VRectanglef.hpp",
    "../../shared/include/vBase/VMath/VTriangle.hpp",
    "../../shared/include/vBase/VMath/VVertex.hpp",
    "../../shared/include/vBase/VMath/VVertex2.hpp",
    "../../shared/include/vBase/VMath/VVertex3.hpp",
    "../../shared/include/vBase/VMath/VVertex3f.hpp",
    "../../shared/include/vBase/VMath/VVertex4.hpp",
    "../../shared/include/vBase/vLog.hpp",
    "../../shared/include/vBase/VMemCheck.hpp",
    "../../shared/include/vBase/VMemDbg.hpp",
    "../../shared/include/vBase/VMemDump.hpp",
    "../../shared/include/vBase/VMemoryManager.hpp",
    "../../shared/include/vBase/VModule.hpp",
    "../../shared/include/vBase/VModuleInfo.hpp",
    "../../shared/include/vBase/VModuleInfoList.hpp",
    "../../shared/include/vBase/VParam/VParam.hpp",
    "../../shared/include/vBase/VParam/VParamArray.hpp",
    "../../shared/include/vBase/VParam/VParamBlock.hpp",
    "../../shared/include/vBase/VParam/VParamComposite.hpp",
    "../../shared/include/vBase/VParam/VParamContainer.hpp",
    "../../shared/include/vBase/VParam/VParamContainerBase.hpp",
    "../../shared/include/vBase/VParam/VParamDesc.hpp",
    "../../shared/include/vBase/VParam/VParamExpression.hpp",
    "../../shared/include/vBase/VParam/VParamType.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformHandlerShaderInfo.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformHandlerTypedefs.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubBase.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubDX10.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubDX11.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubDX9.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubLinux.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubPS3.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubPSP2.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubXbox360.hpp",
    "../../shared/include/vBase/vPlatformHandler/vPlatformStubCafe.hpp",
    "../../shared/include/vBase/VPlatformLinux.hpp",
    "../../shared/include/vBase/VPlatformPosix.hpp",
    "../../shared/include/vBase/VPlatformPS3.hpp",
    "../../shared/include/vBase/VPlatformWin32.hpp",
    "../../shared/include/vBase/VProfiling.hpp",
    "../../shared/include/vBase/VProgressStatus.hpp",
    "../../shared/include/vBase/VReceiver.hpp",
    "../../shared/include/vBase/VRefCounter.hpp",
    "../../shared/include/vBase/VRefTarget.hpp",
    "../../shared/include/vBase/VRemoteCommunication/VConnection.hpp",
    "../../shared/include/vBase/VRemoteCommunication/VMessage.hpp",
    "../../shared/include/vBase/VRemoteCommunication/VTarget.hpp",
    "../../shared/include/vBase/VReportMessage.hpp",
    "../../shared/include/vBase/vResource/VResource.hpp",
    "../../shared/include/vBase/vResource/VResourceManager.hpp",
    "../../shared/include/vBase/vResource/VResourceSnapshot.hpp",
    "../../shared/include/vBase/vResource/VTextureManager.hpp",
    "../../shared/include/vBase/vResource/VTextureObject.hpp",
    "../../shared/include/vBase/vResource/VTextureObject.inl",
    "../../shared/include/vBase/VSenderReceiver.hpp",
    "../../shared/include/vBase/VSerialX.hpp",
    "../../shared/include/vBase/vShader/vCompiledEffect.hpp",
    "../../shared/include/vBase/vShader/vCompiledShaderManager.hpp",
    "../../shared/include/vBase/vShader/vCompiledShaderPass.hpp",
    "../../shared/include/vBase/vShader/vConstantBuffer.hpp",
    "../../shared/include/vBase/vShader/vEffectAssignment.hpp",
    "../../shared/include/vBase/vShader/vLightGrid.hpp",
    "../../shared/include/vBase/vShader/VLightmapHelper.hpp",
    "../../shared/include/vBase/vShader/VOpenGLextheader.hpp",
    "../../shared/include/vBase/vShader/vShaderConstants.hpp",
    "../../shared/include/vBase/vShader/vShaderEffectLib.hpp",
    "../../shared/include/vBase/vShader/vShaderFXParser.hpp",
    "../../shared/include/vBase/vShader/vShaderIncludeManager.hpp",
    "../../shared/include/vBase/vShader/vShaderIncludes.hpp",
    "../../shared/include/vBase/vShader/vShaderParam.hpp",
    "../../shared/include/vBase/vShader/vShaderPassResource.hpp",
    "../../shared/include/vBase/vShader/vSimpleRenderState.hpp",
    "../../shared/include/vBase/vShader/vTechniqueConfig.hpp",
    "../../shared/include/vBase/VSmallBlockMemoryManager.hpp",
    "../../shared/include/vBase/VSpuDefs.hpp",
    "../../shared/include/vBase/VStreamProcessor/VStreamProcessingTask.hpp",
    "../../shared/include/vBase/VStreamProcessor/vstreamprocessor.hpp",
    "../../shared/include/vBase/VString.hpp",
    "../../shared/include/vBase/VStringTokenizer.hpp",
    "../../shared/include/vBase/VStringTokenizerInPlace.hpp",
    "../../shared/include/vBase/VStringUtil.hpp",
    "../../shared/include/vBase/VStrRef.hpp",
    "../../shared/include/vBase/VTest/VImageComparison.hpp",
    "../../shared/include/vBase/VTest/vTestClass.hpp",
    "../../shared/include/vBase/VTest/vTestUnit.hpp",
    "../../shared/include/vBase/vTex/VCompressionHelper.hpp",
    "../../shared/include/vBase/vTex/VTextureFileHeader.hpp",
    "../../shared/include/vBase/vTex/VTextureLoader.hpp",
    "../../shared/include/vBase/VTex.hpp",
    "../../shared/include/vBase/VThreadManager/VBackgroundThread.hpp",
    "../../shared/include/vBase/VThreadManager/VManagedThread.hpp",
    "../../shared/include/vBase/VThreadManager/VMutex.hpp",
    "../../shared/include/vBase/VThreadManager/VMutexPC.inl",
    "../../shared/include/vBase/VThreadManager/VMutexPOSIX.inl",
    "../../shared/include/vBase/VThreadManager/VMutexXenon.inl",
    "../../shared/include/vBase/VThreadManager/VMutexPSP2.inl",
    "../../shared/include/vBase/VThreadManager/VMutexPS3.inl",
    "../../shared/include/vBase/VThreadManager/VEvent.hpp",
    "../../shared/include/vBase/VThreadManager/VEventPC.inl",
    "../../shared/include/vBase/VThreadManager/VEventPOSIX.inl",
    "../../shared/include/vBase/VThreadManager/VEventXenon.inl",
    "../../shared/include/vBase/VThreadManager/VEventPSP2.inl",
    "../../shared/include/vBase/VThreadManager/VEventPS3.inl",
    "../../shared/include/vBase/VThreadManager/VThread.hpp",
    "../../shared/include/vBase/VThreadManager/VThreadPC.inl",
    "../../shared/include/vBase/VThreadManager/VThreadPOSIX.inl",
    "../../shared/include/vBase/VThreadManager/VThreadXenon.inl",
    "../../shared/include/vBase/VThreadManager/VThreadPSP2.inl",
    "../../shared/include/vBase/VThreadManager/VThreadPS3.inl",
    "../../shared/include/vBase/VThreadManager/VThreadedTask.hpp",
    "../../shared/include/vBase/VThreadManager/VThreadManager.hpp",
    "../../shared/include/vBase/VThreadManager/VThreadVariable.hpp",
    "../../shared/include/vBase/dynarray.hpp",
    "../../shared/include/vBase/IO/VFileHelper.hpp",
    "../../shared/include/vBase/MFC/VCVersionListCtrl.h",
    "../../shared/include/vBase/stack.hpp",
    "../../shared/include/vBase/VADT/VArray.hpp",
    "../../shared/include/vBase/VADT/VCollection.hpp",
    "../../shared/include/vBase/VADT/VElementCache.hpp",
    "../../shared/include/vBase/VADT/VKDTree.hpp",
    "../../shared/include/vBase/VADT/VLinkedList.hpp",
    "../../shared/include/vBase/VADT/VPListStack.hpp",
    "../../shared/include/vBase/VADT/VRingBuffer.hpp",
    "../../shared/include/vBase/vBaseImpExp.hpp",
    "../../shared/include/vBase/VBaseIncludes.hpp",
    "../../shared/include/vBase/VBaseVersion.hpp",
    "../../shared/include/vBase/VBaseX.hpp",
    "../../shared/include/vBase/VBroadcaster.hpp",
    "../../shared/include/vBase/VCommand.hpp",
    "../../shared/include/vBase/VCommandManager.hpp",
    "../../shared/include/vBase/VCRC.hpp",
    "../../shared/include/vBase/vEndianSwitch.h",
    "../../shared/include/vBase/VExceptions.hpp",
    "../../shared/include/vBase/VFileAccess.hpp",
    "../../shared/include/vBase/VFileExtDefinitions.hpp",
    "../../shared/include/vBase/VGL.hpp",
    "../../shared/include/vBase/VHAL/VDevCapsHandler.hpp",
    "../../shared/include/vBase/VSingleton.hpp",
    "../../shared/include/vBase/VSpursHandler/VSpuPrintfService.h",
    "../../shared/include/vBase/VSpursHandler/VSpursHandler.hpp",
    "../../shared/include/vBase/VStreamProcessor/VDataStream.hpp",
    "../../shared/include/vBase/VStreamProcessor/VStreamIterator_SPURS_PS3.hpp",
    "../../shared/include/vBase/VStreamProcessor/vstreamiterator_threadedtask.hpp",
    "../../shared/include/vBase/VStreamProcessor/VStreamProcessingHelpers_SPURS_PS3.hpp",
    "../../shared/include/vBase/VStreamProcessor/VStreamProcessingHelpers_ThreadedTask.hpp",
    "../../shared/include/vBase/VType.hpp",
    "../../shared/include/vBase/VTypedObjectReference.hpp",
    "../../shared/include/vBase/VTypeManager.hpp",
    "../../shared/include/vBase/Vulpine.hpp",
    "../../shared/include/vBase/VUndoRedoStack.hpp",
    "../../shared/include/vBase/VUserDataObj.hpp",
    "../../shared/include/vBase/VVarType.hpp",
    "../../shared/include/vBase/VWeakPtr.hpp",
    "./include/VGL/controller.hpp",
    "./include/VGL/crashhandler.hpp",
    "./include/VGL/directdraw.hpp",
    "./include/VGL/directinput.hpp",
    "./include/VGL/directx.hpp",
    "./include/VGL/keyboard.hpp",
    "./include/VGL/logwindow.hpp",
    "./include/VGL/mouse.hpp",
    "./include/VGL/reg.hpp",
    "./include/VGL/screen.hpp"
  }
  
  resourceFiles = { "" }

end

ConfigureBuild("Project") -- Calls the script file that generates the project.