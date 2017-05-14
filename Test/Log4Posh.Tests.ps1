
Import-Module  "..\Release\Log4Posh\Log4Posh.psd1" -Force
Write-Warning "Work in progress"

Describe "Log4Posh standalone - basic" {

 Context "When there is no error" {

  It "Log4Net assemblie loaded, [LogManager] must existed"{
    [log4net.LogManager] -eq [LogManager] | Should Be $true
  }
 
  It "Start-Log4Net configure a repository with a xml file" -skip:$(Test-Repository 'Test'){ 
    $Repository=[LogManager]::CreateRepository('Test') 
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
    {$DebugLogger.PSDebug('Test')}| Should Not Throw 
  }
 }

 Context "When there error" {
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



Remove-Module Log4Posh -Force
Import-Module  "..\Release\Log4Posh\Log4Posh.psd1" -Force
Import-Module  "..\Release\Log4Posh\Demos\Module1\Module1.psd1" -Force

InModuleScope Module1 {

  Describe "Log4Posh inside a module - basic" {

  Context "When there is no error" {

    It "Log4Net assemblie loaded, [LogManager] must existed"{
      [log4net.LogManager] -eq [LogManager] | Should Be $true
    }
  
    It "Must exist the repository 'Module1'"{   
     $Repository=[LogManager]::GetRepository('Module1') | Should Be $true
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
    
    It "Must TypeData loaded"{  
      Get-TypeData log4net.Core.LogImpl|Should Not BeNullOrEmpty
    }
   
    It "Must logger works"{  
        [LogManager]::GetRepository('Module1')|
        Get-Log4NetLogger -Name 'InfoLogger','DebugLogger'|
        Set-Log4NetAppenderThreshold 'Console' -DebugLevel
     $DebugLogger=[LogManager]::GetLogger('Module1','DebugLogger')
     {$DebugLogger.PSDebug('Test')}| Should Not Throw 
    }
  }

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
 }
}

<#
Start-Log4Net
1- Start-Log4Net $Repository $XmlConfigPath 
 fichier inexistant
 fichier xml erroné/invalide
 teste les appenders
 teste les loggers

2- Start-Log4Net $Repository $XmlConfigPath 
 Même chose mais avec un module

Initialize-Log4NetModule
3- Start-Log4Net $Repository $XmlConfigPath 
 Même chose mais avec un script
 Initialize-Log4NetScript

Stop-Log4Net
  implication pour 1 module : import M1
  implication pour 2 modules : import M1,M2  Remove M1 -> M2 fonctionne tjr ?
  implication pour 2 modules : import M1  Remove M2 -> M1 fonctionne  ?

Start-ConsoleAppender
Stop-ConsoleAppender

Get-Log4NetLogger


Set-Log4NetAppenderFileName
Get-Log4NetAppenderFileName


ConvertTo-Log4NetCoreLevel
Get-DefaultAppenderFileName
Get-DefaultRepositoryName
Get-Log4NetFileAppender

Get-Log4NetRepository
Get-LogDebugging

Set-Log4NetAppenderThreshold
Set-Log4NetLoggerLevel
Set-Log4NetRepositoryThreshold
Set-LogDebugging
Switch-AppenderFileName
Test-Repository



#>
