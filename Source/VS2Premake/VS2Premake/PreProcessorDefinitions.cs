using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;

namespace VS2Premake
{
  /// <summary>
  /// Extract, Sort and Write all -- PreProcessor Definitions -- to the script.
  /// </summary>
  public class PreProcessorDefinitions : ILibraryCollection
  {

    public override string[] processLines
    {
      get
      {
        return new string[] { "defines" };
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

      // -- Setup -- //
      XmlNode configs = VS2Premake.GetNode("Configurations", e.Project);

      var unsorted = new Dictionary<string, List<string>>();
      var sorted = new Dictionary<string, string>();


      // -- Find -- //
      unsorted = Find(configs);

      // -- Sort -- //
      sorted = Sort(unsorted);

      // -- Write -- //
      Write(ref e.Line, sorted);
    }


    /// <summary>
    /// Sorts all definitions into a dictionary grouped per script-variable. 
    /// </summary>
    protected override Dictionary<string, string> Sort(Dictionary<string, List<string>> unsorted)
    {
      var sorted = new Dictionary<string, string>();

      SortPS3_PSP2(unsorted, sorted);

      SortDX11(unsorted, sorted);

      SortOthers(unsorted, sorted);

      return sorted;
    }

    /// <summary>
    /// Sorting for DX11 configurations.
    /// </summary>
    private void SortDX11(Dictionary<string, List<string>> unsorted, Dictionary<string, string> sorted)
    {
      if (!VS2Premake.TryFindKeyPart(unsorted, "DX11"))
        return;
      
      List<string> debugX86 = unsorted["Debug|x32"];
      List<string> releaseX86 = unsorted["Release|x32"];
      List<string> debugDX11 = unsorted["Debug DX11|x32"];

      List<string> definesDX11 = Subtract(debugDX11, debugX86, releaseX86);

      sorted.Add("definesDX11 ", Format(definesDX11));
    }

    /// <summary>
    /// Sorting for all other configurations.
    /// </summary>
    private void SortOthers(Dictionary<string, List<string>> unsorted, Dictionary<string, string> sorted)
    {
      if (!unsorted.ContainsKey("Debug|x32"))
        return;

      // related defines
      List<string> debugX86 = unsorted["Debug|x32"];
      List<string> releaseX86 = unsorted["Release|x32"];

      List<string> debugX64 = VS2Premake.TryGetValue(unsorted, "Debug|x64");
      List<string> releaseX64 = VS2Premake.TryGetValue(unsorted, "Release|x64");

      List<string> debugXbox = VS2Premake.TryGetValue(unsorted, "Debug|Xbox360");
      List<string> releaseXbox = VS2Premake.TryGetValue(unsorted, "Release|Xbox360");

      List<string> staticLibDebug = VS2Premake.TryGetValue(unsorted, "StaticLib Debug|x32");
      List<string> staticLibMTDebug = VS2Premake.TryGetValue(unsorted, "StaticLib MT Debug|x32");

#if DEBUG
      Console.WriteLine("Running in Debug. Dummy Definitions are added!");
      debugX86.Add("debug x86_Only");
      debugX64.Add("debug x64 Only");
      releaseX64.Add("release x64");
      releaseX86.Add("release x86");
      staticLibDebug.Add("staticlib");
      staticLibMTDebug.Add("staticlibmt");
      debugXbox.Add("debug xbox");
      releaseXbox.Add("release xbox");
      debugX86.Add("both x86");
      releaseX86.Add("both x86");
      debugX64.Add("both x64");
      releaseX64.Add("both x64");
      debugXbox.Add("both xbox");
      releaseXbox.Add("both xbox");

      debugX86.Add("sharedlib");
      releaseX86.Add("sharedlib");
      debugX64.Add("sharedlib");
      releaseX64.Add("sharedlib");
#endif

      // sort      
      List<string> definesDebugX86 = Subtract(debugX86, debugX64, releaseX86);
      List<string> definesReleaseX86 = Subtract(releaseX86, releaseX64, debugX86);

      List<string> definesDebugX64 = Subtract(debugX64, debugX86, releaseX64);
      List<string> definesReleaseX64 = Subtract(releaseX64, releaseX86, debugX64);

      List<string> sharedLib = Subtract(VS2Premake.ReturnEqual(debugX86, releaseX64), staticLibDebug);
      List<string> staticLib = Subtract(staticLibDebug, debugX86);
      List<string> staticLibMT = Subtract(staticLibMTDebug, staticLibDebug);

      List<string> definesX86 = Subtract(VS2Premake.ReturnEqual(debugX86, releaseX86), sharedLib);
      List<string> definesX64 = Subtract(debugX64, definesDebugX64, debugX86);


      List<string> definesDebugCommon = Subtract(debugX86, releaseX86, definesDebugX86);
      List<string> definesReleaseCommon = Subtract(releaseX86, debugX86, definesReleaseX86);

      List<string> definesDebugXbox360 = Subtract(debugXbox, releaseXbox, staticLibDebug);
      List<string> definesReleaseXbox360 = Subtract(releaseXbox, debugXbox, staticLibDebug);
      List<string> definesXbox360 = Subtract(debugXbox, definesDebugXbox360, staticLibDebug);


      // add to sorted collection
      sorted.Add("definesX86 ", Format(definesX86));
      sorted.Add("definesSharedLib", Format(sharedLib));
      sorted.Add("definesStaticLib ", Format(staticLib));
      sorted.Add("definesStaticLibMT", Format(staticLibMT));
      sorted.Add("definesRelease ", Format(definesReleaseCommon));
      sorted.Add("definesDebug ", Format(definesDebugCommon));
      
      sorted.Add("definesReleaseX86 ", Format(definesReleaseX86));
      sorted.Add("definesDebugX86 ", Format(definesDebugX86));

      sorted.Add("definesReleaseX64 ", Format(definesReleaseX64));
      sorted.Add("definesDebugX64 ", Format(definesDebugX64));
      sorted.Add("definesX64 ", Format(definesX64));

      sorted.Add("definesXbox360 ", Format(definesXbox360));
      sorted.Add("definesDebugXbox360 ", Format(definesDebugXbox360));
      sorted.Add("definesReleaseXbox360 ", Format(definesReleaseXbox360));
    }

    /// <summary>
    /// Sorting for PSP2 and PS3.
    /// </summary>
    private void SortPS3_PSP2(Dictionary<string, List<string>> unsorted, Dictionary<string, string> sorted)
    {
      // get related
      List<string> debugLib = VS2Premake.TryGetValue(unsorted, "StaticLib Debug|x32");
      List<string> releaseLib = VS2Premake.TryGetValue(unsorted, "StaticLib Release|x32");

      // ps3 specific
      if (VS2Premake.TryFindKeyPart(unsorted, "PS3"))
      {

        List<string> debugPS3 = unsorted["Debug PS3|x32"];
        List<string> releasePS3 = unsorted["Release PS3|x32"];

#if DEBUG
        debugPS3.Add("debug ps3");
        releasePS3.Add("release ps3");
        debugPS3.Add("all ps3");
        releasePS3.Add("all ps3");
#endif

        List<string> definesDebugPS3 = Subtract(debugPS3, releasePS3, debugLib);
        List<string> definesReleasePS3 = Subtract(releasePS3, debugPS3, releaseLib);
        List<string> definesPS3 = Subtract(releasePS3, definesReleasePS3, releaseLib);

        sorted.Add("definesPS3 ", Format(definesPS3));
        sorted.Add("definesDebugPS3 ", Format(definesDebugPS3));
        sorted.Add("definesReleasePS3 ", Format(definesReleasePS3));
      }

      // psp2 specific
      if (VS2Premake.TryFindKeyPart(unsorted, "PSP2"))
      {
        // related defines
        List<string> debugPSP2 = unsorted["Debug PSP2|x32"];
        List<string> releasePSP2 = unsorted["Release PSP2|x32"];

#if DEBUG
        debugPSP2.Add("debug psp2");
        releasePSP2.Add("release psp2");
        debugPSP2.Add("all psp2");
        releasePSP2.Add("all psp2");
#endif

        // sort
        List<string> definesDebugPSP2 = Subtract(debugPSP2, releasePSP2, debugLib);
        List<string> definesReleasePSP2 = Subtract(releasePSP2, debugPSP2, releaseLib);
        List<string> definesPSP2 = Subtract(debugPSP2, definesDebugPSP2, debugLib);

        // add to sorted collection
        sorted.Add("definesPSP2 ", Format(definesPSP2));
        sorted.Add("definesReleasePSP2 ", Format(definesReleasePSP2));
        sorted.Add("definesDebugPSP2 ", Format(definesDebugPSP2));
      }
    }


    /// <summary>
    /// Extract pre-processor definitions for the specified configuration-node.
    /// </summary>
    /// <param name="configuration">the configuration node.</param>
    /// <returns>returns a list of all pre-processor definitions assigned to the configuration.</returns>
    protected override List<string> Extract(XmlNode configuration)
    {
      foreach (XmlNode tool in configuration.ChildNodes)
      {
        if (tool.Attributes["Name"].Value == "VCCLCompilerTool" || tool.Attributes["Name"].Value == "VCCLX360CompilerTool")
        {
          XmlAttribute defines = tool.Attributes["PreprocessorDefinitions"];
          if (defines != null)
          {
            return VS2Premake.SplitString(defines.Value);
          }
        }
      }
      return new List<string>();
    }

  }
}
