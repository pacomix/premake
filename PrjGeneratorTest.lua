os.chdir(globalScriptDir) -- Restore the working directory from where this file was included.

PrintVerbose("\t\tWorking directory: " .. os.getcwd())
local bUseSpecificTargetDir = false   -- Whether to use the specific fixed output dir or use the suffixed ones (binXXXXXXXXXX/libXXXXXXXXX).
local bUseSpecificTargetName = false  -- Whether to use the specific fixed output names or use the suffixed ones.
local baseSharedFolder = nil          -- Relative path to the Vision's trunk/shared/ folder
local bUseProfilingConfig = nil       -- Does the project contains profiling configs?
local outputTargetWithoutBuildSystemSuffix = nil  -- Self-descriptive. Used mostly for console output target name.
local bUseSpecificImportLibName = nil

if outputImportLibDebugWin32 ~= "" or outputImportLibDebugDX11Win32 ~= "" or outputImportLibDebugNoXIWin32 ~= "" or outputImportLibDebugX64 ~= "" or outputImportLibDebugDX11X64 ~= "" or outputImportLibDebugNoXIX64 ~= "" or outputImportLibReleaseWin32 ~= "" or outputImportLibReleaseDX11Win32 ~= "" or outputImportLibReleaseNoXIWin32 ~= "" or outputImportLibReleaseX64 ~= "" or outputImportLibReleaseDX11X64 ~= "" or outputImportLibReleaseNoXIX64 ~= "" or outputImportLibDebugXbox360  ~= "" or outputImportLibDebugPS3 ~= "" or outputImportLibDebugPSP2 ~= "" or outputImportLibDebugWii ~= "" or outputImportLibReleaseXbox360 ~= "" or outputImportLibReleasePS3 ~= "" or outputImportLibReleasePSP2 ~= "" or outputImportLibReleaseWii ~= "" then
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
--writeExcludesTo(excludedSourcesWii, excludedSourcesWiiBaseLocation .. "ignoreWii.txt")

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
      relativePathToSharedFolder = ""
      break
    end
  end

  if iSecurityCounter >= 16 then
    --error("\n\n\tERROR!!!!! Shared base folder can not be found.\n\tStarted from:\n\n\t\t" .. globalScriptDir .. "\n\n\tEnded in:\n\n\t\t" .. os.getcwd())
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

mapValidOptions = getMapBuildOptionsKeys()
local mapOptions, mapBuildConfig, mapPlatformOptions, mapPlatformBuildConfigOptions = explodeConfigMap(buildConfigMap, buildConfigsForProject, buildPlatformsForProject)

function executeOption(option, content, preText)
  if preText == nil then preText = "" end
  local premakeFuncTable = {
    ["outputFolder"] = targetdir,
    ["outputTarget"] = targetname,
    ["defines"] = defines,
    ["outputImportLib"] = implibname,
    ["outputType"] = kind,
    ["includeDirs"] = includedirs,
    ["libDirs"] = libdirs,
    ["libLinks"] = links,
    ["stackReserve"] = StackReserveSize,
    ["stackCommit"] = StackCommitSize,
    ["flags"] = flags,
    ["buildCommandLine"] = buildoptions,
    ["preBuildCommand"] = prebuildcommands,
    ["postBuildCommand"] = postbuildcommands,
    ["linkCommandLine"] = linkoptions,
    ["disableWarnings"] = disablespecificwarnings,
    ["delayDLL"] = delayloadeddlls,
    ["ignoreLibs"] = ignoredefaultlibrarynames,
    ["resFiles"] = resources,
    ["pchSource"] = pchsource,
    ["pchHeader"] = pchheader,
    ["propertySheet"] = propertySheet,
    ["forceUsingFiles"] = forcedusingfiles,
    ["resIncludeDirs"] = resincludedirs,
    ["toolset"] = toolset,
    ["objdir"] = objdir,
    ["androidarch"] = androidarch,
    ["SoName"] = SoName,
    ["sourceFiles"] = files,
    ["excludedSources"] = excludes,
  }
  if not tableContainsValue(mapValidOptions, option) then error("Invalid value found as option => " .. option) end
  if not tableContainsKey(premakeFuncTable, option) then 
    for key,val in pairs(premakeFuncTable) do
      printf("[%s] => [func]", key)
    end
    error("Value has no assigned function => " .. option)
  end
  
  --printPair(option, content)
  
  if printConfigMapHelper_ContainAnyValues(content) then
    if type(content) == "table" then content = table.flatten(content) end
    printf("%s[%s] => %s", preText, option, tableToString(content))
    premakeFuncTable[option] (content)
  end
end

function tableToString(value)
  retVal = ""
  
  if value then
    if (printConfigMapHelper_ContainAnyValues(value)) then
      if (type(value) == "table") then
        local bFirstString = true
        for key, val in pairs(value) do
          if (printConfigMapHelper_ContainAnyValues(val)) then
            if (type(val) == "table") then
              retVal = retVal .. "[" .. key .. "]" .. tableToString(val)
            elseif (type(val) == "string") then
              retVal = retVal .. ", " .. val
            end
          end
        end
      elseif (type(value) == "string") then
        retVal = retVal .. " * " .. value
      end
    end
  end
  
  --printf("%s", retVal)
  
  return retVal
end

function printPair(option, content)
  if (type(content) == "table") then
    local contentString = ""
    for key,val in pairs(content) do
      local bFirstValue = true
      if type(val) == "table" then
        contentString = contentString .. tableToString(val) .. " "
      else
        if bFirstValue then
          contentString = contentString .. " = " .. val .. " "
          bFirstValue = false
        else
          contentString = contentString .. val .. " "
        end
      end
    end
    printf("\t[%s] = [%s]", option, contentString)
  else
    printf("\t[%s] = [%s]", option, content)
  end
end

baseSharedFolder = GetBaseSharedFolder()
if buildSystem == "vs2008" or buildSystem == "vs2010" then
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
    if excludedSources ~= nil and excludedSources ~= {} then
      excludes (excludedSources)
    end
    -- TODO - Add checking of targetname in config map
    if outputTarget ~= nil and outputTarget ~= "" then
      targetname (outputTarget)
    end
    
    -- TODO - Extend it to several platforms generating a list of unique files 
    -- and then the exclusion list for each platform.
    PrintVerbose("Populating files...")
    flattenFinalFiles = table.flatten(finalFiles)
    local resolvedFiles = {}
    for idx,file in pairs(flattenFinalFiles) do
      --PrintVerbose("" .. file)
      table.insert(resolvedFiles, populateFiles(file, false))
    end
    resolvedFiles = table.flatten(resolvedFiles)
    local bMissingFiles = false
    for i,v in pairs(resolvedFiles) do
      if v:find("ERROR") then 
        bMissingFiles = true
        printf("%s", v)
      end
    end
    if bMissingFiles then os.exit(1) end
    
    -- Check that the targetname, if not specifying specific output names, doesn't end with the buildSystemSuffix for consoles.
    --[[
    if (string.endswith(outputTarget, buildSystemSuffix)) then
      outputTargetWithoutBuildSystemSuffix = string.explode(outputTarget, buildSystemSuffix)[1]
      PrintVerbose("\tBase output name for consoles: " .. outputTargetWithoutBuildSystemSuffix)
    else
      outputTargetWithoutBuildSystemSuffix = outputTarget
    end
    ]]
    
    targetprefix ""
    implibextension ".lib"
    implibprefix ""
    implibsuffix ""
    --objdir (buildTempDir)
    --VSresculture (culture)
    callingConvention (callConvention)
    
    Xbox360TargetExt = ".xex"

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
    
    -- TODO - Add checking in the map build config
    if not bUseSpecificImportLibName then
      --implibdir (baseSharedFolder .. "lib/" )
    else
      --implibdir ("")
    end
    
    

    -- TODO - Add checking in the map build config
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
    end
    configuration "*" -- Do not forget to always reset the current configuration object.
    ---------------------------------------
    
    -- Global options
    configuration "*" 
    PrintVerbose("\nGeneral options:")
    for key, value in pairs(mapOptions) do
      executeOption(key, value, "\t")
    end
    
    -- Per build config options
    PrintVerbose("\nPer build config options:")
    for keyBuildConfig, option in pairs(mapBuildConfig) do
      configuration (keyBuildConfig)
      for key, val in pairs(option) do
        executeOption(key, val, "\t[" .. keyBuildConfig .. "]")
      end
    end
    
    -- Per platform options
    PrintVerbose("\nPer platform options:")
    for keyPlatform, option in pairs(mapPlatformOptions) do
      configuration (keyPlatform)
      for key, val in pairs(option) do
        executeOption(key, val, "\t[" .. keyPlatform .. "]")
      end
    end
    
    -- Per platform specific build config options
    PrintVerbose("\nPer platform specific build config options:")
    for keyPlatform, buildconfig in pairs(mapPlatformBuildConfigOptions) do
      for key, val in pairs(buildconfig) do
        configuration (key, keyPlatform)
        for opt, content in pairs(val) do
          executeOption(opt, content, "\t[" .. keyPlatform .. "][" .. key .. "]")
        end
      end
    end
    --error("chek values")
    --mapPlatformBuildConfigOptions 
    
    -- Specific platforms things ----------
    --[[
    PrintVerbose("\t\tExcluding files...")
    -- Exclude files & specific file configuration ----------------------------------------------------------
    configuration { "Debug or Debug DX11 or Release or Release DX11 or ReleaseP or ReleaseP DX11", "x32 or x64 or any" }
      excludes (excludedSourcesWindows)
      nopchfile { sourcesNotUsingPCH }
      custombuildtool {
         "../../ThirdParty/tinyXML/**.h*"
      }
    ]]
    ---------------------------------------------------------------------------------------------------------
    
    -- CustomBuildTool -----------------------------------------------------------------------------------
    if fileCustomBuildTool then
      for file,customBuildTool in pairs(fileCustomBuildTool) do
        configuration { file }
          custombuildcommandline (customBuildTool["CommandLine"])
          custombuildcommandlineOutput (customBuildTool["Outputs"])
          custombuildcommandlineDepends (customBuildTool["Dependencies"])
      end
    end
    ---------------------------------------------------------------------------------------------------------
    
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
    
