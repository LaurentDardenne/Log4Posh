#   --Requires -Modules Log4Posh

$ScriptName=([System.IO.FileInfo]$PSCommandPath).BaseName
$script:lg4n_ScriptName=$ScriptName

#module log4posh is loaded
[log4net.GlobalContext]::Properties["LogJobName"]=$ScriptName

#The module ModuleProcessing configure the Log4posh repository
Import-Module .\Modules\ModuleProcessing\ModuleProcessing.psd1
# dans ce cas le module doit exporter les loggers
# Export-ModuleMember -Variable DebugLogger,InfoLogger -function BTrois,BDeux,Bun


Write-warning "Call Logger in the script"
$DebugLogger.PSDebug("Message de debug [Technique]")
$InfoLogger.PSInfo("Message d'info [Fonctionnel]")
Import-Module .\Modules\ModuleShared\ModuleShared.psd1
Write-warning "Call Btrois function"
BTrois
#Ce script, le module partagé et le module de traitement écrivent dans le même fichier de log