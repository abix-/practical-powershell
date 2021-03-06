<#
.SYNOPSIS
    Get-PageFile - Gathers pagefile settings from computers.
.DESCRIPTION
    This script gathers pagefile settings from the specified computer(s)
.NOTES
    File Name: Get-PageFile.ps1
    Author: Al Iannacone
    Created:  2/8/2013
    Modified: 1/8/2013
    Version: 1.0

.EXAMPLE
C:\PS>.\Get-PageFile.ps1 -computername my-vcenter.domain.local
#>

[cmdletbinding()]
Param (
    [Parameter(ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    [alias("cn")]
    $computername="localhost"
)

function writeToObj($computer,$manual="N/A",$cpf="N/A",$gpf="N/A",$ppf="N/A",$location="N/A",$minsize="N/A",$maxsize="N/A") {
    $obj= New-Object PSObject -Property @{
        ComputerName = $computer
        Mode = $manual
        Location = $location
        MinSize = $minsize
        MaxSize = $maxsize
        'C:\pagefile.sys' = $cpf
        'G:\pagefile.sys' = $gpf
        'P:\pagefile.sys' = $ppf
    }
    return $obj
}

function Test-PathEx($Path) {
    if (Test-Path $Path) { 
        $true
    }
    else {
        $parent = Split-Path $Path
        try { [System.IO.Directory]::EnumerateFiles($Parent) -contains $Path }
        catch { }
    }
}

Function Get-WmiCustom([string]$computername,[string]$namespace,[string]$class,[int]$timeout=15) 
{ 
    $ConnectionOptions = new-object System.Management.ConnectionOptions 
    $EnumerationOptions = new-object System.Management.EnumerationOptions

    $timeoutseconds = new-timespan -seconds $timeout 
    $EnumerationOptions.set_timeout($timeoutseconds)

    $assembledpath = "\\" + $computername + "\" + $namespace 
    #write-host $assembledpath -foregroundcolor yellow

    $Scope = new-object System.Management.ManagementScope $assembledpath, $ConnectionOptions 
    $Scope.Connect()

    $querystring = "SELECT * FROM " + $class 
    #write-host $querystring

    $query = new-object System.Management.ObjectQuery $querystring 
    $searcher = new-object System.Management.ManagementObjectSearcher 
    $searcher.set_options($EnumerationOptions) 
    $searcher.Query = $querystring 
    $searcher.Scope = $Scope

    trap { $_ } $result = $searcher.get()

    return $result 
}

function getPFData($computer) {
    $ready = $true
    try { Test-Connection -ComputerName $computer -count 1 -ErrorAction "STOP" | out-null }
    catch {
        Write-Host "$computer is offline"
        $pfdata = writeToObj $computer "Offline" 
        $ready = $false
    }

    if($ready -eq $true) {
        try { Get-WmiCustom win32_computersystem -namespace "root\cimv2" -computername $computer -ea "STOP" -timeout 10 | out-null }
        catch { 
            Write-Host "$computer failed WMI Query"
            $pfdata = writeToObj $computer "WMI Query Failed" 
            $ready = $false
            write-verbose "here"
        }
    }

    if($ready -eq $true) {
        if(Test-PathEx \\$computer\c$\pagefile.sys) { $cpf = "Exists" } else { $cpf = "Does not exist" }
        if(Test-PathEx \\$computer\g$\pagefile.sys) { $gpf = "Exists" } else { $gpf = "Does not exist" }
        if(Test-PathEx \\$computer\p$\pagefile.sys) { $ppf = "Exists" } else { $ppf = "Does not exist" }
        $pf = Get-WmiCustom win32_pagefile -namespace "root\cimv2" -computername $computer -ea "STOP" -timeout 10
        if(!$pf) {
            $pf = Get-WmiCustom win32_pagefileusage -namespace "root\cimv2" -computername $computer -timeout 10
            if($pf) { $pfdata = writeToObj $computer "Automatic" $cpf $gpf $ppf $pf.Name }
        } else { $pfdata = writeToObj $computer "Manual" $cpf $gpf $ppf $pf.Name $pf.InitialSize $pf.MaximumSize } 
    }   
    return $pfdata
}

foreach($computer in $computername) {
    $i++
    Write-Progress -Activity "Gathering Pagefile Data" -Status "Working on $($computer)" -PercentComplete (($i/$computername.Length)*100)
    $serverpf = GetPFData $computer
    if($serverpf) {
        $serverpf | Select ComputerName,Mode,Location,MinSize,MaxSize,'C:\pagefile.sys','G:\pagefile.sys','P:\pagefile.sys'
    }
}