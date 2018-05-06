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
Import-Module .\Moduleprocessing\Moduleprocessing.psd1
Import-Module .\ModuleShared\ModuleShared.psd1
BTrois
#Ce script, le module partagé et le module de traitement écrivent dans le même fichier de log
} 
catch{
 if ($true)
 {'test si lg4n est activé et utilisable-> log "Fatal"'>$null}
}
Finally {
    Stop-Log4Net
}