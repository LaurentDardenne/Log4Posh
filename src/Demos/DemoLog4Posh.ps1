Function Demo2 {
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
param()
 #Charge le module prérequis
$m=Import-Module log4posh -pass

#Charge les modules de démos utilisant log4posh
Set-Location  "$($M.Modulebase)\Demos"
 [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$env:PSModulePath +=";$pwd"
Import-Module Module1,Module2,Module3

Write-host "`r`nDisplays the appenders of each logger declared in the specified modules." -foreground yellow
'Module1','Module2','Module3'|
 Get-Log4NetRepository|
 ForEach-Object  {
   Write-Warning "Current repository '$($_.name)'"
   $_.GetAppenders()
 } 

Write-host "`r`nDeletes the log files associated with the specified modules" -foreground yellow
'Module1','Module2','Module3'| 
 Get-Log4NetAppenderFileName -Internal|
 Remove-Item -path {$_}

 Write-host "`r`nBy default, loggers do not send to the console" -foreground yellow
 ATrois

 Write-host "`r`nContent of the ATrois function" -foreground yellow
 ${Function:ATrois}

 Write-host "`r`nDisplays the file names of the fileappenders of each logger declared in the specified modules :" -foreground yellow
   #Noms des modules à interroger
'Module1','Module2','Module3'|
   #Récupère tous les Appenders nommé 'FileExternal'
   #Pour cette démo 'FileExternal' et 'FileInternal' sont identiques 
 Get-Log4NetAppenderFileName -External|
   #Affiche le fichier de logs de chaque module 
 Get-Content -path {Write-warning "File log : $_";$_}
Write-host "By default, loggers emit in a file located in the 'logs' directory of each module using log4Posh" -fore yellow
 
 #Active les traces sur la console
 #Seul les loggers de niveau INFO sont concernés
Write-host "`r`nActivates the traces on the console, only the loggers with 'INFO' level  are concerned." -foreground yellow 
'Module1','Module2','Module3'|
   #Récupère le repository Log4Net associé
  Get-Log4NetRepository|
   #Récupère les loggers indiqués
  Get-Log4NetLogger -Name 'InfoLogger','DebugLogger'|
   #active les logs sur la console, en modifiant le niveau de log
  Set-Log4NetAppenderThreshold 'Console' -Level Info
ATrois
# 2629838 INFO  - [Module1] message from function ATrois
# 2629853 INFO  - [Module1] message from function AUn
# 2629853 INFO  - [Module2] message from function BUn
# 2629869 INFO  - [Module3] message from function CUn
 
Write-host "`r`nActivates the traces on the console, only the loggers with 'DEBUG' level  are concerned." -foreground yellow  
'Module1','Module2','Module3'|
  Get-Log4NetRepository|
  Get-Log4NetLogger -Name 'InfoLogger','DebugLogger'|
  Set-Log4NetAppenderThreshold 'Console' -DebugLevel
ATrois  
# 3020119 DEBUG - [Module1] message from function ATrois
# 3020119 INFO  - [Module1] message from function ATrois
# 3020135 DEBUG - [Module1] message from function AUn
# 3020135 INFO  - [Module1] message from function AUn
# 3020135 DEBUG - [Module2] message from function BUn
# 3020150 INFO  - [Module2] message from function BUn
# 3020150 DEBUG - [Module3] message du module CUn
# 3020150 INFO  - [Module3] message from function CUn  

Write-host "`r`nDisplay of module names according to the functions called." -foreground yellow  
AUn
# 3176650 DEBUG - [Module1] message from function AUn
# 3176650 INFO  - [Module1] message from function AUn  

Bdeux
# 062364 DEBUG - [Module2] message from function BDeux
# 062364 INFO  - [Module2] message from function BDeux
# 062364 DEBUG - [Module3] message du module CUn
# 062379 INFO  - [Module3] message from function CUn

CTrois
# 3191751 DEBUG - [Module3] message from function CTrois
# 3191766 INFO  - [Module3] message from function CTrois
# 3191766 DEBUG - [Module1] message from function AUn
# 3191766 INFO  - [Module1] message from function AUn
# 3191766 DEBUG - [Module2] message from function BUn
# 3191766 INFO  - [Module2] message from function BUn
# 3191766 DEBUG - [Module3] message du module CUn
# 3191766 INFO  - [Module3] message from function CUn

Write-host "`r`nDisables the loggers of the module named 'Module2'" -foreground yellow
 [LogManager]::GetRepository('Module2')|
  Get-Log4NetLogger -Name 'InfoLogger','DebugLogger'|
  Set-Log4NetAppenderThreshold 'Console' -Off

ATrois  
# 4794127 DEBUG - [Module1] message from function ATrois
# 4794127 INFO  - [Module1] message from function ATrois
# 4794127 DEBUG - [Module1] message from function AUn
# 4794127 INFO  - [Module1] message from function AUn
# 4794142 DEBUG - [Module3] message du module CUn
# 4794142 INFO  - [Module3] message from function CUn

Write-host "`r`nDisplays some details of log files :" -foreground yellow
'Module1','Module2','Module3'|
  Get-Log4NetRepository|
  Get-Log4NetFileAppender -All|
  Select-Object Name,File,LockingModel,RepositoryName|Format-List -GroupBy RepositoryName

$Repo= [Log4net.LogManager]::GetRepository((Get-DefaultRepositoryName))
Write-host "`r`nTry to display the appenders." -foreground yellow
$Repo.GetAppenders()
#Ras.
Write-host "`r`nThe default repository for the current script/current session is not configured :" -foreground yellow
$Repo.Configured
#false

Write-host "`r`nConfigures the default repository" -foreground yellow
Initialize-Log4NetScript 

Write-host "`r`nDisplays configured appenders :" -foreground yellow
$Repo.GetAppenders()

Write-host "`r`nDisplays declared loggers :" -foreground yellow 
$Repo.GetCurrentLoggers()|Select-Object Name

Write-host "`r`nDisplays variables associated with loggers declared (Logger name = Variable name):" -foreground yellow 
$Repo.GetCurrentLoggers()|Select-Object Name|Get-Variable 

Write-host "`r`nLog information using the loggers variables declared by the 'Initialize-Log4NetScript' function :" -foreground yellow
$InfoLogger.PSInfo("Logger info ready.")
$DebugLogger.PSDebug("Logger debug ready.")

Write-host "`r`nActivates the logs on the console, modifying the log level :" -foreground yellow
$Repo|
   #Récupère les loggers indiqués
  Get-Log4NetLogger -Name 'InfoLogger','DebugLogger'|
   #active les logs sur la console, en modifiant le niveau de log
  Set-Log4NetAppenderThreshold 'Console' -Level Debug

$InfoLogger.PSInfo("Logger info ready.")
$DebugLogger.PSDebug("Logger debug ready.")
 
$pid 
#5932 

Write-host "`r`nDefault log file location :" -foreground yellow
$Repo.Name|Get-Log4NetAppenderFileName -External
#C:\Users\Laurent\AppData\Local\Temp\DefaultLog4Posh-5932-ConsoleHost-07042014190000.log

Write-host "`r`nChanging the location of the main script log file :" -foreground yellow
$Repo.Name|
 Switch-AppenderFileName FileExternal 'C:\temp\MyLog.txt'
$InfoLogger.PSInfo("Appender FileExternal redirigé")
#1233853 INFO  - [Console] Appender FileExternal redirigé

Get-Content 'C:\temp\MyLog.txt'
#[PID:5932] [ConsoleHost] INFO  2014-04-07 05:16:48 - [Console] Appender FileExternal redirigé

 [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$lg4n_ScriptName="DemoScript"
$InfoLogger.PSInfo("Modification du nom du producteur de log")
Get-Content 'C:\temp\MyLog.txt'
#[PID:5932] [ConsoleHost] INFO  2014-04-07 05:16:48 - [Console] Appender FileExternal redirigé
#[PID:5932] [ConsoleHost] INFO  2014-04-07 05:20:14 - [DemoScript] Modification du nom du producteur de log

Write-host "`r`nModifying the location of the module log file 'module3' :" -foreground yellow
'Module3'|Switch-AppenderFileName FileExternal 'C:\temp\MyLog.txt'
ATrois
Get-Content 'C:\temp\MyLog.txt'

Write-host "`r`nReset the default location of the log file of module 'module3' :" -foreground yellow
'Module3'|Switch-AppenderFileName FileExternal -Default
'Module3'|Get-Log4NetAppenderFileName -External
}
. Demo2