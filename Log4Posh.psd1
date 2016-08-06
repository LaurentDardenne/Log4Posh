#
# Manifeste de module pour le module "Log4Posh"
#
# Généré le : 10/02/2010
# Ajout  : 27/03/2014 Méthode PSDebug, refonte autour de repository
# Ajout  : 06/08/2016 refonte du chargement des dll
#
@{
  Author="Laurent Dardenne"
  CompanyName="http://laurent-dardenne.developpez.com/"
  Copyright="© 2016, Laurent Dardenne, released under Copyleft"
  Description="A log4net wrapper for PowerShell"
  CLRVersion="2.0"
  GUID = 'f796dd07-541c-4ad8-bfac-a6f15c4b06a0'
  ModuleToProcess="Log4Posh.psm1" 
  ModuleVersion="1.2.0.0"
  PowerShellVersion="2.0"
  TypesToProcess = @(
      'TypeData\log4net.Core.LogImpl.Types.ps1xml'
  )
  
}
