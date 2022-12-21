[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidAssignmentToAutomaticVariable','',Justification='PowerShell 2.0')]
[Diagnostics.CodeAnalysis.SuppressMessage('AssignmentStatementToAutomaticNotSupported','',Justification='Ok for PowerShell 2.0')]
param()

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
{ $m=Import-Module Log4Posh -PassThru}

Write-host "`r`nConfigures the default repository" -foreground yellow
Initialize-Log4Net -Console All

$InfoLogger.PSInfo("Name of the productor of the log : $lg4n_ScriptName")
 [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$lg4n_ScriptName="DemoScriptWithLog4Posh"
$InfoLogger.PSInfo("Change the name of the productor of the log : $lg4n_ScriptName")


Write-host "`r`nDefault configuration file" -foreground green
Write-host "`t$($m.ModuleBase)\DefaultLog4Posh.Config.xml"

Write-host "`r`nShow all created Log4net repositories :"
[LogManager]::GetAllRepositories()|
 Select-Object Name,Configured|
 Format-Table

Write-host "`r`nLog information using the loggers variables declared by the 'Initialize-Log4Net' function :" -foreground yellow
Un

Write-host "`r`nChange the layout for the console logger (utc date)"
$RepositoryName=Get-DefaultRepositoryName
$Repository=Get-Log4NetRepository -RepositoryName $RepositoryName
$Console=$Repository.GetAppenders()|Where-Object {$_.Name -eq 'Console'}

 #http://logging.apache.org/log4net/release/sdk/?topic=html/T_log4net_Layout_PatternLayout.htm
$logpattern = "%utcdate{dd MMMM yyyy HH:mm:ss} %-5level - %message%newline"
$Console.Layout=new-object log4net.Layout.PatternLayout($logpattern)
$Console.ActivateOptions()
Trois

Write-host "`r`nDisplays the appenders of each logger declared in the specified modules."
 Get-DefaultRepositoryName|
 ForEach-Object { Write-host "`r`n`tLog4NetRepository for the module : $_";$_}|
 Get-Log4NetRepository|
 ForEach-Object  {
   $T=$_.GetAppenders()| Select-Object -ExpandProperty Name
   $ofs=','
   Write-Host "`tAppenders : " -foreground green -noNewLine
   Write-Host "$T" -foreground yellow
 }
#

Get-DefaultRepositoryName|
 Get-Log4NetRepository|
 Get-Log4NetFileAppender -All|
 Select-Object Name,File

 Write-Host "`r`nFor each logger displays the FileAppender file name" -foreground green
 #déclaré dans les modules précisés.
   #Noms des modules à interroger
 Get-DefaultRepositoryName|
    #Récupère tous les Appenders nommé 'FileExternal'
  Get-Log4NetAppenderFileName -External|
   #Affiche le fichier de logs de chaque module
  Get-Content -path {Write-Host "`tContent of script log file : $_" -foreground yellow;$_}

Write-Host "`r`nStop Log4net. The default repository is no longer configured" -foreground green
}

if(!$PSScriptRoot)
{ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

. Demo
Stop-Log4Net