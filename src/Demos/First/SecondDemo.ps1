#Requires -Modules Log4Posh

  $ScriptName=([System.IO.FileInfo]$PSCommandPath).BaseName

   #$lg4n_ScriptName is added in beginning of a log line (ETS manage this variable)
   #$LogJobName is used for named an appender`s file (Log4net manage this propertie)
  $Script:lg4n_ScriptName=[log4net.GlobalContext]::Properties["LogJobName"]=$ScriptName

   #Log4net manage this property, it is used for the path of a appender`s file
  [log4net.GlobalContext]::Properties["ApplicationLogPath"]="C:\Temp"
   #reads its own properties
   #$ScriptFileInfo  = Test-ScriptFileInfo -LiteralPath $PSCommandPath

    #Log4net manage this property, this string is added only for the first writing
  [log4net.GlobalContext]::Properties["Header"]="My Header"

 function Log{
   $DebugLogger.PSDebug("Debug message from function Log. (Send by `$DebugLogger)")
   $InfoLogger.PSInfo("Information message from function Log.(Send by `$InfoLogger)")

   $DebugLogger.PSError("Error message from function Log.(Send by `$DebugLogger)")
   $InfoLogger.PSError("Error message from function Log.(Send by `$InfoLogger)")
   Throw "Error"
 }

 try {
  #The script declares the loggers
  Initialize-Log4Net -RepositoryName $ScriptName -XmlConfigPath "$PSScriptRoot\Log4Net.Config.xml"

  Log
 }
 catch{
     $InfoLogger.PSFatal("The log content the stack trace of the script",$_)
     $InfoLogger.Fatal("The log do not content the stack trace of the script",$_.Exception)
 }
 Finally {
     Stop-Log4Net
     $DebugLogger=$Null
     $InfoLogger=$Null
 }
