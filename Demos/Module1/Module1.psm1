$Script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name

   #Récupère le code d'une fonction publique du module Log4Posh (Prérequis)
   #et l'exécute dans la portée du module
$InitializeLogging=$MyInvocation.MyCommand.ScriptBlock.Module.NewBoundScriptBlock(${function:Initialize-Log4NetModule})
&$InitializeLogging $Script:lg4n_ModuleName "$psScriptRoot\Log4Net.Config.xml"

function AUn {
  $DebugLogger.PSDebug("message from function AUn")
  $InfoLogger.PSInfo("message from function AUn")
}

function ADeux { 
  $DebugLogger.PSDebug("message from function ADeux")
  $InfoLogger.PSInfo("message from function ADeux")
  BUn
}

function ATrois {
  $DebugLogger.PSDebug("message from function ATrois")
  $InfoLogger.PSInfo("message from function ATrois")
  Write-Verbose "Call Module1.AUn, Module2.BUn, Module3.CUn"
  AUn;BUN;CUN
}

Function OnRemove {
  Stop-Log4Net $Script:lg4n_ModuleName
}#OnRemovePsIonicZip
 
# Section  Initialization
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { OnRemove }