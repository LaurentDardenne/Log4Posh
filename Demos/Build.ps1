 #Charge le module prérequis
ipmo Log4Posh

#Charge les modules de démos utilisant log4posh
Set-Location  $PSScriptRoot
$env:PSModulePath +=";$pwd"
ipmo Module1,Module2,Module3

#Affiche les appenders de chaque logger déclaré dans 
#les modules précisés
'Module1','Module2','Module3'|
 Foreach { Write-host "`r`nLog4NetRepository for the module : $_";$_}|
 Get-Log4NetRepository|
 Foreach  {
   $T=$_.GetAppenders()| Select-Object -ExpandProperty Name
   $ofs=','
   Write-Host "`tAppenders : " -foreground green -noNewLine
   Write-Host "$T" -foreground yellow
 } 

 Write-Host "Removes the log files associated with the modules" 
'Module1','Module2','Module3'| 
  Get-Log4NetAppenderFileName -Internal | 
  Del -path {$_}


Write-Host "Call the function Module1.ATrois. By default, loggers do not write on the console."
ATrois

$Code=${Function:ATrois}
Write-Host "Code of the function Module1.ATrois" -foreground green
Write-Host $Code -foreground yellow

 #Affiche les noms de fichiers des fileappenders de chaque logger
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
