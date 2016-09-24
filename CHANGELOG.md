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
