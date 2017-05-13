---
external help file: Log4Posh-help.xml
online version: 
schema: 2.0.0
---

# Switch-AppenderFileName

## SYNOPSIS
Modifies the name of the file associated with the FileAppender named $AppenderName of a repository $Name

## SYNTAX

### NewName (Default)
```
Switch-AppenderFileName -RepositoryName <String> [[-AppenderName] <String>] [-NewFileName] <String>
 [<CommonParameters>]
```

### Default
```
Switch-AppenderFileName -RepositoryName <String> [[-AppenderName] <String>] [-Default] [<CommonParameters>]
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
Nom du repository, par convention est identique au nom du module.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -AppenderName
Par défaut nom de l'appender dédié aux logs fonctionnels de chaque module utilisant Log4Posh

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

### -NewFileName
{{Fill NewFileName Description}}

```yaml
Type: String
Parameter Sets: NewName
Aliases: 

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Default
{{Fill Default Description}}

```yaml
Type: SwitchParameter
Parameter Sets: Default
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

