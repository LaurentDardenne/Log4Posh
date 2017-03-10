
if(! (Test-Path variable:Log4PoshVcs))
{
    throw "The project configuration is required, see the 'Log4Posh_ProjectProfile.ps1' script." 
}
$ModuleVersion=(Import-ManifestData "$Log4PoshVcs\Log4Posh.psd1").ModuleVersion

$Result=nuspec 'Log4Posh' $ModuleVersion {
   properties @{
        Authors='Dardenne Laurent'
        Owners='Dardenne Laurent'
        Description='A log4net wrapper for PowerShell.'
        title='Log4Posh module'
        summary='A log4net wrapper for PowerShell.'
        copyright='Copyleft'
        language='fr-FR'
        licenseUrl='https://creativecommons.org/licenses/by-nc-sa/4.0/'
        projectUrl='https://github.com/LaurentDardenne/Log4Posh'
        iconUrl='https://github.com/LaurentDardenne/Log4Posh/blob/master/icon/Log4Posh.png'
        releaseNotes="$(Get-Content "$Log4PoshVcs\releasenotes.md" -raw)"
        tags='Powershell Logging Log log4net Trace'
   }
   
   files {
        file -src "$Log4PoshVcs\lib\net20\log4net.dll" -target "2.0\log4net.dll"
        file -src "$Log4PoshVcs\lib\net40\log4net.dll" -target "4.0\log4net.dll"
        file -src "$Log4PoshVcs\lib\core\" -target "core"
        file -src "$Log4PoshVcs\Log4Posh.psd1"
        file -src "$Log4PoshVcs\Log4Posh.psm1"
        file -src "$Log4PoshVcs\DefaultLog4Posh.Config.xml"
        file -src "$Log4PoshVcs\Log4Posh.Resources.psd1"
        file -src "$Log4PoshVcs\Demos\" -target "Demos"
        file -src "$Log4PoshVcs\en-US\" -target "en-US"
        file -src "$Log4PoshVcs\fr-FR\" -target "fr-FR"


        file -src "$Log4PoshVcs\TypeData\log4net.Core.LogImpl.Types.ps1xml" -target "TypeData\log4net.Core.LogImpl.Types.ps1xml"
        file -src "$Log4PoshVcs\README.md"
        file -src "$Log4PoshVcs\releasenotes.md"
        file -src "$Log4PoshVcs\Log4NetLicence\" -target "Log4NetLicence\"
   }        
}

$Result|
  Push-nupkg -Path $Log4PoshDelivery -Source 'https://www.myget.org/F/ottomatt/api/v2/package'
  
