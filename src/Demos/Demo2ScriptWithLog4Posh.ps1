function Un {
  $DebugLogger.PSDebug("message from function Un")
  $InfoLogger.PSInfo("message from function Un")
}

function Deux { 
  Un
  $DebugLogger.PSDebug("message from function Deux")
  $InfoLogger.PSInfo("message from function Deux")
}

function Trois {
  Deux
  $DebugLogger.PSDebug("message from function Trois")
  $InfoLogger.PSInfo("message from function Trois")
  
}

Function Demo {
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
param()
 #Charge le module prérequis
$m=Get-Module Log4Posh
if ($null -eq $M)
{ Import-Module Log4Posh }

Write-host "`r`nConfigures the default repository" -foreground yellow
$RepositoryName = $MyInvocation.ScriptName
#  #Get the code of a public function of the module Log4Posh (Prerequisite)
#  # and executes it within the scope of the module
# $InitializeLogging=[scriptblock]::Create("${function:Initialize-Log4Net}")
# $Params=@{
#   RepositoryName = $RepositoryName
#   XmlConfigPath = "$PSScriptRoot\Demo2Script.Log4Net.Config.xml"
# }
# Write-host "`r`nDefault configuration file" -foreground green
# Write-host "$($params.XmlConfigPath)`r`n"
# &$InitializeLogging @Params
Initialize-Log4Net -RepositoryName $RepositoryName -XmlConfigPath "$PSScriptRoot\Demo2Script.Log4Net.Config.xml" -scope 'Script'

 [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$lg4n_ScriptName="Demo2ScriptWithLog4Posh"
$InfoLogger.PSInfo("Change the name of the productor of the log : $lg4n_ScriptName")

Write-host "`r`nShow all created Log4net repositories :"
[LogManager]::GetAllRepositories()|
 Select-Object Name,Configured|
 Format-Table
 
Trois

$sbView={
  Write-Host "`r`nFor each logger displays the FileAppender file name" -foreground green
 
   #Récupère tous les Appenders nommé 'FileExternal' 
 Get-Log4NetAppenderFileName -RepositoryName $RepositoryName |
  #Affiche le fichier de logs de chaque module 
 ForEach-Object {Write-Host "`tlog file : $_" -foreground yellow}
}
.$sbView
Write-host "`r`nChanging the location of the main script log file :" -foreground yellow
$FileName=([System.IO.FileInfo]$RepositoryName).BaseName 
Switch-AppenderFileName -RepositoryName $RepositoryName FileExternal "C:\temp\$FileName.log"
Switch-AppenderFileName -RepositoryName $RepositoryName FileInternal "C:\temp\$FileName.log"
$InfoLogger.PSInfo("Appender FileExternal redirected")

.$sbView

Write-Host "`r`nStop Log4net. The default repository is no longer configured" -foreground green
}

if(!$PSScriptRoot)
{  $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

. Demo
Stop-Log4Net