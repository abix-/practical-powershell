[cmdletbinding()]
Param (
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

$servers = @(GetCSV $csv)
$connection = connect-viserver my-vcenter.domain.local

foreach($server in $servers) {
    $adapter = get-vm $server.Hostname | get-networkadapter
    Set-NetworkAdapter -NetworkAdapter $adapter -Connected:$true -StartConnected:$true -Confirm:$false
}