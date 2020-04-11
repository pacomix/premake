# Premake 4.3 + modifications

This is a old fork of Premake 4.3 with tons of fixes, modifications and addons.

## Premake4Mod

* Premake4Mod is the name given to the tool resulting of the whole changes applied to the original Premake v4.3 tool. This is the tool I use to generate the solution/project files.
* These modifications serve(s|d) my purposes and by no means Premake 4.3 was forked with any intention to be publicly released at that time.
* If you are wondering why a Premake 4.3 fork it is that back then (2013) cooperation and the whole GitHub ecosystem wasn't at the same stage it is now so sharing code, making pull requests and so wasn't the way it is now. I sent all my modifications back then to the author and I received a simple answer to submit my modifications to the repository. Since I didn't have that culture at that time I decided to just ignore that absence of interest in getting his tool kind of greatly improved. But now this is different so here you are.

## Changelist from original Premake 4.3
### General
- Added. Project Build configurations and platforms are now completely independent from the ones that are declared in the solution. The configuration objects are now traversed, collapsed and stored in every project object rather than in the solution object.
- Fixed. Function src/base/path.lua:path.getrelative(src, dst) - Computing a relative path was not working when the path was only one directory deeper regarding the parent. IE: path.getrelative("myPath/one", "one") was returning "myPath/one" instead of "one"
- Added. Support for using environment variables in a path declaration. For example to include dirs, output dirs, etc...
- Added. Specifying empty ("") flags is now possible. Useful when using templated script.
- Changed. Script to generate the executable in the correct place.


### Visual Studio 2008/10
- Added. Xbox deployment folder can be accessed now by using XBoxDeploymentHD variable which will contain absolute path.
- Added. Dummy configuration block in order Visual studio doesn't ask you to save an unmodified project file. Not working for C# projects at the moment.
- Added. Support for project's nice name. It allows to use a project name in the solution different from the project's filename.
- Added. Support for the built application's icon.
- Added. CustomBuildTool parameter's support.
- Fixed. Pre-build step for C# projects doesn't need to be escaped.
- Fixed. Correct path composing when using Visual Studio environment variables in paths.
- Fixed. When using quotes in the lib link variables the extension is not added anymore. Now it takes the name as it is inside the quotes.
- Fixed. Empty string in path's variables doesn't return anymore relative path to the same current directory: "."
- Added. Support for import library output target.
- Added. Support to use an specific referenced Assembly version.
- Fixed. Property sheet's path entry was being written with forward slashes non-translated into backward ones.
- Added. Support for generating stripped .pdb files.
- Fixed. Optimization flags when used in conjunction with property sheets.
- Fixed. A project was not being defined as Managed project when its whole configurations were defining the Managed flag.
- Fixed. Correct toolsversion field matching the version number generated by the Service Pack 1 for C# projects.
- Fixed. Project dependencies were also generating a link library entry in the property Additional Dependencies. It should have the project dependency entry in the solution file.
- Added. Namespace. For C# projects, it specifies the Default Namespace of the Assembly.
- Added. Flag CSGenerateDoc. When specified on C# projects, the build configuration will output the documentation with filename $(AssemblyName).doc.xml in the intermediate directory.
- Added. Flag CSTargetAnyCPU. When specified on C# projects, the build configuration platform will be targeted for Any CPU.
- Fixed. When a ".designer.cs" dependency exist, the relative path is now calculated correctly.
- Added. System assemblies references for C++ projects.
- Added. Support for setting FavorSizeOrSpeed parameter.
- Added. Support for Enable/Disable Intrinsic Functions.
- Added. Support for Inline Function Expansion parameter based in the optimization level.
- Added. Support for configuring different levels of Warnings.
- Fixed. Import library was not being defined for ConsoleApp/WindowedApp output type.
- Fixed. Symbols format is now correct based in the NoEditAndContinue flag.
- Fixed. GenerateDebugInfo is now correctly set in Visual Studio.
- Fixed. Order of the build configurations to match the order established in Visual Studio.
- Added. Support for property sheets.
- Fixed. Ignore libraries parameter for VS2008/10. Now supported in both IDEs for Static and Non-Static builds.
- Fixed. Generation of the library link string with the .ppu.obj extension is now correct.
- Fixed. Buffer security check default parameter was being set incorrectly.
- Added correct support for project references in solutions:
  - Default Debug/Release build config is mapped inside the .sln file if no matching build configuration from the Solution is found in the referenced project.
  - Only matching build configurations defined in a project are created for the .prj file when it is referenced inside a solution that has more/different build configurations.
- Fixed. Correct option is selected now based in the output type (StaticLib, SharedLib, etc...) when the MFC flag is set.
- Fixed. UseOfMFC was wrong when linking against shared/static runtime libraries.
- Added. StackReserveSize and StackCommitSize parameters.
- Added. Support to add project references inside a project.
- Added. Support for setting No Precompiled Header support for specific files through a file list.
- Added. Support for excluding files from specific build configs.
- Fixed. Correct linking when using the -l format for the names of the link libraries.
- Added. Support for setting the Incremental Link parameter.
- Added. Support for disabling Buffer Security Check parameter.
- Added. Support for disabling Function Level Linking parameter.
- Added. Support for disabling String Pooling parameter.
- Added. Support for disabling Basic Runtime Check parameter.
- Added. Support for setting CustomBuildTool for specific files.
- Added. Support for Disabling Specific Warnings.

### Visual Studio 2010
- Added. Full Support for PS3 platform in Visual Studio 2010.
- Added. Full Support for XBox360 platform in Visual Studio 2010.
- Added. Support for the Static Code Analysis tool through VSEnableStaticCodeAnalysis flag.
- Fixed. Compile language was not correctly being set.
- Fixed. BasicRuntimeCheck parameter was not correctly being set.
- Fixed. Excluding resource files from build was completely ignored.
- Fixed. Some values were being overwritten when using property sheets in Visual Studio 2010 projects when it shouldn't.
- Fixed. Defining a configuration for using CLR (Managed flag) had no effect on Visual Studio 2010 projects.
- Fixed. Assemblies (system) references were not being correctly generated for Visual Studio 2010 projects.
- Added. Support for C# project generation.
- Fixed. NoImportLib flags now also takes in account Shared lib, ConsoleApp and WindowedApp output types.
- Fixed. Whole Program Optimization was being set by default.
- Fixed. Correct project extension when using Default as Compile As parameter.
- Added. Added Default to the Compile As parameter
- Added. TargetMachine parameter for Static Library output types.
- Fixed. Missing Additional Dependencies and Library Directories for StaticLib (Librarian Section) configurations.

### Visual Studio 2008
- Added. Support for ForcedUsingFiles parameter.
- Changed. Set the CopyLocal parameter of References for C++ projects to False again.
- Debug Output Format is set now to Disabled/Default when flag Symbols is not defined.
- Fix. Import lib can also be generated for Application project type (Console/WindowedApp).
- Changed. Set the CopyLocal parameter of References for C++ projects to True.
- Fixed. TargetMachine was being overwritten when using Property Sheets.
- Fixed. RuntimeLibrary parameter when used in conjunction with Property Sheets and targetting the Xbox360 platform. This parameter is not inherited from the property sheet file and must be explicitly written.
- Fixed. NoLinkLibDepencies flags were not working correctly. Depending on the output type (StaticLib, ConsoleApp, SharedLib) the default value was different.
- Changed. Project References and Project Dependencies are both now supported in solutions files.
- Added. Pre/Post build step in C# projects.
- Fixed. Inclusion of quotes in Additional Dependencies entries.
- Added. Support solution-project build configurations mapping.
- Added. Support for Makefile output type (VCNMakeTool).
- Added. Support to define framework version in C# projects.
- Added. "Default" to supported languages.
- Added. Support for Delay Loaded DLLs list.
- Added. Support for Link Library Dependencies parameter.
- Added. Support for setting the calling convention.
- Fixed. Resource Compiler Tool additional include directories was also using the Compiler Tool additional include directories.
- Fixed. Resource Compiler Tool preprocessor definitions was also using the Compiler Tool preprocessor definitions.
- Fixed. Target Machine parameter was not being set correctly for x64 platform.
- Added. Support for disabling Optimize References parameter.
- Added. Support for disabling COMDATFolding parameter.
- Added. Support for the description parameter of Pre-Post build steps.
- Added. Support to define the Culture parameter for the Resource Compiler.

### XCode 4+
- Added. Generation of Workspace and scheme files.

### XCode 3.2/4
- Fixed. Build Configuration sections was containing merged options between the sections. Now they are written exactly in the same order and in the correct build configuration's section.
- Fixed. Dependencies section now contains the correct project ID in their respective sections as well as correct names in the comment fields.
- Fixed. Linking libraries was using by default '-l' option that was causing an error in the link stage.
- Fixed. Getting link libraries was using fullpath of the link lib of the system where Premake4 was being executed.
- Changed. By default position dependent code parameter is never used anymore.
- Fixed. Prefix to output target name was not being applied for StaticLib output type.
- Fixed. Symbols were being generated even when not definining the Symbols flag.
- Added. Updated the generation of XCode projects from version 3.1 to 3.2
- Added. Persistent generation of unique object IDs based on object type, name, path, etc... (Still under revision. Used in the whole XCode projects and working fine although it doesn't follow XCode hashing algorithm since it is not know at the moment...)
- Added. Resource file type support for any kind of extension.
- Added. iOS platform support.

### New Premake Parameters
Take a look inside src/base/api.lua for more info about each parameter.

- mapBuildConfigurations:                  Defines a list of solution's build configurations mapped to the project's build configuration. Optional.
- projectPossibleBuildableConfigurations:  Defines the build configurations of a project.
- projectBuildableConfigurations:          Specify which configurations of a project should be built.
- callingConvention
- XCodeSigning
- nopchfile:                               Filelist that specifies the files that shouldn't use precompiled headers.
- custombuildtool:                         Filelist that specifies the files that should use custom build tool.
- custombuildcommandline:                  Command line for custom build tool. Must be specified per file.
- custombuildcommandlineOutput:            Output files generated by the custom build command line.
- custombuildcommandlineDepends:           Dependent files for triggering the custom build step.
- forcedusingfiles:                        Fill the Forced Using files field with the passed list.
- ignoredefaultlibrarynames:               List for ignoring default libs during linking.
- disablespecificwarnings:                 List with the warning numbers to be ignored during the build.
- delayloadeddlls:                         List with dll's names to be set in the Visual Studio Delay Loaded DLL's parameter.
- VSresculture:                            Culture parameter for the resource compiler.
- XBoxDeploymentHD:                        Specifies the deployment path to the target XBox. Absolute path.
- resources:                               File list (it can be also a folder name) to be include as resources.
- toolset:                                 (VS2010-PS3 only) - Specifies the toolset to use for building. SNC, GCC or SPU
- fileservingPS3:                          (VS2010-PS3 only) - Specifies which directory to use when launching the debugger for PS3.
- homedirPS3:                              (VS2010-PS3 only) - Specifies the home dir to use when launching the debugger for PS3.

- Flags:
   - VSEnableFunctionLevelLinking: Activates this parameter in a Visual Studio project.
   - VSBufferSecurityCheck:        Activates this parameter in a Visual Studio project.
   - VSFavorSize:                  Activates this parameter in a Visual Studio project.
   - VSFavorSpeed:                 Activates this parameter in a Visual Studio project.
   - VSEnableIntrinsicFunctions:   Activates this parameter in a Visual Studio project.
   - VSUseReferencesInProjects:    Activates the project referencing inside the projects.
   - VSNoBasicRuntimeCheck:        Deactivates this parameter in a Visual Studio project.
   - VSNoStringPooling:            Deactivates this parameter in a Visual Studio project.
   - VSNoOptimizeReferences:       Deactivates this parameter in a Visual Studio project.
   - VSNoCOMDATFolding:            Deactivates this parameter in a Visual Studio project.
   - VSNoTargetMachine:            Deactivates this parameter in a Visual Studio project.
   - VSNoSubSystem:                Deactivates this parameter in a Visual Studio project.
   - VSEnableStaticCodeAnalysis:   Activates the Static Code Analysis in VS2010 Ultimate.
   - NoIncrementalLink:            Deactivates this parameter in a Visual Studio project.
   - NoLinkLibDependencies:        Deactivates this parameter in a Visual Studio project.
   - MinWarnings:                  Minimum level of Warnings during builds.
   - CSGenerateDoc:                When specified on C# projects, the build configuration will output the documentation with filename $(AssemblyName).doc.xml in the intermediate directory.
   - CSTargetAnyCPU:               When specified on C# projects, the build configuration platform will be targeted for Any CPU.
   - VSDisableSPUElfConversion     (VS2010-PS3 only) - Disables the section to automatically generate the conversion to .ppu.obj of SPU project type. Note that then you will have to use a post build step in order to achieve this and manually add the link dependencies to the project.
