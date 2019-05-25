<# Custom Script for Windows to install a file from Azure Storage using the staging folder created by the deployment script #>
param (
    [int]$UsersAmount,
    [string]$VMSQLNAME,
    [string]$VMSQLIP,
    [string]$VMSTDNAME,
    [string]$VMSTDIP,
    [int]$VMSTDIPINITNUM
)

Import-Module ServerManager
Install-WindowsFeature DNS,RSAT-DNS-Server

Import-Module DnsServer

$DNSZoneName = "L300.local"

Add-DnsServerPrimaryZone -Name $DNSZoneName -ZoneFile "$DNSZoneName.dns"
Add-DnsServerResourceRecordA -Name $VMSQLNAME -ZoneName $DNSZoneName -IPv4Address $VMSQLIP -TimeToLive 00:00:00

$StartIPLoop = $VMSTDIPINITNUM+1
for ($i = $StartIPLoop; $i -le $UsersAmount+$VMSTDIPINITNUM; $i++) {
    Add-DnsServerResourceRecordA -Name ($VMSTDNAME+$i) -ZoneName $DNSZoneName -IPv4Address ($VMSTDIP+$i) -TimeToLive 00:00:00
}

netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow
function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
}

Disable-InternetExplorerESC