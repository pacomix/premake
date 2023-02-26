
premake.vstudio.vs11_helpers = { }
local vs11_helpers = premake.vstudio.vs11_helpers
	
		
	function vs11_helpers.remove_relative_path(file)
		file = file:gsub("%.%.\\",'')
		file = file:gsub("%.\\",'')
		return file
	end
		
	function vs11_helpers.file_path(file)
		file = vs11_helpers.remove_relative_path(file)
		local path = string.find(file,'\\[%w%.%_%-]+$')
		if path then
			return string.sub(file,1,path-1)
		else
			return nil
		end
	end
	
	function vs11_helpers.list_of_directories_in_path(path)
		local list={}
		path = vs11_helpers.remove_relative_path(path)
		if path then
			for dir in string.gmatch(path,"[%w%-%_%.]+\\")do
				if #list == 0 then
					list[1] = dir:sub(1,#dir-1)
				else
					list[#list +1] = list[#list] .."\\" ..dir:sub(1,#dir-1)				
				end
			end		
		end
		return list
	end

	function vs11_helpers.table_of_file_filters(files)
		local filters ={}

		for _, valueTable in pairs(files) do
			for _, entry in ipairs(valueTable) do
				local result = vs11_helpers.list_of_directories_in_path(entry)
				for __,dir in ipairs(result) do
					if table.contains(filters,dir) ~= true then
					filters[#filters +1] = dir
					end
				end
			end
		end
		
		return filters
	end
	
	function vs11_helpers.get_file_extension(file)
		local ext_start,ext_end = string.find(file,"%.[%w_%-]+$")
		if ext_start then
			return  string.sub(file,ext_start+1,ext_end)
		end
	end
	

	
	--also translates file paths from '/' to '\\'
	function vs11_helpers.sort_input_files(prj,files,sorted_container)
		local types = 
		{	
			h	= "ClInclude",
			hpp	= "ClInclude",
			hxx	= "ClInclude",
			c	= "ClCompile",
			cpp	= "ClCompile",
			cxx	= "ClCompile",
			cc	= "ClCompile",
			appxmanifest	= "AppxManifest",
			rc  = "ResourceCompile"
		}

		for _, current_file in ipairs(files) do
			local translated_path = path.translate(current_file, '\\')
			local ext = vs11_helpers.get_file_extension(translated_path)
			if ext then
      
        local bHasCustomBuildCommand = false
        if prj then
          local fcfg = premake.getfileconfig(prj, current_file)

          if fcfg then
            if (fcfg.custombuildcommandline and fcfg.custombuildcommandline ~= "" and fcfg.custombuildcommandline ~= {}) then
              local commandLine = table.implode(fcfg.custombuildcommandline, "", "", "\r\n")
              if commandLine and commandLine ~= "" then
                bHasCustomBuildCommand = true
              end
            end
          end
        end
        
				local type = types[ext]
        if bHasCustomBuildCommand then
          table.insert(sorted_container.CustomBuild,translated_path)
        elseif type then
					table.insert(sorted_container[type],translated_path)
				else
          table.insert(sorted_container.None,translated_path)
        end
			end
		end
	end	
		
		
	
	local function vs2012_config(prj)		
		_p(1,'<ItemGroup Label="ProjectConfigurations">')
    
    local buildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectPossibleBuildableConfigurations) -- Only create configs for the configurations that can be built.
    for _, cfginfo in ipairs(buildableConfigs) do
        _p(2,'<ProjectConfiguration Include="%s">', premake.esc(cfginfo.name))
					_p(3,'<Configuration>%s</Configuration>',cfginfo.buildcfg)
					_p(3,'<Platform>%s</Platform>',cfginfo.platform)
				_p(2,'</ProjectConfiguration>')
      --end
    end
		_p(1,'</ItemGroup>')
	end
	
	local function vs2012_globals(prj)
		_p(1,'<PropertyGroup Label="Globals">')
			_p(2,'<ProjectGuid>{%s}</ProjectGuid>',prj.uuid)
			_p(2,'<RootNamespace>%s</RootNamespace>',prj.name)
			_p(2,'<Keyword>%s</Keyword>', iif(prj.flags.Managed or premake.vstudio_isManaged(prj), "ManagedCProj", "Win32Proj"))  -- In visual studio this value can be inherited from property sheets but we always overwrite it in order behave like the VS2008 generator.
      _p(2,'<ProjectName>%s</ProjectName>', prj.nicename)
		_p(1,'</PropertyGroup>')
	end
	
	function vs11_helpers.config_type(config)
		local t =
		{	
			SharedLib = "DynamicLibrary",
			StaticLib = "StaticLibrary",
			ConsoleApp = "Application",
			WindowedApp = "Application"
		}
		return t[config.kind]
	end
	
	local function if_config_and_platform()
		return 'Condition="\'$(Configuration)|$(Platform)\'==\'%s\'"'
	end	
	
	local function optimisation(cfg)
		local result = "Disabled"
    
    if (cfg.propertySheet and cfg.propertySheet ~= "") and not (cfg.flags.Optimize or cfg.flags.OptimizeSize or cfg.flags.OptimizeSpeed) then
      result = ""
    elseif cfg.flags.Optimize then
				result = "Full"
    elseif cfg.flags.OptimizeSize then
      result = "MinSpace"
    elseif cfg.flags.OptimizeSpeed then
      result = "MaxSpeed"
    end
		return result
	end
		
	local function config_type_block(prj)
  
    local buildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectPossibleBuildableConfigurations) -- Only create configs for the configurations that can be built.
    for _, cfginfo in ipairs(buildableConfigs) do
      local cfg = premake.getconfig(prj, cfginfo.src_buildcfg, cfginfo.src_platform)
      _p(1,'<PropertyGroup '..if_config_and_platform() ..' Label="Configuration">'
          , premake.esc(cfginfo.name))
        _p(2,'<ConfigurationType>%s</ConfigurationType>',vs11_helpers.config_type(cfg))
        if cfg.flags.Unicode or cfg.flags.MultiByte then
          _p(2,'<CharacterSet>%s</CharacterSet>',iif(cfg.flags.Unicode,"Unicode","MultiByte"))
        end
      
      if cfg.flags.Managed then
        _p(2, '<CLRSupport>true</CLRSupport>')
      end
      
      if cfg.flags.MFC then
        if cfg.flags.StaticRuntime then
          _p(2,'<UseOfMfc>Static</UseOfMfc>')
        else
          _p(2,'<UseOfMfc>Dynamic</UseOfMfc>')
        end
      end
      
      local use_debug = "false"
      if optimisation(cfg) == "Disabled" then 
        use_debug = "true"
      elseif optimisation(cfg) == "" then -- Inherit value from property sheet when it is empty string.
        use_debug = ""  
      else
        -- Commented out to match vs2008. TODO Add a new flag to set this parameter IE: UseWholeProgramOptimization
        --_p(2,'<WholeProgramOptimization>true</WholeProgramOptimization>')
      end
      if use_debug ~= ""  then
        _p(2,'<UseDebugLibraries>%s</UseDebugLibraries>',use_debug)
      end
      
      if cfg.toolset and cfg.toolset ~= "" then
        _p(2,'<PlatformToolset>%s</PlatformToolset>', cfg.toolset)
      else 
        -- always need toolset or will think it is a vs2010 proj
        _p(1,'<PlatformToolset>v110</PlatformToolset>')
      end
      
      if cfg.androidarch and cfg.androidarch ~= "" then
        _p(2,'<AndroidArch>%s</AndroidArch>', cfg.androidarch)
      end
      
      _p(1,'</PropertyGroup>')
    end
	end

	
	local function import_props(prj)
  
    local buildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectPossibleBuildableConfigurations) -- Only create configs for the configurations that can be built.
    for _, cfginfo in ipairs(buildableConfigs) do
        local cfg = premake.getconfig(prj, cfginfo.src_buildcfg, cfginfo.src_platform)
        _p(1,'<ImportGroup '..if_config_and_platform() ..' Label="PropertySheets">'
            ,premake.esc(cfginfo.name))
          _p(2,'<Import Project="$(UserRootDir)\\Microsoft.Cpp.$(Platform).user.props" Condition="exists(\'$(UserRootDir)\\Microsoft.Cpp.$(Platform).user.props\')" Label="LocalAppDataPlatform" />')
          
          if cfg.propertySheet and cfg.propertySheet ~= "" then
            _p(2, '<Import Project="%s" />', premake.esc(path.translate(cfg.propertySheet)));
          end
          
        _p(1,'</ImportGroup>')
      --end
      
    end
	end

	local function incremental_link(cfg,cfginfo)
		if cfg.kind ~= "StaticLib" then
			ShoudLinkIncrementally = 'false'
			if optimisation(cfg) == "Disabled" and not cfg.flags.NoIncrementalLink then
				ShoudLinkIncrementally = 'true'
			end

			_p(2,'<LinkIncremental '..if_config_and_platform() ..'>%s</LinkIncremental>'
					,premake.esc(cfginfo.name),ShoudLinkIncrementally)
		end		
	end
		
		
	local function ignore_import_lib(cfg,cfginfo)
		if cfg.kind ~= "StaticLib" then
			if cfg.flags.NoImportLib then 
        _p(2,'<IgnoreImportLibrary '..if_config_and_platform() ..'>%s</IgnoreImportLibrary>'
					,premake.esc(cfginfo.name), "true")
      end
		end
	end
	
		
	local function intermediate_and_out_dirs(prj)
		_p(1,'<PropertyGroup>')
			_p(2,'<_ProjectFileVersion>10.0.30319.1</_ProjectFileVersion>')
			
      local buildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectPossibleBuildableConfigurations) -- Only create configs for the configurations that can be built.
      for _, cfginfo in ipairs(buildableConfigs) do
          local cfg = premake.getconfig(prj, cfginfo.src_buildcfg, cfginfo.src_platform)
          _p(2,'<OutDir '..if_config_and_platform() ..'>%s\\</OutDir>'
              , premake.esc(cfginfo.name),premake.esc(cfg.buildtarget.directory) )
          _p(2,'<IntDir '..if_config_and_platform() ..'>%s\\</IntDir>'
              , premake.esc(cfginfo.name), premake.esc(cfg.objectsdir))
          if cfg.platform == 'Xbox360' then
            -- Default values of visual studio here... $(OutDir)$(TargetName)$(TargetExt)
            --_p(2,'<OutputFile '..if_config_and_platform() ..'>$(OutDir)%s</OutputFile>', premake.esc(cfginfo.name), cfg.buildtarget.name)
            if cfg.XBoxDeploymentHD ~= nil and cfg.XBoxDeploymentHD ~= "" then
              _p(2,'<RemoteRoot ' .. if_config_and_platform() ..'>%s</RemoteRoot>', premake.esc(cfginfo.name), cfg.XBoxDeploymentHD )
            end
            if cfg.imagepath ~= nil then
              _p(2,'<ImageXexOutput ' .. if_config_and_platform() ..'>%s</ImageXexOutput>', premake.esc(cfginfo.name), premake.esc(path.translate(cfg.imagepath)))
            end
          else
            if (cfg.buildtarget.name ~= prj.nicename) then
              _p(2,'<TargetName '..if_config_and_platform() ..'>%s</TargetName>'
                  ,premake.esc(cfginfo.name),path.getbasename(cfg.buildtarget.name))
            end
          end
        
          -- TODO - At the moment those two new project's properties section are not supported. We deactivate it and continue using the old system to generate .ppu.obj, this is, by using a post build step (SPU Projects)
          if cfg.platform == 'PS3' and cfg.toolset == "SPU" and cfg.flags.VSDisableSPUElfConversion then
            _p(2, '<SpuElfConversionUseInBuild ' .. if_config_and_platform() .. '>false</SpuElfConversionUseInBuild>', premake.esc(cfginfo.name))
            --_p(2, '<PreConvEventUseInBuild ' .. if_config_and_platform() .. '>false</PreConvEventUseInBuild>')
          end
          
          if cfg.flags.VSEnableStaticCodeAnalysis then
          _p(2,'<RunCodeAnalysis '..if_config_and_platform()..'>true</RunCodeAnalysis>', premake.esc(cfginfo.name))
          end

          ignore_import_lib(cfg,cfginfo)
          incremental_link(cfg,cfginfo)

		  if cfg.platform == 'Durango' then
			_p(2,'<ReferencePath ' .. if_config_and_platform() ..'>$(VCInstallDir)atlmfc\\lib;$(VCInstallDir)lib;$(Console_SdkLibPath);$(Console_SdkWindowsMetadataPath)</ReferencePath>', premake.esc(cfginfo.name))
			_p(2,'<LibraryPath ' .. if_config_and_platform() ..'>$(Console_SdkLibPath);$(VCInstallDir)lib\\amd64;$(VCInstallDir)atlmfc\\lib\\amd64</LibraryPath>', premake.esc(cfginfo.name))
			_p(2,'<LibraryWPath ' .. if_config_and_platform() ..'>$(Console_SdkLibPath);$(Console_SdkWindowsMetadataPath)</LibraryWPath>', premake.esc(cfginfo.name))
			_p(2,'<IncludePath ' .. if_config_and_platform() ..'>$(Console_SdkIncludeRoot)\\um;$(Console_SdkIncludeRoot)\\shared;$(Console_SdkIncludeRoot)\\winrt;$(VCInstallDir)include;$(VCInstallDir)atlmfc\\include</IncludePath>', premake.esc(cfginfo.name))
			_p(2,'<ExecutablePath ' .. if_config_and_platform() ..'>$(Console_SdkRoot)bin;$(VCInstallDir)bin\\x86_amd64;$(VCInstallDir)bin;$(WindowsSDK_ExecutablePath_x86);$(VSInstallDir)Common7\\Tools\\bin;$(VSInstallDir)Common7\\tools;$(VSInstallDir)Common7\\ide;$(ProgramFiles)\\HTML Help Workshop;$(MSBuildToolsPath32);$(FxCopDir);$(PATH);</ExecutablePath>', premake.esc(cfginfo.name))
			
			if cfg.AppxLayoutDir ~= nil and cfg.AppxLayoutDir ~= "" then
              _p(2,'<LayoutDir ' .. if_config_and_platform() ..'>%s</LayoutDir>', premake.esc(cfginfo.name), cfg.AppxLayoutDir )
            end		  
		  end 

          if cfg.flags.NoManifest then
             _p(2,'<GenerateManifest '..if_config_and_platform() ..'>false</GenerateManifest>' ,premake.esc(cfginfo.name))
          end
      end
      
		_p(1,'</PropertyGroup>')
	end
	

	
	local function runtime(cfg)
		local runtime
		if premake.config.isdebugbuild(cfg) then
			runtime = iif(cfg.flags.StaticRuntime,"MultiThreadedDebug", "MultiThreadedDebugDLL")
		else
			runtime = iif(cfg.flags.StaticRuntime, "MultiThreaded", "MultiThreadedDLL")
		end
		return runtime
	end
	
	local function precompiled_header(cfg)
      	if not cfg.flags.NoPCH and cfg.pchheader then
			_p(3,'<PrecompiledHeader>Use</PrecompiledHeader>')
			_p(3,'<PrecompiledHeaderFile>%s</PrecompiledHeaderFile>', iif(cfg.flags.VSUseFullPathPCH, path.translate(cfg.pchheader, "\\"), path.getname(cfg.pchheader)))
		else
			_p(3,'<PrecompiledHeader></PrecompiledHeader>')
		end
	end
	
	local function preprocessor(indent,cfg)
		if #cfg.defines > 0 then
		    _p(indent,'<PreprocessorDefinitions>%%(PreprocessorDefinitions);%s</PreprocessorDefinitions>'
				,premake.esc(table.concat(cfg.defines, ";")))
		elseif cfg.propertySheet and cfg.propertySheet ~= "" then
      _p(indent,'<PreprocessorDefinitions>%%(PreprocessorDefinitions)</PreprocessorDefinitions>')
    else
			_p(indent,'<PreprocessorDefinitions></PreprocessorDefinitions>')
		end
	end
	
	local function include_dirs(indent,cfg)
		if #cfg.includedirs > 0 then
			_p(indent,'<AdditionalIncludeDirectories>%s;%%(AdditionalIncludeDirectories)</AdditionalIncludeDirectories>'
					,premake.esc(path.translate(table.concat(cfg.includedirs, ";"), '\\')))
		end
	end
	
	local function resource_compile(cfg)
		_p(2,'<ResourceCompile>')
			preprocessor(3,cfg)
			include_dirs(3,cfg)
		_p(2,'</ResourceCompile>')
		
	end
	
	local function exceptions(cfg)
		if cfg.flags.NoExceptions then
			_p(2,'<ExceptionHandling>false</ExceptionHandling>')
		elseif cfg.flags.SEH then
			_p(2,'<ExceptionHandling>Async</ExceptionHandling>')
		end
	end
	
	local function rtti(cfg)
		if cfg.flags.NoRTTI then
			_p(3,'<RuntimeTypeInfo>false</RuntimeTypeInfo>')
		end
	end
	
	local function wchar_t_buildin(cfg)
		if cfg.flags.NativeWChar then
			_p(3,'<TreatWChar_tAsBuiltInType>true</TreatWChar_tAsBuiltInType>')
		elseif cfg.flags.NoNativeWChar then
			_p(3,'<TreatWChar_tAsBuiltInType>false</TreatWChar_tAsBuiltInType>')
		end
	end
	
	local function sse(cfg)
		if cfg.flags.EnableSSE then
			_p(3,'<EnableEnhancedInstructionSet>StreamingSIMDExtensions</EnableEnhancedInstructionSet>')
		elseif cfg.flags.EnableSSE2 then
			_p(3,'<EnableEnhancedInstructionSet>StreamingSIMDExtensions2</EnableEnhancedInstructionSet>')
		end
	end
	
	local function floating_point(cfg)
	     if cfg.flags.FloatFast then
			_p(3,'<FloatingPointModel>Fast</FloatingPointModel>')
		elseif cfg.flags.FloatStrict then
			_p(3,'<FloatingPointModel>Strict</FloatingPointModel>')
		end
	end
   
   local function buffersecuritycheck(cfg)
      if not cfg.flags.VSBufferSecurityCheck then
         _p(3,'<BufferSecurityCheck>false</BufferSecurityCheck>')
      end
   end
	

	local function debug_info(cfg)
	--
	--	EditAndContinue /ZI
	--	ProgramDatabase /Zi
	--	OldStyle C7 Compatable /Z7
	--
		local debug_info = ''
		if cfg.flags.Symbols then
			if optimisation(cfg) ~= "Disabled" or cfg.flags.NoEditAndContinue then
				debug_info = "ProgramDatabase"
			elseif cfg.platform ~= "x64" then
				debug_info = "EditAndContinue"
			else
				debug_info = "OldStyle"
			end
			
			_p(3,'<DebugInformationFormat>%s</DebugInformationFormat>',debug_info)
		end
		
	end
	
	local function minimal_build(cfg)
		if not (premake.config.isdebugbuild(cfg) and not cfg.flags.NoMinimalRebuild and not cfg.flags.Managed) then
			_p(3,'<MinimalRebuild>false</MinimalRebuild>')
		end
	end
	
	local function compile_language(cfg)
		if cfg.language == "C" then
			_p(3,'<CompileAs>CompileAsC</CompileAs>')
        elseif cfg.language == "Default" then
            _p(3,'<CompileAs>Default</CompileAs>')
	        -- If it is a WinRT platform then add /ZW support by default too
	        if (cfg.platform == "Durango" or string.find(cfg.platform , "Metro") or string.find(cfg.platform , "Apollo")) then 
		        _p(3,'<CompileAsWinRT>true</CompileAsWinRT>')
            end
	    end
	end	
		
	local function vs11_clcompile(cfg)
		_p(2,'<ClCompile>')
		
		if #cfg.buildoptions > 0 then
			_p(3,'<AdditionalOptions>%s %%(AdditionalOptions)</AdditionalOptions>',
					table.concat(premake.esc(cfg.buildoptions), " "))
		end
		if optimisation(cfg) ~= "" then
      _p(3,'<Optimization>%s</Optimization>', optimisation(cfg))
    end
    
    if _VS.optimization(cfg) >= 2 then -- full optimization or maximize speed
       _p(3,'<InlineFunctionExpansion>AnySuitable</InlineFunctionExpansion>')
    elseif _VS.optimization(cfg) > 0 then
       _p(3,'<InlineFunctionExpansion>OnlyExplicitInline</InlineFunctionExpansion>')
    end
    
    if cfg.flags.VSEnableIntrinsicFunctions then
      _p(3,'<IntrinsicFunctions>true</IntrinsicFunctions>')
    end
    
    if (cfg.flags.VSFavorSize and not cfg.flags.VSFavorSpeed) or (cfg.flags.VSFavorSpeed and not cfg.flags.VSFavorSize) then
      _p(3, '<FavorSizeOrSpeed>%s</FavorSizeOrSpeed>', iif(cfg.flags.VSFavorSize, "Size", "Speed"))
    end
  
    include_dirs(3,cfg)
    preprocessor(3,cfg)
    minimal_build(cfg)
		
		if optimisation(cfg) == "Disabled" and not cfg.flags.VSNoBasicRuntimeCheck then
			_p(3,'<BasicRuntimeChecks>EnableFastChecks</BasicRuntimeChecks>')
			if cfg.flags.ExtraWarnings then
				_p(3,'<SmallerTypeCheck>true</SmallerTypeCheck>')
			end
		else
      _p(3,'<BasicRuntimeChecks>Default</BasicRuntimeChecks>')
      if cfg.flags.VSNoStringPooling then
        _p(3,'<StringPooling>false</StringPooling>')
      else
        _p(3,'<StringPooling>true</StringPooling>')
      end
		end
		
    if not (cfg.propertySheet or cfg.propertySheet == "") then
      _p(3,'<RuntimeLibrary>%s</RuntimeLibrary>', runtime(cfg))
    end
  
    if cfg.flags.VSEnableFunctionLevelLinking then
      _p(3,'<FunctionLevelLinking>true</FunctionLevelLinking>')
    end
    
    precompiled_header(cfg)
		
		if cfg.flags.ExtraWarnings then
			_p(3,'<WarningLevel>Level4</WarningLevel>')
		elseif not cfg.flags.MinWarnings then
			_p(3,'<WarningLevel>Level3</WarningLevel>')
		end
			
		if cfg.flags.FatalWarnings then
			_p(3,'<TreatWarningAsError>true</TreatWarningAsError>')
		end
		
		if cfg.flags.VSEnableStaticCodeAnalysis then
			_p(3,'<EnablePREfast>true</EnablePREfast>')
		end
		
		if cfg.disablespecificwarnings then
      local disabledWarnings = premake.esc(table.concat(cfg.disablespecificwarnings, ";"))
      if disabledWarnings ~= "" then
        _p(3,'<DisableSpecificWarnings>%s</DisableSpecificWarnings>', disabledWarnings)
      end
		end
	
			exceptions(cfg)
			rtti(cfg)
			wchar_t_buildin(cfg)
         buffersecuritycheck(cfg)
			sse(cfg)
			floating_point(cfg)
			debug_info(cfg)
      
    if cfg.flags.Symbols then
      if cfg.kind == "StaticLib" then
        _p(4,'<ProgramDataBaseFileName>$(TargetDir)$(TargetName).pdb</ProgramDataBaseFileName>')
      else
        -- Defaults to intermediates dir
        --_p(4,'<ProgramDataBaseFileName>%s\\%s.pdb</ProgramDataBaseFileName>', "$(IntDir)", "vc110")
      end
    end
			
		if cfg.flags.NoFramePointer then
			_p(3,'<OmitFramePointers>true</OmitFramePointers>')
		end
			
		compile_language(cfg)
    
    _p(2,'<MultiProcessorCompilation>true</MultiProcessorCompilation>')
    
	if cfg.platform == "Durango" then
	   _p(2,'<AdditionalUsingDirectories>$(Console_SdkWindowsMetadataPath);$(VCInstallDir)vcpackages;%%(AdditionalUsingDirectories)</AdditionalUsingDirectories>')
    end
     
	   _p(2,'</ClCompile>')
	end


	local function event_hooks(cfg)	
		if #cfg.postbuildcommands> 0 then
		    _p(2,'<PostBuildEvent>')
				_p(3,'<Command>%s</Command>',premake.esc(table.implode(cfg.postbuildcommands, "", "", "\r\n")))
			_p(2,'</PostBuildEvent>')
		end
		
		if #cfg.prebuildcommands> 0 then
		    _p(2,'<PreBuildEvent>')
				_p(3,'<Command>%s</Command>',premake.esc(table.implode(cfg.prebuildcommands, "", "", "\r\n")))
			_p(2,'</PreBuildEvent>')
		end
		
		if #cfg.prelinkcommands> 0 then
		    _p(2,'<PreLinkEvent>')
				_p(3,'<Command>%s</Command>',premake.esc(table.implode(cfg.prelinkcommands, "", "", "\r\n")))
			_p(2,'</PreLinkEvent>')
		end	
	end

	local function additional_options(indent,cfg)
		if #cfg.linkoptions > 0 then
				_p(indent,'<AdditionalOptions>%s %%(AdditionalOptions)</AdditionalOptions>',
					table.concat(premake.esc(cfg.linkoptions), " "))
		end
	end
	
	local function link_target_machine(cfg)
    local targetMachine = iif((cfg.platform == "x64" or cfg.platform == "Durango" or cfg.platform == "Metro_x64"), "MachineX64", "MachineX86")
    if cfg.flags.VSNoTargetMachine then
     targetMachine = "NotSet"
    end
    
    if targetMachine ~= "NotSet" and not (cfg.propertySheet and cfg.propertySheet ~= "") then
      _p(3,'<TargetMachine>%s</TargetMachine>', targetMachine)
    end
	end
  
	local function import_lib(cfg)
		--Prevent the generation of an import library for a static lib.
		if cfg.kind ~= "StaticLib" and not cfg.flags.NoImportLib then
			local implibname = cfg.linktarget.fullpath
			_p(3,'<ImportLibrary>$(TargetDir)$(TargetName).lib</ImportLibrary>')
		end
	end
	
	local function common_link_section(cfg)
  
    if #cfg.links > 0 then
      if cfg.platform == "Durango" then   --or string.find(cfg.platform, "Metro") or string.find(cfg.platform, "Apollo") then 
        _p(3,'<AdditionalDependencies>%s;%s</AdditionalDependencies>',
           table.concat(premake.getlinks(cfg, "system", "fullpath"), ";"), iif(cfg.flags.NoLinkLibInheritedDependencies, "", "%(AdditionalDependencies)")
        )
      else
        _p(3,'<AdditionalDependencies>%s;%%(AdditionalDependencies)</AdditionalDependencies>',
          table.concat(premake.getlinks(cfg, "system", "fullpath"), ";")
        )
      end
    end
    
    if cfg.flags.VSIgnoreAllDefaultLibs then
      _p(3, '<IgnoreAllDefaultLibraries>true</IgnoreAllDefaultLibraries>')
    end
    
    _p(3,'<AdditionalLibraryDirectories>%s%s%%(AdditionalLibraryDirectories)</AdditionalLibraryDirectories>',
      table.concat(premake.esc(path.translate(cfg.libdirs, '\\')) , ";"), 
      iif(cfg.libdirs and #cfg.libdirs >0,';','')
    )
        
    _p(3, '<IgnoreSpecificDefaultLibraries>%s%s%%(IgnoreSpecificDefaultLibraries)</IgnoreSpecificDefaultLibraries>',
      premake.esc(table.concat(cfg.ignoredefaultlibrarynames, ";")),
      iif(cfg.ignoredefaultlibrarynames and #cfg.ignoredefaultlibrarynames >0,';','')
      )
  
    if not cfg.flags.VSNoSubSystem then
      _p(3,'<SubSystem>%s</SubSystem>',iif(cfg.kind == "ConsoleApp","Console", "Windows"))
    end
		
		if cfg.flags.Symbols then 
			_p(3,'<GenerateDebugInformation>true</GenerateDebugInformation>')
		end
			
		if optimisation(cfg) ~= "Disabled" and optimisation(cfg) ~= "" then
			_p(3,'<OptimizeReferences>true</OptimizeReferences>')
			_p(3,'<EnableCOMDATFolding>true</EnableCOMDATFolding>')
		end
    
		if cfg.flags.Symbols and cfg.kind ~= "StaticLib" then
      -- Defaults to $(TargetDir)$(TargetName)
			--_p(3,'<ProgramDataBaseFile>$(OutDir)%s.pdb</ProgramDataBaseFile>', path.getbasename(cfg.buildtarget.name))
		end

		if cfg.platform == "Durango" or string.find(cfg.platform, "Metro") or string.find(cfg.platform, "Apollo") then 
		   _p(1, '<GenerateWindowsMetadata>false</GenerateWindowsMetadata>');
		end
  
	end
	
  local function item_def_lib(cfg)
		if cfg.kind == 'StaticLib' then
			_p(1,'<Lib>')
        -- Default values of visual studio here... $(OutDir)$(TargetName)$(TargetExt)
				--_p(2,'<OutputFile>$(OutDir)%s</OutputFile>',cfg.buildtarget.name)
        common_link_section(cfg)
				additional_options(2,cfg)
        if cfg.platform ~= 'Xbox360' then
          link_target_machine(cfg)
        end
			_p(1,'</Lib>')
		end
	end
  
	local function item_link(cfg)
		_p(2,'<Link>')
		if cfg.kind ~= 'StaticLib' then
		
      if cfg.platform ~= 'Xbox360' then
        -- Default values of visual studio here... $(OutDir)$(TargetName)$(TargetExt)
        --_p(3,'<OutputFile>$(OutDir)%s</OutputFile>', cfg.buildtarget.name)
      end
    							
			common_link_section(cfg)
      
      if cfg.flags.Symbols and cfg.flags.GenerateStrippedSymbols then
        _p(3,'<StripPrivateSymbols>$(TargetDir)$(TargetName)-STRIPPED.pdb</StripPrivateSymbols>')
      end
			
			if vs11_helpers.config_type(cfg) == 'Application' and not cfg.flags.WinMain and not ( cfg.platform == "Durango" or string.find(cfg.platform,"Metro") or string.find(cfg.platform,"Apollo") ) then
				_p(3,'<EntryPointSymbol>mainCRTStartup</EntryPointSymbol>')
			end

			import_lib(cfg)

      if cfg.platform ~= 'Xbox360' then
        _p(3,'<TargetMachine>%s</TargetMachine>', iif( (cfg.platform == "x64" or cfg.platform == "Durango" or cfg.platform == "Metro_x64"), "MachineX64", "MachineX86"))
      end
      
      if cfg.platform == 'Android' then
        if cfg.SoName then
          _p(3,'<SoName>%s</SoName>', cfg.SoName)
        else
          _p(3,'<SoName>$(TargetName)$(TargetExt)</SoName>')
        end
      end
			
			additional_options(3,cfg)
      
      if cfg.StackReserveSize and cfg.StackReserveSize ~= "" then
        _p(4,'<StackReserveSize>%s</StackReserveSize>', cfg.StackReserveSize)
      end
      
      if cfg.StackCommitSize and cfg.StackCommitSize ~= "" then
        _p(4,'<StackCommitSize>%s</StackCommitSize>', cfg.StackCommitSize)
      end
      
		else
			--common_link_section(cfg) -- StaticLib configs do not have <Link> section. Uses <Lib> instead.
		end
		
		_p(2,'</Link>')
	end
	
	local function item_definitions(prj)
  
    local buildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectPossibleBuildableConfigurations) -- Only create configs for the configurations that can be built.
    for _, cfginfo in ipairs(buildableConfigs) do
        local cfg = premake.getconfig(prj, cfginfo.src_buildcfg, cfginfo.src_platform)
        _p(1,'<ItemDefinitionGroup ' ..if_config_and_platform() ..'>'
					,premake.esc(cfginfo.name))
				vs11_clcompile(cfg)
				resource_compile(cfg)
				item_def_lib(cfg)
				item_link(cfg)
				event_hooks(cfg)
        if cfg.platform == 'Xbox360' and cfg.XBoxDeploymentHD ~= nil and cfg.XBoxDeploymentHD ~= "" then
          _p(2, '<Deploy>')
          _p(3, '<DeploymentType>CopyToHardDrive</DeploymentType>')
          _p(2, '</Deploy>')
        end
			_p(1,'</ItemDefinitionGroup>')
      --end
    end
	end
  
  local function write_project_references_block(prj)
    if prj.flags and prj.flags.VSUseReferencesInProjects then
      local deps = premake.getreferences(prj)
			if #deps > 0 then
        _p(1, '<ItemGroup>')
				for _, dep in ipairs(deps) do -- dep == the referenced project object
          -- Build a relative path from the solution file to the project file
          local projpath = path.translate(path.getrelative(prj.location, _VS.projectfile(dep)), "\\")
          
          _p(2, '<ProjectReference Include="%s">', projpath)
          _p(3, '<Project>{%s}</Project>', dep.uuid)
          _p(3, '<Private>false</Private>')
          _p(2, '</ProjectReference>')
				end
        _p(1, '</ItemGroup>')
			end
    end
  end
  
  local function write_project_custom_build_block(prj, files)
    if files and #files > 0 then
      _p(1, '<ItemGroup>')
      for _,fname in pairs(files) do
        local fcfg = premake.getfileconfig(prj, path.translate(fname, '/'))
        
        local bHasCustomBuildCommand = false        
        local bHasCustomOutputs = false
        local bHasCustomDependencies = false
        local commandLine = nil
        local outputs = nil
        
        local function writeField(name, CfgPlat, content, sep)
          if (content and content ~= "" and content ~= {}) then
            local output = premake.esc(table.implode(content, "", "", sep))
            if output and output ~= "" then
              _p(3, '<%s ' .. if_config_and_platform() .. '>%s</%s>', name, CfgPlat, output, name)
            end
          end
        end
        
        if (fcfg.custombuildcommandline and fcfg.custombuildcommandline ~= "" and fcfg.custombuildcommandline ~= {}) then
          commandLine = table.implode(fcfg.custombuildcommandline, "", "", "\r\n")
          if commandLine and commandLine ~= "" then
          
            _p(2, '<CustomBuild Include="%s">', fname)
            _p(3, '<FileType>Document</FileType>')
            
            local buildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectPossibleBuildableConfigurations) -- Only create configs for the configurations that can be built.
            for _, cfginfo in ipairs(buildableConfigs) do
              local cfgNameEscaped = premake.esc(cfginfo.name)
            
              writeField("Command", cfgNameEscaped, fcfg.custombuildcommandline, "\r\n")
              writeField("Outputs", cfgNameEscaped, fcfg.custombuildcommandlineOutput, ";")
              writeField("AdditionalInputs", cfgNameEscaped, fcfg.custombuildcommandlineDepends, ";")
            end
            
            _p(2, '</CustomBuild>')
            
          end
        end
      end
      _p(1, '</ItemGroup>')
    end
  end
  
  local function write_project_system_references_block(prj)
    if prj.flags and prj.flags.VSUseReferencesInProjects then
      local deps = premake.getassembliesreferences(prj)
			if #deps > 0 then
        _p(1, '<ItemGroup>')
          for _, dep in ipairs(deps) do
            _p(2, '<Reference Include="%s">', premake.esc(dep))
              _p(3, '<CopyLocalSatelliteAssemblies>true</CopyLocalSatelliteAssemblies>')
              _p(3, '<ReferenceOutputAssembly>true</ReferenceOutputAssembly>')
            _p(2, '</Reference>')
          end
        _p(1, '</ItemGroup>')
			end
    end
  end
  
	--
	--   <ItemGroup>
  --     <ProjectReference Include="zlibvc.vcxproj">
  --       <Project>{8fd826f8-3739-44e6-8cc8-997122e53b8d}</Project>
  --     </ProjectReference>
  --   </ItemGroup>
	--
	
	local function write_file_type_block(files,group_type,prj)
		if #files > 0  then
			_p(1,'<ItemGroup>')
			for _, current_file in ipairs(files) do
      
        local bExcluded = false
        
        if prj ~= nil then
          local buildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectPossibleBuildableConfigurations) -- Only create configs for the configurations that can be built.
          for _, cfginfo in ipairs(buildableConfigs) do
            -- Retrieve the configuration information data block starting from the build config and platform.
            local cfg = premake.getconfig(prj, cfginfo.src_buildcfg, cfginfo.src_platform)
            
            for _, exclude in ipairs(cfg.excludes) do
              local excluded = (current_file == path.translate(exclude, "\\"))
              if (excluded) then
                if (bExcluded == false) then
                  _p(2,'<%s Include=\"%s\" >', group_type,current_file)
                  bExcluded = true
                end
                _p(3,'<ExcludedFromBuild ' .. if_config_and_platform() .. '>true</ExcludedFromBuild>', premake.esc(cfginfo.name))
                break -- One file found is enough
              end
            end
          end
        end
        
        if bExcluded == false then
          _p(2,'<%s Include=\"%s\" />', group_type,current_file)
        else
          _p(2,'</%s>', group_type)
        end
      end
			_p(1,'</ItemGroup>')
		end
	end
	
	local function write_file_compile_block(files,prj,configs)
	
		if #files > 0  then	
		
      -- Looks for the pch source file inside the file list and if it is the one specified to be created
      -- (in the pchsource instruction) just set it to create.
			local config_mappings = {}
      local buildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectPossibleBuildableConfigurations) -- Only create configs for the configurations that can be built.
      --[[
      for _, cfginfo in ipairs(buildableConfigs) do
        local cfg = premake.getconfig(prj, cfginfo.src_buildcfg, cfginfo.src_platform)        
        if cfg.pchheader and cfg.pchsource and not cfg.flags.NoPCH then
          config_mappings[cfginfo] = path.translate(cfg.pchsource, "\\")
        end
      end
      --]]
			
      local bPCHSourceFound = false
			_p(1,'<ItemGroup>')
			for _, fname in ipairs(files) do
				_p(2,'<ClCompile Include=\"%s\">', fname)
        
        local buildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectPossibleBuildableConfigurations) -- Only create configs for the configurations that can be built.
        for _, cfginfo in ipairs(buildableConfigs) do
          
          -- Retrieve the configuration information data block starting from the build config and platform.
          local cfg = premake.getconfig(prj, cfginfo.src_buildcfg, cfginfo.src_platform)
          
          for _, exclude in ipairs(cfg.excludes) do
            local excluded = (fname == path.translate(exclude, "\\"))
            if (excluded) then
              _p(3,'<ExcludedFromBuild ' .. if_config_and_platform() .. '>true</ExcludedFromBuild>', premake.esc(cfginfo.name))
              break -- One file found is enough
            end
          end
        
          for _, exclude in ipairs(cfg.nopchfile) do
            local fileIsNotUsingPCH = (fname == path.translate(exclude, "\\"))
            if (fileIsNotUsingPCH) then
              _p(3,'<PrecompiledHeader '.. if_config_and_platform() .. '>NotUsing</PrecompiledHeader>', premake.esc(cfginfo.name))
			  _p(3,'<CompileAsWinRT>false</CompileAsWinRT>') -- A bit of a hack. Know that files without PCH are .c files etc, which just happen to not support /ZW either.
              break -- One file found is enough
            end
          end
          
          -- If the file is the one declared to be the precompiled header set it to Create
          --if config_mappings[cfginfo] and fname == config_mappings[cfginfo] then 
          if cfg.pchheader and cfg.pchsource and not cfg.flags.NoPCH and fname == path.translate(cfg.pchsource, "\\") then
            _p(3,'<PrecompiledHeader '.. if_config_and_platform() .. '>Create</PrecompiledHeader>', premake.esc(cfginfo.name))
            --only one source file per pch
          end
        end
				_p(2,'</ClCompile>')
			end
			_p(1,'</ItemGroup>')
		end
	end
	
	local function vcxproj_files(prj)
		local sorted =
		{
			ClCompile	={},
			ClInclude	={},
			None		={},
			ResourceCompile = {},
			AppxManifest = {},		
			CustomBuild = {}
		}
		
		cfg = premake.getconfig(prj)
		vs11_helpers.sort_input_files(prj,cfg.files,sorted)
		write_file_type_block(sorted.ClInclude,"ClInclude")
		write_file_compile_block(sorted.ClCompile,prj,prj.solution.vstudio_configs) -- That is wrong. Configs should be the ones from the projects and not from the solution. TODO Simplify this by passing prj.configs instead & TEST
		write_project_references_block(prj)
        write_project_system_references_block(prj)
        write_project_custom_build_block(prj, sorted.CustomBuild)
   		write_file_type_block(sorted.None,'None')
		write_file_type_block(sorted.AppxManifest,'AppxManifest', prj)
		write_file_type_block(sorted.ResourceCompile,'ResourceCompile', prj)

	end
	
	local function write_filter_includes(prj, sorted_table)
		local directories = vs11_helpers.table_of_file_filters(sorted_table)
		--I am going to take a punt here that the ItemGroup is missing if no files!!!!
		--there is a test for this see
		--vs11_filters.noInputFiles_bufferDoesNotContainTagItemGroup
		if #directories >0 then
			_p(1,'<ItemGroup>')
			for _, dir in pairs(directories) do
        local prjNameCRC32 = string.format("%08X", string.Hash(prj.name))
        local temp = string.format("%08X", string.Hash(prjNameCRC32))
        local prjNameCRC32ed = string.format("%s-%s", string.sub(temp, 1, 4), string.sub(temp, 5, 8))
        local filterNameCRC32 = string.format("%08X", string.Hash(dir))
        temp = string.format("%08X", string.Hash(filterNameCRC32))
        local filterNameCRC32ed = string.format("%s-%s", string.sub(temp, 1, 4), string.sub(temp, 5, 8))
        
				_p(2,'<Filter Include="%s">',dir)
					_p(3,'<UniqueIdentifier>{%s}</UniqueIdentifier>', prjNameCRC32 .. "-" .. prjNameCRC32ed .. "-" .. filterNameCRC32ed .. filterNameCRC32)
				_p(2,'</Filter>')
			end
			_p(1,'</ItemGroup>')
		end
	end
	
	local function write_file_filter_block(files,group_type)
		if #files > 0  then
			_p(1,'<ItemGroup>')
			for _, current_file in ipairs(files) do
				local path_to_file = vs11_helpers.file_path(current_file)
				if path_to_file then
					_p(2,'<%s Include=\"%s\">', group_type,path.translate(current_file, "\\"))
						_p(3,'<Filter>%s</Filter>',path_to_file)
					_p(2,'</%s>',group_type)
				else
					_p(2,'<%s Include=\"%s\" />', group_type,path.translate(current_file, "\\"))
				end
			end
			_p(1,'</ItemGroup>')
		end
	end
	
	local tool_version_and_xmlns = 'ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003"'	
	local xml_version_and_encoding = '<?xml version="1.0" encoding="utf-8"?>'
	
	local function vcxproj_filter_files(prj)
		local sorted =
		{
			ClCompile	={},
			ClInclude	={},
			None		={},
			ResourceCompile ={},
			AppxManifest ={},
			CustomBuild = {}
		}
		
		cfg = premake.getconfig(prj)
		vs11_helpers.sort_input_files(prj,cfg.files,sorted)

		io.eol = "\r\n"
		_p(xml_version_and_encoding)
		_p('<Project ' ..tool_version_and_xmlns ..'>')
			write_filter_includes(prj, sorted)
			write_file_filter_block(sorted.ClInclude,"ClInclude")
			write_file_filter_block(sorted.ClCompile,"ClCompile")
			write_file_filter_block(sorted.None,"None")
			write_file_filter_block(sorted.AppxManifest,"AppxManifest")
			write_file_filter_block(sorted.ResourceCompile,"ResourceCompile")
			write_file_filter_block(sorted.CustomBuild,"CustomBuild")
		_p('</Project>')
	end

	function premake.vs2012_vcxproj(prj)
		io.eol = "\r\n"
		_p(xml_version_and_encoding)
		_p('<Project DefaultTargets="Build" ' ..tool_version_and_xmlns ..'>')
			vs2012_config(prj)
			vs2012_globals(prj)
			
			_p(1,'<Import Project="$(VCTargetsPath)\\Microsoft.Cpp.Default.props" />')
			
			config_type_block(prj)
			
			_p(1,'<Import Project="$(VCTargetsPath)\\Microsoft.Cpp.props" />')
			
			--check what this section is doing
			_p(1,'<ImportGroup Label="ExtensionSettings">')
			_p(1,'</ImportGroup>')
			
			import_props(prj)
			
			--what type of macros are these?
			_p(1,'<PropertyGroup Label="UserMacros" />')
			
			intermediate_and_out_dirs(prj)
			
			item_definitions(prj)
			
			vcxproj_files(prj)

			_p(1,'<Import Project="$(VCTargetsPath)\\Microsoft.Cpp.targets" />')
			_p(1,'<ImportGroup Label="ExtensionTargets">')
			_p(1,'</ImportGroup>')

		_p('</Project>')
	end
	

	function premake.vs2012_vcxproj_user(prj)
		_p(xml_version_and_encoding)
		_p('<Project ' ..tool_version_and_xmlns ..'>')
    
    local buildableConfigs = premake.vstudio_buildProjectConfigurations(prj.projectPossibleBuildableConfigurations) -- Only create configs for the configurations that can be built.
    for _, cfginfo in ipairs(buildableConfigs) do
      local cfg = premake.getconfig(prj, cfginfo.src_buildcfg, cfginfo.src_platform)
      
      if cfg.platform == "PS3" and cfg.fileservingPS3 and cfg.fileservingPS3 ~= "" then
        _p(2,'<PropertyGroup '..if_config_and_platform() ..'>', premake.esc(cfginfo.name))
        _p(3,'<LocalDebuggerFileServingDirectory>%s</LocalDebuggerFileServingDirectory>',cfg.fileservingPS3)
        _p(2,'</PropertyGroup>')
      end
      
      if cfg.platform == "PS3" and cfg.homedirPS3 and cfg.homedirPS3 ~= "" then
        _p(2,'<PropertyGroup '..if_config_and_platform() ..'>', premake.esc(cfginfo.name))
        _p(3,'<LocalDebuggerHomeDirectory>%s</LocalDebuggerHomeDirectory>',cfg.homedirPS3)
        _p(2,'</PropertyGroup>')
      end
    end
		_p('</Project>')
	end
	
	function premake.vs2012_vcxproj_filters(prj)
		vcxproj_filter_files(prj)
	end
	

		