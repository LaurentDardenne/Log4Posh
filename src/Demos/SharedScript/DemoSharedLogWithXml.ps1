#   --Requires -Modules Log4Posh

$ScriptName=([System.IO.FileInfo]$PSCommandPath).BaseName

#$lg4n_ScriptName is added in beginning of a log line (ETS manage this variable)
#$LogJobName is used for named an appender`s file (Log4net manage this propertie)
$script:lg4n_ScriptName=[log4net.GlobalContext]::Properties["LogJobName"]=$ScriptName

#Log4net manage this property, it is used for the path of a appender`s file
[log4net.GlobalContext]::Properties["ApplicationLogPath"]="$PSScriptRoot\Logs"

try {
    #The script declares the loggers
    Initialize-Log4Net -RepositoryName $ScriptName -XmlConfigPath "$PSScriptRoot\$ScriptName.Config.xml"

    #Each logger use a dedicated file
    $DebugLogger.PSDebug("Debug message [Technical]")
    $InfoLogger.PSInfo("Information message [Functional]")

    #We use the native method, the $lg4n_ScriptName variable is not inserted into a log line
    $DebugLogger.Debug("No 'header'. Debug message [Technical]")
    $InfoLogger.Info("No 'header'. Information message [Functional]")

    #The modules use script loggers
    Import-Module .\Moduleprocessing\ModuleProcessing.psd1
    Import-Module .\ModuleShared\ModuleShared.psd1
    BTrois
    #This script, the shared module, and the processing module write to the same log file
    AError
    #This fonction throw an exception :
    # at BError, ..\Log4Posh\Demos\SharedScript\Moduleprocessing\ModuleProcessing.psm1: line 24
    # at AError, ..\Log4Posh\Demos\SharedScript\ModuleShared\ModuleShared.psm1: line 24
    # at <ScriptBlock>,..\Log4Posh\Demos\SharedScript\DemoSharedLogWithXml.ps1: line 30
}
catch{
  $Repository=Get-Log4NetRepository -RepositoryName $ScriptName
  if(!$Repository.Configured)
  { Write-Error "Error $_" }
  else
  {
     #Log the error (ErrorRecord) with the 'ScriptStackTrace' property after the message string.
    $InfoLogger.PSFatal('Error',$_)

    #Log the error (exception) without the 'ScriptStackTrace' property.
    $InfoLogger.PSFatal('Error',$_.exception)
  }
}
Finally {
    Stop-Log4Net -RepositoryName $ScriptName
}