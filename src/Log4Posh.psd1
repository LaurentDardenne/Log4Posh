#
# Manifeste de module pour le module "Log4Posh"
#
# Généré le : 10/02/2010
@{
  Author="Laurent Dardenne"
  CompanyName=""
  Copyright="2016, Laurent Dardenne, released under Copyleft"
  Description="A log4net wrapper for PowerShell"
  CLRVersion="2.0"
  GUID = 'f796dd07-541c-4ad8-bfac-a6f15c4b06a0'
  ModuleToProcess="Log4Posh.psm1"
  ModuleVersion="3.0.3"
  PowerShellVersion="2.0"
  TypesToProcess = @(
      'TypeData\log4net.Core.LogImpl.Types.ps1xml'
  )
  FunctionsToExport ='ConvertTo-Log4NetCoreLevel',
                     'Get-Log4NetAppenderFileName',
                     'Get-DefaultAppenderFileName',
                     'Get-DefaultRepositoryName',
                     'Get-Log4NetShortcuts',
                     'Get-Log4NetLogger',
                     'Get-Log4NetFileAppender',
                     'Get-ParentProcess',
                     'Get-Log4NetRepository',
                     'Initialize-Log4NetModule',
                     'Initialize-Log4NetScript',
                     'Initialize-Log4Net',
                     'Start-Log4Net',
                     'Stop-Log4Net',
                     'Set-Log4NetAppenderFileName',
                     'Set-Log4NetRepositoryThreshold',
                     'Set-Log4NetLoggerLevel',
                     'Set-Log4NetAppenderThreshold',
                     'Stop-ConsoleAppender',
                     'Start-ConsoleAppender',
                     'Switch-AppenderFileName',
                     'Test-Repository',
                     'Set-LogDebugging',
                     'Get-LogDebugging',
                     'New-Log4NetCoreLevel',
                     'Get-DefaultRepository',
                     'Get-Log4NetGlobalContextProperty',
                     'Get-Log4NetConfiguration'

  VariablesToExport ='LogDefaultColors','LogJobName'

  AliasesToExport = 'saca','spca'

  # Supported PSEditions
  #CompatiblePSEditions = 'Desktop', 'Core'

  # Private data to pass to the module specified in RootModule/ModuleToProcess.
  PrivateData = @{

     # PSData data to pass to the Publish-Module cmdlet
    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('PSEdition_Desktop','PSEdition_Core')

        # A URL to the license for this module.
        LicenseUri = 'https://creativecommons.org/licenses/by-nc-sa/4.0'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/LaurentDardenne/Log4Posh'

        # A URL to an icon representing this module.
        IconUri = 'https://github.com/LaurentDardenne/Log4Posh/blob/master/Icon/Log4Posh.png'

        # ReleaseNotes of this module
        ReleaseNotes = 'Initial version.'
    } # End of PSData hashtable
  } # End of PrivateData hashtable
}
