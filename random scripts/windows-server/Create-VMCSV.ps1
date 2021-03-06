[cmdletbinding()]
Param (
    [parameter(Mandatory=$true)]
    $csv
)

$connection = connect-viserver vcenter
$report = @()

$clusters = Get-Cluster
foreach($cluster in $clusters) {
    Write-Host "Reading data from $($cluster.name)"
    $vms = Get-Cluster $cluster.Name | Get-VM
    if($vms) {
        foreach($vm in $vms) {
            $indexof = $vm.Name.IndexOf('`')
            if(!$indexof -ne "-1"){ 
                $line = "" | Select VMName, VMIp, MAC, WebURL, Protocol, Port, Path
                $line.VMName = $vm.Name
                try { $line.VMIp = [System.Net.Dns]::GetHostByName("$($vm.Name)").HostName }
                catch { $line.VMIp = $vm.Name }
        		$line.Protocol = "RDP"
        		$line.Port = "3389"
                $line.Path = $cluster.Name
                if($vm.ResourcePool.Name -ne "Resources") {
                    $line.Path += "\$($vm.ResourcePool.Name)"
                }
                $report += $line
            }
        }
    }
}

$report | Sort Path, VMName | ConvertTo-Csv -NoTypeInformation -Delimiter ";" | Select -Skip 1 | Out-File -FilePath $csv -Encoding ascii