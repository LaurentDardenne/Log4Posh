#Requires -Modules InvokeBuild

[CmdletBinding(DefaultParameterSetName = "Debug")]
Param(
    [Parameter(ParameterSetName="Release")]
  [switch] $Release,

  #'Dev','Prod'
  [string] $Environnement='Dev'
)

Write-Host "Build the delivery for the Log4Posh module."

$local:Verbose=$PSBoundParameters.ContainsKey('Verbose')
$local:Debug=$($PSBoundParameters.ContainsKey('Debug'))
Invoke-Build -File "$PSScriptRoot\Log4Posh.build.ps1" -Configuration $PsCmdlet.ParameterSetName -Environnement $Environnement -Verbose:$Verbose -Debug:$Debug

