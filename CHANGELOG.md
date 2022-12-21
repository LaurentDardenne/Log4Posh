2023-12-21  Version 3.1.0
  Update Log4Net library to 2.0.15
  Migration :
     Pester v5.3.3
     InvokeBuild v5.10.1
     PSScriptAnalyzer v1.21.0
     GitHubAction

2021-12-20  Version 3.0.6
  Update Log4Net library to 2.0.14

2019-09-22  Version 3.0.5
  Add 
    Documentation file
    function to remove old timestamped log files
    Function header log
  
  Fix 
    Regression in PSake 4.8.0. 
    Encoding file with UTF8-BOM

2019-01-12  Version 3.0.4
  Add simple demos.

2018-07-15  Version 3.0.3
  Add
    log4net.Core.LogImpl.Types.ps1xml :

     We can use a ErrorRecord instance instead a Exception when we call PSFatal('Message',$Exception).

     It write the 'ScriptStackTrace' property after the message string.

2018-07-15  Version 3.0.2
  Add
    Log files are now created with the UTF-8 encoding by default.

    PSWarn method in TypeData (ETS).

    PSDebugFormat, PSInfoFormat, PSWarnFormat, PSErrorFormat, PSFatalFormat methods in TypeData (ETS).

    Add 'Get-Log4NetGlobalContextProperty' function.

    Add 'Get-Log4NetConfiguration' function.

2018-05-18  Version 3.0.1
 Fix
     function Start-Log4Net
      When the module was loaded from an UNC path, the constructor of the class System.IO.fileInfo

      raised a NotSupportedException exception.

2018-05-06  Version 3.0.0
  Breaking change
    The function Initialize-Log4Net dot not use script scope by default with a xml configuration ($XmlConfigPath)

    The caller, in the case of a module using its own loggers, must specify the scope 'Script'
    
    The following code :
    ```powershell
      $InitializeLogging=[scriptblock]::Create("${function:Initialize-Log4Net}")
      $Params=@{
        RepositoryName = $Script:lg4n_ModuleName
        XmlConfigPath = "$psScriptRoot\Log4Net.Config.xml"
        DefaultLogFilePath = "$psScriptRoot\Logs\${Script:lg4n_ModuleName}.log"
      }
      &$InitializeLogging @Params
    ```
   becomes
   ```powershell
      $InitializeLogging=[scriptblock]::Create("${function:Initialize-Log4Net}")
      $Params=@{
        RepositoryName = $Script:lg4n_ModuleName
        XmlConfigPath = "$psScriptRoot\Log4Net.Config.xml"
        DefaultLogFilePath = "$psScriptRoot\Logs\${Script:lg4n_ModuleName}.log"
        Scope='Script'
      }
      &$InitializeLogging @Params
  ```
  Add
     Function Get-DefaultRepository : return the défault repository. See Get-DefaultRepositoryName
     Get-Log4NetLogger : add -All parameter. Return all loggers of a repository
     
  Change 
    Get-Log4NetAppenderFileName : rename the parameter 'ModuleName' to 'RepositoryName'
                                  rename the alias 'RepositoryName' to 'ModuleName'


2017-08-11  Version 2.2.0
  Change 
     The functions Initialize-Log4NetModule and Initialize-Log4NetScript are obsolete.
       Use instead the function Initialize-Log4Net.

     function Initialize-Log4NetModule 
       The $DefaultLogFilePath parameter is no longer mandatory.
       We use by default the file names defined in the xml file.
       
       The $DefaultLogFile variable is obsolete.
       Use instead the function Get-Log4NetFileAppender 

     function Get-Log4NetAppenderFileName
       Add -All parameter. 
       Returns the current path of the internal and external log files of a repository.

  Fix
     function Get-Log4NetFileAppender
       The required parameter -Repository can not have a default value.
    
     function Start-Log4Net
       When the internal log of Log4Net is activated, the API [Log4net.Config.XmlConfigurator]::Configure()
       return Error and Log in the same collection.
       We must filter the $Result collection on the 'Prefix' member.

 
2017-05-22  Version 2.1.2
  Fix 
   In the manifest the key 'VariableToExport' need Export-ModuleMember -Variable * -Function * -Alias *

2017-05-15  Version 2.1.1
  Fix 
    Start-Log4Net: XmlConfigurator use [Environment]::CurrentDirectory not the Powershell location
   
  Add
    Function New-Log4NetCoreLevel : Create a personalized level.
    Comment about the ETS members
    French tutoriel about Log4net with Powershell
         
  Change
    Throw to $PSCmdlet.ThrowTerminatingError.
    
2017-04-29  Version 2.1.0
  Fix 
    PSSA rules
    Creating indirectly the default repository 
    
  Add
    Support for .NET Core 1.0
    Build tasks
    Translation
    Log4net licence 
     
  Change
    Start-Log4Net : Add Test-Path for the xml configuration file.
    Pester tests
    Throw to $PSCmdlet.ThrowTerminatingError.
    Remove Export-ModuleMember use instead the manifest
    Export functions 'Set-LogDebugging' and 'Get-LogDebugging'
    Use Log4Net version 2.0.8.0
    Core : Now we must create the default repository 'log4net-default-repository'
    Use Publish-Module instead PSNuspec

2017-02-11  Version 2.0.1
  Change
      Reorganization of the repository for the build

  Fix: 
     function Initialize-Log4NetModule : the call of New-item must use the -PATH parameter.

2016-09-24  Version 2.0.0
  Fix: 
     the initialization of the code injection
     build script
     the the log file name into demo files.

  Add:
     functions Set-LogDebugging and Get-LogDebugging
     Nuspec4 file
     icon for nuget package
     Changelog.md et releasesnotes.md file

  Change:
     Start-Log4Net now fire Error instead Warning (prevent silent failure of log4net)
     the assembly directories (On Github only)
     Pds1 key 'FunctionsToExport'

  Remove :
     Commented code (PSObjectRenderer)
     Alias 'swtafn' 
     

2016-08-06  Version 1.2.0.0
   Refactoring : loading dll by the dotnet version ($psversiontable.CLRVersion) 

2014-03-27  Version 1.1.0.0
   Add PSDebug method, refactoring : use a Log4net repository for each module

2014-03-01  Version 1.0.0.0
    Original version
