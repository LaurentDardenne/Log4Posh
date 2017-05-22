Version 2.1.2
  FIX : 
     In the manifest the key 'VariableToExport' need Export-ModuleMember -Variable * -Function * -Alias *
   
Version 2.1.0
     
   CHANGE : 
     Rename the function Get-Log4NetShortcuts to Get-Log4NetShortcut
     Use log4Net dll version 2.0.8.0
     Remove Export-ModuleMember use instead the manifest
     Export functions 'Set-LogDebugging' and 'Get-LogDebugging'
      
   ADDING : 
     Support for .NET Core 1.0
     'New-Log4NetCoreLevel' function. Create a personalized level.
     Localization of the demo scripts 
     Minimal inline help
     Translation
     French tutoriel about Log4net with Powershell 
    
   FIX: 
     Get-DefaultAppenderFileName
     Start-Log4Net

   Note :
     
    From : https://logging.apache.org/log4net/release/framework-support.html#netstandard-1.3

    .NET Core 1.0 / .NET Standard 1.3
      Targets netstandard-1.3 and thus doesn't support a few things that work on Mono or the classical .NET platform.
      Things that are not supported in log4net for .NET Standard 1.3:
        - the ADO.NET appender
        - anything related to ASP.NET (trace appender and several pattern converters)
        - .NET Remoting
        - log4net.LogicalThreadContext and the associated properties and stack classes
        - the colored console appender
        - the event log appender
        - The NetSendAppender
        - The SMTP appender
        - DOMConfigurator
        - stack trace patterns
        - access to appSettings (neither the log4net section itself nor using the AppSettingsPatternConverter)
        - Access to "special paths" using the EnvironmentFolderPathPatternConverter
        - Impersonation of Windows accounts

Version 2.0.1
  2017-02-11   
   Fix the function Initialize-Log4NetModule : the call of New-item must use the -PATH parameter.
     
Version 2.0.0
  2016-09-24  
   Fix the initialization of the code injection
   Add functions Set-LogDebugging and Get-LogDebugging

Version 1.2.0
  2016-08-06
   Refactoring : loading dll by the dotnet version ($psversiontable.CLRVersion) 

Version 1.1.0
  2014-03-27  
   Add PSDebug method, refactoring : use a Log4net repository for each module

Version 1.0.0
  2014-03-01  
    Original version
