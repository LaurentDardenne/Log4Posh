function New-LogHeader {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
  Justification="New-LogHeader do not change the system state.")]
<#
  .SYNOPSIS
  Returns the informations to insert into a log header.

  .DESCRIPTION
  The log header is useful for the support team.
  It is build from the contains of somes environment variables and Powershell variables.

  .EXAMPLE
  New-LogHeader -Path $PSCommandPath -ScriptFileInfo $ScriptFileInfo -Date [DateTime]::Now
  Creating the log header with the path of the running script, his own information and
  the current datetime.

  .INPUTS
  Nothing

  .OUTPUTS
  [string]

  .NOTES
  General notes
#>
  [CmdletBinding()]
  param (
      #Path of the script writing the log
    [string] $Path,

     #date of the data processing execution
    [DateTime] $Date,

     #Informations of the script
    [Parameter(ParameterSetName='Script')]
    [PSTypeName('Microsoft.PowerShell.Commands.PSScriptInfo')]
    $ScriptFilelnfo,

     #Informations of the module
    [Parameter(ParameterSetName='Module')]
    [System.Management.Automation.PSModuleInfo]$ModuleInfo
  )

  Write-Debug "$Script:lg4n_ModuleName - Create the log header."
  if ($PSCmdlet.ParameterSetName -eq 'Script')
  {
    $version='Script version = {0} ' -F $ScriptFileInfo.Version
    $Codepath="Script path $Path"
  }
  else
  {
    $version='Module version = {0} ' -F $ModuleInfo.Version
    $Codepath="Module path $Path"
  }

  $Header=@"
$('-' * 80)
Date $($Date.ToString('yyyy-MM-dd_HH-mm-ss'))
$CodePath
$version
COMPUTERNAME = $env:COMPUTERNAME
OS = $env:OS

USERDNSDOMAIN = $env:USERDNSDOMAIN
USERNAME - $env:USERNAME

PSModulePath = $(
 "$(' ' * 4)"
 $Ofs="`r`n$(' ' * 4)"
 $env:PSModulePath -split ';'
)
PSVersionTable: $($PSVersionTable.PSVersion)
Culture = $(Get-Culture)

Loaded modules :
 $(Get-Module|Select-Object Name,Version,Modulebase|Out-String)
 $('-' * 80)
"@
  Write-Debug "$Script:lg4n_ModuleName - Log header created."
return $Header
}