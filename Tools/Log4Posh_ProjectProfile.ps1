Param (
 # Spécifique au poste de développement
 [string] $VcsPathRepository=''
) 

if (Test-Path env:APPVEYOR_BUILD_FOLDER)
{
  $VcsPathRepository=$env:APPVEYOR_BUILD_FOLDER
}

if (!(Test-Path $VcsPathRepository))
{
  Throw 'Configuration error, the variable $VcsPathRepository should be configured.'
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
$Log4PoshDelivery= "${env:temp}\Delivery\Log4Posh"   
$Log4PoshLogs= "${env:temp}\Delivery\Logs\Log4Posh" 
$Log4PoshDelivery, $Log4PoshLogs|
 Foreach {
  new-item $_ -ItemType Directory -EA SilentlyContinue         
 }

 # Variable communes à tous les postes, leurs contenu est spécifique au poste de développement
$Log4PoshBin= "$VcsPathRepository\Bin"
$Log4PoshHelp= "$VcsPathRepository\Documentation\Helps"
$Log4PoshSetup= "$VcsPathRepository\Setup"
$Log4PoshVcs= "$VcsPathRepository"
$Log4PoshTests= "$VcsPathRepository\Tests"
$Log4PoshTools= "$VcsPathRepository\Tools"

if (Test-Path env:APPVEYOR_BUILD_FOLDER)
{
  $Log4PoshUr="'https://github.com/${env:APPVEYOR_REPO_NAME}.git" 
}
else
{
  $Log4PoshUrl= 'Todo'
  # Configuration error, the variable $Log4PoshUrl should be configured.'
  Set-PSBreakpoint -Variable Log4PoshUrl -Mode readwrite 
}

 #PSDrive sur le répertoire du projet 
$null=New-PsDrive -Scope Global -Name Log4Posh -PSProvider FileSystem -Root $Log4PoshVcs 

Write-Host "Projet Log4Posh configuré." -Fore Green


