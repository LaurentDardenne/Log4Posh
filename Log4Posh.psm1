#Log4Posh.psm1
# !!! WARNING !!! Repository names are case sensitive

Import-LocalizedData -BindingVariable Log4PoshMsgs -Filename Log4Posh.Resources.psd1 -EA Stop

# ------------ Initialisation et Finalisation  ----------------------------------------------------------------------------

$ClrVersion=[System.Reflection.Assembly]::Load("mscorlib").GetName().Version.ToString(2)
Add-Type -Path "$psScriptRoot\$ClrVersion\log4net.dll" #"$psScriptRoot\$ClrVersion\Log4PoshTools.dll"

Function Get-ParentProcess {
#Permet de retrouver le process parent ayant exécuté 
#la session Powershell exécutant ce script/module
 param( $ID )
 $ParentID=$ID         
 $Result=@(
   Do {
     $Process=Get-CimInstance Win32_Process -Filter "ProcessID='$parentID'" -property Name,CommandLine,ParentProcessID
     $ParentID=$Process.ParentProcessID
     try {
      get-process -ID $ParentID
      $exit=$true
      }
     catch [Microsoft.PowerShell.Commands.ProcessCommandException] {
      $exit=$false       
     }
   } until ($Exit)
 )
   
 $ofs='.'
 [Array]::Reverse($Result)
 ,$Result
} #Get-ParentProcess

 
 if ($ExecutionContext.host.Name -eq 'ServerRemoteHost')
 {$_pid= (Get-ParentProcess  $PID)[0].Id}
 else
 {$_pid= $pid}

  #Propriété statique, indique le process PowerShell courant
  #Dans un job local ce n'est pas le process courant, mais le parent 
[log4net.GlobalContext]::Properties.Item("Owner")=$_pid
[log4net.GlobalContext]::Properties.Item("RunspaceId")=$ExecutionContext.Host.Runspace.InstanceId

  #Propriété dynamique, Log4net appel la méthode ToString de l'objet référencé.
  $Script:LogJobName= new-object System.Management.Automation.PSObject -Property @{Value=$ExecutionContext.Host.Name}
  $Script:LogJobName|Add-Member -Force -MemberType ScriptMethod ToString { $this.Value.toString() }
[log4net.GlobalContext]::Properties["LogJobName"]=$Script:LogJobName

$LogShortCut=@{
  LogManager = [log4net.LogManager];
  LogBasicCnfg = [log4net.Config.BasicConfigurator];
  LogXmlCnfg = [log4net.Config.XmlConfigurator];
  LogColoredConsole = [log4net.Appender.ColoredConsoleAppender];
  LogColors = [log4net.Appender.ColoredConsoleAppender+Colors];
  LogLevel = [log4net.Core.Level];
  LogThreadContext = [log4net.ThreadContext];
  LogGlobalContext = [log4net.GlobalContext];
  LogMailPriority = [System.Net.Mail.MailPriority];
  LogSmtpAuthentication = [log4net.Appender.SmtpAppender+SmtpAuthentication];
}


Function Start-Log4Net {
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
#Configure un repository à l'aide d'un fichier de configuration XML
 [CmdletBinding(DefaultParameterSetName="Path")] 
 param (
    [ValidateNotNullOrEmpty()]
    [Parameter(Position=0, Mandatory=$false,ParameterSetName="Path")]
  [log4net.Repository.ILoggerRepository] $Repository=$([LogManager]::GetRepository()),
  
    [Parameter(Position=1,Mandatory=$true,ParameterSetName="Path")]  
    [ValidateNotNullOrEmpty()]
  [string] $Path,

    [Parameter(ParameterSetName="Default")]
  [switch] $DefaultConfiguration
 )

 if ($DefaultConfiguration)
 {
   $Path="$psScriptRoot\DefaultLog4Posh.Config.xml"
   $Repository=[LogManager]::GetRepository()
 } 

 $ConfigFile=New-Object System.IO.fileInfo $Path
 Write-debug "Configure the repository '$Repository' with  '$Path'" 
 $Result=[Log4net.Config.XmlConfigurator]::Configure($Repository,$ConfigFile)
 if ($Result.Count -ne 0 )
 { 
   $ofs="`r`n"
   [string]$Message=$Result|Out-String
   throw ( New-Object System.Xml.XmlException $Message) 
 }
 
# prevent silent failure of log4net
 if(!$Repository.Configured) #Todo test
 {
 	Write-Warning "Log4net repository $($Repository.Name) is not configured"
 	foreach($message in $Repository.ConfigurationMessages)
 	{
 		Write-Warning "`t$Message"
 	}
 }
}#Start-Log4Net

Function Stop-Log4Net {
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
#On arrête proprement les loggers d'un repository,
#on vide les buffers, puis on réinitialise le repository.
 param (
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$false)]
   [string] $RepositoryName=$(Get-DefaultRepositoryName)
 )
 Write-Debug "Close the repository '$RepositoryName'"
 if (-not (Test-Repository $RepositoryName))
 {throw ($Log4PoshMsgs.RepositoryDoNotExist -F $RepositoryName) } 
  
 [LogManager]::GetRepository($RepositoryName).GetAppenders()|
  Where-Object {$_ -is  [log4net.Appender.BufferingAppenderSkeleton]}|
  Foreach-Object {
   Write-Debug "Flush appender $($_.Name)"           
    $_.Flush() 
  }
   #Shutdown() est appelé en interne, tous les appenders sont fermés proprement,
   #le repository par défaut n'est plus configuré
 [LogManager]::ResetConfiguration($RepositoryName) 
}#Stop-Log4Net

# todo : tjr utile ?
# Function Register-PSObjectRenderer {
#  #Enregistre le type [PSLog4NET.PSObjectRenderer] implémentant l'interface IObjectRenderer. 
#  #Le type [PSLog4NET.PSObjectRenderer] appel en interne la méthode tostring() du psobject,
#  #celle peut être rédéfinie via ETS:
#  # $MyObject |Add-Member -Force -MemberType ScriptMethod ToString { rver|Out-String } 
#  param (
#      [ValidateNotNullOrEmpty()]
#      [Parameter(Position=0, Mandatory=$false)]
#    [string] $RepositoryName=$(Get-DefaultRepositoryName)
#  )
#  $Repository=[LogManager]::GetRepository($RepositoryName)        
#  $Repository.RendererMap.Put([PSLog4NET.PSObjectRenderer],(new-object PSLog4NET.PSObjectRenderer) )
# } #Register-PSObjectRenderer

Function ConvertTo-Log4NetCoreLevel {
#Converti un nom de niveau en un objet [Log4Net.Core.Level]
#Chaque repository peut déclarer de nouveaux niveaux
 param (
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$false)]
   [string] $RepositoryName=$(Get-DefaultRepositoryName),

     [Parameter(Position=1,Mandatory=$true)]
   [string] $Level   
 )
 if (-not (Test-Repository $RepositoryName))
 { throw ($Log4PoshMsgs.RepositoryDoNotExist -F $RepositoryName) } 
  
 $Repository=[LogManager]::GetRepository($RepositoryName)
 $Repository.LevelMap[$Level]
}#ConvertTo-Log4NetCoreLevel

Function Set-Log4NetRepositoryThreshold {
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
#Bascule le niveau de log d'un repository
 [CmdletBinding(DefaultParameterSetName="Level")] 
 param (
      [ValidateNotNullOrEmpty()]
      [Parameter(Position=0,Mandatory=$True,ValueFromPipeline = $true)] 
    [String] $RepositoryName, 
    
     [Parameter(Position=1, ParameterSetName="Level")]
   [string] $Level='Info',
    
     [Parameter(ParameterSetName="off")]
   [switch] $Off,
    
     [Parameter(ParameterSetName="debug")]
   [switch] $DebugLevel 
 ) 

 process { 
   Get-Log4NetRepository $RepositoryName| 
   Where-Object {$_ -ne $Null}|
   Foreach-Object  {
      $Repository=$_ 
      If ($Off) 
       { $Repository.Threshold=[logLevel]::Off }
      elseif ($DebugLevel)
       { $Repository.Threshold=[logLevel]::Debug } 
      else
       { $Repository.Threshold= $Repository.LevelMap[$Level] }
      Write-Verbose "The Threshold property of the repository '$($Repository.Name)' was modified : '$($Repository.Threshold)'."
   }
 }#process
}#Set-Log4NetRepositoryThreshold


Function Set-Log4NetLoggerLevel {
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
#Bascule le niveau de log d'un logger
 [CmdletBinding(DefaultParameterSetName="Level")] 
 param (
     [Parameter(Mandatory=$true,ValueFromPipeline = $true)]
   [log4net.Core.LogImpl] $Logger,
    
     [Parameter(Position=1, ParameterSetName="Level")]
   [string] $Level='Info',
    
     [Parameter(ParameterSetName="off")]
   [switch] $Off,
    
     [Parameter(ParameterSetName="debug")]
   [switch] $DebugLevel 
 ) 

 process { 
   If ($null -ne $Logger  )
   { 
      If ($Off) 
       { $Logger.Logger.Level=[logLevel]::Off }
      elseif ($DebugLevel)
       { $Logger.Logger.Level=[logLevel]::Debug } 
      else
       { $Logger.Logger.Level=$Logger.logger.Repository.LevelMap[$Level] }
      Write-Verbose "The Level property of the logger '$($Logger.Name)' was modified : '$($Logger.Logger.Level)'."
   }
   else
   { Write-Error ($Log4PoshMsgs.LoggerDoNotExist -F $Logger.Name) }
 }
}#Set-Log4NetLoggerLevel

Function Set-Log4NetAppenderThreshold {
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
#Bascule le niveau de log d'un appender d'un logger
 [CmdletBinding(DefaultParameterSetName="Level")] 
 param (
     [Parameter(Mandatory=$true,ValueFromPipeline = $true)]
   [log4net.Core.LogImpl] $Logger,

     [Parameter(Position=1,Mandatory=$true)]
   [string[]] $AppenderName,
    
     [Parameter(Position=2,ParameterSetName="Level")]
   [string] $Level='Info',
    
     [Parameter(ParameterSetName="off")]
   [switch] $Off, 
   
     [Parameter(ParameterSetName="debug")]
   [switch] $DebugLevel 
 ) 
 
 process {  
   If ($null -ne $Logger)
   { 
      $logger.Logger.Appenders|
       Where-Object { $AppenderName -Contains $_.Name }|
       Foreach-Object {
        If ($Off) 
         { $_.Threshold=[logLevel]::Off }
        elseif ($DebugLevel)
         { $_.Threshold=[logLevel]::Debug } 
        else
         { $_.Threshold=$Logger.logger.Repository.LevelMap[$Level] }
        Write-Verbose "The Threshold property of the appender '$($_.Name)' was modified : '$($_.Threshold)'."
       }
   }
   else
   { Write-Error ($Log4PoshMsgs.LoggerDoNotExist -F $Logger.Name) }
 }
}#Set-Log4NetAppenderThreshold

Function Stop-ConsoleAppender { 
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
#Bascule le niveau de log d'un logger  
 param (
     [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
   [log4net.Core.LogImpl] $Logger
 )

 process {
   Set-Log4NetAppenderThreshold -Logger $Logger 'Console' -Off
 } 
}#Stop-ConsoleAppender

Function Start-ConsoleAppender {
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
 param (
     [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
   [log4net.Core.LogImpl] $Logger 
 )
         
 process {
   Set-Log4NetAppenderThreshold -Logger $Logger 'Console' -DebugLevel
 } 
}#Start-ConsoleAppender

 #Définition des couleurs d'affichage par défaut
[System.Collections.Hashtable[]] $script:LogDefaultColors=@(
   @{Level="Debug";FColor="Green";BColor=""},
   @{Level="Info";FColor="White";BColor=""},
   @{Level="Warn";FColor="Yellow,HighIntensity";BColor=""},
   @{Level="Error";FColor="Red,HighIntensity";BColor=""},
   @{Level="Fatal";FColor="Red";BColor="Red,HighIntensity"}
 )

 # ------------- Type Accelerators -----------------------------------------------------------------
function Get-Log4NetShortcuts {
  #Affiche les raccourcis dédiés à Log4net
 $AcceleratorsType::Get.GetEnumerator()|
  Where-Object {$_.Value.FullName -match "^log4net\.(.*)"}
}#Get-Log4NetShortcuts
 
$AcceleratorsType = [PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")   
 # Ajoute les raccourcis de type    
 Try {
  $LogShortCut.GetEnumerator() |
  Foreach-Object {
   Try {
     Write-Debug "Add TypeAccelerators $($_.Key) =$($_.Value)"
     $AcceleratorsType::Add($_.Key,$_.Value)
   } Catch [System.Management.Automation.MethodInvocationException]{
     write-Error $_.Exception.Message 
   }
  } 
 } Catch [System.Management.Automation.RuntimeException] 
 {
   write-Error $_.Exception.Message
 }

function Get-Log4NetLogger {
#Renvoi un ou des loggers du repository $RepositoryName          
  Param (   
      [ValidateNotNullOrEmpty()]
      [Parameter(Position=0,Mandatory=$True,ValueFromPipeline = $true)] 
    [log4net.Repository.ILoggerRepository] $Repository=$([Log4net.LogManager]::GetRepository()),
    
      [ValidateNotNullOrEmpty()]
      [Parameter(Position=1,Mandatory=$True)]
    [String[]] $Name
  )
  
 #Renvoi un logger de nom $Name ou le crée s'il n'existe pas. 
 # le nom "Root" est valide et renvoi le root existant
 process {
   foreach ($Current in $Name)
   {
     [LogManager]::GetLogger($Repository.Name,$Current)
   }
 }
} #Get-Log4NetLogger

function Get-Log4NetFileAppender{
#Renvoi d'un repository tout les appender, dérivés de la classe FilesAppender, 
#dont le nom est $AppenderName
 param(
      [ValidateNotNullOrEmpty()]
      [Parameter(Position=0,Mandatory=$True,ValueFromPipeline = $true)]
   [log4net.Repository.ILoggerRepository] $Repository=$([Log4net.LogManager]::GetRepository()),

    [ValidateNotNullOrEmpty()]
    [Parameter(Position=1,Mandatory=$false)]  
  [string] $AppenderName="FileExternal",
  
  [switch] $All
 )

 process { 
    $Repository.GetAppenders()|
     Where-Object {
      if ($All)
      {$_.GetType().IsSubclassOf([Log4net.Appender.FileAppender])}
      else 
      {($_.Name -eq $AppenderName) -and  ($_.GetType().IsSubclassOf([Log4net.Appender.FileAppender]))}
     }|
     Foreach-Object { Write-Verbose "Find the appender '$($_.Name)' into the repository '$($Repository.Name)'."; $_}|
     Add-Member NoteProperty -Name RepositoryName -Value $Repository.Name -Force -Passthru
 }#process
}#Get-Log4NetFileAppender

Function Set-Log4NetAppenderFileName {
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions",
                                                   Justification="Log4net do not change the system state, only the application 'context'")]
#Change le nom de fichier d'un appender dérivé de la classe FileAppender
 param (
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
     [ValidateScript( {$_.GetType().IsSubclassOf([Log4net.Appender.FileAppender])})]
     $Appender,
   
    [ValidateNotNullOrEmpty()]
    [Parameter(Position=1, Mandatory=$true)]    
   [string] $NewFileName
)
 process { 
     $Appender.File = $NewFileName
     $Appender.ActivateOptions()
     Write-Verbose "The appender '$($Appender.Name)' into the repository '$($Appender.RepositoryName)' was modified : '$NewFileName'."
 }#process  
}#Set-Log4NetAppenderFileName

function Get-DefaultRepositoryName {
 "log4net-default-repository"
}#Get-DefaultRepositoryName

function Get-Log4NetRepository {
 param (
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
   [string] $RepositoryName
 )
 process {
   if (-not (Test-Repository $RepositoryName) )
   { Write-Error ($Log4PoshMsgs.RepositoryDoNotExist -F $RepositoryName) }
   else
   { [LogManager]::GetRepository($RepositoryName) }
 }
}#Get-Log4NetRepository

function Test-Repository {
#Indique si le repository existe ou pas. 
#Si le paramètre -Configured est précisé on indique si le repository est configuré, 
#s'il n'existe pas on déclenche une exception. 

 param (
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$true)]
   [string] $RepositoryName,
   
   [switch] $Configured
) 
 $isExist=[log4net.Core.LoggerManager]::RepositorySelector.ExistsRepository($RepositoryName)
 if ($Configured)
 {
  if (-not $isExist)
  {throw ($Log4PoshMsgs.RepositoryDoNotExist -F $RepositoryName) }
  else
  { [LogManager]::GetRepository($RepositoryName).Configured }
 }
 else
 { $isExist } 
}#Test-Repository

function Get-DefaultAppenderFileName {
#renvoi le chemin par défaut du fichier de log d'un module
  Param (
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$true)]
   [string] $ModuleName
  )
         
 $Module=Get-Module $ModuleName
 if ($null -ne $Module) 
 { Write-Error ($Log4PoshMsgs.ModuleDoNotExist -F $ModuleName) }
 else
 { 
   $Fi=New-object System.IO.FileInfo $Module.Path
   "{0}\Logs\{1}.log" -F $Fi.Directory,$Fi.BaseName
 }
}#Get-DefaultAppenderFileName

function Get-Log4NetAppenderFileName {
#Renvoi le chemin courant du fichier de log internal (Debug) ou external (fonctionel) d'un module

  [CmdletBinding(DefaultParameterSetName="External")]
  Param (
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
   [string] $ModuleName,
  
    [Parameter(ParameterSetName="External")]
   [switch] $External,
   
    [Parameter(ParameterSetName="Internal")]
   [switch] $Internal
  )

 process {  
    #todo pour toutes les fonctions revoir si le repo est configuré       
   $Repository=Get-Log4NetRepository $ModuleName #todo
   if ($null -ne $Repository) 
   { 
     $AppenderName="File$($PsCmdlet.ParameterSetName)"
     $Repository.GetAppenders()|
      Where-Object { $_.Name -eq $AppenderName  }|
      Foreach-Object { 
       Write-Verbose "Find the appender '$($_.Name)' into the repository '$($Repository.Name)'."
       $_.File
      }
   }  
 }
}#Get-Log4NetAppenderFileName
         
function Initialize-Log4NetModule {
#Initialise, pour un module, un repository Log4Net et ses loggers
#Fonction injectée dans le module utilisant Log4Posh 
  Param (
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$true)]
   [string] $ModuleName,

     [ValidateNotNullOrEmpty()]
     [Parameter(Position=1, Mandatory=$True)]  
   [string] $Path
  )
  if (Test-Repository $ModuleName)
  { 
   $Repository=[LogManager]::GetRepository($ModuleName)
   $Repository.ResetConfiguration() 
  }
  else
  { $Repository=[LogManager]::CreateRepository($ModuleName) }
  
  Start-Log4Net $Repository $Path
 
#  Register-PSObjectRenderer $Repository.Name
  
   #Créé les variables Logger dans la portée de l'appelant
   #les noms des loggers sont normés
  Set-Variable -Name DebugLogger -Value ([LogManager]::GetLogger($ModuleName,'DebugLogger')) -Scope Script
  Set-Variable -Name InfoLogger -Value ([LogManager]::GetLogger($ModuleName,'InfoLogger')) -Scope Script
  Set-Variable -Name DefaultLogFile -Value "$psScriptRoot\Logs\$ModuleName.log" -Scope Script
  
   #Initialise le nom de fichier des FileAppenders dédiés au module
  Switch-AppenderFileName -RepositoryName $ModuleName FileInternal $script:DefaultLogFile
  Switch-AppenderFileName -RepositoryName $ModuleName FileExternal $script:DefaultLogFile
}#Initialize-Log4NetModule

function Initialize-Log4NetScript {
#Initialise le repository Log4Net par défaut 
  Param (
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=1, Mandatory=$false)]  
   [string] $FileExternalPath,
   
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=2, Mandatory=$false)]  
   [string] $FileInternalPath,
   
      [ValidateSet('All','Debug','Info','None')]
     [Parameter(Mandatory=$false)]  
   [string] $Console='None',
   
     [Parameter(Mandatory=$false)]  
   [string] $Scope=2
  )

  $Repository=Get-DefaultRepositoryName
  
  Start-Log4Net -DefaultConfiguration

#  Register-PSObjectRenderer $Repository  
  
  if ($PSBoundParameters.ContainsKey('FileExternalPath'))
  { Switch-AppenderFileName -RepositoryName $Repository FileExternal $FileExternalPath }
  
  if ($PSBoundParameters.ContainsKey('FileInternalPath'))
  { Switch-AppenderFileName -RepositoryName $Repository FileInternal $FileInternalPath }
  
  Set-Variable -Name DebugLogger -Value ([LogManager]::GetLogger('DebugLogger')) -Scope $Scope
  Set-Variable -Name InfoLogger -Value ([LogManager]::GetLogger('InfoLogger')) -Scope $Scope
  
  If (($Console -eq 'All') -or ($Console -eq 'Info')) 
  { Start-ConsoleAppender $InfoLogger }
  
  If (($Console -eq 'All') -or ($Console -eq 'Debug')) 
  { Start-ConsoleAppender $DebugLogger }
  
  If ($Console -eq 'None') 
  { 
    $InfoLogger,$DebugLogger |
     Stop-ConsoleAppender  
  }  
}#Initialize-Log4NetScript

function Switch-AppenderFileName{
#Modifie le nom du fichier associé au FileAppender 
#nommés $AppenderName d'un repository $Name
[CmdletBinding(DefaultParameterSetName="NewName")]
 param(
      [ValidateNotNullOrEmpty()]
      [Parameter(Mandatory=$true,ValueFromPipeline = $true)]
   [String] $RepositoryName, #Nom du repository, par convention est identique au nom du module. 
  
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=1, Mandatory=$false)]  
    #Par défaut nom de l'appender dédié aux logs fonctionnels de chaque module utilisant Log4Posh
   [string] $AppenderName="FileExternal",
  
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=2, Mandatory=$true,ParameterSetName="NewName")]    
   [string] $NewFileName,
    
    [Parameter(ParameterSetName="Default")]
   [switch] $Default
 )

 process { 
   if ($PsCmdlet.ParameterSetName -eq "Default")
   { $NewFileName=Get-DefaultAppenderFileName $RepositoryName } 
   
   [LogManager]::GetRepository($RepositoryName)|
     Get-Log4NetFileAppender -AppenderName $AppenderName|
     Set-Log4NetAppenderFileName -NewFileName $NewFileName
 }#process
}#Switch-AppenderFileName

# ----------- Suppression des objets du Wrapper -------------------------------------------------------------------------
function OnRemoveLog4Posh {
   #Remove shortcuts
  $LogShortCut.GetEnumerator() |
    Foreach-Object {
     Try {
       Write-Debug "Remove TypeAccelerators $($_.Key)"
       [void]$AcceleratorsType::Remove($_.Key)
     } Catch {
       write-Error $_.Exception.Message
     }
  }
}

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { OnRemoveLog4Posh } 
$MyInvocation.MyCommand.ScriptBlock.Module.AccessMode="ReadOnly"

$F=@(
 'ConvertTo-Log4NetCoreLevel',
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
# 'Register-PSObjectRenderer',
 'Start-Log4Net',
 'Stop-Log4Net',
 'Set-Log4NetAppenderFileName',
 'Set-Log4NetRepositoryThreshold',
 'Set-Log4NetLoggerLevel',
 'Set-Log4NetAppenderThreshold',
 'Stop-ConsoleAppender',
 'Start-ConsoleAppender',
 'Switch-AppenderFileName',
 'Test-Repository'
)


Set-Alias -name saca  -value Start-ConsoleAppender
Set-Alias -name spca  -value Stop-ConsoleAppender
Set-Alias -name swtafn  -value Switch-AppenderFileName
#Set-Alias -name Add-PSObjectRenderer -value Add-Log4NetPSObjectRenderer

Export-ModuleMember -Variable LogDefaultColors,LogJobName  -Alias * -Function $F
