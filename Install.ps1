#Install.ps1
#Requires -Modules psake

#Install : new workstation or CI (Appveyor )
# Ci (Appveyor) will use the latest version of the dependencies

#or update the dependencies locally (Modules, scripts, binaries)
#The versions of the modules installed on the Appveyor (IC) and those installed on the dev station
#may not match and break the build.



 [CmdletBinding(DefaultParameterSetName = "Install")]
 Param(
     [Parameter(ParameterSetName="Update")]
   [switch] $Update
 )
#By default we install, otherwise we update
#And we force the install for the CI
if (Test-Path env:APPVEYOR)
{ Invoke-Psake ".\Install.psake.ps1" -parameters @{"Mode"="Install"} -nologo }
else
{ Invoke-Psake ".\Install.psake.ps1" -parameters @{"Mode"="$($PsCmdlet.ParameterSetName)"} -nologo }

