[cmdletbinding()]
Param (
    [parameter(Mandatory=$true)]
    $service,
    [alias("cn")]
    $computername = $env:COMPUTERNAME,
    $backupdir = "C:\backups",
    [switch]$nohistory,
    [switch]$nooutboundbatfiles
)


$date = Get-Date -format yyyy-MM-dd
$servicepath = (Get-WmiObject -computername $computername -query "SELECT PathName FROM Win32_Service WHERE Name = '$service'").PathName
$servicepath = $servicepath.Trim('"')
if($computername -ne $env:COMPUTERNAME) {
    $servicepath = $servicepath -replace '([a-zA-z])(:\\)','$1$\'
    $servicepath = "\\" + $computername + "\" + $servicepath
    $servicepath
}
$servicedir = $servicepath -replace ('^"+([^\.]+\.\w+)\s.+$','$1')
$servicedir

if(Test-Path $servicedir) {
    if($nohistory) { $switches += "-xr!history" }
    if($nooutboundbatfiles) { 
        if($switches) {
            $switches += " -xr!outboundbatfiles"
        } else {
            $switches += "-xr!outboundbatfiles"
        }
    }
    Write-Host "Starting to backup all files in $servicedir"
    & "C:\Program Files\7-Zip\7z.exe" a -tzip $backupdir\$date\$service.zip $servicedir -mx9 $switches
} else {
    Write-Host "There is no folder at $servicedir on $computername"
    #write-host $servicedir
}