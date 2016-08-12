Param (
 # Spécifique au poste de développement
 [ValidateScript({Test-Path $_})]
 [string] $VcsPathRepository=$env:APPVEYOR_BUILD_FOLDER
) 

if ($VcsPathRepository -eq [string]::Empty)
{
  $VcsPathRepository="$env:temp"
   #todo a supprimer une fois renseigné
  Throw "Erreur de configuration, le chemin 'VcsPathRepository' doit être configuré." 
}

#Variable commune à tous les postes
#todo ${env:Name with space}
if ( $null -eq [System.Environment]::GetEnvironmentVariable("ProfileLog4Posh","User"))
{ 
  [Environment]::SetEnvironmentVariable("ProfileLog4Posh",$VcsPathRepository, "User")
   #refresh the Environment Provider
  $env:ProfileProfileLog4Posh=$VcsPathRepository  
}

 # Variable spécifiques au poste de développement
$Log4PoshDelivry= "$('C:\Users\Laurent\AppData\Local\Temp\Delivry'.TrimEnd('\','/'))\Log4Posh"   
$Log4PoshLogs= "$('C:\Users\Laurent\AppData\Local\Temp\Logs'.TrimEnd('\','/'))\Log4Posh" 

 # Variable communes à tous les postes, leurs contenu est spécifique au poste de développement
$Log4PoshBin= "$VcsPathRepository\Bin"
$Log4PoshHelp= "$VcsPathRepository\Documentation\Helps"
$Log4PoshSetup= "$VcsPathRepository\Setup"
$Log4PoshVcs= "$VcsPathRepository"
$Log4PoshTests= "$VcsPathRepository\Tests"
$Log4PoshTools= "$VcsPathRepository\Tools"
$Log4PoshUrl= 'https://github.com/LaurentDardenne/Log4Posh.git'

 #PSDrive sur le répertoire du projet 
$null=New-PsDrive -Scope Global -Name Log4Posh -PSProvider FileSystem -Root $Log4PoshVcs 

Write-Host "Projet Log4Posh configuré." -Fore Green


