Function Demo {
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
param()
 #Charge le module prérequis
Import-Module Log4Posh

#Charge les modules de démos utilisant log4posh
Set-Location  $PSScriptRoot
 [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$env:PSModulePath +=";$pwd"
Import-Module Module1,Module2,Module3

Write-host "`r`nShow all created Log4net repositories :"
[LogManager]::GetAllRepositories()|
 Select-Object Name,Configured|
 Format-Table

Write-host "`r`nDisplays the appenders of each logger declared in the specified modules."
'Module1','Module2','Module3'|
 ForEach-Object { Write-host "`r`nLog4NetRepository for the module : $_";$_}|
 Get-Log4NetRepository|
 ForEach-Object  {
   $T=$_.GetAppenders()| Select-Object -ExpandProperty Name
   $ofs=','
   Write-Host "`tAppenders : " -foreground green -noNewLine
   Write-Host "$T" -foreground yellow
 } 

 Write-Host "Removes the log files associated with the modules" 
'Module1','Module2','Module3'| 
  Get-Log4NetAppenderFileName -Internal | 
  Remove-Item -path {$_}


Write-Host "Call the function Module1.ATrois. By default, loggers do not write on the console."
ATrois

$Code=${Function:ATrois}
Write-Host "Code of the function Module1.ATrois" -foreground green
Write-Host $Code -foreground yellow

 Write-Host "For each logger displays the FileAppender file name" -foreground green
 #déclaré dans les modules précisés.
   #Noms des modules à interroger
'Module1','Module2','Module3'|
    #Récupère tous les Appenders nommé 'FileExternal' 
  Get-Log4NetAppenderFileName -External|
   #Affiche le fichier de logs de chaque module 
  Get-Content -path {Write-Host "`tContent of module log file : $_" -foreground yellow;$_}
 #Par défault, les loggers émettent dans un fichier situé 
 #dans le répertoire 'logs' de chaque module utilisant log4Posh

 
 Write-Host "`r`nEnable traces on the console. Only the loggers with the level 'info' are assigned" -foreground green
'Module1','Module2','Module3'|
   #Récupère le repository Log4Net associé
  Get-Log4NetRepository|
   #Récupère les loggers indiqués
  Get-Log4NetLogger -Name 'InfoLogger','DebugLogger'|
   #active les logs sur la console, en modifiant le niveau de log
  Set-Log4NetAppenderThreshold 'Console' -Level Info

Write-Host "Call the function Module1.ATrois"
ATrois
}
. Demo