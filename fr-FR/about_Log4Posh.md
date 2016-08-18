Log4Posh est un module basé sur la librairie [Log4Net](http://laurent-dardenne.developpez.com/articles/Windows/PowerShell/UtiliserLog4NetAvecPowerShell) et propose un mécanisme de log pouvant être réutilisé par vos propres modules.
Il permet d'implémenter aisément dans le code d'autres modules des traces de debug techniques ou des traces fonctionnelles.
 
Ces dernières, similaire à un *Write-Verbose*, contiennent des infos de progression d'un traitement et pourront être utilisées par le script principal.
Afin de valider la présence du module [Log4Posh](https://github.com/LaurentDardenne/Log4Posh/blob/master/Log4Posh.psm1), il est préférable de créer [un manifeste de module](http://ottomatt.pagesperso-orange.fr/Data/Tutoriaux/Powershell/Les-modules-PowerShell/Les-modules-PowerShell.pdf) et d'y renseigner la ligne suivante :
 ```powershell
     #Module de log
    RequiredModules=@{ModuleName="Log4Posh";GUID="f796dd07-541c-4ad8-bfac-a6f15c4b06a0"; ModuleVersion="1.1.0.0"}     
```
### Initialisation des logs dans le code d'un module

Le module dépend du module log4Posh via un manifeste. Les premières lignes de code du module doivent initialiser le repository Log4Net :
```powershell
      #Récupère le code d'une fonction publique du module Log4Posh (Prérequis)
      #et l'exécute dans la portée du module
    $Script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name
    $InitializeLogging=$MyInvocation.MyCommand.ScriptBlock.Module.NewBoundScriptBlock(${function:Initialize-Log4NetModule})
    &$InitializeLogging $Script:lg4n_ModuleName "$psScriptRoot\Log4Net.Config.xml"
```
La variable privée $lg4n\_ModuleName est référencée dans le fichier de type '[log4net.Core.LogImpl.Types.ps1xml](https://github.com/LaurentDardenne/Log4Posh/blob/master/TypeData/log4net.Core.LogImpl.Types.ps1xml)' et permet d'ajouter le nom du producteur du log.
Chaque module à son propre fichier de configuration ([Log4Net.Config.xml](https://github.com/LaurentDardenne/Log4Posh/blob/master/DefaultLog4Posh.Config.xml)) et son propre repository. Le nom du repository Log4Net est identique au nom du module, **attention les API Log4Net de gestion des repository sont sensibles à la casse**.
### Finalisation du module

Le scriptBlock OnRemove doit contenir l'arrêt du repository lié au module:
```powershell
    $MyInvocation.MyCommand.ScriptBlock.Module.OnRemove= {Stop-Log4Net $Script:lg4n_ModuleName }
```
Le repository n'est pas supprimé, mais réinitialisé.
Le module Log4Posh configure quant à lui le repository Log4net par défaut et c'est celui-ci que le ou les scripts principaux utiliseront.
La configuration, chargée dans un repository public dédié au module, déclare deux loggers dans la portée privé du module :
```xml
    <logger name="DebugLogger">
       <level value="Debug" />
       <appender-ref ref="Console" />
       <appender-ref ref="FileInternal"/>
       <appender-ref ref="Debugger"/>
    </logger>
       
    <logger name="InfoLogger">
      <level value="Info" />
      <appender-ref ref="Console" />
      <appender-ref ref="FileExternal"/>
      <appender-ref ref="Debugger"/>
    </logger>
```
Chaque logger crée les appenders suivants :
```xml
    <appender name="Console" type="log4net.Appender.ManagedColoredConsoleAppender">
    <appender name="Debugger" type="log4net.Appender.OutputDebugStringAppender">
```
L'appender nommé **Debugger** est un dispositif unique pour une session Windows d'une machine.
L'appender nommé **Console** est un dispositif unique pour chaque console Powershell, il peut donc exister plusieurs appender Console.
Le logger DebugLogger crée l'appender suivant :
```xml
    <appender name="FileInternal" type="log4net.Appender.RollingFileAppender">
```
Ce logger de niveau 'Debug' est dédié aux traces de debug internes à un module.
Le logger InfoLogger crée l'appender suivant :
```xml
    <appender name="FileExternal" type="log4net.Appender.RollingFileAppender">
```
Ce logger de niveau 'Info' est dédié aux traces de debug fonctionnels à un module.
Par défaut le nom de chemin du fichier de ces FileAppenders pointe sur
```powershell    
    "$psScriptRoot\Logs\ModuleName.log"
```
Ce nom de chemin peut être reconfiguré dynamiquement dans le code du script principal.

### Le principe

Plusieurs FileAppenders, ou dérivés, peuvent pointer sur un même fichier, que ces FileAppenders soient déclarés dans un ou plusieurs Loggers ne modifie pas cette possibilité.
Par défaut les appenders FileExternal et FileInternal utilisent le même fichier, leur mode de gestion des verrous est positionné au minimum.
Ainsi les logs fonctionnels d'un ou plusieurs modules peuvent être enregistrés dans le fichier de log du script principal.
On redirige un des loggers du module vers le fichier du logger du script principal
```powershell
    "ADHerms","ExchgInventory","PSObjectHelper"|
      Switch-AppenderFileName FileExternal "$env:MyProject\TraitementXYZ.log"
```
Désormais les logs fonctionnels des 3 modules et ceux du script principal sont écrit dans le même fichier.
Enfin l'initialisation du script principal :
```powershell
    Import-Module Log4Posh
      
     #Configure les loggers pour ce script
     #Les chemins des FileAppenders nommés FileExternal sont redirigés
     #Les appenders console sont activés
     #Les variables logger sont créées dans la portée de l'appelant de ce script
    Initialize-Log4NetScript -FileExternal "C:\temp\Main.log" -Console All
      
    $InfoLogger.PSInfo("Logger info ready.") 
    $DebugLogger.PSDebug("Logger debug ready.")
```
 Un module peut être utilisé simultanément dans plusieurs sessions Powershell ou dans une seule session exécutant des jobs, afin de distinguer le producteur de la trace vous pouvez utiliser les propriétés contextuelles Log4Net (portée globale) suivantes.
 La configuration XML du format de la chaîne à afficher déclare les propriétés contextuelles de la manière suivante :
```xml
     <layout type="log4net.Layout.PatternLayout">
       <param name="ConversionPattern" 
                  value="[PID:%property{Owner}] [%property{LogJobName}] %-5p %d{yyyy-MM-dd hh:mm:ss} – %message%newline"/>
```
*'Owner'* est le PID de la session Powershell. Si le module est exécuté dans un job, on recherche l'ID du process parent ce qui facilitera le filtrage des lignes de log.
 *'LogJobName'* est le nom du job, paramétrable via la propriété $JobName publiée par le module Log4Posh.
 Ainsi on sait d'où proviennent les logs, mais pour retrouver le nom du producteur on utilisera la méthode synthétique, d'un Logger, nommée PSDebug.
 Celle-ci préfixe le message de log du nom du module où a été appelée la méthode.
 Le code d'usage suivant :
```powershell
    Import-Module log4posh, PsIonic
    Get-ZipFile c:\temp\test.zip -List   

    # LastModified              Size CompressedSize    Ratio    Encrypted   FileName
    # ------------              ---- --------------    -----    ---------   --------
    # 05/02/2014 16:14:50     426978          13864      97%        False   t3.log
    # 09/03/2014 13:14:00       6274           1950      69%        False   MyText
    # 09/03/2014 13:14:00         27             26       4%        False   File1
    # 09/03/2014 13:14:00          6              8     -33%        False   Clés1
    # 09/03/2014 13:14:00          6              8     -33%        False   Clés2
    # 09/03/2014 15:46:12       6639           1808      73%        False   HashTable_clixml
```
renvoi la ligne de log ci dessous :
```
[PID:5380] [ConsoleHost] DEBUG 2014-03-11 07:29:23 – PsIonic : The file name is 'c:\temp\test.zip'
```
*\[PID:5380\]* est l'ID du process Powershell.
 *\[ConsoleHost\]* est le nom par défaut du job, ici c'est la console Powershell. Pour un job le nom par défaut est 'ServerRemoteHost'.
 *"PsIonic : The file name is 'c:\\temp\\test.zip'"*, est le message préfixé du nom du module.
 Cette dernière partie est produite par cet appel :
 ```powershell
    $Logger.PSDebug("The file name is '$ArchivePath'")
```
Pour modifier le nom du Job :
```powershell
    $LogJobName.Value="UnScript" 
    Get-ZipFile c:\temp\test.zip -list
```
Ce qui génère la ligne suivante
```
[PID:5380] [UnScript] DEBUG 2014-03-11 07:29:24 – PsIonic : The file name is 'c:\temp\test.zip'
```
La même chose, mais dans deux jobs :
```powershell
    $action={
      param($MyJobname)
       Import-Module log4posh
       ipmo psionic
       $LogJobName.Value=$MyJobName
        #gzf est un alias PsIonic 
       gzf c:\temp\test.zip -list
     }

    start-job -ArgumentList 'Job1' -ScriptBlock $action 
    start-job -ArgumentList 'Job2' -ScriptBlock $action
```
 Le résultat dans le fichier de log :
 ```
 [PID:5380] [Job2] DEBUG 2014-03-11 07:30:02 – PsIonic : The file name is 'c:\temp\test.zip'
 [PID:5380] [Job1] DEBUG 2014-03-11 07:30:02 – PsIonic : The file name is 'c:\temp\test.zip'
```
Pour ce cas les lignes se chevaucheront.
