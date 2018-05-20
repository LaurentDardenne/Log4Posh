Log4Posh est un module basé sur la librairie [Log4Net](https://github.com/LaurentDardenne/Tutorial/tree/master/Utiliser%20Log4net%20avec%20Powershell) et propose un mécanisme de log pouvant être réutilisé par vos propres scripts ou modules.

Voici un court rappel des relations des objets log4net utilisés :

  Chaque référentiel (repository) possède un LogManager.

    Chaque LogManager possède un ou plusieurs Loggers.

     Chaque logger a un ou plusieurs appenders.

      Chaque appender a un ou plusieurs filtres (filer) et une mise en page (layout).

<p align="center"> 
<img src="https://www.codeproject.com/KB/cs/log4net_XmlConfigurator/log4net_objects.gif">
</p>


Log4Posh permet d'implémenter aisément dans le code de modules ou de script des traces de debug techniques et/ou des traces fonctionnelles.

Ces dernières, similaire à un *Write-Verbose*, contiennent des informations de progression d'un traitement et pourront être utilisées par le script principal.
Afin de valider la présence du module [Log4Posh](https://github.com/LaurentDardenne/Log4Posh/blob/master/Log4Posh.psm1), il est préférable de créer [un manifeste de module](http://ottomatt.pagesperso-orange.fr/Data/Tutoriaux/Powershell/Les-modules-PowerShell/Les-modules-PowerShell.pdf) et d'y renseigner la ligne suivante :
 ```powershell
     #Module de log
    RequiredModules=@{ModuleName="Log4Posh";GUID="f796dd07-541c-4ad8-bfac-a6f15c4b06a0"; ModuleVersion="3.0.1"}     
```

### Initialisation des logs dans le code d'un script

Log4Posh ajoute des membres personnalisés (ETS) à la classe logger, on permet ainsi l'ajout automatique du nom du producteur de log lors de chaque appel d'une de ces méthodes ( préfixée par PS, exemple PSDebug() ).
```Powershell
#Requires -Modules Log4Posh

#La déclaration de $lg4n_ScriptName est ajoutée en début de script (ETS utilise cette variable)
$ScriptName=([System.IO.FileInfo]$PSCommandPath).BaseName

#La clause requiert chargeant la dll du framework Log4Net, on peut accèder à ses API.
#La déclaration de la propriété de contexte 'LogJobName' permet d'indiquer le nom du script
# dans un fichier de configuration XML.

#Cette propriété est utilisée dans une déclaration de nom de fichier d'un appenderfile.
$script:lg4n_ScriptName=[log4net.GlobalContext]::Properties["LogJobName"]=$ScriptName

#Cette propriété est utilisée dans une déclaration de nom de chemin d'un appenderfile.
[log4net.GlobalContext]::Properties["ApplicationLogPath"]="$PSScriptRoot\Logs"
```
Une fois ces affections faites, on configure log4net dans le script :
```Powershell
 #par convention le fichier de configuration porte le même nom que le script
Initialize-Log4Net -RepositoryName $ScriptName -XmlConfigPath "$PSScriptRoot\$ScriptName.Config.xml"
```
Ici la notion de repository permet de cloisonner les loggers (objet en charge des log), on peut donc soit déclarer un repository global soit plusieurs repository, un pour le script principal et un pour chaque module appelés.


On peut également choisir d'utiliser la configuration par défaut de Log4Posh :
```Powershell
 Initialize-Log4Net
```

Il reste possible de modifier la configuration par défaut à l'aide de cmdlets :
```Powershell   
   $Repository=Get-DefaultRepository
   Switch-AppenderFileName -RepositoryName $Repository.Name -AppenderName 'FileExternal' -NewFileName (Join-Path -Path $Path -ChildPath $Name)
   #...
```   

### Initialisation des logs dans le code d'un module
Deux cas se présentent, le premier utilise un repository global, celui déclaré dans le script appelant les modules.
Ici seul la déclaration de la variable utilisée par ETS est nécessaire, pour un module le nom de cette variable est $lg4n_ModuleName :
```Powershell   
    $Script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name
```
Ensuite le code des fonctions du module utilise implicitement les variables loggers déclarés dans le portée du script.

Le second cas utilise un repository dédié au modules.Les premières lignes de code du module doivent initialiser le repository. Le manifeste de ce module charge donc le module Log4Posh :
```powershell
    $Script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name
    
     #Récupère le code d'une fonction publique du module Log4Posh (Prérequis)
     #et l'exécute dans la portée du module.
    $InitializeLogging=[scriptblock]::Create("${function:Initialize-Log4Net}")
    $Params=@{
      RepositoryName = $Script:lg4n_ModuleName
      XmlConfigPath = "$psScriptRoot\Log4Net.Config.xml"
      DefaultLogFilePath = "$psScriptRoot\Logs\${Script:lg4n_ModuleName}.log"
      Scope='Script'
    }
     #Ce code créé les variables $DebugLogger et $InfoLogger dans la portée du module
    &$InitializeLogging @Params

```
La variable privée _$lg4n\_ModuleName_ est référencée dans le fichier de type '[log4net.Core.LogImpl.Types.ps1xml](https://github.com/LaurentDardenne/Log4Posh/blob/master/src/TypeData/log4net.Core.LogImpl.Types.ps1xml)' et permet d'ajouter le nom du producteur du log.
Chaque module peut utiliser son propre fichier de configuration ([Log4Net.Config.xml](https://github.com/LaurentDardenne/Log4Posh/blob/master/DefaultLog4Posh.Config.xml)) et son propre repository. Le nom du repository Log4Net est identique au nom du module, **attention les API Log4Net de gestion des repository sont sensibles à la casse**.

###  Arrêt de Log4Net

Dans un script on place l'appel à Stop-Log4Net dans une instruction try/finally
```powershell
   try {
    #traitement
   }
   finally {
    Stop-Log4Net -RepositoryName $Script:lg4n_ModuleName
   }
```

Dans un module le scriptBlock _OnRemove_ doit contenir l'arrêt du repository lié au module:
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

## Initialisation des logs dans le code d'un script
### Utilisation du repository par défaut
Le script doit charger le module Log4Posh puis configurer le repository par défaut en appelant la fonction Initialize-Log4Net.
Dans ce cas tous les scripts utiliseraient la même configuration :
```powershell
Import-Module Log4Posh
Initialize-Log4Net -Console All 

$InfoLogger.PSInfo("Name of the productor of the log : $lg4n_ScriptName")
 $lg4n_ScriptName="DemoScriptWithLog4Posh"
$InfoLogger.PSInfo("Change the name of the productor of the log : $lg4n_ScriptName")
```
La variable $lg4n\_ScriptName est référencée dans le fichier de type '[log4net.Core.LogImpl.Types.ps1xml](https://github.com/LaurentDardenne/Log4Posh/blob/master/TypeData/log4net.Core.LogImpl.Types.ps1xml)' et permet d'ajouter le nom du producteur du log.

### Utilisation d'un repository dédié
Le script doit charger le module Log4Posh puis appeler la fonction Initialize-Log4Net en précisant le nom du repository et le fichier de configuration xml.
Dans ce cas chaque script utilise sa propre configuration :
```powershell
   #Récupère le code d'une fonction publique du module Log4Posh (Prérequis)
   #et l'exécute dans la portée du script
   #Ce code créé les variables $DebugLogger et $InfoLogger dans la portée de l'appelant.
$InitializeLogging=[scriptblock]::Create("${function:Initialize-Log4Net}")
$Params=@{
  RepositoryName = $MyInvocation.ScriptName
  XmlConfigPath = "$PSScriptRoot\Demo2Script.Log4Net.Config.xml"
}

&$InitializeLogging @Params
```
A partir de la version 3 de Powershell, vous pouvez également utilisez l'instruction #Requires :
```powershell
#Requires -Modules Log4Posh
 #ou
#Requires -Modules @{ModuleName="Log4Posh";GUID="f796dd07-541c-4ad8-bfac-a6f15c4b06a0"; ModuleVersion="2.2.0"}   
```
### Modification du fichier de configuration
Vous pouvez configurer Log4Posh en recopiant le fichier _DefaultLog4Posh.Config.xml_ dans le répertoire de votre script ou de votre module.
Le nom d'un fichier de log se déclare dans les élements de type FileAppender  :
```xml
 <appender name="FileInternal" type="log4net.Appender.RollingFileAppender">
```
Plus précisément dans l'élément _file_ :
```xml
  <file type="log4net.Util.PatternString" value="%env{TEMP}\\DefaultLog4Posh-%property{Owner}-%property{LogJobName}-%date{ddMMyyyy}.log"/>
``` 
Vous pouvez utilisez une variable d'environnement, un nom de chemin complet ou une propriété Log4net ( cf. [log4net.GlobalContext]::Propertie)

La fonction _**Get-Log4NetAppenderFileName**_  renvoit les emplacements par défaut des fichiers de log.
La fonction _**Get-Log4NetAppender**_  renvoit le détail de tous les fichiers de log d'un repository.

Une fois la configuration chargée, la fonction _**Switch-AppenderFileName**_  permet de modifier les emplacements du fichier  associé à un FileAppender.

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
    Initialize-Log4Net -FileExternal "C:\temp\Main.log" -Console All
      
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
