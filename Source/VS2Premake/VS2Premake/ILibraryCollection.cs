using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;

namespace VS2Premake
{
  public abstract class ILibraryCollection
  {

    /// <summary>
    /// Define the script-lines that this class should process (only the first word or the common prefix should be used.
    /// </summary>
    public abstract string[] processLines
    {
      get;
    }

    /// <summary>
    /// The EntryPoint. Manages the full process from extraction to writing to the script.
    /// </summary>
    /// <param name="e">Holds data about the script line and the Xml project-file.</param>
    public abstract void Process(LineReadEventArgs e);

    /// <summary>
    /// Tests the input line and verify if its a valid line that should be processed by the object.
    /// </summary>
    /// <param name="line"></param>
    /// <returns></returns>
    protected bool IsValidLine(string line)
    {
      for (int i = 0; i < processLines.Length; i++)
      {
        if (line.StartsWith(processLines[i]))
        {
          Console.WriteLine("> Processing:  {0}", VS2Premake.GetFirstWord(line));
          //Reset();
          return true;        
        }
      }

      // this process should not be executed for this line!
      return false;
    }

    /// <summary>
    /// Finds all Xml data required.
    /// </summary>
    protected virtual Dictionary<string, List<string>> Find(XmlNode configurations)
    {

      var unsorted = new Dictionary<string, List<string>>();

      foreach (XmlNode config in configurations)
      {
        string configName = config.Attributes["Name"].Value;
        configName = VS2Premake.ConvertToPremakeCompatibleConfig(configName);

        if (VS2Premake.ValidConfigurations.Contains(configName))
        {
          unsorted.Add(configName, Extract(config));
        }
      }
      return unsorted;
    }

    /// <summary>
    /// Undefined sorting-function.
    /// </summary>
    protected abstract Dictionary<string, string> Sort(Dictionary<string, List<string>> unsorted);

    /// <summary>
    /// Write all processed data into the script file.
    /// </summary>
    /// <param name="script"></param>
    /// <param name="sorted"></param>
    protected virtual void Write(ref string script, Dictionary<string, string> sorted)
    {
      foreach (string category in sorted.Keys)
      {
        VS2Premake.WriteVariableToLine(ref script, category, sorted[category]);
      }
    }

    /// <summary>
    /// Undefined function, each derived class should provide its own implementation.
    /// </summary>
    /// <param name="configuration"></param>
    /// <returns></returns>
    protected abstract List<string> Extract(XmlNode configuration);


    // -- Helper Functions -- //

    /// <summary>
    /// Wrapper to format the definitions into a script-compatible layout.
    /// </summary>
    protected virtual string Format(List<string> list)
    {
      string output = VS2Premake.AddCurlyBraces(VS2Premake.FormatListToString(list));
      return VS2Premake.AddBuildSystemSuffix(output);
    }

    /// <summary>
    /// Case-Insensitive wrapper around VS2Premake.ReturnEqual(). Provides warning-layer.
    /// </summary>
    /// <param name="list"></param>
    /// <param name="compare"></param>
    /// <returns></returns>
    protected virtual List<string> ReturnEqual(List<string> list, List<string> compare)
    {
      if (compare.Count == 0)
      {
        Console.WriteLine("    <!> Warning - Pleasy verify the results: {0}", VS2Premake.GetFirstWord(VS2Premake.CurrentLine));
        return list;
      }

      return VS2Premake.ReturnEqual(list, compare, StringComparer.CurrentCultureIgnoreCase);
    }

    /// <summary>
    /// Wrapper for subtracting lists
    /// </summary>
    protected virtual List<string> Subtract(List<string> list1, List<string> substract1)
    {
      return VS2Premake.SubstractLists(list1, substract1);
    }

    /// <summary>
    /// Overloaded wrapper for subtracting lists
    /// </summary>
    protected virtual List<string> Subtract(List<string> list1, List<string> substract1, List<string> subtract2)
    {
      return VS2Premake.SubstractLists(VS2Premake.SubstractLists(list1, substract1), subtract2);
    }
  }
}
