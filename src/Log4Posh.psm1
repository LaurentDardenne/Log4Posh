#Log4Posh.psm1
# !!! WARNING !!! Repository names are case sensitive

Import-LocalizedData -BindingVariable Log4PoshMsgs -Filename Log4Posh.Resources.psd1 -EA Stop

# ------------ Initialisation et Finalisation  ----------------------------------------------------------------------------


function Get-DefaultRepositoryName {
<#
    .SYNOPSIS
      This function return the name of the default repository.
#>         
 'log4net-default-repository'
}#Get-DefaultRepositoryName

$script:DefaultRepositoryName=Get-DefaultRepositoryName

if (($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -ne 'Desktop')) 
{
    #$IsCoreCLR
   if (-not $IsWindows)
   { Write-Warning "this OS is not yet tested." }
   Write-Verbose "Loading : $psScriptRoot\core\log4net.dll"    
   Add-Type -Path "$psScriptRoot\core\log4net.dll"

  #todo Test
    #https://windowsserver.uservoice.com/forums/295068-nano-server/suggestions/13870437-powershell-core-add-type-bug-unable-to-locate-cor
    #     #IsNanoServer: from NanoServerPackage.psm1
    #    $operatingSystem = Get-CimInstance -ClassName win32_operatingsystem
    #    $systemSKU = $operatingSystem.OperatingSystemSKU
    #    $script:isNanoServer = ($systemSKU -eq 109) -or ($systemSKU -eq 144) -or ($systemSKU -eq 143)
    #if(IsNanoServer) #pb with Add-Type ?
    # $Dll = [Microsoft.PowerShell.CoreCLR.AssemblyExtensions]::LoadFrom($PSScriptRoot + "\my.coreclr.dll")
    
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


#todo
#https://github.com/PowerShell/PowerShell/issues/2578
# /// suggested alternative (about 100 times faster)
# public static class ProcessInfoUtil
# {
# 	public static System.Diagnostics.Process GetParentProcess() { return ParentProcessId == 0 ? null : System.Diagnostics.Process.GetProcessById(ParentProcessId); }
# 
# 	public static readonly int ParentProcessId = GetParentProcessId();
# 
# 	private static int GetParentProcessId()
# 	{
# 		var pi = new PROCESS_BASIC_INFORMATION();
# 		int actual;
# 		if (0 == NativeMethods.NtQueryInformationProcess(new IntPtr(-1), 0/*processbasicInformation*/, ref pi, pi.Size, out actual))
# 		{
# 			return (int)pi.InheritedFromUniqueProcessId;
# 		}
# 		else 
# 		{
# 			return 0;
# 		}
# 	}
# 
# 	[StructLayout(LayoutKind.Sequential, Pack = 1)]
# 	private struct PROCESS_BASIC_INFORMATION
# 	{
# 		public IntPtr ExitStatus;
# 		public IntPtr PebBaseAddress;
# 		public IntPtr AffinityMask;
# 		public IntPtr BasePriority;
# 		public UIntPtr UniqueProcessId;
# 		public IntPtr InheritedFromUniqueProcessId;
# 
# 		public int Size { get { return Marshal.SizeOf(typeof(PROCESS_BASIC_INFORMATION));}}
# 	}
# 
# 	static class NativeMethods
# 	{
# 	[DllImport("NtDll", SetLastError=true)]
# 	public static extern int NtQueryInformationProcess(IntPtr ProcessHandle, int processInformationClass, ref PROCESS_BASIC_INFORMATION ProcessInformation, int processInformationLength, out int returnLength);
# 	}
# }

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
[log4net.GlobalContext]::Properties.Item("RunspaceId")=[System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId

  #Propriété dynamique, Log4net appel la méthode ToString de l'objet référencé.
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
      This function configures a repository using an XML configuration file
#>    
 [CmdletBinding(DefaultParameterSetName="Path")] 
 param (
    [ValidateNotNullOrEmpty()]
    [Parameter(Position=0, Mandatory=$false,ParameterSetName="Path")]
  [log4net.Repository.ILoggerRepository] $Repository=$([LogManager]::GetRepository($script:DefaultRepositoryName)),
  
    [Parameter(Position=1,Mandatory=$true,ParameterSetName="Path")]  
    [ValidateNotNullOrEmpty()]
  [string] $Path,

    [Parameter(ParameterSetName="Default")]
  [switch] $DefaultConfiguration
 )

 if ($DefaultConfiguration)
 {
   $Path="$psScriptRoot\DefaultLog4Posh.Config.xml"
   $Repository=[LogManager]::GetRepository($script:DefaultRepositoryName)
 } 

 if (Test-Path $Path) 
 { 
    #Need  a full path. Use internally [environment]::currentdirectory
   $Path=$ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($Path)
   $ConfigFile=New-Object System.IO.fileInfo $Path

   Write-debug "Configure the repository '$($Repository.Name)' with  '$Path'" 
   $Result=[Log4net.Config.XmlConfigurator]::Configure($Repository,$ConfigFile)
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
#>   
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

Function ConvertTo-Log4NetCoreLevel {
<#
    .SYNOPSIS
      Converts a level name to an object [Log4Net.Core.Level].
      Each repository can declare new levels.
#>  
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
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]

<#
    .SYNOPSIS
      Change the log level of a repository
#> 
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
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
<#
    .SYNOPSIS
      Change the log level of a logger
#> 
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
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="Log4net do not change the system state, only the application 'context'")]
<#
    .SYNOPSIS
      Change the log level of a appender
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
      The name 'Root' is valid.
#>           
  Param (   
      [ValidateNotNullOrEmpty()]
      [Parameter(Position=0,Mandatory=$True,ValueFromPipeline = $true)] 
    [log4net.Repository.ILoggerRepository] $Repository=$([Log4net.LogManager]::GetRepository($script:DefaultRepositoryName)),
    
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
<#
    .SYNOPSIS
     Returns a repository to all append, derived from the FilesAppender class, whose name is $AppenderName
#>  
 param(
      [ValidateNotNullOrEmpty()]
      [Parameter(Position=0,Mandatory=$True,ValueFromPipeline = $true)]
   [log4net.Repository.ILoggerRepository] $Repository=$([Log4net.LogManager]::GetRepository($script:DefaultRepositoryName)),

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
     Return the default path of the log file of a module*
#> 
  Param (
     [ValidateNotNullOrEmpty()]
     [Parameter(Position=0, Mandatory=$true)]
   [string] $ModuleName
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
      Returns the current path of the internal (debug) or external (functional) log file of a module
#> 
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
   $Repository=Get-Log4NetRepository $ModuleName 
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
<#
    .SYNOPSIS
     Initializes, for a module, a Log4Net repository and its loggers
     This function is injected into the module using Log4Posh      
#> 
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
     [Parameter(Position=2, Mandatory=$True)]  
   [string] $DefaultLogFilePath
  )
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

  $ParentPath=Split-Path $DefaultLogFilePath -parent
  if (-not (Test-Path $ParentPath))
  { New-Item -Path $ParentPath -ItemType Directory }
  Set-Variable -Name DefaultLogFile -Value $DefaultLogFilePath -Scope Script
  
   #Initialise le nom de fichier des FileAppenders dédiés au module
  Switch-AppenderFileName -RepositoryName $RepositoryName FileInternal $script:DefaultLogFile
  Switch-AppenderFileName -RepositoryName $RepositoryName FileExternal $script:DefaultLogFile
}#Initialize-Log4NetModule

function Initialize-Log4NetScript {
<#
    .SYNOPSIS
      Initializes the default Log4Net repository      
#> 
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
   #Nom du repository, par convention est identique au nom du module.
      [ValidateNotNullOrEmpty()]
      [Parameter(Mandatory=$true,ValueFromPipeline = $true)]
   [String] $RepositoryName,  
  
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

# Configuration du debug interne au framework log4Net 
# https://logging.apache.org/log4net/release/faq.html 
function Set-LogDebugging{
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                   Justification="Log4net do not change the system state, only the application 'context'")]
         
<#
    .SYNOPSIS
      Enables log4Net framework internal debugging       
#>     
 param ( 
   [switch] $Off
 )

 $State = -not $Off.IsPresent  
 [log4net.Util.LogLog]::InternalDebugging=$State
#  todo Add. Config file or by code ?
#  <system.diagnostics>
#     <trace autoflush="true">
#         <listeners>
#             <add 
#                 name="textWriterTraceListener" 
#                 type="System.Diagnostics.TextWriterTraceListener" 
#                 initializeData="C:\tmp\log4net.txt" />
#         </listeners>
#     </trace>
# </system.diagnostics>
}

function Get-LogDebugging{
<#
    .SYNOPSIS
      Disables log4Net framework internal debugging       
#>             
 [log4net.Util.LogLog]::InternalDebugging
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
 
