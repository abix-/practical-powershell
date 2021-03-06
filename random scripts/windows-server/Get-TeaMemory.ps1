function GetProcessInfoByName($computername,$processName)
{
    $obj = Get-WmiObject -computername $computername -class Win32_PerfFormattedData_PerfProc_Process | where{$_.name -like $processName+"*"}
    $privateworkingset = $obj.workingSetPrivate / 1MB
    $privateworkingset = "{0:N2}" -f $privateworkingset
    Write-Host $computername":" $privateworkingset"MB"
}

GetProcessInfoByName tea-app01 ctreesql
GetProcessInfoByName tea-app02 ctreesql