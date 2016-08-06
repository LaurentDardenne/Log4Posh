#Log4Posh.psm1
# !!! ATTENTION !!! les noms de repository sont sensibles � la casse

Import-LocalizedData -BindingVariable Log4PoshMsgs -Filename Log4Posh.Resources.psd1 -EA Stop

# ------------ Initialisation et Finalisation  ----------------------------------------------------------------------------

$ClrVersion=[System.Reflection.Assembly]::Load("mscorlib").GetName().Version.ToString(2)
Add-Type -Path "$psScriptRoot\$ClrVersion\log4net.dll" #"$psScriptRoot\$($PSVersionTable.PSVersion)\Log4PoshTools.dll"

Function Get-ParentProcess {
#Permet de retrouver le process parent ayant ex�cut� 
#la session Powershell ex�cutant ce script/module
 param( $ID )
 $ParentID=$ID         
 $Result=@(
   Do {
     $Process=Get-WmiObject Win32_Process -Filter "ProcessID='$parentID'" -property Name,CommandLine,ParentProcessID
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

  #Propri�t� statique, indique le process PowerShell courant
  #Dans un job local ce n'est pas le process courant, mais le parent 
[log4net.GlobalContext]::Properties.Item("Owner")=$_pid
[log4net.GlobalContext]::Properties.Item("RunspaceId")=$ExecutionContext.Host.Runspace.InstanceId

  #Propri�t� dynamique, Log4net appel la m�thode ToString de l'objet r�f�renc�.
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
#Configure un repository � l'aide d'un fichier de configuration XML
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
 #todo
# See FAQ To prevent silent failure of log4net as reported as LOG4NET-342, ... 
# 
# if(-not [LogManager]::GetRepository().Configured){
# 	[LogManager]::GetRepository("Repo").ConfigurationMessages

}#Start-Log4Net

Function Stop-Log4Net {
#On arr�te proprement les loggers d'un repository,
#on vide les buffers, puis on r�initialise le repository.
 param (
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$false)]
   [string] $RepositoryName=$(Get-DefaultRepositoryName)
 )
 Write-Debug "Close the repository '$RepositoryName'"
 if (-not (Test-Repository $RepositoryName))
 {throw ($Log4PoshMsgs.RepositoryDoNotExist -F $RepositoryName) } 
  
 [LogManager]::GetRepository($RepositoryName).GetAppenders()|
  Where {$_ -is  [log4net.Appender.BufferingAppenderSkeleton]}|
  Foreach {
   Write-Debug "Flush appender $($_.Name)"           
    $_.Flush() 
  }
   #Shutdown() est appel� en interne, tous les appenders sont ferm�s proprement,
   #le repository par d�faut n'est plus configur�
 [LogManager]::ResetConfiguration($RepositoryName) 
}#Stop-Log4Net

# todo : tjr utile ?
# Function Register-PSObjectRenderer {
#  #Enregistre le type [PSLog4NET.PSObjectRenderer] impl�mentant l'interface IObjectRenderer. 
#  #Le type [PSLog4NET.PSObjectRenderer] appel en interne la m�thode tostring() du psobject,
#  #celle peut �tre r�d�finie via ETS:
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
#Chaque repository peut d�clarer de nouveaux niveaux
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
   Where {$_ -ne $Null}|
   Foreach  {
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
   If ($Logger -ne $null)
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
   If ($Logger -ne $null)
   { 
      $logger.Logger.Appenders|
       Where { $AppenderName -Contains $_.Name }|
       Foreach {
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
 param (
     [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
   [log4net.Core.LogImpl] $Logger 
 )
         
 process {
   Set-Log4NetAppenderThreshold -Logger $Logger 'Console' -DebugLevel
 } 
}#Start-ConsoleAppender

 #D�finition des couleurs d'affichage par d�faut
[System.Collections.Hashtable[]] $script:LogDefaultColors=@(
   @{Level="Debug";FColor="Green";BColor=""},
   @{Level="Info";FColor="White";BColor=""},
   @{Level="Warn";FColor="Yellow,HighIntensity";BColor=""},
   @{Level="Error";FColor="Red,HighIntensity";BColor=""},
   @{Level="Fatal";FColor="Red";BColor="Red,HighIntensity"}
 )

 # ------------- Type Accelerators -----------------------------------------------------------------
function Get-Log4NetShortcuts {
  #Affiche les raccourcis d�di�s � Log4net
 $AcceleratorsType::Get.GetEnumerator()|
  Where {$_.Value.FullName -match "^log4net\.(.*)"}
}#Get-Log4NetShortcuts
 
$AcceleratorsType = [PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")   
 # Ajoute les raccourcis de type    
 Try {
  $LogShortCut.GetEnumerator() |
  Foreach {
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
  
 #Renvoi un logger de nom $Name ou le cr�e s'il n'existe pas. 
 # le nom "Root" est valide et renvoi le root existant
 process {
   foreach ($Current in $Name)
   {
     [LogManager]::GetLogger($Repository.Name,$Current)
   }
 }
} #Get-Log4NetLogger

function Get-Log4NetFileAppender{
#Renvoi d'un repository tout les appender, d�riv�s de la classe FilesAppender, 
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
     Where {
      if ($All)
      {$_.GetType().IsSubclassOf([Log4net.Appender.FileAppender])}
      else 
      {($_.Name -eq $AppenderName) -and  ($_.GetType().IsSubclassOf([Log4net.Appender.FileAppender]))}
     }|
     Foreach { Write-Verbose "Find the appender '$($_.Name)' into the repository '$($Repository.Name)'."; $_}|
     Add-Member NoteProperty -Name RepositoryName -Value $Repository.Name -Force -Passthru
 }#process
}#Get-Log4NetFileAppender

Function Set-Log4NetAppenderFileName {
#Change le nom de fichier d'un appender d�riv� de la classe FileAppender
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
#Si le param�tre -Configured est pr�cis� on indique si le repository est configur�, 
#s'il n'existe pas on d�clenche une exception. 

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
#renvoi le chemin par d�faut du fichier de log d'un module
  Param (
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$true)]
   [string] $ModuleName
  )
         
 $Module=Get-Module $ModuleName
 if ($Module -eq $null) 
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
    #todo pour toutes les fonctions revoir si le repo est configur�       
   $Repository=Get-Log4NetRepository $ModuleName #todo
   if ($Repository -ne $null) 
   { 
     $AppenderName="File$($PsCmdlet.ParameterSetName)"
     $Repository.GetAppenders()|
      Where { $_.Name -eq $AppenderName  }|
      Foreach { 
       Write-Verbose "Find the appender '$($_.Name)' into the repository '$($Repository.Name)'."
       $_.File
      }
   }  
 }
}#Get-Log4NetAppenderFileName
         
function Initialize-Log4NetModule {
#Initialise, pour un module, un repository Log4Net et ses loggers
#Fonction inject�e dans le module utilisant Log4Posh 
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
  
   #Cr�� les variables Logger dans la port�e de l'appelant
   #les noms des loggers sont norm�s
  Set-Variable -Name DebugLogger -Value ([LogManager]::GetLogger($ModuleName,'DebugLogger')) -Scope Script
  Set-Variable -Name InfoLogger -Value ([LogManager]::GetLogger($ModuleName,'InfoLogger')) -Scope Script
  Set-Variable -Name DefaultLogFile -Value "$psScriptRoot\Logs\$ModuleName.log" -Scope Script
  
   #Initialise le nom de fichier des FileAppenders d�di�s au module
  Switch-AppenderFileName -RepositoryName $ModuleName FileInternal $script:DefaultLogFile
  Switch-AppenderFileName -RepositoryName $ModuleName FileExternal $script:DefaultLogFile
}#Initialize-Log4NetModule

function Initialize-Log4NetScript {
#Initialise le repository Log4Net par d�faut 
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
#Modifie le nom du fichier associ� au FileAppender 
#nomm�s $AppenderName d'un repository $Name
[CmdletBinding(DefaultParameterSetName="NewName")]
 param(
      [ValidateNotNullOrEmpty()]
      [Parameter(Mandatory=$true,ValueFromPipeline = $true)]
   [String] $RepositoryName, #Nom du repository, par convention est identique au nom du module. 
  
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=1, Mandatory=$false)]  
    #Par d�faut nom de l'appender d�di� aux logs fonctionnels de chaque module utilisant Log4Posh
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
    Foreach {
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
