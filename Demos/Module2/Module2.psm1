$Script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name

   #Récupère le code d'une fonction publique du module Log4Posh (Prérequis)
   #et l'exécute dans la portée du module
$InitializeLogging=[scriptblock]::Create("${function:Initialize-Log4NetModule}")
$Params=@{
  RepositoryName = $Script:lg4n_ModuleName
  XmlConfigPath = "$psScriptRoot\Log4Net.Config.xml"
  DefaultLogFilePath = "$psScriptRoot\Logs\${Script:lg4n_ModuleName}.log"
}
&$InitializeLogging @Params

function BUn {
  $DebugLogger.PSDebug("message from function BUn")
  $InfoLogger.PSInfo("message from function BUn") 
}

function BDeux { 
  $DebugLogger.PSDebug("message from function BDeux")
  $InfoLogger.PSInfo("message from function BDeux") 
  CUn 
}

function BTrois {
  $DebugLogger.PSDebug("message from function BTrois")
  $InfoLogger.PSInfo("message from function BTrois") 
  AUn;BUN;CUN
}

Function OnRemove {
  Stop-Log4Net $Script:lg4n_ModuleName
}#OnRemovePsIonicZip
 
# Section  Initialization
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { OnRemove }