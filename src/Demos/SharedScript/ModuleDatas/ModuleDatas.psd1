﻿@{
	ModuleToProcess = 'ModuleDatas.psm1'

	# Numéro de version de ce module.
	ModuleVersion = '1.1'

	# ID utilisé pour identifier de manière unique ce module
	GUID = '2ac17c25-3634-41e1-bb8b-5d0fc415874b'

    # Auteur de ce module
	Author = 'Laurent Dardenne'

	# Description de la fonctionnalité fournie par ce module
	Description = 'Log4Posh demos module'

	# Version minimale du moteur Windows PowerShell requise par ce module
	PowerShellVersion = '2.0'

    #Module de log
    RequiredModules=@{ModuleName="Log4Posh";GUID="f796dd07-541c-4ad8-bfac-a6f15c4b06a0"; ModuleVersion="2.0.1"}
}
