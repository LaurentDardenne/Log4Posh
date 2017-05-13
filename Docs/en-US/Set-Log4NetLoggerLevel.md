---
external help file: Log4Posh-help.xml
online version: 
schema: 2.0.0
---

# Set-Log4NetLoggerLevel

## SYNOPSIS
{{Fill in the Synopsis}}

## SYNTAX

### Level (Default)
```
Set-Log4NetLoggerLevel -Logger <LogImpl> [[-Level] <String>] [<CommonParameters>]
```

### off
```
Set-Log4NetLoggerLevel -Logger <LogImpl> [-Off] [<CommonParameters>]
```

### debug
```
Set-Log4NetLoggerLevel -Logger <LogImpl> [-DebugLevel] [<CommonParameters>]
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

### -DebugLevel
{{Fill DebugLevel Description}}

```yaml
Type: SwitchParameter
Parameter Sets: debug
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Level
{{Fill Level Description}}

```yaml
Type: String
Parameter Sets: Level
Aliases: 

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Logger
{{Fill Logger Description}}

```yaml
Type: LogImpl
Parameter Sets: (All)
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Off
{{Fill Off Description}}

```yaml
Type: SwitchParameter
Parameter Sets: off
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### log4net.Core.LogImpl

## OUTPUTS

### System.Object

## NOTES

## RELATED LINKS

