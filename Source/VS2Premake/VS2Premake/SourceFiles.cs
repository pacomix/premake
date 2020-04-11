using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Linq;
using System.Text;
using System.IO;
using System.Xml;

namespace VS2Premake
{
  /// <summary>
  /// Extract, Sort, Format and Write source-files to the script.
  /// </summary>
  public class SourceFiles
  {
    /// <summary>
    /// Defines files that should be ignored by the exclusion processor, meaning they do show up inside sourceFiles {} but not in any of the excludeXXX {} variable tables of the script.
    /// </summary>
    private static List<string> ignoredFiles = new List<string>() { ".\\vsi.nul" };

    /// <summary>
    /// The EntryPoint. Manages the full process from extraction to writing to the script.
    /// </summary>
    /// <param name="e">Holds data about the script line and the Xml project-file.</param>
    public void Process(LineReadEventArgs e)
    {
      // only execute if we had the correct line-group.
      if (e.Line.StartsWith("source") || e.Line.StartsWith("excluded")) { }
      else
        return;
      
      Console.WriteLine("> Processing: Source Files..");

      // -- Setup -- //
      var noPCHfiles = new List<string>();
      var sourceFiles = new List<string>();
      var excludedFromBuild = new Dictionary<string, List<string>>();

      foreach (var config in VS2Premake.ValidConfigurations)
      {
        excludedFromBuild.Add(config, new List<string>());
      }

      XmlNode files = VS2Premake.GetNode("Files", e.Project);


      // -- Search Source Files -- //
      //Console.WriteLine("    Searching Files..");
      FindSource(files, sourceFiles, noPCHfiles, excludedFromBuild);


      // -- Fix Errors & Write to Script -- //
      Console.WriteLine("    Finding And Fixing Errors...");

      FindAndSolveErrors(sourceFiles);
      WriteSourceFilesToScript(ref e.Line, "sourceFiles ", sourceFiles);

      FindAndSolveErrors(noPCHfiles);
      WriteSourceFilesToScript(ref e.Line, "sourcesNotUsingPCH ", noPCHfiles);

      if (e.Line.StartsWith("excludedSourcesWindows "))
      {
        List<string> excludedSourcesWindows = VS2Premake.TryGetValue(excludedFromBuild, "Debug|x32");
        FindAndSolveErrors(excludedSourcesWindows);
        WriteSourceFilesToScript(ref e.Line, "excludedSourcesWindows ", excludedSourcesWindows);
      }
      else if (e.Line.StartsWith("excludedSourcesWindowsNoXI "))
      {
        List<string> excludedSourcesWindowsNoXI = VS2Premake.TryGetValue(excludedFromBuild, "Debug NoXI|x32");
        FindAndSolveErrors(excludedSourcesWindowsNoXI);
        WriteSourceFilesToScript(ref e.Line, "excludedSourcesWindowsNoXI ", excludedSourcesWindowsNoXI);
      }
      else if (e.Line.StartsWith("excludedSourcesXbox360"))
      {
        List<string> excludedSourcesXbox360 = VS2Premake.TryGetValue(excludedFromBuild, "Debug|Xbox360");
        FindAndSolveErrors(excludedSourcesXbox360);
        WriteSourceFilesToScript(ref e.Line, "excludedSourcesXbox360", excludedSourcesXbox360);
      }
      else if (e.Line.StartsWith("excludedSourcesPS3"))
      {
        List<string> excludedSourcesPS3 = VS2Premake.TryGetValue(excludedFromBuild, "Debug PS3|x32");
        FindAndSolveErrors(excludedSourcesPS3);
        WriteSourceFilesToScript(ref e.Line, "excludedSourcesPS3", excludedSourcesPS3);
      }
      else if (e.Line.StartsWith("excludedSourcesPSP2"))
      {
        List<string> excludedSourcesPSP2 = VS2Premake.TryGetValue(excludedFromBuild, "Debug PSP2|x32");
        FindAndSolveErrors(excludedSourcesPSP2);
        WriteSourceFilesToScript(ref e.Line, "excludedSourcesPSP2", excludedSourcesPSP2);
      }

    }

    /// <summary>
    /// Finds and automatically fixes invalid-paths and casing errors. 
    /// </summary>
    /// <param name="fileList"></param>
    private void FindAndSolveErrors(List<string> fileList)
    {
      // add prefix (./)
      AddPrefix(fileList);

      Dictionary<int, string> copiedSourceFiles = new Dictionary<int, string>();
      for (int i = 0; i < fileList.Count; i++)
      {
        copiedSourceFiles.Add(i, fileList[i]);
      }

      foreach (var index in copiedSourceFiles.Keys)
      {
        string originalRelativePath = copiedSourceFiles[index];

        if (ignoredFiles.Contains(originalRelativePath))
          continue;

        string properFullpath = originalRelativePath;
        try
        {
          properFullpath = VS2Premake.GetProperFilePathCapitalization(originalRelativePath);
        }
        catch (Exception)
        {
          fileList.Remove(originalRelativePath);

          Console.WriteLine("        <!> Deleted: {0}", originalRelativePath);
        }
        finally
        {
          if (originalRelativePath != properFullpath)
          {
            fileList.Remove(originalRelativePath);

            string properFilename = Path.GetFileName(properFullpath);
            string originalFilename = Path.GetFileName(originalRelativePath);

            string renamedRelativePath = originalRelativePath.Replace(originalFilename, properFilename);

            fileList.Add(renamedRelativePath);

            Console.WriteLine("        <!> Renamed: {0}", originalRelativePath);
          }
        }
      }
    }

    /// <summary>
    /// Adds ./ as prefix if files don't already have one.
    /// </summary>
    /// <param name="fileList"></param>
    private void AddPrefix(List<string> fileList)
    {
      List<string> copiedSource = new List<string>(fileList);
      // always start with './'
      for (int i = 0; i < copiedSource.Count; i++)
      {
        if (copiedSource[i].StartsWith("..\\") ||
          copiedSource[i].StartsWith(".\\"))
          continue;
        else
        {
          fileList[i] = ".\\" + fileList[i];
        }
      }
    }

    /// <summary>
    /// Recursively adds all source files into the collection. 
    /// </summary>
    /// <param name="node">the node inside the Xml that acts as a parent for all Files.</param>
    private void FindSource(XmlNode node, List<string> sourceFiles, List<string> noPCHfiles, Dictionary<string, List<string>> excludedFromBuild)
    {       
      // <Xml LAYOUT>
      // > Files
      //  > Filter
      //   > File->RelativePath
      //     > FileConfiguration->UsePreCompiledHeader(1:0) 

      foreach (XmlNode file in node.ChildNodes)
      {
        XmlAttribute filepath = file.Attributes["RelativePath"];
        if (filepath == null)
        {
          // this node is not valid, i.e. doesn't contain "RelativePath". Search in its childnodes for a valid filelist instead.
          FindSource(file, sourceFiles, noPCHfiles, excludedFromBuild);
        }
        else
        {
          if (!sourceFiles.Contains(filepath.Value))
          {
            if (!UsingPreCompiledHeader(file))
            {
              noPCHfiles.Add(filepath.Value);
            }   
            else
            {           
              sourceFiles.Add(filepath.Value);
            }

            ExcludedFromBuild(file, excludedFromBuild);
          }
        }
      }
    }

    /// <summary>
    /// See if the file uses a pre-compiled header. 
    /// </summary>
    /// <param name="file">The file to check.</param>
    /// <returns>whether precompiledheaders (PCH) is used by this file.</returns>
    private bool UsingPreCompiledHeader(XmlNode file)
    {
      foreach (XmlNode fileconfig in file.ChildNodes)
      {
        foreach (XmlNode tool in fileconfig.ChildNodes)
        {
          XmlAttribute attribute = tool.Attributes["UsePrecompiledHeader"];
          if (attribute != null)
          {
            string usePCH = attribute.Value;
            if (usePCH == "1")
              return true;
            else
              return false;
          }
        }
      }
      return true;
    }

    /// <summary>
    /// Find all files that are excluded from specific build configurations (PS3, Windows, Xbox360 etc.) and sort them per category (i.e. excludedSourcesPS3)
    /// </summary>
    /// <param name="file">the file that may be excluded from a configuration.</param>
    /// <param name="excludedFromBuild">the collection holding all excluded files per configuration.</param>
    /// <returns>returns true if this specific files is excluded from one or more build configuration.</returns>
    private bool ExcludedFromBuild(XmlNode file, Dictionary<string, List<string>> excludedFromBuild)
    {
      bool excluded = false;
      foreach (XmlNode fileconfig in file.ChildNodes)
      {
        XmlAttribute attribute = fileconfig.Attributes["ExcludedFromBuild"];
        if (attribute != null)
        {
          string exclude = attribute.Value;
          if (exclude == "true")
          {
            string configname = fileconfig.Attributes["Name"].Value;
            configname = VS2Premake.ConvertToPremakeCompatibleConfig(configname);

            if (VS2Premake.ValidConfigurations.Contains(configname))
            {
              excludedFromBuild[configname].Add(file.Attributes["RelativePath"].Value);
            }
            excluded = true;
          }
        }       
      }
      return excluded;
    }

    /// <summary>
    /// Formats the source files and writes them to the script line.
    /// </summary>
    /// <param name="script">The line to write to.</param>
    /// <param name="varName">The variable name in the script to add the files to.</param>
    /// <param name="sourceFiles">The files to add.</param>
    private void WriteSourceFilesToScript(ref string script, string varName, List<string> sourceFiles)
    {

      string allFiles = VS2Premake.FormatListToString(sourceFiles);

      // if we have no actual values, clear the complete string.
      // reason: no invalid files inside VS project named: "."
      if (allFiles == "\"\"")
        allFiles = "";

      // add new-line symbol + 4 indents
      allFiles = allFiles.Replace(", ", ",\n    ");

      if (varName == "sourceFiles ")
      {
        allFiles = "\n    sourcesNotUsingPCH,\n    " + allFiles;
      }
      else
      {
        // format for the sourcesNotUsingPCH and other categories.
        allFiles = "\n    " + allFiles;
      }

      if (script.StartsWith(varName))
      {
        script = script.Replace("\"\"", allFiles);

        Console.WriteLine("    Processed: {0}", varName);
      }
    }
  }
}

