using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;

namespace VS2Premake
{
  /// <summary>
  /// Extract, Sort and Write all -- Additional Include Libraries -- to the script.
  /// </summary>
  public class IncludeDirs : ILibraryCollection
  {

    public override string[] processLines
    {
      get
      {
        return new string[] { "includeDirs" };
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

    /// <summary>
    /// Sorts all Include Libraries by script-variable. 
    /// </summary>
    /// <param name="unsorted"></param>
    /// <returns></returns>
    protected override Dictionary<string, string> Sort(Dictionary<string, List<string>> unsorted)
    {
      var sorted = new Dictionary<string, string>();

      List<string> libsX86 = VS2Premake.TryGetValue(unsorted, "Release|x32");
      List<string> libsX64 = VS2Premake.TryGetValue(unsorted, "Release|x64");

      List<string> libsXbox360 = VS2Premake.TryGetValue(unsorted, "Release|Xbox360");
      List<string> libsPS3 = VS2Premake.TryGetValue(unsorted, "Release PS3|x32");
      List<string> libsPSP2 = VS2Premake.TryGetValue(unsorted, "Release PSP2|x32");

      List<string> includeCommon = new List<string>();
      if (libsX64.Count > 0)
        includeCommon = VS2Premake.ReturnEqual(libsX86, libsX64);
      else if (libsPS3.Count > 0)
        includeCommon = VS2Premake.ReturnEqual(libsX86, libsPS3);
      else if (libsPSP2.Count > 0)
        includeCommon = VS2Premake.ReturnEqual(libsX86, libsPSP2);
      else if (libsXbox360.Count > 0)
        includeCommon = VS2Premake.ReturnEqual(libsX86, libsXbox360);

      if (libsXbox360.Count > 0)
        includeCommon = VS2Premake.ReturnEqual(includeCommon, libsXbox360);
      if (libsPS3.Count > 0) 
        includeCommon = VS2Premake.ReturnEqual(includeCommon, libsPS3);
      if (libsPSP2.Count > 0) 
        includeCommon = VS2Premake.ReturnEqual(includeCommon, libsPSP2);

      sorted.Add("includeDirsCommon", String.Format("{{ {0} }}", VS2Premake.FormatListToString(includeCommon)));

      List<string> includeX86 = VS2Premake.SubstractLists(libsX86, includeCommon);
      sorted.Add("includeDirsWin32", String.Format("{{ includeDirsCommon, {0} }}", VS2Premake.FormatListToString(includeX86)));

      List<string> includeX64 = new List<string>();     
      if (libsX64.Count > 0)
        includeX64 = VS2Premake.SubstractLists(libsX64, libsX86);     
      if (VS2Premake.TryFindKeyPart(unsorted, "x64"))
        sorted.Add("includeDirsX64", String.Format("{{ includeDirsWin32, {0} }}", VS2Premake.FormatListToString(includeX64)));

      List<string> includeXbox = new List<string>();
      if (libsXbox360.Count > 0)
        includeXbox = VS2Premake.SubstractLists(libsXbox360, includeCommon);
      if (VS2Premake.TryFindKeyPart(unsorted, "Xbox360"))
        sorted.Add("includeDirsXbox360", String.Format("{{ includeDirsCommon, {0} }}", VS2Premake.FormatListToString(includeXbox)));

      List<string> includePS3 = new List<string>();
      if (libsPS3.Count > 0)
        includePS3 = VS2Premake.SubstractLists(libsPS3, includeCommon);
      if (VS2Premake.TryFindKeyPart(unsorted, "PS3"))
        sorted.Add("includeDirsPS3", String.Format("{{ includeDirsCommon, {0} }}", VS2Premake.FormatListToString(includePS3)));

      List<string> includePSP2 = new List<string>();
      if (libsPSP2.Count > 0)
        includePSP2 = VS2Premake.SubstractLists(libsPSP2, includeCommon);
      if (VS2Premake.TryFindKeyPart(unsorted, "PSP2"))
        sorted.Add("includeDirsPSP2", String.Format("{{ includeDirsCommon, {0} }}", VS2Premake.FormatListToString(includePSP2)));

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
          if (name.Value == "VCCLCompilerTool" || name.Value == "VCCLX360CompilerTool")
          {
            XmlAttribute includeLibs = tool.Attributes["AdditionalIncludeDirectories"];
            if (includeLibs != null)
              return VS2Premake.SplitString(includeLibs.Value);
          }
        }
      }
      return null;
    }
  }
}
