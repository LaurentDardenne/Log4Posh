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
# 2629853 INFO  - [Modu