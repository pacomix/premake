--
-- xcode_common.lua
-- Functions to generate the different sections of an Xcode project.
-- Copyright (c) 2009-2010 Jason Perkins and the Premake project
--

	local xcode = premake.xcode
	local tree  = premake.tree

local archs = {
			Native = "$(NATIVE_ARCH_ACTUAL)",
			x32    = "i386",
			x64    = "x86_64",
			Universal32 = "$(ARCHS_STANDARD_32_BIT)",
			Universal64 = "$(ARCHS_STANDARD_64_BIT)",
			Universal = "$(ARCHS_STANDARD_32_64_BIT)",
      iOS = "$(ARCHS_UNIVERSAL_IPHONE_OS)"
		}

--
-- Return the Xcode build category for a given file, based on the file extension.
--
-- @param node
--    The node to identify.
-- @returns
--    An Xcode build category, one of "Sources", "Resources", "Frameworks", or nil.
--

	function xcode.getbuildcategory(node)
		local categories = {
			[".a"] = "Frameworks",
			[".c"] = "Sources",
			[".cc"] = "Sources",
			[".cpp"] = "Sources",
			[".cxx"] = "Sources",
			[".dylib"] = "Frameworks",
			[".framework"] = "Frameworks",
			[".m"] = "Sources",
			[".mm"] = "Sources",
			[".strings"] = "Resources",
			[".nib"] = "Resources",
			[".xib"] = "Resources",
			[".icns"] = "Resources",
		}
    if node.isResource then return "Resources" end

		if categories[path.getextension(node.name)] == "Resources" then node.isResource = true end
		return categories[path.getextension(node.name)]
	end


--
-- Return the displayed name for a build configuration, taking into account the
-- configuration and platform, i.e. "Debug 32-bit Universal".
--
-- @param cfg
--    The configuration being identified.
-- @returns
--    A build configuration name.
--

	function xcode.getconfigname(cfg)
		local name = cfg.name
		if #cfg.project.solution.xcode.platforms > 1 then
			name = name .. " " .. premake.action.current().valid_platforms[cfg.platform]
		end
		return name
	end


--
-- Return the Xcode type for a given file, based on the file extension.
--
-- @param fname
--    The file name to identify.
-- @returns
--    An Xcode file type, string.
--

	function xcode.getfiletype(node)
		local types = {
			[".c"]         = "sourcecode.c.c",
			[".cc"]        = "sourcecode.cpp.cpp",
			[".cpp"]       = "sourcecode.cpp.cpp",
			[".css"]       = "text.css",
			[".cxx"]       = "sourcecode.cpp.cpp",
			[".framework"] = "wrapper.framework",
			[".gif"]       = "image.gif",
			[".h"]         = "sourcecode.c.h",
			[".html"]      = "text.html",
			[".lua"]       = "sourcecode.lua",
			[".m"]         = "sourcecode.c.objc",
			[".mm"]        = "sourcecode.cpp.objc",
			[".nib"]       = "wrapper.nib",
			[".pch"]       = "sourcecode.c.h",
			[".plist"]     = "text.plist.xml",
			[".strings"]   = "text.plist.strings",
			[".xib"]       = "file.xib",
			[".icns"]      = "image.icns",
		}
		return types[path.getextension(node.path)] or "text"
	end


--
-- Return the Xcode product type, based target kind.
--
-- @param node
--    The product node to identify.
-- @returns
--    An Xcode product type, string.
--

	function xcode.getproducttype(node)
		local types = {
			ConsoleApp  = "com.apple.product-type.tool",
			WindowedApp = "com.apple.product-type.application",
			StaticLib   = "com.apple.product-type.library.static",
			SharedLib   = "com.apple.product-type.library.dynamic",
		}
		return types[node.cfg.kind]
	end


--
-- Return the Xcode target type, based on the target file extension.
--
-- @param node
--    The product node to identify.
-- @returns
--    An Xcode target type, string.
--

	function xcode.gettargettype(node)
		local types = {
			ConsoleApp  = "\"compiled.mach-o.executable\"",
			WindowedApp = "wrapper.application",
			StaticLib   = "archive.ar",
			SharedLib   = "\"compiled.mach-o.dylib\"",
		}
		return types[node.cfg.kind]
	end


--
-- Return a unique file name for a project. Since Xcode uses .xcodeproj's to 
-- represent both solutions and projects there is a likely change of a name
-- collision. Tack on a number to differentiate them.
--
-- @param prj
--    The project being queried.
-- @returns
--    A uniqued file name
--

	function xcode.getxcodeprojname(prj)
		-- if there is a solution with matching name, then use "projectname1.xcodeproj"
		-- just get something working for now
		local fname = premake.project.getfilename(prj, "%%.xcodeproj")
		return fname
	end


--
-- Returns true if the file name represents a framework.
--
-- @param fname
--    The name of the file to test.
--

	function xcode.isframework(fname)
		return (path.getextension(fname) == ".framework")
	end


--
-- Retrieves a unique 12 byte ID for an object. This function accepts and ignores two
-- parameters 'node' and 'usage', which are used by an alternative implementation of
-- this function for testing.
--
-- @returns
--    A 24-character string representing the 12 byte ID.
--

  testGeneratedID = { }
  
  function xcode.newidtest(prj, strID, val)
    local id = strID
    if testGeneratedID == nil then
      testGeneratedID = { }
    end
		if testGeneratedID[id] then
			err = "ID Generated more than once:\t" .. id .. "\n\t\tVal: " .. val
      error("\n\n\tError: " .. err .. "\n\n", 0)
		else
			testGeneratedID[id] = val
		end
    
  end
  
	--function xcode.newid(node, section)
  function xcode.newid(prj, node, section)
    local strID = ""
    hash1 = nil
    hash2 = nil
    hash3 = nil
    val1 = nil
    val2 = nil
    val3 = nil
    
    --printf("Generating id for: " .. node.name)
    if section ~= nil and section ~= "" then
      --printf("section ~= nil and section ~= empty string")
      val1 = node.name .. ":" .. section
      val2 = section
      val3 = iif(node.path ~= "" and node.path ~= nil, node.path, node.name)
      --[[
      printf("\tName:Section: " .. val1)
      printf("\tSection: " .. val2)
      printf("\tPath/Name: " .. val3)
      --]]
    elseif xcode.getbuildcategory(node) then  -- It is a buildable file. So it has path and so
      --printf("xcode.getbuildcategory(node)")
      val1 = node.name
      val2 = xcode.getbuildcategory(node)
      if node.path then
        val3 = node.path
      else
        val3 = val1
      end
      --[[
      printf("\tName: " .. node.name)
      printf("\tCateg.: " .. xcode.getbuildcategory(node))
      printf("\tPath: " .. node.path)
      --]]
    elseif node.path then
      --printf("node.path")
      val1 = node.name .. ":" .. node.path
      val2 = node.name
      val3 = node.path
      --[[
      printf("\tName/Path: " .. node.name .. ":" .. node.path)
      printf("\tName: " .. node.name)
      printf("\tPath: " .. node.path)
      --]]
    else
      --printf("Last resource!")
      val1 = node.name
      val2 = val1
      val3 = val1
      --[[
      printf("ERROR: imposible to find a good way to generate the ID")
      printf("\tGenerating ID for name: " .. node.name) --Generate random or three repeated
      --]]
    end
    
    strID = string.format("%08X%08X%08X", string.Hash(val1), string.Hash(val2), string.Hash(val3))
    
    xcode.newidtest(prj, strID, "[" .. val1 .. "-" .. val2 .. "-" .. val3 .. "]")
    
    return strID
    
	end


--
-- Create a product tree node and all projects in a solution; assigning IDs 
-- that are needed for inter-project dependencies.
--
-- @param sln
--    The solution to prepare.
--

	function xcode.preparesolution(sln)
    -- reset the duplicated ID table
    testGeneratedID = nil
    
		-- create and cache a list of supported platforms
		sln.xcode = { }
		sln.xcode.platforms = premake.filterplatforms(sln, premake.action.current().valid_platforms, "Universal")
    
    -- Fix several stuff that XCode doesn't like. Like when using the current in a ./ format...
    for prj in premake.solution.eachproject(sln) do
      for _cfg in premake.eachconfig(prj) do
        local cfg = premake.getconfig(prj, _cfg.name, sln.xcode.platforms[1])
        for _, dir in ipairs(cfg.includedirs) do
          if dir == "./" then
            cfg.includedirs[_] = "."
          end
        end
      end
    end
		
		for prj in premake.solution.eachproject(sln) do
      testGeneratedID = nil
			-- need a configuration to get the target information
			local cfg = premake.getconfig(prj, prj.configurations[1], sln.xcode.platforms[1])
      
      
      

			-- build the product tree node
			local node = premake.tree.new(path.getname(cfg.buildtarget.bundlepath))
			node.cfg = cfg
			node.id = premake.xcode.newid(prj, node, "product")
			node.targetid = premake.xcode.newid(prj, node, "target")
			
			-- attach it to the project
			prj.xcode = {}
			prj.xcode.projectnode = node
		end
    
    if _ACTION == "xcode4" then
      _p('<?xml version="1.0" encoding="UTF-8"?>')
      _p('<Workspace')
      _p('   version = "1.0">')
      
      for prj in premake.solution.eachproject(sln) do
        _p('   <FileRef')
        _p('      location = "group:%s">', path.getrelative(sln.location, prj.location) .. '/' .. prj.name .. ".xcodeproj" )
        _p('   </FileRef>')
      end
      
      _p(0, '</Workspace>')
    end
    
	end


--
-- Print out a list value in the Xcode format.
--
-- @param list
--    The list of values to be printed.
-- @param tag
--    The Xcode specific list tag.
--

	function xcode.printlist(list, tag)
		if #list > 0 then
			_p(4,'%s = (', tag)
			for _, item in ipairs(list) do
        if item and item ~= "" then
          _p(5, '"%s",', item)
        end
			end
			_p(4,');')
		end
	end


---------------------------------------------------------------------------
-- Section generator functions, in the same order in which they appear
-- in the .pbxproj file
---------------------------------------------------------------------------

	function xcode.Header()
		_p('// !$*UTF8*$!')
		_p('{')
		_p(1,'archiveVersion = 1;')
		_p(1,'classes = {')
		_p(1,'};')
		_p(1,'objectVersion = 46;')
		_p(1,'objects = {')
		_p('')
	end


	function xcode.PBXBuildFile(tr)
		_p('/* Begin PBXBuildFile section */')
		tree.traverse(tr, {
			onnode = function(node)
				if node.buildid then
					_p(2,'%s /* %s in %s */ = {isa = PBXBuildFile; fileRef = %s /* %s */; };', 
						node.buildid, node.name, xcode.getbuildcategory(node), node.id, node.name)
				end
			end
		})
		_p('/* End PBXBuildFile section */')
		_p('')
	end


	function xcode.PBXContainerItemProxy(tr)
		if #tr.projects.children > 0 then
			_p('/* Begin PBXContainerItemProxy section */')
			for _, node in ipairs(tr.projects.children) do
				_p(2,'%s /* PBXContainerItemProxy */ = {', node.productproxyid)
				_p(3,'isa = PBXContainerItemProxy;')
				_p(3,'containerPortal = %s /* %s */;', node.id, path.getname(node.path))
				_p(3,'proxyType = 2;')
				_p(3,'remoteGlobalIDString = %s;', node.project.xcode.projectnode.id)
				_p(3,'remoteInfo = "%s";', node.project.name)
				_p(2,'};')
				_p(2,'%s /* PBXContainerItemProxy */ = {', node.targetproxyid)
				_p(3,'isa = PBXContainerItemProxy;')
				_p(3,'containerPortal = %s /* %s */;', node.id, path.getname(node.path))
				_p(3,'proxyType = 1;')
				_p(3,'remoteGlobalIDString = %s;', node.project.xcode.projectnode.targetid)
				_p(3,'remoteInfo = "%s";', node.project.name)
				_p(2,'};')
			end
			_p('/* End PBXContainerItemProxy section */')
			_p('')
		end
	end


	function xcode.PBXFileReference(tr)
		_p('/* Begin PBXFileReference section */')
		
		tree.traverse(tr, {
			onleaf = function(node)
				-- I'm only listing files here, so ignore anything without a path
				if not node.path then
					return
				end
				
				-- is this the product node, describing the output target?
				if node.kind == "product" then
					_p(2,'%s /* %s */ = {isa = PBXFileReference; explicitFileType = %s; includeInIndex = 0; name = "%s"; path = "%s"; sourceTree = BUILT_PRODUCTS_DIR; };',
						node.id, node.name, xcode.gettargettype(node), node.name, path.getname(node.cfg.buildtarget.bundlepath))
						
				-- is this a project dependency?
				elseif node.parent.parent == tr.projects then
					local relpath = path.getrelative(tr.project.location, node.parent.project.location)
					_p(2,'%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = "wrapper.pb-project"; name = "%s"; path = "%s"; sourceTree = SOURCE_ROOT; };',
						node.parent.id, node.parent.name, node.parent.name, path.join(relpath, node.parent.name))
					
				-- something else
				else
					local pth, src
					if xcode.isframework(node.path) then
						--respect user supplied paths
						if string.find(node.path,'/')  then
							if string.find(node.path,'^%.')then
								error('relative paths are not currently supported for frameworks')
							end
							pth = node.path
						else
							pth = "/System/Library/Frameworks/" .. node.path
						end
            src = "absolute"
					else
						-- something else; probably a source code file
						pth = tree.getlocalpath(node)
						src = "group"
					end
					
					_p(2,'%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = %s; name = "%s"; path = "%s"; sourceTree = "<%s>"; };',
						node.id, node.name, xcode.getfiletype(node), node.name, pth, src)
				end
			end
		})
		
		_p('/* End PBXFileReference section */')
		_p('')
	end


	function xcode.PBXFrameworksBuildPhase(tr)
		_p('/* Begin PBXFrameworksBuildPhase section */')
		_p(2,'%s /* Frameworks */ = {', tr.products.children[1].fxstageid)
		_p(3,'isa = PBXFrameworksBuildPhase;')
		_p(3,'buildActionMask = 2147483647;')
		_p(3,'files = (')
		
		-- write out library dependencies
		tree.traverse(tr.frameworks, {
			onleaf = function(node)
				_p(4,'%s /* %s in Frameworks */,', node.buildid, node.name)
			end
		})
		
		-- write out project dependencies
		tree.traverse(tr.projects, {
			onleaf = function(node)
        if node.buildid then	--Only add valid nodes. It crashes when using project references.
          _p(4,'%s /* %s in Frameworks */,', node.buildid, node.name)
        end
			end
		})
		
		_p(3,');')
		_p(3,'runOnlyForDeploymentPostprocessing = 0;')
		_p(2,'};')
		_p('/* End PBXFrameworksBuildPhase section */')
		_p('')
	end


	function xcode.PBXGroup(tr)
		_p('/* Begin PBXGroup section */')

		tree.traverse(tr, {
			onnode = function(node)
				-- Skip over anything that isn't a proper group
				if (node.path and #node.children == 0) or node.kind == "vgroup" then
					return
				end
				
				-- project references get special treatment
				if node.parent == tr.projects then
					_p(2,'%s /* Products */ = {', node.productgroupid)
				else
					_p(2,'%s /* %s */ = {', node.id, node.name)
				end
				
				_p(3,'isa = PBXGroup;')
				_p(3,'children = (')
				for _, childnode in ipairs(node.children) do
          if node.parent == tr.projects then
            _p(4, '%s /* %s */,', childnode.id, node.project.xcode.projectnode.name)
          else
            _p(4,'%s /* %s */,', childnode.id, childnode.name)
          end
				end
				_p(3,');')
				
				if node.parent == tr.projects then
					_p(3,'name = Products;')
				else
					_p(3,'name = %s;', node.name)
					if node.path then
						local p = node.path
						if node.parent.path then
							p = path.getrelative(node.parent.path, node.path)
						end
						_p(3,'path = %s;', p)
					end
				end
				
				_p(3,'sourceTree = "<group>";')
				_p(2,'};')
			end
		}, true)
				
		_p('/* End PBXGroup section */')
		_p('')
	end	

  function xcode.XCSchemeBuildableReference(prj, depth)
    local node = prj.xcode.projectnode
    local sln = prj.solution
    local spaces = string.rep("   ", depth)
    _p('%s<BuildableReference', spaces)
    _p('%s   BuildableIdentifier = "primary"', spaces)
    _p('%s   BlueprintIdentifier = "%s"', spaces, node.targetid)
    _p('%s   BuildableName = "%s"', spaces, node.name)
    _p('%s   BlueprintName = "%s"', spaces, prj.name)
    _p('%s   ReferencedContainer = "container:%s">', spaces, path.getrelative(sln.location, prj.location) .. '/' .. prj.name .. ".xcodeproj" )
    _p('%s</BuildableReference>', spaces)
    
  end

  function xcode.XCScheme(sln)
    _p('<?xml version="1.0" encoding="UTF-8"?>')
    _p('<Scheme')
    _p('   version = "1.3">')
    _p('   <BuildAction')
    _p('      parallelizeBuildables = "YES"')
    _p('      buildImplicitDependencies = "YES">')
    _p('      <BuildActionEntries>')
    for prj in premake.solution.eachproject(sln) do
      _p('         <BuildActionEntry')
      _p('            buildForTesting = "YES"')
      _p('            buildForRunning = "YES"')
      _p('            buildForProfiling = "YES"')
      _p('            buildForArchiving = "YES"')
      _p('            buildForAnalyzing = "YES">')
      xcode.XCSchemeBuildableReference(prj, 4)
      _p('         </BuildActionEntry>')
    end
    _p('      </BuildActionEntries>')
    _p('   </BuildAction>')
    
    _p('   <TestAction')
    _p('      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.GDB"')
    _p('      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.GDB"')
    _p('      shouldUseLaunchSchemeArgsEnv = "YES"')
    _p('      buildConfiguration = "%s">', sln.currentScheme)
    _p('      <Testables>')
    _p('      </Testables>')
    _p('   </TestAction>')
    
    -- For launch and profiling looks for an executable app.
    local prj = nil
    for _prj in premake.solution.eachproject(sln) do
      if _prj.kind == "WindowedApp" or _prj.kind == "ConsoleApp" then
        prj = _prj
        break
      end
    end
    
    if prj ~= nil then
      local node = prj.xcode.projectnode[1]
      
      _p('   <LaunchAction')
      _p('      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.GDB"')
      _p('      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.GDB"')
      _p('      displayScaleIsEnabled = "NO"')
      _p('      displayScale = "1.00"')
      _p('      launchStyle = "0"')
      _p('      useCustomWorkingDirectory = "NO"')
      _p('      buildConfiguration = "%s">', sln.currentScheme)
      _p('      <BuildableProductRunnable>')
      xcode.XCSchemeBuildableReference(prj, 3)
      _p('      </BuildableProductRunnable>')
      _p('      <AdditionalOptions>')
      _p('      </AdditionalOptions>')
      _p('   </LaunchAction>')

      _p('   <ProfileAction')
      _p('      displayScaleIsEnabled = "NO"')
      _p('      displayScale = "1.00"')
      _p('      shouldUseLaunchSchemeArgsEnv = "YES"')
      _p('      savedToolIdentifier = ""')
      _p('      useCustomWorkingDirectory = "NO"')
      _p('      buildConfiguration = "%s">', sln.currentScheme)
      _p('      <BuildableProductRunnable>')
      xcode.XCSchemeBuildableReference(prj, 3)
      _p('      </BuildableProductRunnable>')
      _p('   </ProfileAction>')
    end
    
    _p('   <AnalyzeAction')
    _p('      buildConfiguration = "%s">', sln.currentScheme)
    _p('   </AnalyzeAction>')
    
    _p('   <ArchiveAction')
    _p('      buildConfiguration = "%s"', sln.currentScheme)
    _p('      revealArchiveInOrganizer = "YES">')
    _p('   </ArchiveAction>')
    
    _p('</Scheme>')
    
  end
  
	function xcode.PBXNativeTarget(tr)
    
		_p('/* Begin PBXNativeTarget section */')
		for _, node in ipairs(tr.products.children) do
			local name = tr.project.name
			
			_p(2,'%s /* %s */ = {', node.targetid, name)
			_p(3,'isa = PBXNativeTarget;')
			_p(3,'buildConfigurationList = %s /* Build configuration list for PBXNativeTarget "%s" */;', node.cfgsection, name)
			_p(3,'buildPhases = (')
			if #tr.project.prebuildcommands > 0 then
				_p(4,'9607AE1010C857E500CD1376 /* Prebuild */,')
			end
			_p(4,'%s /* Resources */,', node.resstageid)
			_p(4,'%s /* Sources */,', node.sourcesid)
			if #tr.project.prelinkcommands > 0 then
				_p(4,'9607AE3510C85E7E00CD1376 /* Prelink */,')
			end
			_p(4,'%s /* Frameworks */,', node.fxstageid)
			if #tr.project.postbuildcommands > 0 then
				_p(4,'9607AE3710C85E8F00CD1376 /* Postbuild */,')
			end
			_p(3,');')
			_p(3,'buildRules = (')
			_p(3,');')
			
			_p(3,'dependencies = (')
			for _, node in ipairs(tr.projects.children) do
				_p(4,'%s /* PBXTargetDependency */,', node.targetdependid)
			end
			_p(3,');')
			
			_p(3,'name = "%s";', name)
			
			local p
			if node.cfg.kind == "ConsoleApp" then
				p = "$(HOME)/bin"
			elseif node.cfg.kind == "WindowedApp" then
				p = "$(HOME)/Applications"
			end
			if p then
				_p(3,'productInstallPath = "%s";', p)
			end
			
			_p(3,'productName = "%s";', name)
			_p(3,'productReference = %s /* %s */;', node.id, node.name)
			_p(3,'productType = "%s";', xcode.getproducttype(node))
			_p(2,'};')
		end
		_p('/* End PBXNativeTarget section */')
		_p('')
	end


	function xcode.PBXProject(tr)
		_p('/* Begin PBXProject section */')
		_p(2,'08FB7793FE84155DC02AAC07 /* Project object */ = {')
		_p(3,'isa = PBXProject;')
		_p(3,'buildConfigurationList = 1DEB928908733DD80010E9CD /* Build configuration list for PBXProject "%s" */;', tr.name)
		_p(3,'compatibilityVersion = "Xcode 3.2";')
		_p(3,'hasScannedForEncodings = 1;')
		_p(3,'mainGroup = %s /* %s */;', tr.id, tr.name)
		_p(3,'projectDirPath = "";')
		
		if #tr.projects.children > 0 then
			_p(3,'projectReferences = (')
			for _, node in ipairs(tr.projects.children) do
				_p(4,'{')
				_p(5,'ProductGroup = %s /* Products */;', node.productgroupid)
				_p(5,'ProjectRef = %s /* %s */;', node.id, path.getname(node.path))
				_p(4,'},')
			end
			_p(3,');')
		end
		
		_p(3,'projectRoot = "";')
		_p(3,'targets = (')
		for _, node in ipairs(tr.products.children) do
			_p(4,'%s /* %s */,', node.targetid, node.name)
		end
		_p(3,');')
		_p(2,'};')
		_p('/* End PBXProject section */')
		_p('')
	end


	function xcode.PBXReferenceProxy(tr)
    -- If we have projects references (children) fill in the section with the required data
		if #tr.projects.children > 0 then
			_p('/* Begin PBXReferenceProxy section */')
			tree.traverse(tr.projects, {
				onleaf = function(node)
					--_p(2,'%s /* %s */ = {', node.id, node.name)
          _p(2,'%s /* %s */ = {', node.id, node.parent.project.xcode.projectnode.name)
					_p(3,'isa = PBXReferenceProxy;')
					_p(3,'fileType = %s;', xcode.gettargettype(node))
					_p(3,'path = "%s";', node.path)
					_p(3,'remoteRef = %s /* PBXContainerItemProxy */;', node.parent.productproxyid)
					_p(3,'sourceTree = BUILT_PRODUCTS_DIR;')
					_p(2,'};')
				end
			})
			_p('/* End PBXReferenceProxy section */')
			_p('')
		end
	end
	

	function xcode.PBXResourcesBuildPhase(tr)
		_p('/* Begin PBXResourcesBuildPhase section */')
		for _, target in ipairs(tr.products.children) do
			_p(2,'%s /* Resources */ = {', target.resstageid)
			_p(3,'isa = PBXResourcesBuildPhase;')
			_p(3,'buildActionMask = 2147483647;')
			_p(3,'files = (')
			tree.traverse(tr, {
				onnode = function(node)
					if xcode.getbuildcategory(node) == "Resources" then
						_p(4,'%s /* %s in Resources */,', node.buildid, node.name)
					end
				end
			})
			_p(3,');')
			_p(3,'runOnlyForDeploymentPostprocessing = 0;')
			_p(2,'};')
		end
		_p('/* End PBXResourcesBuildPhase section */')
		_p('')
	end
	
	function xcode.PBXShellScriptBuildPhase(tr)
		local wrapperWritten = false

		local function doblock(id, name, which)
			-- start with the project-level commands (most common)
			local prjcmds = tr.project[which]
			local commands = table.join(prjcmds, {})

			-- see if there are any config-specific commands to add
			for _, cfg in ipairs(tr.configs) do
				local cfgcmds = cfg[which]
				if #cfgcmds > #prjcmds then
					table.insert(commands, 'if [ "${CONFIGURATION}" = "' .. xcode.getconfigname(cfg) .. '" ]; then')
					for i = #prjcmds + 1, #cfgcmds do
						table.insert(commands, cfgcmds[i])
					end
					table.insert(commands, 'fi')
				end
			end
			
			if #commands > 0 then
				if not wrapperWritten then
					_p('/* Begin PBXShellScriptBuildPhase section */')
					wrapperWritten = true
				end
				_p(2,'%s /* %s */ = {', id, name)
				_p(3,'isa = PBXShellScriptBuildPhase;')
				_p(3,'buildActionMask = 2147483647;')
				_p(3,'files = (')
				_p(3,');')
				_p(3,'inputPaths = (');
				_p(3,');');
				_p(3,'name = %s;', name);
				_p(3,'outputPaths = (');
				_p(3,');');
				_p(3,'runOnlyForDeploymentPostprocessing = 0;');
				_p(3,'shellPath = /bin/sh;');
				_p(3,'shellScript = "%s";', table.concat(commands, "\\n"):gsub('"', '\\"'))
				_p(2,'};')
			end
		end
				
		doblock("9607AE1010C857E500CD1376", "Prebuild", "prebuildcommands")
		doblock("9607AE3510C85E7E00CD1376", "Prelink", "prelinkcommands")
		doblock("9607AE3710C85E8F00CD1376", "Postbuild", "postbuildcommands")
		
		if wrapperWritten then
			_p('/* End PBXShellScriptBuildPhase section */')
		end
	end
	
	
	function xcode.PBXSourcesBuildPhase(tr)
		_p('/* Begin PBXSourcesBuildPhase section */')
		for _, target in ipairs(tr.products.children) do
			_p(2,'%s /* Sources */ = {', target.sourcesid)
			_p(3,'isa = PBXSourcesBuildPhase;')
			_p(3,'buildActionMask = 2147483647;')
			_p(3,'files = (')
			tree.traverse(tr, {
				onleaf = function(node)
					if xcode.getbuildcategory(node) == "Sources" then
						_p(4,'%s /* %s in Sources */,', node.buildid, node.name)
					end
				end
			})
			_p(3,');')
			_p(3,'runOnlyForDeploymentPostprocessing = 0;')
			_p(2,'};')
		end
		_p('/* End PBXSourcesBuildPhase section */')
		_p('')
	end


	function xcode.PBXVariantGroup(tr)
		_p('/* Begin PBXVariantGroup section */')
		tree.traverse(tr, {
			onbranch = function(node)
				if node.kind == "vgroup" then
					_p(2,'%s /* %s */ = {', node.id, node.name)
					_p(3,'isa = PBXVariantGroup;')
					_p(3,'children = (')
					for _, lang in ipairs(node.children) do
						_p(4,'%s /* %s */,', lang.id, lang.name)
					end
					_p(3,');')
					_p(3,'name = %s;', node.name)
					_p(3,'sourceTree = "<group>";')
					_p(2,'};')
				end
			end
		})
		_p('/* End PBXVariantGroup section */')
		_p('')
	end


	function xcode.PBXTargetDependency(tr)
		if #tr.projects.children > 0 then
			_p('/* Begin PBXTargetDependency section */')
			tree.traverse(tr.projects, {
				onleaf = function(node)
					_p(2,'%s /* PBXTargetDependency */ = {', node.parent.targetdependid)
					_p(3,'isa = PBXTargetDependency;')
					_p(3,'name = "%s";', node.name)
					_p(3,'targetProxy = %s /* PBXContainerItemProxy */;', node.parent.targetproxyid)
					_p(2,'};')
				end
			})
			_p('/* End PBXTargetDependency section */')
			_p('')
		end
	end


	function xcode.XCBuildConfiguration_Target(tr, target, cfg)
		local cfgname = xcode.getconfigname(cfg)
		
		_p(2,'%s /* %s */ = {', cfg.xcode.targetid, cfgname)
		_p(3,'isa = XCBuildConfiguration;')
		_p(3,'buildSettings = {')
    
    local outdir = path.getdirectory(cfg.buildtarget.bundlepath)
		if outdir ~= "." then
      printf("\t\tOutput Dir: " .. outdir)
			_p(4,'CONFIGURATION_BUILD_DIR = "%s";', outdir)
		end
		
    printf("1!!")
		_p(4,'CONFIGURATION_TEMP_DIR = "%s";', cfg.objectsdir)
    
    printf("2!!")
    if cfg.buildtarget.prefix and cfg.buildtarget.prefix ~= "" then
			_p(4,'EXECUTABLE_PREFIX = %s;', cfg.buildtarget.prefix)
    else
      _p(4,'EXECUTABLE_PREFIX = "";')
		end
    
    printf("3!!")
    if tr.infoplist then
			_p(4,'INFOPLIST_FILE = "%s";', tr.infoplist.path)
		end
    
    installpaths = {
			ConsoleApp = '/usr/local/bin',
			WindowedApp = '"$(HOME)/Applications"',
			SharedLib = '/usr/local/lib',
			StaticLib = '/usr/local/lib',
		}
    printf("4!!")
		_p(4,'INSTALL_PATH = %s;', installpaths[cfg.kind])
    printf("5!!")
    _p(4,'OBJROOT = "%s";', cfg.objectsdir)
    printf("6!!")
    _p(4,'PRODUCT_NAME = "%s";', cfg.buildtarget.basename)
    printf("7!!")
    
    if cfg.targetdir and cfg.targetdir ~= "." then
      _p(4,'SYMROOT = "%s";', cfg.targetdir)
		end
    
    printf("8!!")
		_p(3,'};')
		_p(3,'name = "%s";', cfgname)
		_p(2,'};')
    
    printf("End of printing the config!!")
	end
	
	
  -- TODO - Add support for hardcoded values
	function xcode.XCBuildConfiguration_Project(tr, cfg)
		local cfgname = xcode.getconfigname(cfg)

		_p(2,'%s /* %s */ = {', cfg.xcode.projectid, cfgname)
		_p(3,'isa = XCBuildConfiguration;')
		_p(3,'buildSettings = {')
    
    if cfg.platform == "iOS" then
      _p(4,'ARCHS = "%s";', archs[cfg.platform])
      if cfg.XCodeSigning and cfg.XCodeSigning ~= "" and cfg.kind == "WindowedApp" then
        _p(4, '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "%s";', cfg.XCodeSigning)
      elseif cfg.XCodeSigning and cfg.XCodeSigning ~= "" then
        error("\tERROR: Code signing is only valid for Windowed Applications!!!! IGNORING value...")
      end
    else
      _p(4,'ARCHS = ("%s");', archs[cfg.platform])
    end
		
    
    if cfg.flags.Symbols then         _p(4,'COPY_PHASE_STRIP = NO;')                end
    if _ACTION ~= "xcode4" then       _p(4,'ALWAYS_SEARCH_USER_PATHS = NO;')        end
                                      _p(4,'DEBUG_INFORMATION_FORMAT = "dwarf";')
    if not cfg.flags.Symbols then     _p(4,'GCC_GENERATE_DEBUGGING_SYMBOLS = NO;')  end
                                      _p(4,'GCC_C_LANGUAGE_STANDARD = gnu99;')
    if cfg.flags.NoExceptions then    _p(4,'GCC_ENABLE_CPP_EXCEPTIONS = NO;')       end
    if cfg.flags.NoRTTI then          _p(4,'GCC_ENABLE_CPP_RTTI = NO;')             end
    if cfg.flags.Symbols and cfg.flags.NoEditAndContinue then _p(4,'GCC_ENABLE_FIX_AND_CONTINUE = NO;') end
    if cfg.flags.NoExceptions then    _p(4,'GCC_ENABLE_OBJC_EXCEPTIONS = NO;')      end
    if cfg.flags.Optimize or
        cfg.flags.OptimizeSize then   _p(4,'GCC_OPTIMIZATION_LEVEL = s;')           elseif 
        cfg.flags.OptimizeSpeed then  _p(4,'GCC_OPTIMIZATION_LEVEL = 3;')           else
                                      _p(4,'GCC_OPTIMIZATION_LEVEL = 0;')
    end
    if cfg.pchheader and not 
       cfg.flags.NoPCH then           _p(4,'GCC_PRECOMPILE_PREFIX_HEADER = YES;')
                                      _p(4,'GCC_PREFIX_HEADER = "%s";', cfg.pchheader)
    end
    xcode.printlist(cfg.defines, 'GCC_PREPROCESSOR_DEFINITIONS')
    
    if cfg.kind == "WindowedApp" then _p(4,'GCC_SYMBOLS_PRIVATE_EXTERN = NO;')      end
    if cfg.flags.FatalWarnings then   _p(4,'GCC_TREAT_WARNINGS_AS_ERRORS = YES;')   end
    
    -- TODO - Add support in flags for setting/unsetting warnings.
    _p(4,'GCC_WARN_ABOUT_INVALID_OFFSETOF_MACRO = NO;')
    _p(4,'GCC_WARN_ABOUT_RETURN_TYPE = YES;')
    --_p(4,'GCC_WARN_UNUSED_VARIABLE = YES;')
    
    xcode.printlist(cfg.includedirs, 'HEADER_SEARCH_PATHS')
    xcode.printlist(cfg.libdirs, 'LIBRARY_SEARCH_PATHS')
    if _ACTION ~= "xcode4" then _p(4,'ONLY_ACTIVE_ARCH = NO;')  end
    -- Link Libraries and Dependencies Link libraries ------------------
    -- build list of "other" C/C++ flags
		local checks = {
			["-ffast-math"]          = cfg.flags.FloatFast,
			["-ffloat-store"]        = cfg.flags.FloatStrict,
			["-fomit-frame-pointer"] = cfg.flags.NoFramePointer,
		}
    
    local flags = { }
    for flag, check in pairs(checks) do
      if check then
        table.insert(flags, flag)
      end
    end
    xcode.printlist(table.join(flags, cfg.buildoptions), 'OTHER_CFLAGS')

    -- build list of "other" linked flags. All libraries that aren't frameworks
    -- are listed here, so I don't have to try and figure out if they are ".a"
    -- or ".dylib", which Xcode requires to list in the Frameworks section    
    flags = { }
    printf("\t\tAdding libs: ")
    for _, lib in ipairs(premake.getlinks(cfg, "system", "fullpath")) do
      if not xcode.isframework(lib) then
        if lib ~= nil and lib ~= "" then
          table.insert(flags, lib)
          printf("\t\t\t'" .. lib .. "'")
        end
      end
    end
    flags = table.join(flags, cfg.linkoptions)
    
    -- Now automatically adds the libraries generated by the referenced/dependent projects.
    if #tr.projects.children > 0 then
      local outputTargetReferences = {}
      tree.traverse(tr.projects, {
        onleaf = function(node)
          local libName = path.getbasename(node.parent.project.xcode.projectnode.name)
          if string.startswith(libName, "lib") then
            local noLib = "-l" .. string.sub(libName, 4)
            table.insert(outputTargetReferences, noLib)
          else
            error("" .. node.parent.project.name .. " project has not the target name with the naming convention libXXXXXX.a. Fix that please!")
          end
        end
      })
      flags = table.join(flags, outputTargetReferences)
    end
    
    xcode.printlist(flags, 'OTHER_LDFLAGS')
    --------------------------------------------------------------------
    _p(4,'PREBINDING = NO;')
    _p(4,"SDKROOT = iphoneos;")
    if cfg.flags.StaticRuntime then _p(4,'STANDARD_C_PLUS_PLUS_LIBRARY_TYPE = static;') end
    _p(4,"TARGETED_DEVICE_FAMILY = 1,2;")
    _p(4,"VALID_ARCHS = \"armv7 i386\";")   
    
    if cfg.flags.ExtraWarnings then   _p(4,'WARNING_CFLAGS = "-Wall";')   end
    
		
		_p(3,'};')
		_p(3,'name = "%s";', cfgname)
		_p(2,'};')
	end


	function xcode.XCBuildConfiguration(tr)
		_p('/* Begin XCBuildConfiguration section */')
		for _, target in ipairs(tr.products.children) do
			for _, cfg in ipairs(tr.configs) do
        xcode.XCBuildConfiguration_Project(tr, cfg)
				xcode.XCBuildConfiguration_Target(tr, target, cfg)
			end
		end
    --[[
		for _, cfg in ipairs(tr.configs) do
			xcode.XCBuildConfiguration_Project(tr, cfg)
		end
    --]]
		_p('/* End XCBuildConfiguration section */')
		_p('')
	end


	function xcode.XCBuildConfigurationList(tr)
		local sln = tr.project.solution
		
		_p('/* Begin XCConfigurationList section */')
		for _, target in ipairs(tr.products.children) do
			_p(2,'%s /* Build configuration list for PBXNativeTarget "%s" */ = {', target.cfgsection, target.name)
			_p(3,'isa = XCConfigurationList;')
			_p(3,'buildConfigurations = (')
			for _, cfg in ipairs(tr.configs) do
				_p(4,'%s /* %s */,', cfg.xcode.targetid, xcode.getconfigname(cfg))
			end
			_p(3,');')
			_p(3,'defaultConfigurationIsVisible = 0;')
			_p(3,'defaultConfigurationName = "%s";', xcode.getconfigname(tr.configs[1]))
			_p(2,'};')
		end
		_p(2,'1DEB928908733DD80010E9CD /* Build configuration list for PBXProject "%s" */ = {', tr.name)
		_p(3,'isa = XCConfigurationList;')
		_p(3,'buildConfigurations = (')
		for _, cfg in ipairs(tr.configs) do
			_p(4,'%s /* %s */,', cfg.xcode.projectid, xcode.getconfigname(cfg))
		end
		_p(3,');')
		_p(3,'defaultConfigurationIsVisible = 0;')
		_p(3,'defaultConfigurationName = "%s";', xcode.getconfigname(tr.configs[1]))
		_p(2,'};')
		_p('/* End XCConfigurationList section */')
		_p('')
	end


	function xcode.Footer()
		_p(1,'};')
		_p('\trootObject = 08FB7793FE84155DC02AAC07 /* Project object */;')
		_p('}')
	end
