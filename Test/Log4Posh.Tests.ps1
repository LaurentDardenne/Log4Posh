
Import-Module  "..\Release\Log4Posh\Log4Posh.psd1" -Force -Global
Import-Module  "..\Release\Log4Posh\Demos\Module1\Module1.psd1" -Global

Describe "Log4Posh standalone - basic" {

 Context "When there is no error" {

  It "Log4Net assemblie loaded, [LogManager] must existed"{
    [log4net.LogManager] -eq [LogManager] | Should Be $true
  }
 
  It "The default repository name is exactly 'log4net-default-repository'" {
    Get-DefaultRepositoryName|Should BeExactly 'log4net-default-repository'
  }
  
  It "The names of a repository is case sensitive" {
    { [LogManager]::GetRepository('log4net-default-repository') } | Should Not Throw 
    { [LogManager]::GetRepository('Log4net-default-repository') } | Should Throw 
  }

  #todo si PS v6 portable
  # if (($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -eq 'Desktop')) 
  #  { $LogShortCut.LogColoredConsole = [log4net.Appender.ColoredConsoleAppender] ...

  It "Start-Log4Net configure a repository with a xml file" { 
    if (Test-Repository 'Test')
    { 
       Stop-Log4Net -Repository 'Test' 
       $Repository=[LogManager]::GetRepository('Test')
    }
    else
    { $Repository=[LogManager]::CreateRepository('Test') }
    
    Start-Log4Net -Repository $Repository -Path "$PSScriptRoot\BasicLog4Posh.Config.xml"
    Test-Repository 'Test' -Configured | Should Be $true 
  }
 
  It "Must exist one appender"{   
    $Repository=[LogManager]::GetRepository('Test')   
    $Repository.GetAppenders().Count| Should be 1
  }
  
  It "Must exist two logger"{     
    $Repository=[LogManager]::GetRepository('Test')   
    $Repository.GetCurrentLoggers().Count| Should be 2
  }
 
  It "Must loggers are not null"{  
    [LogManager]::GetLogger('Test','DebugLogger')|Should Not BeNullOrEmpty
    [LogManager]::GetLogger('Test','InfoLogger')|Should Not BeNullOrEmpty
  }
  It "Must TypeData loaded"{  
    Get-TypeData log4net.Core.LogImpl|Should Not BeNullOrEmpty
  }
 
  It "Must logger works"{  
    $DebugLogger=[LogManager]::GetLogger('Test','DebugLogger')
    {$DebugLogger.PSDebug('Message - Console - Main context')}| Should Not Throw 
    #todo file
  }
 
  It "Must enable the console appender, then disabled it"{
    $DebugLogger=[LogManager]::GetLogger('Test','DebugLogger')
    $Appender=$DebugLogger.Logger.Appenders | Where-Object { $_.Name -eq 'Console'}
     $Appender.Threshold|Should Be 'Debug'
    Stop-ConsoleAppender -Logger $DebugLogger
     $Appender.Threshold|Should Be 'Off'  
    Start-ConsoleAppender -Logger $DebugLogger
     $Appender.Threshold|Should Be 'Debug'
  }

  It "Must convert a string to Log4Net.Core.Level" {
    $Repository=[LogManager]::GetRepository('Test')
    $Result=ConvertTo-Log4NetCoreLevel -Repository $Repository.Name 'Debug'
    $Result.Equals([Log4net.Core.Level]::Debug)
    
    $ScriptLevel= new-object log4net.Core.Level 41000,'SCRIPT'
    $Repository.LevelMap.Add($ScriptLevel)
    $Result=ConvertTo-Log4NetCoreLevel -Repository $Repository.Name 'SCRIPT'
    $Result.Equals($ScriptLevel) 
  }
  
  It "Must reset the configuration of the 'Test' repository" {
    Test-Repository 'Test' -Configured | Should Be $true
    Stop-Log4Net -RepositoryName 'Test'
    Test-Repository 'Test' -Configured | Should Be $false
    $Repository=[LogManager]::GetRepository('Test')
    $Repository.GetAppenders().Count | Should Be 0
  }
  
  It "Start-Log4Net reconfigure the repository 'Test' with a new xml file" { 
    if (Test-Repository 'Test')
    { Stop-Log4Net -Repository 'Test' }
    $Repository=[LogManager]::GetRepository('Test') 
    Start-Log4Net -Repository $Repository -Path "$PSScriptRoot\ThreeAppenders.Config.xml"
    Test-Repository 'Test' -Configured | Should Be $true 
  }
 
  It "Must exist three appender"{   
    $Repository=[LogManager]::GetRepository('Test')   
    $Repository.GetAppenders().Count| Should be 3
  }
  
  It "Must exist two logger"{     
    $Repository=[LogManager]::GetRepository('Test')   
    $Repository.GetCurrentLoggers().Count| Should be 2
  }
 
  It "Must loggers are not null"{  
    [LogManager]::GetLogger('Test','DebugLogger')|Should Not BeNullOrEmpty
    [LogManager]::GetLogger('Test','InfoLogger')|Should Not BeNullOrEmpty
  }
 }

 Context "When there error" {
   #Log4Net repository can not be removed While the dll is loaded, but they can be reconfigured.
  It "Verify if a unknown repository not exist" -skip:$(Test-Repository 'Pester') {     
    Test-Repository 'Pester' | Should Be $false
  }
  
  It "Verify if the a new repository 'Pester' is not configured" -skip:$(Test-Repository 'Pester'){     
   try {
     $Repository=[LogManager]::CreateRepository('Pester') 
     Test-Repository 'Pester' -Configured | Should Be $false
   } 
   catch {
      $_.FullyQualifiedErrorId | Should be 'RepositoryNotConfigured,Test-Repository'
   }
  }

  It "Start-Log4Net throw a FileNotFoundException" -skip:$(Test-Repository 'Test2'){ 
   $Repository=[LogManager]::CreateRepository('Test2') 
   try {
     Start-Log4Net -Repository $Repository -Path "$PSScriptRoot\NotExistLog4Posh.Config.xml"
   }
   catch {
     $_.FullyQualifiedErrorId | Should be 'XMLConfigurationFile,Start-Log4Net'
   }
  }

  It "Start-Log4Net throw a XML configuration error. Set 'threshold' property to 'ON' is invalid" -skip:$(Test-Repository 'Test3'){ 
   $Repository=[LogManager]::CreateRepository('Test3') 
   try {
     Start-Log4Net -Repository $Repository -Path "$PSScriptRoot\ErrorLog4Posh.Config.xml"
   }
   catch {
     $_.FullyQualifiedErrorId | Should be 'XMLConfigurationFile,Start-Log4Net'
   }
  }
 }
}

Describe "Log4Posh used by module - basic" {

  Context "When there is no error" {
  
    It "Must exist the repository 'Module1'"{   
     [LogManager]::GetRepository('Module1') | Should Not BeNullOrEmpty
    }

    It "Verify if the repository 'Module1' is configured" {  
      Test-Repository 'Module1' -Configured | Should Be $true
    }
 
    It "Must exist four appenders"{   
      $Repository=[LogManager]::GetRepository('Module1')   
      $Repository.GetAppenders().Count| Should be 4
    }
    
    It "Must exist two logger"{     
      $Repository=[LogManager]::GetRepository('Module1')   
      $Repository.GetCurrentLoggers().Count| Should be 2
    }
  
    It "Must loggers are not null"{  
      [LogManager]::GetLogger('Module1','DebugLogger')|Should Not BeNullOrEmpty
      [LogManager]::GetLogger('Module1','InfoLogger')|Should Not BeNullOrEmpty
    }
  }
}

InModuleScope Module1 {
  Describe "Log4Posh used by module - InModuleScope " {

   Context "When there is no error" {
     #The name of the repository is set by an ETS member (log4net.Core.LogImpl.Types)
     #This member use a private variable of the module
    It "Must logger works"{  
     [LogManager]::GetRepository('Module1')|
       Get-Log4NetLogger -Name 'InfoLogger','DebugLogger'|
       Set-Log4NetAppenderThreshold 'Console' -DebugLevel
     $DebugLogger=[LogManager]::GetLogger('Module1','DebugLogger')
     {$DebugLogger.PSDebug('Message - Console - Module1 context')}| Should Not Throw 
    }
  }
 }
}
  #  #$env:TEMP\TestAppendersLG4PS.log
  # Context "When there error" {
  #   It "Verify if a unknown repository not exist" -skip:$(Test-Repository 'Pester') {     
  #     Test-Repository 'Pester' | Should Be $false
  #   }
    
  #   It "Verify if the a new repository 'Pester' is not configured" -skip:$(Test-Repository 'Pester'){     
  #   try {
  #     $Repository=[LogManager]::CreateRepository('Pester') 
  #     Test-Repository 'Pester' -Configured | Should Be $false
  #   } 
  #   catch {
  #       $_.FullyQualifiedErrorId | Should be 'RepositoryNotConfigured,Test-Repository'
  #   }
  #   }

  #   It "Start-Log4Net throw a FileNotFoundException" -skip:$(Test-Repository 'Test2'){ 
  #   $Repository=[LogManager]::CreateRepository('Test2') 
  #   try {
  #     Start-Log4Net -Repository $Repository -Path "$PSScriptRoot\NotExistLog4Posh.Config.xml"
  #   }
  #   catch {
  #     $_.FullyQualifiedErrorId | Should be 'XMLConfigurationFile,Start-Log4Net'
  #   }
  #   }

  #   It "Start-Log4Net throw a XML configuration error. Set 'threshold' property to 'ON' is invalid" -skip:$(Test-Repository 'Test3'){ 
  #   $Repository=[LogManager]::CreateRepository('Test3') 
  #   try {
  #     Start-Log4Net -Repository $Repository -Path "$PSScriptRoot\ErrorLog4Posh.Config.xml"
  #   }
  #   catch {
  #     $_.FullyQualifiedErrorId | Should be 'XMLConfigurationFile,Start-Log4Net'
  #   }
  #   }
  # }

<#
Start-Log4Net

2- Start-Log4Net $Repository $XmlConfigPath 
 Même chose mais avec un module

Initialize-Log4NetModule
3- Start-Log4Net $Repository $XmlConfigPath 
 Même chose mais avec un script
 Initialize-Log4NetScript

Get-Log4NetLogger


Set-Log4NetAppenderFileName
Get-Log4NetAppenderFileName


Get-DefaultAppenderFileName

Get-Log4NetFileAppender

Get-Log4NetRepository
Get-LogDebugging

Set-Log4NetAppenderThreshold
Set-Log4NetLoggerLevel
Set-Log4NetRepositoryThreshold
Set-LogDebugging
Switch-AppenderFileName




#>
