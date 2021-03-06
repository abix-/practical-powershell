[cmdletbinding()]
Param (
    [alias("s")]
    #[Parameter(Mandatory=$true)]
    $server,
    $csv
)

function GetCSV($csvfile) {
   if(!(Test-Path $csvfile)) { 
        Write-Verbose "$($csvfile) does not exist. Try again."
   }
   elseif(!($csvfile.substring($csvfile.LastIndexOf(".")+1) -eq "csv")) {
        Write-Verbose "$($csvfile) is not a CSV. Try again."
   }
   else {
	    $csv = @(Import-Csv $csvfile)
        if(!$csv) {
            Write-Verbose "The CSV is empty. Try again."
        }
        else {
            $csvvalid = $true
            return $csv
        }
    }
}

function GetKAgentInfo($server) {
    if((Test-Connection -ComputerName $server -count 1 -ErrorAction 0)) {
        if(Test-Path "\\$server\c$\program files (x86)\kaspersky lab\networkagent\klnagchk.exe") {
            $info = .\PsExec.exe \\$server "c:\program files (x86)\kaspersky lab\networkagent\klnagchk.exe" | out-null
        } elseif (Test-Path "\\$server\c$\program files (x86)\kaspersky lab\networkagent 8\klnagchk.exe") {
            $info = .\PsExec.exe \\$server "c:\program files (x86)\kaspersky lab\networkagent 8\klnagchk.exe" | out-null
        } elseif (Test-Path "\\$server\c$\program files\kaspersky lab\networkagent\klnagchk.exe") {
            $info = .\PsExec.exe \\$server "c:\program files\kaspersky lab\networkagent\klnagchk.exe" | out-null
        } elseif (Test-Path "\\$server\c$\program files\kaspersky lab\networkagent 8\klnagchk.exe") {
            $info = .\PsExec.exe \\$server "c:\program files\kaspersky lab\networkagent 8\klnagchk.exe" | out-null
        } else { Write-Host "$server - Failed to find klnagchk.exe" }
    } else { 
        Write-Host "$server is offline"
        $info = "Offline"
    }
    return $info
}

function CreateObj($server, $info) {
    if($info) {
        if($info | Select-String "Network Agent is not running") {
            $status = "Not running"
        } elseif($info | Select-String "Network Agent is running") {
            $status = "Running"
        } elseif($info -eq "Offline") {
            $status = "Offline"
        } else {
            $status = "Unknown"
        }
    } else {
        $status = "Unknown"
    }

    $obj = New-Object PSObject -Property @{
        Server = $server
        Status = $status
    }
    return $obj     
}

if($server) {
    $info = GetKAgentInfo $server
    $obj = CreateObj $server $info
    $obj
} elseif($csv) {
    $allobj = @()
    $servers = @(GetCSV $csv)
    foreach($server in $servers) {
        Write-Progress -Activity "Working on $($server.name)" -PercentComplete (($i/$servers.count)*100)
        $i++
        $info = GetKAgentInfo $server.Name
        $obj = CreateObj $server.Name $info
        $allobj += $obj
    }
    $allobj
    $allobj | select Server,Status | Sort-Object Server | export-csv results.csv -notype
} else {
    Write-Host "The -server or -csv switch is required"
}


