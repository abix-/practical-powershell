$path = "c:\scripts\"
#$servers = import-csv "$path\new_webservers.csv"
$server = "server"

foreach ($server in $servers) {
    $servername = $server.name.ToUpper()
    copy $path\WebLog_Purge_TEMPLATE.xml $path\WebLog_Purge_$servername.xml
    (Get-Content $path\WebLog_Purge_$servername.xml) | % {$_ -replace "SERVERNAME", "$servername"} | Set-Content -path $path\WebLog_Purge_$servername.xml
    
}