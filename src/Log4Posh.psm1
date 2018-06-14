#Log4Posh.psm1
# !!! Pay attention to the repositories name AND Loggers name, they are case sensitive.

Import-LocalizedData -BindingVariable Log4PoshMsgs -Filename Log4Posh.Resources.psd1 -EA Stop

function Get-DefaultRepositoryName {
<#
    .SYNOPSIS
      This function return the name of the default repository.
#>
 'log4net-default-repository'
}#Get-DefaultRepositoryName

function Get-DefaultRepository {
  <#
      .SYNOPSIS
        This function return the default repository.
  #>
  [LogManager]::GetRepository($script:DefaultRepositoryName)
}#Get-DefaultRepository

$script:DefaultRepositoryName=Get-DefaultRepositoryName

if (($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -ne 'Desktop'))
{
    #$IsCoreCLR
   if (-not $IsWindows)
   { Write-Warning "this OS is not yet tested." }
   Write-Verbose "Loading : $psScriptRoot\core\log4net.dll"
   Add-Type -Path "$psScriptRoot\core\log4net.dll"

    #The method GetLoggerRepository() do not exist because GetCallingAssembly() is
    # not available in CoreFX (https://github.com/dotnet/corefx/issues/2221).
   #Create default repository
  [log4net.LogManager]::CreateRepository($script:DefaultRepositoryName) > $null
}
else
{
  $ClrVersion=[System.Reflection.Assembly]::Load("mscorlib").GetName().Version.ToString(2)
  Write-Verbose "Loading : $psScriptRoot\$ClrVersion\log4net.dll"
  Add-Type -Path "$psScriptRoot\$ClrVersion\log4net.dll"
     #Creating indirectly the default repository
  [log4net.LogManager]::GetRepository() > $null
}


Function Get-ParentProcess {
  <#
      .SYNOPSIS
        Retrieves the parent process that ran the Powershell session running this script / module
  #>
 param(
     # process ID from which the parent is searched.
    $Id
  )
 $ParentID=$Id
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
 {$ParentPID= (Get-ParentProcess  $PID)[0].Id}
 else
 {$ParentPID= $pid}

 # Static property, indicates the current PowerShell process.
 # Inside a local job it is not the current process, but the parent.
[log4net.GlobalContext]::Properties.Item("Owner")=$ParentPID
[log4net.GlobalContext]::Properties.Item("RunspaceId")=[System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId

 # Dynamic property, Log4net calls the ToString() method of the referenced object.
  $Script:LogJobName= new-object System.Management.Automation.PSObject -Property @{Value=$ExecutionContext.Host.Name}
  $Script:LogJobName|Add-Member -Force -MemberType ScriptMethod ToString { $this.Value.toString() }
[log4net.GlobalContext]::Properties["LogJobName"]=$Script:LogJobName

$LogShortCut=@{
  LogManager = [log4net.LogManager];
  LogBasicCnfg = [log4net.Config.BasicConfigurator];
  LogXmlCnfg = [log4net.Config.XmlConfigurator];
  LogLevel = [log4net.Core.Level];
  LogThreadContext = [log4net.ThreadContext];
  LogGlobalContext = [log4net.GlobalContext];
}

if (($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -eq 'Desktop'))
{
  $LogShortCut.LogColoredConsole = [log4net.Appender.ColoredConsoleAppender]
  $LogShortCut.LogColors = [log4net.Appender.ColoredConsoleAppender+Colors];
  $LogShortCut.LogMailPriority = [System.Net.Mail.MailPriority];
  $LogShortCut.LogSmtpAuthentication = [log4net.Appender.SmtpAppender+SmtpAuthentication]
}


Function Start-Log4Net {
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
<#
    .SYNOPSIS
      This function configure a repository using an XML configuration file
#>
 [CmdletBinding(DefaultParameterSetName="Path")]
 param (
   #The repository to configure. The default value is the default repository (see Get-DefaultRepositoryName)
    [ValidateNotNullOrEmpty()]
    [Parameter(Position=0, Mandatory=$false,ParameterSetName="Path")]
  [log4net.Repository.ILoggerRepository] $Repository=$([LogManager]::GetRepository($script:DefaultRepositoryName)),

    #Path of the XML configuration file
    [Parameter(Position=1,Mandatory=$true,ParameterSetName="Path")]
    [ValidateNotNullOrEmpty()]
  [string] $Path,

    #Use the default XML configuration file : ModulePath\DefaultLog4Posh.Config.xml
    [Parameter(ParameterSetName="Default")]
  [switch] $DefaultConfiguration
 )

 if ($DefaultConfiguration)
 {
   $Path="$psScriptRoot\DefaultLog4Posh.Config.xml"
   Write-debug "Configure the repository '$($script:DefaultRepositoryName)' with  '$Path'"
   $Repository=[LogManager]::GetRepository($script:DefaultRepositoryName)
 }

 if (Test-Path $Path)
 {
    #Need a full path. Use internally [environment]::currentdirectory
   $Path=$ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($Path).ProviderPath
   $ConfigFile=New-Object System.IO.fileInfo $Path

   Write-debug "Configure the repository '$($Repository.Name)' with  '$Path'"
   # Result contains Loglog instances.
    #Prefix member is a string indicating the severity of the internal message.
    # Possible values : "log4net: ", "log4net:ERROR ", "log4net:WARN "
   $Result=[Log4net.Config.XmlConfigurator]::Configure($Repository,$ConfigFile)|Where-Object {$_.Prefix -ne 'log4net: '}
   if ($Result.Count -ne 0 )
   {
      $ofs="`r`n"
      [string]$Message=$Result|Out-String
      $ex=New-Object System.Xml.XmlException $Message
      $ER= New-Object -Typename System.Management.Automation.ErrorRecord -Argumentlist $ex,
                                                                                       'XMLConfigurationFile',
                                                                                       'InvalidData',
                                                                                       $Path
      $PSCmdlet.ThrowTerminatingError($ER)
   }
 }
 else
 {
      $ex=New-Object System.IO.FileNotFoundException "The configuration file do not exist : $Path"
      $ER= New-Object -Typename System.Management.Automation.ErrorRecord -Argumentlist $ex,
                                                                                       'XMLConfigurationFile',
                                                                                       'ObjectNotFound',
                                                                                       $Path
      $PSCmdlet.ThrowTerminatingError($ER)
 }
 # prevent silent failure of log4net
 if(!$Repository.Configured)
 {
 	 Write-Error "Log4net repository $($Repository.Name) is not configured" -ErrorId 'XMLConfigurationFile' -Category InvalidOperation
 	 foreach($message in $Repository.ConfigurationMessages)
 	 { Write-Error "`t$Message" }
 }
}#Start-Log4Net

Function Stop-Log4Net {
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
<#
    .SYNOPSIS
      The loggers of a repository are cleanly stopped, the buffers are emptied, and the repository is then reinitialized.

      Note:
      When the module Log4Posh is removed, [LogManager]::GetAllRepositories() return all repositories with the state NOT CONFIGURED.
#>
 param (
    #The Repository name to configure. The default value is the default repository name (see Get-DefaultRepositoryName)
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
   # Shutdown() method is called internally, all appenders are closed properly,
   # the default repository is no longer configured.
 [LogManager]::ResetConfiguration($RepositoryName)
}#Stop-Log4Net

Function ConvertTo-Log4NetCoreLevel {
<#
    .SYNOPSIS
      Converts a level name to an object [Log4Net.Core.Level].
      Each repository can declare new levels.
#>
 param (
    #The Repository name to configure. The default value is the default repository name (see Get-DefaultRepositoryName)
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$false)]
   [string] $RepositoryName=$(Get-DefaultRepositoryName),

    # The level name to Converts to an object [Log4Net.Core.Level].
     [Parameter(Position=1,Mandatory=$true)]
   [string] $Level
 )
 if (-not (Test-Repository $RepositoryName))
 { throw ($Log4PoshMsgs.RepositoryDoNotExist -F $RepositoryName) }

 $Repository=[LogManager]::GetRepository($RepositoryName)
 $Repository.LevelMap[$Level]
}#ConvertTo-Log4NetCoreLevel

Function Set-Log4NetRepositoryThreshold {
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]

<#
    .SYNOPSIS
      Change the logging threshold of a repository
#>
 [CmdletBinding(DefaultParameterSetName="Level")]
 param (
    #The Repository name to modify.
      [ValidateNotNullOrEmpty()]
      [Parameter(Position=0,Mandatory=$True,ValueFromPipeline = $true)]
    [String] $RepositoryName,

    #The level name used to configure the repository. The default value is 'Info'
     [Parameter(Position=1, ParameterSetName="Level")]
   [string] $Level='Info',

     #Set the log level of a repository with the value 'Off'
     [Parameter(ParameterSetName="off")]
   [switch] $Off,

   #Set the log level of a repository with the value 'Debug'
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
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
<#
    .SYNOPSIS
      Change the logging level of a logger
#>
 [CmdletBinding(DefaultParameterSetName="Level")]
 param (
    #The logger object to modify.
     [Parameter(Mandatory=$true,ValueFromPipeline = $true)]
   [log4net.Core.LogImpl] $Logger,

   #The level name used to configure the logger. The default value is 'Info'
     [Parameter(Position=1, ParameterSetName="Level")]
   [string] $Level='Info',

    #Set the log level of a logger  with the value 'Off'
     [Parameter(ParameterSetName="off")]
   [switch] $Off,

    #Set the log level of a logger with the value 'Debug'
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
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
<#
    .SYNOPSIS
      Change the logging threshold  of a appender
#>
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
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
<#
    .SYNOPSIS
      Change the log level of the 'Console' logger
#>
 param (
     [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
   [log4net.Core.LogImpl] $Logger
 )

 process {
   Set-Log4NetAppenderThreshold -Logger $Logger 'Console' -Off
 }
}#Stop-ConsoleAppender

Function Start-ConsoleAppender {
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
<#
    .SYNOPSIS
      Start the 'Console' logger
#>
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
function Get-Log4NetShortcut {
  #Affiche les raccourcis dédiés à Log4net
 $AcceleratorsType::Get.GetEnumerator()|
  Where-Object {$_.Value.FullName -match "^log4net\.(.*)"}
}#Get-Log4NetShortcut

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

<#
    .SYNOPSIS
      Returns one or more loggers from the repository $Repository.
      If the named logger already exists, then the existing instance will be returned. Otherwise, a new instance is created.
      The name 'Root' is valid.

      By default, loggers do not have a set level but inherit it from the hierarchy. This is one of the central features of log4net.
#>
  [CmdletBinding(DefaultParameterSetName="All")]
  [outputType([Log4net.ILog])]
  Param (
      #This is to the name of the repository
      [ValidateNotNullOrEmpty()]
      [Parameter(Position=0,Mandatory=$True,ValueFromPipeline = $true)]
    [log4net.Repository.ILoggerRepository] $Repository,

      [ValidateNotNullOrEmpty()]
      [Parameter(Position=1,Mandatory=$True,ParameterSetName='Name')]
    [String[]] $Name,

    [Parameter(Position=1,Mandatory=$True,ParameterSetName='All')]
    [Switch]$All
  )

 process {
  if ($PsCmdlet.ParameterSetName -eq 'Name')
  {
    foreach ($Current in $Name)
    { [LogManager]::GetLogger($Repository.Name,$Current) }
  }
  else
  {
    #Note: GetCurrentLoggers return all loggers but in a different type as Getlogger
    foreach ($Current in [LogManager]::GetRepository($Repository.Name).GetCurrentLoggers().Name)
    { [LogManager]::GetLogger($Repository.Name,$Current) }
  }
 }
} #Get-Log4NetLogger

function Get-Log4NetFileAppender{
<#
    .SYNOPSIS
     Search in a repository all appenders, derived from the FilesAppender class.
#>
 param(
      #The name of the repository where to look for appenders.
      [ValidateNotNullOrEmpty()]
      [Parameter(Position=0,Mandatory=$True,ValueFromPipeline = $true)]
    [log4net.Repository.ILoggerRepository] $Repository,

    #Return the appender whose name is $AppenderName
    #Default value is 'FileExternal'.
    [ValidateNotNullOrEmpty()]
    [Parameter(Position=1,Mandatory=$false)]
   [string] $AppenderName="FileExternal",

    #Return all appenders for a repository.
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
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                   Justification="Log4net do not change the system state, only the application 'context'")]
<#
    .SYNOPSIS
     Change the file name of an appender derived from the 'FileAppender' class
#>
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

function Get-Log4NetRepository {
<#
    .SYNOPSIS
      Returning a repository by its name
#>
 #[outputType([log4net.Repository.ILoggerRepository])]

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
<#
    .SYNOPSIS
      Indicates whether the repository exists or not.
      If the -Configured parameter specifies whether the repository is configured, if it does not exist, an exception is raised.
#>
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
  {
      $msg=$Log4PoshMsgs.RepositoryDoNotExist -F $RepositoryName
      $ex=new-object System.Exception $msg
      $ER= New-Object -Typename System.Management.Automation.ErrorRecord -Argumentlist $ex,
                                                                                       'RepositoryNotConfigured',
                                                                                       'ResourceUnavailable',
                                                                                       $RepositoryName
      $PSCmdlet.ThrowTerminatingError($ER)
  }
  else
  { [LogManager]::GetRepository($RepositoryName).Configured }
 }
 else
 { $isExist }
}#Test-Repository

function Get-DefaultAppenderFileName {
<#
    .SYNOPSIS
     Return the default path of the log file of a module.
#>
  Param (
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$true)]
   [string] $ModuleName #todo default for script ? $RepositoryName = $MyInvocation.ScriptName avec ou sans .ps1
                        #convention $lg4n_ScriptName
  )

 $Module=Get-Module $ModuleName
 if ($null -eq $Module)
 { Write-Error ($Log4PoshMsgs.ModuleDoNotImported -F $ModuleName) }
 else
 {
   $Fi=New-object System.IO.FileInfo $Module.Path
   "{0}\Logs\{1}.log" -F $Fi.Directory,$Fi.BaseName
 }
}#Get-DefaultAppenderFileName

function Get-Log4NetAppenderFileName {
<#
    .SYNOPSIS
      Returns the current path of the internal (debug) or/and external (functional) log file of a module
#>
  [CmdletBinding(DefaultParameterSetName="External")]
  Param (
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
     [Alias('ModuleName')]
   [string] $RepositoryName,

    [Parameter(ParameterSetName="External")]
   [switch] $External,

    [Parameter(ParameterSetName="Internal")]
   [switch] $Internal,

    [Parameter(ParameterSetName="All")]
   [switch] $All
  )

 process {
   $Repository=Get-Log4NetRepository $RepositoryName
   if ($null -ne $Repository)
   {
     if ($PsCmdlet.ParameterSetName -eq 'All')
     { $Pattern="FileExternal|FileInternal" }
     else
     { $Pattern="File$($PsCmdlet.ParameterSetName)" }
     $Repository.GetAppenders()|
      Where-Object { $_.Name -match $Pattern  }|
      Foreach-Object {
       Write-Verbose "Find the appender '$($_.Name)' into the repository '$($Repository.Name)'."
       $_.File
      }
   }
 }
}#Get-Log4NetAppenderFileName

function Initialize-Log4Net {
<#
    .SYNOPSIS
     Initializes a Log4Net repository and its loggers.
     By default, initializes log4posh for a script and configure the default Log4Net repository.
     To configure Log4Posh with a xml file, use the -XmlConfigPath parameter (for a module, a script or a job).

     For a module, this function is injected into the module using Log4Posh. By Default the repository name is the name of caller module.

#>
  [CmdletBinding(DefaultParameterSetName="DefaultConfiguration")]

  Param (
     #Name of the module to initialize todo module/script
     #This is to the name of the repository
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$true,ParameterSetName="XmlConfiguration")]
   [string] $RepositoryName,

     #Name of the config.xml
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=1, Mandatory=$True,ParameterSetName="XmlConfiguration")]
   [string] $XmlConfigPath,

     #Path of default log file
     #The directory is created if it do not exist
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=2,ParameterSetName="XmlConfiguration")]
   [string] $DefaultLogFilePath,

     #Path of file used by the RollingFileAppender associated with logger $InfoLogger.
     #This logger is dedicated to functional debug traces.
     #
     #By default the FileExternal and FileInternal appenders use the same file,
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=1, Mandatory=$false,ParameterSetName="DefaultConfiguration")]
   [string] $FileExternalPath,

     #Path of file used by the RollingFileAppender associated with logger $DebugLogger.
     #This logger is dedicated to internal debug traces.
     #
     #By default the FileExternal and FileInternal appenders use the same file,
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=2, Mandatory=$false,ParameterSetName="DefaultConfiguration")]
   [string] $FileInternalPath,

     #Configure the console appender.
     #
     # All   : Start the console appender for the $InfoLogger and $DebugLogger loggers
     # Debug : Start the console appender for the $DebugLogger logger
     # Info  : Start the console appender for the $InfoLogger  logger
     # None  : Stop the console appender for the  $InfoLogger and $DebugLogger loggers
     [ValidateSet('All','Debug','Info','None')]
     [Parameter(Mandatory=$false,ParameterSetName="DefaultConfiguration")]
   [string] $Console='None',

     #The number of the scope where create the $DebugLogger and $InfoLogger variable.
     #The default value is 2
     #[Parameter(Mandatory=$false,ParameterSetName="DefaultConfiguration")]
   [string] $Scope=2
  )

 if ($PsCmdlet.ParameterSetName -eq 'XmlConfiguration')
 {
    Write-debug "with XmlConfiguration : $RepositoryName -> $XmlConfigPath"
    if (Test-Repository $RepositoryName)
    {
     $Repository=[LogManager]::GetRepository($RepositoryName)
     Write-debug "Reset repository: '$Repository'"
     $Repository.ResetConfiguration()
    }
    else
    {
      Write-debug "Create repository: '$RepositoryName'"
      $Repository=[LogManager]::CreateRepository($RepositoryName)
    }

    Start-Log4Net $Repository $XmlConfigPath

     #Créé les variables Logger dans la portée de l'appelant
     #les noms des loggers sont normés
    Write-debug "Set loggers variable in scope : $scope"
    Set-Variable -Name DebugLogger -Value ([LogManager]::GetLogger($RepositoryName,'DebugLogger')) -Scope $Scope
    Set-Variable -Name InfoLogger -Value ([LogManager]::GetLogger($RepositoryName,'InfoLogger')) -Scope $Scope

    if ($PSBoundParameters.ContainsKey('DefaultLogFilePath'))
    {
      $ParentPath=Split-Path $DefaultLogFilePath -parent
      Write-debug "with DefaultLogFilePath : '$DefaultLogFilePath'"
      if (-not (Test-Path $ParentPath))
      {
        Write-debug "with create parentpath :'$ParentPath'"
        New-Item -Path $ParentPath -ItemType Directory
      }

       #Initialise le nom de fichier des FileAppenders dédiés au module
      Switch-AppenderFileName -RepositoryName $RepositoryName FileInternal $DefaultLogFilePath
      Switch-AppenderFileName -RepositoryName $RepositoryName FileExternal $DefaultLogFilePath
    }
 }

 if ($PsCmdlet.ParameterSetName -eq 'DefaultConfiguration')
 {

    $RepositoryName=$script:DefaultRepositoryName
    Write-debug "with DefaultConfiguration : '$RepositoryName'"
    Start-Log4Net -DefaultConfiguration

    if ($PSBoundParameters.ContainsKey('FileExternalPath'))
    {
       Write-debug "FileExternal: '$FileExternalPath'"
       Switch-AppenderFileName -RepositoryName $RepositoryName FileExternal $FileExternalPath
    }

    if ($PSBoundParameters.ContainsKey('FileInternalPath'))
    {
      Write-Debug "FileInternal : '$FileInternalPath'"
      Switch-AppenderFileName -RepositoryName $RepositoryName FileInternal $FileInternalPath
    }

    Write-debug "Set loggers variable in scope : $scope"
    Set-Variable -Name DebugLogger -Value ([LogManager]::GetLogger($RepositoryName,'DebugLogger')) -Scope $Scope
    Set-Variable -Name InfoLogger -Value ([LogManager]::GetLogger($RepositoryName,'InfoLogger')) -Scope $Scope

    If (($Console -eq 'All') -or ($Console -eq 'Info'))
    { Start-ConsoleAppender $InfoLogger }

    If (($Console -eq 'All') -or ($Console -eq 'Debug'))
    { Start-ConsoleAppender $DebugLogger }

    If ($Console -eq 'None')
    {
      $InfoLogger,$DebugLogger |
       Stop-ConsoleAppender
    }
 }
}

function Initialize-Log4NetModule {
<#
    .SYNOPSIS
     Initializes, for a module, a Log4Net repository and its loggers
     This function is injected into the module using Log4Posh
#>
  [Obsolete("Use the 'Initialize-Log4Net' function instead.")]
  Param (
     #Name of the module to initialize
     #This is to the name of the repository
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$true)]
   [string] $RepositoryName,

     #Name of the config.xml
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=1, Mandatory=$True)]
   [string] $XmlConfigPath,

     #Path of default log file
     #The directory is created if it do not exist
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=2)]
   [string] $DefaultLogFilePath
  )
  function getDefaultFileName {
    $FileName=($DebugLogger.Logger.Appenders|Where-Object {$_.Name -eq 'FileInternal'}).File
    if ($FileName -eq ($InfoLogger.Logger.Appenders|Where-Object {$_.name -eq 'FileExternal'}).File)
    {
      return $Filename
    }
    else
    { return $null}
  }

  if (Test-Repository $RepositoryName)
  {
   $Repository=[LogManager]::GetRepository($RepositoryName)
   $Repository.ResetConfiguration()
  }
  else
  { $Repository=[LogManager]::CreateRepository($RepositoryName) }

  Start-Log4Net $Repository $XmlConfigPath

   #Créé les variables Logger dans la portée de l'appelant
   #les noms des loggers sont normés
  Set-Variable -Name DebugLogger -Value ([LogManager]::GetLogger($RepositoryName,'DebugLogger')) -Scope Script
  Set-Variable -Name InfoLogger -Value ([LogManager]::GetLogger($RepositoryName,'InfoLogger')) -Scope Script

  if ($PSBoundParameters.ContainsKey('DefaultLogFilePath'))
  {
    $ParentPath=Split-Path $DefaultLogFilePath -parent
    if (-not (Test-Path $ParentPath))
    { New-Item -Path $ParentPath -ItemType Directory }

    Set-Variable -Name DefaultLogFile -Value $DefaultLogFilePath -Scope Script

     #Initialise le nom de fichier des FileAppenders dédiés au module
    Switch-AppenderFileName -RepositoryName $RepositoryName FileInternal $script:DefaultLogFile
    Switch-AppenderFileName -RepositoryName $RepositoryName FileExternal $script:DefaultLogFile
  }
  else
  {
    Set-Variable -Name DefaultLogFile -Value (getDefaultFileName) -Scope Script
  }
}#Initialize-Log4NetModule

function Initialize-Log4NetScript {
<#
    .SYNOPSIS
      Initializes the default Log4Net repository
#>
 [Obsolete("Use the 'Initialize-Log4Net' function instead.")]
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

  $RepositoryName=$script:DefaultRepositoryName

  Start-Log4Net -DefaultConfiguration

  if ($PSBoundParameters.ContainsKey('FileExternalPath'))
  { Switch-AppenderFileName -RepositoryName $RepositoryName FileExternal $FileExternalPath }

  if ($PSBoundParameters.ContainsKey('FileInternalPath'))
  { Switch-AppenderFileName -RepositoryName $RepositoryName FileInternal $FileInternalPath }

  Set-Variable -Name DebugLogger -Value ([LogManager]::GetLogger($RepositoryName,'DebugLogger')) -Scope $Scope
  Set-Variable -Name InfoLogger -Value ([LogManager]::GetLogger($RepositoryName,'InfoLogger')) -Scope $Scope

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
<#
    .SYNOPSIS
      Modifies the name of the file associated with the FileAppender named $AppenderName of a repository $Name
#>
[CmdletBinding(DefaultParameterSetName="NewName")]
 param(
    #Name of the repository.
      [ValidateNotNullOrEmpty()]
      [Parameter(Mandatory=$true,ValueFromPipeline = $true)]
   [String] $RepositoryName,

    #The name of the appender dedicated to the functional logs of each module/script using Log4Posh
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=1, Mandatory=$false)]
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

# Configuration du debug interne au framework log4Net
# https://logging.apache.org/log4net/release/faq.html
function Set-LogDebugging{
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                   Justification="Log4net do not change the system state, only the application 'context'")]

<#
    .SYNOPSIS
      Set the internal debugging for the log4Net framework
#>
 param (
   [switch] $Off
 )

 $State = -not $Off.IsPresent
 [log4net.Util.LogLog]::InternalDebugging=$State
}

function Get-LogDebugging{
<#
    .SYNOPSIS
      Get the internal debugging for the log4Net framework
#>
 [log4net.Util.LogLog]::InternalDebugging
}

Function New-Log4NetCoreLevel {
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
<#
    .SYNOPSIS
     Create a new level.
     Levels have a numeric Value that defines the relative ordering between levels. Two Levels with the same Value are deemed to be equivalent.
     The levels that are recognized by log4net are set for each Repository and each repository can have different levels defined.

     The levels are stored in the LevelMap on the repository :
      $Repository.LevelMap.AllLevels
      $Repository.LevelMap['Debug']
#>
  Param (
     #Name of the module to initialize
     #This is to the name of the repository
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$true)]
   [string] $RepositoryName,

    #Levels have a numeric Value that defines the relative ordering between levels. Two Levels with the same Value are deemed to be equivalent.
    [Parameter(Position=1, Mandatory=$true)]
   [int] $Level,

    #Name of the level
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=2, Mandatory=$true)]
   [string] $LevelName,

    #Each level has a DisplayName in addition to its Name. The DisplayName is the string that is written into the output log.
    #By default the display name is the same as the level name, but this can be used to alias levels or to localize the log output.
     [Parameter(Position=3)]
   [string] $DisplayName
  )

    $Repository=[LogManager]::GetRepository($RepositoryName)
    if ($PSBoundParameters.ContainsKey('DisplayName'))
    { $ScriptLevel= new-object log4net.Core.Level $Level,$LevelName,$DisplayName }
    else
    { $ScriptLevel= new-object log4net.Core.Level $Level,$LevelName }
    $Repository.LevelMap.Add($ScriptLevel)
}

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


Set-Alias -name saca  -value Start-ConsoleAppender
Set-Alias -name spca  -value Stop-ConsoleAppender

Export-ModuleMember -Variable * -Function * -Alias *
