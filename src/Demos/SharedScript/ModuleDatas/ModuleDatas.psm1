#Use the Logger variables declared in the context of the caller.
#this module do not configure a Log4Net repository
$script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name
$Script:LogJobName=$Script:ModuleName
  
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
