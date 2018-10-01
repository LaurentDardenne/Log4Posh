$script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name
$Script:LogJobName=$Script:ModuleName


function AUn {
  $DebugLogger.PSDebug("message from function AUn")
  $InfoLogger.PSInfo("message fromfunction AUn")
}

function ADeux {
  $DebugLogger.PSDebug("message from function ADeux")
  $InfoLogger.PSInfo("message from function ADeux")
  AUn
}

function ATrois {
  $DebugLogger.PSDebug("message from function ATrois")
  $InfoLogger.PSInfo("message from function ATrois")
  Write-Verbose "Call $Script:ModuleName.AUn , ModuleProcess.BUn"
  AUn
}
