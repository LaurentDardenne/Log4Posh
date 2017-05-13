---
external help file: Log4Posh-help.xml
online version: 
schema: 2.0.0
---

# Get-Log4NetFileAppender

## SYNOPSIS
Returns a repository to all append, derived from the FilesAppender class, whose name is $AppenderName

## SYNTAX

```
Get-Log4NetFileAppender [-Repository] <ILoggerRepository> [[-AppenderName] <String>] [-All]
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

### -Repository
{{Fill Repository Description}}

```yaml
Type: ILoggerRepository
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: $([Log4net.LogManager]::GetRepository($script:DefaultRepositoryName))
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -AppenderName
{{Fill AppenderName Description}}

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: FileExternal
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
{{Fill All Description}}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

