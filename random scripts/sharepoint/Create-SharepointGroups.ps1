[cmdletbinding()]
Param (
    [parameter(Mandatory=$true)]
    $name,
    [parameter(Mandatory=$true)]
    $url
)

function EnableGroupSettings($groups,$groupname) {
    $groups = $site.RootWeb.sitegroups
    $group = $groups | where{$_.Name -eq $groupname}
    if($group) {
        Write-Host "Changing group settings on '$groupname'"
        $group.AllowRequestToJoinLeave = $true
        $group.RequestToJoinLeaveEmailSetting = "helpdesk@domain.local"
        $group.Update()
        $id = $group.ID.ToString()
        return $id
    } else {
        Write-Host "Failed set group settings for '$groupname'"
        return "0"
    }
}

$status = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
$site = New-Object Microsoft.SharePoint.SPSite("http://intranet")
$roles = @("FULL","DESIGN","APPROVE","CONTRIB","READ")
$perms = @("Full Control","Design","Approve","Contribute","Read")

$i = 0
$ids = ""
foreach($role in $roles) {
    $names += "$name - $role;"
    Write-Host "Creating '$name - $role' group on $url"
    if($role -eq "FULL") {
        stsadm -o creategroup -url $url -name "$name - $role" -ownerlogin "Intranet Owners" -description "$($perms[$i]) on $url"
    } else {
        stsadm -o creategroup -url $url -name "$name - $role" -ownerlogin "$name - FULL" -description "$($perms[$i]) on $url"
    }
    stsadm -o userrole -url $url -userlogin "$name - $role" -role "$($perms[$i])"
    $id = EnableGroupSettings $groups "$name - $role"
    if($id -ne "0") {
        [string]$ids = $ids + ";$id"
    }
    $i++   
}

if($ids) {
    $web = $site.AllWebs | where{$_.url -eq $url}
    if($web -and $ids) {
        $web.Properties["vti_associategroups"] += $ids
        $web.Properties.Update()
        Write-Host "Quick launch has been updated for $url"
    } else {
        Write-Host "The URL was not found or the groups were not properly created. The groups were not added to the quicklaunch. Use the below line to populate the Group Quick Launch"
        Write-Host $names
    }
}

$site.Dispose()