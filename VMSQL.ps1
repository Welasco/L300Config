<# Custom Script for Windows to install a file from Azure Storage using the staging folder created by the deployment script #>
param (
    [int]$UsersAmount
)

Import-Module ServerManager
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Downloaddir = "C:\HybridConnectionManager"
mkdir $Downloaddir
Invoke-WebRequest -Uri https://go.microsoft.com/fwlink/?linkid=841308 -OutFile ($Downloaddir+"\HybridConnectionManager.msi")

$SQLBackupDir = "C:\SQLBackup"
mkdir $SQLBackupDir
Invoke-WebRequest -Uri https://github.com/Welasco/L300TestApp/raw/master/L300DB.bak -OutFile ($SQLBackupDir+"\L300DB.bak")

$SQLDataDir = "C:\SQLData"
mkdir $SQLDataDir

$tSQL = @'
RESTORE DATABASE L300DB
FROM DISK = N'C:\SQLBackup\L300DB.bak'
WITH MOVE 'L300DB' TO 'c:\SQLData\L300DB.mdf',
MOVE 'L300DB_log' TO 'c:\SQLData\L300DB_log.ldf',
RECOVERY;
'@

$tSQL | Out-File ($SQLBackupDir+"\L300-restore.sql")


sqlcmd -E -S . -b -i ($SQLBackupDir+"\L300-restore.sql")

function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
}

Disable-InternetExplorerESC