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
  
function CUn {
  $DebugLogger.PSDebug("message from function CUn")
  $InfoLogger.PSInfo("message from function CUn")
}

function CDeux { 
  $DebugLogger.PSDebug("message from function CDeux")
  $InfoLogger.PSInfo("message from function CDeux")
  BUn 
}

function CTrois {
  $DebugLogger.PSDebug("message from function CTrois")
  $InfoLogger.PSInfo("message from function CTrois")
  AUn;BUN;CUN
}

Function OnRemove {
  Stop-Log4Net $Script:lg4n_ModuleName
}#OnRemovePsIonicZip
 
# Section  Initialization
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { OnRemove }