 #Charge le module prérequis
$m=ipmo log4posh -pass

#Charge les modules de démos utilisant log4posh
Set-Location  "$($M.Modulebase)\Demos"
$env:PSModulePath +=";$pwd"
ipmo Module1,Module2,Module3

#Affiche les appenders de chaque logger déclaré dans 
#les modules précisés
'Module1','Module2','Module3'|
 Get-Log4NetRepository|
 Foreach  {
   Write-Warning $_.name
   $_.GetAppenders()|
   Select-Object  Name
 } 

 #Supprime les fichiers de logs associés aux modules précisés
'Module1','Module2','Module3'| 
 Get-Log4NetAppenderFileName -Internal|
 Del -path {$_}

 #Par défault, les loggers n'émettent pas sur la console
 ATrois

 #Contenu de la fonction ATrois
 ${Function:ATrois}

 #Affiche les noms de fichiers des fileappenders de chaque logger 
 #déclaré dans les modules précisés.
   #Noms des modules à interroger
'Module1','Module2','Module3'|
   #Récupère tous les Appenders nommé 'FileExternal' 
 Get-Log4NetAppenderFileName -External|
   #Affiche le fichier de logs de chaque module 
 Get-Content -path {Write-warning "File log : $_";$_}
 #Par défault, les loggers émettent dans un fichier situé 
 #dans le répertoire 'logs' de chaque module utilisant log4Posh

 
 #Active les traces sur la console
 #Seul les loggers de niveau INFO sont concernés
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
 
 #Active les traces sur la console  
 #Les loggers de niveau DEBUG sont concernés
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

 #Visualisation des noms de modules selon les fonctions appelées 
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

#Désactive les loggers du module nommé 'module2'
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

'Module1','Module2','Module3'|
  Get-Log4NetRepository|
  Get-Log4NetFileAppender -All|
  Select Name,File,LockingModel,RepositoryName|fl -GroupBy RepositoryName

$Repo= [Log4net.LogManager]::GetRepository()
$Repo.GetAppenders()
#Ras.
#Le repository par défaut pour le script courant/Session courante n'est pas configuré

 #Configure le repository par défaut
Initialize-Log4NetScript 

 #Affiche les appenders configurés
$Repo.GetAppenders()

 #Affiche les loggers déclarés
$Repo.GetCurrentLoggers()|Select Name
 #Affiche les variables associé aux loggers déclarés
 #LoggerName = VariableName
$Repo.GetCurrentLoggers()|Select Name|Get-Variable 

 #Log une information à l'aide des variables loggers déclarées 
 #via l'appel à Initialize-Log4NetScript
$InfoLogger.PSInfo("Logger info ready.")
$DebugLogger.PSDebug("Logger debug ready.")

$Repo|
   #Récupère les loggers indiqués
  Get-Log4NetLogger -Name 'InfoLogger','DebugLogger'|
   #active les logs sur la console, en modifiant le niveau de log
  Set-Log4NetAppenderThreshold 'Console' -Level Debug

$InfoLogger.PSInfo("Logger info ready.")
$DebugLogger.PSDebug("Logger debug ready.")
 
$pid 
#5932 
 #Emplacement par défaut du fichier de log
$Repo.Name|Get-Log4NetAppenderFileName -External
#C:\Users\Laurent\AppData\Local\Temp\DefaultLog4Posh-5932-ConsoleHost-07042014190000.log

#Modification de l'emplacement du fichier de log
#du script principal
$Repo.Name|
 Switch-AppenderFileName FileExternal 'C:\temp\MyLog.txt'
$InfoLogger.PSInfo("Appender FileExternal redirigé")
#1233853 INFO  - [Console] Appender FileExternal redirigé

Type 'C:\temp\MyLog.txt'
#[PID:5932] [ConsoleHost] INFO  2014-04-07 05:16:48 - [Console] Appender FileExternal redirigé

$lg4n_ScriptName="DemoScript"
$InfoLogger.PSInfo("Modification du nom du producteur de log")
Type 'C:\temp\MyLog.txt'
#[PID:5932] [ConsoleHost] INFO  2014-04-07 05:16:48 - [Console] Appender FileExternal redirigé
#[PID:5932] [ConsoleHost] INFO  2014-04-07 05:20:14 - [DemoScript] Modification du nom du producteur de log

#Modification de l'emplacement du fichier de log
#du module 'module3'
'Module3'|Switch-AppenderFileName FileExternal 'C:\temp\MyLog.txt'
ATrois
Type 'C:\temp\MyLog.txt'

#Rétabli l'emplacement par défaut du fichier de log
#du module 'module3'
'Module3'|Switch-AppenderFileName FileExternal -Default
'Module3'|Get-Log4NetAppenderFileName -External
