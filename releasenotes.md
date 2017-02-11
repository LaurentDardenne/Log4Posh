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
