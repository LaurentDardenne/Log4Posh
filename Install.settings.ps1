###############################################################################
# Customize these properties and tasks for your module.
###############################################################################

Properties {
    # ----------------------- Basic properties --------------------------------

    # Is the environment is APPVEYOR or a local computer ?
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $isAPPVEYOR = Test-Path env:APPVEYOR


    #Location of nuget feed
    #see build.settings.ps1 : $PublishRepository
    $MyGetPublishUri = 'https://www.myget.org/F/ottomatt/api/v2/package'
    $MyGetSourceUri = 'https://www.myget.org/F/ottomatt/api/v2'

    $DEV_MyGetPublishUri = 'https://www.myget.org/F/devottomatt/api/v2/package'
    $DEV_MyGetSourceUri = 'https://www.myget.org/F/devottomatt/api/v2'


    #Common modules
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $PSGallery=@{
       Modules=@('Pester','PsScriptAnalyzer','BuildHelpers','platyPS')
       Scripts=@()
     }
    #Personnal modules & script (French documentation only)
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $MyGet=@{
       Modules=@('Log4Posh','MeasureLocalizedData','DTW.PS.FileSystem','Template','OptimizationRules','ParameterSetRules')
       Scripts=@('Lock-File', 'Using-Culture')
     }
}

###############################################################################
# Customize these tasks for performing operations before and/or after file staging.
###############################################################################

# Executes before the StageFiles task.
Task BeforeStageFiles {
}

# Executes after the StageFiles task.
Task AfterStageFiles {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Build.
###############################################################################

# Executes before the BeforeStageFiles phase of the Build task.
Task BeforeBuild {
}

# Executes after the Build task.
Task AfterBuild {
}

###############################################################################
# Customize these tasks for performing operations before and/or after BuildHelp.
###############################################################################

# Executes before the BuildHelp task.
Task BeforeBuildHelp {
}

# Executes after the BuildHelp task.
Task AfterBuildHelp {
}

###############################################################################
# Customize these tasks for performing operations before and/or after BuildUpdatableHelp.
###############################################################################

# Executes before the BuildUpdatableHelp task.
Task BeforeBuildUpdatableHelp {
}

# Executes after the BuildUpdatableHelp task.
Task AfterBuildUpdatableHelp {
}

###############################################################################
# Customize these tasks for performing operations before and/or after GenerateFileCatalog.
###############################################################################

# Executes before the GenerateFileCatalog task.
Task BeforeGenerateFileCatalog {
}

# Executes after the GenerateFileCatalog task.
Task AfterGenerateFileCatalog {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Install.
###############################################################################

# Executes before the Install task.
Task BeforeInstall {
}

# Executes after the Install task.
Task AfterInstall {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Publish.
###############################################################################

# Executes before the Publish task.
Task BeforePublish {
}

# Executes after the Publish task.
Task AfterPublish {
}
