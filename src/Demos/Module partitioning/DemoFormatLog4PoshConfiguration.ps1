#   --Requires -Modules Log4Posh
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
        ($_.Value.Appenders|out-string) -split "`r`n"|Foreach-Object {$_ -replace '^',"`t`t"}
      }
     }
     "`r`n"
    }
 }

Format-Log4PoshConfiguration
