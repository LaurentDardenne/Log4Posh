#   --Requires -Modules Log4Posh

$ScriptName=([System.IO.FileInfo]$PSCommandPath).BaseName

#$lg4n_ScriptName is added in beginning of a log line (ETS manage this variable)
#$LogJobName is used for named an appender`s file (Log4net manage this propertie)
$script:lg4n_ScriptName=[log4net.GlobalContext]::Properties["LogJobName"]=$ScriptName

#Log4net manage this property, it is used for the path of a appender`s file
[log4net.GlobalContext]::Properties["ApplicationLogPath"]="$PSScriptRoot\Logs"


function Format-Log4PoshConfiguration{
  #Return string that contains the details of the log4net configuration
   $Lg4nConfiguration=Get-Log4NetConfiguration
   "Log4Net properties :"
   Get-Log4NetGlobalContextProperty|Out-String
   "Repositories configuration :"
   $Lg4nConfiguration.GetEnumerator()|
   Foreach-object {
     "$($_.Key)`r`n"
     if ($_.Value.keys.Count -eq 0)
     {
        "`tNo loggers."
     }
     else
     {
      $_.Value.GetEnumerator() |Foreach-object {
        "`t$($_.Key) : $($_.Value.EffectiveLevel)`r`n "
        ($_.Value.Appenders|out-string) -split "`r`n"|% {$_ -replace '^',"`t`t"}
      }
     }
     "`r`n"
    }
 }


try {
    Initialize-Log4Net -RepositoryName $ScriptName -XmlConfigPath "$PSScriptRoot\Demo2Script.Log4Net.Config.xml"
    Format-Log4PoshConfiguration
}
catch{
  $Repository=Get-Log4NetRepository -RepositoryName $ScriptName
  if(!$Repository.Configured)
  { Write-Error "Error $_" }
  else
  { $InfoLogger.PSFatal('Error',$_) }
}
Finally {
    Stop-Log4Net -RepositoryName $ScriptName
}

