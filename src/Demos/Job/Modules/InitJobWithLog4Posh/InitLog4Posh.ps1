
$ScriptName=([System.IO.FileInfo]$PSCommandPath).BaseName
$script:lg4n_ScriptName=$ScriptName

#module log4posh is loaded
[log4net.GlobalContext]::Properties["LogJobName"]=$ScriptName

#Log4net manage this property, it is used for the path of a appender`s file
[log4net.GlobalContext]::Properties["ApplicationLogPath"]="$PSScriptRoot\Logs"

Initialize-Log4Net -RepositoryName $ScriptName -XmlConfigPath "$PSScriptRoot\$ScriptName.Config.xml"
