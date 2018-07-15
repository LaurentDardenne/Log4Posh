#Use the Logger variables declared in the context of the caller.
#this module do not configure a Log4Net repository
$script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name
$Script:LogJobName=$Script:ModuleName

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
