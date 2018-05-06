@{
	ModuleToProcess = 'ModuleShared.psm1'

	# Numéro de version de ce module.
	ModuleVersion = '1.1'
 
	# ID utilisé pour identifier de manière unique ce module
	GUID = '78630364-3e2a-42ed-9f76-6e62e691b1f2'
	
    # Auteur de ce module
	Author = 'Laurent Dardenne' 

	# Description de la fonctionnalité fournie par ce module
	Description = 'Log4Posh demos module'

	# Version minimale du moteur Windows PowerShell requise par ce module
	PowerShellVersion = '2.0'

    #Module de log
    RequiredModules=@{ModuleName="Log4Posh";GUID="f796dd07-541c-4ad8-bfac-a6f15c4b06a0"; ModuleVersion="2.2.0"}                           
}
