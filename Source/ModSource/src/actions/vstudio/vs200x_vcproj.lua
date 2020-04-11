--
-- vs200x_vcproj.lua
-- Generate a Visual Studio 2002-2008 C/C++ project.
-- Copyright (c) 2009, 2010 Jason Perkins and the Premake project
--

premake.vstudio.vcproj = { }
local vcproj = premake.vstudio.vcproj


--
-- Write out the <Configuration> element.
--

	function vcproj.Configuration(name, cfg)
		_p(2,'<Configuration')
		_p(3,'Name="%s"', premake.esc(name))
		_p(3,'OutputDirectory="%s"', premake.esc(cfg.buildtarget.directory))
		_p(3,'IntermediateDirectory="%s"', premake.esc(cfg.objectsdir))
    if cfg.propertySheet and cfg.propertySheet ~= "" then
      _p(3,'InheritedPropertySheets="%s"', premake.esc(path.translate(cfg.propertySheet)))
    end
    
		_p(3,'ConfigurationType="%s"', _VS.cfgtype(cfg))
		if (cfg.flags.MFC) then
			_p(3, 'UseOfMFC="%s"', iif(cfg.kind == "StaticLib" and cfg.flags.StaticRuntime, 1, 2))
		end
    if cfg.flags.Unicode or cfg.flags.MultiByte then
      _p(3,'CharacterSet="%s"', iif(cfg.flags.Unicode, 1, 2))
    end
		if cfg.flags.Managed then
			_p(3,'ManagedExtensions="1"')
		end
		_p(3,'>')
	end
	
	
--
-- Write out the <Platforms> element; ensures that each target platform
-- is listed only once. Skips over .NET's pseudo-platforms (like "Any CPU").
--

	function premake.vs200x_vcproj_platforms(prj)
		local used = { }
		_p(1,'<Platforms>')
    buildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectPossibleBuildableConfigurations) -- Only create configs for the configurations that can be built.
    for _, cfg in ipairs(buildableConfigs) do
			if cfg.isreal and not table.contains(used, cfg.platform) then
				table.insert(used, cfg.platform)
				_p(2,'<Platform')
				_p(3,'Name="%s"', cfg.platform)
				_p(2,'/>')
			end
		end
		_p(1,'</Platforms>')
	end


--
-- Return the debugging symbols level for a configuration.
--

	function premake.vs200x_vcproj_symbols(cfg)
    if cfg.flags.Symbols then
      if not cfg.flags.NoEditAndContinue and _VS.optimization(cfg) == 0 then 
        return 4
      else
        return 3
      end
    else
      return -1 -- Take the default value when not defining Symbols
    end
	end

--
-- Compiler block for Wii platform.
--

  function premake.vs200x_vcproj_VCNMakeTool(cfg)
		_p(3,'<Tool')
		_p(4,'Name="VCNMakeTool"')
    _p(4,'BuildCommandLine="%s"', table.concat(premake.esc(cfg.buildoptions), "&#x0D;&#x0A;"))
    -- TODO Add support for ReBuildCommandLine - Implement it through: prebuildcommands
    _p(4,'CleanCommandLine="%s"', table.concat(premake.esc(cfg.linkoptions), "&#x0D;&#x0A;"))
    _p(4,'Output="%s"', premake.esc(cfg.buildtarget.directory) .. "\\" .. cfg.buildtarget.name)
    _p(4,'PreprocessorDefinitions="%s"', premake.esc(table.concat(cfg.defines, ";")))
    --[[ TODO Add support for the next field entries
        IncludeSearchPath=""
        ForcedIncludes=""
        AssemblySearchPath=""
        ForcedUsingAssemblies=""
        CompileAsManaged=""	
    --]]
		_p(3,'/>')
	end

  function premake.vs200x_vcproj_VCCustomBuildTool(cfg)
  
    local function writeField(name, content, sep)
      if (content and content ~= "" and content ~= {}) then
        local output = premake.esc(table.implode(content, "", "", sep))
        if output and output ~= "" then
          _p(4, '%s = "%s"', name, output)
        end
      end
    end
    
		_p(3,'<Tool')
		_p(4,'Name="VCCustomBuildTool"')
    
    -- CommandLine
    writeField("CommandLine", cfg.custombuildcommandline, "\r\n")
    writeField("Outputs", cfg.custombuildcommandlineOutput, ";")
    writeField("AdditionalDependencies", cfg.custombuildcommandlineDepends, ";")
    
    _p(3,'/>')
  end

	function premake.vs200x_vcproj_VCCLCompilerTool(cfg)
		_p(3,'<Tool')
		_p(4,'Name="%s"', iif(cfg.platform ~= "Xbox360", "VCCLCompilerTool", "VCCLX360CompilerTool"))
		
		if #cfg.buildoptions > 0 then
			_p(4,'AdditionalOptions="%s"', table.concat(premake.esc(cfg.buildoptions), " "))
		end
		
    if _VS.optimization(cfg) >= 0 then
      _p(4,'Optimization="%s"', _VS.optimization(cfg))
    end
		
		if cfg.flags.NoFramePointer then
			_p(4,'OmitFramePointers="%s"', _VS.bool(true))
		end
      
    if _VS.optimization(cfg) >= 2 then -- full optimization or maximize speed
       _p(4,'InlineFunctionExpansion="2"')
    elseif _VS.optimization(cfg) > 0 then
       _p(4,'InlineFunctionExpansion="1"')
    end
  
    if cfg.flags.VSEnableIntrinsicFunctions then
       _p(4, 'EnableIntrinsicFunctions="true"')
    end
    
    if (cfg.flags.VSFavorSize and not cfg.flags.VSFavorSpeed) or (cfg.flags.VSFavorSpeed and not cfg.flags.VSFavorSize) then
       _p(4, 'FavorSizeOrSpeed="%s"', iif(cfg.flags.VSFavorSize, 2, 1))
    end
      
		if #cfg.includedirs > 0 then
			_p(4,'AdditionalIncludeDirectories="%s"', premake.esc(path.translate(table.concat(cfg.includedirs, ";"), '\\')))
		end
		
		if #cfg.defines > 0 then
			_p(4,'PreprocessorDefinitions="%s"', premake.esc(table.concat(cfg.defines, ";")))
		end
		
		if premake.config.isdebugbuild(cfg) and not cfg.flags.NoMinimalRebuild and not cfg.flags.Managed then
			_p(4,'MinimalRebuild="%s"', _VS.bool(true))
		end
		
		if cfg.flags.NoExceptions then
			_p(4,'ExceptionHandling="%s"', iif(_ACTION < "vs2005", "FALSE", 0))
		elseif cfg.flags.SEH and _ACTION > "vs2003" then
			_p(4,'ExceptionHandling="2"')
		end
		
    if _VS.optimization(cfg) == 0 and not (cfg.flags.VSNoBasicRuntimeCheck or cfg.flags.Managed) then
			_p(4,'BasicRuntimeChecks="3"')
		end
    
    if cfg.flags.VSNoStringPooling then
      _p(4,'StringPooling="%s"', _VS.bool(false))
		elseif _VS.optimization(cfg) > 0 then
			_p(4,'StringPooling="%s"', _VS.bool(true))
		end
		
		local runtime
		if premake.config.isdebugbuild(cfg) then
			runtime = iif(cfg.flags.StaticRuntime, 1, 3)
		else
			runtime = iif(cfg.flags.StaticRuntime, 0, 2)
		end
		
    if not (cfg.propertySheet or cfg.propertySheet == "") or cfg.platform == "Xbox360" then  -- XBox360 .vsprops contents are not fully supported in VS.
      _p(4,'RuntimeLibrary="%s"', runtime)
    end
    
    if not cfg.flags.VSBufferSecurityCheck then
      _p(4,'BufferSecurityCheck="%s"', _VS.bool(false))
    end
    
    if cfg.flags.VSEnableFunctionLevelLinking then
       _p(4,'EnableFunctionLevelLinking="%s"', _VS.bool(true))
    end

		if _ACTION > "vs2003" and cfg.platform ~= "Xbox360" and cfg.platform ~= "x64" then
			if cfg.flags.EnableSSE then
				_p(4,'EnableEnhancedInstructionSet="1"')
			elseif cfg.flags.EnableSSE2 then
				_p(4,'EnableEnhancedInstructionSet="2"')
			end
		end
	
		if _ACTION < "vs2005" then
			if cfg.flags.FloatFast then
				_p(4,'ImproveFloatingPointConsistency="%s"', _VS.bool(false))
			elseif cfg.flags.FloatStrict then
				_p(4,'ImproveFloatingPointConsistency="%s"', _VS.bool(true))
			end
		else
			if cfg.flags.FloatFast then
				_p(4,'FloatingPointModel="2"')
			elseif cfg.flags.FloatStrict then
				_p(4,'FloatingPointModel="1"')
			end
		end
		
		if _ACTION < "vs2005" and not cfg.flags.NoRTTI then
			_p(4,'RuntimeTypeInfo="%s"', _VS.bool(true))
		elseif _ACTION > "vs2003" and cfg.flags.NoRTTI then
			_p(4,'RuntimeTypeInfo="%s"', _VS.bool(false))
		end
		
		if cfg.flags.NativeWChar then
			_p(4,'TreatWChar_tAsBuiltInType="%s"', _VS.bool(true))
		elseif cfg.flags.NoNativeWChar then
			_p(4,'TreatWChar_tAsBuiltInType="%s"', _VS.bool(false))
		end
		
		if not cfg.flags.NoPCH and cfg.pchheader and cfg.pchheader ~= "" then
			_p(4,'UsePrecompiledHeader="%s"', iif(_ACTION < "vs2005", 3, 2))
			_p(4,'PrecompiledHeaderThrough="%s"', iif(cfg.flags.VSUseFullPathPCH, path.translate(cfg.pchheader, "\\"), path.getname(cfg.pchheader)))
		else
      if cfg.flags.NoPCH then
        _p(4,'UsePrecompiledHeader="%s"', iif(_ACTION > "vs2003", 0, 2))
      end
		end
    
    if cfg.flags.Symbols then
      if cfg.kind == "StaticLib" then
        _p(4,'ProgramDataBaseFileName="$(TargetDir)$(TargetName).pdb"')
      end
    end
		
    if cfg.flags.ExtraWarnings or not cfg.flags.MinWarnings then
      _p(4,'WarningLevel="%s"', iif(cfg.flags.ExtraWarnings, 4, 3))
    end
		
		if cfg.flags.FatalWarnings then
			_p(4,'WarnAsError="%s"', _VS.bool(true))
		end
		
		if _ACTION < "vs2008" and not cfg.flags.Managed then
			_p(4,'Detect64BitPortabilityProblems="%s"', _VS.bool(not cfg.flags.No64BitChecks))
		end
    
    if premake.vs200x_vcproj_symbols(cfg) >= 0 then
      _p(4,'DebugInformationFormat="%s"', premake.vs200x_vcproj_symbols(cfg))
    end
    
    if cfg.disablespecificwarnings then
      _p(4,'DisableSpecificWarnings="%s"', premake.esc(table.concat(cfg.disablespecificwarnings, ";")))
    end
    
    -- ForcedUsingFiles
    if cfg.forcedusingfiles and #cfg.forcedusingfiles > 0 then
      _p(4, 'ForcedUsingFiles="%s"', premake.esc(table.concat(cfg.forcedusingfiles, ";")))
    end
    
    if cfg.callingConvention == "cdecl" then
      _p(4, 'CallingConvention="0"')
    elseif cfg.callingConvention == "fastcall" then
      _p(4, 'CallingConvention="1"')
    elseif cfg.callingConvention == "stdcall" then
      _p(4, 'CallingConvention="2"')
    end
    
		if cfg.language == "C" then
			_p(4, 'CompileAs="1"')
    elseif cfg.language == "Default" then
      _p(4,'CompileAs="0"')
		end
		_p(3,'/>')
	end
	
	

--
-- Linker block for Windows and Xbox 360 platforms.
--

  function premake.vs200x_vcproj_VCLinkerTool_common_section(cfg)
  
    if cfg.kind == "StaticLib" then
      if not cfg.flags.NoLinkLibDependencies then -- Funny... the default value is different for visual studio (2008) when having static lib output type or executable...
        _p(4,'LinkLibraryDependencies="%s"', 1)
      end
    else
      if cfg.flags.NoLinkLibDependencies then -- Funny... the default value is different for visual studio (2008) when having nont static lib output type or executable...
        _p(4,'LinkLibraryDependencies="%s"', 0)
      end
    end
    
    if #cfg.linkoptions > 0 then
      _p(4,'AdditionalOptions="%s"', table.concat(premake.esc(cfg.linkoptions), " "))
    end
  
    if #cfg.links > 0 then
      _p(4,'AdditionalDependencies="%s"', premake.esc(table.concat(premake.getlinks(cfg, "system", "fullpath"), " ")))
    end
  
    if cfg.flags.VSIgnoreAllDefaultLibs then
      _p(4, 'IgnoreAllDefaultLibraries="true"')
    end
    
    -- Default values of visual studio here... $(OutDir)$(TargetName)$(TargetExt)
    --_p(4,'OutputFile="$(OutDir)\\%s"', cfg.buildtarget.name)

    if #cfg.libdirs > 0 then
      _p(4,'AdditionalLibraryDirectories="%s"', table.concat(premake.esc(path.translate(cfg.libdirs, '\\')) , ";"))
    end
    
    if cfg.ignoredefaultlibrarynames then
      _p(4,'IgnoreDefaultLibraryNames="%s"', premake.esc(table.concat(cfg.ignoredefaultlibrarynames, ";")))
    end
    
	end

	function premake.vs200x_vcproj_VCLinkerTool(cfg)
		_p(3,'<Tool')
		if cfg.kind ~= "StaticLib" then
      _p(4,'Name="%s"', iif(cfg.platform ~= "Xbox360", "VCLinkerTool", "VCX360LinkerTool"))
			
      --premake.vs200x_vcproj_VCLinkerTool_common_section(cfg)    
      if cfg.flags.NoLinkLibDependencies then -- Funny... the default value is different for visual studio (2008) when having nont static lib output type or executable...
        _p(4,'LinkLibraryDependencies="%s"', 0)
      end
      
      if #cfg.linkoptions > 0 then
        _p(4,'AdditionalOptions="%s"', table.concat(premake.esc(cfg.linkoptions), " "))
      end
    
      if #cfg.links > 0 then
        _p(4,'AdditionalDependencies="%s"', premake.esc(table.concat(premake.getlinks(cfg, "system", "fullpath"), " ")))
      end
    
      _p(4,'OutputFile="$(OutDir)\\%s"', cfg.buildtarget.name)
      
      if cfg.flags.NoIncrementalLink then
        _p(4,'LinkIncremental="%s"', 1)
      elseif not (cfg.propertySheet or cfg.propertySheet == "") then
        _p(4,'LinkIncremental="%s"', 2)
      end

      if #cfg.libdirs > 0 then
        _p(4,'AdditionalLibraryDirectories="%s"', table.concat(premake.esc(path.translate(cfg.libdirs, '\\')) , ";"))
      end
      
      if cfg.ignoredefaultlibrarynames then
        _p(4,'IgnoreDefaultLibraryNames="%s"', premake.esc(table.concat(cfg.ignoredefaultlibrarynames, ";")))
      end
    
			if cfg.flags.NoImportLib then
				_p(4,'IgnoreImportLibrary="%s"', _VS.bool(true))
			end      

      if cfg.delayloadeddlls then
        _p(4,'DelayLoadDLLs="%s"', premake.esc(table.concat(cfg.delayloadeddlls, ";")))
      end

      local deffile = premake.findfile(cfg, ".def")
      if deffile then
        _p(4,'ModuleDefinitionFile="%s"', deffile)
      end

      if cfg.flags.NoManifest then
        _p(4,'GenerateManifest="%s"', _VS.bool(false))
      end

      if cfg.flags.Symbols then
        _p(4,'GenerateDebugInformation="%s"', _VS.bool(true))
      end

      if cfg.flags.Symbols then
        -- Not needed. Defaults to $(TargetDir)$(TargetName).pdb
        --_p(4,'ProgramDatabaseFile="$(OutDir)\\%s.pdb"', path.getbasename(cfg.buildtarget.name))
        if cfg.flags.GenerateStrippedSymbols then
          _p(4,'StripPrivateSymbols="$(TargetDir)$(TargetName)-STRIPPED.pdb"')
        end
      end
            
      if not cfg.flags.VSNoSubSystem then
        _p(4,'SubSystem="%s"', iif(cfg.kind == "ConsoleApp", 1, 2))
      end

      local COMDATFolding = iif(cfg.flags.VSNoCOMDATFolding, 0, 2)
      local References = iif(cfg.flags.VSNoOptimizeReferences, 0, 2)

      if _VS.optimization(cfg) > 0 then
        if References > 0 then
           _p(4,'OptimizeReferences="2"')
        end
        if COMDATFolding > 0 then
           _p(4,'EnableCOMDATFolding="2"')
        end
      end
			
			if (cfg.kind == "ConsoleApp" or cfg.kind == "WindowedApp") and not cfg.flags.WinMain then
				_p(4,'EntryPointSymbol="mainCRTStartup"')
			end
			
      if not cfg.flags.NoImportLib then
        if cfg.kind == "SharedLib" or cfg.kind == "ConsoleApp" or cfg.kind == "WindowedApp" then
          _p(4,'ImportLibrary="$(TargetDir)$(TargetName).lib"')
        end
      end
			
      local targetMachine = iif(cfg.platform == "x64", 17, 1)
      if cfg.flags.VSNoTargetMachine then -- or (cfg.propertySheet and cfg.propertySheet ~= "") then
       targetMachine = 0
      end
               
      if targetMachine > 0 and not (cfg.propertySheet and cfg.propertySheet ~= "") then
        _p(4,'TargetMachine="%d"', targetMachine)
      end
      
      if cfg.StackReserveSize and cfg.StackReserveSize ~= "" then
        _p(4,'StackReserveSize="%s"', cfg.StackReserveSize)
      end
      
      if cfg.StackCommitSize and cfg.StackCommitSize ~= "" then
        _p(4,'StackCommitSize="%s"', cfg.StackCommitSize)
      end
		
		else
			_p(4,'Name="VCLibrarianTool"')
		
			premake.vs200x_vcproj_VCLinkerTool_common_section(cfg)
		
    end
    
		
		_p(3,'/>')
	end
	
	
--
-- Compiler and linker blocks for the PS3 platform, which uses GCC.
--

	function premake.vs200x_vcproj_VCCLCompilerTool_GCC(cfg)
		_p(3,'<Tool')
		_p(4,'Name="VCCLCompilerTool"')

		local buildoptions = table.join(premake.gcc.getcflags(cfg), premake.gcc.getcxxflags(cfg), cfg.buildoptions)
		if #buildoptions > 0 then
			_p(4,'AdditionalOptions="%s"', premake.esc(table.concat(buildoptions, " ")))
		end

		if #cfg.includedirs > 0 then
			_p(4,'AdditionalIncludeDirectories="%s"', premake.esc(path.translate(table.concat(cfg.includedirs, ";"), '\\')))
		end

		if #cfg.defines > 0 then
			_p(4,'PreprocessorDefinitions="%s"', table.concat(premake.esc(cfg.defines), ";"))
		end

		--_p(4,'ProgramDataBaseFileName="$(OutDir)\\%s.pdb"', path.getbasename(cfg.buildtarget.name))
		_p(4,'DebugInformationFormat="0"')
		_p(4,'CompileAs="0"')
		_p(3,'/>')
	end

	function premake.vs200x_vcproj_VCLinkerTool_GCC(cfg)
		_p(3,'<Tool')
		if cfg.kind ~= "StaticLib" then
			_p(4,'Name="VCLinkerTool"')
			
			local buildoptions = table.join(premake.gcc.getldflags(cfg), cfg.linkoptions)
			if #buildoptions > 0 then
				_p(4,'AdditionalOptions="%s"', premake.esc(table.concat(buildoptions, " ")))
			end
			
			if #cfg.links > 0 then
				_p(4,'AdditionalDependencies="%s"', premake.esc(table.concat(premake.getlinks(cfg, "all", "fullpath"), " ")))
			end
			
      -- Default values of visual studio here... $(OutDir)$(TargetName)$(TargetExt)
			--_p(4,'OutputFile="$(OutDir)\\%s"', cfg.buildtarget.name)
			_p(4,'LinkIncremental="0"')
			_p(4,'AdditionalLibraryDirectories="%s"', table.concat(premake.esc(path.translate(cfg.libdirs, '\\')) , ";"))
			_p(4,'GenerateManifest="%s"', _VS.bool(false))
			_p(4,'ProgramDatabaseFile=""')
			_p(4,'RandomizedBaseAddress="1"')
			_p(4,'DataExecutionPrevention="0"')			
		else
			_p(4,'Name="VCLibrarianTool"')

			local buildoptions = table.join(premake.gcc.getldflags(cfg), cfg.linkoptions)
			if #buildoptions > 0 then
				_p(4,'AdditionalOptions="%s"', premake.esc(table.concat(buildoptions, " ")))
			end
		
			if #cfg.links > 0 then
				_p(4,'AdditionalDependencies="%s"', premake.esc(table.concat(premake.getlinks(cfg, "all", "fullpath"), " ")))
			end
		
			_p(4,'OutputFile="$(OutDir)\\%s"', cfg.buildtarget.name)

			if #cfg.libdirs > 0 then
				_p(4,'AdditionalLibraryDirectories="%s"', premake.esc(path.translate(table.concat(cfg.libdirs , ";"))))
			end
      
      if not cfg.flags.NoLinkLibDependencies then
        _p(4,'LinkLibraryDependencies="1"' )
      end
      
		end
		
		_p(3,'/>')
	end
	


--
-- Resource compiler block.
--

	function premake.vs200x_vcproj_VCResourceCompilerTool(cfg)
		_p(3,'<Tool')
		_p(4,'Name="VCResourceCompilerTool"')

		if #cfg.resoptions > 0 then
			_p(4,'AdditionalOptions="%s"', table.concat(premake.esc(cfg.resoptions), " "))
		end

		if #cfg.resdefines > 0 then
         _p(4,'PreprocessorDefinitions="%s"', table.concat(premake.esc(cfg.resdefines), ";"))
		end

		if #cfg.resincludedirs > 0 then
         local dirs = cfg.resincludedirs
		 _p(4,'AdditionalIncludeDirectories="%s"', premake.esc(path.translate(table.concat(dirs, ";"), '\\')))
		end
      
      if cfg.VSresculture and cfg.VSresculture ~= "" then
         _p(4, 'Culture="%s"', cfg.VSresculture)
      end

		_p(3,'/>')
	end
	
	

--
-- Manifest block.
--

	function premake.vs200x_vcproj_VCManifestTool(cfg)
		-- locate all manifest files
		local manifests = { }
		for _, fname in ipairs(cfg.files) do
			if path.getextension(fname) == ".manifest" then
				table.insert(manifests, fname)
			end
		end
		
		_p(3,'<Tool')
		_p(4,'Name="VCManifestTool"')
		if #manifests > 0 then
			_p(4,'AdditionalManifestFiles="%s"', premake.esc(table.concat(manifests, ";")))
		end
		_p(3,'/>')
	end



--
-- VCMIDLTool block
--

	function premake.vs200x_vcproj_VCMIDLTool(cfg)
		_p(3,'<Tool')
		_p(4,'Name="VCMIDLTool"')
		if cfg.platform == "x64" then
			_p(4,'TargetEnvironment="3"')
		end
		_p(3,'/>')
	end

	

--
-- Write out a custom build steps block.
--

	function premake.vs200x_vcproj_buildstepsblock(name, steps, desc)
		_p(3,'<Tool')
		_p(4,'Name="%s"', name)
		if #steps > 0 then
      if desc and desc ~= "" then
        tempDesc = { desc }
        _p(4, 'Description="%s"', premake.esc(table.implode(tempDesc, "", "", "\r\n")))
      end
      if (#steps > 1) or (#steps == 1 and steps[1] ~= "") then
        _p(4,'CommandLine="%s"', premake.esc(table.implode(steps, "", "", "\r\n")))
      end
		end
		_p(3,'/>')
	end



--
-- Map project tool blocks to handler functions. Unmapped blocks will output
-- an empty <Tool> element.
--

	local blockmap = 
	{
		VCCLCompilerTool       = premake.vs200x_vcproj_VCCLCompilerTool,
		VCCLCompilerTool_GCC   = premake.vs200x_vcproj_VCCLCompilerTool_GCC,
		VCLinkerTool           = premake.vs200x_vcproj_VCLinkerTool,
		VCLinkerTool_GCC       = premake.vs200x_vcproj_VCLinkerTool_GCC,
		VCManifestTool         = premake.vs200x_vcproj_VCManifestTool,
		VCMIDLTool             = premake.vs200x_vcproj_VCMIDLTool,
		VCResourceCompilerTool = premake.vs200x_vcproj_VCResourceCompilerTool,
    VCNMakeTool            = premake.vs200x_vcproj_VCNMakeTool,
    VCCustomBuildTool      = premake.vs200x_vcproj_VCCustomBuildTool,
	}
	
	
--
-- Return a list of sections for a particular Visual Studio version and target platform.
--

	local function getsections(version, platform, cfg)
		if version == "vs2002" then
			return {
				"VCCLCompilerTool",
				"VCCustomBuildTool",
				"VCLinkerTool",
				"VCMIDLTool",
				"VCPostBuildEventTool",
				"VCPreBuildEventTool",
				"VCPreLinkEventTool",
				"VCResourceCompilerTool",
				"VCWebServiceProxyGeneratorTool",
				"VCWebDeploymentTool"
			}
		end
		if version == "vs2003" then
			return {
				"VCCLCompilerTool",
				"VCCustomBuildTool",
				"VCLinkerTool",
				"VCMIDLTool",
				"VCPostBuildEventTool",
				"VCPreBuildEventTool",
				"VCPreLinkEventTool",
				"VCResourceCompilerTool",
				"VCWebServiceProxyGeneratorTool",
				"VCXMLDataGeneratorTool",
				"VCWebDeploymentTool",
				"VCManagedWrapperGeneratorTool",
				"VCAuxiliaryManagedWrapperGeneratorTool"
			}
		end
		if platform == "Xbox360" then
			return {
				"VCPreBuildEventTool",
				"VCCustomBuildTool",
				"VCXMLDataGeneratorTool",
				"VCWebServiceProxyGeneratorTool",
				"VCMIDLTool",
				"VCCLCompilerTool",
				"VCManagedResourceCompilerTool",
				"VCResourceCompilerTool",
				"VCPreLinkEventTool",
				"VCLinkerTool",
				"VCALinkTool",
				"VCX360ImageTool",
				"VCBscMakeTool",
				"VCX360DeploymentTool",
				"VCPostBuildEventTool",
				"DebuggerTool",
			}
		end
    if platform == "Cafe" then
			return {	-- TODO - Add here the specific sections of the WiiU platform.
        "VCPreBuildEventTool",
        "VCCustomBuildTool",
        "VCCLCompilerTool",
        "VCPreLinkEventTool",
        "VCLinkerTool",
        "VCALinkTool",
        "VCManifestTool",
        "VCXDCMakeTool",
        "VCBscMakeTool",
        "VCFxCopTool",
        "VCAppVerifierTool",
        "VCPostBuildEventTool"
			}
		end
		if platform == "PS3" then
			return {	
            "VCPreBuildEventTool",
            "VCCustomBuildTool",
            "VCXMLDataGeneratorTool",
            "VCWebServiceProxyGeneratorTool",
            "VCMIDLTool",
            "VCCLCompilerTool",
            "VCManagedResourceCompilerTool",
            "VCResourceCompilerTool",
            "VCPreLinkEventTool",
            "VCLinkerTool",
            "VCALinkTool",
            "VCManifestTool",
            "VCXDCMakeTool",
            "VCBscMakeTool",
            "VCFxCopTool",
            "VCAppVerifierTool",
            --"VCWebDeploymentTool", No web deployment tool to preserve order. Is it used at all?
            "VCPostBuildEventTool"
          }
		else
      if cfg.flags then      
        if cfg.kind == "Makefile" then
          return { "VCNMakeTool" }
        else
          return {	
            "VCPreBuildEventTool",
            "VCCustomBuildTool",
            "VCXMLDataGeneratorTool",
            "VCWebServiceProxyGeneratorTool",
            "VCMIDLTool",
            "VCCLCompilerTool",
            "VCManagedResourceCompilerTool",
            "VCResourceCompilerTool",
            "VCPreLinkEventTool",
            "VCLinkerTool",
            "VCALinkTool",
            "VCManifestTool",
            "VCXDCMakeTool",
            "VCBscMakeTool",
            "VCFxCopTool",
            "VCAppVerifierTool",
            --"VCWebDeploymentTool", No web deployment tool to preserve order. Is it used at all?
            "VCPostBuildEventTool"
          }
        end
      else
        return { "" }
      end
		end
	end



--
-- The main function: write the project file.
--

	function premake.vs200x_vcproj(prj)
		io.eol = "\r\n"
		_p('<?xml version="1.0" encoding="Windows-1252"?>')
		
		-- Write opening project block
		_p('<VisualStudioProject')
		_p(1,'ProjectType="Visual C++"')
		if _ACTION == "vs2002" then
			_p(1,'Version="7.00"')
		elseif _ACTION == "vs2003" then
			_p(1,'Version="7.10"')
		elseif _ACTION == "vs2005" then
			_p(1,'Version="8.00"')
		elseif _ACTION == "vs2008" then
			_p(1,'Version="9.00"')
		end
		_p(1,'Name="%s"', premake.esc(prj.nicename))
		_p(1,'ProjectGUID="{%s}"', prj.uuid)
		if _ACTION > "vs2003" then
			_p(1,'RootNamespace="%s"', prj.name)
		end
    
		_p(1,'Keyword="%s"', iif(prj.flags.Managed or premake.vstudio_isManaged(prj), "ManagedCProj", "Win32Proj"))
    _p(1,'TargetFrameworkVersion="0"')
		_p(1,'>')

		-- list the target platforms
		premake.vs200x_vcproj_platforms(prj)

		if _ACTION > "vs2003" then
			_p(1,'<ToolFiles>')
			_p(1,'</ToolFiles>')
		end

		_p(1,'<Configurations>')
    buildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectPossibleBuildableConfigurations) -- Create configs for the configurations that could be built.
    
    -- Build the whole possible permutations for creating the dummy configurations blocks.
    -- NOTE: Important note here: we CAN NOT use premake.project.each to iterate through
    --      them because the object returned by that iterator is a COLLAPSED configuration
    --      block (instead the real 'project' object) against the solution where the project 
    --      is referenced from.
    -- We need to generate those "dummy" blocks for non-existent build configurations otherwise 
    -- VS always ask you to save the project file.
    local allPermutations = nil
    for sln in premake.solution.each() do
      for _, objPrj in ipairs(sln.projects) do
        if prj.name == objPrj.name then
          allPermutations = premake.vstudio_buildconfigs(objPrj)
          break
        end
      end
    end
    
    -- Return a configuration object from a given configuration container.
    -- It does return the first configuration in the list if the configuration
    -- you specified doesn't exist in the list.
    local function getConfig(config, configList)
      local bConfigDefined = false
      for _, cfginfo in ipairs(configList) do
        if cfginfo.src_buildcfg == config.src_buildcfg and cfginfo.src_platform == config.src_platform then
          bConfigDefined = true
          if cfginfo.isreal then
            cfg = premake.getconfig(prj, cfginfo.src_buildcfg, cfginfo.src_platform)
          end
          break
        end
      end
      if bConfigDefined == false then
        cfg = premake.getconfig(prj, buildableConfigs[1].src_buildcfg, buildableConfigs[1].src_platform)
      end
      
      return cfg
    end
    
    -- All perm
    --[[
    printf("CONFIG PERMUTATIONS:")
    for _, cfginfo in ipairs(allPermutations) do
      printf("\t%s|%s", cfginfo.buildcfg, cfginfo.platform)
    end
    --]]
    
    for _, cfginfo in ipairs(allPermutations) do
      local bConfigDefined = false
      local cfg = getConfig(cfginfo, buildableConfigs) -- If the build configuration we are checking for do exist, we will get our configuration block, otherwise we will get a dummy one. It really doesn't matter because this build configuration will not be set to be built.
      
      -- Start a configuration
      vcproj.Configuration(cfginfo.name, cfg)				
      for _, block in ipairs(getsections(_ACTION, cfginfo.src_platform, cfg)) do
      
        if blockmap[block] then
          blockmap[block](cfg)
  
        -- Build event blocks --
        elseif block == "VCPreBuildEventTool" then
          premake.vs200x_vcproj_buildstepsblock("VCPreBuildEventTool", cfg.prebuildcommands, cfg.prebuilddesc)
        elseif block == "VCPreLinkEventTool" then
          premake.vs200x_vcproj_buildstepsblock("VCPreLinkEventTool", cfg.prelinkcommands)
        elseif block == "VCPostBuildEventTool" then
          premake.vs200x_vcproj_buildstepsblock("VCPostBuildEventTool", cfg.postbuildcommands, cfg.postbuilddesc)
        -- End build event blocks --
        
        -- Xbox 360 custom sections --
        elseif block == "VCX360DeploymentTool" then
          _p(3,'<Tool')
          _p(4,'Name="VCX360DeploymentTool"')
          _p(4,'DeploymentType="0"')
          if #cfg.deploymentoptions > 0 then
            _p(4,'AdditionalOptions="%s"', table.concat(premake.esc(cfg.deploymentoptions), " "))
          end
          -- TODO This is hardcoded. Add a parameter in api.lua for this.
          if cfg.XBoxDeploymentHD ~= nil and cfg.XBoxDeploymentHD ~= "" then
            _p(4,'RemoteRoot="%s"', cfg.XBoxDeploymentHD)
          end
          
          _p(3,'/>')

        elseif block == "VCX360ImageTool" then
          _p(3,'<Tool')
          _p(4,'Name="VCX360ImageTool"')
          if #cfg.imageoptions > 0 then
            _p(4,'AdditionalOptions="%s"', table.concat(premake.esc(cfg.imageoptions), " "))
          end
          if cfg.imagepath ~= nil then
            _p(4,'OutputFileName="%s"', premake.esc(path.translate(cfg.imagepath)))
          end
          _p(3,'/>')
          
        elseif block == "DebuggerTool" then
          _p(3,'<DebuggerTool')
          _p(3,'/>')
        
        -- End Xbox 360 custom sections --
          
        else
          _p(3,'<Tool')
          _p(4,'Name="%s"', block)
          _p(3,'/>')
        end
        
      end

      _p(2,'</Configuration>')
    end
		_p(1,'</Configurations>')

		_p(1,'<References>')
    if prj.flags and prj.flags.VSUseReferencesInProjects then
      local deps = premake.getreferences(prj)
			if #deps > 0 then
				for _, dep in ipairs(deps) do
          _p(2, "<ProjectReference")
            _p(3, 'ReferencedProjectIdentifier="{%s}"', dep.uuid)
            _p(3, 'CopyLocal="false"')
            -- Build a relative path from the solution file to the project file
            local projpath = path.translate(path.getrelative(prj.location, _VS.projectfile(dep)), "\\")
            _p(3, 'RelativePathToProject="%s"', projpath)
          _p(2, "/>")
				end
			end
      
      local assembliesreferences = premake.getassembliesreferences(prj)
      --for _, linkname in ipairs(premake.getlinks(prj, "system", "basename")) do
      if #assembliesreferences > 0 then
        for _, linkname in ipairs(assembliesreferences) do
          _p(2, '<AssemblyReference')
            _p(3, 'RelativePath="%s"', premake.esc(linkname) .. ".dll")
            _p(3, 'AssemblyName="%s"', premake.esc(linkname))
            _p(3, 'MinFrameworkVersion="0"')
          _p(2, '/>')
        end
      end
    end
		_p(1,'</References>')
		
		_p(1,'<Files>')
		premake.walksources(prj, _VS.files)
		_p(1,'</Files>')
		
		_p(1,'<Globals>')
		_p(1,'</Globals>')
		_p('</VisualStudioProject>')
	end



