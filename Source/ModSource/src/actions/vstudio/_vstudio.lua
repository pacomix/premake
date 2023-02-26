--
-- _vstudio.lua
-- Define the Visual Studio 200x actions.
-- Copyright (c) 2008-2010 Jason Perkins and the Premake project
--

	_VS = { }  -- deprecated, will remove eventually

	premake.vstudio = { }
	local vstudio = premake.vstudio


--
-- Map Premake platform identifiers to the Visual Studio versions. Adds the Visual
-- Studio specific "any" and "mixed" to make solution generation easier.
--

	premake.vstudio_platforms = { 
		any     = "Any CPU", 
		mixed   = "Mixed Platforms", 
		Native  = "Win32",
		x32     = "Win32", 
		x64     = "x64",
		PS3     = "PS3",
		PSVita  = "PSVita",
		Xbox360 = "Xbox 360",
		Cafe    = "Cafe",
		Durango     = "Durango",
		Apollo_x32  = "Win32",
		Apollo_Arm  = "Arm",
		Metro_x32   = "Win32",
		Metro_x64   = "x64",
		Metro_Arm   = "Arm",
        Android = "Android",
	}

	

--
-- Returns the architecture identifier for a project.
--

	function _VS.arch(prj)
		if (prj.language == "C#") then
			if (_ACTION < "vs2005") then
				return ".NET"
			else
				return "Any CPU"
			end
		else
			return "Win32"
		end
	end
	
	

--
-- Return the version-specific text for a boolean value.
-- (this should probably go in vs200x_vcproj.lua)
--

	function _VS.bool(value)
		if (_ACTION < "vs2005") then
			return iif(value, "TRUE", "FALSE")
		else
			return iif(value, "true", "false")
		end
	end
  
  function premake.vstudio_isManaged(prj)
    -- Look if all project configs contains the flag Managed and set the prj.flags.Managed to true in that case
    buildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectPossibleBuildableConfigurations) -- Only create configs for the configurations that can be built.
    local bManaged = true
    for _, cfginfo in ipairs(buildableConfigs) do
      local cfg = premake.getconfig(prj, cfginfo.src_buildcfg, cfginfo.src_platform)
      if not cfg.flags.Managed then
        bManaged = false
        break
      end
    end
    return bManaged    
  end


--
-- Process the solution's list of configurations and platforms, creates a list
-- of build configuration/platform pairs in a Visual Studio compatible format.
--
-- @param sln
--    The solution containing the configuration and platform lists.
-- @param with_pseudo
--    If true, Visual Studio's "Any CPU" and "Mixed Platforms" platforms will
--    be added for .NET and mixed mode solutions.
--

--
-- Process the solution's list of configurations and platforms, creates a list
-- of build configuration/platform pairs in a Visual Studio compatible format.
--
-- @param sln
--    The solution containing the configuration and platform lists.
--

function premake.vstudio_buildconfigs(sln)
		local cfgs = { }
		
		local platforms = premake.filterplatforms(sln, premake.vstudio_platforms, "Native")
		
		for _, buildcfg in ipairs(sln.configurations) do
			for _, platform in ipairs(platforms) do
				local entry = { }
				local bAddBuildcfg = true
        
				entry.src_buildcfg = buildcfg
				entry.src_platform = platform
				
				-- PS3 is funky and needs special handling in versions previous to VS2010; it's more of a build
				-- configuration than a platform from Visual Studio's point of view
				if (platform ~= "PS3" and platform ~= "PSVita") or (_ACTION == "vs2010") or (_ACTION == "vs2012") then
					entry.buildcfg = buildcfg
					entry.platform = premake.vstudio_platforms[platform]
				else
					 -- TODO - Hard coded - Only create Debug, Release or ReleaseP build configs for PS3/PSVita.
					 --  Note: If we do not do so like that, we will end up with a lot unuseful and nonsense configurations since PS3/PSVita for vs2008 are understood as normal build configurations for win32 platform.
					 if not (buildcfg == "Debug" or buildcfg == "Release" or buildcfg=="ReleaseP") then bAddBuildcfg = false end
					 entry.buildcfg = buildcfg .. " " .. platform --iif(platform == "PSVita", "PSP2", platform)
					 entry.platform = "Win32"
				end
				
				-- create a name the way VS likes it
				entry.name = entry.buildcfg .. "|" .. entry.platform
				
				-- flag the "fake" platforms added for .NET
				entry.isreal = (--[[platform ~= "any" and --]]platform ~= "mixed")
				
        if bAddBuildcfg == true then
          table.insert(cfgs, entry)
          
          if _ACTION ~= "vs2010" and _ACTION ~= "vs2012" then
            if platform == "PS3" or platform == "PSVita" then
              for _, tmpPlatform in ipairs(platforms) do
                if tmpPlatform ~= "PS3" and tmpPlatform ~= "PSVita" and tmpPlatform ~= "x32" then
                  local entry2 = {}
                  entry2.src_buildcfg = buildcfg
                  entry2.src_platform = tmpPlatform
                  entry2.buildcfg = entry.buildcfg
                  entry2.platform = premake.vstudio_platforms[tmpPlatform]
                  entry2.name = entry2.buildcfg .. "|" .. entry2.platform
                  table.insert(cfgs, entry2)
                end
              end
            end
          end
        end
			end
		end
		
		return cfgs
	end



  --
  -- Creates a list of build configuration/platform pairs in a Visual 
  -- Studio compatible format.
  --
  -- @param configList
  --    The build configurations list in the Premake format. 
  --    IE: "Debug|x32", "Release|x64"
  --
  function premake.vstudio_buildProjectConfigurations(configList)
		local cfgs = { }
		
    if not configList then
      error("\n\n\t\tThere is no buildable config for project: '" .. prj.name .. "'\n\n\tSet projectBuildableConfigs.\n\n")
    end
    
		for _, buildcfg in ipairs(configList) do
      local CfgAndPlatform = string.explode(buildcfg, "|")
      local platform = CfgAndPlatform[2]
      local entry = { }
      local bAddBuildcfg = true
      
      entry.src_buildcfg = CfgAndPlatform[1]
      entry.src_platform = CfgAndPlatform[2]
      
      -- PS3 is funky and needs special handling in version previous to VS2010; it's more of a build
      -- configuration than a platform from Visual Studio's point of view				
      if (platform ~= "PS3" and platform ~= "PSVita") or (_ACTION == "vs2010") or (_ACTION == "vs2012") then
        entry.buildcfg = CfgAndPlatform[1]
        entry.platform = premake.vstudio_platforms[CfgAndPlatform[2]]
      else
        if not (CfgAndPlatform[1] == "Debug" or CfgAndPlatform[1] == "Release" or CfgAndPlatform[1]=="ReleaseP") then bAddBuildcfg = false end
        entry.buildcfg = CfgAndPlatform[1] .. " " .. CfgAndPlatform[2]
        entry.platform = "Win32"
      end
      
      -- create a name the way VS likes it
      entry.name = entry.buildcfg .. "|" .. entry.platform
      
      -- flag the "fake" platforms added for .NET
      entry.isreal = (--[[platform ~= "any" and --]]platform ~= "mixed")
      
      if bAddBuildcfg == true then
        table.insert(cfgs, entry)
      end
      
		end
		
		return cfgs
	end
  
--
-- Return a configuration type index.
-- (this should probably go in vs200x_vcproj.lua)
--

	function _VS.cfgtype(cfg)
    if (cfg.kind == "Makefile") then
      return 0
		elseif (cfg.kind == "SharedLib") then
			return 2
		elseif (cfg.kind == "StaticLib") then
			return 4
		else
			return 1
		end
	end
	
	

--
-- Clean Visual Studio files
--

	function premake.vstudio.cleansolution(sln)
		premake.clean.file(sln, "%%.sln")
		premake.clean.file(sln, "%%.suo")
		premake.clean.file(sln, "%%.ncb")
		-- MonoDevelop files
		premake.clean.file(sln, "%%.userprefs")
		premake.clean.file(sln, "%%.usertasks")
	end
	
	function premake.vstudio.cleanproject(prj)
		local fname = premake.project.getfilename(prj, "%%")

		os.remove(fname .. ".vcproj")
		os.remove(fname .. ".vcproj.user")

		os.remove(fname .. ".vcxproj")
		os.remove(fname .. ".vcxproj.user")
		os.remove(fname .. ".vcxproj.filters")

		os.remove(fname .. ".csproj")
		os.remove(fname .. ".csproj.user")

		os.remove(fname .. ".pidb")
		os.remove(fname .. ".sdf")
	end

	function premake.vstudio.cleantarget(name)
		os.remove(name .. ".pdb")
		os.remove(name .. ".idb")
		os.remove(name .. ".ilk")
		os.remove(name .. ".vshost.exe")
		os.remove(name .. ".exe.manifest")
	end
	
	

--
-- Write out entries for the files element; called from premake.walksources().
-- (this should probably go in vs200x_vcproj.lua)
--

	local function output(indent, value)
		-- io.write(indent .. value .. "\r\n")
		_p(indent .. value)
	end
	
	local function attrib(indent, name, value)
		-- io.write(indent .. "\t" .. name .. '="' .. value .. '"\r\n')
		_p(indent .. "\t" .. name .. '="' .. value .. '"')
	end
	
  local function write_fileconfigurationtag(name, nestlevel)
    local indent = string.rep("\t", nestlevel + 2)
    
    output(indent, "\t<FileConfiguration")
    attrib(indent, "\tName", name)
    output(indent, "\t\t>")
    
    return true
    
  end
  
  local function write_custombuildfile_block(cfgname, commands, outputFiles, nestlevel)
    local indent = string.rep("\t", nestlevel + 2)
    
    output(indent, "\t\t<Tool")
    attrib(indent, "\t\tName", "VCCustomBuildTool")
    if (commands and commands ~= "" and commands ~= {}) then
      local commandLine = premake.esc(table.implode(commands, "", "", "\r\n"))
      if commandLine and commandLine ~= "" then
        attrib(indent, "\t\tCommandLine", commandLine)
      end
    end
    if(outputFiles and outputFiles ~= "" and outputFiles ~= {}) then
      local outputs = premake.esc(table.implode(outputFiles, "", "", ";"))
      if outputs and outputs ~= "" then
        attrib(indent, "\t\tOutputs", outputs)
      end
    end
    output(indent, "\t\t/>")
    
  end
  
	function _VS.files(prj, fname, state, nestlevel)
		local indent = string.rep("\t", nestlevel + 2)
		
		if (state == "GroupStart") then
			output(indent, "<Filter")
			attrib(indent, "Name", path.getname(fname))
			attrib(indent, "Filter", "")
			output(indent, "\t>")

		elseif (state == "GroupEnd") then
			output(indent, "</Filter>")

		else
			output(indent, "<File")
			attrib(indent, "RelativePath", path.translate(fname, "\\"))
			output(indent, "\t>")
         
         
         
      -- START - Support for any file configuration. Extend as needed.
      local fcfg = premake.getfileconfig(prj, fname)
      
      local buildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectPossibleBuildableConfigurations) -- Only create configs for the configurations that can be built.      
      -- START MOD - Add support for file excludes
      for _, cfginfo in ipairs(buildableConfigs) do
        local cfg = premake.getconfig(prj, cfginfo.src_buildcfg, cfginfo.src_platform)
        local bFileConfigurationTagWritten = false
        if not cfg then 
          error("A configuration file block must exist for: " .. cfginfo.src_buildcfg .. "|" .. cfginfo.src_platform, 0)
          break 
        end
        for _, exclude in ipairs(cfg.excludes) do
           local excluded = (fname == exclude)
           if (excluded) then 
            if not bFileConfigurationTagWritten then
              bFileConfigurationTagWritten = true
              
              output(indent, "\t<FileConfiguration")
              attrib(indent, "\tName", cfginfo.name)
            end
            
            attrib(indent, "\tExcludedFromBuild", "1")
            output(indent, "\t\t>")
            break -- One file found is enough
           end
        end
        
        -- START MOD - Add support for no pch support file
        for _, exclude in ipairs(cfg.nopchfile) do
          local fileIsNotUsingPCH = (fname == exclude)
          if (fileIsNotUsingPCH) then 
            if not bFileConfigurationTagWritten then bFileConfigurationTagWritten = write_fileconfigurationtag(cfginfo.name, nestlevel) end
            output(indent, "\t\t<Tool")
            attrib(indent, "\t\tName", iif(cfg.system == "Xbox360", "VCCLX360CompilerTool", "VCCLCompilerTool"))
            attrib(indent, "\t\tUsePrecompiledHeader", "0")
            output(indent, "\t\t/>")
            break -- One file found is enough
          end
        end
        
        if (fcfg.custombuildcommandline and fcfg.custombuildcommandline ~= "" and fcfg.custombuildcommandline ~= {}) then
          if not bFileConfigurationTagWritten then bFileConfigurationTagWritten = write_fileconfigurationtag(cfginfo.name, nestlevel) end
          --write_custombuildfile_block(cfginfo.name, fcfg.custombuildcommandline, fcfg.custombuildcommandlineOutput, nestlevel)
          premake.vs200x_vcproj_VCCustomBuildTool(fcfg)
        else
          for _, exclude in ipairs(cfg.custombuildtool) do
            excluded = (fname == exclude)
            if (excluded) then 
              if not bFileConfigurationTagWritten then bFileConfigurationTagWritten = write_fileconfigurationtag(cfginfo.name, nestlevel) end
              --write_custombuildfile_block(cfginfo.name, "", "", nestlevel)
              premake.vs200x_vcproj_VCCustomBuildTool(fcfg)
              break
            end
          end
        end
        
        if (not prj.flags.NoPCH and prj.pchsource == fname) then
          if cfginfo.isreal then
						local cfg = premake.getconfig(prj, cfginfo.src_buildcfg, cfginfo.src_platform)
            
						if not bFileConfigurationTagWritten then bFileConfigurationTagWritten = write_fileconfigurationtag(cfginfo.name, nestlevel) end
						output(indent, "\t\t<Tool")
						attrib(indent, "\t\tName", iif(cfg.system == "Xbox360", "VCCLX360CompilerTool", "VCCLCompilerTool"))
						attrib(indent, "\t\tUsePrecompiledHeader", "1")
						output(indent, "\t\t/>")
					end
        end
        
        if bFileConfigurationTagWritten then output(indent, "\t</FileConfiguration>") end 
        
      end
      
			output(indent, "</File>")
		end
	end
	
	
	
--
-- Return the optimization code.
-- (this should probably go in vs200x_vcproj.lua)
--

	function _VS.optimization(cfg)
		local result = 0
    
    if (cfg.propertySheet and cfg.propertySheet ~= "") and not (cfg.flags.Optimize or cfg.flags.OptimizeSize or cfg.flags.OptimizeSpeed) then
      result = -1
    elseif cfg.flags.Optimize then
      result = 3
    elseif cfg.flags.OptimizeSize then
      result = 1
    elseif cfg.flags.OptimizeSpeed then
      result = 2
    end
		return result
	end



--
-- Assemble the project file name.
--

	function _VS.projectfile(prj)
		local extension
		if (prj.language == "C#") then
			extension = ".csproj"
		elseif ( (_ACTION == "vs2010" or _ACTION == "vs2012" ) and (prj.language == "C++" or prj.language == "C" or prj.language == "Default")) then
			extension = ".vcxproj"
		else
			extension = ".vcproj"
		end

		local fname = path.join(prj.location, prj.name)
		return fname..extension
	end
	

--
-- Returns the Visual Studio tool ID for a given project type.
--

	function _VS.tool(prj)
		if (prj.language == "C#") then
			return "FAE04EC0-301F-11D3-BF4B-00C04F79EFBC"
		else
			return "8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942"
		end
	end


--
-- Register the Visual Studio command line actions
--

	newaction {
		trigger         = "vs2002",
		shortname       = "Visual Studio 2002",
		description     = "Generate Microsoft Visual Studio 2002 project files",
		os              = "windows",
		
		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		
		valid_languages = { "C", "C++", "C#" },
		
		valid_tools     = {
			cc     = { "msc"   },
			dotnet = { "msnet" },
		},

		onsolution = function(sln)
			premake.generate(sln, "%%.sln", premake.vs2002_solution)
		end,
		
		onproject = function(prj)
			if premake.isdotnetproject(prj) then
				premake.generate(prj, "%%.csproj", premake.vs2002_csproj)
				premake.generate(prj, "%%.csproj.user", premake.vs2002_csproj_user)
			else
				premake.generate(prj, "%%.vcproj", premake.vs200x_vcproj)
			end
		end,
		
		oncleansolution = premake.vstudio.cleansolution,
		oncleanproject  = premake.vstudio.cleanproject,
		oncleantarget   = premake.vstudio.cleantarget
	}

	newaction {
		trigger         = "vs2003",
		shortname       = "Visual Studio 2003",
		description     = "Generate Microsoft Visual Studio 2003 project files",
		os              = "windows",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		
		valid_languages = { "C", "C++", "C#" },
		
		valid_tools     = {
			cc     = { "msc"   },
			dotnet = { "msnet" },
		},

		onsolution = function(sln)
			premake.generate(sln, "%%.sln", premake.vs2003_solution)
		end,
		
		onproject = function(prj)
			if premake.isdotnetproject(prj) then
				premake.generate(prj, "%%.csproj", premake.vs2002_csproj)
				premake.generate(prj, "%%.csproj.user", premake.vs2002_csproj_user)
			else
				premake.generate(prj, "%%.vcproj", premake.vs200x_vcproj)
			end
		end,
		
		oncleansolution = premake.vstudio.cleansolution,
		oncleanproject  = premake.vstudio.cleanproject,
		oncleantarget   = premake.vstudio.cleantarget
	}

	newaction {
		trigger         = "vs2005",
		shortname       = "Visual Studio 2005",
		description     = "Generate Microsoft Visual Studio 2005 project files",
		os              = "windows",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		
		valid_languages = { "C", "C++", "C#" },
		
		valid_tools     = {
			cc     = { "msc"   },
			dotnet = { "msnet" },
		},

		onsolution = function(sln)
			premake.generate(sln, "%%.sln", premake.vs2005_solution)
		end,
		
		onproject = function(prj)
			if premake.isdotnetproject(prj) then
				premake.generate(prj, "%%.csproj", premake.vs2005_csproj)
				premake.generate(prj, "%%.csproj.user", premake.vs2005_csproj_user)
			else
				premake.generate(prj, "%%.vcproj", premake.vs200x_vcproj)
			end
		end,
		
		oncleansolution = premake.vstudio.cleansolution,
		oncleanproject  = premake.vstudio.cleanproject,
		oncleantarget   = premake.vstudio.cleantarget
	}

	newaction {
		trigger         = "vs2008",
		shortname       = "Visual Studio 2008",
		description     = "Generate Microsoft Visual Studio 2008 project files",
		os              = "windows",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		
		valid_languages = { "C", "C++", "C#", "Default" },
		
		valid_tools     = {
			cc     = { "msc"   },
			dotnet = { "msnet" },
		},

		onsolution = function(sln)
			premake.generate(sln, "%%.sln", premake.vs2005_solution)
		end,
		
		onproject = function(prj)
			if premake.isdotnetproject(prj) then
				premake.generate(prj, "%%.csproj", premake.vs2005_csproj)
				premake.generate(prj, "%%.csproj.user", premake.vs2005_csproj_user)
			else
				premake.generate(prj, "%%.vcproj", premake.vs200x_vcproj)
			end
		end,
		
		oncleansolution = premake.vstudio.cleansolution,
		oncleanproject  = premake.vstudio.cleanproject,
		oncleantarget   = premake.vstudio.cleantarget
	}

		
	newaction 
	{
		trigger         = "vs2010",
		shortname       = "Visual Studio 2010",
		description     = "Generate Visual Studio 2010 project files (experimental)",
		os              = "windows",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		
		valid_languages = { "C", "C++", "C#", "Default" },
		
		valid_tools     = {
			cc     = { "msc"   },
			dotnet = { "msnet" },
		},

		onsolution = function(sln)
			premake.generate(sln, "%%.sln", premake.vs_generic_solution)
		end,
		
		onproject = function(prj)
      if premake.isdotnetproject(prj) then
				premake.generate(prj, "%%.csproj", premake.vs2005_csproj)
				premake.generate(prj, "%%.csproj.user", premake.vs2005_csproj_user)
			else
        premake.generate(prj, "%%.vcxproj", premake.vs2010_vcxproj)
        premake.generate(prj, "%%.vcxproj.user", premake.vs2010_vcxproj_user)
        premake.generate(prj, "%%.vcxproj.filters", premake.vs2010_vcxproj_filters)
      end
		end,
		

		oncleansolution = premake.vstudio.cleansolution,
		oncleanproject  = premake.vstudio.cleanproject,
		oncleantarget   = premake.vstudio.cleantarget
	}
	
	newaction 
	{
		trigger         = "vs2012",
		shortname       = "Visual Studio 2012",
		description     = "Generate Visual Studio 2012 project files (experimental)",
		os              = "windows",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		
		valid_languages = { "C", "C++", "C#", "Default" },
		
		valid_tools     = {
			cc     = { "msc"   },
			dotnet = { "msnet" },
		},

		onsolution = function(sln)
			premake.generate(sln, "%%.sln", premake.vs_generic_solution)
		end,
		
		onproject = function(prj)
        if premake.isdotnetproject(prj) then
				premake.generate(prj, "%%.csproj", premake.vs2005_csproj)
				premake.generate(prj, "%%.csproj.user", premake.vs2005_csproj_user)
			else
        premake.generate(prj, "%%.vcxproj", premake.vs2012_vcxproj)
        premake.generate(prj, "%%.vcxproj.user", premake.vs2012_vcxproj_user)
        premake.generate(prj, "%%.vcxproj.filters", premake.vs2012_vcxproj_filters)
      end
		end,
		

		oncleansolution = premake.vstudio.cleansolution,
		oncleanproject  = premake.vstudio.cleanproject,
		oncleantarget   = premake.vstudio.cleantarget
	}
