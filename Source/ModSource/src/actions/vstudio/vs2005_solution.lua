--
-- vs2005_solution.lua
-- Generate a Visual Studio 2005 or 2008 solution.
-- Copyright (c) 2009 Jason Perkins and the Premake project
--


	function premake.vs2005_solution(sln)
		io.eol = '\r\n'

		-- Precompute Visual Studio configurations
		sln.vstudio_configs = premake.vstudio_buildconfigs(sln)
		
		-- Mark the file as Unicode
		_p('\239\187\191')

		-- Write the solution file version header
		_p('Microsoft Visual Studio Solution File, Format Version %s', iif(_ACTION == 'vs2005', '9.00', '10.00'))
		_p('# Visual Studio %s', iif(_ACTION == 'vs2005', '2005', '2008'))

		-- Write out the list of project entries
		for prj in premake.solution.eachproject(sln) do
			-- Build a relative path from the solution file to the project file
			local projpath = path.translate(path.getrelative(sln.location, _VS.projectfile(prj)), "\\")
			
			_p('Project("{%s}") = "%s", "%s", "{%s}"', _VS.tool(prj), prj.name, projpath, prj.uuid)
			local deps = premake.getdependencies(prj)
			if #deps > 0 then
				_p('\tProjectSection(ProjectDependencies) = postProject')
				for _, dep in ipairs(deps) do
					_p('\t\t{%s} = {%s}', dep.uuid, dep.uuid)
				end
				_p('\tEndProjectSection')
			end
			_p('EndProject')
		end

		_p('Global')
		premake.vs2005_solution_platforms(sln)
		premake.vs2005_solution_project_platforms(sln)
		premake.vs2005_solution_properties(sln)
		_p('EndGlobal')
	end
	

	
--
-- Write out the contents of the SolutionConfigurationPlatforms section, which
-- lists all of the configuration/platform pairs that exist in the solution.
--

	function premake.vs2005_solution_platforms(sln)
		_p('\tGlobalSection(SolutionConfigurationPlatforms) = preSolution')
		for _, cfg in ipairs(sln.vstudio_configs) do
			_p('\t\t%s = %s', cfg.name, cfg.name)
		end
		_p('\tEndGlobalSection')
	end
	
	

--
-- Write out the contents of the ProjectConfigurationPlatforms section, which maps
-- the configuration/platform pairs into each project of the solution.
--

	function premake.vs2005_solution_project_platforms(sln)
		_p('\tGlobalSection(ProjectConfigurationPlatforms) = postSolution')
		for prj in premake.solution.eachproject(sln) do
    
      -- PREPARATION - If we are in VS2008 we need to convert the PS3/PSVita mapping configurations into the correct ones. The map can be written in the next way: "Debug|(PS3|PSVita)=Debug (PS3|PSP2)|Win32"
      -- but for VS2008 we need to convert it into: "Debug (PS3|PSP2)|Win32=Debug (PS3|PSP2)|Win32" due to the lack of authentic PS3/PSVita platform for that IDE.
      if _ACTION ~= "vs2010" and _ACTION ~= "vs2012" then
        if #prj.mapBuildConfigurations > 0 then
          for _, mappedCfg in ipairs(prj.mapBuildConfigurations) do
            local SrcDstUntransformed = string.explode(mappedCfg, "=")
            local srcConfigPlatform = SrcDstUntransformed[1]
            local dstConfigPlatform = SrcDstUntransformed[2]
            local srcConfig = string.explode(srcConfigPlatform, "|")[1]
            local srcPlatform = string.explode(srcConfigPlatform, "|")[2]
            local dstConfig = string.explode(dstConfigPlatform, "|")[1]
            local dstPlatform = string.explode(dstConfigPlatform, "|")[2]
            
            if srcPlatform == "PS3" then
              srcPlatform = "Win32"
              srcConfig = srcConfig .. " PS3"
            elseif srcPlatform == "PSVita" then
              srcPlatform = "Win32"
              srcConfig = srcConfig .. " PSVita"
            end
            
            if dstPlatform == "PS3" then
              dstPlatform = "Win32"
              dstConfig = dstConfig .. " PS3"
            elseif dstPlatform == "PSVita" then
              dstPlatform = "Win32"
              dstConfig = dstConfig .. " PSVita"
            end
            
            prj.mapBuildConfigurations[_] = srcConfig .. "|" .. srcPlatform .. "=" .. dstConfig .. "|" .. dstPlatform
          end
          
          -- check
          for _, mappedCfg in ipairs(prj.mapBuildConfigurations) do
            local SrcDstUntransformed = string.explode(mappedCfg, "=")
            local srcConfigPlatform = SrcDstUntransformed[1]
            local dstConfigPlatform = SrcDstUntransformed[2]
            local srcConfig = string.explode(srcConfigPlatform, "|")[1]
            local srcPlatform = string.explode(srcConfigPlatform, "|")[2]
            local dstConfig = string.explode(dstConfigPlatform, "|")[1]
            local dstPlatform = string.explode(dstConfigPlatform, "|")[2]
            
            if srcPlatform == "PS3" or dstPlatform == "PS3" then error("SOURCE AND/OR DESTINY PLATFORM UNSUPPORTED: PS3") end
            if srcPlatform == "PSVita" or dstPlatform == "PSVita" then error("SOURCE AND/OR DESTINY PLATFORM UNSUPPORTED: PSVita") end
          end
        end
      else
      end
      
      printf("\tPROJECT\t'%s'", prj.name)
      
      buildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectBuildableConfigurations)
      possibleBuildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectPossibleBuildableConfigurations)
      
      if #buildableConfigs == 0 then
        printf("\t\tBuild configurations:\tNONE")
      else
        printf("\t\tBuild configurations:")
        for _, possibleBuildableCfg in ipairs(possibleBuildableConfigs) do
          local bBuildable = "| |"
          for _, buildableCfg in ipairs(buildableConfigs) do
            if buildableCfg.name == possibleBuildableCfg.name then
              bBuildable = "|x|"
              break
            end
          end 
          printf("\t\t\t%s\t%s", bBuildable, possibleBuildableCfg.name)
        end
      end
      
      if #possibleBuildableConfigs == 0 then
        err = "project '" ..prj.name .. "' has no build configurations! '"
        error("\n\n\tError: " .. err .. "\n\n", 0)
      end
      
      printf('\t\tBuild map:')
			for _, cfg in ipairs(sln.vstudio_configs) do
				-- .NET projects always map to the "Any CPU" platform (for now, at 
				-- least). For C++, "Any CPU" and "Mixed Platforms" map to the first
				-- C++ compatible target platform in the solution list.
				local mapped
				if premake.isdotnetproject(prj) then
					mapped = "Any CPU"  -- NOTE Add direct support to automatically map Win32 configurations to C# x86
				else
					if cfg.platform == "Any CPU" or cfg.platform == "Mixed Platforms" then
						mapped = sln.vstudio_configs[3].platform
					else
						mapped = cfg.platform
					end
				end
        
        if mapped == "Any CPU" or mapped == cfg.platform or cfg.platform == "Mixed Platforms" then        
        
          -- First store a valid configuration to be written to map a non-existent project configuration
          -- into a valid (random, or... in this case, the first valid entry in the referenced project)
          local tempMapped = possibleBuildableConfigs[1].name -- Default mapped config for a non-existant build configuration
          local bFound = false
          for _, buildConfig in ipairs(buildableConfigs) do            
            if buildConfig.isreal then
              local cfgPrj = premake.getconfig(prj, buildConfig.src_buildcfg, buildConfig.src_platform)
              if not cfgPrj then 
                error("A configuration block must exist for: " .. buildConfig.src_buildcfg .. "|" .. buildConfig.src_platform, 0)
                break 
              end
              local cfgPrjFullName = buildConfig.name
              tempMapped = cfgPrjFullName
              local matchedCSharpConfig = false
              local mappedConfig = cfg.buildcfg
              
              -- NOTE. This is a temporary solution while we create the project mapping feature. Probably it will not be used.
              -- Lets decide which C# build config should be mapped.
              if #prj.mapBuildConfigurations == 0 then
                if mapped == "Any CPU" then 
                  --printf("Checking prj buildcfg: " .. buildConfig.src_buildcfg .. " Against sln build cfg: " .. cfg.buildcfg)
                  if buildConfig.src_buildcfg == cfg.buildcfg then 
                    if cfg.src_platform == "Win32" or cfg.src_platform == "x64" then
                      matchedCSharpConfig = true
                    end
                  end
                end
              else
                for _, mappedCfg in ipairs(prj.mapBuildConfigurations) do
                
                  local mapEntries = string.explode(mappedCfg, "=")
                  local srcMapCfgPltName = mapEntries[1]
                  local srcMapCfgName = string.explode(srcMapCfgPltName, "|")[1]
                  local srcMapPltName = string.explode(srcMapCfgPltName, "|")[2]
                  
                  local dstMapCfgPltName = mapEntries[2]
                  local dstMapCfgName = string.explode(dstMapCfgPltName, "|")[1]
                  local dstMapPltName = string.explode(dstMapCfgPltName, "|")[2]
                  
                  if prj.language == "C#" and dstMapPltName == "x86" then
                    dstMapPltName = "Win32"
                    dstMapCfgPltName = dstMapCfgName .. "|" .. dstMapPltName
                  end
                  
                  if srcMapCfgPltName == cfg.name then  -- We just found a valid entry in the supplied map. The entry matches the one we are processing right now.
                    -- now check if the mapped configuration exist in the project build configuration's list
                    local bMatchedMappedConfig = false
                    for _, buildConfigTest in ipairs(buildableConfigs) do
                      --printf("\t\tChecking: '%s'== '%s'", buildConfigTest.name, dstMapCfgPltName)
                      if buildConfigTest.name == dstMapCfgPltName then
                        bMatchedMappedConfig = true
                      end
                    end
                    if bMatchedMappedConfig == false then
                      error("Mapped configuration doesn't exist in the project: '" .. dstMapCfgPltName .. "'")
                    end
                    --printf("\t\t\tMapped:\t'%s'='%s'", mapEntries[1], mapEntries[2])
                    mappedConfig = dstMapCfgName
                    if prj.language == "C#" and dstMapPltName == "Win32" then 
                      mapped = "x86"
                    else
                      mapped = dstMapPltName
                    end
                    matchedCSharpConfig = true
                    break
                  end
                end
              end
              ------------------------------------------------------------
              
              if cfg.name == cfgPrjFullName or matchedCSharpConfig == true then            -- If our declared configuration matches it means it should be built
                if cfgPrj.kind then                       -- and after all we defined the output type of the file to generate with the build
                  _p('\t\t{%s}.%s.ActiveCfg = %s|%s', prj.uuid, cfg.name, mappedConfig, mapped)
                  _p('\t\t{%s}.%s.Build.0 = %s|%s',  prj.uuid, cfg.name, mappedConfig, mapped)
                  printf('\t\t\t|x|\t%s => %s|%s', cfg.name, mappedConfig, mapped)
                  bFound = true
                  break
                else
                  err = "project '" ..prj.name .. "' needs a kind in configuration '" .. cfgPrj.name .. "'"
                  error("\n\n\tError: " .. err .. "\n\n", 0)
                end
              end
            end
          end
          
          if not bFound then
            _p('\t\t{%s}.%s.ActiveCfg = %s', prj.uuid, cfg.name, tempMapped)
            printf('\t\t\t| |\t%s => %s', cfg.name, tempMapped)
          end
          
				end        
			end
		end
		_p('\tEndGlobalSection')
	end
	
	

--
-- Write out contents of the SolutionProperties section; currently unused.
--

	function premake.vs2005_solution_properties(sln)	
		_p('\tGlobalSection(SolutionProperties) = preSolution')
		_p('\t\tHideSolutionNode = FALSE')
		_p('\tEndGlobalSection')
	end
