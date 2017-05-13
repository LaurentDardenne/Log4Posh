---
external help file: Log4Posh-help.xml
online version: 
schema: 2.0.0
---

# Initialize-Log4NetModule

## SYNOPSIS
Initializes, for a module, a Log4Net repository and its loggers
This function is injected into the module using Log4Posh

## SYNTAX

```
Initialize-Log4NetModule [-RepositoryName] <String> [-XmlConfigPath] <String> [-DefaultLogFilePath] <String>
 [<CommonParameters>]
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
Parameter Sets: (All)
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
Parameter Sets: (All)
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
Parameter Sets: (All)
Aliases: 

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

