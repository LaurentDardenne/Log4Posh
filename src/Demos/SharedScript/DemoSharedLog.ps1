#Requires -Modules Log4Posh
Function Initialize-Logging {
  param(
      [string] $Path,
      [string] $Name
  )
  
   [log4net.GlobalContext]::Properties["LogJobName"]='DemoSharedLog'
   #change le nom via PatternString unicité du nom pour chaque exécution
   $p=[log4net.Util.PatternString]::new('%env{TEMP}\\DefaultLog4Posh-%property{Owner}-%property{LogJobName}-%date{ddMMyyyy}.log')
   $p.Format()>$null
   #todo $ConversionPattern='[PID:%property{Owner}] [%property{LogJobName}] %-5level %d{yyyy-MM-dd HH:mm:ss} – %message%newline'
  
   Initialize-Log4Net #Qu'on écrive ou non dans un logger le fichier déclaré dans le config.xml est tout de même crée
                      #Ce qui implique qu'un module ne peut écrire dans son fichier de log par défaut
                      # avant que l'appelant n'ai modifié le nom de fichier

<#
+ repo, chacun avec 2 loggers dédiés mais utilisant le même fichier de config
ETS ajoute les membres sur chaque instance de log4net.Core.LogImpl

dans un module crée la fonction
new-item -name function:Initialize-LoggingModuleName -value ${function:Initialize-Log4Net}")
On l'appel de l'extérieur en fournissant le nom de config du script.

depuis le script appeler du code dans un module et lui passer en param une hashtable

$Params=@{
  RepositoryName = $Script:lg4n_ModuleName
  XmlConfigPath = "$psScriptRoot\Log4Net.Config.xml"
  DefaultLogFilePath = "$psScriptRoot\Logs\${Script:lg4n_ModuleName}.log"
}
&$InitializeLogging @Params
#>

   $Repository=Get-DefaultRepository
   Switch-AppenderFileName -RepositoryName $Repository.Name -AppenderName 'FileExternal' -NewFileName (Join-Path -Path $Path -ChildPath $Name)
   
   $PathLg4n=New-object System.IO.FileInfo (Get-Log4NetAppenderFileName -RepositoryName $Repository.Name -Internal)
   write-warning  $PathLg4n
   Switch-AppenderFileName -RepositoryName $Repository.Name -AppenderName 'FileInternal' -NewFileName (Join-Path -Path $Path -ChildPath $PathLg4n.Name) 
   $DebugLogger.Debug("Modify the location of the main script log file :'$path'")
}

# Initialize-Log4Net  -> écrit dans le fichier déclaré par le ficheir de config du module log4posh
#$DebugLogger.PSDebug("Message")

Initialize-Logging -Path 'C:\temp' -Name 'DemoSharedLog.ps1.log'
$DebugLogger.PSDebug("Message de debug [Technique]")
$InfoLogger.PSInfo("Message d'info [Fonctionnel]")
#ce script, le module partagé et le module de traitement écrivent dans le même fichier de log