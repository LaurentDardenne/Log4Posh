---
external help file: Log4Posh-help.xml
online version: 
schema: 2.0.0
---

# Get-Log4NetAppenderFileName

## SYNOPSIS
Returns the current path of the internal (debug) or external (functional) log file of a module

## SYNTAX

### External (Default)
```
Get-Log4NetAppenderFileName [-ModuleName] <String> [-External] [<CommonParameters>]
```

### Internal
```
Get-Log4NetAppenderFileName [-ModuleName] <String> [-Internal] [<CommonParameters>]
```

### All
```
Get-Log4NetAppenderFileName [-ModuleName] <String> [-All] [<CommonParameters>]
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

### -ModuleName
{{Fill ModuleName Description}}

```yaml
Type: String
Parameter Sets: (All)
Aliases: RepositoryName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -External
{{Fill External Description}}

```yaml
Type: SwitchParameter
Parameter Sets: External
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Internal
{{Fill Internal Description}}

```yaml
Type: SwitchParameter
Parameter Sets: Internal
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
{{Fill All Description}}

```yaml
Type: SwitchParameter
Parameter Sets: All
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

