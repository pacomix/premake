os.chdir(globalScriptDir) -- Restore the working directory from where this file was included.

PrintVerbose("\t\tWorking directory: " .. os.getcwd())
local bUseSpecificTargetDir = false   -- Whether to use the specific fixed output dir or use the suffixed ones (binXXXXXXXXXX/libXXXXXXXXX).
local bUseSpecificTargetName = false  -- Whether to use the specific fixed output names or use the suffixed ones.
local baseSharedFolder = nil          -- Relative path to the Vision's trunk/shared/ folder
local bUseProfilingConfig = nil       -- Does the project contains profiling configs?
local outputTargetWithoutBuildSystemSuffix = nil  -- Self-descriptive. Used mostly for console output target name.
local bUseSpecificImportLibName = nil

if outputImportLibDebugWin32 ~= "" or outputImportLibDebugDX11Win32 ~= "" or outputImportLibDebugNoXIWin32 ~= "" or outputImportLibDebugX64 ~= "" or outputImportLibDebugDX11X64 ~= "" or outputImportLibDebugNoXIX64 ~= "" or outputImportLibReleaseWin32 ~= "" or outputImportLibReleaseDX11Win32 ~= "" or outputImportLibReleaseNoXIWin32 ~= "" or outputImportLibReleaseX64 ~= "" or outputImportLibReleaseDX11X64 ~= "" or outputImportLibReleaseNoXIX64 ~= "" or outputImportLibDebugXbox360  ~= "" or outputImportLibDebugPS3 ~= "" or outputImportLibDebugPSP2 ~= "" or outputImportLibDebugWii ~= "" or outputImportLibDebugWiiU ~= "" or outputImportLibReleaseXbox360 ~= "" or outputImportLibReleasePS3 ~= "" or outputImportLibReleasePSP2 ~= "" or outputImportLibReleaseWii ~= ""  or outputImportLibReleaseWiiU ~= "" then
  bUseSpecificImportLibName = true
end
  
if outputFolder == nil or outputFolder == "" then
  bUseSpecificTargetDir = true
end

if outputTarget == nil or outputTarget == "" then
  bUseSpecificTargetName = true
end

if not buildTempDir or buildTempDir == "" then
  buildTempDir = "intermediates"
end

-- Adds intermediates specific folder for the different IDEs
buildTempDir = buildTempDir .. "/" .. projectBaseName .. "/" .. buildSystemSuffix

-- Write the ignoreWii.txt file
writeExcludesTo(excludedSourcesWii, excludedSourcesWiiBaseLocation .. "ignoreWii.txt")

-- Locates the Shared folder relative to the script's location
function GetBaseSharedFolder()
  -- Look for the shared folder location
  globalScriptDir = os.getcwd()
  local iSecurityCounter = 0
  local relativePathToSharedFolder = ""
  while not os.isdir(relativePathToSharedFolder .. "shared/data/base") do
    --os.chdir("..")
    relativePathToSharedFolder = relativePathToSharedFolder .. "../"
    iSecurityCounter = iSecurityCounter + 1
    if iSecurityCounter >= 16 then
      relativePathToSharedFolder = nil
      break
    end
  end

  if iSecurityCounter >= 16 then
    error("\n\n\tERROR!!!!! Shared base folder can not be found.\n\tStarted from:\n\n\t\t" .. globalScriptDir .. "\n\n\tEnded in:\n\n\t\t" .. os.getcwd())
  end
  
  --os.chdir(globalScriptDir) -- Restore the previous path.
  
  return relativePathToSharedFolder .. "shared/"
  
end

PrintVerbose("\t\tUsing Target Specific Directory: " .. iif(bUseSpecificTargetDir, "true", "false"))
PrintVerbose("\t\tUsing Target Specific Name: " .. iif(bUseSpecificTargetName, "true", "false"))

-- Write the platform and config tables as a list.
local flatProjectBuildConfigs = table.flatten( projectBuildConfigs )
local flatbuildConfigsForProject = table.flatten( buildConfigsForProject )
local flatbuildPlatformsForProject = table.flatten( buildPlatformsForProject )
local flatincludeBuildConfigs = table.flatten ( includeBuildConfigs )

projectBuildConfigs = flatProjectBuildConfigs
buildConfigsForProject = flatbuildConfigsForProject
buildPlatformsForProject = flatbuildPlatformsForProject
includeBuildConfigs = flatincludeBuildConfigs

if excludeBuildConfigs then
  local flatexcludeBuildConfigs = table.flatten ( excludeBuildConfigs )
  excludeBuildConfigs = flatexcludeBuildConfigs
end

if buildSystem == "vs2008" or buildSystem == "vs2010" or buildSystem == "vs2012" then
  project ( projectName )
  
    configurations { buildConfigsForProject }
    platforms      { buildPlatformsForProject }
    
    uuid (projectGUID)
    
    -- Nice project name
    if projectNiceName == "" or projectNiceName == nil then
      projectNiceName = projectName
    end
    nicename (projectNiceName)
    
    if projectLocation and projectLocation ~= "" then
      location (projectLocation)
      basedir  (projectLocation)
    else
      location (".")
      basedir (".")
    end
    language (projectLanguage)
    
    -- filter files for wrong entries.
    local finalFiles = {}
    for _,fileEntry in ipairs(sourceFiles) do
      if fileEntry and fileEntry ~= "" then
        table.insert(finalFiles, fileEntry)
      end
    end
    
    files { finalFiles }
    if not bUseSpecificTargetName then
      targetname (outputTarget)
    end
    
    -- Check that the targetname, if not specifying specific output names, doesn't end with the buildSystemSuffix for consoles.
    if (string.endswith(outputTarget, buildSystemSuffix)) then
      outputTargetWithoutBuildSystemSuffix = string.explode(outputTarget, buildSystemSuffix)[1]
      PrintVerbose("\tBase output name for consoles: " .. outputTargetWithoutBuildSystemSuffix)
    else
      outputTargetWithoutBuildSystemSuffix = outputTarget
    end
    
    targetprefix ""
    implibextension ".lib"
    implibprefix ""
    implibsuffix ""
    objdir (buildTempDir)
    VSresculture (culture)
    callingConvention (callConvention)
    
    Xbox360TargetExt = ".xex"

    -- Check if the project contains Release Profile configs
    for _, buildConfig in ipairs(projectBuildConfigs) do
      if string.startswith(buildConfig, "ReleaseP") then
        bUseProfilingConfig = true
        break
      end
    end

    mapBuildConfigurations (mapBuildConfigs)
    projectPossibleBuildableConfigurations ( projectBuildConfigs )  -- Defines which configurations this project can be built for.
    
    if not projectBuildConfigs then
      error("\n\n\tThere is no build configurations defines for the project!!!")
    end
    
    if not includeBuildConfigs then
      error("\n\n\tYou must define which build configurations should be built by defining the includeBuildConfigs variable at least empty...")
    end
    
    local finalBuildConfigs = excludeListFromList(includeBuildConfigs, excludeBuildConfigs)
    
    -- Sanity check to warn the user about trying using a non-existent build configuration for the project
    if includeBuildConfigs then  
      for _, includeValue in ipairs(includeBuildConfigs) do
        local iIdx = 0
        local bFoundValue = false
        for _, value in ipairs(finalBuildConfigs) do
          iIdx = iIdx + 1
          if value == includeValue then
            bFoundValue = true
            break
          end
        end
        
        -- verification
        if not bFoundValue then
          error("\n\n\tbuild configuration TO INCLUDE DOESN'T EXIST IN THE project's build configuration TABLE!!")
        end
        -----
      end
      finalBuildConfigs = includeBuildConfigs
    end
    
    local temp = table.flatten(finalBuildConfigs)
    finalBuildConfigs = temp
    
    PrintVerbose("\t\tBuild Configs:")
    for _, value in ipairs(finalBuildConfigs) do
      PrintVerbose("\t\t\t" .. value)
    end
    
    projectBuildableConfigurations ( finalBuildConfigs )            -- Defines the configurations that should be built for this project
    
    if projectDependencies then
      links { projectDependencies }
    end
    
    if projectReferences ~= "" then
     --links { projectReferences }
     linksReferences { projectReferences }
     flags { "VSUseReferencesInProjects" }  -- General per project flag used to generate the project references in the project file rather than in the solution file.
     
     printf ("\t\tReferences:")
     for _, prjRefName in ipairs(projectReferences) do
      printf ("\t\t\t%s", prjRefName)
     end
    end
        
    if sourcePCH ~= "" then
      printf ("\t\tSource PCH: %s", sourcePCH)
      pchsource (sourcePCH)
    end
    if sourceHeaderPCH ~= "" then
      printf ("\t\tHeader PCH: %s", sourceHeaderPCH)
      pchheader (sourceHeaderPCH)
    end
        
    if not baseSharedFolder then
      PrintVerbose("\t\tLocating base Shared folder...")
      baseSharedFolder = GetBaseSharedFolder()
      PrintVerbose("\t\tLocating base Shared folder... OK -> " .. baseSharedFolder)
    end
    
    if not bUseSpecificImportLibName then
      implibdir (baseSharedFolder .. "lib/" )
    else
      implibdir ("")
    end

    if projectLanguage == "C#" then
      kind (outputTypeWin)
      framework ( iif(buildSystem == "vs2008", "3.5", "4.0" ) )
      icon (projectIcon)
      namespace ( iif(isDeclared(projectNamespace), projectNamespace, outputName) )
      links (libLinkAllWindows)
      if postBuildWin then
        postbuildcommands (postBuildWin)
        postbuilddesc (postBuildDescWin)
      end
      if preBuildWin then
        prebuildcommands (preBuildWin)
        prebuilddesc (preBuildDescWin)
      end
      
      -- puts every resource file into a valid Premake configuration filelist block
      if isDeclared(resourceFiles) then
        local tempConfigurationFileList = ""
        local bSkipFirst = true
        files { resourceFiles }
        for _, file in ipairs(resourceFiles) do
          if bSkipFirst == true then
            tempConfigurationFileList = file
            bSkipFirst = false            
          else
            tempConfigurationFileList = tempConfigurationFileList .. " or " .. file
          end          
        end
        
        configuration { tempConfigurationFileList }
          buildaction ("Embed")
      end
    end
    
    -- Create empty configuration blocks for any of the build configurations we have 
    PrintVerbose("\t\tCreating empty configuration blocks for:")
    for _,cfgBuildPlatform in ipairs(finalBuildConfigs) do
      local explodedEntry = string.explode(cfgBuildPlatform, "|")
      local cfgBuild = explodedEntry[1]
      local cfgPlatform = explodedEntry[2]
      PrintVerbose("\t\t\t" .. cfgBuild .. "|" .. cfgPlatform)
      configuration { "" .. cfgBuild, "" .. cfgPlatform }
      if "true" == "false" then
        flags { "VSUseFullPathPCH" }
      end
    end
    configuration "*" -- Do not forget to always reset the current configuration object.
    ---------------------------------------
    
    -- Specific platforms things ----------
    
    if sourcePCH ~= "" then
      printf ("\t\tSource PCH: %s", sourcePCH)
      pchsource (sourcePCH)
      configuration("Debug* or *Debug or Release* or *Release or ReleaseP*", "x32 or x64 or PS3 or Xbox360 or Durango or Apollo_Arm or Apollo_x32 or Metro_Arm or Metro_x32 or Metro_x64 ")
        pchsource (sourcePCH)
    end
    if sourceHeaderPCH ~= "" then
      printf ("\t\tHeader PCH: %s", sourceHeaderPCH)
      pchheader (sourceHeaderPCH)
      configuration("Debug* or *Debug or Release* or *Release or ReleaseP*", "x32 or x64 or PS3 or Xbox360 or Durango or Apollo_Arm or Apollo_x32 or Metro_Arm or Metro_x32 or Metro_x64")
        pchheader (sourceHeaderPCH)
    end
    
    -- When using Xbox360 + property sheets this parameter is not inherited
    if sourceHeaderPCHXbox360 and sourceHeaderPCHXbox360 ~= "" then
      printf ("\t\tSource Header PCH (Xbox360): %s", sourceHeaderPCHXbox360)
      configuration { "Debug or Release or ReleaseP", "Xbox360" }
        pchheader (sourceHeaderPCHXbox360)
    end
    
    configuration { "Debug or Release or ReleaseP", "Xbox360" }
      XBoxDeploymentHD ("$(XBOX_DEPLOY_ROOT)")

	configuration { "Debug*", "Durango" }
      printf("** DEBUG DURANGO LAYOUT: [%s]\n", layoutFolderDebugDurango)
	  AppxLayoutDir (layoutFolderDebugDurango)
	
	configuration { "Release*", "Durango" }
      AppxLayoutDir (layoutFolderReleaseDurango)
	
	configuration { "Debug*", "Apollo_x32" }
      AppxLayoutDir (layoutFolderDebugApolloX86)
	
	configuration { "Release*", "Apollo_x32" }
      AppxLayoutDir (layoutFolderReleaseApolloX86)
		
    configuration { "Debug*", "Apollo_Arm" }
      AppxLayoutDir (layoutFolderReleaseApolloArm)
	
	configuration { "Release*", "Apollo_Arm" }
      AppxLayoutDir (layoutFolderDebugApolloArm)
	  
	configuration { "Debug*", "Metro_x32" }
      AppxLayoutDir (layoutFolderDebugMetroX86)
	
	configuration { "Release*", "Metro_x32" }
      AppxLayoutDir (layoutFolderReleaseMetroX86)
	  
	configuration { "Debug*", "Metro_x64" }
      AppxLayoutDir (layoutFolderDebugMetroX64)
	
	configuration { "Release*", "Metro_x64" }
      AppxLayoutDir (layoutFolderReleaseMetroX64)
		
    configuration { "Debug*", "Metro_Arm" }
      AppxLayoutDir (layoutFolderReleaseMetroArm)
	
	configuration { "Release*", "Metro_Arm" }
      AppxLayoutDir (layoutFolderDebugMetroArm)
	  
	
    ---------------------------------------

    -- Property sheets --------------------
    if (string.endswith(projectPropertySheet, ".vsprops") or string.endswith(projectPropertySheet, ".props")) then
        PrintVerbose("\t\tProject Property Sheet file: " .. projectPropertySheet)
        propertySheet (projectPropertySheet)
    else
    if projectPropertySheet ~= nil and projectPropertySheet ~= "" then
      PrintVerbose("\t\tProject Property Sheet file: " .. projectPropertySheet)
      configuration { "Debug", "x32" }
        propertySheet (projectPropertySheet .. "DebugWin32" .. buildSystemSuffix .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
      configuration { "Debug DX11", "x32" }
        propertySheet (projectPropertySheet .. "DebugWin32DX11" .. buildSystemSuffix .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
      configuration { "Debug", "x64" }
        propertySheet (projectPropertySheet .. "Debugx64" .. buildSystemSuffix .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
      configuration { "Debug DX11", "x64" }
        propertySheet (projectPropertySheet .. "Debugx64DX11" .. buildSystemSuffix .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
      configuration { "Debug", "PS3" }
        propertySheet (projectPropertySheet .. "DebugPS3" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
      configuration { "Debug", "PSVita" }
        propertySheet (projectPropertySheet .. "DebugPSP2" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
      configuration { "Debug", "Xbox360" }
        propertySheet (projectPropertySheet .. "DebugXbox360" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
		configuration { "Debug DX11", "Durango" }
          propertySheet (projectPropertySheet .. "DebugDurango" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
		configuration { "Debug DX11", "Apollo_Arm" }
          propertySheet (projectPropertySheet .. "DebugApolloArm" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
		configuration { "Debug DX11", "Apollo_x32" }
          propertySheet (projectPropertySheet .. "DebugApolloX86" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
		configuration { "Debug DX11", "Metro_x32" }
          propertySheet (projectPropertySheet .. "DebugMetroX86" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
	
		configuration { "Debug DX11", "Metro_x64" }
          propertySheet (projectPropertySheet .. "DebugMetroX64" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )

        configuration { "Debug DX11", "Metro_Arm" }
          propertySheet (projectPropertySheet .. "DebugMetroArm" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
 
       
      configuration { "Release", "x32" }
        propertySheet (projectPropertySheet .. "ReleaseWin32" .. buildSystemSuffix .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
      configuration { "Release DX11", "x32" }
        propertySheet (projectPropertySheet .. "ReleaseWin32DX11" .. buildSystemSuffix .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
      configuration { "Release", "x64" }
        propertySheet (projectPropertySheet .. "Releasex64" .. buildSystemSuffix .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
      configuration { "Release DX11", "x64" }
        propertySheet (projectPropertySheet .. "Releasex64DX11" .. buildSystemSuffix .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
      configuration { "Release", "PS3" }
        propertySheet (projectPropertySheet .. "ReleasePS3" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
      configuration { "Release", "PSVita" }
        propertySheet (projectPropertySheet .. "ReleasePSP2" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
      configuration { "Release", "Xbox360" }
        propertySheet (projectPropertySheet .. "ReleaseXbox360" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )

		configuration { "Release DX11", "Durango" }
          propertySheet (projectPropertySheet .. "ReleaseDurango" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
		configuration { "Release DX11", "Apollo_Arm" }
          propertySheet (projectPropertySheet .. "ReleaseApolloArm" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
		configuration { "Release DX11", "Apollo_x32" }
          propertySheet (projectPropertySheet .. "ReleaseApolloX86" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
        
		configuration { "Release DX11", "Metro_x32" }
          propertySheet (projectPropertySheet .. "ReleaseMetroX86" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
	
		configuration { "Release DX11", "Metro_x64" }
          propertySheet (projectPropertySheet .. "ReleaseMetroX64" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )

        configuration { "Release DX11", "Metro_Arm" }
          propertySheet (projectPropertySheet .. "ReleaseMetroArm" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )

        configuration { "Debug", "Cafe" }
          propertySheet (projectPropertySheet .. "DebugCafe" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
          
        configuration { "Release", "Cafe" }
          propertySheet (projectPropertySheet .. "ReleaseCafe" .. iif(buildSystemSuffix == "90", ".vsprops", ".props") )
      end
    end
    ---------------------------------------

    PrintVerbose("\t\tExcluding files...")
    -- Exclude files & specific file configuration ----------------------------------------------------------
    configuration { "Debug or Debug DX11 or Release or Release DX11 or ReleaseP or ReleaseP DX11", "x32 or x64 or any" }
      excludes (excludedSourcesWindows)
      nopchfile { sourcesNotUsingPCH }
      custombuildtool {
         "../../ThirdParty/tinyXML/**.h*"
      }
      
    configuration { "Debug NoXI or Release NoXI", "x32 or x64 or any" }
      excludes (excludedSourcesWindowsNoXI)
      nopchfile { sourcesNotUsingPCH }
      custombuildtool {
         "../../ThirdParty/tinyXML/**.h*"
      }
    
    configuration { "Static*", "x32 or x64 or any" }
      excludes (excludedSourcesWindows)
      nopchfile { sourcesNotUsingPCH }
      custombuildtool {
         "../../ThirdParty/tinyXML/**.h*"
      }
         
    configuration { "Debug or Release or ReleaseP", "Xbox360" }
      excludes (excludedSourcesXbox360)
      nopchfile { sourcesNotUsingPCH }
      custombuildtool {
         "../../ThirdParty/tinyXML/**.h*"
      }
          
    configuration { "Debug* or Release*", "Durango" }
      excludes (excludedSourcesDurango)
      nopchfile { sourcesNotUsingPCH }
      custombuildtool {
         "../../ThirdParty/tinyXML/**.h*"
      }

	configuration { "Debug* or Release*", "Apollo_Arm" }
      excludes (excludedSourcesApolloArm)
      nopchfile { sourcesNotUsingPCH }
      custombuildtool {
         "../../ThirdParty/tinyXML/**.h*"
      }

	configuration { "Debug* or Release*", "Apollo_x32" }
      excludes (excludedSourcesApolloX86)
      nopchfile { sourcesNotUsingPCH }
      custombuildtool {
         "../../ThirdParty/tinyXML/**.h*"
      }

	  
	configuration { "Debug* or Release*", "Metro_Arm" }
      excludes (excludedSourcesMetroArm)
      nopchfile { sourcesNotUsingPCH }
      custombuildtool {
         "../../ThirdParty/tinyXML/**.h*"
      }

	configuration { "Debug* or Release*", "Metro_x32" }
      excludes (excludedSourcesMetroX86)
      nopchfile { sourcesNotUsingPCH }
      custombuildtool {
         "../../ThirdParty/tinyXML/**.h*"
      }

	configuration { "Debug* or Release*", "Metro_x64" }
      excludes (excludedSourcesMetroX64)
      nopchfile { sourcesNotUsingPCH }
      custombuildtool {
         "../../ThirdParty/tinyXML/**.h*"
      }

    configuration { "Debug or Release or ReleaseP", "PS3" }
      excludes (excludedSourcesPS3)
      nopchfile { sourcesNotUsingPCH }
      custombuildtool {
         "../../ThirdParty/tinyXML/**.h*"
      }

    configuration { "Debug or Release or ReleaseP", "PSVita" }
      excludes (excludedSourcesPSP2)
      nopchfile { sourcesNotUsingPCH }
      custombuildtool {
         "../../ThirdParty/tinyXML/**.h*"
      }
      
    configuration { "Debug or Release or ReleaseP", "Cafe" }
      excludes (excludedSourcesWiiU)
      nopchfile { sourcesNotUsingPCH }
      custombuildtool {
         "../../ThirdParty/tinyXML/**.h*"
      }
    ---------------------------------------------------------------------------------------------------------
    
    -- CustomBuildTool -----------------------------------------------------------------------------------
    if fileCustomBuildTool then
      for files,customBuildTool in pairs(fileCustomBuildTool) do
        configuration { files }
          custombuildcommandline (customBuildTool["CommandLine"])
          custombuildcommandlineOutput (customBuildTool["Outputs"])
          custombuildcommandlineDepends (customBuildTool["Dependencies"])
      end
    end
    ---------------------------------------------------------------------------------------------------------
    
    PrintVerbose("\t\tGeneral defines...")
    -- General defines -------------------------------------------------------------------------------------
    configuration "*Debug*"    defines { definesDebug     }  resdefines { definesDebug }   -- For: any Debug configuration
    configuration "*Release*"  defines { definesRelease   }  resdefines { definesRelease }   -- For: any Release configuration
    configuration { "Debug or Release or ReleaseP or *DX11 or *NoXI or *Debug or *Release", "x64" }  defines { definesX64 }                                -- For: any x64 configuration
    configuration { "Debug or Release or ReleaseP or *DX11 or *NoXI or *Debug or *Release", "x32" }  defines { definesX86 }   -- For: Windows platforms
    configuration { "ReleaseP*" } defines { "PROFILING" }
        
    PrintVerbose("\t\tInclude dirs...")
    -- Include dirs -----------------------------------------------------------------------------------------
    configuration { "Debug or Release or ReleaseP or *DX11 or *NoXI or *Debug or *Release", "x32"  } includedirs (includeDirsWin32)
    configuration { "Debug or Release or ReleaseP or *DX11 or *NoXI or *Debug or *Release", "x64"  } includedirs (includeDirsX64)
    configuration { "Debug or Release or ReleaseP", "Xbox360"                                      } includedirs (includeDirsXbox360)
    configuration { "Debug or Release or ReleaseP", "PS3"                                          } includedirs (includeDirsPS3)
    configuration { "Debug or Release or ReleaseP", "PSVita"                                       } includedirs (includeDirsPSP2)
    configuration { "Debug or Release or ReleaseP", "Cafe"                                         } includedirs (includeDirsWiiU)
    configuration { "*DX11", "Durango"                                                             } includedirs (includeDirsDurango)
    configuration { "*DX11", "Apollo_Arm"                                                          } includedirs (includeDirsApolloArm)
    configuration { "*DX11", "Apollo_x32"                                                          } includedirs (includeDirsApolloX86)
    configuration { "*DX11", "Metro_Arm"                                                           } includedirs (includeDirsMetroArm)
    configuration { "*DX11", "Metro_x32"                                                           } includedirs (includeDirsMetroX86)
    configuration { "*DX11", "Metro_x64"                                                           } includedirs (includeDirsMetroX64)
    if includePathResCompilerWindows ~= "" then
      configuration { "x32 or x64 or PS3 or PSVita" } resincludedirs (includePathResCompilerWindows)
    end
    ---------------------------------------------------------------------------------------------------------

    PrintVerbose("\t\tLib dirs...")
    -- Lib dirs   -------------------------------------------------------------------------------------------
    configuration { "Debug or Release or ReleaseP or *DX11 or *NoXI", "x32" } libdirs (libDirsWin32)
    configuration { "StaticLib*", "x32"                                     } libdirs (libDirsStaticWin32)
    configuration { "Debug or Release or ReleaseP or *DX11 or *NoXI", "x64" } libdirs (libDirsX64)
    configuration { "StaticLib*", "x64"                                     } libdirs (libDirsStaticX64)
    
    configuration { "Debug or Debug DX11 or Debug NoXI", "x32"     } libdirs (libDirsDebugWin32)
    configuration { "Release or Release DX11 or Release NoXI", "x32" } libdirs (libDirsReleaseWin32)
    
    configuration { "Debug or Debug DX11 or Debug NoXI", "x64"     } libdirs (libDirsDebugX64)
    configuration { "Release or Release DX11 or Release NoXI", "x64" } libdirs (libDirsReleaseX64)    
    
    configuration { "Debug or Release or ReleaseP", "Xbox360" } libdirs (libDirsXbox360)
    configuration { "Debug or Release or ReleaseP", "PS3"     } libdirs (libDirsPS3)
    configuration { "Debug or Release or ReleaseP", "PSVita"  } libdirs (libDirsPSP2)
    configuration { "Debug or Release or ReleaseP", "Cafe"    } libdirs (libDirsWiiU)
    configuration { "*DX11", "Durango"    } libdirs (libDirsDurango)
    configuration { "*DX11", "Apollo_Arm" } libdirs (libDirsApolloArm)
    configuration { "*DX11", "Apollo_x32" } libdirs (libDirsApolloX86)
    configuration { "*DX11", "Metro_x32"  } libdirs (libDirsMetroX86)
    configuration { "*DX11", "Metro_x64"  } libdirs (libDirsMetroX64)
    configuration { "*DX11", "Metro_Arm"  } libdirs (libDirsMetroArm)
    
    configuration { "Release or ReleaseP", "Xbox360"      } libdirs (libDirsReleaseXbox360)
    configuration { "Release or ReleaseP", "PS3"  } libdirs (libDirsReleasePS3)
    configuration { "Release or ReleaseP", "PSVita"} libdirs (libDirsReleasePSP2)
    configuration { "Release or ReleaseP", "Cafe"} libdirs (libDirsReleaseWiiU)
    configuration { "Release*", "Durango" } libdirs (libDirsReleaseDurango)
    configuration { "Release*", "Apollo_Arm" } libdirs (libDirsReleaseApolloArm)
    configuration { "Release*", "Apollo_x32" } libdirs (libDirsReleaseApolloX86)
    configuration { "Release*", "Metro_x32" } libdirs (libDirsReleaseMetroX86)
    configuration { "Release*", "Metro_x64" } libdirs (libDirsReleaseMetroX64)
    configuration { "Release*", "Metro_Arm" } libdirs (libDirsReleaseMetroArm)
    
    configuration { "Debug", "Xbox360"  } libdirs (libDirsDebugXbox360)
    configuration { "Debug", "PS3"      } libdirs (libDirsDebugPS3)
    configuration { "Debug", "PSVita"   } libdirs (libDirsDebugPSP2)    
    configuration { "Debug", "Cafe"     } libdirs (libDirsDebugWiiU)
    configuration { "Debug*", "Durango" } libdirs (libDirsDebugDurango)
    configuration { "Debug*", "Apollo_Arm" } libdirs (libDirsDebugApolloArm)
    configuration { "Debug*", "Apollo_x32" } libdirs (libDirsDebugApolloX86)
    configuration { "Debug*", "Metro_x32" } libdirs (libDirsDebugMetroX86)
    configuration { "Debug*", "Metro_x64" } libdirs (libDirsDebugMetroX64)
    configuration { "Debug*", "Metro_Arm" } libdirs (libDirsDebugMetroArm)
    ---------------------------------------------------------------------------------------------------------

    PrintVerbose("\t\tLink libs...")
    -- Link libs  -------------------------------------------------------------------------------------------
    -- FIXME The isDeclared calls is only to avoid declare the used variables in every script. It should be later
    --      modified in the Globals.lua to be declared global and empty.
    configuration { "StaticLib Debug",    "x32" } links (libLinkDebugStaticWin32)
    if isDeclared(libLinkDebugStaticMTWin32) then
      configuration { "StaticLib MT Debug", "x32" } links (libLinkDebugStaticMTWin32)
    end
    configuration { "Debug",              "x32" } links (libLinkDebugDx9Win32)
    configuration { "Debug DX11",         "x32" } links (libLinkDebugDx11Win32)
    configuration { "Debug NoXI",         "x32" } links (libLinkDebugNoXIWin32)

    configuration { "StaticLib Release",              "x32" } links (libLinkReleaseStaticWin32)
    if isDeclared(libLinkReleaseStaticMTWin32) then
      configuration { "StaticLib MT Release",           "x32" } links (libLinkReleaseStaticMTWin32)
    end
    
    if isDeclared(libLinkReleasePAllWin) then
      configuration { "ReleaseP or ReleaseP DX11", "x32 or x64" } links (libLinkReleasePAllWin)
    end
    configuration { "Release or ReleaseP",            "x32" } links (libLinkReleaseDx9Win32)
    configuration { "Release DX11 or ReleaseP DX11",  "x32" } links (libLinkReleaseDx11Win32)
    configuration { "Release NoXI",                   "x32" } links (libLinkReleaseNoXIWin32)

    configuration { "StaticLib Debug",    "x64" } links (libLinkDebugStaticX64)
    if isDeclared(libLinkDebugStaticMTX64) then
      configuration { "StaticLib MT Debug", "x64" } links (libLinkDebugStaticMTX64)
    end
    configuration { "Debug",              "x64" } links (libLinkDebugDx9x64)
    configuration { "Debug DX11",         "x64" } links (libLinkDebugDx11x64)
    configuration { "Debug NoXI",         "x64" } links (libLinkDebugNoXIx64)

    configuration { "StaticLib Release",              "x64" } links (libLinkReleaseStaticX64)
    if isDeclared(libLinkReleaseStaticMTX64) then
      configuration { "StaticLib MT Release",           "x64" } links (libLinkReleaseStaticMTX64)
    end
    configuration { "Release or ReleaseP",            "x64" } links (libLinkReleaseDx9x64)
    configuration { "Release DX11 or ReleaseP DX11",  "x64" } links (libLinkReleaseDx11x64)
    configuration { "Release NoXI",                   "x64" } links (libLinkReleaseNoXIx64)

    configuration { "Debug",                "Xbox360" } links (libLinkDebugXbox360)
    configuration { "Release or ReleaseP",  "Xbox360" } links (libLinkReleaseXbox360)

    configuration { "Debug",                "PS3" } links (libLinkDebugPS3)
    configuration { "Release or ReleaseP",  "PS3" } links (libLinkReleasePS3)

    configuration { "Debug",                "PSVita" } links (libLinkDebugPSP2)
    configuration { "Release or ReleaseP",  "PSVita" } links (libLinkReleasePSP2)

    configuration { "Debug",                "Cafe" } links (libLinkDebugWiiU)
    configuration { "Release or ReleaseP",  "Cafe" } links (libLinkReleaseWiiU)
   
    configuration { "Debug*",                "Durango" } links (libLinkDebugDurango)
    configuration { "Release*",  "Durango" } links (libLinkReleaseDurango)

    configuration { "Debug*",                "Apollo_x32" } links (libLinkDebugApolloX86)
    configuration { "Release*",  "Apollo_x32" } links (libLinkReleaseApolloX86)

	  configuration { "Debug*",                "Apollo_Arm" } links (libLinkDebugApolloArm)
    configuration { "Release*",  "Apollo_Arm" } links (libLinkReleaseApolloArm)

	  configuration { "Debug*",                "Metro_x32" } links (libLinkDebugMetroX86)
    configuration { "Release*",  "Metro_x32" } links (libLinkReleaseMetroX86)

	  configuration { "Debug*",                "Metro_Arm" } links (libLinkDebugMetroArm)
    configuration { "Release*",  "Metro_Arm" } links (libLinkReleaseMetroArm)

	  configuration { "Debug*",                "Metro_x64" } links (libLinkDebugMetroX64)
    configuration { "Release*",  "Metro_x64" } links (libLinkReleaseMetroX64)
    ---------------------------------------------------------------------------------------------------------
     
    PrintVerbose("\t\tOutput names...")
    -- Output names -----------------------------------------------------------------------------------------
    if  bUseSpecificTargetName then
      configuration { "Debug", "x32"              } targetname (outputTargetDebugWin32)
      configuration { "Debug DX11", "x32"         } targetname (outputTargetDebugDX11Win32)
      configuration { "Debug NoXI", "x32"         } targetname (outputTargetDebugNoXIWin32)
      configuration { "StaticLib Debug", "x32"    } targetname (outputTargetDebugStaticWin32)
      configuration { "StaticLib MT Debug", "x32" } targetname (outputTargetDebugStaticMTWin32)
      
      configuration { "Debug", "x64"              } targetname (outputTargetDebugX64)
      configuration { "Debug DX11", "x64"         } targetname (outputTargetDebugDX11X64)
      configuration { "Debug NoXI", "x64"         } targetname (outputTargetDebugNoXIX64)
      configuration { "StaticLib Debug", "x64"    } targetname (outputTargetDebugStaticX64)
      configuration { "StaticLib MT Debug", "x64" } targetname (outputTargetDebugStaticMTX64)
      
      configuration { "Release or ReleaseP",           "x32" } targetname (outputTargetReleaseWin32)
      configuration { "Release DX11 or ReleaseP DX11", "x32" } targetname (outputTargetReleaseDX11Win32)
      configuration { "Release NoXI", "x32"         } targetname (outputTargetReleaseNoXIWin32)
      configuration { "StaticLib Release", "x32"    } targetname (outputTargetReleaseStaticWin32)
      configuration { "StaticLib MT Release", "x32" } targetname (outputTargetReleaseStaticMTWin32)
      
      configuration { "Release or ReleaseP",           "x64" } targetname (outputTargetReleaseX64)
      configuration { "Release DX11 or ReleaseP DX11", "x64" } targetname (outputTargetReleaseDX11X64)
      configuration { "Release NoXI", "x64"         } targetname (outputTargetReleaseNoXIX64)
      configuration { "StaticLib Release", "x64"    } targetname (outputTargetReleaseStaticX64)
      configuration { "StaticLib MT Release", "x64" } targetname (outputTargetReleaseStaticMTX64)
      
      configuration { "Debug", "Xbox360"    }
        targetname (outputTargetDebugXbox360)
        imagepath(iif(bUseSpecificTargetDir, outputFolderDebugXbox360, outputFolder .. iif(outputTypeXbox360 == "StaticLib", "lib", "binxbox360d\\")) .. outputTargetDebugXbox360  .. "D" .. Xbox360TargetExt)        
        
      configuration { "Release", "Xbox360"  }
        targetname (outputTargetReleaseXbox360)
        imagepath(iif(bUseSpecificTargetDir, outputFolderReleaseXbox360, outputFolder .. iif(outputTypeXbox360 == "StaticLib", "lib", "binxbox360\\")) .. iif( bUseProfilingConfig, "/builds/release/", "/" ) .. outputTargetReleaseXbox360 .. Xbox360TargetExt)

      configuration { "ReleaseP", "Xbox360"  }
        targetname (outputTargetReleaseXbox360)
        imagepath(iif(bUseSpecificTargetDir, outputFolderReleaseXbox360 .. "/profiling/", outputFolder .. iif(outputTypeXbox360 == "StaticLib", "lib", "binxbox360\\")) .. iif( bUseProfilingConfig, "/builds/profiling/", "/" ) .. outputTargetReleaseXbox360 .. Xbox360TargetExt)
      
      configuration { "Debug",               "PS3" } targetname (outputTargetDebugPS3)
      configuration { "Release or ReleaseP", "PS3" } targetname (outputTargetReleasePS3)
      
      configuration { "Debug",                "PSVita"  } targetname (outputTargetDebugPSP2)
      configuration { "Release or ReleaseP",  "PSVita"  } targetname (outputTargetReleasePSP2)
      
      configuration { "Debug Wii",                    "x32" } targetname (outputTargetDebugWii)
      configuration { "Release Wii or ReleaseP Wii",  "x32" } targetname (outputTargetReleaseWii)
      
      configuration { "Debug",                "Cafe" } targetname (outputTargetDebugWiiU)
      configuration { "Release or ReleaseP",  "Cafe" } targetname (outputTargetReleaseWiiU)

  	  configuration { "Debug*",    "Durango"  } targetname (outputTargetDebugDurango)
      configuration { "Release*",  "Durango"  } targetname (outputTargetReleaseDurango)
      
	    configuration { "Debug*",    "Apollo_x32"  } targetname (outputTargetDebugApolloX86)
      configuration { "Release*",  "Apollo_x32"  } targetname (outputTargetReleaseApolloX86)
      
	    configuration { "Debug*",    "Apollo_Arm"  } targetname (outputTargetDebugApolloArm)
      configuration { "Release*",  "Apollo_Arm"  } targetname (outputTargetReleaseApolloArm)
      
	    configuration { "Debug*",    "Metro_x32"  } targetname (outputTargetDebugMetroX86)
      configuration { "Release*",  "Metro_x32"  } targetname (outputTargetReleaseMetroX86)
      
	    configuration { "Debug*",    "Metro_x64"  } targetname (outputTargetDebugMetroX64)
      configuration { "Release*",  "Metro_x64"  } targetname (outputTargetReleaseMetroX64)
      
	    configuration { "Debug*",    "Metro_Arm"  } targetname (outputTargetDebugMetroArm)
      configuration { "Release*",  "Metro_Arm"  } targetname (outputTargetReleaseMetroArm)

    else
      configuration { "Debug", "Xbox360" }
        targetname (outputTargetWithoutBuildSystemSuffix .. iif(outputTypeXbox360 == "StaticLib", "Xe", "" ))
        imagepath (iif(bUseSpecificTargetDir, outputFolderDebugXbox360, outputFolder .. iif(outputTypeXbox360 == "StaticLib", "lib/", "binxbox360d/")) .. outputTargetWithoutBuildSystemSuffix .. iif(outputTypeXbox360 == "StaticLib", "Xe", "" )  .. "D" .. Xbox360TargetExt)
        
      configuration { "Release", "Xbox360" }
        targetname (outputTargetWithoutBuildSystemSuffix .. iif(outputTypeXbox360 == "StaticLib", "Xe", "" ))
        imagepath (iif(bUseSpecificTargetDir, outputFolderReleaseXbox360, outputFolder .. iif(outputTypeXbox360 == "StaticLib", "lib/", "binxbox360/")) .. iif( bUseProfilingConfig, "/builds/release/", "/" ) .. outputTargetWithoutBuildSystemSuffix .. iif(outputTypeXbox360 == "StaticLib", "Xe", "" ) .. Xbox360TargetExt)
        
      configuration { "ReleaseP", "Xbox360" }
        targetname (outputTargetWithoutBuildSystemSuffix .. iif(outputTypeXbox360 == "StaticLib", "Xe", "" ))
        imagepath (iif(bUseSpecificTargetDir, outputFolderReleaseXbox360 .. "/profiling/", outputFolder .. iif(outputTypeXbox360 == "StaticLib", "lib/", "binxbox360/")) .. iif( bUseProfilingConfig, "/builds/profiling/", "/" ) .. outputTargetWithoutBuildSystemSuffix .. iif(outputTypeXbox360 == "StaticLib", "Xe", "" ) .. Xbox360TargetExt)
        
      configuration { "PS3" }
        targetname (outputTargetWithoutBuildSystemSuffix .. iif(outputTypePS3 == "StaticLib", iif(not bIsSPU, "PS3", "") , ""))
        toolset (iif(bIsSPU, "SPU", "SNC"))
        fileservingPS3("$(ProjectDir)" .. GetBaseSharedFolder() .. "..")
        homedirPS3("$(ProjectDir)" .. GetBaseSharedFolder() .. "..")
        
      configuration { "PSVita"      } targetname (outputTargetWithoutBuildSystemSuffix .. iif(outputTypePSP2 == "StaticLib", "PSP2", "")) 
      configuration { "*Wii", "x32" } targetname (outputTargetWithoutBuildSystemSuffix .. iif(outputTypeWii == "StaticLib", "Wii", ""))

      configuration { "Cafe"    } targetname (outputTargetWithoutBuildSystemSuffix .. iif(outputTypeWiiU == "StaticLib", "WiiU", ""))

  	  configuration { "Durango"      } targetname (outputTargetWithoutBuildSystemSuffix .. iif(outputTypeDurango == "StaticLib", "Durango", "")) 
  	  configuration { "Apollo_x32"      } targetname (outputTargetWithoutBuildSystemSuffix .. iif(outputTypeApolloX86 == "StaticLib", "ApolloX86", "")) 
  	  configuration { "Apollo_Arm"      } targetname (outputTargetWithoutBuildSystemSuffix .. iif(outputTypeApolloArm == "StaticLib", "ApolloArm", "")) 
  	  configuration { "Metro_x64"      } targetname (outputTargetWithoutBuildSystemSuffix .. iif(outputTypeMetroArm == "StaticLib", "MetroX64", "")) 
  	  configuration { "Metro_x32"      } targetname (outputTargetWithoutBuildSystemSuffix .. iif(outputTypeMetroX86 == "StaticLib", "MetroX86", "")) 
  	  configuration { "Metro_Arm"      } targetname (outputTargetWithoutBuildSystemSuffix .. iif(outputTypeMetroArm == "StaticLib", "MetroArm", "")) 
    
    end
    
    configuration { "PS3" }
      toolset (iif(bIsSPU, "SPU", "SNC"))
      fileservingPS3("$(ProjectDir)" .. GetBaseSharedFolder() .. "..")
      homedirPS3("$(ProjectDir)" .. GetBaseSharedFolder() .. "..")
        
    if not bUseSpecificImportLibName then
      configuration { "x64" } implibdir (baseSharedFolder .. "lib/x64/")
      configuration { "*NoXI", "x32" } implibdir (baseSharedFolder .. "lib/builds/noXInput/")
      configuration { "*NoXI", "x64" } implibdir (baseSharedFolder .. "lib/x64/builds/noXInput/")
    end
    
    -- Release(P) specific output dirs
    if not bUseSpecificImportLibName then
      configuration { "ReleaseP*", "x32 or Xbox360" } implibdir (baseSharedFolder .. "lib/builds/profiling/")
      configuration { "ReleaseP*", "x64" } implibdir (baseSharedFolder .. "lib/x64/builds/profiling/")
      if bUseProfilingConfig then
        configuration { "Release or Release DX11 or Release Wii", "x32 or Xbox360 or PS3 or PSVita or Cafe or Durango or Apollo_Arm or Apollo_x32 or Metro_Arm or Metro_x32 or Metro_x64" } implibdir (baseSharedFolder .. "lib/builds/release/")
        configuration { "Release or Release DX11", "x64" } implibdir (baseSharedFolder .. "lib/x64/builds/release/")
      end
    end
    ---------------------------------------------------------------------------------------------------------

    PrintVerbose("\t\tTarget and import lib dirs...")
    
    -- Import Library name -----------
    configuration { "Debug* or Release* or StaticLib*", "x32 or x64 or PS3 or PSVita or Durango or Apollo_Arm or Apollo_x32 or Metro_Arm or Metro_x32 or Metro_x64" } 
    
    if not bUseSpecificImportLibName then
      if bUseSpecificTargetName or bIsEnginePlugin then
        implibname ("/$(TargetName)" .. buildSystemSuffix)
      else
        implibname ("/$(TargetName)")
      end
    else
      -- Windows ---------------------
      configuration { "Debug", "x32" }
        implibname (outputImportLibDebugWin32)
        
      configuration { "Debug DX11", "x32" }
        implibname (outputImportLibDebugDX11Win32)
        
      configuration { "Debug NoXI", "x32" }
        implibname (outputImportLibDebugNoXIWin32)
      
      configuration { "Debug", "x64" }
        implibname (outputImportLibDebugX64)
        
      configuration { "Debug DX11", "x64" }
        implibname (outputImportLibDebugDX11X64)
        
      configuration { "Debug NoXI", "x64" }
        implibname (outputImportLibDebugNoXIX64)
      
      configuration { "Release", "x32" }
        implibname (outputImportLibReleaseWin32)
        
      configuration { "Release DX11", "x32" }
        implibname (outputImportLibReleaseDX11Win32)
        
      configuration { "Release NoXI", "x32" }
        implibname (outputImportLibReleaseNoXIWin32)
      
      configuration { "Release", "x64" }
        implibname (outputImportLibReleaseX64)
        
      configuration { "Release DX11", "x64" }
        implibname (outputImportLibReleaseDX11X64)
        
      configuration { "Release NoXI", "x64" }
        implibname (outputImportLibReleaseNoXIX64)
        
      -- Consoles ------------------------
      configuration { "Debug", "Xbox360" }
        implibname (outputImportLibDebugXbox360)
        
      configuration { "Debug", "PS3" }
        implibname (outputImportLibDebugPS3)
        
      configuration { "Debug", "PSVita" }
        implibname (outputImportLibDebugPSP2)
        
      configuration { "Debug Wii", "x32" }
        implibname (outputImportLibDebugWii)

      configuration { "Debug*", "Durango" }
        implibname (outputImportLibDebugDurango)
      
   	  configuration { "Debug*", "Apollo_Arm" }
         implibname (outputImportLibDebugApolloArm)
         
   	  configuration { "Debug*", "Apollo_x32" }
         implibname (outputImportLibDebugApolloX86)
         
   	  configuration { "Debug*", "Metro_x32" }
         implibname (outputImportLibDebugMetroX86)
         
   	  configuration { "Debug*", "Metro_x64" }
         implibname (outputImportLibDebugMetroX64)
         
   	  configuration { "Debug*", "Metro_Arm" }
         implibname (outputImportLibDebugMetroArm)
        
      configuration { "Debug", "Cafe" }
        implibname (outputImportLibDebugWiiU)
        
      configuration { "Release", "Xbox360" }
        implibname (outputImportLibReleaseXbox360)
        
      configuration { "Release", "PS3" }
        implibname (outputImportLibReleasePS3)
        
      configuration { "Release", "PSVita" }
        implibname (outputImportLibReleasePSP2)
        
      configuration { "Release Wii", "x32" }
        implibname (outputImportLibReleaseWii)

      configuration { "Release", "Cafe" }
        implibname (outputImportLibReleaseWiiU)

   	  configuration { "Release*", "Durango" }
        implibname (outputImportLibReleaseDurango)
         
   	  configuration { "Release*", "Apollo_Arm" }
        implibname (outputImportLibReleaseApolloArm)
         
   	  configuration { "Release*", "Apollo_x32" }
        implibname (outputImportLibReleaseApolloX86)
         
   	  configuration { "Release*", "Metro_x32" }
        implibname (outputImportLibReleaseMetroX86)
         
   	  configuration { "Release*", "Metro_x64" }
        implibname (outputImportLibReleaseMetroX64)
         
   	  configuration { "Release*", "Metro_Arm" }
        implibname (outputImportLibReleaseMetroArm)
    
    end


    if not bUseSpecificTargetName or bIsEnginePlugin then
      configuration { "*Debug*", "x32 or x64" }
        targetsuffix (iif(bIsEnginePlugin, "", "D")) -- Windows engine plugins follows a naming that should not add the target suffix. The target suffix gets added after the extension ( .vplugin(D) )
        implibsuffix (iif(not bIsEnginePlugin or bUseSpecificImportLibName, "", "D"))
        
      configuration { "*Release*", "x32 or x64" }
        targetsuffix ("")
        implibsuffix ("")
        
      configuration { "Debug DX11", "x32 or x64" }
        targetsuffix (iif(bIsEnginePlugin, "", "DX11D"))
        implibsuffix (iif(not bIsEnginePlugin or bUseSpecificImportLibName, "", "DX11D"))
        
      configuration { "Release DX11 or ReleaseP DX11", "x32 or x64" }
        targetsuffix (iif(bIsEnginePlugin, "", "DX11"))
        implibsuffix (iif(not bIsEnginePlugin or bUseSpecificImportLibName, "", "DX11"))
        
      configuration { "Debug", "Xbox360" }
        targetsuffix (iif(bIsEnginePlugin and bUseSpecificTargetName, "", "D"))
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "XeD"))
        
      configuration { "Release or ReleaseP", "Xbox360" }
        targetsuffix ("")
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "Xe"))
        
      configuration { "Debug", "PS3" }
        targetsuffix (iif(bIsEnginePlugin and bUseSpecificTargetName, "", "D"))
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "PS3D"))
        
      configuration { "Release or ReleaseP", "PS3" }
        targetsuffix ("")
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "PS3"))
        
      configuration { "Debug", "PSVita" }
        targetsuffix (iif(bIsEnginePlugin and bUseSpecificTargetName, "", "D"))
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "PSP2D"))
        
      configuration { "Release or ReleaseP", "PSVita" }
        targetsuffix ("")
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "PSP2"))
        
      configuration { "Debug Wii", "x32" }
        targetsuffix (iif(bIsEnginePlugin and bUseSpecificTargetName, "", "D"))
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "WiiD"))
        
      configuration { "Debug", "Cafe" }
        targetsuffix (iif(bIsEnginePlugin and bUseSpecificTargetName, "", "D"))
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "WiiUD"))
        
      configuration { "Release or ReleaseP", "Cafe" }
        targetsuffix ("")
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "WiiU"))

	    configuration { "Debug*", "Durango" }
        targetsuffix (iif(bIsEnginePlugin and bUseSpecificTargetName, "", "D"))
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "DURANGOD"))
        
      configuration { "Release*", "Durango" }
        targetsuffix ("")
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "DURANGO"))
     
	    configuration { "Debug*", "Apollo_Arm or Apollo_x32" }
        targetsuffix (iif(bIsEnginePlugin and bUseSpecificTargetName, "", "D"))
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "APOLLOD"))
        
      configuration { "Release*", "Apollo_Arm or Apollo_x32" }
        targetsuffix ("")
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "APOLLO"))

      configuration { "Debug*", "Metro_Arm or Metro_x32 or Metro_x64" }
        targetsuffix (iif(bIsEnginePlugin and bUseSpecificTargetName, "", "D"))
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "METROD"))
        
      configuration { "Release Wii or ReleaseP Wii", "x32" }
        targetsuffix ("")
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "Wii"))
        
      configuration { "Release*", "Metro_Arm or Metro_x32 or Metro_x64" }
        targetsuffix ("")
        implibsuffix (iif(bIsEnginePlugin or bUseSpecificImportLibName, "", "METRO"))
      
      configuration { "StaticLib Debug", "x32 or x64" }
        targetsuffix (iif(bIsEnginePlugin and bUseSpecificTargetName, "", "SD"))
        implibsuffix (iif(not bIsEnginePlugin or bUseSpecificImportLibName, "", "SD"))
      
      configuration { "StaticLib MT Debug", "x32 or x64" }
        targetsuffix (iif(bIsEnginePlugin and bUseSpecificTargetName, "", "SMTD"))
        implibsuffix (iif(not bIsEnginePlugin or bUseSpecificImportLibName, "", "SMTD"))
        
      configuration { "StaticLib Release", "x32 or x64" }
        targetsuffix (iif(bIsEnginePlugin and bUseSpecificTargetName, "", "S"))
        implibsuffix (iif(not bIsEnginePlugin or bUseSpecificImportLibName, "", "S"))
      
      configuration { "StaticLib MT Release", "x32 or x64" }
        targetsuffix (iif(bIsEnginePlugin and bUseSpecificTargetName, "", "SMT"))
        implibsuffix (iif(not bIsEnginePlugin or bUseSpecificImportLibName, "", "SMT"))
    end
      
    if projectLanguage == "C#" then
      configuration { "Debug" }
        targetdir (iif(bUseSpecificTargetDir, outputFolderDebugWin32, outputFolder .. "Debug/"))
    end

	local haveDurangoSplitDebugFolder = ( outputFolderDebugDurango ~= nil and outputFolderDebugDurango ~= "")
	local haveApolloArmSplitDebugFolder = ( outputFolderDebugApolloArm ~= nil and outputFolderDebugApolloArm ~= "")
	local haveApolloX86SplitDebugFolder = ( outputFolderDebugApolloX86 ~= nil and outputFolderDebugApolloX86 ~= "")
	local haveMetroArmSplitDebugFolder = ( outputFolderDebugMetroArm ~= nil and outputFolderDebugMetroArm ~= "")
	local haveMetroX86SplitDebugFolder = ( outputFolderDebugMetroX86 ~= nil and outputFolderDebugMetroX86 ~= "")
	local haveMetroX64SplitDebugFolder = ( outputFolderDebugMetroX64 ~= nil and outputFolderDebugMetroX64 ~= "")
	
    configuration { "Debug",      "x32" } targetdir (iif(bUseSpecificTargetDir, outputFolderDebugWin32, outputFolder .. "bin" .. buildSystemSuffix .. "dx9x86d"))                     delayloadeddlls (delayDebugWin32)
    configuration { "Debug DX11", "x32" } targetdir (iif(bUseSpecificTargetDir, outputFolderDebugDX11Win32, outputFolder .. "bin" .. buildSystemSuffix .. "dx11x86d"))                delayloadeddlls (delayDebugDX11Win32)
    configuration { "Debug NoXI", "x32" } targetdir (iif(bUseSpecificTargetDir, outputFolderDebugNoXIWin32, outputFolder .. "bin" .. buildSystemSuffix .. "dx9x86d/builds/noXInput")) delayloadeddlls (delayDebugNoXIWin32)
    configuration { "Debug",  "PS3" } targetdir (iif(bUseSpecificTargetDir, outputFolderDebugPS3, outputFolder .. iif(outputTypePS3 == "StaticLib", "lib", "binps3d")))
    configuration { "Debug", "PSVita" } targetdir (iif(bUseSpecificTargetDir, outputFolderDebugPSP2, outputFolder .. iif(outputTypePSP2 == "StaticLib", "lib", "binpsp2d")))
    configuration { "Debug",  "Xbox360" } targetdir (iif(bUseSpecificTargetDir, outputFolderDebugXbox360, outputFolder .. iif(outputTypeXbox360 == "StaticLib", "lib", "binxbox360d")))
    configuration { "Debug Wii", "x32"  } targetdir (iif(bUseSpecificTargetDir, outputFolderDebugWii, outputFolder .. iif(outputTypeWii == "StaticLib", "lib", "binwiid")))
    configuration { "Debug", "Cafe"  } targetdir (iif(bUseSpecificTargetDir, outputFolderDebugWiiU, outputFolder .. iif(outputTypeWiiU == "StaticLib", "lib", "binwiiud")))
    
	  configuration { "Debug*",  "Durango" } targetdir (iif(bUseSpecificTargetDir or haveDurangoSplitDebugFolder, outputFolderDebugDurango, iif(outputTypeDurango == "StaticLib", outputFolder .. "lib", "./bindurangod")))
    configuration { "Debug*",  "Apollo_Arm" } targetdir (iif(bUseSpecificTargetDir or haveApolloArmSplitDebugFolder, outputFolderDebugApolloArm, iif(outputTypeApolloArm == "StaticLib", outputFolder .. "lib", "./binapolloarmd")))
    configuration { "Debug*",  "Apollo_x32" } targetdir (iif(bUseSpecificTargetDir or haveApolloX86SplitDebugFolder, outputFolderDebugApolloX86, iif(outputTypeApolloX86 == "StaticLib", outputFolder .. "lib", "./binapollox86d")))
	  configuration { "Debug*",  "Metro_Arm" } targetdir (iif(bUseSpecificTargetDir or haveMetroArmSplitDebugFolder, outputFolderDebugMetroArm, iif(outputTypeMetroArm == "StaticLib", outputFolder .. "lib", "./binmetroarmd")))
    configuration { "Debug*",  "Metro_x32" } targetdir (iif(bUseSpecificTargetDir or haveMetroX86SplitDebugFolder, outputFolderDebugMetroX86, iif(outputTypeMetroX86 == "StaticLib", outputFolder .. "lib", "./binmetrox86d")))
    configuration { "Debug*",  "Metro_x64" } targetdir (iif(bUseSpecificTargetDir or haveMetroX64SplitDebugFolder, outputFolderDebugMetroX64, iif(outputTypeMetroX64 == "StaticLib", outputFolder .. "lib", "./binmetrox64d")))

    configuration { "StaticLib Debug or StaticLib MT Debug", "x32" }  targetdir (iif(bUseSpecificTargetDir, outputFolderDebugStaticWin32, outputFolder .. "lib"))

    configuration { "Debug",      "x64" }  targetdir (iif(bUseSpecificTargetDir, outputFolderDebugX64, outputFolder .. "bin" .. buildSystemSuffix .. "dx9x64d"))                 delayloadeddlls (delayDebugX64)
    configuration { "Debug DX11", "x64" }  targetdir (iif(bUseSpecificTargetDir, outputFolderDebugDX11X64, outputFolder .. "bin" .. buildSystemSuffix .. "dx11x64d"))                delayloadeddlls (delayDebugDX11X64)
    configuration { "Debug NoXI", "x64" }  targetdir (iif(bUseSpecificTargetDir, outputFolderDebugNoXIX64, outputFolder .. "bin" .. buildSystemSuffix .. "dx9x64d/builds/noXInput")) delayloadeddlls (delayDebugNoXIX64)
    configuration { "StaticLib Debug or StaticLib MT Debug", "x64" }  targetdir (iif(bUseSpecificTargetDir, outputFolderDebugStaticX64, outputFolder .. "lib/x64"))

    -- RELEASE configurations
    if projectLanguage == "C#" then
      configuration { "Release" }
        targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseWin32, outputFolder .. "Release/"))
    end
    
	local haveDurangoSplitReleaseFolder = ( outputFolderReleaseDurango ~= nil and outputFolderReleaseDurango ~= "")
	local haveApolloArmSplitReleaseFolder = ( outputFolderReleaseApolloArm ~= nil and outputFolderReleaseApolloArm ~= "")
	local haveApolloX86SplitReleaseFolder = ( outputFolderReleaseApolloX86 ~= nil and outputFolderReleaseApolloX86 ~= "")
	local haveMetroArmSplitReleaseFolder = ( outputFolderReleaseMetroArm ~= nil and outputFolderReleaseMetroArm ~= "")
	local haveMetroX86SplitReleaseFolder = ( outputFolderReleaseMetroX86 ~= nil and outputFolderReleaseMetroX86 ~= "")
	local haveMetroX64SplitReleaseFolder = ( outputFolderReleaseMetroX64 ~= nil and outputFolderReleaseMetroX64 ~= "")
	
    configuration { "Release",      "x32" } targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseWin32, outputFolder .. "bin" .. buildSystemSuffix .. "dx9x86" .. iif( bUseProfilingConfig, "/builds/release/", "" )))                  delayloadeddlls (delayReleaseWin32)
    configuration { "Release DX11", "x32" } targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseDX11Win32, outputFolder .. "bin" .. buildSystemSuffix .. "dx11x86" .. iif( bUseProfilingConfig, "/builds/release/", "" )))                 delayloadeddlls (delayReleaseDX11Win32)
    configuration { "Release NoXI", "x32" } targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseNoXIWin32, outputFolder .. "bin" .. buildSystemSuffix .. "dx9x86/builds/noXInput" .. iif( bUseProfilingConfig, "/builds/release/", "" )))  delayloadeddlls (delayReleaseNoXIWin32)
    configuration { "Release",  "PS3" } targetdir (iif(bUseSpecificTargetDir, outputFolderReleasePS3, outputFolder .. iif(outputTypePS3 == "StaticLib", "lib", "binps3") .. iif( bUseProfilingConfig, "/builds/release/", "" )))
    configuration { "Release", "PSVita" } targetdir (iif(bUseSpecificTargetDir, outputFolderReleasePSP2, outputFolder .. iif(outputTypePSP2 == "StaticLib", "lib", "binpsp2") .. iif( bUseProfilingConfig, "/builds/release/", "" )))
    configuration { "Release",  "Xbox360" } targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseXbox360, outputFolder .. iif(outputTypeXbox360 == "StaticLib", "lib", "binxbox360") .. iif( bUseProfilingConfig, "/builds/release/", "" )))
    configuration { "Release Wii", "x32"  } targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseWii, outputFolder .. iif(outputTypeWii == "StaticLib", "lib", "binwii") .. iif( bUseProfilingConfig, "/builds/release/", "" )))
    configuration { "Release", "Cafe"  } targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseWiiU, outputFolder .. iif(outputTypeWiiU == "StaticLib", "lib", "binwiiu") .. iif( bUseProfilingConfig, "/builds/release/", "" )))
    
    configuration { "Release DX11",  "Durango" } targetdir (iif(bUseSpecificTargetDir or haveDurangoSplitReleaseFolder, outputFolderReleaseDurango,         outputFolder .. iif(outputTypeDurango == "StaticLib", "lib", "./bindurango") .. iif( bUseProfilingConfig, "/builds/release/", "" )))
    configuration { "Release DX11",  "Apollo_Arm" } targetdir (iif(bUseSpecificTargetDir or haveApolloArmSplitReleaseFolder, outputFolderReleaseApolloArm,  outputFolder .. iif(outputTypeApolloArm == "StaticLib", "lib", "./binapolloarm") .. iif( bUseProfilingConfig, "/builds/release/", "" )))
    configuration { "Release DX11",  "Apollo_x32" } targetdir (iif(bUseSpecificTargetDir or haveApolloX86SplitReleaseFolder, outputFolderReleaseApolloX86,  outputFolder .. iif(outputTypeApolloX86 == "StaticLib", "lib", "./binapollox86") .. iif( bUseProfilingConfig, "/builds/release/", "" )))
    configuration { "Release DX11",  "Metro_Arm" } targetdir (iif(bUseSpecificTargetDir or haveMetroArmSplitReleaseFolder, outputFolderReleaseMetroArm,     outputFolder .. iif(outputTypeMetroArm == "StaticLib", "lib", "./binmetroarm") .. iif( bUseProfilingConfig, "/builds/release/", "" )))
    configuration { "Release DX11",  "Metro_x32" } targetdir (iif(bUseSpecificTargetDir or haveMetroX86SplitReleaseFolder, outputFolderReleaseMetroX86,     outputFolder .. iif(outputTypeMetroX86 == "StaticLib", "lib", "./binmetrox86") .. iif( bUseProfilingConfig, "/builds/release/", "" )))
    configuration { "Release DX11",  "Metro_x64" } targetdir (iif(bUseSpecificTargetDir or haveMetroX64SplitReleaseFolder, outputFolderReleaseMetroX64,     outputFolder .. iif(outputTypeMetroX64 == "StaticLib", "lib", "./binmetrox64") .. iif( bUseProfilingConfig, "/builds/release/", "" )))

    configuration { "StaticLib Release or StaticLib MT Release", "x32" } targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseStaticWin32, outputFolder .. "lib") .. iif( bUseProfilingConfig, "/builds/release/", "" ))
    configuration { "Release",      "x64" }   targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseX64, outputFolder .. "bin" .. buildSystemSuffix .. "dx9x64" .. iif( bUseProfilingConfig, "/builds/release/", "" )))                  delayloadeddlls (delayReleaseX64)
    configuration { "Release DX11", "x64" }   targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseDX11X64, outputFolder .. "bin" .. buildSystemSuffix .. "dx11x64" .. iif( bUseProfilingConfig, "/builds/release/", "" )))                 delayloadeddlls (delayReleaseDX11X64)
    configuration { "Release NoXI", "x64" }   targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseNoXIX64, outputFolder .. "bin" .. buildSystemSuffix .. "dx9x64/builds" .. iif( bUseProfilingConfig, "/release", "" ) .. "/noXInput/"))  delayloadeddlls (delayReleaseNoXIX64)
    configuration { "StaticLib Release or StaticLib MT Release", "x64" } targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseStaticX64, outputFolder .. "lib/x64" .. iif( bUseProfilingConfig, "/builds/release/", "" )))
    
    configuration { "ReleaseP",     "x32" } targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseWin32 .. "/profiling/", outputFolder .. "bin" .. buildSystemSuffix .. "dx9x86" .. "/builds/profiling/"))                  delayloadeddlls (delayReleaseWin32)
    configuration { "ReleaseP DX11", "x32" } targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseDX11Win32 .. "/profiling/", outputFolder .. "bin" .. buildSystemSuffix .. "dx11x86" .. "/builds/profiling/"))                 delayloadeddlls (delayReleaseDX11Win32)
    configuration { "ReleaseP",  "PS3" } targetdir (iif(bUseSpecificTargetDir, outputFolderReleasePS3 .. "/profiling/", outputFolder .. iif(outputTypePS3 == "StaticLib", "lib", "binps3") .. "/builds/profiling/"))
    configuration { "ReleaseP", "PSVita" } targetdir (iif(bUseSpecificTargetDir, outputFolderReleasePSP2 .. "/profiling/", outputFolder .. iif(outputTypePSP2 == "StaticLib", "lib", "binpsp2") .. "/builds/profiling/"))
    configuration { "ReleaseP",  "Xbox360" } targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseXbox360 .. "/profiling/", outputFolder .. iif(outputTypeXbox360 == "StaticLib", "lib", "binxbox360") .. "/builds/profiling/"))
    configuration { "ReleaseP Wii", "x32"  } targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseWii .. "/profiling/", outputFolder .. iif(outputTypeWii == "StaticLib", "lib", "binwii") .. "/builds/profiling/"))
    configuration { "ReleaseP", "Cafe"  } targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseWiiU .. "/profiling/", outputFolder .. iif(outputTypeWiiU == "StaticLib", "lib", "binwiiu") .. "/builds/profiling/"))

    configuration { "ReleaseP DX11",  "Durango" } targetdir (iif(bUseSpecificTargetDir or haveDurangoSplitReleaseFolder, outputFolderReleaseDurango .. "/profiling/",  iif(outputTypeDurango == "StaticLib", outputFolder .."lib".. "/builds/profiling/", "./bindurangop") ))
    configuration { "ReleaseP DX11",  "Apollo_Arm" } targetdir (iif(bUseSpecificTargetDir or haveApolloArmSplitReleaseFolder, outputFolderReleaseApolloArm .. "/profiling/", iif(outputTypeApolloArm == "StaticLib", outputFolder .."lib".. "/builds/profiling/", "./binapolloarmp") ))
    configuration { "ReleaseP DX11",  "Apollo_x32" } targetdir (iif(bUseSpecificTargetDir or haveApolloX86SplitReleaseFolder, outputFolderReleaseApolloX86 .. "/profiling/", iif(outputTypeApolloX86 == "StaticLib", outputFolder .."lib".. "/builds/profiling/", "./binapollox86p") ))
    configuration { "ReleaseP DX11",  "Metro_Arm" } targetdir (iif(bUseSpecificTargetDir or haveMetroArmSplitReleaseFolder, outputFolderReleaseMetroArm .. "/profiling/", iif(outputTypeMetroArm == "StaticLib", outputFolder .."lib".. "/builds/profiling/", "./binmetroarmp") ))
    configuration { "ReleaseP DX11",  "Metro_x32" } targetdir (iif(bUseSpecificTargetDir or haveMetroX86SplitReleaseFolder, outputFolderReleaseMetroX86 .. "/profiling/", iif(outputTypeMetroX86 == "StaticLib", outputFolder .."lib".. "/builds/profiling/", "./binmetrox86p") ))
    configuration { "ReleaseP DX11",  "Metro_x64" } targetdir (iif(bUseSpecificTargetDir or haveMetroX64SplitReleaseFolder, outputFolderReleaseMetroX64 .. "/profiling/", iif(outputTypeMetroX64 == "StaticLib", outputFolder .."lib".. "/builds/profiling/", "./binmetrox64p") ))

    configuration { "ReleaseP",     "x64" }   targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseX64 .. "/profiling/", outputFolder .. "bin" .. buildSystemSuffix .. "dx9x64" .. "/builds/profiling/"))                  delayloadeddlls (delayReleaseX64)
    configuration { "ReleaseP DX11", "x64" }   targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseDX11X64 .. "/profiling/", outputFolder .. "bin" .. buildSystemSuffix .. "dx11x64" .. "/builds/profiling/"))                 delayloadeddlls (delayReleaseDX11X64)
    configuration { "ReleaseP NoXI", "x64" }   targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseNoXIX64 .. "/profiling/", outputFolder .. "bin" .. buildSystemSuffix .. "dx9x64/builds/profiling/noXInput/"))  delayloadeddlls (delayReleaseNoXIX64)

    --configuration { "Debug DX11" }     implibsuffix ("DX11D")
    --configuration { "Release DX11 or ReleaseP DX11" }   implibsuffix ("DX11")
    
    -- Specific PS3
    if bIsSPU then
      configuration { "Debug",  "PS3" }
        targetdir (iif(bUseSpecificTargetDir, outputFolderDebugPS3, outputFolder .. "debug/"))
        implibdir (iif(bUseSpecificTargetDir, outputFolderDebugPS3 .. "/", outputFolder .. "debug/"))
        targetsuffix ("")
        implibsuffix ("")
        
      configuration { "Release",  "PS3" }
        targetdir (iif(bUseSpecificTargetDir, outputFolderReleasePS3, outputFolder .. "release/"))
        implibdir (iif(bUseSpecificTargetDir, outputFolderReleasePS3 .. "/", outputFolder .. "release/"))
        targetsuffix ("")
        implibsuffix ("")
        
      configuration { "ReleaseP",  "PS3" }
        targetdir (iif(bUseSpecificTargetDir, outputFolderReleasePS3 .. "/profiling", outputFolder .. "release/profiling") )
        targetsuffix ("")
        implibsuffix ("")
    else
      configuration { "Debug",  "PS3" }
        targetdir (iif(bUseSpecificTargetDir, outputFolderDebugPS3, outputFolder .. iif(outputTypePS3 == "StaticLib", "lib", "binps3d")))
      
      configuration { "Release",  "PS3" }
        targetdir (iif(bUseSpecificTargetDir, outputFolderReleasePS3, outputFolder .. iif(outputTypePS3 == "StaticLib", "lib", "binps3") .. iif( bUseProfilingConfig, "/builds/release/", "" )))
        
      configuration { "ReleaseP",  "PS3" }
        targetdir (iif(bUseSpecificTargetDir, outputFolderReleasePS3 .. "/profiling/", outputFolder .. iif(outputTypePS3 == "StaticLib", "lib", "binps3") .. "/builds/profiling/"))
    end
    ---------------
    
    PrintVerbose("\t\tOutput type...")
    -- Output type
    if outputTypeWin ~= "" then
      configuration { "Release DX11", "x32 or x64 or any" }   
        kind (outputTypeWin)
        targetextension (GetTargetExtension(outputTypeWin, "x32"))
        defines { GetDefinesByOutputType(outputTypeWin) }
      
      configuration { "Debug or Debug DX11 or Debug NoXI", "x32 or x64 or any" }
        kind (outputTypeWin)
        targetextension (GetTargetExtension(outputTypeWin, "x32") .. iif(bIsEnginePlugin, "D", "") )
        defines { GetDefinesByOutputType(outputTypeWin) }
        
      configuration { "Release or Release DX11  or ReleaseP or ReleaseP DX11 or Release NoXI", "x32 or x64 or any" }
        kind (outputTypeWin)
        targetextension (GetTargetExtension(outputTypeWin, "x32"))
        defines { GetDefinesByOutputType(outputTypeWin) }
        
      configuration { "StaticLib Debug or StaticLib MT Debug or StaticLib Release or StaticLib MT Release", "x32 or x64 or any" }
        if outputTypeWin == "SharedLib" then
          kind ("StaticLib")
          targetextension (GetTargetExtension("StaticLib", "x32"))
          defines { GetDefinesByOutputType("StaticLib") }
        else
          kind (outputTypeWin)
          targetextension (GetTargetExtension(outputTypeWin, "x32"))
          defines { GetDefinesByOutputType(outputTypeWin) }
        end
    end
    
    if outputTypeWii ~= "" then
      configuration { "Debug Wii", "x32" }
        kind (outputTypeWii)
        targetextension (GetTargetExtension(outputTypeWii, "Wii"))
        defines { GetDefinesByOutputType(outputTypeWii) }
        
      configuration { "Release Wii or ReleaseP Wii", "x32" }
        kind (outputTypeWii)
        targetextension (GetTargetExtension(outputTypeWii, "Wii"))
        defines { GetDefinesByOutputType(outputTypeWii) }
    end  
    
    if outputTypeWiiU ~= "" then
      configuration { "Debug", "Cafe" }
        kind (outputTypeWiiU)
        targetextension (GetTargetExtension(outputTypeWiiU, "WiiU"))
        defines { GetDefinesByOutputType(outputTypeWiiU) }
        
      configuration { "Release or ReleaseP", "Cafe" }
        kind (outputTypeWiiU)
        targetextension (GetTargetExtension(outputTypeWiiU, "WiiU"))
        defines { GetDefinesByOutputType(outputTypeWiiU) }
    end  

    if outputTypePS3 ~= "" then
      configuration { "Debug", "PS3" }
        kind (outputTypePS3)
        targetextension (GetTargetExtension(outputTypePS3, "PS3"))
        defines { GetDefinesByOutputType(outputTypePS3) }
        
      configuration { "Release or ReleaseP", "PS3" }
        kind (outputTypePS3)
        targetextension (GetTargetExtension(outputTypePS3, "PS3"))
        defines { GetDefinesByOutputType(outputTypePS3) }
    end
    
    if outputTypePSP2 ~= "" then
      configuration { "Debug", "PSVita" }
        kind (outputTypePSP2)
        targetextension (GetTargetExtension(outputTypePSP2, "PSP2"))
        defines { GetDefinesByOutputType(outputTypePSP2) }
        
      configuration { "Release or ReleaseP", "PSVita" }
        kind (outputTypePSP2)
        targetextension (GetTargetExtension(outputTypePSP2, "PSP2"))
        defines { GetDefinesByOutputType(outputTypePSP2) }
    end
    
    if outputTypeXbox360 ~= "" then
      configuration { "Debug or Release or ReleaseP", "Xbox360" }   -- For: any configuration of the 'Xbox360' platform.
        kind (outputTypeXbox360)           -- Set the output type to  
        targetextension (GetTargetExtension(outputTypeXbox360, "Xbox360"))
        --targetextension (Xbox360TargetExt) <--- NO! Xbox 360 needs the normal .exe extension to generate then the .xex file.
        defines { GetDefinesByOutputType(outputTypeXbox360) }
    end
      
    configuration { "Debug Wii or Release Wii or ReleaseP Wii", "x32" }
      kind "Makefile"
      defines { "" }
    if outputTypeDurango ~= "" then
      configuration { "Debug DX11 or Release DX11 or ReleaseP DX11", "Durango" }  
        kind (outputTypeDurango)           -- Set the output type to  
        targetextension (GetTargetExtension(outputTypeDurango, "Durango"))
        defines { GetDefinesByOutputType(outputTypeDurango) }
    end

    if outputTypeApollo ~= "" then
      configuration { "Debug DX11 or Release DX11 or ReleaseP DX11", "Apollo_Arm or Apollo_x32" }   
        kind (outputTypeApollo)           -- Set the output type to  
        targetextension (GetTargetExtension(outputTypeApollo, "Apollo"))
        defines { GetDefinesByOutputType(outputTypeApollo) }
    end

    if outputTypeMetro ~= "" then
      configuration { "Debug DX11 or Release DX11 or ReleaseP DX11", "Metro_Arm or Metro_x32 or Metro_x64" }   
        kind (outputTypeMetro)           -- Set the output type to  
        targetextension (GetTargetExtension(outputTypeMetro, "Metro"))
        defines { GetDefinesByOutputType(outputTypeMetro) }
    end

    -- End - Decide output kind -  or .dll

    PrintVerbose("\t\tSpecific platform and build configs defines...")
    configuration { "*DX11"   } defines { definesDX11 }
    configuration { "*NoXI"   } defines { "_VISION_NO_XINPUT" }
    if definesStaticLibMT and definesStaticLibMT ~= "" then
      configuration { "StaticLib MT*", "x32 or x64" } defines { definesStaticLibMT }    -- Add this define
    end
    if definesStaticLib and definesStaticLib ~= "" then
      configuration { "StaticLib Debug or StaticLib Release", "x32 or x64" } defines { definesStaticLib }    -- Add this define
    end
    
    configuration { "Debug",                "x32" } defines { definesDebugX86 }
    configuration { "Release or ReleaseP",  "x32" } defines { definesReleaseX86 }
    
    configuration { "Debug",                "x64" } defines { definesDebugX64 }
    configuration { "Release or ReleaseP",  "x64" } defines { definesReleaseX64}

    configuration { "Debug DX11",                     "x32 or x64" } defines { definesDebugDX11 }
    configuration { "Release DX11 or ReleaseP DX11",  "x32 or x64" } defines { definesReleaseDX11 }

    configuration { "Debug or Release or ReleaseP", "PS3" } defines { definesPS3 }
    configuration { "Debug",                        "PS3" } defines { definesDebugPS3 }
    configuration { "Release or ReleaseP",          "PS3" } defines { definesReleasePS3 }
    
    configuration { "Debug or Release or ReleaseP", "PSVita" } defines { definesPSP2 }
    configuration { "Debug",                        "PSVita" } defines { definesDebugPSP2 }
    configuration { "Release or ReleaseP",          "PSVita" } defines { definesReleasePSP2 }
         
    configuration { "Debug or Release or ReleaseP", "Xbox360" } defines { definesXbox360 }
    configuration { "Debug",                        "Xbox360" } defines { definesDebugXbox360 }
    configuration { "Release or ReleaseP",          "Xbox360" } defines { definesReleaseXbox360 }
    
    configuration { "Debug Wii or Release Wii or ReleaseP Wii", "x32" } defines { definesWii }
    configuration { "Debug Wii",                                "x32" } defines { definesDebugWii }
    configuration { "Release Wii or ReleaseP Wii",              "x32" } defines { definesReleaseWii } 
    configuration { "Debug or Release or ReleaseP", "Cafe" } defines { definesWiiU }
    configuration { "Debug",                        "Cafe" } defines { definesDebugWiiU }
    configuration { "Release or ReleaseP",          "Cafe" } defines { definesReleaseWiiU } 

    configuration { "Debug DX11 or Release DX11 or ReleaseP DX11", "Durango" } defines { definesDurango }
    configuration { "Debug DX11",                        "Durango" } defines { definesDebugDurango }
    configuration { "Release DX11 or ReleaseP DX11",          "Durango" } defines { definesReleaseDurango }
   
    configuration { "Debug DX11 or Release DX11 or ReleaseP DX11", "Apollo_Arm" } defines { definesApolloArm }
    configuration { "Debug DX11",                        "Apollo_Arm" } defines { definesDebugApolloArm } 
    configuration { "Release DX11 or ReleaseP DX11",          "Apollo_Arm" } defines { definesReleaseApolloArm }
   
    configuration { "Debug DX11 or Release DX11 or ReleaseP DX11", "Apollo_x32" } defines { definesApolloX86 }
    configuration { "Debug DX11",                        "Apollo_x32" } defines { definesDebugApolloX86 } 
    configuration { "Release DX11 or ReleaseP DX11",          "Apollo_x32" } defines { definesReleaseApolloX86 }
   
    configuration { "Debug DX11 or Release DX11 or ReleaseP DX11",  "Metro_Arm" } defines { definesMetroArm }
    configuration { "Debug DX11",                        "Metro_Arm" } defines { definesDebugMetroArm } 
    configuration { "Release DX11 or ReleaseP DX11",          "Metro_Arm" } defines { definesReleaseMetroArm }
   
    configuration { "Debug DX11 or Release DX11 or ReleaseP DX11", "Metro_x32" } defines { definesMetroX86 }
    configuration { "Debug DX11",                        "Metro_x32" } defines { definesDebugMetroX86 } 
    configuration { "Release DX11 or ReleaseP DX11",          "Metro_x32" } defines { definesReleaseMetroX86 }
   
    configuration { "Debug DX11 or Release DX11 or ReleaseP DX11", "Metro_x64" } defines { definesMetroX64 }
    configuration { "Debug DX11",                        "Metro_x64" } defines { definesDebugMetroX64 } 
    configuration { "Release DX11 or ReleaseP DX11",          "Metro_x64" } defines { definesReleaseMetroX64 }

    PrintVerbose("\t\tSpecific misc compile & link optiones...")
    configuration { "Debug", "x32" }
      StackReserveSize  (stackReserveDebugWin32)
      StackCommitSize   (stackCommitDebugWin32)
      
    configuration { "Debug DX11", "x32" }
      StackReserveSize  (stackReserveDebugDX11Win32)
      StackCommitSize   (stackCommitDebugDX11Win32)
      
    configuration { "Debug NoXI", "x32" }
      StackReserveSize  (stackReserveDebugNoXIWin32)
      StackCommitSize   (stackCommitDebugNoXIWin32)
    
    configuration { "StaticLib*Debug", "x32" }
      StackReserveSize  (stackReserveDebugStaticWin32)
      StackCommitSize   (stackCommitDebugStaticWin32)
      
    configuration { "Debug", "x64" }
      StackReserveSize  (stackReserveDebugX64)
      StackCommitSize   (stackCommitDebugX64)
      
    configuration { "Debug DX11", "x64" }
      StackReserveSize  (stackReserveDebugDX11X64)
      StackCommitSize   (stackCommitDebugDX11X64)
      
    configuration { "Debug NoXI", "x64" }
      StackReserveSize  (stackReserveDebugNoXIX64)
      StackCommitSize   (stackCommitDebugNoXIX64)
    
    configuration { "StaticLib*Debug", "x64" }
      StackReserveSize  (stackReserveDebugStaticX64)
      StackCommitSize   (stackCommitDebugStaticX64)
      
    configuration { "Release or ReleaseP", "x32" }
      StackReserveSize  (stackReserveReleaseWin32)
      StackCommitSize   (stackCommitReleaseWin32)
      
    configuration { "Release DX11 or ReleaseP DX11", "x32" }
      StackReserveSize  (stackReserveReleaseDX11Win32)
      StackCommitSize   (stackCommitReleaseDX11Win32)
      
    configuration { "Release NoXI", "x32" }
      StackReserveSize  (stackReserveReleaseNoXIWin32)
      StackCommitSize   (stackCommitReleaseNoXIWin32)
    
    configuration { "StaticLib*Release", "x32" }
      StackReserveSize  (stackReserveReleaseStaticWin32)
      StackCommitSize   (stackCommitReleaseStaticWin32)
      
    configuration { "Release or ReleaseP", "x64" }
      StackReserveSize  (stackReserveReleaseX64)
      StackCommitSize   (stackCommitReleaseX64)
      
    configuration { "Release DX11 or ReleaseP DX11", "x64" }
      StackReserveSize  (stackReserveReleaseDX11X64)
      StackCommitSize   (stackCommitReleaseDX11X64)
      
    configuration { "Release NoXI", "x64" }
      StackReserveSize  (stackReserveReleaseNoXIX64)
      StackCommitSize   (stackCommitReleaseNoXIX64)
    
    configuration { "StaticLib*Release", "x64" }
      StackReserveSize  (stackReserveReleaseStaticX64)
      StackCommitSize   (stackCommitReleaseStaticX64)
  
    configuration { "Debug", "PS3" }
      StackReserveSize  (stackReserveDebugPS3)
      StackCommitSize   (stackCommitDebugPS3)
      
    configuration { "Release or ReleaseP", "PS3" }
      StackReserveSize  (stackReserveReleasePS3)
      StackCommitSize   (stackCommitReleasePS3)
      
    configuration { "Debug", "PSVita" }
      StackReserveSize  (stackReserveDebugPSP2)
      StackCommitSize   (stackCommitDebugPSP2)
      
    configuration { "Release or ReleaseP", "PSVita" }
      StackReserveSize  (stackReserveReleasePSP2)
      StackCommitSize   (stackCommitReleasePSP2)
      
    configuration { "Debug", "Xbox360" }
      StackReserveSize  (stackReserveDebugXbox360)
      StackCommitSize   (stackCommitDebugXbox360)
      
    configuration { "Release or ReleaseP", "Xbox360" }
      StackReserveSize  (stackReserveReleaseXbox360)
      StackCommitSize   (stackCommitReleaseXbox360)
    
    configuration { "Debug", "Cafe" }
      StackReserveSize  (stackReserveDebugWiiU)
      StackCommitSize   (stackCommitDebugWiiU)
      
    configuration { "Release or ReleaseP", "Cafe" }
      StackReserveSize  (stackReserveReleaseWiiU)
      StackCommitSize   (stackCommitReleaseWiiU)
    
	  configuration { "Debug DX11", "Durango" }
      StackReserveSize  (stackReserveDebugDurango)
      StackCommitSize   (stackCommitDebugDurango)
      
    configuration { "Release DX11 or ReleaseP DX11", "Durango" }
      StackReserveSize  (stackReserveReleaseDurango)
      StackCommitSize   (stackCommitReleaseDurango)
    
	  configuration { "Debug DX11", "Apollo_Arm" }
      StackReserveSize  (stackReserveDebugApolloArm)
      StackCommitSize   (stackCommitDebugApolloArm)
      
    configuration { "Release DX11 or ReleaseP DX11", "Apollo_Arm" }
      StackReserveSize  (stackReserveReleaseApolloArm)
      StackCommitSize   (stackCommitReleaseApolloArm)

    configuration { "Debug DX11", "Apollo_x32" }
      StackReserveSize  (stackReserveDebugApolloX86)
      StackCommitSize   (stackCommitDebugApolloX86)
      
    configuration { "Release DX11 or ReleaseP DX11", "Apollo_x32" }
      StackReserveSize  (stackReserveReleaseApolloX86)
      StackCommitSize   (stackCommitReleaseApolloX86)

    configuration { "Debug DX11", "Metro_Arm" }
      StackReserveSize  (stackReserveDebugMetroArm)
      StackCommitSize   (stackCommitDebugMetroArm)
      
    configuration { "Release DX11 or ReleaseP DX11", "Metro_Arm" }
      StackReserveSize  (stackReserveReleaseMetroArm)
      StackCommitSize   (stackCommitReleaseMetroArm)

    configuration { "Debug DX11", "Metro_x32" }
      StackReserveSize  (stackReserveDebugMetroX86)
      StackCommitSize   (stackCommitDebugMetroX86)
      
    configuration { "Release DX11 or ReleaseP DX11", "Metro_x32" }
      StackReserveSize  (stackReserveReleaseMetroX86)
      StackCommitSize   (stackCommitReleaseMetroX86)

    configuration { "Debug DX11", "Metro_x64" }
      StackReserveSize  (stackReserveDebugMetroX64)
      StackCommitSize   (stackCommitDebugMetroX64)
      
    configuration { "Release DX11 or ReleaseP DX11", "Metro_x64" }
      StackReserveSize  (stackReserveReleaseMetroX64)
      StackCommitSize   (stackCommitReleaseMetroX64)

    PrintVerbose("\t\tCompiler & linker flags...")
    -- Compiler & Linker Flags and Stuff --------------------------------------------------------------------
    ----- x32 --------
    configuration { "Debug or Debug DX11 or Debug NoXI or StaticLib* or Release or ReleaseP or Release DX11 or ReleaseP DX11 or Release NoXI", "x32 or x64 or Xbox360" }
      buildoptions   ("/MP")  -- Enable multi-process compiling for all support platforms
      
    configuration { "Debug or Debug DX11 or Debug NoXI", "x32" }
      buildoptions   (buildOptDebugWin32)
      linkoptions    (linkOptDebugWin32)
      flags          (flagsDebugWin32)
      ignoredefaultlibrarynames (ignoreDefaultLibsDebug)
      disablespecificwarnings (disableWarningsDebugWin32)
      forcedusingfiles (forcedUsingFilesDebugWin32)
      if postBuildWin then
        postbuildcommands (postBuildWin)
        postbuilddesc (postBuildDescWin)
      end
      if preBuildDebugWin then
        prebuildcommands (preBuildDebugWin)
        prebuilddesc (preBuildDescWin)
      end
      
    configuration { "Debug NoXI or Release NoXI", "x32" }
      if postBuildNoXI then
        postbuildcommands (postBuildNoXI)
        postbuilddesc (postBuildDescNoXI)
      end
      
    configuration { "Debug NoXI or Release NoXI", "x64" }
      if postBuildNoXI then
        postbuildcommands (postBuildNoXIX64)
        postbuilddesc (postBuildDescNoXI)
      end
      
    configuration { "StaticLib Debug", "x32" }
      buildoptions   (buildOptDebugStaticWin32)
      linkoptions    (linkOptDebugStaticWin32)
      flags          ( { flagsDebugWin32, flagsStaticWin } )
      ignoredefaultlibrarynames (ignoreDefaultLibsStaticDebug)
      disablespecificwarnings (disableWarningsDebugWin32)
      forcedusingfiles (forcedUsingFilesDebugWin32)
      if postBuildWin then
        postbuildcommands (postBuildWin)
        postbuilddesc (postBuildDescWin)
      end
      if preBuildDebugWin then
        prebuildcommands (preBuildDebugWin)
        prebuilddesc (preBuildDescWin)
      end
      
    configuration { "StaticLib MT Debug", "x32" }
      buildoptions   (buildOptDebugStaticMTWin32)
      linkoptions    (linkOptDebugStaticWin32)
      flags          {flagsDebugWin32, flagsStaticMTWin}
      disablespecificwarnings (disableWarningsDebugWin32)
      forcedusingfiles (forcedUsingFilesDebugWin32)
      if postBuildWin then
        postbuildcommands (postBuildWin)
        postbuilddesc (postBuildDescWin)
      end
      if preBuildDebugWin then
        prebuildcommands (preBuildDebugWin)
        prebuilddesc (preBuildDescWin)
      end

    configuration { "Release or ReleaseP or Release DX11 or ReleaseP DX11 or Release NoXI", "x32" }
      buildoptions   (buildOptReleaseWin32)
      linkoptions    (linkOptReleaseWin32)
      flags          (flagsReleaseWin32)
      ignoredefaultlibrarynames (ignoreDefaultLibsRelease)
      disablespecificwarnings (disableWarningsReleaseWin32)
      forcedusingfiles (forcedUsingFilesReleaseWin32)
      if postBuildWin then
        postbuildcommands (postBuildWin)
        postbuilddesc (postBuildDescWin)
      end
      if preBuildReleaseWin then
        prebuildcommands (preBuildReleaseWin)
        prebuilddesc (preBuildDescWin)
      end
      
    configuration { "StaticLib Release", "x32" }
      buildoptions   (buildOptReleaseStaticWin32)
      linkoptions    (linkOptReleaseStaticWin32)
      flags          ( { flagsReleaseWin32, flagsStaticWin } )
      ignoredefaultlibrarynames (ignoreDefaultLibsStaticRelease)
      disablespecificwarnings (disableWarningsReleaseWin32)
      forcedusingfiles (forcedUsingFilesReleaseWin32)
      if postBuildWin then
        postbuildcommands (postBuildWin)
        postbuilddesc (postBuildDescWin)
      end
      if preBuildReleaseWin then
        prebuildcommands (preBuildReleaseWin)
        prebuilddesc (preBuildDescWin)
      end
      
    configuration { "StaticLib MT Release", "x32" }
      buildoptions   (buildOptReleaseStaticMTWin32)
      linkoptions    (linkOptReleaseStaticWin32)
      flags          {flagsReleaseWin32, flagsStaticMTWin}
      disablespecificwarnings (disableWarningsReleaseWin32)
      forcedusingfiles (forcedUsingFilesReleaseWin32)
      if postBuildWin then
        postbuildcommands (postBuildWin)
        postbuilddesc (postBuildDescWin)
      end
      if preBuildReleaseWin then
        prebuildcommands (preBuildReleaseWin)
        prebuilddesc (preBuildDescWin)
      end
    ---------------------

    ----- x64 --------
    configuration { "Debug or Debug DX11 or Debug NoXI", "x64" }
      buildoptions   (buildOptDebugX64)
      linkoptions    (linkOptDebugX64)
      flags          (flagsDebugX64)
      ignoredefaultlibrarynames (ignoreDefaultLibsDebugX64)
      disablespecificwarnings (disableWarningsDebugX64)
      forcedusingfiles (forcedUsingFilesDebugX64)
      if postBuildWin then
        postbuildcommands (postBuildWin)
        postbuilddesc (postBuildDescWin)
      end
      if preBuildDebugWinX64 then
        prebuildcommands (preBuildDebugWinX64)
        prebuilddesc (preBuildDescWinX64)
      end
      
    configuration { "StaticLib Debug", "x64" }
      buildoptions   (buildOptDebugStaticX64)
      linkoptions    (linkOptDebugStaticX64)
      flags          ( { flagsDebugX64, flagsStaticWin } )
      ignoredefaultlibrarynames (ignoreDefaultLibsStaticDebugX64)
      disablespecificwarnings (disableWarningsDebugX64)
      forcedusingfiles (forcedUsingFilesDebugX64)
      if postBuildWin then
        postbuildcommands (postBuildWin)
        postbuilddesc (postBuildDescWin)
      end
      if preBuildWinX64 then
        prebuildcommands (preBuildWinX64)
        prebuilddesc (preBuildDescWinX64)
      end
      
    configuration { "StaticLib MT Debug", "x64" }
      buildoptions   (buildOptDebugStaticMTX64)
      linkoptions    (linkOptDebugStaticX64)
      flags          {flagsDebugX64, flagsStaticMTWin}
      disablespecificwarnings (disableWarningsDebugX64)
      forcedusingfiles (forcedUsingFilesDebugX64)
      if postBuildWin then
        postbuildcommands (postBuildWin)
        postbuilddesc (postBuildDescWin)
      end
      if preBuildDebugWinX64 then
        prebuildcommands (preBuildDebugWinX64)
        prebuilddesc (preBuildDescWinX64)
      end
         
    configuration { "Release or ReleaseP or Release DX11 or ReleaseP DX11 or Release NoXI", "x64" }
      buildoptions   (buildOptReleaseX64)
      linkoptions    (linkOptReleaseX64)
      flags          (flagsReleaseX64)
      ignoredefaultlibrarynames (ignoreDefaultLibsReleaseX64)
      disablespecificwarnings (disableWarningsReleaseX64)
      forcedusingfiles (forcedUsingFilesReleaseX64)
      if postBuildWin then
        postbuildcommands (postBuildWin)
        postbuilddesc (postBuildDescWin)
      end
     if preBuildReleaseWinX64 then
        prebuildcommands (preBuildReleaseWinX64)
        prebuilddesc (preBuildDescWinX64)
      end
      
    configuration { "StaticLib Release", "x64" }
      buildoptions   (buildOptReleaseStaticX64)
      linkoptions    (linkOptReleaseStaticX64)
      flags          ( { flagsReleaseX64, flagsStaticWin } )
      ignoredefaultlibrarynames (ignoreDefaultLibsStaticReleaseX64)
      disablespecificwarnings (disableWarningsReleaseX64)
      forcedusingfiles (forcedUsingFilesReleaseX64)
      if postBuildWin then
        postbuildcommands (postBuildWin)
        postbuilddesc (postBuildDescWin)
      end
      if preBuildReleaseWinX64 then
        prebuildcommands (preBuildReleaseWinX64)
        prebuilddesc (preBuildDescWinX64)
      end
      
    configuration { "StaticLib MT Release", "x64" }
      buildoptions   (buildOptReleaseStaticMTX64)
      linkoptions    (linkOptReleaseStaticX64)
      flags          {flagsReleaseX64, flagsStaticMTWin}
      disablespecificwarnings (disableWarningsReleaseX64)
      forcedusingfiles (forcedUsingFilesReleaseX64)
      if postBuildWin then
        postbuildcommands (postBuildWin)
        postbuilddesc (postBuildDescWin)
      end
      if preBuildReleaseWinX64 then
        prebuildcommands (preBuildReleaseWinX64)
        prebuilddesc (preBuildDescWinX64)
      end
    -------------
    
    if projectLanguage == "C#" then
      configuration { "Debug" }
        flags ({ flagsAllWindows, flagsDebugAllWindows })
      
      configuration { "Release" }
        flags ({ flagsAllWindows, flagsReleaseAllWindows })
    end

    ----- PS3 -----
    configuration { "Debug", "PS3" }
      buildoptions   (buildOptDebugPS3)
      linkoptions    (linkOptDebugPS3)
      flags          (flagsDebugPS3)
      disablespecificwarnings (disableWarningsDebugPS3)
      forcedusingfiles (forcedUsingFilesDebugPS3)
      if bIsSPU then
        implibextension (".ppu.obj")
      end
      if postBuildPS3 then
        postbuildcommands (postBuildPS3)
        postbuilddesc (postBuildDescPS3)
      end
      if preBuildPS3 then
        prebuildcommands (preBuildPS3)
        prebuilddesc (preBuildDescPS3)
      end
      
    configuration { "Release or ReleaseP", "PS3" }
      buildoptions   (buildOptReleasePS3)
      linkoptions    (linkOptReleasePS3)
      flags          (flagsReleasePS3)
      disablespecificwarnings (disableWarningsReleasePS3)
      forcedusingfiles (forcedUsingFilesReleasePS3)
      if bIsSPU then
        implibextension (".ppu.obj")
      end
      if postBuildPS3 then
        postbuildcommands (postBuildPS3)
        postbuilddesc (postBuildDescPS3)
      end
      if preBuildPS3 then
        prebuildcommands (preBuildPS3)
        prebuilddesc (preBuildDescPS3)
      end
    ---------------
    
    ----- PSP2 -----
    configuration { "Debug", "PSVita" }
      buildoptions   (buildOptDebugPSP2)
      linkoptions    (linkOptDebugPSP2)
      flags          (flagsDebugPSP2)
      disablespecificwarnings (disableWarningsDebugPSP2)
      forcedusingfiles (forcedUsingFilesDebugPSP2)
      if postBuildPSP2 then
        postbuildcommands (postBuildPSP2)
        postbuilddesc (postBuildDescPSP2)
      end
      if preBuildPSP2 then
        prebuildcommands (preBuildPSP2)
        prebuilddesc (preBuildDescPSP2)
      end
      
    configuration { "Release or ReleaseP", "PSVita" }
      buildoptions   (buildOptReleasePSP2)
      linkoptions    (linkOptReleasePSP2)
      flags          (flagsReleasePSP2)
      disablespecificwarnings (disableWarningsReleasePSP2)
      forcedusingfiles (forcedUsingFilesReleasePSP2)
      if postBuildPSP2 then
        postbuildcommands (postBuildPSP2)
        postbuilddesc (postBuildDescPSP2)
      end
      if preBuildPSP2 then
        prebuildcommands (preBuildPSP2)
        prebuilddesc (preBuildDescPSP2)
      end
    ---------------

    ----- XBOX 360 -----
    configuration { "Debug", "Xbox360" }
      buildoptions   (buildOptDebugXbox360)
      linkoptions    (linkOptDebugXbox360)
      flags          (flagsDebugXbox360)
      ignoredefaultlibrarynames (ignoreDefaultLibsDebugXbox)
      disablespecificwarnings (disableWarningsDebugXbox360)
      forcedusingfiles (forcedUsingFilesDebugXbox360)
      if postBuildXbox360 then
        postbuildcommands (postBuildXbox360)
        postbuilddesc (postBuildDescXbox360)
      end
      if preBuildXbox360 then
        prebuildcommands (preBuildXbox360)
        prebuilddesc (preBuildDescXbox360)
      end
      
    configuration { "Release or ReleaseP", "Xbox360" }
      buildoptions   (buildOptReleaseXbox360)
      linkoptions    (linkOptReleaseXbox360)
      flags          (flagsReleaseXbox360)
      ignoredefaultlibrarynames (ignoreDefaultLibsReleaseXbox)
      disablespecificwarnings (disableWarningsReleaseXbox360)
      forcedusingfiles (forcedUsingFilesReleaseXbox360)
      if postBuildXbox360 then
        postbuildcommands (postBuildXbox360)
        postbuilddesc (postBuildDescXbox360)
      end
      if preBuildXbox360 then
        prebuildcommands (preBuildXbox360)
        prebuilddesc (preBuildDescXbox360)
      end
    --------------------
    
    ----- Wii -----
    configuration { "Debug Wii", "x32" }
      buildoptions   (buildCommandLineDebugWii) -- For the Makefile output type premake use this field to build the BuildCommandLine
      linkoptions    (cleanCommandLineDebugWii) -- For the Makefile output type premake use this field to build the CleanCommandLine
      flags          (flagsDebugWii)
          
    configuration { "Release Wii or ReleaseP Wii", "x32" }
      buildoptions   (buildCommandLineReleaseWii)
      linkoptions    (cleanCommandLineReleaseWii)
      flags          (flagsReleaseWii)
    ----- Durango -----
    configuration { "Debug DX11", "Durango" }
      buildoptions   (buildOptDebugDurango)
      linkoptions    (linkOptDebugDurango)
      flags          (flagsDebugDurango)
      ignoredefaultlibrarynames (ignoreDefaultLibsDebugDurango)
      disablespecificwarnings (disableWarningsDebugDurango)
      forcedusingfiles (forcedUsingFilesDebugDurango)
      if postBuildDurango then
        postbuildcommands (postBuildDurango)
        postbuilddesc (postBuildDescDurango)
      end
      if preBuildDurango then
        prebuildcommands (preBuildDurango)
        prebuilddesc (preBuildDescDurango)
      end
      
    configuration { "Release DX11 or ReleaseP DX11", "Durango" }
      buildoptions   (buildOptReleaseDurango)
      linkoptions    (linkOptReleaseDurango)
      flags          (flagsReleaseDurango)
      ignoredefaultlibrarynames (ignoreDefaultLibsReleaseDurango)
      disablespecificwarnings (disableWarningsReleaseDurango)
      forcedusingfiles (forcedUsingFilesReleaseDurango)
      if postBuildDurango then
        postbuildcommands (postBuildDurango)
        postbuilddesc (postBuildDescDurango)
      end
      if preBuildDurango then
        prebuildcommands (preBuildDurango)
        prebuilddesc (preBuildDescDurango)
      end
    --------------------

	  ----- Apollo Arm -----
    configuration { "Debug DX11", "Apollo_Arm" }
      buildoptions   (buildOptDebugApolloArm)
      linkoptions    (linkOptDebugApolloArm)
      flags          (flagsDebugApolloArm)
      ignoredefaultlibrarynames (ignoreDefaultLibsDebugApolloArm)
      disablespecificwarnings (disableWarningsDebugApolloArm)
      forcedusingfiles (forcedUsingFilesDebugApolloArm)
      if postBuildApolloArm then
        postbuildcommands (postBuildApolloArm)
        postbuilddesc (postBuildDescApolloArm)
      end
      if preBuildApolloArm then
        prebuildcommands (preBuildApolloArm)
        prebuilddesc (preBuildDescApolloArm)
      end
      
    configuration { "Release DX11 or ReleaseP DX11", "Apollo_Arm" }
      buildoptions   (buildOptReleaseApolloArm)
      linkoptions    (linkOptReleaseApolloArm)
      flags          (flagsReleaseApolloArm)
      ignoredefaultlibrarynames (ignoreDefaultLibsReleaseApolloArm)
      disablespecificwarnings (disableWarningsReleaseApolloArm)
      forcedusingfiles (forcedUsingFilesReleaseApolloArm)
      if postBuildApolloArm then
        postbuildcommands (postBuildApolloArm)
        postbuilddesc (postBuildDescApolloArm)
      end
      if preBuildApolloArm then
        prebuildcommands (preBuildApolloArm)
        prebuilddesc (preBuildDescApolloArm)
      end
    --------------------
    
	  ----- Apollo x86 -----
    configuration { "Debug DX11", "Apollo_x32" }
      buildoptions   (buildOptDebugApolloX86)
      linkoptions    (linkOptDebugApolloX86)
      flags          (flagsDebugApolloX86)
      ignoredefaultlibrarynames (ignoreDefaultLibsDebugApolloX86)
      disablespecificwarnings (disableWarningsDebugApolloX86)
      forcedusingfiles (forcedUsingFilesDebugApolloX86)
      if postBuildApolloX86 then
        postbuildcommands (postBuildApolloX86)
        postbuilddesc (postBuildDescApolloX86)
      end
      if preBuildApolloX86 then
        prebuildcommands (preBuildApolloX86)
        prebuilddesc (preBuildDescApolloX86)
      end
      
    configuration { "Release DX11 or ReleaseP DX11", "Apollo_x32" }
      buildoptions   (buildOptReleaseApolloX86)
      linkoptions    (linkOptReleaseApolloX86)
      flags          (flagsReleaseApolloX86)
      ignoredefaultlibrarynames (ignoreDefaultLibsReleaseApolloX86)
      disablespecificwarnings (disableWarningsReleaseApolloX86)
      forcedusingfiles (forcedUsingFilesReleaseApolloX86)
      if postBuildApolloX86 then
        postbuildcommands (postBuildApolloX86)
        postbuilddesc (postBuildDescApolloX86)
      end
      if preBuildApolloX86 then
        prebuildcommands (preBuildApolloX86)
        prebuilddesc (preBuildDescApolloX86)
      end
    --------------------

	  ----- Metro x86 -----
    configuration { "Debug DX11", "Metro_x32" }
      buildoptions   (buildOptDebugMetroX86)
      linkoptions    (linkOptDebugMetroX86)
      flags          (flagsDebugMetroX86)
      ignoredefaultlibrarynames (ignoreDefaultLibsDebugMetroX86)
      disablespecificwarnings (disableWarningsDebugMetroX86)
      forcedusingfiles (forcedUsingFilesDebugMetroX86)
      if postBuildMetroX86 then
        postbuildcommands (postBuildMetroX86)
        postbuilddesc (postBuildDescMetroX86)
      end
      if preBuildMetroX86 then
        prebuildcommands (preBuildMetroX86)
        prebuilddesc (preBuildDescMetroX86)
      end
      
    configuration { "Release DX11 or ReleaseP DX11", "Metro_x32" }
      buildoptions   (buildOptReleaseMetroX86)
      linkoptions    (linkOptReleaseMetroX86)
      flags          (flagsReleaseMetroX86)
      ignoredefaultlibrarynames (ignoreDefaultLibsReleaseMetroX86)
      disablespecificwarnings (disableWarningsReleaseMetroX86)
      forcedusingfiles (forcedUsingFilesReleaseMetroX86)
      if postBuildMetroX86 then
        postbuildcommands (postBuildMetroX86)
        postbuilddesc (postBuildDescMetroX86)
      end
      if preBuildMetroX86 then
        prebuildcommands (preBuildMetroX86)
        prebuilddesc (preBuildDescMetroX86)
      end
    --------------------

	  ----- Metro x64 -----
    configuration { "Debug DX11", "Metro_x64" }
      buildoptions   (buildOptDebugMetroX64)
      linkoptions    (linkOptDebugMetroX64)
      flags          (flagsDebugMetroX64)
      ignoredefaultlibrarynames (ignoreDefaultLibsDebugMetroX64)
      disablespecificwarnings (disableWarningsDebugMetroX64)
      forcedusingfiles (forcedUsingFilesDebugMetroX64)
      if postBuildMetroX64 then
        postbuildcommands (postBuildMetroX64)
        postbuilddesc (postBuildDescMetroX64)
      end
      if preBuildMetroX64 then
        prebuildcommands (preBuildMetroX64)
        prebuilddesc (preBuildDescMetroX64)
      end
      
    configuration { "Release DX11 or ReleaseP DX11", "Metro_X64" }
      buildoptions   (buildOptReleaseMetroX64)
      linkoptions    (linkOptReleaseMetroX64)
      flags          (flagsReleaseMetroX64)
      ignoredefaultlibrarynames (ignoreDefaultLibsReleaseMetroX64)
      disablespecificwarnings (disableWarningsReleaseMetroX64)
      forcedusingfiles (forcedUsingFilesReleaseMetroX64)
      if postBuildMetroX64 then
        postbuildcommands (postBuildMetroX64)
        postbuilddesc (postBuildDescMetroX64)
      end
      if preBuildMetroX64 then
        prebuildcommands (preBuildMetroX64)
        prebuilddesc (preBuildDescMetroX64)
      end
    --------------------

	  ----- Metro Arm  -----
    configuration { "Debug DX11", "Metro_Arm" }
      buildoptions   (buildOptDebugMetroArm)
      linkoptions    (linkOptDebugMetroArm)
      flags          (flagsDebugMetroArm)
      ignoredefaultlibrarynames (ignoreDefaultLibsDebugMetroArm)
      disablespecificwarnings (disableWarningsDebugMetroArm)
      forcedusingfiles (forcedUsingFilesDebugMetroArm)
      if postBuildMetroArm then
        postbuildcommands (postBuildMetroArm)
        postbuilddesc (postBuildDescMetroArm)
      end
      if preBuildMetroArm then
        prebuildcommands (preBuildMetroArm)
        prebuilddesc (preBuildDescMetroArm)
      end
      
    configuration { "Release DX11 or ReleaseP DX11", "Metro_Arm" }
      buildoptions   (buildOptReleaseMetroArm)
      linkoptions    (linkOptReleaseMetroArm)
      flags          (flagsReleaseMetroArm)
      ignoredefaultlibrarynames (ignoreDefaultLibsReleaseMetroArm)
      disablespecificwarnings (disableWarningsReleaseMetroArm)
      forcedusingfiles (forcedUsingFilesReleaseMetroArm)
      if postBuildMetroArm then
        postbuildcommands (postBuildMetroArm)
        postbuilddesc (postBuildDescMetroArm)
      end
      if preBuildMetroArm then
        prebuildcommands (preBuildMetroArm)
        prebuilddesc (preBuildDescMetroArm)
      end
    --------------------

    ----- WiiU -----
    configuration { "Debug", "Cafe" }
      buildoptions   (buildOptDebugWiiU)
      linkoptions    (linkOptDebugWiiU)
      flags          (flagsDebugWiiU)
      ignoredefaultlibrarynames (ignoreDefaultLibsDebugWiiU)
      disablespecificwarnings (disableWarningsDebugWiiU)
      forcedusingfiles (forcedUsingFilesDebugWiiU)
      if postBuildWiiU then
        postbuildcommands (postBuildWiiU)
        postbuilddesc (postBuildDescWiiU)
      end
      if preBuildWiiU then
        prebuildcommands (preBuildWiiU)
        prebuilddesc (preBuildDescWiiU)
      end
          
    configuration { "Release or ReleaseP", "Cafe" }
      buildoptions   (buildOptReleaseWiiU)
      linkoptions    (linkOptReleaseWiiU)
      flags          (flagsReleaseWiiU)
      ignoredefaultlibrarynames (ignoreDefaultLibsReleaseWiiU)
      disablespecificwarnings (disableWarningsReleaseWiiU)
      forcedusingfiles (forcedUsingFilesReleaseWiiU)
      if postBuildWiiU then
        postbuildcommands (postBuildWiiU)
        postbuilddesc (postBuildDescWiiU)
      end
      if preBuildWiiU then
        prebuildcommands (preBuildWiiU)
        prebuilddesc (preBuildDescWiiU)
      end
  ---------------
    
elseif buildSystem == "xcode3" or buildSystem == "xcode4" then

  project ( projectName )
  
    configurations { buildConfigsForProject }
    platforms      { buildPlatformsForProject }
    
    uuid (projectGUID)
    basedir  "."
    
    if projectLocation and projectLocation ~= "" then
      location (projectLocation)
    else
      location "."
    end
    
    language (projectLanguage)
    
    PrintVerbose("\t\tExcluding files...")
    -- Exclude files & resources ----------------------------------------------------------
    local finalSources = excludeListFromList(sourceFiles, excludedSourcesMac)
    files { finalSources }
    resources { resourceFiles }
    PrintVerbose("\t\tExcluding files... OK")
    ---------------------------------------------------------------------------------------------------------
    
    if not bUseSpecificTargetName then
      targetname (outputTarget)
    end
    
    implibname (projectName)
    targetprefix ""
    implibextension ""
    implibprefix ""
    implibsuffix ""
    objdir (buildTempDir)
    
    if projectReferences ~= "" then
     links { projectReferences }
     
     printf ("\t\tReferences:")
     for _, prjRefName in ipairs(projectReferences) do
      printf ("\t\t\t%s", prjRefName)
     end
    end
    
    if projectDependencies and projectDependencies ~= "" then
      links { projectDependencies }
    end

    if sourcePCH ~= "" then
      printf ("\t\tSource PCH: %s", sourcePCH)
      pchsource (sourcePCH)
    end
    if sourceHeaderPCH ~= "" then
      printf ("\t\tHeader PCH: %s", sourceHeaderPCH)
      pchheader (sourceHeaderPCH)
    end

    kind (outputTypeWin)
    
    PrintVerbose("\t\tGeneral defines...")
    -- General defines -------------------------------------------------------------------------------------
    configuration "Debug"
      defines { definesDebug    }
      resdefines { definesDebug }

    configuration "Release"
      defines { definesRelease  }
      resdefines { definesRelease }
        
    PrintVerbose("\t\tInclude dirs...")
    -- Include dirs -----------------------------------------------------------------------------------------
    configuration { "Debug or Release", "iOS"  } includedirs (includeDirsWin32)
    ---------------------------------------------------------------------------------------------------------

    PrintVerbose("\t\tLib dirs...")
    -- Lib dirs   -------------------------------------------------------------------------------------------
    configuration { "Debug or Release", "iOS"  }  libdirs (libDirsWin32)
    ---------------------------------------------------------------------------------------------------------

    PrintVerbose("\t\tLink libs...")
    -- Link libs  -------------------------------------------------------------------------------------------
    configuration { "Debug",    "iOS" } links (libLinkDebugDx9Win32) 
    configuration { "Release",  "iOS" } links (libLinkReleaseDx9Win32)
    configuration { "Debug" } links (libLinkDebugDx9Win32) 
    configuration { "Release" } links (libLinkReleaseDx9Win32)
    
    if outputTypeWin == "WindowedApp" then
      configuration { "Debug or Release", "iOS" } XCodeSigning("iPhone Developer")
    end
    ---------------------------------------------------------------------------------------------------------
     
    PrintVerbose("\t\tOutput names...")
    -- Output names -----------------------------------------------------------------------------------------
    if bUseSpecificTargetName then
      configuration { "Debug", "iOS"    } targetname (outputTargetDebugWin32)      
      configuration { "Release", "iOS"  } targetname (outputTargetReleaseWin32)
    end
    ---------------------------------------------------------------------------------------------------------

    PrintVerbose("\t\tTarget and import lib dirs...")
    -- RELEASE configurations
    configuration { "Release or Debug" }
      targetsuffix ("")
      implibsuffix ("")

    configuration { "Debug", "iOS"    } targetdir (iif(bUseSpecificTargetDir, outputFolderDebugWin32, outputFolder))
    
    
    configuration { "Release", "iOS"  }
      if bUseProfilingConfig == true then
        targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseWin32 .. "/builds/Release/", outputFolder))
      else
        targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseWin32, outputFolder))
      end
      
    configuration { "ReleaseP", "iOS"  }
      targetdir (iif(bUseSpecificTargetDir, outputFolderReleaseWin32 .. "/builds/Profiling/", outputFolder))
        
    PrintVerbose("\t\tOutput type...")
    -- Output type
    if outputTypeWin ~= "" then
      configuration { "Debug or Release", "iOS" }
        kind (outputTypeWin) -- By default every configuration is a .dll
        targetextension (GetTargetExtension(outputTypeWin, "iOS"))
        defines { GetDefinesByOutputType(outputTypeWin) }
        
        if outputTypeWin ~= "ConsoleApp" and outputTypeWin ~= "WindowedApp" then
          targetprefix "lib"  -- Following linux conventions for libraries.
        end
    end
      
    PrintVerbose("\t\tCompiler & linker flags...")
    -- Compiler & Linker Flags and Stuff --------------------------------------------------------------------
    ----- x32 --------
    configuration { "Debug", "iOS" }
      if buildOptDebugWin32 ~= "" then buildoptions (buildOptDebugWin32)  end
      if linkOptDebugWin32 ~= "" then linkoptions    (linkOptDebugWin32)  end
      if flagsDebugWin32 ~= "" then flags (flagsDebugWin32) end
      --[[
      ignoredefaultlibrarynames (ignoreDefaultLibsDebug)
      disablespecificwarnings (disableWarningsDebugWin32)
      --]]
      --if postBuildWin then
      --  postbuildcommands (postBuildWin)
      --  postbuilddesc (postBuildDescWin)
      --end
    
    configuration { "Release", "iOS" }
      if buildOptReleaseWin32 ~= "" then buildoptions (buildOptReleaseWin32)  end
      if linkOptReleaseWin32 ~= "" then linkoptions    (linkOptReleaseWin32)  end
      if flagsReleaseWin32 ~= "" then flags (flagsReleaseWin32) end
      --[[
      ignoredefaultlibrarynames (ignoreDefaultLibsRelease)
      disablespecificwarnings (disableWarningsReleaseWin32)
      --]]
      --if postBuildWin then
      --  postbuildcommands (postBuildWin)
      --  postbuilddesc (postBuildDescWin)
      --end  

end

  PrintVerbose("\tEnd processing: " .. projectName .. "\n\n")
  
CleanVariables() -- Leave everything ready for the next project.
    
