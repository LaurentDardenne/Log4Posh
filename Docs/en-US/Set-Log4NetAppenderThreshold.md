---
external help file: Log4Posh-help.xml
online version: 
schema: 2.0.0
---

# Set-Log4NetAppenderThreshold

## SYNOPSIS
{{Fill in the Synopsis}}

## SYNTAX

### Level (Default)
```
Set-Log4NetAppenderThreshold -Logger <LogImpl> [-AppenderName] <String[]> [[-Level] <String>]
 [<CommonParameters>]
```

### off
```
Set-Log4NetAppenderThreshold -Logger <LogImpl> [-AppenderName] <String[]> [-Off] [<CommonParameters>]
```

### debug
```
Set-Log4NetAppenderThreshold -Logger <LogImpl> [-AppenderName] <String[]> [-DebugLevel] [<CommonParameters>]
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

### -AppenderName
{{Fill AppenderName Description}}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

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
Position: 2
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

