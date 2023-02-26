using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Xml;

namespace VS2Premake
{
  public class VS2Premake
  {
    #region Fields

    #region Valid Configurations
    // -- Contains Valid Configurations -- //
    public readonly static List<string> ValidConfigurations = new List<string>
                                                                { "Debug|x32", "Release|x32", "Debug|x64", "Release|x64", "Debug DX11|x32", "Release DX11|x32", "Debug DX11|x64", "Release DX11|x64",
                                                                             "Debug|Xbox360", "Release|Xbox360", "Debug NoXI|x32", "Release NoXI|x32", "Debug NoXI|x64", "Release NoXI|x64",
                                                                             "Debug PS3|x32", "Release PS3|x32", "Debug PSP2|x32", "Release PSP2|x32", "StaticLib Debug|x32", "StaticLib Release|x32",
                                                                             "StaticLib Debug|x64", "StaticLib Release|x64", "StaticLib MT Debug|x32", "StaticLib MT Release|x32", "StaticLib MT Debug|x64",
                                                                             "StaticLib MT Release|x64", "Debug Wii|x32", "Release Wii|x32" };
    #endregion

    private static string _originalWorkingDirectory;
    private const string defaultTemplateFileDirectory = "templates/Prj-NameOfTheProject.lua";

    public static string CurrentLine = String.Empty;

    #endregion

    static void Main(string[] args)
    {
      string fileDirectory = string.Empty;
      fileDirectory = GetUserDefinedDirectory(args);

      FileStream projectFileStream = File.OpenRead(fileDirectory);
      SetWorkingDir(fileDirectory); 

      XmlDocument projectXmlFile = new XmlDocument();
      projectXmlFile.Load(projectFileStream);

      // -- Define Supported Variables -- //
      ReadScriptLine += ProjectBaseName;
      ReadScriptLine += ProjectGUID;
      ReadScriptLine += ProjectBuildConfigs;

      ReadScriptLine += new SourceFiles().Process;
      ReadScriptLine += new PreProcessorDefinitions().Process;
      ReadScriptLine += new IncludeDirs().Process;
      ReadScriptLine += new LibDirs().Process;
      ReadScriptLine += new libLinks().Process;

      // -- Generate Script -- //
      ProcessScriptLines(projectXmlFile, args);

      Exit(); 
    }

    /// <summary>
    /// Manages the retrieval of a valid project directory from arguments or user input.
    /// </summary>
    /// <param name="args"></param>
    /// <returns></returns>
    private static string GetUserDefinedDirectory(string[] args)
    {
      // -- Show Help to User -- //
      if (args == null || args.Length == 0)
      {
        Console.WriteLine("> Arguments:");
        Console.WriteLine(">    --file= to specify the project to convert.");
        Console.WriteLine(">    --output= to specify the outputname for lua script.");
        Console.WriteLine("> example: vs2premake --file=c:\\trunk\\vbase\\vbase90.vcproj --output=../relativefolder/prj-vbase.lua");
#if DEBUG
        Console.ReadLine();
#endif
        Exit();
      }
#if DEBUG
        Console.WriteLine("    -- RUNNING IN DEBUG. --");
#else
        Console.WriteLine("    -- RUNNING IN RELEASE. --");
#endif      
      try
      {
        if (args[0].StartsWith("--file="))
        {
          args[0] = args[0].Remove(0, 7);
        }
      }
      catch (IndexOutOfRangeException)
      {
        Console.WriteLine("<!> Error: Invalid Argument specified: {0}", args[0]);
        Exit();
      }

      string path = args[0].Trim('"');
      string directory = string.Empty;
      try
      {
        directory = Path.GetFullPath(path);
      }
      catch (ArgumentException)
      {
        Console.WriteLine("   Invalid file specified for --file=");
        Exit();
      }
      if (File.Exists(directory))
      {
        return directory;
      }
      else
      {
        Console.WriteLine("<!> Error: Invalid Path specified: {0}", path);
        Exit();
      }     
      return null;
    }

    /// <summary>
    /// Processes all script lines and generates the final script file.
    /// </summary>
    /// <param name="projectXmlFile"></param>
    private static void ProcessScriptLines(XmlDocument projectXmlFile, string[] args)
    {
      XmlNode projectInfo = projectXmlFile.ChildNodes[1];
      string projectName = projectInfo.Attributes["Name"].Value.Replace("90", "");

      string scriptFilename = null;
      if (args.Length > 1)
      {
        if (args[1].StartsWith("--output="))
        {
          try
          {
            scriptFilename = args[1].Remove(0, 9);
          }
          catch (IndexOutOfRangeException)
          {
            Console.WriteLine("Unsupported option was specified: {0}", args[1]);
            Exit();
          }
        }
      }
      else
      {
        scriptFilename = String.Format("Prj-{0}.lua", projectName);
      }

      if (String.IsNullOrEmpty(scriptFilename))
      {
        Console.WriteLine("Unsupported option was specified: {0}", args[1]);
        Exit();
      }

      // -- Test File Existance -- Prompt User to Overwrite of Create Copy -- //
      string scriptFileDirectory = Path.Combine(_originalWorkingDirectory, scriptFilename);
      if (File.Exists(scriptFileDirectory))
      {
        Console.WriteLine("Script file exists, Overwrite? Y/N (N: creates new file with prefix 'Copy-'");
        bool overwriteFile = RequestUserAnswerYesNo();
        if (!overwriteFile)
        {
          scriptFileDirectory = Path.Combine(_originalWorkingDirectory, "Copy-" + scriptFilename);
        }
      }

      string premakeDir = System.Reflection.Assembly.GetExecutingAssembly().Location;
      premakeDir = Path.GetDirectoryName(premakeDir);

#if DEBUG
      // debug .exe is inside ./debug we have to escape the folder.
      string fullpath = premakeDir + "//..//" + defaultTemplateFileDirectory;
#else
      string fullpath = Path.Combine(premakeDir, defaultTemplateFileDirectory);
#endif

      TextReader scriptReader = null;
      try
      {
        scriptReader = new StreamReader(fullpath);
      }
      catch (DirectoryNotFoundException)
      {
        Console.WriteLine("<!> Can't find Template file...");
        Console.WriteLine("<!> Incorrect Template Directory: " + fullpath);
        Exit();
      }
      
      StringBuilder scriptBuilder = new StringBuilder();
      CurrentLine = scriptReader.ReadLine();
      while (CurrentLine != null)
      {
        if (CurrentLine.Length > 0 && !CurrentLine.StartsWith("--"))
        {
          string unprocessed = CurrentLine;

          // compare line to 'known'-variables.
          CurrentLine = OnReadLine(new LineReadEventArgs(CurrentLine, projectInfo));

          if (CurrentLine != unprocessed)
            Console.WriteLine(">   Done.");
        }
        scriptBuilder.AppendLine(CurrentLine);

        // read next line
        CurrentLine = scriptReader.ReadLine();
      }

      // -- Write to Lua file -- //
      TextWriter scriptWriter = null;
      try
      {
        scriptWriter = new StreamWriter(scriptFileDirectory);
      }
      catch (UnauthorizedAccessException)
      {
        Console.WriteLine("No access to folder! Please verify that the following directory is correct: {0}", scriptFileDirectory);
        Exit();
      }
      scriptWriter.Write(scriptBuilder.ToString());

      scriptReader.Close();
      scriptWriter.Close();

      Console.WriteLine("Script: \"{0}\" was Generated Successfully!", scriptFileDirectory);
#if DEBUG
      Console.WriteLine("    <!> VS2Premake ran in DEBUG. dummy-values were added.");
#endif
    }


    #region Basic Project-info converters
    /// <summary>
    /// Adds base name of the project to the script.
    /// </summary>
    /// <param name="e"></param>
    private static void ProjectBaseName(LineReadEventArgs e)
    {
      string value = e.Project.Attributes["Name"].Value.Replace("90", "");
      WriteVariableToLine(ref e.Line, "projectBaseName", AddQuotations(value));
    }

    /// <summary>
    /// Adds project GUID to the script.
    /// </summary>
    /// <param name="e"></param>
    private static void ProjectGUID(LineReadEventArgs e)
    {
      string value = e.Project.Attributes["ProjectGUID"].Value.Trim(new char[] { '{', '}' });
      WriteVariableToLine(ref e.Line, "projectGUID", AddQuotations(value));
    }

    /// <summary>
    /// Adds all project configurations to the script.
    /// </summary>
    /// <param name="e"></param>
    private static void ProjectBuildConfigs(LineReadEventArgs e)
    {
      List<string> projectConfigs = new List<string>();

      XmlNode c = GetNode("Configurations", e.Project);
      foreach (XmlNode config in c.ChildNodes)
      {
        string configName = config.Attributes["Name"].Value;
        configName = ConvertToPremakeCompatibleConfig(configName);

        if (ValidConfigurations.Contains(configName))
        {
          projectConfigs.Add(configName);
        }
      }

      string value = FormatListToString(projectConfigs);
      WriteVariableToLine(ref e.Line, "projectBuildConfigs", AddCurlyBraces(value));
    } 
    #endregion

    #region Private Helper Functions
    /// <summary>
    /// Requests an response from the user. either Y or N.  
    /// </summary>
    /// <returns></returns>
    private static bool RequestUserAnswerYesNo()
    {
      // true equals Yes, false equals No
      while (true)
      {
        Console.Write(">   Response: ");
        string answer = Console.ReadLine();
        if (answer == "n" || answer == "N")
        {
          return false;
        }
        else if (answer == "y" || answer == "Y")
        {
          return true;
        }
      }
    }

    /// <summary>
    /// Sets the working directory to a new valid path.
    /// </summary>
    /// <param name="arg"></param>
    private static void SetWorkingDir(string arg)
    {
      _originalWorkingDirectory = Environment.CurrentDirectory;
      string addDirectory = Path.GetDirectoryName(arg);
      Environment.CurrentDirectory = Path.GetFullPath(addDirectory);
    }

    /// <summary>
    /// Must be called when terminating the application. Restores the Working Directory
    /// </summary>
    private static void Exit()
    {
      if (!String.IsNullOrEmpty(_originalWorkingDirectory))
        Environment.CurrentDirectory = _originalWorkingDirectory;

#if DEBUG
      Console.WriteLine("Press Enter to Exit...");
      Console.ReadLine();
#endif
      Environment.Exit(0);
    }

    /// <summary>
    /// Adds quotationmarks to the start and and of the input string.
    /// </summary>
    /// <param name="input">input string</param>
    /// <returns>output string</returns>
    private static string AddQuotations(string input)
    {
      return String.Format("\"{0}\"", input);
    }

    /// <summary>
    /// Formats a single 'raw'-string into a value usable by string-tables.
    /// </summary>
    /// <param name="input"></param>
    /// <returns></returns>
    private static string FormatSingleProperty(string input)
    {
      input = input.Replace("\\", "/");
      input = input.Replace("\"", "");

      if (input.Contains('$'))
      {
        input = String.Format(@"\""{0}\""", input);
      }
      return input;
    }

    #endregion

    #region Public Helper Functions
    /// <summary>
    /// Returns the first word in a string.
    /// </summary>
    /// <param name="input">the line of text.</param>
    /// <returns>The first word of the input string</returns>
    public static string GetFirstWord(string input)
    {
      for (int i = 0; i < input.Length; i++)
      {
        if (input[i] == ' ')
          return input.Substring(0, i);
      }
      return String.Empty;
    }

    /// <summary>
    /// Adds curly braces to the start and end of the input string.
    /// </summary>
    /// <param name="input">input string</param>
    /// <returns>output string</returns>
    public static string AddCurlyBraces(string input)
    {
      return String.Format("{{ {0} }}", input);
    }

    /// <summary>
    /// Replaces all occurances of '90' and '100' inside a string with a premake variable to identify the buildsystem version.
    /// </summary>
    /// <param name="input"></param>
    /// <returns></returns>
    public static string AddBuildSystemSuffix(string input)
    {
      input = input.Replace("100", "\" .. buildSystemSuffix .. \"");
      input = input.Replace("90", "\" .. buildSystemSuffix .. \"");
      return input;
    }

    /// <summary>
    /// Gets the XmlNode by name.
    /// </summary>
    /// <param name="nodeName">Name of the child node.</param>
    /// <param name="parent">The parent node.</param>
    /// <returns></returns>
    public static XmlNode GetNode(string nodeName, XmlNode parent)
    {
      foreach (XmlNode node in parent)
      {
        if (node.LocalName == nodeName)
          return node;

        XmlNode child = GetNode(nodeName, node);
        if (child != null)
          return child;
      }

      return null;
    }

    /// <summary>
    /// Writes the filled in variable back into the script.
    /// </summary>
    /// <param name="script"></param>
    /// <param name="varName"></param>
    /// <param name="varValue"></param>
    public static void WriteVariableToLine(ref string script, string varName, string varValue)
    {
      if (script.StartsWith(varName))
      {
        // clear the string if it only contains quotations (this will be an 'empty-table' in lua)
        if (varValue == "{ \"\" }")
        {
          varValue = "{ }";
        }
        script = script.Replace("\"\"", varValue);
      }
    }

    /// <summary>
    /// Formats a List to a single string containing all entries from the List.
    /// </summary>
    /// <param name="list"></param>
    /// <returns></returns>
    public static string FormatListToString(List<string> list)
    {
      string text = "";
      for (int i = 0; i < list.Count; i++)
      {
        if (String.IsNullOrEmpty(list[i]))
          continue;

        text += FormatSingleProperty(list[i]);

        if (i < list.Count - 1)
          text += ";";
      }

      return FormatToLongString(text);
    }

    /// <summary>
    /// Formats a string containing multiple properties into a format compatible with Premake (lua)
    /// </summary>
    /// <param name="properties">the input string</param>
    /// <returns>the re-formatted string of properties</returns>
    public static string FormatToLongString(string properties)
    {
      properties = properties.Trim();
      StringBuilder builder = new StringBuilder(properties);

      // replace "\" with "/" and replace ";" with ", "
      //builder.Replace("\"", "");

      builder.Replace(";", "\", \"");

      // add quotation marks to start + end of string
      string result = String.Format("\"{0}\"", builder.ToString());

      return result;
    }

    /// <summary>
    /// Splits a string using the default seperator ';'
    /// </summary>
    public static List<string> SplitString(string text)
    {
      return SplitString(text, ';');
    }

    /// <summary>
    /// Splits a string using a custom separator
    /// </summary>
    public static List<string> SplitString(string text, char splitter)
    {
      return text.Split(splitter).ToList();
    }

    /// <summary>
    /// Converts the input string (containing a configuration name) to one that is compatible with Premake.
    /// </summary>
    /// <param name="input"></param>
    /// <returns></returns>
    public static string ConvertToPremakeCompatibleConfig(string input)
    {
      input = input.Replace("Win32", "x32");
      input = input.Replace("Xbox 360", "Xbox360");

      return input;
    }

    /// <summary>
    /// Subtracts one list from another.
    /// </summary>
    public static void SubstractLists(List<string> original, List<string> substract, out List<string> remainder)
    {
      remainder = new List<string>(original);
      foreach (string item in substract)
      {
        if (remainder.Contains(item))
          remainder.Remove(item);
      }
    }

    /// <summary>
    /// Substracts one list from another and returns the remainder.
    /// </summary>
    /// <param name="original"></param>
    /// <param name="substract"></param>
    /// <returns></returns>
    public static List<string> SubstractLists(List<string> original, List<string> substract)
    {
      return SubstractLists(original, substract, StringComparer.CurrentCulture);
    }

    /// <summary>
    /// Subtracts one List from another and allows passing a parameter to ignore or use case sensitivity.
    /// </summary>
    /// <param name="stringComparer">Use or ignore case sensitivity.</param>
    /// <returns></returns>
    public static List<string> SubstractLists(List<string> original, List<string> substract, StringComparer stringComparer)
    {
      List<string> remainder = new List<string>();
      foreach (string item in original)
      {
        if (!substract.Contains(item, stringComparer))
        {
          remainder.Add(item);
        }
      }
      return remainder;
    }

    /// <summary>
    /// Returns all equal values inside two lists.
    /// </summary>
    public static List<string> ReturnEqual(List<string> list, List<string> compare)
    {
      return ReturnEqual(list, compare, StringComparer.CurrentCulture);
    }

    /// <summary>
    /// Returns all equal values inside two lists. Can ignore case-sensitivity.
    /// </summary>
    /// <param name="list"></param>
    /// <param name="compare"></param>
    /// <param name="stringComparer"></param>
    /// <returns></returns>
    public static List<string> ReturnEqual(List<string> list, List<string> compare, StringComparer stringComparer)
    {
      var result = new List<string>();
      foreach (var item in compare)
      {
        if (list.Contains(item, stringComparer))
          result.Add(item);
      }
      return result;
    }

    /// <summary>
    /// Tests if the input directory contains at least one Key that contains a substring of the keyPart parameter. returns true/false.
    /// </summary>
    public static bool TryFindKeyPart(Dictionary<string, List<string>> dictionary, string keyPart)
    {
      foreach (var fullKey in dictionary.Keys)
      {
        if (fullKey.Contains(keyPart))
        {
          return true;
        }
      }
      return false;
    }

    /// <summary>
    /// Attempts to return the Value inside a Dictionary. Returns an empty string if no key matches.
    /// </summary>
    public static List<string> TryGetValue(Dictionary<string, List<string>> collection, string primarykey)
    {
      List<string> list = null;
      collection.TryGetValue(primarykey, out list);
      if (list == null)
        list = new List<string>();

#if DEBUG
      // TEMP - CLEARS ALL LISTS TO ONLY SHOW THE DUMMY-VALUES.
      //list.Clear();
      //list.Add(primarykey);
#endif

      return list;
    }

    /// <summary>
    /// Returns the filepath with the correct casings. Expected Exceptions if file not found: IndexOutofRange, DirectoryNotFound.
    /// </summary>
    /// <param name="filepath">the filepath with potentially incorrect casings.</param>
    /// <returns>the filepath with correct casings, if found on disk.</returns>
    public static string GetProperFilePathCapitalization(string filepath)
    {
      string directoryPath = Path.GetDirectoryName(filepath);
      string[] files = Directory.GetFiles(directoryPath, Path.GetFileName(filepath));
      return files[0];
    } 
    #endregion

    #region Events & Handling
    public static event LineReadEventHandler ReadScriptLine;

    private static string OnReadLine(LineReadEventArgs e)
    {
      if (ReadScriptLine != null)
        ReadScriptLine(e);
      return e.Line;
    }

    #endregion
  }
  #region Event Classes

  public delegate void LineReadEventHandler(LineReadEventArgs e);

  public class LineReadEventArgs
  {
    public string Line;
    public XmlNode Project;

    public LineReadEventArgs(string line, XmlNode project)
    {
      this.Line = line;
      this.Project = project;
    }
  } 
  #endregion
}
