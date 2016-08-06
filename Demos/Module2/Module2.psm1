$Script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name

   #Récupère le code d'une fonction publique du module Log4Posh (Prérequis)
   #et l'exécute dans la portée du module
$InitializeLogging=$MyInvocation.MyCommand.ScriptBlock.Module.NewBoundScriptBlock(${function:Initialize-Log4NetModule})
&$InitializeLogging $Script:lg4n_ModuleName "$psScriptRoot\Log4Net.Config.xml"

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