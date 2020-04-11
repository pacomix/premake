globalScriptDir = nil -- It should contain the dir where the script file is located. Used for including the standard script files to generate the projects and solutions.

function ConfigureBuild(element)
  if element ~= "Solution" and element ~= "Project" then
    error("\n\n\tOnly \"Solution\" or \"Project\" are allowed\n\n")
  end

  -- Look for the scripts location
  globalScriptDir = os.getcwd()
  local iSecurityCounter = 0
  while not os.isdir("./vABC") do
    os.chdir("..")
    iSecurityCounter = iSecurityCounter + 1
    if iSecurityCounter >= 16 then
      break
    end
  end

  if iSecurityCounter >= 16 then
    error("\n\n\tERROR!!!!! Global Solution Vars file can not be found.\n\tStarted from:\n\n\t\t" .. globalScriptDir .. "\n\n\tEnded in:\n\n\t\t" .. os.getcwd())
  end
  
  os.chdir("vABC/Premake")
  if element == "Solution" then
    dofile "Globals.lua"
  elseif element == "Project" then
    dofile "PrjGenerator.lua"
  end
  
  os.chdir(globalScriptDir) -- Restore the previous path.
  
end

ConfigureBuild("Solution")
--------------------------------------------------------------------------------------

-- DEFINE HERE THE SOLUTION's CONFIGURATIONS --
if buildSystem == "vs2008" then -- Build configurations for Visual Studio 2008
	buildConfigs = { "Define here the diferent build configuration separated by entries. IE:", "Debug", "Debug NoXI", "etc", "etc" }
	buildPlatforms = {  "Define here the diferent platforms separated by entries. IE:", "x32", "x64", "Xbox360" }
elseif buildSystem == "vs2010" then -- Build configurations for Visual Studio 2010
	buildConfigs = { "Define here the diferent build configuration separated by entries. IE:", "Debug", "Debug NoXI", "etc", "etc" }
	buildPlatforms = {  "Define here the diferent platforms separated by entries. IE:", "x32", "x64", "Xbox360" }
elseif buildSystem == "vs2012" then -- Build configurations for Visual Studio 2012
	buildConfigs = { "Define here the diferent build configuration separated by entries. IE:", "Debug", "Debug NoXI", "etc", "etc" }
	buildPlatforms = {  "Define here the diferent platforms separated by entries. IE:", "x32", "x64" }
elseif buildSystem == "xcode3" then -- Build configurations for XCode
	buildConfigs = { "Define here the diferent build configuration separated by entries. IE:", "Debug", "Debug NoXI", "etc", "etc" }
	buildPlatforms = {  "Define here the diferent platforms separated by entries. IE:", "Universal32", "Universal64" }
end

solution ( "Write here the name of the solution!!" .. buildSystemSuffix ) -- NOTE: Do not use the buildSystemSuffix variable for projects that do not need it.
  basedir "."
  location "."
  configurations { buildConfigs }
  platforms      { buildPlatforms }
  
  if buildSystem == "vs2008" or buildSystem == "vs2010" or buildSystem == "vs2012" then
  -- Define here each project that is part of the solution. Additionally you can explicitly write which configurations should be build and/or excluded for that project.
  -- IE:
      includeBuildConfigs = { "Debug|x32" }
        dofile "vBase/Project-vBase.lua"
  
      includeBuildConfigs = { "Debug|PS3", "Release|PS3" }
        dofile "../shared/projects/SPU/SPUDummyTask"
  
      excludeBuildConfigs = { "Debug|PS3" }
        dofile "../shared/projects/SPU/SPUDummyTaskDMA"
  elseif buildSystem == "xcode3" then
  -- Define here each project that is part of the solution. Additionally you can explicitly write which configurations should be build and/or excluded for that project.
  -- IE:
      includeBuildConfigs = { "Debug|x32" }
        dofile "vBase/Project-vBase.lua"
  
      includeBuildConfigs = { "Debug|PS3", "Release|PS3" }
        dofile "../shared/projects/SPU/SPUDummyTask"
  
      excludeBuildConfigs = { "Debug|PS3" }
        dofile "../shared/projects/SPU/SPUDummyTaskDMA"
  end
