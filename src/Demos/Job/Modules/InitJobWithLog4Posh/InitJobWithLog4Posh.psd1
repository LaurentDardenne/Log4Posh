﻿#
# Module manifest for module 'InitJobWithLog4Posh'
#
# Generated by: Laurent
#
# Generated on: 30/09/2018
#

@{

# Script module or binary module file associated with this manifest.
# RootModule = ''

# Version number of this module.
ModuleVersion = '1.0'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'd556149c-e7e1-4bd7-b545-b92c556ba141'

# Author of this module
Author = 'Laurent'

# Company or vendor of this module
CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) 2018 Laurent. All rights reserved.'

 Description = "Load Log4Posh and itnitialize it in the caller's environment"

  # Minimum version of the Windows PowerShell engine required by this module
 PowerShellVersion = '5.1'

  # Modules that must be imported into the global environment prior to importing this module
 RequiredModules = @( @{ ModuleName = 'Log4Posh';ModuleVersion = '3.0.2';GUID = 'f796dd07-541c-4ad8-bfac-a6f15c4b06a0' })


  # Script files (.ps1) that are run in the caller's environment prior to importing this module.
 ScriptsToProcess = @('InitLog4Posh.ps1')
}

