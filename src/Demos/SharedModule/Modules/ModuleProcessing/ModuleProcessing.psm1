#Use the Logger variables declared in the context of the caller.
#this module do not configure a Log4Net repository
$script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name

 #                        remove Modules\ModuleFolderName\Version
$ApplicationPath=Get-Item "$PSScriptRoot\..\..\.."
[log4net.GlobalContext]::Properties["ApplicationLogPath"]="$ApplicationPath\Logs"

$InitializeLogging=[scriptblock]::Create("${function:Initialize-Log4Net}")
$Params=@{
  RepositoryName = $Script:lg4n_ModuleName
  XmlConfigPath = "$psScriptRoot\Log4Net.Config.xml"
  DefaultLogFilePath = "$psScriptRoot\Logs\${Script:lg4n_ModuleName}.log"
  Scope='Script'
}
&$InitializeLogging @Params

function BUn {
  $DebugLogger.PSDebug("message from function BUn")
  $InfoLogger.PSInfo("message from function BUn") 
}

function BDeux { 
  $DebugLogger.PSDebug("message from function BDeux")
  $InfoLogger.PSInfo("message from function BDeux") 
  ATrois
}

function BTrois {
  $DebugLogger.PSDebug("message from function BTrois")
  $InfoLogger.PSInfo("message from function BTrois") 
  BDeux
}

Function OnRemove {
  Stop-Log4Net $Script:lg4n_ModuleName
}#OnRemovePsIonicZip
 
# Section initialization
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { OnRemove }

Export-ModuleMember -Variable DebugLogger,InfoLogger -function BTrois,BDeux,BUn