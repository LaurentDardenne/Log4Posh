$Script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name
 #see \TypeData\log4net.Core.LogImpl.Types.ps1xml
 
   #Récupère le code d'une fonction publique du module Log4Posh (Prérequis)
   #et l'exécute dans la portée du module.
   #Car, si on passe un scriptblock qui utilise la variable $PSscriptRoot,
   #celle-ci reste liée au scriptblock qui l'a créé !!
$InitializeLogging=[scriptblock]::Create("${function:Initialize-Log4Net}")
$Params=@{
  RepositoryName = $Script:lg4n_ModuleName
  XmlConfigPath = "$psScriptRoot\Log4Net.Config.xml"
  DefaultLogFilePath = "$psScriptRoot\Logs\${Script:lg4n_ModuleName}.log"
  Scope='Script'
}
&$InitializeLogging @Params

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