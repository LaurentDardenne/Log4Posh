---
external help file: Log4Posh-help.xml
online version: 
schema: 2.0.0
---

# Initialize-Log4Net

## SYNOPSIS
Initializes a Log4Net repository and its loggers.
By default, initializes log4posh for a script and configure the default Log4Net repository.
To configure Log4Posh with a xml file, use the -XmlConfigPath parameter (for a module, a script or a job).

For a module, this function is injected into the module using Log4Posh.
By Default the repository name is the name of caller module.

## SYNTAX

### DefaultConfiguration (Default)
```
Initialize-Log4Net [[-FileExternalPath] <String>] [[-FileInternalPath] <String>] [-Console <String>]
 [-Scope <String>] [<CommonParameters>]
```

### XmlConfiguration
```
Initialize-Log4Net [-RepositoryName] <String> [-XmlConfigPath] <String> [[-DefaultLogFilePath] <String>]
 [-Scope <String>] [<CommonParameters>]
```

## DESCRIPTION
{{Fill in the Description}}

## EXAMPLES

### Example 1
```
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -RepositoryName
Name of the module to initialize
This is to the name of the repository

```yaml
Type: String
Parameter Sets: XmlConfiguration
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -XmlConfigPath
Name of the config.xml

```yaml
Type: String
Parameter Sets: XmlConfiguration
Aliases: 

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultLogFilePath
Path of default log file
The directory is created if it do not exist

```yaml
Type: String
Parameter Sets: XmlConfiguration
Aliases: 

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileExternalPath
Path of file used by the RollingFileAppender associated with logger $InfoLogger.
This logger is dedicated to functional debug traces.

By default the FileExternal and FileInternal appenders use the same file,

```yaml
Type: String
Parameter Sets: DefaultConfiguration
Aliases: 

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileInternalPath
Path of file used by the RollingFileAppender associated with logger $DebugLogger.
This logger is dedicated to internal debug traces.

By default the FileExternal and FileInternal appenders use the same file,

```yaml
Type: String
Parameter Sets: DefaultConfiguration
Aliases: 

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Console
Configure the console appender.

 All   : Start the console appender for the $InfoLogger and $DebugLogger loggers
 Debug : Start the console appender for the $DebugLogger logger
 Info  : Start the console appender for the $InfoLogger  logger
 None  : Stop the console appender for the  $InfoLogger and $DebugLogger loggers

```yaml
Type: String
Parameter Sets: DefaultConfiguration
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Scope
The number of the scope where create the $DebugLogger and $InfoLogger variable.
The default valus is 2

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: 2
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

