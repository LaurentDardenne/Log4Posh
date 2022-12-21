param(
    [ValidateSet('Release','Debug')]
    [string] $Configuration,

     [ValidateSet('Dev','Prod')]
    [string] $Environnement
)

Function Test-CIEnvironment {
return (Test-Path env:APPVEYOR)
}
  
Function Get-ApiKeyIntoCI {
    #Read Appveyor environment variable (encrypted)
    Write-host "ApiKey for the configuration : '$BuildConfiguration'"

    if ($BuildConfiguration -eq 'Debug')
    { return $Env:MY_APPVEYOR_DevMyGetApiKey }
    else
    { return $Env:MY_APPVEYOR_MyGetApiKey }
}
  
  
function GetPowershellGetPath {
#extracted from PowerShellGet/PSModule.psm1

$IsInbox = $PSHOME.EndsWith('\WindowsPowerShell\v1.0', [System.StringComparison]::OrdinalIgnoreCase)
if($IsInbox)
{
    $ProgramFilesPSPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell"
}
else
{
    $ProgramFilesPSPath = $PSHome
}

if($IsInbox)
{
    try
    {
        $MyDocumentsFolderPath = [Environment]::GetFolderPath("MyDocuments")
    }
    catch
    {
        $MyDocumentsFolderPath = $null
    }

    $MyDocumentsPSPath = if($MyDocumentsFolderPath)
                                {
                                    Microsoft.PowerShell.Management\Join-Path -Path $MyDocumentsFolderPath -ChildPath "WindowsPowerShell"
                                }
                                else
                                {
                                    Microsoft.PowerShell.Management\Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell"
                                }
}
elseif($IsWindows)
{
    $MyDocumentsPSPath = Microsoft.PowerShell.Management\Join-Path -Path $HOME -ChildPath 'Documents\PowerShell'
}
else
{
    $MyDocumentsPSPath = Microsoft.PowerShell.Management\Join-Path -Path $HOME -ChildPath ".local/share/powershell"
}

$Result=[PSCustomObject]@{

    AllUsersModules = Microsoft.PowerShell.Management\Join-Path -Path $ProgramFilesPSPath -ChildPath "Modules"
    AllUsersScripts = Microsoft.PowerShell.Management\Join-Path -Path $ProgramFilesPSPath -ChildPath "Scripts"

    CurrentUserModules = Microsoft.PowerShell.Management\Join-Path -Path $MyDocumentsPSPath -ChildPath "Modules"
    CurrentUserScripts = Microsoft.PowerShell.Management\Join-Path -Path $MyDocumentsPSPath -ChildPath "Scripts"
}
return $Result
}
 
Function Test-Requisite {
 param (
   [string] $Environnement
 )
    if ($Environnement -eq 'Dev')
    {
        if (Test-path Env:MYGET)
        {
            $NuGetApiKey = $Env:MYGET
            $NuGetApiKey > $null
        }
        else
        { throw "The variable 'Env:Myget' don't exist."}
    }
    else
    {
        #todo publish à part
        throw "Environnement:'$Environnement' not implemented."
        if (Test-path Env:PSGALLERY)
        { $NuGetApiKey = $Env:PSGALLERY }
        else
        { throw "The variable 'Env:PSGALLERY' don't exist."}
    }

}
#todo Test-Requisite -Environnement $Environnement

Function Get-RepositoryName{
   param(
      [string] $Configuration
   )
    #todo if ($Environnement -eq 'Prod') {$RepositoryName='PSGallery' }
   if ($Configuration -eq 'Release')
   { Return 'OttoMatt' }
   else
   { Return 'DevOttoMatt' }
}

function newDirectory {
   param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
       $Path,

        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
       $TaskName
   )

 process {
    if (!(Test-Path -LiteralPath $Path))
    {
       Write-Verbose "$TaskName - create directory '$Path'."
       [System.IO.Directory]::CreateDirectory($path) >$null
    }
    else
    { Write-Verbose "$TaskName - directory already exists '$Path'." }
 }
}

function GetModulePath {
param($Name)
  $List=@(Get-Module $Name -ListAvailable)
  if ($List.Count -eq 0)
  { Throw "Module '$Name' not found."}
   #Last version
  $List[0].Path
}

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    $name = [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path (Join-Path $parent $name) -verbose:($VerbosePreference -eq 'Continue') -EA Stop
}

function Test-BOMFile{
  param (
     [Parameter(mandatory=$true)]
    $Path
   )

    $Params=@{
      Include=@('*.ps1','*.psm1','*.psd1','*.ps1xml','*.xml','*.txt');
      Exclude=@('*.bak','*.exe','*.dll')
    }

    Get-ChildItem -Path $Path -Recurse @Params |
        Where-Object { (-not $_.PSisContainer) -and ($_.Length -gt 0)}|
        ForEach-Object  {
        Write-Verbose "Test BOM for '$($_.FullName)'"
        # create storage object
        $EncodingInfo = 1 | Select-Object FileName,Encoding,BomFound,Endian
        # store file base name (remove extension so easier to read)
        $EncodingInfo.FileName = $_.FullName
        # get full encoding object
        $Encoding = Get-DTWFileEncoding $_.FullName
        # store encoding type name
        $EncodingInfo.Encoding = $Encoding.ToString().SubString($Encoding.ToString().LastIndexOf(".") + 1)
        # store whether or not BOM found
        $EncodingInfo.BomFound = "$($Encoding.GetPreamble())" -ne ""
        $EncodingInfo.Endian = ""
        # if Unicode, get big or little endian
        if ($Encoding.GetType().FullName -eq ([System.Text.Encoding]::Unicode.GetType().FullName)) {
            if ($EncodingInfo.BomFound) {
            if ($Encoding.GetPreamble()[0] -eq 254) {
                $EncodingInfo.Endian = "Big"
            } else {
                $EncodingInfo.Endian = "Little"
            }
            } else {
            $FirstByte = Get-Content -Path $_.FullName -Encoding byte -ReadCount 1 -TotalCount 1
            if ($FirstByte -eq 0) {
                $EncodingInfo.Endian = "Big"
            } else {
                $EncodingInfo.Endian = "Little"
            }
            }
        }
        $EncodingInfo
        }|
        #PS v2 bug with Big Endian
        Where-Object {($_.Encoding -ne "UTF8Encoding") -or ($_.Endian -eq "Big")}
}

function Import-ManifestData {
#Read a .psd1 into a hashtable
  [CmdletBinding()]
 Param (
     [Parameter(Mandatory = $true)]
     [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformation()]
    $Data
  )
 return $Data
}

Function Read-ModuleDependency {
#Reads a module manifest and returns the contents of the RequiredModules key.
    Param (
        [Parameter(Mandatory = $true)]
        $Data,

        [switch] $AsHashTable,

        [switch] $AsModuleSpecification
    )

    try {
       $ErrorActionPreference='Stop'
       $Manifest=Import-ManifestData $Data
    } catch {
       throw (New-Object System.Exception -ArgumentList "Unable to read the manifest $Data",$_.Exception)
    }
    if (($Null -eq $Manifest.RequiredModules) -or ($Manifest.RequiredModules.Count -eq 0))
    { Write-Verbose "RequireModules empty or unknown : $Data" }

    Foreach ($ModuleInfo in $Manifest.RequiredModules)
    {
        #Microsoft.PowerShell.Commands.ModuleSpecification : 'RequiredVersion' need PS version 5.0
        #Instead, one build splatting for Find-Module
        Write-Debug "$($ModuleInfo|Out-String)"
        if ($ModuleInfo -is [System.Collections.Hashtable])
        {
            $ModuleInfo.Add('Name',$ModuleInfo.ModuleName)
            $ModuleInfo.Remove('ModuleName')
            if ($ModuleInfo.Contains('ModuleVersion'))
            {$ModuleInfo.Add('MinimumVersion',$ModuleInfo.ModuleVersion)}
            $ModuleInfo.Remove('ModuleVersion')
            $ModuleInfo.Remove('GUID')
        }
        else
        {
            $Name,$ModuleInfo=$ModuleInfo,@{}
            $ModuleInfo.'Name'=$Name
        }
        if($AsHashTable)
        { Write-Output $ModuleInfo }
        elseif ($AsModuleSpecification)
        { New-Object -TypeName Microsoft.PowerShell.Commands.ModuleSpecification -ArgumentList $ModuleInfo }
        else
        { New-Object PSObject -Property $ModuleInfo }
    }
}

Function Find-ExternalModuleDependencies {
<#
.SYNOPSIS
Determines, according to the current repository, the dependent external module(s).
The returned module names can be inserted into the 'ExternalModuleDependencies' key of a module manifest.
When a module depends on another module, PSGet expects to find it in the same repository, but if we publish a module in a dev repository the way of accessing dependencies changes.
To fix this we need to rewrite the manifest keys.
.EXAMPLE
    $ManifestPath='.\OptimizationRules.psd1'
    $ModuleNames=Read-ModuleDependency $ManifestPath -AsHashTable
    $EMD=Find-ExternalModuleDependencies $ModuleNames -Repository $PublishRepository
#>
    Param(
        [ValidateNotNullOrEmpty()]
       [System.Collections.Hashtable[]] $ModuleSpecification,

        [ValidateNotNullOrEmpty()]
       [String] $Repository
    )

    [System.Collections.Hashtable[]] $Modules=$ModuleSpecification|ForEach-Object {$_.Clone()}

<#
En cas d'erreur de module introuvable, Find-Module ne propose pas son nom dans une propriété de l'exception levée,
on les traite donc un par un.

Note :
La recherche ne peut se faire sur le GUID (FQN) mais uniquement sur le nom ET un numéro de version.
Il existe donc un risque minime de collision entre 2 repositories.

Scénario :
On suppose que les versions de production d'un module ne sont pas dispatchées entre les repositories
PSGallery : Repository principal de production. Il est toujours déclaré.
MyGet     : Repository secondaire de production public ou privé. Déclaré selon les besoins.
DEVMyGet  : Repository secondaire de test public ou privé. Il devrait toujours être déclaré :
                Validation de la chaîne de publication, test d'intégration.

Seul les modules requis (RequiredModule) qui ne sont pas external sont installés implicitement par Install-Module,
ceux indiqués external (ExternalModuleDependencies) doivent l'être explicitement.
Dans Powershell une dépendances externe de module ne précise pas le repository cible, mais indique que la dépendance est dans un autre repository.

Si on ne précise pas le paramètre -Repository avec Install-Module, Powershell installera le premier repository hébergeant le nom du module
répondant aux critéres de recherche.


Si aucun module ne correspond aux critéres de recherche portant sur une version, Find-Module ne renvoit rien.
On ne sait donc pas différencier le cas où d'autres versions existent mais pas celle demandée et le cas où aucune version du module existe dans le repository.
(Elle peut exister mais ailleurs). Le module sera alors considéré comme externe.

Update-ModuleManifest ne complète pas le contenu de la clé -ExternalModuleDependencies mais remplace le contenu existant.
#>

    $EMD=@(
        Foreach ($Module in $Modules) {
            try {
                Write-Verbose  "Find-ExternalModuleDependencies : $($Module|Out-String)"
                $Module.Add('Repository',$Repository)

                Find-Module @Module -EA Stop > $null
            } catch {
                Write-Debug "Not found : $($Params|Out-String)"
                if (($_.CategoryInfo -match '^ObjectNotFound') -and ($_.FullyQualifiedErrorId -match '^NoMatchFoundForCriteria') )
                {
                    #Insert into ExternalModuleDependencies
                   Write-Output $Module.Name
                }
                else
                {throw $_}
            }
         }
     )
     if ($EMD.Count -ne 0)
     {
        #New-ModuleManifest -PrivateData @{ PSData = @{ ExternalModuleDependencies = @('ModuleName') } }
       if ($EMD.Count -eq 1)
       { $EMD +=$EMD[0] }
       Write-Verbose "ExternalModuleDependencies : $EMD"
       Return $EMD
     }
}

 # Used by Edit-Template inside the 'RemoveConditionnal' task.
 # Valid values are 'Debug' or 'Release'
 # 'Release' : Remove the debugging/trace lines, include file, expand scriptblock, clean all directives
 # 'Debug' : Do not change anything
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
[ValidateSet('Release','Debug')]  $BuildConfiguration='Release'

#To manage the ApiKey differently
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$isCIEnvironment=Test-CIEnvironment

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ProjectUrl= 'https://github.com/LaurentDardenne/Log4Posh.git'

#PSSA rules have no function to document
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$IsHelpGeneration=$true

# Default Locale used for help generation, defaults to en-US.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$DefaultLocale = 'en-US'

# Items in the $Exclude array will not be copied to the $OutDir e.g. $Exclude = @('.gitattributes')
# Typically you wouldn't put any file under the src dir unless the file was going to ship with
# the module. However, if there are such files, add their $SrcRootDir relative paths to the exclude list.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$Exclude = @("$ModuleName.psm1","$ModuleName.psd1",'*.bak')
if ($BuildConfiguration -eq 'Release')
{ $Exclude +="${ModuleName}Log4Posh.Config.xml"}
# ----------------------- Basic properties --------------------------------
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ProjectName= 'Log4Posh'

# Specifies the paths of the installed scripts
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$PSGetInstalledPath=GetPowershellGetPath

# The root directories for the module's docs, src and test.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$SrcRootDir  = "$PSScriptRoot\Src"
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$TestRootDir = "$PSScriptRoot\Test"
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$DocsRootDir = "$PSScriptRoot\Docs"

# The $OutDir is where module files and updatable help files are staged for signing, install and publishing.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$OutDir = "$PSScriptRoot\Release"

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ModuleOutDir = "$OutDir\$ProjectName"

# The name of your module should match the basename of the PSD1 file.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ModuleName = Get-Item $SrcRootDir/*.psd1 |
                    Where-Object { $null -ne (Test-ModuleManifest -Path $_ -ErrorAction SilentlyContinue) } |
                    Select-Object -First 1 | Foreach-Object BaseName


# Items in the $Exclude array will not be copied to the $OutDir e.g. $Exclude = @('.gitattributes')
# Typically you wouldn't put any file under the src dir unless the file was going to ship with
# the module. However, if there are such files, add their $SrcRootDir relative paths to the exclude list.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$Exclude = @('*.bak')

# ------------------ Script analysis properties ---------------------------

# Enable/disable use of PSScriptAnalyzer to perform script analysis.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ScriptAnalysisEnabled = $true

# When PSScriptAnalyzer is enabled, control which severity level will generate a build failure.
# Valid values are Error, Warning, Information and None.  "None" will report errors but will not
# cause a build failure.  "Error" will fail the build only on diagnostic records that are of
# severity error.  "Warning" will fail the build on Warning and Error diagnostic records.
# "Any" will fail the build on any diagnostic record, regardless of severity.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
[ValidateSet('Error', 'Warning', 'Any', 'None')]
$ScriptAnalysisFailBuildOnSeverityLevel = 'Error'

# Path to the PSScriptAnalyzer settings file.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ScriptAnalyzerSettingsPath = "$PSScriptRoot\ScriptAnalyzerSettings.psd1"

# Module names for additionnale custom rule
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
[String[]]$PSSACustomRules=$null
# @(
#   (GetModulePath -Name OptimizationRules)
#   (GetModulePath -Name ParameterSetRules)
# )


#MeasureLocalizedData
    #Full path of the module to control
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$LocalizedDataModule="$SrcRootDir\$ModuleName.psm1"

    #Full path of the function to control. If $null is specified only the primary module is analyzed.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$LocalizedDataFunctions=$null

    #Cultures names to test the localized resources file.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$CulturesLocalizedData='en-US','fr-FR'

# ---------------------- Testing properties -------------------------------

# Enable/disable Pester code coverage reporting.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$CodeCoverageEnabled = $false

# CodeCoverageFiles specifies the files to perform code coverage analysis on. This property
# acts as a direct input to the Pester -CodeCoverage parameter, so will support constructions
# like the ones found here: https://github.com/pester/Pester/wiki/Code-Coverage.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$CodeCoverageFiles = "$SrcRootDir\*.ps1", "$SrcRootDir\*.psm1"


# -------------------- Publishing properties ------------------------------

# Your NuGet API key for the nuget feed (PSGallery, Myget, Private).  Leave it as $null and the first time you publish,
# you will be prompted to enter your API key.  The build will store the key encrypted in the
# $NuGetApiKeyPath file, so that on subsequent publishes you will no longer be prompted for the API key.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$NuGetApiKey = $null

# Name of the repository you wish to publish to.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$PublishRepository = Get-RepositoryName -Configuration $Configuration

# Name of the repository for the development version
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$Dev_PublishRepository = 'DevOttoMatt'

# Path to the release notes file.  Set to $null if the release notes reside in the manifest file.
# The contents of this file are used during publishing for the ReleaseNotes parameter.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ReleaseNotesPath = "$PSScriptRoot\ChangeLog.md"

# ----------------------- Misc properties ---------------------------------

# Specifies an output file path to send to Invoke-Pester's -OutputFile parameter.
# This is typically used to write out test results so that they can be sent to a CI
# system like AppVeyor.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$TestOutputFile = $null

# Specifies the test output format to use when the TestOutputFile property is given
# a path.  This parameter is passed through to Invoke-Pester's -OutputFormat parameter.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$TestOutputFormat = "NUnitXml"

# Execute or nor 'TestBOM' task
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$isTestBom=$true

###############################################################################
# Customize these tasks for performing operations before and/or after file staging.
###############################################################################

task RemoveConditionnal -If { return $false } {
#Traite les pseudo directives de parsing conditionnelle

    #todO  The first call works, but not the followings
    #-Force reload the ScriptToProcess
    Import-Module Template -Force 

    try {
    $TempDirectory=New-TemporaryDirectory
    $ModuleOutDir="$OutDir\$ModuleName"

    Write-Verbose "Build with '$BuildConfiguration'"
    Get-ChildItem  "$SrcRootDir\$ModuleName.psm1","$SrcRootDir\$ModuleName.psd1"|
    Foreach-Object {
        $Source=$_
        $TempFileName="$TempDirectory\$($Source.Name)"
        Write-Verbose "Edit : $($Source.FullName)"
        Write-Verbose " to  : $TempFileName"
        if ($BuildConfiguration -eq 'Release')
        {

            #Transforme les directives %Scriptblock%
            $Lines=Get-Content -Path $Source -Encoding UTF8|
                    Edit-String -Setting $TemplateDefaultSettings|
                    Out-ArrayOfString

            #On supprime les lignes de code de Debug,
            #   supprime les lignes demandées,
            #   inclut les fichiers,
            #   nettoie toutes les directives restantes.

            ,$Lines|
            Edit-Template -ConditionnalsKeyWord 'DEBUG' -Include -Remove -Container $Source|
            Edit-Template -Clean|
            Set-Content -Path $TempFileName -Force -Encoding UTF8 -verbose:($VerbosePreference -eq 'Continue')
        }
        elseif ($BuildConfiguration -eq 'Debug')
        {
            #On ne traite aucune directive et on ne supprime rien.
            #On inclut uniquement les fichiers.

            #'NODEBUG' est une directive inexistante et on ne supprime pas les directives
            #sinon cela génére trop de différences en cas de comparaison de fichier
            $Lines=Get-Content -Path $Source -Encoding UTF8|
                    Edit-String -Setting  $TemplateDefaultSettings|
                    Out-ArrayOfString

            ,$Lines|
            Edit-Template -ConditionnalsKeyWord 'NODEBUG' -Include -Container $Source|
            Set-Content -Path $TempFileName -Force -Encoding UTF8 -verbose:($VerbosePreference -eq 'Continue')
        }
        else
        { throw "Invalid configuration name '$BuildConfiguration'" }
        Copy-Item -Path $TempFileName -Destination $ModuleOutDir -Recurse -Verbose:($VerbosePreference -eq 'Continue') -EA Stop
    }#foreach
    } finally {
    if (Test-Path $TempDirectory)
    { Remove-Item $TempDirectory -Recurse -Force -Verbose:($VerbosePreference -eq 'Continue')  }
    }
}


# Executes before the StageFiles task.
task BeforeStageFiles RemoveConditionnal, {
}

#Verifying file encoding BEFORE generation
task TestBOM -If { $isTestBom } {
# PSScripAnalyzer's 'UseBOMForUnicodeEncodedFile' rule ensures that files that
# are not ASCII encoded have a BOM (this rule is too 'permissive' here).
# We only want to deliver UTF-8 files.
  Write-verbose "Validation of directory file encoding : $SrcRootDir"

  Import-Module PowerShell-Beautifier

  $InvalidFiles=@(Test-BOMFile -path $SrcRootDir)
  if ($InvalidFiles.Count -ne 0)
  {
     $InvalidFiles |Format-List *
     Throw 'Files are not encoded in UTF8 or are BigEndian encoded.'
  }
}

task TestLocalizedData -If { return $false } {
    Import-module MeasureLocalizedData

    if ($null -eq $LocalizedDataFunctions)
    {$Result = $CulturesLocalizedData|Measure-ImportLocalizedData -Primary $LocalizedDataModule }
    else
    {$Result = $CulturesLocalizedData|Measure-ImportLocalizedData -Primary $LocalizedDataModule -Secondary $LocalizedDataFunctions}
    if ($Result.Count -ne 0)
    {
      $Result
      throw 'One or more MeasureLocalizedData errors were found. Build cannot continue!'
    }
}

# Executes after the StageFiles task.
task AfterStageFiles TestBOM, TestLocalizedData, {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Build.
###############################################################################

# Executes before the BeforeStageFiles phase of the Build task.
task BeforeBuild {
}

# Verifying file encoding AFTER generation
task TestBOMAfterAll -If { $isTestBom } {
     #Contain Get-DTWFileEncoding
    Import-Module PowerShell-Beautifier

  Write-Verbose  "Final validation of directory file encoding : $ModuleOutDir"
  $InvalidFiles=@(Test-BOMFile -path $ModuleOutDir)
  if ($InvalidFiles.Count -ne 0)
  {
     $InvalidFiles |Format-List *
     Throw 'Files are not encoded in UTF8 or are BigEndian encoded.'
  }
}

# Executes after the Build task.
task AfterBuild TestBOMAfterAll, {
    Write-Host "The delivery is in the directory '$ModuleOutDir'"
    Write-Host "Configuration '$Configuration' for the '$Environnement' environment."
}

###############################################################################
# Customize these tasks for performing operations before and/or after Install.
###############################################################################

# Executes before the Install task.
task BeforeInstall {
}

# Executes after the Install task.
task AfterInstall {
}

###############################################################################
# Customize these tasks for performing operations before and/or after BuildHelp.
###############################################################################

# Executes before the BuildHelp task.
Task BeforeBuildHelp {
}

# Executes after the BuildHelp task.
Task AfterBuildHelp {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Publish.
###############################################################################

# Executes before the Publish task.
Task BeforePublish {
<#
 We use this process to test the following scenario (POC):
  When publishing a module, two repositories are used.
  One for dev and one for private production.
  Crossing repositories impacts the management of Powershell module dependencies.

  When using a single repository, using a prerelease via semver is sufficient.
#>
   $ManifestPath="$OutDir\$ProjectName\$ProjectName.psd1"
   if ( (-not [string]::IsNullOrWhiteSpace($Dev_PublishRepository)) -and ($PublishRepository -eq $Dev_PublishRepository ))
   {
       # We search in a repository ($PublishRepository) for the version number used during the last publication.
       # We modify the manifest of the dev delivery and not that of the project, so we do not create a Tag in Github for each publication.
       Write-Host "Increment the module version for dev repository only."
       Import-Module BuildHelpers

       $SourceLocation=(Get-PSRepository -Name $PublishRepository).SourceLocation
       Write-Host "Get the latest version for '$ProjectName' in '$SourceLocation'"
       $Version = Get-NextNugetPackageVersion -Name $ProjectName -PackageSourceUrl $SourceLocation

       $ModuleVersion=(Test-ModuleManifest -path $ManifestPath).Version
       # If no version exists, take the current version
       $isGreater=$Version -gt $ModuleVersion
       Write-Host "Update the module metadata '$ManifestPath' [$ModuleVersion] ? $isGreater "
       if ($isGreater)
       {
          Write-Host "with the new version : $version"
          Update-Metadata -Path $ManifestPath  -PropertyName ModuleVersion -Value $Version
       }
       #If we publish in a dev repository we must adapt the declarations of dependencies.
       $ModuleNames=Read-ModuleDependency $ManifestPath -AsHashTable
         #ExternalModuleDependencies
       if ($null -ne $ModuleNames)
       {
          $EMD=Find-ExternalModuleDependencies $ModuleNames -Repository $PublishRepository
          if ($null -ne $EMD)
          {
             Write-host "Update ExternalModuleDependencies with $($EMD.Name) in '$ManifestPath'"
             Update-ModuleManifest -path $ManifestPath -ExternalModuleDependencies $EMD
          }
       }
   }
   else
   { Write-Host "Use the version of the manifest." }
}

# Executes after the Publish task.
Task AfterPublish {
}