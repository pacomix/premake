using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;

namespace VS2Premake
{
  public class libLinks : ILibraryCollection
  {

    public override string[] processLines
    {
      get
      {
        return new string[] { "libLink" };
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
    /// Sort based on variables defined in the script.
    /// </summary>
    /// <param name="unsorted">the unsorted input.</param>
    /// <returns>a sorted collection of libraries.</returns>
    protected override Dictionary<string, string> Sort(Dictionary<string, List<string>> unsorted)
    {
      var sorted = new Dictionary<string, string>();
      
      #region Get All Variable Tables

      List<string> releaseX86 = VS2Premake.TryGetValue(unsorted, "Release|x32");
      List<string> releaseStaticX86 = VS2Premake.TryGetValue(unsorted, "StaticLib Release|x32");
      List<string> releaseX86DX11 = VS2Premake.TryGetValue(unsorted, "Release DX11|x32");
      List<string> releaseX86NoXI = VS2Premake.TryGetValue(unsorted, "Release NoXI|x32");

      List<string> debugX86 = VS2Premake.TryGetValue(unsorted, "Debug|x32");
      List<string> debugStaticX86 = VS2Premake.TryGetValue(unsorted, "StaticLib Debug|x32");
      List<string> debugX86DX11 = VS2Premake.TryGetValue(unsorted, "Debug DX11|x32");
      List<string> debugX86NoXI = VS2Premake.TryGetValue(unsorted, "Debug NoXI|x32");

      List<string> debugX64 = VS2Premake.TryGetValue(unsorted, "Debug|x64");
      List<string> debugStaticX64 = VS2Premake.TryGetValue(unsorted, "StaticLib Debug|x64");
      List<string> debugX64DX11 = VS2Premake.TryGetValue(unsorted, "Debug DX11|x64");
      List<string> debugX64NoXI = VS2Premake.TryGetValue(unsorted, "Debug NoXI|x64");

      List<string> releaseX64 = VS2Premake.TryGetValue(unsorted, "Release|x64");
      List<string> releaseStaticX64 = VS2Premake.TryGetValue(unsorted, "StaticLib Release|x64");
      List<string> releaseX64DX11 = VS2Premake.TryGetValue(unsorted, "Release DX11|x64");
      List<string> releaseX64NoXI = VS2Premake.TryGetValue(unsorted, "Release NoXI|x64");

      List<string> debugXbox360 = VS2Premake.TryGetValue(unsorted, "Debug|Xbox360");
      List<string> releaseXbox360 = VS2Premake.TryGetValue(unsorted, "Release|Xbox360");

      List<string> debugPS3 = VS2Premake.TryGetValue(unsorted, "Debug PS3|x32");
      List<string> releasePS3 = VS2Premake.TryGetValue(unsorted, "Release PS3|x32");

      List<string> debugPSP2 = VS2Premake.TryGetValue(unsorted, "Debug PSP2|x32");
      List<string> releasePSP2 = VS2Premake.TryGetValue(unsorted, "Release PSP2|x32");

      #endregion

#if DEBUG
      //#region Debug-only Dummy Values
      //debugStaticX86.Add("allx86");
      //debugX86DX11.Add("allx86");
      //debugX86NoXI.Add("allx86");
      //debugX86.Add("allx86");
      //releaseX86.Add("allx86");
      //releaseStaticX86.Add("allx86");
      //releaseX86DX11.Add("allx86");
      //releaseX86NoXI.Add("allx86");

      //debugStaticX64.Add("allX64");
      //debugX64DX11.Add("allX64");
      //debugX64NoXI.Add("allX64");
      //debugX64.Add("allX64");
      //releaseX64.Add("allX64");
      //releaseStaticX64.Add("allX64");
      //releaseX64DX11.Add("allX64");
      //releaseX64NoXI.Add("allX64");

      //debugX64DX11.Add("allDX11");
      //debugX86DX11.Add("allDX11");
      //releaseX64DX11.Add("allDX11");
      //releaseX86DX11.Add("allDX11");

      //// test: libLinkShared
      //debugX86DX11.Add("lib_shared");
      //debugX86NoXI.Add("lib_shared");
      //debugX86.Add("lib_shared");
      //releaseX86.Add("lib_shared");
      //releaseX86DX11.Add("lib_shared");
      //releaseX86NoXI.Add("lib_shared");

      //debugX64DX11.Add("lib_shared");
      //debugX64NoXI.Add("lib_shared");
      //debugX64.Add("lib_shared");
      //releaseX64.Add("lib_shared");
      //releaseX64DX11.Add("lib_shared");
      //releaseX64NoXI.Add("lib_shared");

      //debugX64DX11.Add("lib_shared");
      //debugX86DX11.Add("lib_shared");
      //releaseX64DX11.Add("lib_shared");
      //releaseX86DX11.Add("lib_shared");

      //// test: libLinkAllWindows
      //debugStaticX86.Add("lib_allwin");
      //debugX86DX11.Add("lib_allwin");
      //debugX86NoXI.Add("lib_allwin");
      //debugX86.Add("lib_allwin");
      //releaseX86.Add("lib_allwin");
      //releaseStaticX86.Add("lib_allwin");
      //releaseX86DX11.Add("lib_allwin");
      //releaseX86NoXI.Add("lib_allwin");

      //debugStaticX64.Add("lib_allwin");
      //debugX64DX11.Add("lib_allwin");
      //debugX64NoXI.Add("lib_allwin");
      //debugX64.Add("lib_allwin");
      //releaseX64.Add("lib_allwin");
      //releaseStaticX64.Add("lib_allwin");
      //releaseX64DX11.Add("lib_allwin");
      //releaseX64NoXI.Add("lib_allwin");

      //debugX64DX11.Add("lib_allwin");
      //debugX86DX11.Add("lib_allwin");
      //releaseX64DX11.Add("lib_allwin");
      //releaseX86DX11.Add("lib_allwin");

      //// test: NoXI
      //releaseX64NoXI.Add("lib_NoXI");
      //debugX64NoXI.Add("lib_NoXI");
      //debugX86NoXI.Add("lib_NoXI");
      //releaseX86NoXI.Add("lib_NoXI");

      //// test: 
      //debugStaticX86.Add("lib_static");
      //releaseStaticX86.Add("lib_static");
      //debugStaticX64.Add("lib_static");
      //releaseStaticX64.Add("lib_static");

      //// non-dx11
      //debugStaticX86.Add("all_with_dx9");
      //debugX86NoXI.Add("all_with_dx9");
      //debugX86.Add("all_with_dx9");
      //releaseX86.Add("all_with_dx9");
      //releaseStaticX86.Add("all_with_dx9");
      //releaseX86NoXI.Add("all_with_dx9");

      //debugStaticX64.Add("all_with_dx9");
      //debugX64NoXI.Add("all_with_dx9");
      //debugX64.Add("all_with_dx9");
      //releaseX64.Add("all_with_dx9");
      //releaseStaticX64.Add("all_with_dx9");
      //releaseX64NoXI.Add("all_with_dx9");

      //#endregion
#endif

      // -- Additional Filters -- //
      
      #region Additional Filters (DX11/DX9)
      List<string> debugX86Dx9Only = Substract(debugX86, debugX86DX11);
      List<string> releaseX86Dx9Only = Substract(releaseX86, releaseX86DX11);

      List<string> debugX64Dx9Only = Substract(debugX64, debugX64DX11);
      List<string> releaseX64Dx9Only = Substract(releaseX64, releaseX64DX11);

      #endregion

      // -- Sort All Variables -- //

      #region libLinkAllWindows

      List<string> libLinkAllWindows = ReturnEqual(releaseX86, releaseX64);
      libLinkAllWindows = ReturnEqual(libLinkAllWindows, releaseStaticX86);
      libLinkAllWindows = ReturnEqual(libLinkAllWindows, releaseX86DX11);
      libLinkAllWindows = ReturnEqual(libLinkAllWindows, releaseX86NoXI);

      libLinkAllWindows = ReturnEqual(libLinkAllWindows, debugX86);
      sorted.Add("libLinkAllWindows", Format(libLinkAllWindows));
 
      #endregion

      #region libLinkShared

      List<string> libLinkShared = Substract(releaseX86, releaseStaticX86);
      libLinkShared = ReturnEqual(libLinkShared, debugX86);
      sorted.Add("libLinkShared", Format(libLinkShared));

      #endregion

      #region libLinkDX11

      List<string> libLinkDX11 = Substract(releaseX86DX11, releaseX86);
      libLinkDX11 = ReturnEqual(libLinkDX11, debugX86DX11);
      sorted.Add("libLinkDx11", Format(libLinkDX11));

      #endregion

      #region lbLinkDebugAllWin32

      List<string> libLinkDebugAllWin32 = ReturnEqual(debugX86, debugStaticX86);
      libLinkDebugAllWin32 = ReturnEqual(libLinkDebugAllWin32, debugX86DX11);
      libLinkDebugAllWin32 = ReturnEqual(libLinkDebugAllWin32, debugX86NoXI);

      libLinkDebugAllWin32 = Substract(libLinkDebugAllWin32, libLinkAllWindows);
      sorted.Add("libLinkDebugAllWin32", Format(libLinkDebugAllWin32));

      #endregion

      #region libLinkDebugAllX64

      List<string> libLinkDebugAllX64 = ReturnEqual(debugX64, debugStaticX64);
      libLinkDebugAllX64 = ReturnEqual(libLinkDebugAllX64, debugX64DX11);
      libLinkDebugAllX64 = ReturnEqual(libLinkDebugAllX64, debugX64NoXI);

      libLinkDebugAllX64 = Substract(libLinkDebugAllX64, libLinkAllWindows);
      sorted.Add("libLinkDebugAllx64", Format(libLinkDebugAllX64));

      #endregion

      #region libLinkReleaseAllWin32

      List<string> libLinkReleaseAllWin32 = ReturnEqual(releaseX86, releaseStaticX86);
      libLinkReleaseAllWin32 = ReturnEqual(libLinkReleaseAllWin32, releaseX86DX11);
      libLinkReleaseAllWin32 = ReturnEqual(libLinkReleaseAllWin32, releaseX86NoXI);

      libLinkReleaseAllWin32 = Substract(libLinkReleaseAllWin32, libLinkAllWindows);
      sorted.Add("libLinkReleaseAllWin32", Format(libLinkReleaseAllWin32));

      #endregion

      #region libLinkReleaseAllX64

      List<string> libLinkReleaseAllX64 = ReturnEqual(releaseX64, releaseStaticX64);
      libLinkReleaseAllX64 = ReturnEqual(libLinkReleaseAllX64, releaseX64DX11);
      libLinkReleaseAllX64 = ReturnEqual(libLinkReleaseAllX64, releaseX64NoXI);

      libLinkReleaseAllX64 = Substract(libLinkReleaseAllX64, libLinkAllWindows);
      sorted.Add("libLinkReleaseAllx64", Format(libLinkReleaseAllX64));

      #endregion

      #region libLinkDebugStaticWin32

      List<string> libLinkDebugStaticWin32 = Substract(debugStaticX86, libLinkAllWindows);
      libLinkDebugStaticWin32 = Substract(libLinkDebugStaticWin32, libLinkDebugAllWin32);

      sorted.Add("libLinkDebugStaticWin32", Format(libLinkDebugStaticWin32, "libLinkAllWindows, libLinkDebugAllWin32, "));

      #endregion

      #region libLinkDebugDx9Win32

      List<string> libLinkDebugDx9Win32 = Substract(debugX86, libLinkAllWindows);
      libLinkDebugDx9Win32 = Substract(libLinkDebugDx9Win32, libLinkDebugAllWin32);
      libLinkDebugDx9Win32 = Substract(libLinkDebugDx9Win32, libLinkShared);

      sorted.Add("libLinkDebugDx9Win32", Format(libLinkDebugDx9Win32, "libLinkAllWindows, libLinkDebugAllWin32, libLinkShared, "));

      #endregion

      #region libLinkDebugDx11Win32

      List<string> libLinkDebugDx11Win32 = Substract(debugX86DX11, libLinkAllWindows);
      libLinkDebugDx11Win32 = Substract(libLinkDebugDx11Win32, libLinkDebugAllWin32);
      libLinkDebugDx11Win32 = Substract(libLinkDebugDx11Win32, libLinkShared);
      libLinkDebugDx11Win32 = Substract(libLinkDebugDx11Win32, libLinkDX11);

      libLinkDebugDx11Win32 = Substract(libLinkDebugDx11Win32, debugX86Dx9Only);
      sorted.Add("libLinkDebugDx11Win32", Format(libLinkDebugDx11Win32, "libLinkAllWindows, libLinkDebugAllWin32, libLinkShared, libLinkDx11, "));

      #endregion

      #region libLinkDebugNoXIWin32

      List<string> libLinkDebugNoXIWin32 = Substract(debugX86NoXI, libLinkAllWindows);
      libLinkDebugNoXIWin32 = Substract(libLinkDebugNoXIWin32, libLinkDebugAllWin32);
      libLinkDebugNoXIWin32 = Substract(libLinkDebugNoXIWin32, libLinkShared);

      // remove XI-type libs
      List<string> xiOnly = Substract(debugX86, debugX86NoXI);
      libLinkDebugNoXIWin32 = Substract(libLinkDebugNoXIWin32, xiOnly);
      sorted.Add("libLinkDebugNoXIWin32", Format(libLinkDebugNoXIWin32, "libLinkAllWindows, libLinkDebugAllWin32, libLinkShared, "));

      #endregion

      #region libLinkReleaseStaticWin32

      List<string> libLinkReleaseStaticWin32 = Substract(releaseStaticX86, libLinkAllWindows);
      libLinkReleaseStaticWin32 = Substract(libLinkReleaseStaticWin32, libLinkReleaseAllWin32);

      sorted.Add("libLinkReleaseStaticWin32", Format(libLinkReleaseStaticWin32, "libLinkAllWindows, libLinkReleaseAllWin32, "));

      #endregion

      #region libLinkReleaseDx9Win32

      List<string> libLinkReleaseDx9Win32 = Substract(releaseX86, libLinkAllWindows);
      libLinkReleaseDx9Win32 = Substract(libLinkReleaseDx9Win32, libLinkReleaseAllWin32);
      libLinkReleaseDx9Win32 = Substract(libLinkReleaseDx9Win32, libLinkShared);

      sorted.Add("libLinkReleaseDx9Win32", Format(libLinkReleaseDx9Win32, "libLinkAllWindows, libLinkReleaseAllWin32, libLinkShared, "));

      #endregion

      #region libLinkReleaseDx11Win32

      List<string> libLinkReleaseDx11Win32 = Substract(releaseX86DX11, libLinkAllWindows);
      libLinkReleaseDx11Win32 = Substract(libLinkReleaseDx11Win32, libLinkReleaseAllWin32);
      libLinkReleaseDx11Win32 = Substract(libLinkReleaseDx11Win32, libLinkShared);
      libLinkReleaseDx11Win32 = Substract(libLinkReleaseDx11Win32, libLinkDX11);

      libLinkReleaseDx11Win32 = Substract(libLinkReleaseDx11Win32, releaseX86Dx9Only);
      sorted.Add("libLinkReleaseDx11Win32", Format(libLinkReleaseDx11Win32, "libLinkAllWindows, libLinkReleaseAllWin32, libLinkShared, libLinkDx11, "));

      #endregion

      #region libLinkReleaseNoXIWin32

      List<string> libLinkReleaseNoXIWin32 = Substract(releaseX86NoXI, libLinkAllWindows);
      libLinkReleaseNoXIWin32 = Substract(libLinkReleaseNoXIWin32, libLinkReleaseAllWin32);
      libLinkReleaseNoXIWin32 = Substract(libLinkReleaseNoXIWin32, libLinkShared);

      // remove XI-type libs
      List<string> releaseXiOnly = Substract(releaseX86, releaseX86NoXI);
      libLinkReleaseNoXIWin32 = Substract(libLinkReleaseNoXIWin32, releaseXiOnly);
      sorted.Add("libLinkReleaseNoXIWin32", Format(libLinkReleaseNoXIWin32, "libLinkAllWindows, libLinkReleaseAllWin32, libLinkShared, "));

      #endregion

      #region libLinkDebugStaticX64

      List<string> libLinkDebugStaticX64 = Substract(debugStaticX64, libLinkAllWindows);
      libLinkDebugStaticX64 = Substract(libLinkDebugStaticX64, libLinkDebugAllX64);

      sorted.Add("libLinkDebugStaticX64", Format(libLinkDebugStaticX64, "libLinkAllWindows, libLinkDebugAllx64, "));

      #endregion

      #region libLinkDebugDx9X64

      List<string> libLinkDebugDx9X64 = Substract(debugX64, libLinkAllWindows);
      libLinkDebugDx9X64 = Substract(libLinkDebugDx9X64, libLinkDebugAllX64);
      libLinkDebugDx9X64 = Substract(libLinkDebugDx9X64, libLinkShared);

      sorted.Add("libLinkDebugDx9x64", Format(libLinkDebugDx9X64, "libLinkAllWindows, libLinkDebugAllx64, libLinkShared, "));

      #endregion

      #region libLinkDebugDx11X64

      List<string> libLinkDebugDx11X64 = Substract(debugX64DX11, libLinkAllWindows);
      libLinkDebugDx11X64 = Substract(libLinkDebugDx11X64, libLinkDebugAllX64);
      libLinkDebugDx11X64 = Substract(libLinkDebugDx11X64, libLinkShared);
      libLinkDebugDx11X64 = Substract(libLinkDebugDx11X64, libLinkDX11);

      libLinkDebugDx11X64 = Substract(libLinkDebugDx11X64, debugX64Dx9Only);
      sorted.Add("libLinkDebugDx11x64", Format(libLinkDebugDx11X64, "libLinkAllWindows, libLinkDebugAllx64, libLinkShared, libLinkDx11, "));

      #endregion

      #region libLinkDebugNoXIX64

      List<string> libLinkDebugNoXIX64 = Substract(debugX64NoXI, libLinkAllWindows);
      libLinkDebugNoXIX64 = Substract(libLinkDebugNoXIX64, libLinkDebugAllX64);
      libLinkDebugNoXIX64 = Substract(libLinkDebugNoXIX64, libLinkShared);

      // remove XI-type libs
      //List<string> xiOnly = Substract(debugX64, debugX64NoXI);
      libLinkDebugNoXIX64 = Substract(libLinkDebugNoXIX64, xiOnly);
      sorted.Add("libLinkDebugNoXIx64", Format(libLinkDebugNoXIX64, "libLinkAllWindows, libLinkDebugAllx64, libLinkShared, "));

      #endregion

      #region libLinkReleaseStaticX64

      List<string> libLinkReleaseStaticX64 = Substract(releaseStaticX64, libLinkAllWindows);
      libLinkReleaseStaticX64 = Substract(libLinkReleaseStaticX64, libLinkReleaseAllX64);

      sorted.Add("libLinkReleaseStaticX64", Format(libLinkReleaseStaticX64, "libLinkAllWindows, libLinkReleaseAllx64, "));

      #endregion

      #region libLinkReleaseDx9X64

      List<string> libLinkReleaseDx9X64 = Substract(releaseX64, libLinkAllWindows);
      libLinkReleaseDx9X64 = Substract(libLinkReleaseDx9X64, libLinkReleaseAllX64);
      libLinkReleaseDx9X64 = Substract(libLinkReleaseDx9X64, libLinkShared);

      sorted.Add("libLinkReleaseDx9x64", Format(libLinkReleaseDx9X64, "libLinkAllWindows, libLinkReleaseAllx64, libLinkShared, "));

      #endregion

      #region libLinkReleaseDx11X64

      List<string> libLinkReleaseDx11X64 = Substract(releaseX64DX11, libLinkAllWindows);
      libLinkReleaseDx11X64 = Substract(libLinkReleaseDx11X64, libLinkReleaseAllX64);
      libLinkReleaseDx11X64 = Substract(libLinkReleaseDx11X64, libLinkShared);
      libLinkReleaseDx11X64 = Substract(libLinkReleaseDx11X64, libLinkDX11);

      // remove dx9 libs
      //List<string> releaseDx9Only = Substract(releaseX64, releaseDx11X64);
      libLinkReleaseDx11X64 = Substract(libLinkReleaseDx11X64, releaseX64Dx9Only);
      sorted.Add("libLinkReleaseDx11x64", Format(libLinkReleaseDx11X64, "libLinkAllWindows, libLinkReleaseAllx64, libLinkShared, libLinkDx11, "));

      #endregion

      #region libLinkReleaseNoXIX64

      List<string> libLinkReleaseNoXIX64 = Substract(releaseX64NoXI, libLinkAllWindows);
      libLinkReleaseNoXIX64 = Substract(libLinkReleaseNoXIX64, libLinkReleaseAllX64);
      libLinkReleaseNoXIX64 = Substract(libLinkReleaseNoXIX64, libLinkShared);

      // remove XI-type libs
      //List<string> releaseXiOnly = Substract(releaseX64, releaseX64NoXI);
      libLinkReleaseNoXIX64 = Substract(libLinkReleaseNoXIX64, releaseXiOnly);
      sorted.Add("libLinkReleaseNoXIx64", Format(libLinkReleaseNoXIX64, "libLinkAllWindows, libLinkReleaseAllx64, libLinkShared, "));

      #endregion

      #region libLinkDebugXbox360

      //List<string> libLinkDebugXbox360 = Substract(debugXbox360, releaseXbox360);
      sorted.Add("libLinkDebugXbox360", Format(debugXbox360));

      #endregion

      #region libLinkReleaseXbox360

      //List<string> libLinkReleaseXbox360 = Substract(releaseXbox360, debugXbox360);
      sorted.Add("libLinkReleaseXbox360", Format(releaseXbox360));

      #endregion

      #region libLinkDebugPS3

      //List<string> libLinkDebugPS3 = Substract(debugPS3, releasePS3);
      sorted.Add("libLinkDebugPS3", Format(debugPS3));

      #endregion

      #region libLinkReleasePS3

      //List<string> libLinkReleasePS3 = Substract(releasePS3, debugPS3);
      sorted.Add("libLinkReleasePS3", Format(releasePS3));

      #endregion

      #region libLinkDebugPSP2

      //List<string> libLinkDebugPSP2 = Substract(debugPSP2, releasePSP2);
      sorted.Add("libLinkDebugPSP2", Format(debugPSP2));

      #endregion

      #region libLinkReleasePSP2

      //List<string> libLinkReleasePSP2 = Substract(releasePSP2, debugPSP2);
      sorted.Add("libLinkReleasePSP2", Format(releasePSP2));

      #endregion

      return sorted;
    }

    /// <summary>
    /// Formats the list intro a single long string and adds curly braces. example: { prefix + longstring }
    /// </summary>
    public string Format(List<string> list, string prefix)
    {
      string output = VS2Premake.AddCurlyBraces(prefix + VS2Premake.FormatListToString(list));
      output = VS2Premake.AddBuildSystemSuffix(output);
      return output;
    }

    /// <summary>
    /// Case-insensitive SubstractList-wrapper.
    /// </summary>
    /// <param name="original"></param>
    /// <param name="substract"></param>
    /// <returns></returns>
    public List<string> Substract(List<string> original, List<string> substract)
    {
      return VS2Premake.SubstractLists(original, substract, StringComparer.CurrentCultureIgnoreCase);
    }

    /// <summary>
    /// Extract LibraryLinks for a single configuration from a Visual Studio 9 project file.
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
            XmlAttribute libs = tool.Attributes["AdditionalDependencies"];
            if (libs != null)
            {
              return VS2Premake.SplitString(libs.Value, ' ');
            }
          }
        }
      }
      return null;
    }
  }
}
