Import-module Log4Posh

$ScriptName=([System.IO.FileInfo]$PSCommandPath).BaseName
$script:lg4n_ScriptName=$ScriptName

#module log4posh is loaded
[log4net.GlobalContext]::Properties["LogJobName"]=$ScriptName

#Log4net manage this property, it is used for the path of a appender`s file
[log4net.GlobalContext]::Properties["ApplicationLogPath"]="$PSScriptRoot\Logs"

Initialize-Log4Net -RepositoryName $ScriptName -XmlConfigPath "$PSScriptRoot\$ScriptName.Config.xml"

$InfoLogger.PSInfo("Call Logger in the script")
Import-Module .\Modules\ModuleShared\ModuleShared.psd1
#Ce script, le module partagé et le module de traitement écrivent dans le même fichier de log
$InfoLogger.PSInfo("Before $env:psmodulePath")
# pointe sur le répertoire de module de démos
#par défaut un job est un process fils de ce process exécutant cette session PS
$env:psmodulePath +=";$PSScriptRoot\Modules\"
$InfoLogger.PSInfo("After $env:psmodulePath")
Start-job  -ScriptBlock {
  param ()
    Import-module InitJobWithLog4Posh
    $script:lg4n_ScriptName='Job1'

    [log4net.GlobalContext]::Properties["LogJobName"]='ContextJob'
    [log4net.GlobalContext]::Properties["ApplicationLogPath"]="$Path\Logs"

    $InfoLogger.PSInfo("Inside PSJob  $env:psmodulePath")

    $InfoLogger.PSInfo("Message d'info [Fonctionnel]")
    Import-Module ModuleShared
    Write-warning "Call Atrois function inside a job"
    ATrois
}
Write-warning "Call Atrois function"
ATrois