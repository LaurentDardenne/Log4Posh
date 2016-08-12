#Build.ps1
#Construit la version de Log4Posh
 [CmdletBinding(DefaultParameterSetName = "Debug")]
 Param(
     [Parameter(ParameterSetName="Release")]
   [switch] $Release
 ) 
# Le profile du projet (Log4Posh_ProjectProfile.ps1) doit être chargé

Set-Location $Log4PoshTools

try {
 'Psake'|
 Foreach {
   $name=$_
   Import-Module $Name -EA stop -force
 }
} catch {
 Throw "Module $name is unavailable."
}  

$Error.Clear()
Invoke-Psake .\Release.ps1 -parameters @{"Config"="$($PsCmdlet.ParameterSetName)"} -nologo

$psake.build_success
