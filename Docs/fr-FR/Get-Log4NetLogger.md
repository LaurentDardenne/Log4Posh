---
external help file: Log4Posh-help.xml
online version: 
schema: 2.0.0
---

# Get-Log4NetLogger

## SYNOPSIS
Returns one or more loggers from the repository $Repository.
The name 'Root' is valid.

## SYNTAX

### All (Default)
```
Get-Log4NetLogger [-Repository] <ILoggerRepository> [-All] [<CommonParameters>]
```

### Name
```
Get-Log4NetLogger [-Repository] <ILoggerRepository> [-Name] <String[]> [<CommonParameters>]
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

### -Name
{{Fill Name Description}}

```yaml
Type: String[]
Parameter Sets: Name
Aliases: 

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
{{Fill All Description}}

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases: 

Required: True
Position: 2
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

