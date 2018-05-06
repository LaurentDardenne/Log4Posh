@{
	ModuleToProcess = 'ModuleProcessing.psm1'

	# Numéro de version de ce module.
	ModuleVersion = '1.1'
 
	# ID utilisé pour identifier de manière unique ce module
	GUID = '7ec0e1d0-d443-456f-8d18-dad1e093a67c'
	
    # Auteur de ce module
	Author = 'Laurent Dardenne' 

	# Description de la fonctionnalité fournie par ce module
	Description = 'Log4Posh demos module'

	# Version minimale du moteur Windows PowerShell requise par ce module
	PowerShellVersion = '2.0'

    #Module de log
    RequiredModules=@{ModuleName="Log4Posh";GUID="f796dd07-541c-4ad8-bfac-a6f15c4b06a0"; ModuleVersion="2.2.0"}                           
}
