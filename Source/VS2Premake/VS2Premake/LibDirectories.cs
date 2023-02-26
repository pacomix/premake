using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;

namespace VS2Premake
{
  /// <summary>
  /// Extract, Sort and Write all -- Additional Library Directories -- to the script.
  /// </summary>
  public class LibDirs : ILibraryCollection
  {

    public override string[] processLines
    {
      get
      {
        return new string[] { "libDirs" };
      }
    }

    /// <summary>
    /// The EntryPoint. Manages the full process from extraction to writing to the script.
    /// </summary>
    /// <param name="e">Holds data about the script line and the Xml project-file.</param>
    public override void Process(LineReadEventArgs e)
    {
      if (!IsValidLine(e.Line))
        return;

      // setup
      Dictionary<string, List<string>> unsortedLibs;
      Dictionary<string, string> sortedLibs;
      XmlNode configurations = VS2Premake.GetNode("Configurations", e.Project);

      // find
      unsortedLibs = Find(configurations);

      // sort
      sortedLibs = Sort(unsortedLibs);

      // write
      Write(ref e.Line, sortedLibs);
    }


    protected override Dictionary<string, string> Sort(Dictionary<string, List<string>> unsortedLibs)
    {
      var sorted = new Dictionary<string, string>();

      List<string> libsX86 = VS2Premake.TryGetValue(unsortedLibs,"Release|x32");
      List<string> libsX64 = VS2Premake.TryGetValue(unsortedLibs, "Release|x64");

      List<string> libsStaticX64 = VS2Premake.TryGetValue(unsortedLibs, "StaticLib Release|x64");
      List<string> libsStaticX86 = VS2Premake.TryGetValue(unsortedLibs, "StaticLib Release|x32");

      List<string> libsXbox360 = VS2Premake.TryGetValue(unsortedLibs, "Release|Xbox360");
      List<string> libsPS3 = VS2Premake.TryGetValue(unsortedLibs, "Release PS3|x32");
      List<string> libsPSP2 = VS2Premake.TryGetValue(unsortedLibs, "Release PSP2|x32");

      // -- All Win32 & X64 Specific -- //

      #region Extra Variables 'libDirsAllWin32, libDirsAllX64'

      List<string> includeAllX86 = new List<string>();
      if (libsX86.Count > 0 && libsStaticX86.Count > 0)
        includeAllX86 = VS2Premake.ReturnEqual(libsX86, libsStaticX86);
      sorted.Add("libDirsAllWin32", String.Format("{{ {0} }}", VS2Premake.FormatListToString(includeAllX86)));

      List<string> includeAllX64 = new List<string>();
      if (libsX64.Count > 0 && libsStaticX64.Count > 0)
        includeAllX64 = VS2Premake.ReturnEqual(libsX64, libsStaticX64);
      sorted.Add("libDirsAllX64", String.Format("{{ {0} }}", VS2Premake.FormatListToString(includeAllX64)));

      #endregion

      // -- Main Variables -- //

      #region Windows
      List<string> includeX86 = new List<string>();
      if (libsX86 != null)
        includeX86 = VS2Premake.SubstractLists(libsX86, includeAllX86);
      sorted.Add("libDirsWin32", String.Format("{{ libDirsAllWin32, {0} }}", VS2Premake.FormatListToString(includeX86)));

      List<string> includeX64 = new List<string>();
      if (libsX64 != null)
        includeX64 = VS2Premake.SubstractLists(libsX64, includeAllX64);
      sorted.Add("libDirsX64", String.Format("{{ libDirsAllX64, {0} }}", VS2Premake.FormatListToString(includeX64)));

      List<string> includeStaticX86 = new List<string>();
      if (libsStaticX86 != null)
        includeStaticX86 = VS2Premake.SubstractLists(libsStaticX86, includeAllX86);
      sorted.Add("libDirsStaticWin32", String.Format("{{ libDirsAllWin32, {0} }}", VS2Premake.FormatListToString(includeStaticX86)));

      List<string> includeStaticX64 = new List<string>();
      if (libsStaticX64 != null)
        includeStaticX64 = VS2Premake.SubstractLists(libsStaticX64, includeAllX64);
      sorted.Add("libDirsStaticX64", String.Format("{{ libDirsAllX64, {0} }}", VS2Premake.FormatListToString(includeStaticX64)));

      #endregion

      #region Consoles (Xbox, PS3, PSP2)
      List<string> includeXbox = new List<string>();
      if (libsXbox360 != null)
      {
        includeXbox = VS2Premake.SubstractLists(libsXbox360, libsX86);
        sorted.Add("libDirsXbox360", String.Format("{{ {0} }}", VS2Premake.FormatListToString(includeXbox)));
      }

      List<string> includePS3 = new List<string>();
      if (libsPS3 != null)
      {
        includePS3 = VS2Premake.SubstractLists(libsPS3, libsX86);
        sorted.Add("libDirsPS3", String.Format("{{ {0} }}", VS2Premake.FormatListToString(includePS3)));
      }

      List<string> includePSP2 = new List<string>();
      if (libsPSP2 != null)
      {
        includePSP2 = VS2Premake.SubstractLists(libsPSP2, libsX86);
        sorted.Add("libDirsPSP2", String.Format("{{ {0} }}", VS2Premake.FormatListToString(includePSP2)));
      } 
      #endregion

      return sorted;
    }

    /// <summary>
    /// Extract IncludeLibraries for a single configuration from a Visual Studio 9 project file.
    /// </summary>
    protected override List<string> Extract(XmlNode configuration)
    {
      foreach (XmlNode tool in configuration.ChildNodes)
      {
        XmlAttribute name = tool.Attributes["Name"];
        if (name != null)
        {
          if (name.Value == "VCLibrarianTool" || name.Value == "VCLinkerTool" || name.Value == "VCX360LinkerTool")
          {
            XmlAttribute libs = tool.Attributes["AdditionalLibraryDirectories"];
            if (libs != null)
            {
              return VS2Premake.SplitString(libs.Value);
            }
          }
        }
      }
      return null;
    }
  }
}
