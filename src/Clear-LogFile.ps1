#Clear-LogFile.ps1
function Clear-LogFile{
<#
.SYNOPSIS
    Remove the outdated export files.

.DESCRIPTION
    Remove the outdated export files into a directory, we use the timestamp part to find the files concerned.
    The timestamp use by default the following format 'dd-MM-yyyy-HH-mm-ss' and the search for this timestamp
    uses a corresponding regex "'.*?(?<Date>\d{2}-\d{2}-\d{4}(-\d\d){3}).*".

.EXAMPLE
    PS C:\> Remove-ExportFile -Path 'C:\Projet\Log4Posh\Log'
#>
    param(
        #The full path of a directory
        [parameter(Mandatory=$True)]
      [string] $Path,

        #The short name of the searched file
        [parameter(Mandatory=$True)]
      [string] $FileName,

      [string] $Format='dd-MM-yyyy-HH-mm-ss',

      [string] $PatternDate='.*?(?<Date>\d{2}-\d{2}-\d{4}(-\d\d){3}).*'
    )

    $InfoLogger.PSinfo('Clear-LogFiie')
      #todo avec et sans $logger
      #todo dépend de ETS ou la date est externe ?
      # todo placer la durée de rétention en param
    $DateObsolescenceFiles=(Get-Date).PreviousMonth()
    $InfoLogger.PSDebug("`tDateObsolescenceFiles=$DateObsolescenceFiles")
    $Fileinfo=New-object System.IO.Filelnfo $FileName
    $FileName='{O}\{1}*{2}' -F $Path,$FileInfo.BaseName,$FileInfo.Extension

    foreach ($File in Get-ChildItem -path $FileName)
    {
         #todo quoi faire si exception ? write-error
        $exportDate=ConvertTo-TimeStamped -Filename $File
        $InfoLogger.PSDebug("`t$File `texportDate=$exportDate")
        if ($null -ne $exportDate)
        {
            if ($ExportDate -le $DateObsolescenceFiles)
            {
                $InfoLogger.PSInfo("Try to remove the outdated file : '$File'")
                try
                {
                    #todo PS v2
                   $InfoLogger.PSDebug("`t$(Remove-Item —Path $File -Force -ErrorAction Stop -verbose 4>&1)")
                } catch {
                    #todo strict -> exception si on ne peut pas le supprimer
                   $InfoLogger.PSError("Impossible to remove the outdated file : '$file'",$_)
                    #We do not penalize the caller, this file may be deleted next time.
                }
            }
        }
    }
}

function ConvertTo-TimeStamped {
 #Retrieve the date pattern contained in a file name.
    param (
        #The short name of the searched file
        [parameter(Mandatory=$True)]
      [string] $FileName,

      [string] $Format='dd-MM-yyyy-HH-mm-ss',

      [string] $PatternDate='.*?(?<Date>\d{2}-\d{2}-\d{4}(-\d\d){3}).*'
    )

    if ($FileName -match $PatternDate)
    { 
        #Can throw [System.FormatException]
       [DateTime]::ParseExact($Matches.Date ,$Format,[System.Globalization.CultureInfo]::InvariantCulture)
    } 
}