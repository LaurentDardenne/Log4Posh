#Release.ps1
#Construit la version Release via Psake

Task default -Depends Delivery

Task Delivery -Depends Clean{
   Write-host  $TaskName 
} #Delivery


Task Clean -Depends Init {
   Write-host  $TaskName 
} #Clean

Task Init {
   Write-host  $TaskName
}#Init

