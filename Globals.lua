-- GLOBAL FUNCTIONS ----------

local mapBuildOptionsKeys = {
    "outputFolder",
    "outputTarget",
    "defines",
    "outputImportLib",
    "outputType",
    "includeDirs",
    "libDirs",
    "libLinks",
    "stackReserve",
    "stackCommit",
    "flags",
    "buildCommandLine",
    "preBuildCommand",
    "postBuildCommand",
    "linkCommandLine",
    "disableWarnings",
    "delayDLL",
    "ignoreLibs",
    "resFiles",
    "pchSource",
    "pchHeader",
    "propertySheet",
    "forceUsingFiles",
    "resIncludeDirs",
    "toolset",
    "objdir",
    "androidarch",
    "SoName", --Android only
    "sourceFiles",
    "excludedSources",
  }
  
local mapBuildOptionsKeysDefaults = {
    ["outputFolder"] = "",
    ["outputTarget"] = "",
    ["defines"] = {},
    ["outputImportLib"] = "",
    ["outputType"] = "",
    ["includeDirs"] = {},
    ["libDirs"] = {},
    ["libLinks"] = {},
    ["stackReserve"] = "",
    ["stackCommit"] = "",
    ["flags"] = {},
    ["buildCommandLine"] = {},
    ["preBuildCommand"] = {},
    ["postBuildCommand"] = {},
    ["linkCommandLine"] = {},
    ["disableWarnings"] = {},
    ["delayDLL"] = {},
    ["ignoreLibs"] = {},
    ["resFiles"] = {},
    ["pchSource"] = "",
    ["pchHeader"] = "",
    ["propertySheet"] = "",
    ["forceUsingFiles"] = "",
    ["resIncludeDirs"] = {},
    ["toolset"] = "",
    ["objdir"] = "",
    ["androidarch"] = "",
    ["SoName"] = "",
    ["sourceFiles"] = {},
    ["excludedSources"] = {}
  }
  
function getMapBuildOptionsKeys()
  return mapBuildOptionsKeys
end


function getMapBuildOptionsKeysDefaults()
  return mapBuildOptionsKeysDefaults
end


function printConfigMapHelper_PrintTable(tableToPrint,tabs)

  local tabChar = ""
  for i=0,tabs,1 do
    tabChar = tabChar .. "\t"
  end
  
  for key,val in pairs(tableToPrint) do
    local contentVals = ""
    if (printConfigMapHelper_ContainAnyValues(val)) then
      if (type(val) == "table") then
        if (type(val[1]) == "table" or val[1] == nil) then
          printf("%s[%s]", tabChar, key)
          printConfigMapHelper_PrintTable(val, tabs+1)
        else
          printf("%s[%s]", tabChar, key)
          printConfigMapHelper_aligned(val, key, tabs)
        end
      else
        printf("%s[%s]", tabChar, key)
        printConfigMapHelper_aligned(val, key, tabs)
      end
    end
  end
end


function printConfigMapHelper_aligned(str, key, tabs)
  local alignSpaces = ""
  tabs = tabs + 2
  --for i = 0,(tabs * 8) + ((((string.len(key) + 4) / 8) + 1) * 8),1 do
  for i = 0,(tabs * 8),1 do
    alignSpaces = alignSpaces .. " "
  end
  if (type(str) == "table") then
    for _, value in pairs(str) do
      printf(alignSpaces .. value)
    end
  else
    printf(alignSpaces .. str)
  end 
  --printf("%s[%s] = %s", tabChar, key, contentVals)
end


function printConfigMapHelper_ContainAnyValues(tableToPrint)
  local retVal = false
  
  if (type(tableToPrint) ~= nil) then 
    if type(tableToPrint) == "string" then
      if tableToPrint ~= ""  then
        retVal = true
      end
    elseif type(tableToPrint) == "table" then
      for key,val in pairs(tableToPrint) do
        if type(val) == "string" then
          if val ~= "" then
            retVal = true
          end
        elseif type(val) == "table" then
          retVal = printConfigMapHelper_ContainAnyValues(val)
        end
        
        if (retVal == true) then
          break
        end
      end
    end
  end
  
  return retVal
end

function printConfigMap(buildConfigMap)
  printf("Build config structure and content: ")
  printConfigMapHelper_PrintTable(buildConfigMap,0)
end

function tableContainsKey(localTable, keyToCheck)
  for key,val in pairs(localTable) do
    if (key == keyToCheck) then
      return true
    end
  end
  return false
end

function tableContainsValue(localTable, valueToCheck)
  for key,val in pairs(localTable) do
    if (val == valueToCheck) then
      return true
    end
  end
  return false
end

function validateBuildConfigMap(buildConfigMap, buildConfigs, platforms)
  
  invalidKeys = validateBuildConfigMap_helper(buildConfigMap, buildConfigs, platforms)
  
  printf("Found %s invalid keys in the build config map:\n", #invalidKeys)
  if #invalidKeys > 0 then
    invalidKeys = table.flatten(invalidKeys)
    printf("Found %s invalid keys in the build config map:\n", #invalidKeys)
    for key,val in pairs(invalidKeys) do
      printf("\t[%s]", val)
    end
  end
  
end

function validateBuildConfigMap_helper(buildConfigMap, buildConfigs, platforms)

  local invalidKeys = {}
  if (type(buildConfigMap) ~= "table") then
    return invalidKeys
  end
  
  for entry,buildConfigKey in pairs(buildConfigMap) do
    --printf("Checking entry: %s", entry)
    if (tableContainsValue(mapBuildOptionsKeys, entry) == false) and (tableContainsValue(buildConfigs, entry) == false) and (tableContainsValue(platforms, entry) == false) then
      printf("Key [%s] wasn't found in the valid entry list.", entry)
      if tableContainsValue(invalidKeys, entry) == false then
        table.insert(invalidKeys, entry)
      end
    end
    retVal = validateBuildConfigMap_helper(buildConfigKey, buildConfigs, platforms)
    if #retVal > 0 then
      retVal = table.flatten(retVal)
      for retValKey, retValValue in pairs(retVal) do
        if tableContainsValue(invalidKeys, retValValue) == false then
          table.insert(invalidKeys, retValValue)
        end
      end
    end
  end

  invalidKeys = table.flatten(invalidKeys)
  return invalidKeys

end


function getBuildConfigMap(buildConfigs, buildPlatforms)
  local buildConfigsMap = {}
  
  for _,key in pairs(mapBuildOptionsKeys) do
    buildConfigsMap[key] = {}
  end
  
  for _,key in pairs(buildConfigs) do
    buildConfigsMap[key] = {}
    for _,keyOptions in pairs(mapBuildOptionsKeys) do
      buildConfigsMap[key][keyOptions] = {}
    end
  end
  
  for _,key in pairs(buildPlatforms) do
    buildConfigsMap[key] = {}
    for _,keyOptions in pairs(mapBuildOptionsKeys) do
      buildConfigsMap[key][keyOptions] = {}
    end
    for _,keyBuildConfig in pairs(buildConfigs) do
      buildConfigsMap[key][keyBuildConfig] = {}
      for _,keyOptions in pairs(mapBuildOptionsKeys) do
        buildConfigsMap[key][keyBuildConfig][keyOptions] = {}
      end
    end
  end

  return buildConfigsMap
end

function getBuildConfigMapDefaults(buildConfigs, buildPlatforms)
  local buildConfigsMap = {}
  local buildConfig = table.flatten(buildConfigs)
  local buildPlatforms = table.flatten(buildPlatforms)
  
  for key,defaultVal in pairs(mapBuildOptionsKeysDefaults) do
    buildConfigsMap[key] = defaultVal
  end
  
  for _,key in pairs(buildConfigs) do
    buildConfigsMap[key] = {}
    for keyOptions, defaultVal in pairs(mapBuildOptionsKeysDefaults) do
      buildConfigsMap[key][keyOptions] = defaultVal
    end
  end
  
  if (buildPlatforms == nil or printConfigMapHelper_ContainAnyValues(buildPlatforms) == false ) then
    error("no platforms!!!!")
  end
  for _,key in pairs(buildPlatforms) do
    buildConfigsMap[key] = {}
    for keyOptions, defaultVal in pairs(mapBuildOptionsKeysDefaults) do
      buildConfigsMap[key][keyOptions] = defaultVal
    end
    for _,keyBuildConfig in pairs(buildConfigs) do
      buildConfigsMap[key][keyBuildConfig] = {}
      for keyOptions, defaultVal in pairs(mapBuildOptionsKeysDefaults) do
        buildConfigsMap[key][keyBuildConfig][keyOptions] = defaultVal
      end
    end
  end
  
  return buildConfigsMap
end

function tableCount(tableToCount)
  retVal = 0
  
  for key,val in pairs(tableToCount) do
    if val ~= nil then
      if (type(val) == "table") then
        retVal = retVal + tableCount(val)
      else
        retVal = retVal + 1
      end
    end
  end
  
  return retVal
end

-- It generates four different maps with the next content.
--  - General options               -> Options applied to any build config and platform
--  - Per build config              -> Options applied to a build config of any platform
--  - Per platform general options  -> Options applied to any build config of a platform
--  - Per platform and build config -> Specific options for build config and platform
function explodeConfigMap(configMap, buildConfigs, platforms)
  local mapOptions = {}
  local mapBuildConfig = {}
  local mapPlatformOptions = {}
  local mapPlatformBuildConfigOptions = {}
  local mapInvalidEntries = {}
  
  
  if (mapBuildOptionsKeys == nil) then printf("mapBuildOptionsKeys is nil!") end
  if (buildConfigs == nil) then printf("buildConfigs is nil!") end
  if (platforms == nil) then printf("platforms is nil!") end
  
  for key,val in pairs(configMap) do
    -- Add the value to the tables if it contains something.
    local validVal = false
    if ((type(val) == "table") and (tableCount(val) > 0)) or ((type(val) == "string") and (val:len() > 0)) then
      validVal = true
    end
    
    if validVal then
      if tableContainsValue(mapBuildOptionsKeys, key) then
        mapOptions[key] = val
        --table.insert(mapOptions, val)
      elseif tableContainsValue(buildConfigs, key) then
        mapBuildConfig[key] = val
        --table.insert(mapBuildConfig, val)
      elseif tableContainsValue(platforms, key) then
        printf("Table contains a platform value: [%s]", key)
        mapPlatformOptions[key] = {}
        mapPlatformBuildConfigOptions[key] = {}
        -- Check for option or build config
        for keyPlatform,valPlatform in pairs(val) do
          if tableContainsValue(mapBuildOptionsKeys, keyPlatform) then
            --printf("Table contains an option: [%s]", keyPlatform)
            mapPlatformOptions[key][keyPlatform] = valPlatform
            --table.insert(mapPlatformOptions[key], valPlatform)
          elseif tableContainsValue(buildConfigs, keyPlatform) then
            --printf("Table contains a build option val: [%s]", keyPlatform)
            mapPlatformBuildConfigOptions[key][keyPlatform] = valPlatform
            --table.insert(mapPlatformBuildConfigOptions[key], valPlatform)
          end
        end
      else
        if(mapInvalidEntries[key] == nil) then
          mapInvalidEntries[key] = 1
        else
          mapInvalidEntries[key] = mapInvalidEntries[key] + 1
        end
      end
    end
  end
  
  if tableCount(mapOptions) > 0 then
    printf("=========\nConfig map of general options:")
    printConfigMap(mapOptions)
    printf("=========")
  end
  
  if tableCount(mapBuildConfig) > 0 then
    printf("=========\nConfig map of build config general options:")
    printConfigMap(mapBuildConfig)
    printf("=========")
  end
  
  if tableCount(mapPlatformOptions) > 0 then
    printf("=========\nConfig map of platform general options:")
    printConfigMap(mapPlatformOptions)
    printf("=========")
  end
  
  if tableCount(mapPlatformBuildConfigOptions) > 0 then
    printf("=========\nConfig map of platform build config specific options:")
    printConfigMap(mapPlatformBuildConfigOptions)
    printf("=========")
  end
  
  if tableCount(mapInvalidEntries) > 0 then
    printf("=========\nConfig map contains unknown or non-permitted options => %s", tableCount(mapInvalidEntries))
    printConfigMap(mapInvalidEntries)
    printf("=========")
    
    error("Config map contains unknown or non-permitted options...")
  end
  
  return mapOptions, mapBuildConfig, mapPlatformOptions, mapPlatformBuildConfigOptions
end

function GetBuildIDESuffix( buildTarget )

   if buildTarget == "vs2008" then  return "90"    end
   if buildTarget == "vs2010" then  return "100"   end
   if buildTarget == "vs2012" then  return "110"   end
   if buildTarget == "xcode3" then  return ""     end
   if buildTarget == "xcode4" then  return ""     end
   
   return nil
end

-- Misc functions
verbosePrint = true
function PrintVerbose(outString)
  if verbosePrint and outString then
    printf(outString)
  end
end

function iif(exp, val_true, val_false)
  if (exp) == true then
      return val_true
  else  
      return val_false
  end  
end

function isDeclared(var)
  if var and var ~= {} and var ~= "" then return true end
  return false
end

function GetTargetExtension(outputType, platform)
  local err = ""
  if platform == "Xbox360" or platform == "Durango" then
    if outputType == "ConsoleApp" then
      return ".exe"
    elseif outputType == "SharedLib" then
      err = "Invalid output type [" .. outputType .. "] for platform [" .. platform .. "]"
    elseif outputType == "StaticLib" then
      return ".lib"
    end
  elseif platform == "PSP2" then
    if outputType == "ConsoleApp" then
      return ".self"
    elseif outputType == "SharedLib" then
      err = "Invalid output type [" .. outputType .. "] for platform [" .. platform .. "]"
    elseif outputType == "StaticLib" then
      return ".lib"
    end
  elseif platform == "PS3" then
    if outputType == "ConsoleApp" then
      return iif(bIsSPU == true, ".elf", ".self")
    elseif outputType == "SharedLib" then
      err = "Invalid output type [" .. outputType .. "] for platform [" .. platform .. "]"
    elseif outputType == "StaticLib" then
      return ".lib"
    end
  elseif platform == "Wii" then
    if outputType == "ConsoleApp" then
      return ".elf"
    elseif outputType == "SharedLib" then
      err = "Invalid output type [" .. outputType .. "] for platform [" .. platform .. "]"
    elseif outputType == "StaticLib" then
      return ".a"
    end
  elseif platform == "WiiU" then
    if outputType == "ConsoleApp" then
      return ".rpx"
    elseif outputType == "SharedLib" then
      return ".rpl"
    elseif outputType == "StaticLib" then
      return ".a"
    end
  elseif string.endswith(platform, "x32") or string.endswith(platform, "x64") or string.endswith(platform, "Arm") or string.endswith(platform, "any") or platform == "Metro" or platform == "Apollo" then
    if bIsEnginePlugin then
      return ".vPlugin"
    elseif outputType == "ConsoleApp" or outputType == "WindowedApp" then 
      return ".exe"
    elseif outputType == "SharedLib" then
      return ".dll"
    elseif outputType == "StaticLib" then
      return ".lib"
    end
  elseif platform == "Universal" or platform == "iOS" then
    if outputType == "ConsoleApp" or outputType == "WindowedApp" then
      return ".app"
    elseif outputType == "SharedLib" then
      return ".dll"
    elseif outputType == "StaticLib" then
      return ".a"
    end
  elseif platform == "Android" or platform == "iOS" then
    if outputType == "ConsoleApp" or outputType == "WindowedApp" then
      return ".so"
    elseif outputType == "SharedLib" then
      return ".so"
    elseif outputType == "StaticLib" then
      return ".a"
    end
  end
  
  if err == "" then
    err = "Undefined outputType and or platform: " .. outputType .. "|" .. platform
  end
  
  error("\n\n\tError: " .. err .. "\n\n", 0)
end

function GetDefinesByOutputType(outputType)

  if outputType == "SharedLib" then
    return definesSharedLib
  elseif outputType == "StaticLib" then
    return definesStaticLib
  elseif outputType == "ConsoleApp" then
    return {}
  end
  
  return {}
  
end

-- Excludes a list from another list. It breaks if no matching correspondence is found.
-- Returns: The source list without the elements in the excList
function excludeListFromList(srcList, excList)
    
    local finalSrcList = { }
    finalSrcList = srcList
    
    if excList and #excList > 0 then  
      for _, excludeValue in ipairs(excList) do
        local iIdx = 0
        local removedValue = nil
        for _, value in ipairs(finalSrcList) do
          iIdx = iIdx + 1
          if value == excludeValue then
            removedValue = table.remove(finalSrcList, iIdx)
            -- verification
            if removedValue ~= excludeValue then
              error("\n\n\tWRONG value WAS REMOVED FROM THE buildConfigs: " .. excludeValue[1] .. "<>" .. removedValue[1])
            end
            -----
            break
          end
        end
        
        -- verification
        if not removedValue then
          error("\n\n\tvalue TO EXCLUDE DOESN'T EXIST IN THE source list TABLE: " .. excludeValue)
        end
        -----
      end
    end
    
    return finalSrcList
    
end

function concatenateTableNoDups(tableOne, tableOther)
  local finalTable = {}
  local repeatedTable = {}
  finalTable = tableOne
  
  for i, v in pairs(finalOther) do
    if tableContainsValue(finalTable, v) == false then
      insert.table(finalTable, v)
    else
      insert.table(repeatedTable, v)
    end
  end
  
  printf("Table of repeated values:")
  printConfigMap(repeatedTable, 1)
  sys.exit(1)
  
end

-- Excludes a list from another list. It breaks if no matching correspondence is found.
-- Returns: The source list without the elements in the excList
function getNonMatchingExcludeListFromList(srcList, excList)
    
    local finalSrcList = { }
    local nonMatching = { }
    finalSrcList = srcList
    
    if excList and #excList > 0 then  
      for _, excludeValue in ipairs(excList) do
        local iIdx = 0
        local removedValue = nil
        for _, value in ipairs(finalSrcList) do
          iIdx = iIdx + 1
          if value == excludeValue then
            removedValue = table.remove(finalSrcList, iIdx)
            -- verification
            if removedValue ~= excludeValue then
              error("\n\n\tWRONG value WAS REMOVED FROM THE buildConfigs: " .. excludeValue[1] .. "<>" .. removedValue[1])
            end
            -----
            break
          end
        end
        
        -- verification
        if not removedValue then
          --error("\n\n\tvalue TO EXCLUDE DOESN'T EXIST IN THE source list TABLE: " .. excludeValue)
          table.insert(nonMatching, excludeValue)
        end
        -----
      end
    end
    
    return nonMatching
    
end

function getBaseDirFromPath(path)
  local countMatches = 0
  local retVal = ".\\"
  
  path = path:gsub("/", "\\")
  
  --PrintVerbose("Getting basedir from path => " .. path)
  
  if path:match("\\") then
    --PrintVerbose("Result of pathmatch: " .. path:match(".*\\(.*)"))
    --PrintVerbose("Result of pathfind pathmatch: " .. path:find(path:match(".*\\(.*)"), 1, true))
    
    retVal = path:sub(1, path:find(path:match(".*\\(.*)"), 1, true)-1)
  end
  
  --printf("Basedir of [%s] => [%s]", path, retVal)
  return retVal
end

function getBaseNameFromPath(path)
  local countMatches = 0
  local retVal = path
  
  path = path:gsub("/", "\\")
  
  --[[
  printf("\nPath to match: %s", path)
  printf("Path matched: %s", path:match(".*\\(.*)"))
  printf("String substed: %s", path:match(".*\\(.*)"))
  printf("Path founds: " .. path:find(path:match(".*\\(.*)"), 1, true))
  ]]
  
  if path:match("\\") then
    retVal = path:sub(path:find(path:match(".*\\(.*)"), 1, true))
  end
  
  --printf("Basename of [%s] => [%s]", path, retVal)
  
  return retVal
end

function populateFiles(path, errorOnMissingFile)
  local localErrorOnMissingFile = errorOnMissingFile or false
  local doRecursive = ""
  local pathToFiles = {}
  local baseDir = ".\\"
  local baseName = nil
  
  path = path:gsub("/", "\\")
  
  --printf("Populating file(s): %s", path)
  if path:match("%*%*") then
    path = path:gsub("%*%*", "%*")
    doRecursive = " /S"
  end
  --printf("Populating file(s) transformed: %s", path)
  
  baseDir = getBaseDirFromPath(path)
  baseName = getBaseNameFromPath(path)
  local commandToExecute = "forfiles /P " .. baseDir .. " /M " .. baseName .. doRecursive .. " /C \"cmd /c echo @relpath\" 2>&1"
    
  --printf("COMMAND: [%s]", commandToExecute)
  for file in io.popen(commandToExecute):lines() do
    local finalPathToFile = baseDir .. file:gsub("\"", ""):gsub("(%.\\)", "")
    local fileResult = file:gsub("\"", ""):gsub("(%.\\)", "")
    --printf("File brute: [%s]", finalPathToFile)
    if file:find("ERROR") then
      if localErrorOnMissingFile == true then
        error(string.format("ERROR. File not found => [%s]", baseDir .. baseName))
      else
        table.insert(pathToFiles, string.format("ERROR. File not found => [%s]", baseDir .. baseName))
      end
    else
      table.insert(pathToFiles, finalPathToFile)
    end
  end
  
  return pathToFiles
end

function writeExcludesTo(excludes, filename)
  if excludes and excludes ~= "" and excludes ~= { } and excludes ~= { "" } and filename and filename ~= "" then
    -- check that the table contains at least one valid entry.
    if #excludes > 0 then
      local containEntries = nil
      for _, entry in ipairs(excludes) do
        if entry ~= "" then
          containEntries = true
          break
        end
      end
      if containEntries then
        local file = io.open(filename, "w")
        if not file then
          print(file)
          error("Can not open file for writting: " .. filename)
        else
          for _, entry in ipairs(excludes) do
            if entry ~= "" then
              file:write(path.translate(entry) .. '\n')
            end
          end
          local res = file:close()
          if not res then
            error("Check file RES: " .. res)
          else
            PrintVerbose("Check file: " .. filename)
          end
        end
      end
    end
  end
end

function GetTargetPlatforms(platform)
  if (platform == "Windows") then
    return { "x32", "x64" }
  elseif (platform == "Android" or platform == "Android_ARM" or platform == "Android_x86" or platform == "Android_MIPS") then
    return { "Android" }
  else
    return { platform }
  end
end

function CleanVariables()

  buildConfigMap = {}

  projectBaseName = tempSlnPrefix .. ""
  projectName = projectBaseName .. buildSystemSuffix -- NOTE: For solutions/projects that shouldn
  projectLocation = ""
  projectGUID = ""
  outputFolder = ""
  outputTarget = projectName -- If this variable is not used the specific ones will be the used instead. Tipically this field will contain: projectName
  projectReferences = { }
  projectDependencies = { }
  projectPropertySheet = ""
  projectLanguage = ""
  projectNamespace = ""
  projectIcon = "" -- Relative path to the icon to be used in the generated application.
  projectNiceName = "" -- Name with which the project will appear inside a Visual Studio Solution.
  targetPlatform = targetPlatform or nil -- Windows, iOS, Android etc...

  projectBuildConfigs = { }
  buildConfigsForProject = {}
  buildPlatformsForProject = {}

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
  outputFolderDebugWii = ""
  outputFolderReleaseWii = ""
  outputFolderDebugDurango = ""
  outputFolderReleaseDurango = ""
  outputFolderDebugApolloArm  = ""
  outputFolderReleaseApolloArm = ""
  outputFolderDebugApolloX86  = ""
  outputFolderReleaseApolloX86 = ""
  outputFolderDebugMetroArm  = ""
  outputFolderReleaseMetroArm = ""
  outputFolderDebugMetroX86  = ""
  outputFolderReleaseMetroX86 = ""
  outputFolderDebugMetroX64  = ""
  outputFolderReleaseMetroX64 = ""
  outputFolderDebugWiiU = ""
  outputFolderReleaseWiiU = ""

  layoutFolderDebugDurango = ""
  layoutFolderReleaseDurango = ""
  layoutFolderDebugApolloArm  = ""
  layoutFolderReleaseApolloArm = ""
  layoutFolderDebugApolloX86  = ""
  layoutFolderReleaseApolloX86 = ""
  layoutFolderDebugMetroArm  = ""
  layoutFolderReleaseMetroArm = ""
  layoutFolderDebugMetroX86  = ""
  layoutFolderReleaseMetroX86 = ""
  layoutFolderDebugMetroX64  = ""
  layoutFolderReleaseMetroX64 = ""

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
  outputTargetDebugWii = ""
  outputTargetReleaseWii = ""
  outputTargetDebugDurango = ""
  outputTargetReleaseDurango = ""
  outputTargetDebugApolloArm  = ""
  outputTargetReleaseApolloArm = ""
  outputTargetDebugApolloX86  = ""
  outputTargetReleaseApolloX86 = ""
  outputTargetDebugMetroArm  = ""
  outputTargetReleaseMetroArm = ""
  outputTargetDebugMetroX86  = ""
  outputTargetReleaseMetroX86 = ""
  outputTargetDebugMetroX64  = ""
  outputTargetReleaseMetroX64 = ""
  outputTargetDebugWiiU = ""
  outputTargetReleaseWiiU = ""
  
  -- Specific import library name & dir
  outputImportLibDebugWin32 = ""
  outputImportLibDebugDX11Win32 = ""
  outputImportLibDebugNoXIWin32 = ""
  outputImportLibDebugX64 = ""
  outputImportLibDebugDX11X64 = ""
  outputImportLibDebugNoXIX64 = ""
  outputImportLibReleaseWin32 = ""
  outputImportLibReleaseDX11Win32 = ""
  outputImportLibReleaseNoXIWin32 = ""
  outputImportLibReleaseX64 = ""
  outputImportLibReleaseDX11X64 = ""
  outputImportLibReleaseNoXIX64 = ""
  outputImportLibDebugXbox360 = ""
  outputImportLibDebugPS3 = ""
  outputImportLibDebugPSP2 = ""
  outputImportLibDebugWii = ""
  outputImportLibDebugWiiU = ""
  outputImportLibReleaseXbox360 = ""
  outputImportLibReleasePS3 = ""
  outputImportLibReleasePSP2 = ""
  outputImportLibReleaseWii = ""
  outputImportLibReleaseWiiU = ""
  outputImportLibDebugDurango = ""
  outputImportLibReleaseDurango = ""
  outputImportLibDebugApolloArm  = ""
  outputImportLibReleaseApolloArm = ""
  outputImportLibDebugApolloX86  = ""
  outputImportLibReleaseApolloX86 = ""
  outputImportLibDebugMetroArm  = ""
  outputImportLibReleaseMetroArm = ""
  outputImportLibDebugMetroX86  = ""
  outputImportLibReleaseMetroX86 = ""
  outputImportLibDebugMetroX64  = ""
  outputImportLibReleaseMetroX64 = ""

  --------------------------------------------------------------------------------------
  -- SPECIAL WII SECTION !!!!!!
  buildCommandLineWii = { }

  buildCommandLineDebugWii = { buildCommandLineWii }

  buildCommandLineReleaseWii = { buildCommandLineWii }

  cleanCommandLineDebugWii = { }
  cleanCommandLineReleaseWii = cleanCommandLineDebugWii

  definesWii = { "" } -- Defines for the Wii Platform
  definesDebugWii = { "" }
  definesReleaseWii = { "" }

  flagsAllWii = { "" }-- 
  flagsDebugWii = { flagsAllWii }
  flagsReleaseWii = { flagsAllWii }
  --------------------------------------------------------------------------------------

  -- PREPROCESSOR DEFINITIONS ----------------------------------------------------------
  -- Platform defines
  definesPS3 = { }                                               -- Defines for PS3 platform
  definesPSP2 = { }                                            -- Defines for PSP2 platform
  definesX86 = { } -- Defines for Windows platform
  definesX64 = ""                                                                                     -- Defines for Windows x64 platform
  definesXbox360 = { }                         -- Defines for Xbox360 platform
  definesDurango = { } 
  definesApolloArm = { } 
  definesApolloX86 = { } 
  definesMetroArm = { } 
  definesMetroX86 = { } 
  definesMetroX64 = { } 

  -- Build configurations defines
  definesSharedLib = ""  -- Defines for a .dll output type
  definesStaticLib = ""      -- Defines for a .lib output type
  definesStaticLibMT = ""      -- Defines for a .lib output type
  definesDebug = ""             -- Defines for all Debug builds
  definesRelease = ""           -- Defines for all Release builds
  definesDX11 = ""            -- Defines for DX11 builds
  definesDebugDX11 = {}            -- Defines for DX11 builds
  definesReleaseDX11 = {}            -- Defines for DX11 builds

  definesDebugX86 = ""                -- Defines for Debug Windows 32bits platforms only
  definesReleaseX86 = ""              -- Defines for Release Windows 32bits platforms only

  definesDebugX64 = ""                -- Defines for Debug Windows 64bits platforms only
  definesReleaseX64 = ""              -- Defines for Release Windows 64bits platforms only

  definesDebugPS3 = ""  -- Defines for Debug PS3 builds
  definesReleasePS3 = ""              -- Defines for Release PS3 builds

  definesDebugPSP2 = ""   -- Defines for Debug PSP2 builds
  definesReleasePSP2 = "" -- Defines for Release PSP2 builds

  definesDebugXbox360 = ""            -- Defines for Debug Xbox360 builds
  definesReleaseXbox360 = ""          -- Defines for Release Xbox360 builds
  
  definesDebugDurango = "" 
  definesDebugApolloArm = ""
  definesDebugApolloX86 = ""
  definesDebugMetroArm = ""
  definesDebugMetroX86 = ""
  definesDebugMetroX64 = ""
  
  definesReleaseDurango = ""
  definesReleaseApolloArm = ""
  definesReleaseApolloX86 = ""
  definesReleaseMetroArm = ""
  definesReleaseMetroX86 = ""
  definesReleaseMetroX64 = ""
  
  definesWiiU = { } -- Defines for the WiiU Platform
  definesDebugWiiU = { }
  definesReleaseWiiU = { }
  --------------------------------------------------------------------------------------

  -- Output Type. Can be SharedLib, StaticLib, ConsoleApp
  bIsEnginePlugin = false
  outputTypeWin = ""
  outputTypeXbox360 = ""
  outputTypePS3 = ""
  outputTypePSP2 = ""
  outputTypeWii = ""
  outputTypeWiiU = ""
  outputTypeDurango = ""
  outputTypeApollo = ""
  outputTypeMetro = ""

  -- Specific PS3 section
  targetExtensionExePS3 = "" -- Can be .self or .elf
  targetExtensionExePSP2 = "" -- Can be .self or .elf
  bIsSPU = false -- Indicates that the project is a SPU project

  -- Include dirs
  includeDirsCommon    = { }
  includeDirsWin32     = { includeDirsCommon }
  includeDirsX64       = { includeDirsWin32 }
  includeDirsXbox360   = { includeDirsCommon }
  includeDirsPS3       = { includeDirsCommon }
  includeDirsPSP2     = { includeDirsCommon }
  includeDirsWiiU      = { includeDirsCommon }
  includeDirsDurango    = { includeDirsCommon }
  includeDirsApolloArm    = { includeDirsCommon }
  includeDirsApolloX86    = { includeDirsCommon }
  includeDirsMetroArm    = { includeDirsCommon }
  includeDirsMetroX86    = { includeDirsCommon }
  includeDirsMetroX64    = { includeDirsCommon }

  -- Lib dirs
  libDirsCommon        = { }
  libDirsStaticWin32   = { }
  libDirsWin32         = { }
  libDirsStaticX64     = { }
  libDirsX64           = { }
  libDirsXbox360       = { }
  libDirsDurango       = { } 
  libDirsApolloArm     = { } 
  libDirsApolloX86     = { } 
  libDirsMetroArm      = { } 
  libDirsMetroX86      = { } 
  libDirsMetroX64      = { } 
  libDirsPS3           = { }
  libDirsPSP2          = { }
  libDirsWiiU          = { }
  
  libDirsDebugWin32	 = { }
  libDirsReleaseWin32  = { }
  libDirsDebugX64 	 = {  }
  libDirsReleaseX64    = { }

  libDirsDebugXbox360      = { }
  libDirsReleaseXbox360     = { }
  libDirsDebugPS3      = { }
  libDirsReleasePS3     = { }
  libDirsDebugPSP2      = { }
  libDirsReleasePSP2     = { }
  libDirsDebugWiiU       = { }
  libDirsReleaseWiiU     = { }
  
  libDirsDebugDurango       = { } 
  libDirsDebugApolloArm     = { } 
  libDirsDebugApolloX86     = { } 
  libDirsDebugMetroArm      = { } 
  libDirsDebugMetroX86      = { } 
  libDirsDebugMetroX64      = { } 
  
  libDirsReleaseDurango       = { } 
  libDirsReleaseApolloArm     = { } 
  libDirsReleaseApolloX86     = { } 
  libDirsReleaseMetroArm      = { } 
  libDirsReleaseMetroX86      = { } 
  libDirsReleaseMetroX64      = { } 
  
  
  -- Link libs
  libLinkAllWindows          = { } -- Helper variable. For C# projects it must contain the referenced assemblies. 
  libLinkShared              = { }
  libLinkDx11                = { }

  libLinkDebugAllWin32       = { }
  libLinkDebugAllx64         = { }
  libLinkReleaseAllWin32     = { }
  libLinkReleaseAllx64       = { }
  libLinkReleasePAllWin      = { }
  --
  libLinkDebugStaticWin32    = { libLinkAllWindows, libLinkDebugAllWin32 }
  libLinkDebugStaticMTWin32  = libLinkDebugStaticWin32
  libLinkDebugDx9Win32       = { libLinkAllWindows, libLinkDebugAllWin32, libLinkShared }
  libLinkDebugDx11Win32      = { libLinkAllWindows, libLinkDebugAllWin32, libLinkShared, libLinkDx11 }
  libLinkDebugNoXIWin32      = { libLinkAllWindows, libLinkDebugAllWin32, libLinkShared }

  libLinkReleaseStaticWin32  = { libLinkAllWindows, libLinkReleaseAllWin32 }
  libLinkReleaseStaticMTWin32= libLinkReleaseStaticWin32
  libLinkReleaseDx9Win32     = { libLinkAllWindows, libLinkReleaseAllWin32, libLinkShared }
  libLinkReleaseDx11Win32    = { libLinkAllWindows, libLinkReleaseAllWin32, libLinkShared, libLinkDx11 }
  libLinkReleaseNoXIWin32    = { libLinkAllWindows, libLinkReleaseAllWin32, libLinkShared }

  libLinkDebugStaticX64      = { libLinkAllWindows, libLinkDebugAllx64 }
  libLinkDebugStaticMTX64      = libLinkDebugStaticX64
  libLinkDebugDx9x64         = { libLinkAllWindows, libLinkDebugAllx64, libLinkShared }
  libLinkDebugDx11x64        = { libLinkAllWindows, libLinkDebugAllx64, libLinkShared, libLinkDx11 }
  libLinkDebugNoXIx64        = { libLinkAllWindows, libLinkDebugAllx64, libLinkShared }

  libLinkReleaseStaticX64    = { libLinkAllWindows, libLinkReleaseAllx64 }
  libLinkReleaseStaticMTX64  = libLinkReleaseStaticX64
  libLinkReleaseDx9x64       = { libLinkAllWindows, libLinkReleaseAllx64, libLinkShared }
  libLinkReleaseDx11x64      = { libLinkAllWindows, libLinkReleaseAllx64, libLinkShared, libLinkDx11 }
  libLinkReleaseNoXIx64      = { libLinkAllWindows, libLinkReleaseAllx64, libLinkShared }

  libLinkDebugXbox360        = ""
  libLinkReleaseXbox360      = ""

  libLinkDebugPS3            = ""
  libLinkReleasePS3          = ""

  libLinkDebugPSP2            = ""
  libLinkReleasePSP2          = ""

  libLinkDebugDurango      = ""
  libLinkDebugApolloArm    = ""
  libLinkDebugApolloX86    = ""
  libLinkDebugMetroArm     = ""
  libLinkDebugMetroX86     = ""
  libLinkDebugMetroX64     = ""

  libLinkReleaseDurango      = ""
  libLinkReleaseApolloArm    = ""
  libLinkReleaseApolloX86    = ""
  libLinkReleaseMetroArm     = ""
  libLinkReleaseMetroX86     = ""
  libLinkReleaseMetroX64     = ""

  libLinkDebugWiiU            = ""
  libLinkReleaseWiiU          = ""
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
  stackReserveDebugDurango      = ""
  stackReserveDebugApolloArm    = ""
  stackReserveDebugApolloX86    = ""
  stackReserveDebugMetroArm     = ""
  stackReserveDebugMetroX86     = ""
  stackReserveDebugMetroX64     = ""
  stackReserveReleaseDurango      = ""
  stackReserveReleaseApolloArm    = ""
  stackReserveReleaseApolloX86    = ""
  stackReserveReleaseMetroArm     = ""
  stackReserveReleaseMetroX86     = ""
  stackReserveReleaseMetroX64     = ""
  
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
  stackCommitDebugDurango      = ""
  stackCommitDebugApolloArm    = ""
  stackCommitDebugApolloX86    = ""
  stackCommitDebugMetroArm     = ""
  stackCommitDebugMetroX86     = ""
  stackCommitDebugMetroX64     = ""
  stackCommitReleaseDurango      = ""
  stackCommitReleaseApolloArm    = ""
  stackCommitReleaseApolloX86    = ""
  stackCommitReleaseMetroArm     = ""
  stackCommitReleaseMetroX86     = ""
  stackCommitReleaseMetroX64     = ""

  buildTempDir = "intermediates"
  callConvention = ""

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
  --]]
  flagsStatic = { }

  flagsAllWindows = { }
  flagsDebugAllWindows = { }
  flagsReleaseAllWindows = { }

  flagsDebugWin32 = { flagsAllWindows, flagsDebugAllWindows }
  flagsReleaseWin32 = { flagsAllWindows, flagsReleaseAllWindows }
  flagsDebugX64 = { flagsAllWindows, flagsDebugAllWindows }
  flagsReleaseX64 = { flagsAllWindows, flagsReleaseAllWindows }
  flagsStaticWin = ""
  flagsStaticMTWin = { flagsStatic }

  flagsAllXbox360 = { }
  flagsDebugXbox360 = { flagsAllXbox360, flagsStatic }
  flagsReleaseXbox360 = { flagsAllXbox360, flagsStatic }

  flagsAllPS3 = { }
  flagsDebugPS3 = { flagsAllPS3, flagsStatic }
  flagsReleasePS3 = { flagsAllPS3, flagsStatic }

  flagsAllPSP2 = { }
  flagsDebugPSP2 = { flagsAllPSP2, flagsStatic }
  flagsReleasePSP2 = { flagsAllPSP2, flagsStatic }

  flagsAllDurango = { }
  flagsDebugDurango = { flagsAllDurango, flagsStatic }
  flagsReleaseDurango = { flagsAllDurango, flagsStatic }
  
  flagsAllApolloArm = { }
  flagsDebugApolloArm = { flagsAllApolloArm, flagsStatic }
  flagsReleaseApolloArm = { flagsAllApolloArm, flagsStatic }
  
  flagsAllApolloX86 = { }
  flagsDebugApolloX86 = { flagsAllApolloX86, flagsStatic }
  flagsReleaseApolloX86 = { flagsAllApolloX86, flagsStatic }
  
  flagsAllMetroArm = { }
  flagsDebugMetroArm = { flagsAllMetroArm, flagsStatic }
  flagsReleaseMetroArm = { flagsAllMetroArm, flagsStatic }
  
  flagsAllMetroX86 = { }
  flagsDebugMetroX86 = { flagsAllMetroX86, flagsStatic }
  flagsReleaseMetroX86 = { flagsAllMetroX86, flagsStatic }

  flagsAllMetroX64 = { }
  flagsDebugMetroX64 = { flagsAllMetroX64, flagsStatic }
  flagsReleaseMetroX64 = { flagsAllMetroX64, flagsStatic }

  flagsAllWiiU = { }
  flagsDebugWiiU = { flagsAllWiiU, flagsStatic }
  flagsReleaseWiiU = { flagsAllWiiU, flagsStatic }
  
  -- additional build options ---
  buildOptAllWin = { } -- Prog. Database Debug Info. 
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

  buildOptAllDurango = { }
  buildOptDebugDurango =     { buildOptAllDurango }
  buildOptReleaseDurango =   { buildOptAllDurango }
  
  buildOptAllApolloArm = { }
  buildOptDebugApolloArm  =     { buildOptAllApolloArm }
  buildOptReleaseApolloArm  =   { buildOptAllApolloArm }
  
  buildOptAllApolloX86 = { }
  buildOptDebugApolloX86  =     { buildOptAllApolloX86 }
  buildOptReleaseApolloX86  =   { buildOptAllApolloX86 }
  
  buildOptAllMetroArm = { }
  buildOptDebugMetroArm  =     { buildOptAllMetroArm }
  buildOptReleaseMetroArm  =   { buildOptAllMetroArm }
  
  buildOptAllMetroX86 = { }
  buildOptDebugMetroX86  =     { buildOptAllMetroX86 }
  buildOptReleaseMetroX86  =   { buildOptAllMetroX86 }
  
  buildOptAllMetroX64 = { }
  buildOptDebugMetroX64  =     { buildOptAllMetroX64 }
  buildOptReleaseMetroX64  =   { buildOptAllMetroX64 }
  
  buildOptAllPS3 = { }
  buildOptDebugPS3 =   { buildOptAllPS3 }
  buildOptReleasePS3 = { buildOptAllPS3 }

  buildOptAllPSP2 = { }
  buildOptDebugPSP2 = { buildOptAllPSP2 }
  buildOptReleasePSP2 = { buildOptAllPSP2 }

  buildOptAllWiiU = { }
  buildOptDebugWiiU = { buildOptAllWiiU }
  buildOptReleaseWiiU = { buildOptAllWiiU }

  -- Pre-build command
  preBuildWin = ""  -- Prebuild step for C# projects
  preBuildDebugWin = ""
  preBuildReleaseWin = ""
  preBuildDebugWinX64 = ""
  preBuildReleaseWinX64 = ""
  preBuildXbox360 = ""
  preBuildPS3 = ""
  preBuildPSP2 = ""

  preBuildDurango      = ""
  preBuildApolloArm    = ""
  preBuildApolloX86    = ""
  preBuildMetroArm     = ""
  preBuildMetroX86     = ""
  preBuildMetroX64     = ""

  preBuildWiiU = ""

  preBuildDescWin = "Executing Pre-Build Step..."
  preBuildDescWinX64 = "Executing Pre-Build Step..."
  preBuildDescXbox360 = "Executing Pre-Build Step..."
  preBuildDescPS3 = "Executing Pre-Build Step..."
  preBuildDescPSP2 = "Executing Pre-Build Step..."
  preBuildDescWiiU = "Executing Pre-Build Step..."

  -- Post-build command
  postBuildWin = ""
  postBuildNoXI = ""
  postBuildNoXIX64 = ""
  postBuildXbox360 = ""
  postBuildPS3 = ""
  postBuildPSP2 = ""

  postBuildDurango      = ""
  postBuildApolloArm    = ""
  postBuildApolloX86    = ""
  postBuildMetroArm     = ""
  postBuildMetroX86     = ""
  postBuildMetroX64     = ""
  
  postBuildWiiU = ""

  postBuildDescWin = "Executing Post-Build Step..."
  postBuildDescNoXI = ""
  postBuildDescXbox360 = "Executing Post-Build Step..."
  postBuildDescPS3 = "Executing Post-Build Step..."
  postBuildDescPSP2 = "Executing Post-Build Step..."
  postBuildDescWiiU = "Executing Post-Build Step..."

  -- additional linker options ---
  linkOptAllStaticWin = { }
  linkOptDebugNonStaticWin = { }
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

  linkOptDebugDurango      = ""
  linkOptDebugApolloArm    = ""
  linkOptDebugApolloX86    = ""
  linkOptDebugMetroArm     = ""
  linkOptDebugMetroX86     = ""
  linkOptDebugMetroX64     = ""
  linkOptReleaseDurango      = ""
  linkOptReleaseApolloArm    = ""
  linkOptReleaseApolloX86    = ""
  linkOptReleaseMetroArm     = ""
  linkOptReleaseMetroX86     = ""
  linkOptReleaseMetroX64     = ""
  
  linkOptDebugWiiU = ""
  linkOptReleaseWiiU = ""

  -- Disable warnings ---------------------------------------
  disableWarningsDebugWin32 = ""
  disableWarningsReleaseWin32 = ""

  disableWarningsDebugX64 = ""
  disableWarningsReleaseX64 = ""

  disableWarningsDebugXbox360 = ""
  disableWarningsReleaseXbox360 = ""

  disableWarningsDebugPS3 = ""
  disableWarningsReleasePS3 = ""

  disableWarningsDebugPSP2 = { }
  disableWarningsReleasePSP2 = { }
  
  disableWarningsDebugDurango      = ""
  disableWarningsDebugApolloArm    = ""
  disableWarningsDebugApolloX86    = ""
  disableWarningsDebugMetroArm     = ""
  disableWarningsDebugMetroX86     = ""
  disableWarningsDebugMetroX64     = ""
  disableWarningsReleaseDurango      = ""
  disableWarningsReleaseApolloArm    = ""
  disableWarningsReleaseApolloX86    = ""
  disableWarningsReleaseMetroArm     = ""
  disableWarningsReleaseMetroX86     = ""
  disableWarningsReleaseMetroX64     = ""
  
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

  forcedUsingFilesDebugDurango      = ""
  forcedUsingFilesDebugApolloArm    = ""
  forcedUsingFilesDebugApolloX86    = ""
  forcedUsingFilesDebugMetroArm     = ""
  forcedUsingFilesDebugMetroX86     = ""
  forcedUsingFilesDebugMetroX64     = ""
  forcedUsingFilesReleaseDurango      = ""
  forcedUsingFilesReleaseApolloArm    = ""
  forcedUsingFilesReleaseApolloX86    = ""
  forcedUsingFilesReleaseMetroArm     = ""
  forcedUsingFilesReleaseMetroX86     = ""
  forcedUsingFilesReleaseMetroX64     = ""

  -----------------------------------------------------------

  ------------------------------------
  ---- Windows specific --------------
  -- Delayed .dll loads
  delayDllCommon    =     { }
  delayDllXICommon  =     { }
  delayDebugWin32   =     { delayDllCommon, delayDllXICommon }
  delayDebugDX11Win32 =   { delayDllCommon, delayDllXICommon }
  delayDebugNoXIWin32 =   { delayDllCommon }

  delayReleaseWin32   =    { delayDllCommon, delayDllXICommon }
  delayReleaseDX11Win32 =  { delayDllCommon, delayDllXICommon }
  delayReleaseNoXIWin32 =  { delayDllCommon }

  delayDebugX64   =      { delayDllCommon, delayDllXICommon }
  delayDebugDX11X64 =    { delayDllCommon, delayDllXICommon }
  delayDebugNoXIX64 =    { delayDllCommon }

  delayReleaseX64   =    { delayDllCommon, delayDllXICommon }
  delayReleaseDX11X64 =  { delayDllCommon, delayDllXICommon }
  delayReleaseNoXIX64 =  { delayDllCommon }

  -- Ignored libs
  ignoreDefaultLibsAll = { }
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
  
  ignoreDefaultLibsDebugDurango = { ignoreDefaultLibsAll }
  ignoreDefaultLibsReleaseDurango = { ignoreDefaultLibsAll }
  ignoreDefaultLibsDebugApolloArm = { ignoreDefaultLibsAll }
  ignoreDefaultLibsReleaseApolloArm = { ignoreDefaultLibsAll }
  ignoreDefaultLibsDebugApolloX86 = { ignoreDefaultLibsAll }
  ignoreDefaultLibsReleaseApolloX86 = { ignoreDefaultLibsAll }
  ignoreDefaultLibsDebugMetroArm = { ignoreDefaultLibsAll }
  ignoreDefaultLibsReleaseMetroArm = { ignoreDefaultLibsAll }
  ignoreDefaultLibsDebugMetroX86 = { ignoreDefaultLibsAll }
  ignoreDefaultLibsReleaseMetroX86 = { ignoreDefaultLibsAll }
  ignoreDefaultLibsDebugMetroX64 = { ignoreDefaultLibsAll }
  ignoreDefaultLibsReleaseMetroX64 = { ignoreDefaultLibsAll }
  
  ---- Windows Specific --------------
  ------------------------------------

  -- Misc
  culture = "" -- for the resource compiler 1031 == 0x407 Germany
  includePathResCompilerWindows = {}

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

  -- WARNING: Be sure that the filename case matches the filename you write here.

  sourceHeaderPCH = ""
  sourcePCH = ""

  excludedSources = {}
  excludedSourcesWindows = { }
  excludedSourcesWindowsNoXI = { }
  excludedSourcesMac = { }
  excludedSourcesXbox360 = { }
  excludedSourcesDurango = { }
  excludedSourcesApolloArm = { }
  excludedSourcesApolloX86 = { }
  excludedSourcesMetroArm = { }
  excludedSourcesMetroX86 = { }
  excludedSourcesMetroX64 = { }
  excludedSourcesPS3 = { }
  excludedSourcesPSP2 = { }
  excludedSourcesWiiU = { "" }
  excludedSourcesWiiUBaseLocation = ""
  

  sourceFiles= { }

  sourcesNotUsingPCH = { }
  
  resourceFiles = { }
  
  -- Undefine again the selected configurations to be build.
  includeBuildConfigs = nil -- Per project active build configurations
  excludeBuildConfigs = nil -- Per project inactive build configurations
  mapBuildConfigs = nil
  
  -- Custom Build Step (file specific and per-build config)
  fileCustomBuildTool = nil
  -- IE:
  --fileCustomBuildCommandLine = {
  --    ["**.i"] = {},
  --    ["**.shader"] = {},
  --  }
  --fileCustomBuildCommandLine["**.i"]["CommandLine"] = { "command line 1", "command line 2", "command line 3" }
  --fileCustomBuildCommandLine["**.i"]["Outputs"] = { "vision types", "vision types2", "visiontypes3" }
  --fileCustomBuildCommandLine["**.i"]["Dependencies"] = { "vision types", "vision types2", "visiontypes3" }
  --
  --fileCustomBuildCommandLine["**.shader"]["CommandLine"] = { "command line 1", "command line 2", "command line 3" }
  --fileCustomBuildCommandLine["**.shader"]["Outputs"] = { "vision types", "vision types2", "visiontypes3" }
  --fileCustomBuildCommandLine["**.shader"]["Dependencies"] = { "MyFile001.cpp", "MyFile002.cpp", "MyFile003.cpp" }
  
  -- NOTE: If using wildcards be sure to create the entries prior to the file specific ones. Otherwise, if the extension matches the one of the file specific entry, it will be overwritten.
  ---------------------------------------------------------------------------------------------------------
    
end

buildSystem = _ACTION   -- _ACTION contains the target build system we are generating
buildSystemSuffix = "" --GetBuildIDESuffix( buildSystem )
printf("Build System: %s", buildSystem)

outputTypeDLL = "SharedLib"
outputTypeLIB = "StaticLib"
-------------


-- DEFINE HERE THE SOLUTION's CONFIGURATIONS & PLATFORMS--
buildConfigs = nil
buildPlatforms = nil

--tempSlnPrefix = "PRE" -- Temporary prefix for the project/solution names during the testing implementation.
tempSlnPrefix = ""

-- Active/Inactive project configurations. NOTE: You should define this variable before including the project script file in the list of the solution's project
includeBuildConfigs = nil -- Per project active build configurations
excludeBuildConfigs = nil -- Per project inactive build configurations


-----------------------------------------------------------------------------------------------------------------------------
-- Third Party --------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
function addPostfix(postfix, prefixArray)
  local new_array = {}
  for i,v in ipairs(prefixArray) do
    new_array[i] = v .. postfix
  end
  return new_array
end

-- PSVita SDK
libLinkReleasePSVitaSDK = { "-lSceGxm_stub", "-lSceDisplay_stub", "-lSceCtrl_stub", "-lSceSysmodule_stub", "-lScePerf_stub", "-lSceRazorCapture_stub_weak", "-lSceNet_stub", "-lSceNetCtl_stub", "-lm_stub", "-lSceTouch_stub", "-lSceMotion_stub", "-lSceRtc_stub", "-lSceCommonDialog_stub", "-lSceAppUtil_stub" }
libLinkDebugPSVitaSDK   = { libLinkReleasePSVitaSDK, "-lSceDbg_stub" }

-- Durango SDK
libLinkReleaseDurangoXDK = {  "xswaplib", "xinput", "d3d11", "d3dcompiler", "ws2_32", "runtimeobject", "mincore", "mincore_legacy", "mincore_obsolete", "user32" }
libLinkDebugDurangoXDK = { libLinkReleaseDurangoXDK }

-- Cafe SDK WiiU
libLinkCommonWiiUSDK = {
    "coredyn.a",
    "pad.a",
    "gfd.a",
    "mtx.a",
    "vpad.a",
    "vpadbase.a",
    "wg.a",
    "gx2.a",
    "avm.a",
    "tcl.a",
    "tve.a",
    "dc.a",
    "nsysccr.a",
    "nsysnet.a",
    "nn_ac.a",
    "padscore.a",
    "sci.a",
    "nn_util.a",
    "nn_erreula_static.a",
    "proc_ui.a",
    "nn_save.a",
    "axfx.a",
    "snd_core.a"
}
libLinkDebugWiiUSDK = { libLinkCommonWiiUSDK, "gx2spark.a" }
libLinkReleaseWiiUSDK = { libLinkCommonWiiUSDK }

--Havok
havokVersion = "2012.2"
vslibpath = iif(buildSystem == "vs2012", "vs11", iif(buildSystem == "vs2010", "vs2010", "net_9-0" ) )
havokBaseDirs = { "$(VISION_HAVOK_SDK_DIR)", "../../ThirdParty/Havok/" .. havokVersion, "$(HAVOK_THIRDPARTY_DIR)/redistsdks/Havok/" .. havokVersion }

havokIncludeDirs 			= addPostfix( "/Source", havokBaseDirs )
havokIncludeDirsSPU 		= addPostfix( "/Source", havokBaseDirs )
havokLibDirsDebugWin32		= addPostfix( "/Lib/win32_" .. vslibpath .. "/dev_dll", havokBaseDirs )
havokLibDirsReleaseWin32   	= addPostfix( "/Lib/win32_" .. vslibpath .. "/release_dll", havokBaseDirs )
havokLibDirsDebugX64		= addPostfix( "/Lib/x64_" .. vslibpath .. "/dev_dll", havokBaseDirs )
havokLibDirsReleaseX64   	= addPostfix( "/Lib/x64_" .. vslibpath .. "/release_dll", havokBaseDirs )
havokLibDirsDebugXbox360	= addPostfix( "/Lib/xbox360_" .. vslibpath .. "/dev_dll", havokBaseDirs )
havokLibDirsReleaseXbox360  = addPostfix( "/Lib/xbox360_" .. vslibpath .. "/release_dll", havokBaseDirs )
havokLibDirsDebugPS3        = addPostfix( "/Lib/ps3_" .. vslibpath .. "/dev_snc", havokBaseDirs )
havokLibDirsReleasePS3      = addPostfix( "/Lib/ps3_" .. vslibpath .. "/release_snc", havokBaseDirs )
havokLibDirsDebugSPU        = addPostfix( "/Lib/spu_" .. vslibpath .. "/" .. "dev" .. iif(buildSystem == "vs2010", "_gcc", "" ) , havokBaseDirs )
havokLibDirsReleaseSPU      = addPostfix( "/Lib/spu_" .. vslibpath .. "/" .. "release" .. iif(buildSystem == "vs2010", "_gcc", "" ) , havokBaseDirs )
havokLibDirsDebugPSP2       = addPostfix( "/Lib/psvita_net_9-0/dev", havokBaseDirs )
havokLibDirsReleasePSP2     = addPostfix( "/Lib/psvita_net_9-0/release", havokBaseDirs )
havokLibDirsDebugWiiU       = addPostfix( "/Lib/wiiu_vs2010/dev", havokBaseDirs )
havokLibDirsReleaseWiiU     = addPostfix( "/Lib/wiiu_vs2010/release", havokBaseDirs )

havokLibDirsDebugDurango	= addPostfix( "/Lib/durango_" .. vslibpath .. "/dev_dll", havokBaseDirs )
havokLibDirsReleaseDurango  = addPostfix( "/Lib/durango_" .. vslibpath .. "/release_dll", havokBaseDirs )
havokLibDirsDebugApollo	= addPostfix( "/Lib/apollo_arm_" .. vslibpath .. "/dev_dll", havokBaseDirs )
havokLibDirsReleaseApollo  = addPostfix( "/Lib/apollo_arm_" .. vslibpath .. "/release_dll", havokBaseDirs )
havokLibDirsDebugApolloEmu	= addPostfix( "/Lib/apollo_x86_" .. vslibpath .. "/dev_dll", havokBaseDirs )
havokLibDirsReleaseApolloEmu  = addPostfix( "/Lib/apollo_x86_" .. vslibpath .. "/release_dll", havokBaseDirs )
havokLibDirsDebugMetroX86	= addPostfix( "/Lib/metro_x86_" .. vslibpath .. "/dev_dll", havokBaseDirs )
havokLibDirsReleaseMetroX86  = addPostfix( "/Lib/metro_x86_" .. vslibpath .. "/release_dll", havokBaseDirs )
havokLibDirsDebugMetroX64	= addPostfix( "/Lib/metro_x64_" .. vslibpath .. "/dev_dll", havokBaseDirs )
havokLibDirsReleaseMetroX64  = addPostfix( "/Lib/metro_x64_" .. vslibpath .. "/release_dll", havokBaseDirs )
havokLibDirsDebugMetroArm	= addPostfix( "/Lib/metro_arm_" .. vslibpath .. "/dev_dll", havokBaseDirs )
havokLibDirsReleaseMetroArm  = addPostfix( "/Lib/metro_arm_" .. vslibpath .. "/release_dll", havokBaseDirs )

havokLibLinkDebugPS3        = { "libhkBase.a", "libhkSerialize.a", "libhkSceneData.a", "libhkInternal.a", "libhkGeometryUtilities.a", "libhkVisualize.a", "libhkCompat.a", "libhkpCollide.a", "libhkcdCollide.a", "libhkpConstraintSolver.a", "libhkpDynamics.a", "libhkpInternal.a", "libhkpUtilities.a", "libhkpVehicle.a", "libhkcdInternal.a", "libhkpConstraint.a", "hkpSpursIntegrate.elf.o", "hkpSpursCollide.elf.o", "hkpSpursRayCastQuery.elf.o","hkpSpursCollisionQuery.elf.o", "hkpSpursCollideStaticCompound.elf.o" }
havokLibLinkReleasePS3      =  havokLibLinkDebugPS3
havokLibLinkDebugPSP2       = { "libhkBase.a", "libhkcdInternal.a", "libhkCompat.a", "libhkGeometryUtilities.a", "libhkInternal.a", "libhkpCollide.a", "libhkcdCollide.a", "libhkpConstraintSolver.a", "libhkpDynamics.a", "libhkpInternal.a", "libhkpUtilities.a", "libhkpVehicle.a", "libhkSceneData.a", "libhkSerialize.a", "libhkVisualize.a", "libhkpConstraint.a" }
havokLibLinkReleasePSP2     = havokLibLinkDebugPSP2
havokLibLinkDebugDurango       = { "hkBase.lib", "hkcdInternal.lib", "hkCompat.lib", "hkGeometryUtilities.lib", "hkInternal.lib", "hkpCollide.lib", "hkcdCollide.lib", "hkpConstraintSolver.lib", "hkpDynamics.lib", "hkpInternal.lib", "hkpUtilities.lib", "hkpVehicle.lib", "hkSceneData.lib", "hkSerialize.lib", "hkVisualize.lib" }
havokLibLinkReleaseDurango     = havokLibLinkDebugDurango

havokLibLinkDebugWiiU       = { "hkBase.a", "hkcdInternal.a", "hkCompat.a", "hkGeometryUtilities.a", "hkInternal.a", "hkpCollide.a", "hkcdCollide.a", "hkpConstraintSolver.a", "hkpDynamics.a", "hkpInternal.a", "hkpUtilities.a", "hkpVehicle.a", "hkSceneData.a", "hkSerialize.a", "hkVisualize.a", "hkpConstraint.a" }
havokLibLinkReleaseWiiU     = havokLibLinkDebugWiiU


havokAIlibLinkDebugPS3      = { "libhkaiPathfinding.a", "libhkaiInternal.a", "libhkaiVisualize.a", "libhkaiAiPhysicsBridge.a", "hkaiSpursDynamicNavMesh.elf.o", "hkaiSpursPathfinding.elf.o", "hkaiSpursLocalSteering.elf.o" }
havokAIlibLinkReleasePS3    = havokAIlibLinkDebugPS3
havokAIlibLinkDebugPSP2     = { "libhkaiPathfinding.a", "libhkaiInternal.a", "libhkaiVisualize.a", "libhkaiAiPhysicsBridge.a" }
havokAIlibLinkReleasePSP2   = havokAIlibLinkDebugPSP2
havokAIlibLinkDebugDurango  = { "hkaiPathfinding.lib", "hkaiInternal.lib", "hkaiVisualize.lib", "hkaiAiPhysicsBridge.lib" }
havokAIlibLinkReleaseDurango    = havokAIlibLinkDebugDurango

havokAIlibLinkDebugWiiU     = { "hkaiPathfinding.a", "hkaiInternal.a", "hkaiVisualize.a", "hkaiAiPhysicsBridge.a" }
havokAIlibLinkReleaseWiiU   = havokAIlibLinkDebugWiiU

havokAnimationlibLinkDebugPS3  = { "libhkaAnimation.a", "libhkaInternal.a", "libhkaRagdoll.a", "hkaSpursMapping.elf.o", "hkaSpursSampleAndBlend.elf.o", "hkaSpursSampleAndCombine.elf.o" }
havokAnimationlibLinkReleasePS3  = havokAnimationlibLinkDebugPS3
havokAnimationlibLinkDebugPSP2  = { "libhkaAnimation.a", "libhkaInternal.a", "libhkaRagdoll.a" }
havokAnimationlibLinkReleasePSP2  = havokAnimationlibLinkDebugPSP2
havokAnimationlibLinkDebugDurango  = { "hkaAnimation.lib", "hkaInternal.lib", "hkaRagdoll.lib" }
havokAnimationlibLinkReleaseDurango  = havokAnimationlibLinkDebugDurango

havokAnimationlibLinkDebugWiiU  = { "hkaAnimation.a", "hkaInternal.a", "hkaRagdoll.a" }
havokAnimationlibLinkReleaseWiiU  = havokAnimationlibLinkDebugWiiU

havokBehaviorlibLinkDebugPS3 = { "libhkbBehavior.a", "libhkbInternal.a", "libhkbUtilities.a", "libhkbScript.a", "hkbSpursSpu.elf.o" }
havokBehaviorlibLinkReleasePS3 = havokBehaviorlibLinkDebugPS3
havokBehaviorlibLinkDebugPSP2 = { "libhkbBehavior.a", "libhkbInternal.a", "libhkbUtilities.a", "libhkbScript.a" }
havokBehaviorlibLinkReleasePSP2 = havokBehaviorlibLinkDebugPSP2
havokBehaviorlibLinkDebugDurango = { "hkbBehavior.lib", "hkbInternal.lib", "hkbUtilities.lib", "hkbScript.lib" }
havokBehaviorlibLinkReleaseDurango = havokBehaviorlibLinkDebugDurango

havokBehaviorlibLinkDebugWiiU = { "hkbBehavior.a", "hkbInternal.a", "hkbUtilities.a", "hkbScript.a" }
havokBehaviorlibLinkReleaseWiiU = havokBehaviorlibLinkDebugWiiU

havokClothLibLinkDebugPS3   = { "libhclSetup.a", "libhclCloth.a", "libhclInternal.a", "libhclPhysicsBridge.a", "hclSpursSpu.elf.o"}
havokClothLibLinkReleasePS3 = havokClothLibLinkDebugPS3
havokClothLibLinkDebugPSP2  = { "libhclSetup.a", "libhclCloth.a", "libhclInternal.a", "libhclPhysicsBridge.a" }
havokClothLibLinkReleasePSP2 = havokClothLibLinkDebugPSP2  
havokClothLibLinkDebugDurango  = { "hclSetup.lib", "hclCloth.lib", "hclInternal.lib", "hclPhysicsBridge.lib" }
havokClothLibLinkReleaseDurango = havokClothLibLinkDebugDurango

havokClothLibLinkDebugWiiU  = { "hclSetup.a", "hclCloth.a", "hclInternal.a", "hclPhysicsBridge.a" }
havokClothLibLinkReleaseWiiU = havokClothLibLinkDebugWiiU

havokDestructionlibLinkDebugPS3   = { "libhkdDestruction.a", "libhkdInternal.a", "libhkgpConvexDecomposition.a", "hkdSpursSpu.elf.o" }
havokDestructionlibLinkReleasePS3 = havokDestructionlibLinkDebugPS3
havokDestructionlibLinkDebugPSP2   = { "libhkdDestruction.a", "libhkdInternal.a", "libhkgpConvexDecomposition.a" }
havokDestructionlibLinkReleasePSP2 = havokDestructionlibLinkDebugPSP2
havokDestructionlibLinkDebugDurango  = { "hkdDestruction.lib", "hkdInternal.lib", "hkgpConvexDecomposition.lib" }
havokDestructionlibLinkReleaseDurango = havokDestructionlibLinkDebugPSP2

havokDestructionlibLinkDebugWiiU   = { "hkdDestruction.a", "hkdInternal.a", "hkgpConvexDecomposition.a" }
havokDestructionlibLinkReleaseWiiU = havokDestructionlibLinkDebugWiiU

-- Qt
QtVersion = "4.7.4"
QtBaseDir = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\Qt\\" .. QtVersion
QtIncludeDirs = { "../../ThirdParty/Qt/" .. QtVersion .. "/include", "../../ThirdParty/Qt/" .. QtVersion .. "/include/QtGui", "../../ThirdParty/Qt/" .. QtVersion .. "/include/QtCore",
  "$(HAVOK_THIRDPARTY_DIR)/redistsdks/Qt/" .. QtVersion .. "/include", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/Qt/" .. QtVersion .. "/include/QtGui", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/Qt/" .. QtVersion .. "/include/QtCore" }
QtLibDirsDebug90	        = { "../../../ThirdParty/Qt/" .. QtVersion .. "/lib/$(PlatformName)_net_9-0", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/Qt/" .. QtVersion .. "/lib/$(PlatformName)_net_9-0" }
QtLibDirsRelease90        = { "../../../ThirdParty/Qt/" .. QtVersion .. "/lib/$(PlatformName)_net_9-0", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/Qt/" .. QtVersion .. "/lib/$(PlatformName)_net_9-0" }
QtLibDirsDebug100	        = { "../../../ThirdParty/Qt/" .. QtVersion .. "/lib/$(PlatformName)_vs2010",  "$(HAVOK_THIRDPARTY_DIR)/redistsdks/Qt/" .. QtVersion .. "/lib/$(PlatformName)_vs2010" }
QtLibDirsRelease100       = { "../../../ThirdParty/Qt/" .. QtVersion .. "/lib/$(PlatformName)_vs2010",  "$(HAVOK_THIRDPARTY_DIR)/redistsdks/Qt/" .. QtVersion .. "/lib/$(PlatformName)_vs2010" }
QtLibsDebug = { "qtmaind.lib", "QtCored4.lib", "QtGuid4.lib", "QtSolutions_PropertyBrowser-headd.lib" }
QtLibsRelease = { "qtmain.lib", "QtCore4.lib", "QtGui4.lib", "QtSolutions_PropertyBrowser-head.lib" }
QtDefines = { "QT_CORE_LIB", "QT_GUI_LIB", "QT_NO_CAST_FROM_ASCII", "QT_STATICPLUGIN", "QT_DLL", "QT_QTPROPERTYBROWSER_IMPORT" }

-- yajl
YajlBaseDir = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\yajl\\"
YajlIncludeDirs = { "../../ThirdParty/yajl/Source", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/yajl/Source" }
YajlLibDirsDebug90    = { "../../../ThirdParty/yajl/lib/$(PlatformName)_net_9-0", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/yajl/lib/$(PlatformName)_net_9-0" }
YajlLibDirsRelease90  = { "../../../ThirdParty/yajl/lib/$(PlatformName)_net_9-0", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/yajl/lib/$(PlatformName)_net_9-0" }
YajlLibDirsDebug100	  = { "../../../ThirdParty/yajl/lib/$(PlatformName)_vs2010",  "$(HAVOK_THIRDPARTY_DIR)/redistsdks/yajl/lib/$(PlatformName)_vs2010" }
YajlLibDirsRelease100 = { "../../../ThirdParty/yajl/lib/$(PlatformName)_vs2010",  "$(HAVOK_THIRDPARTY_DIR)/redistsdks/yajl/lib/$(PlatformName)_vs2010" }
YajlLibsDebug = { "yajld.lib", "yajl_wrapperd.lib" }
YajlLibsRelease = { "yajl.lib", "yajl_wrapper.lib" }

-- JPEGLib
JPEGLibVersion = "6b"
JPEGLibIncludeDirs = {"../../ThirdParty/JPEGLib/" .. JPEGLibVersion, "$(HAVOK_THIRDPARTY_DIR)/redistsdks/JPEGLib/" .. JPEGLibVersion}
JPEGLibLibDirs = {"../../ThirdParty/JPEGLib/" .. JPEGLibVersion, "$(HAVOK_THIRDPARTY_DIR)/redistsdks/JPEGLib/" .. JPEGLibVersion}

-- Lua
LuaVersion = "5.1.4"
LuaDirWin = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\Lua\\" .. LuaVersion
LuaDirWinRel = "../../ThirdParty/Lua/" .. LuaVersion
LuaIncludeDirs = { LuaDirWinRel, LuaDirWin }
LuaLibDirs    = { LuaDirWinRel .. "/lib", LuaDirWin .. "/lib" }
LuaLibDirsX64 = { LuaDirWinRel .. "/lib/x64", LuaDirWin .. "/lib/x64" }
LuaLibDir = LuaDirWin .. "/lib"

-- PNGLib
PNGLibVersion = "1.2.47"
PNGLibIncludeDirs = {"../../ThirdParty/PNGLib/" .. PNGLibVersion, "$(HAVOK_THIRDPARTY_DIR)/redistsdks/PNGLib/" .. PNGLibVersion}
PNGLibLibDirs = {"../../ThirdParty/PNGLib/" .. PNGLibVersion, "$(HAVOK_THIRDPARTY_DIR)/redistsdks/PNGLib/" .. PNGLibVersion}

-- Beast
beastVersion = "2012.1"
beastDirWin = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\Beast\\" .. beastVersion
beastIncludeDirs = {"../../ThirdParty/Beast/" .. beastVersion .. "/include", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/Beast/" .. beastVersion .. "/include"}
beastLibDirs = {"../../ThirdParty/Beast/" .. beastVersion .. "/lib", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/Beast/" .. beastVersion .. "/lib"}

-- PhysX
PhysXVersion = "2_8_4"
PhysXDirWin = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\PhysX\\" .. PhysXVersion
PhysXIncludeDirs = {"../../ThirdParty/PhysX/" .. PhysXVersion .. "/include", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/PhysX/" .. PhysXVersion .. "/include" }
PhysXLibDirs = {"../../ThirdParty/PhysX/" .. PhysXVersion, "$(HAVOK_THIRDPARTY_DIR)/redistsdks/PhysX/" .. PhysXVersion}
PhysXLibDirsX86 = {"../../ThirdParty/PhysX/" .. PhysXVersion .. "/lib/Win32", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/PhysX/" .. PhysXVersion .. "/lib/Win32"}
PhysXLibDirsX64 = {"../../ThirdParty/PhysX/" .. PhysXVersion .. "/lib/Win64", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/PhysX/" .. PhysXVersion .. "/lib/Win64"}
PhysXLibDirsXbox360 = {"../../ThirdParty/PhysX/" .. PhysXVersion .. "/lib/xbox360", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/PhysX/" .. PhysXVersion .. "/lib/xbox360"}
--PhysXLibDirsPS3 = {"../../ThirdParty/PhysX/" .. PhysXVersion .. "/lib/PS3", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/PhysX/" .. PhysXVersion .. "/lib/PS3"}
PhysXLibDirPS3 = "$(HAVOK_THIRDPARTY_DIR)/redistsdks/PhysX/" .. PhysXVersion .. "/lib/PS3"

-- fmod
fmodVersion = "4.42.00"
fmodDirWin = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\fmod\\" .. fmodVersion
fmodIncludeDirs = {"../../ThirdParty/fmod/" .. fmodVersion .. "/inc", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/fmod/" .. fmodVersion .. "/inc" }
fmodLibDirsWin = {"../../ThirdParty/fmod/" .. fmodVersion .. "/lib/win", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/fmod/" .. fmodVersion .. "/lib/win" }
fmodLibDirsXbox360 = {"../../ThirdParty/fmod/" .. fmodVersion .. "/lib/xbox360", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/fmod/" .. fmodVersion .. "/lib/xbox360" }
fmodLibDirsPS3 = {"../../ThirdParty/fmod/" .. fmodVersion .. "/lib/ps3", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/fmod/" .. fmodVersion .. "/lib/ps3" }
fmodLibDirPS3 = "$(HAVOK_THIRDPARTY_DIR)/redistsdks/fmod/" .. fmodVersion .. "/lib/ps3"
fmodLibDirsPSP2 = {"../../ThirdParty/fmod/" .. fmodVersion .. "/lib/ngp", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/fmod/" .. fmodVersion .. "/lib/ngp" }
fmodLibDirPSP2 = "$(HAVOK_THIRDPARTY_DIR)/redistsdks/fmod/" .. fmodVersion .. "/lib/ngp"

fmodLibDirsWiiU = {"../../ThirdParty/fmod/" .. fmodVersion .. "/lib/wiiu", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/fmod/" .. fmodVersion .. "/lib/wiiu" }
fmodLibDirWiiU = "$(HAVOK_THIRDPARTY_DIR)/redistsdks/fmod/" .. fmodVersion .. "/lib/wiiu"
fmodDirWiiU = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\fmod\\" .. fmodVersion
fmodIncludeDirsWiiU = {"../../ThirdParty/fmod/" .. fmodVersion .. "/inc", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/fmod/" .. fmodVersion .. "/inc" }


-- nvAPI
nvapiDirs = {"$(HAVOK_THIRDPARTY_DIR)/sdks/common/nvAPI"}

-- tinyXML
tinyXMLVersion = "2.6.1"
tinyXMLDir = "$(HAVOK_THIRDPARTY_DIR)/redistsdks/tinyXML/" .. tinyXMLVersion
tinyXMLIncludeDirs = { "../../ThirdParty/tinyXML/" .. tinyXMLVersion, "$(HAVOK_THIRDPARTY_DIR)/redistsdks/tinyXML/" .. tinyXMLVersion }

-- zLib
zLibVersion = "1.2.3"
zLibDir = "$(HAVOK_THIRDPARTY_DIR)/redistsdks/zLib/" .. zLibVersion
zLibIncludeDirs = { "../../ThirdParty/zLib/" .. zLibVersion .. "/src", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/zLib/" .. zLibVersion .. "/src" }

-- qhull
qhullVersion = "2003.1"
--needs to be not the full path since the header files have too common names (ie. io.h") and thus will conflict with others
qhullIncludeDirs = { "../ThirdParty", "$(HAVOK_THIRDPARTY_DIR)/redistsdks" }
qhullLibDirs = { "../ThirdParty/qhull/" .. qhullVersion .. "/lib", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/qhull/" .. qhullVersion .. "/lib" }

-- Oniguruma
OnigurumaVersion = "5.9.2"
OnigurumaIncludeDirs = { "../ThirdParty/Oniguruma/" .. OnigurumaVersion, "$(HAVOK_THIRDPARTY_DIR)/redistsdks/Oniguruma/" .. OnigurumaVersion }
OnigurumaLibDirsX86 = { "../ThirdParty/Oniguruma/" .. OnigurumaVersion .. "/lib/x86", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/Oniguruma/" .. OnigurumaVersion .. "/lib/x86" }
OnigurumaLibDirsX64 = { "../ThirdParty/Oniguruma/" .. OnigurumaVersion .. "/lib/x64", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/Oniguruma/" .. OnigurumaVersion .. "/lib/x64" }

-- Fork Particle
forkparticleVersion = "1.1.0d"
forkparticleIncludeDirs = { "../ThirdParty/ForkParticle/" .. forkparticleVersion .. "/include", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/ForkParticle/" .. forkparticleVersion .. "/include"}
forkparticleLibDirs = { "../ThirdParty/ForkParticle/" .. forkparticleVersion .. "/lib", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/ForkParticle/" .. forkparticleVersion .. "/lib"}

-- SpeedTree
speedtreeVersion = "5_1"
speedtreeIncludeDirs = {
  "../../../ThirdParty/SpeedTree/" .. speedtreeVersion .. "/Include", 
  "../../../ThirdParty/SpeedTree/" .. speedtreeVersion .. "/Source/Applications/Common Source",
  "$(HAVOK_THIRDPARTY_DIR)/redistsdks/SpeedTree/" .. speedtreeVersion .. "/Include", 
  "$(HAVOK_THIRDPARTY_DIR)/redistsdks/SpeedTree/" .. speedtreeVersion .. "/Source/Applications/Common Source"
  }
speedtreeLibDirsX86 = {"../../../ThirdParty/SpeedTree/" .. speedtreeVersion .. "//Lib/Windows/VC9", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/SpeedTree/" .. speedtreeVersion .. "/Lib/Windows/VC9" }
speedtreeLibDirsX64 = {"../../../ThirdParty/SpeedTree/" .. speedtreeVersion .. "//Lib/Windows/VC9.x64", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/SpeedTree/" .. speedtreeVersion .. "/Lib/Windows/VC9.x64" }
speedtreeLibDirsXbox360 = {"../../../ThirdParty/SpeedTree/" .. speedtreeVersion .. "//Lib/360/VC9", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/SpeedTree/" .. speedtreeVersion .. "/Lib/360/VC9" }
--speedtreeLibDirsPS3 = {"../../../ThirdParty/SpeedTree/" .. speedtreeVersion .. "//Lib/PS3", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/SpeedTree/" .. speedtreeVersion .. "/Lib/PS3" }
speedtreeLibDirPS3 = "$(HAVOK_THIRDPARTY_DIR)/redistsdks/SpeedTree/" .. speedtreeVersion .. "/Lib/PS3"

-- Scaleform
scaleformVersion = "4.2.22"
local scaleformVersionMSVC = iif(buildSystem == "vs2012", "Msvc11", iif(buildSystem == "vs2010", "Msvc10", "Msvc90" ))
scaleformPathBackslashes = "..\\..\\ThirdParty\\Scaleform\\" .. scaleformVersion
scaleformAbsPathBackslashes = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\Scaleform\\" .. scaleformVersion
scaleformPathSlashes = "../../ThirdParty/Scaleform/" .. scaleformVersion
scaleformAbsPathSlashes = "$(HAVOK_THIRDPARTY_DIR)/redistsdks/Scaleform/" .. scaleformVersion
scaleform3rdPartyLibDirJpeg = "/3rdParty/jpeg-8d/Lib"
scaleform3rdPartyLibDirZlib = "/3rdParty/zlib-1.2.7/Lib"
scaleform3rdPartyLibDirLibPng = "/3rdParty/libpng-1.5.13/Lib"
scaleform3rdPartyLibDirExpat = "/3rdParty/expat-2.1.0/lib"
scaleform3rdPartyLibDirPcre = "/3rdParty/pcre/Lib"

scaleformIncludeDirs = {
scaleformPathSlashes .. "/Include", scaleformAbsPathSlashes .. "/Include",
scaleformPathSlashes .. "/Src", scaleformAbsPathSlashes .. "/Src",
scaleformPathSlashes .. "/Src/Render", scaleformAbsPathSlashes .. "/Src/Render",
scaleformPathSlashes .. "/Src/GFx", scaleformAbsPathSlashes .. "/Src/GFx",
scaleformPathSlashes .. "/Src/Sound", scaleformAbsPathSlashes .. "/Src/Sound",
scaleformPathSlashes .. "/Apps/Samples/Common", scaleformAbsPathSlashes .. "/Apps/Samples/Common",
scaleformPathSlashes .. "/Apps", scaleformAbsPathSlashes .. "/Apps",
scaleformPathSlashes .. "/Apps/Samples/FxPlayer", scaleformAbsPathSlashes .. "/Apps/Samples/FxPlayer"
}
scaleformLibDirsDebug = {
scaleformPathSlashes .. "/Lib/$(PlatformName)/" .. scaleformVersionMSVC .. "/Debug", scaleformAbsPathSlashes .. "/Lib/$(PlatformName)/" .. scaleformVersionMSVC .. "/Debug",
scaleformPathSlashes .. scaleform3rdPartyLibDirJpeg .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Debug", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirJpeg .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Debug",
scaleformPathSlashes .. scaleform3rdPartyLibDirZlib .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Debug", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirZlib .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Debug",
scaleformPathSlashes .. scaleform3rdPartyLibDirLibPng .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Debug", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirLibPng .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Debug",
scaleformPathSlashes .. scaleform3rdPartyLibDirExpat .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Debug", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirExpat .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Debug",
scaleformPathSlashes .. scaleform3rdPartyLibDirPcre .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Debug", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirPcre .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Debug"
} 
scaleformLibDirsRelease = {
scaleformPathSlashes .. "/Lib/$(PlatformName)/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. "/Lib/$(PlatformName)/" .. scaleformVersionMSVC .. "/Release",
scaleformPathSlashes .. scaleform3rdPartyLibDirJpeg .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirJpeg .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Release",
scaleformPathSlashes .. scaleform3rdPartyLibDirZlib .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirZlib .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Release",
scaleformPathSlashes .. scaleform3rdPartyLibDirLibPng .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirLibPng .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Release",
scaleformPathSlashes .. scaleform3rdPartyLibDirExpat .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirExpat .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Release",
scaleformPathSlashes .. scaleform3rdPartyLibDirPcre .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirPcre .. "/$(PlatformName)/" .. scaleformVersionMSVC .. "/Release"
} 
scaleformLibDirsDebugXbox360 = {
scaleformPathSlashes .. "/Lib/Xbox360/" .. scaleformVersionMSVC .. "/Debug", scaleformAbsPathSlashes .. "/Lib/Xbox360/" .. scaleformVersionMSVC .. "/Debug",
scaleformPathSlashes .. scaleform3rdPartyLibDirJpeg .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirJpeg .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release",
scaleformPathSlashes .. scaleform3rdPartyLibDirZlib .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirZlib .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release",
scaleformPathSlashes .. scaleform3rdPartyLibDirLibPng .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirLibPng .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release",
scaleformPathSlashes .. scaleform3rdPartyLibDirExpat .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirExpat .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release",
scaleformPathSlashes .. scaleform3rdPartyLibDirPcre .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirPcre .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release"
} 
scaleformLibDirsReleaseXbox360 = {
scaleformPathSlashes .. "/Lib/Xbox360/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. "/Lib/Xbox360/" .. scaleformVersionMSVC .. "/Release",
scaleformPathSlashes .. scaleform3rdPartyLibDirJpeg .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirJpeg .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release",
scaleformPathSlashes .. scaleform3rdPartyLibDirZlib .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirZlib .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release",
scaleformPathSlashes .. scaleform3rdPartyLibDirLibPng .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirLibPng .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release",
scaleformPathSlashes .. scaleform3rdPartyLibDirExpat .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirExpat .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release",
scaleformPathSlashes .. scaleform3rdPartyLibDirPcre .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release", scaleformAbsPathSlashes .. scaleform3rdPartyLibDirPcre .. "/Xbox360/" .. scaleformVersionMSVC .. "/Release"
} 
scaleformLibDirPS3 =  scaleformAbsPathSlashes .. "/Lib/PS3"
scaleformLibDirsDebugPS3 = { 
scaleformPathSlashes .. "/Lib/PS3/snc/Msvc10", scaleformAbsPathSlashes .. "/Lib/PS3/snc/Msvc10",
scaleformPathSlashes .. "/Lib/PS3/snc/Msvc10/Debug_NoRTTI", scaleformAbsPathSlashes .. "/Lib/PS3/snc/Msvc10/Debug_NoRTTI"
} 
scaleformLibDirsReleasePS3 = { 
scaleformPathSlashes .. "/Lib/PS3/snc/Msvc10", scaleformAbsPathSlashes .. "/Lib/PS3/snc/Msvc10",
scaleformPathSlashes .. "/Lib/PS3/snc/Msvc10/Release_NoRTTI", scaleformAbsPathSlashes .. "/Lib/PS3/snc/Msvc10/Release_NoRTTI"
} 

-- CriMovie
crimovieVersion = "2.05.30"
crimovieIncludeDirsPC = {"../../ThirdParty/CriMovie/" .. crimovieVersion .. "/pc/include", "$(HAVOK_THIRDPARTY_DIR)/sdks/common/CriMovie/" .. crimovieVersion .. "/pc/include"}
crimovieIncludeDirsXbox360 = {"../../ThirdParty/CriMovie/" .. crimovieVersion .. "/xbox360/include", "$(HAVOK_THIRDPARTY_DIR)/sdks/common/CriMovie/" .. crimovieVersion .. "/xbox360/include"}
crimovieIncludeDirsPS3 = {"../../ThirdParty/CriMovie/" .. crimovieVersion .. "/ps3/include", "$(HAVOK_THIRDPARTY_DIR)/sdks/common/CriMovie/" .. crimovieVersion .. "/ps3/include"}
crimovieLibDirsPCX86 = {"../../ThirdParty/CriMovie/" .. crimovieVersion .. "/pc/libs/x86", "$(HAVOK_THIRDPARTY_DIR)/sdks/common/CriMovie/" .. crimovieVersion .. "/pc/libs/x86"}
crimovieLibDirsPCX64 = {"../../ThirdParty/CriMovie/" .. crimovieVersion .. "/pc/libs/x64", "$(HAVOK_THIRDPARTY_DIR)/sdks/common/CriMovie/" .. crimovieVersion .. "/pc/libs/x64"}
crimovieLibDirsXbox360 = {"../../ThirdParty/CriMovie/" .. crimovieVersion .. "/xbox360/libs", "$(HAVOK_THIRDPARTY_DIR)/sdks/common/CriMovie/" .. crimovieVersion .. "/xbox360/libs"}
crimovieLibDirsPS3 = {"../../ThirdParty/CriMovie/" .. crimovieVersion .. "/ps3/libs", "$(HAVOK_THIRDPARTY_DIR)/sdks/common/CriMovie/" .. crimovieVersion .. "/ps3/libs"}

-- rapidxml
rapidxmlVersion = "1.11"
rapidxmlIncludeDirs = {"../../ThirdParty/rapidxml/" .. rapidxmlVersion, "$(HAVOK_THIRDPARTY_DIR)/redistsdks/rapidxml/" .. rapidxmlVersion}

-- p4api
p4apiVersion = "2012.1"
local p4apiVersionMSVC = iif(buildSystem == "vs2010", "MSVC100", "MSVC90" )
p4apiPathBackslashes = "..\\..\\ThirdParty\\p4api\\" .. p4apiVersion .. "\\" .. p4apiVersionMSVC
p4apiAbsPathBackslashes = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\p4api\\" .. p4apiVersion .. "\\" .. p4apiVersionMSVC
p4apiPathSlashes = "../../ThirdParty/p4api/" .. p4apiVersion .. "/" .. p4apiVersionMSVC
p4apiAbsPathSlashes = "$(HAVOK_THIRDPARTY_DIR)/redistsdks/p4api/" .. p4apiVersion .. "/" .. p4apiVersionMSVC

p4apiIncludeDirsX86Debug = {p4apiPathSlashes .. "/x86/Debug/", p4apiAbsPathSlashes .. "/x86/Debug/"}
p4apiIncludeDirsX86Release = {p4apiPathSlashes .. "/x86/Release/", p4apiAbsPathSlashes .. "/x86/Release/"}
p4apiIncludeDirsX64Debug = {p4apiPathSlashes .. "/x64/Debug/", p4apiAbsPathSlashes .. "/x64/Debug/"}
p4apiIncludeDirsX64Release = {p4apiPathSlashes .. "/x64/Release/", p4apiAbsPathSlashes .. "/x64/Release/"}

p4apiLibDirsX86Debug = {p4apiPathSlashes .. "/x86/Debug/lib/", p4apiAbsPathSlashes .. "/x86/Debug/lib/"}
p4apiLibDirsX86Release = {p4apiPathSlashes .. "/x86/Release/lib/", p4apiAbsPathSlashes .. "/x86/Release/lib/"}
p4apiLibDirsX64Debug = {p4apiPathSlashes .. "/x64/Debug/lib/", p4apiAbsPathSlashes .. "/x64/Debug/lib/"}
p4apiLibDirsX64Release = {p4apiPathSlashes .. "/x64/Release/lib/", p4apiAbsPathSlashes .. "/x64/Release/lib/"}


-- SubstanceAir
substanceairVersion = "1.x"
substanceairDirWin = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\SubstanceAir\\" .. substanceairVersion
substanceairIncludeDirs = {"../../ThirdParty/SubstanceAir/" .. substanceairVersion .. "/include", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/SubstanceAir/" .. substanceairVersion .. "/include"}
substanceairLibDirsDebug = {"../../ThirdParty/SubstanceAir/" .. substanceairVersion .. "/lib/win32/debugstatic", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/SubstanceAir/" .. substanceairVersion .. "/lib/win32/debugstatic"}
substanceairLibDirsRelease = {"../../ThirdParty/SubstanceAir/" .. substanceairVersion .. "/lib/win32/releasestatic", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/SubstanceAir/" .. substanceairVersion .. "/lib/win32/releasestatic"}

-- SubstanceRedux
substancereduxVersion = "1.x"
substancereduxDirWin = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\SubstanceRedux\\" .. substancereduxVersion
substancereduxIncludeDirs = {"../../ThirdParty/SubstanceRedux/" .. substancereduxVersion .. "/include", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/SubstanceRedux/" .. substancereduxVersion .. "/include"}
substancereduxLibDirsDebug = {"../../ThirdParty/SubstanceRedux/" .. substancereduxVersion .. "/lib/win32/debug", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/SubstanceRedux/" .. substancereduxVersion .. "/lib/win32/debug"}
substancereduxLibDirsRelease = {"../../ThirdParty/SubstanceRedux/" .. substancereduxVersion .. "/lib/win32/release", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/SubstanceRedux/" .. substancereduxVersion .. "/lib/win32/release"}

-- curl
curlVersion = "7.22.0"
curlIncludeDirs = {"../../ThirdParty/curl/" .. curlVersion .. "/include", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/curl/" .. curlVersion .. "/include"}
curlLibDirsX86 = {"../../ThirdParty/curl/" .. curlVersion .. "/libwin/runtime_dll/x86", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/curl/" .. curlVersion .. "/libwin/runtime_dll/x86"}
curlLibDirsX64 = {"../../ThirdParty/curl/" .. curlVersion .. "/libwin/runtime_dll/x64", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/curl/" .. curlVersion .. "/libwin/runtime_dll/x64"}

-- Swig
swigVersion = "2.0.3"
swigDirWin = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\swig\\" .. swigVersion

-- NUnit
nunitVersion = "2.2.0"
nunitDirWin = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\NUnit\\" .. nunitVersion

-- IEControl
iecontrolVersion = "1.1.1"
iecontrolDirWin = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\IEControl\\" .. iecontrolVersion

-- ScintillaNet
scintillanetVersion = "2.2.0"
scintillanetDirWin = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\ScintillaNet\\" .. scintillanetVersion

-- WintabDN
wintabdnVersion = "1.0"
wintabdnDirWin = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\WintabDN\\" .. wintabdnVersion .. "\\WintabDN"

-- SlimDX
slimdxVersion = ""
slimdxDirWin = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\SlimDX\\" .. slimdxVersion


-- RakNet
raknetVersion = "4.0"
raknetDirWin = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\RakNet\\" .. raknetVersion
raknetIncludeDirs = {"../../ThirdParty/RakNet/" .. raknetVersion .. "/Source", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/RakNet/" .. raknetVersion .. "/Source" } 
raknetAdditionalIncludeDirs = {"../../ThirdParty/RakNet/" .. raknetVersion .. "/DependentExtensions/miniupnpc-1.5", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/RakNet/" .. raknetVersion .. "/DependentExtensions/miniupnpc-1.5" } 
raknetLibDirs = {"../../ThirdParty/RakNet/" .. raknetVersion .. "/Lib", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/RakNet/" .. raknetVersion .. "/Lib" } 
raknetLibDirsX64 = {"../../ThirdParty/RakNet/" .. raknetVersion .. "/Lib/x64", "$(HAVOK_THIRDPARTY_DIR)/redistsdks/RakNet/" .. raknetVersion .. "/Lib/x64" } 
raknetLibDir = "$(HAVOK_THIRDPARTY_DIR)/redistsdks/RakNet/" .. raknetVersion .. "/Lib"

-- Pitch RPR
pitchRprVersion = "1_18_0"
pitchRprDirWin = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\PitchRpr\\" .. pitchRprVersion .. "\\" .. buildSystem

-- LVC Game
lvcgameVersion = "3.7.113.29270"
lvcgameDirWin = "$(HAVOK_THIRDPARTY_DIR)\\redistsdks\\LVCGame\\" .. lvcgameVersion
