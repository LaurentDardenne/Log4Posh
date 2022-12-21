#Requires -Modules Log4Posh

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidAssignmentToAutomaticVariable','',Justification='PowerShell 2.0')]
[Diagnostics.CodeAnalysis.SuppressMessage('AssignmentStatementToAutomaticNotSupported','',Justification='Ok for PowerShell 2.0')]
param()

#Powershell v2
if (!$PSCommandPath)
{
 $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

 $m=Get-Module Log4Posh
 if ($null -eq $M)
 { $m=Import-Module Log4Posh -PassThru}

 $ScriptName='FirstDemo'
}
else
{ $ScriptName=([System.IO.FileInfo]$PSCommandPath).BaseName }

#$lg4n_ScriptName is added in beginning of a log line (ETS manage this variable)
$script:lg4n_ScriptName=[log4net.GlobalContext]::Properties["LogJobName"]=$ScriptName

function Log{
  $DebugLogger.PSDebug("Debug message from function Log. (Send by `$DebugLogger)")
  $InfoLogger.PSInfo("Information message from function Log.(Send by `$InfoLogger)")

  $DebugLogger.PSError("Error message from function Log.(Send by `$DebugLogger)")
  $InfoLogger.PSError("Error message from function Log.(Send by `$InfoLogger)")
}

try {
 #The script declares the loggers
 Initialize-Log4Net -RepositoryName $ScriptName -XmlConfigPath "$PSScriptRoot\Log4Net.Config.xml"

 Log
}
Finally {
 Write-warning "Content of the file '$env:Temp\First.log'"
 Get-Content $env:Temp\First.log
 Stop-Log4Net
 "For this demo `$DebugLogger write only to the console."
 "For this demo `$InfoLogger write only into a file."
}
