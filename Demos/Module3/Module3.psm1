$Script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name
   
   #Récupère le code d'une fonction publique du module Log4Posh (Prérequis)
   #et l'exécute dans la portée du module
$InitializeLogging=$MyInvocation.MyCommand.ScriptBlock.Module.NewBoundScriptBlock(${function:Initialize-Log4NetModule})
&$InitializeLogging $Script:lg4n_ModuleName "$psScriptRoot\Log4Net.Config.xml"
  
function CUn {
  $DebugLogger.PSDebug("message du module CUn")
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