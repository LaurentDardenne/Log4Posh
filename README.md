[![Build status](https://github.com/LaurentDardenne/Log4Posh/actions/workflows/Build.yml/badge.svg)](https://github.com/LaurentDardenne/Log4Posh/actions/workflows/Build.yml)

![Logo](http://ottomatt.pagesperso-orange.fr/Data/Log4Posh.jpg)
# Log4Posh
A log4net wrapper for PowerShell. Support .NET Core 1.0 / .NET Standard 1.3

[French](https://github.com/LaurentDardenne/Log4Posh/blob/master/src/fr-FR/about_Log4Posh.md) documentation. Principe et configuration

To install this module :
```Powershell
$PSGalleryPublishUri = 'https://www.myget.org/F/ottomatt/api/v2/package'
$PSGallerySourceUri = 'https://www.myget.org/F/ottomatt/api/v2'

Register-PSRepository -Name OttoMatt -SourceLocation $PSGallerySourceUri -PublishLocation $PSGalleryPublishUri #-InstallationPolicy Trusted
Install-Module Log4Posh -Repository OttoMatt
```