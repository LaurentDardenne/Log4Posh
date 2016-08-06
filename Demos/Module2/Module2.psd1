@{
	ModuleToProcess = 'Module2.psm1'

	# Numéro de version de ce module.
	ModuleVersion = '1.0'
 
	# ID utilisé pour identifier de manière unique ce module
	GUID = 'e3346635-625e-4071-9de2-9a0c7c90ee95'
	
    # Auteur de ce module
	Author = 'Laurent Dardenne' 

	# Description de la fonctionnalité fournie par ce module
	Description = 'Log4Posh demos module'

	# Version minimale du moteur Windows PowerShell requise par ce module
	PowerShellVersion = '2.0'

    #Module de log
    RequiredModules=@{ModuleName="Log4Posh";GUID="f796dd07-541c-4ad8-bfac-a6f15c4b06a0"; ModuleVersion="1.1.0.0"}                           
}
