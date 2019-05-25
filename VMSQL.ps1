<# Custom Script for Windows to install a file from Azure Storage using the staging folder created by the deployment script #>
param (
    [int]$UsersAmount,
    [string]$SQLUserName,
    [string]$SQLUserPassword
)

################################################################################
# Function Log
# Function used to generate logs
################################################################################
function Log($Message){
    [string]$UserLogFile = ".\SQLLog.txt"
    Add-Content $UserLogFile (([System.DateTime]::Now).ToString() + $Message)
}

# SQL Function
function sqlquery(){
    param (
        [string]$SQLUserName,
        [string]$SQLUserPassword,
        [string]$SQLDB
    )
    # SQL Settings

    # SQL Server Endpoint
    $SQLServer = "."

    # SQL Database Name
    #$SQLDBName = "L300DB"

    # SQL User Name
    #$SQLUserName = "L300ConfigAdmin"

    # SQL User Name Password
    #$SQLUserPassword = "No_P@ssw0rd!"

    # SQL Azure Query
    #$SqlQuery = "SELECT * from SalesLT.Product;"
    $SqlQuery = "SELECT 1;"

    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    if($SQLDB -ne "" -and $SQLDB -ne $null){
        $SqlConnection.ConnectionString = ("Server=tcp:"+ $SQLServer +",1433;Initial Catalog="+ $SQLDB +";Persist Security Info=False;User ID="+ $SQLUserName +";Password="+ $SQLUserPassword +";MultipleActiveResultSets=False;Encrypt=False;TrustServerCertificate=False;Connection Timeout=30;")
    }
    else{
        $SqlConnection.ConnectionString = ("Server=tcp:"+ $SQLServer +",1433;Persist Security Info=False;User ID="+ $SQLUserName +";Password="+ $SQLUserPassword +";MultipleActiveResultSets=False;Encrypt=False;TrustServerCertificate=False;Connection Timeout=30;")
    }

    $Error.Clear();
    # Querying SQL and printing the result
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $SqlQuery
    $SqlCmd.Connection = $SqlConnection
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $result = $SqlAdapter.Fill($DataSet)
    Log(" [SQLQUERY] Query Result: " + $result)
    #$DataSet.Tables
}

function sqlrestore(){
    $sqlcmdoutput = sqlcmd -E -S . -b -i ($SQLBackupDir+"\L300-restore.sql")
    Log(" [INFO] SQLCMD restore Output: $sqlcmdoutput")
}

Log(" [INFO] Importing Server Manager Module")
Import-Module ServerManager
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Downloaddir = "C:\HybridConnectionManager"
if ((Test-Path -Path $Downloaddir) -ne $true) {
    Log(" [INFO] Creating folder $Downloaddir")
    mkdir $Downloaddir
    Log(" [INFO] Downloading Hybrid Connection Manager")
    Invoke-WebRequest -Uri https://go.microsoft.com/fwlink/?linkid=841308 -OutFile ($Downloaddir+"\HybridConnectionManager.msi")
}
else {
    Log(" [INFO] HybridConnectionManger already downloaded")
}


$SQLBackupDir = "C:\SQLBackup"
if ((Test-Path -Path $SQLBackupDir) -ne $true) {
    Log(" [INFO] Creating folder $SQLBackupDir")
    mkdir $SQLBackupDir
    Log(" [INFO] Downloading SQLBackup L300DB.bak")
    Invoke-WebRequest -Uri https://github.com/Welasco/L300TestApp/raw/master/L300DB.bak -OutFile ($SQLBackupDir+"\L300DB.bak")
    Log(" [INFO] Creating L300-restore.sql")
    $tSQL = @'
RESTORE DATABASE L300DB
FROM DISK = N'C:\SQLBackup\L300DB.bak'
WITH MOVE 'L300DB' TO 'c:\SQLData\L300DB.mdf',
MOVE 'L300DB_log' TO 'c:\SQLData\L300DB_log.ldf',
RECOVERY;
'@
    $tSQL | Out-File ($SQLBackupDir+"\L300-restore.sql")
    Log(" [INFO] Restore file created $SQLBackupDir\L300-restore.sql")
}
else {
    Log(" [INFO] SQLBackup already downloaded")
}


$SQLDataDir = "C:\SQLData"
if ((Test-Path -Path $SQLDataDir) -ne $true) {
    Log(" [INFO] Creating folder $SQLDataDir")
    mkdir $SQLDataDir
}
else {
    Log(" [INFO] SQLDataDir $SQLDataDir already exist")
}

for ($i = 0; $i -lt 10; $i++) {
    try {
        Log(" [INFO] Testing SQLConnection $i")
        sqlquery -SQLUserName $SQLUserName -SQLUserPassword $SQLUserPassword
        Log(" [INFO] SQL Connected")

        for ($i = 0; $i -lt 10; $i++) {
            try {
                Log(" [INFO] Starting SQL Restore")
                sqlrestore
                Log(" [INFO] Testing SQLConnection to L300DB $i")
                sqlquery -SQLUserName $SQLUserName -SQLUserPassword $SQLUserPassword -SQLDB "L300DB"
                Log(" [INFO] SQL Connected to L300DB")
                break
            }
            catch {
                Log(" [ERROR] Failed to connect to SQLDB L300DB")
                Start-Sleep -Seconds 30
                Log(" [WARNING] Sleeping for 30 seconds to wait SQLDB L300DB get ready")                
            }
        }
        break
    }
    catch {
        Log(" [ERROR] Failed to connect to SQL Server")
        Start-Sleep -Seconds 30
        Log(" [WARNING] Sleeping for 30 seconds to wait SQL")
    }    
}

Log(" [INFO] Allowing Windows Firewall ICMP")
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow

Log(" [INFO] Disabling IE Security Settings")
function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
}

Disable-InternetExplorerESC

Log(" [INFO] Script finished. Exiting Script")