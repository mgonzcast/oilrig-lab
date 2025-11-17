$ErrorActionPreference = "Continue"

Write-Host "=====================================" -ForegroundColor Green
Write-Host "Provisioning SQL Server: endofroads" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$DomainName = "boombox.com"
$DCAddress = "10.1.0.4"
$SQLIPAddress = "10.1.0.7"
$DomainAdmin = "BOOMBOX\Administrator"
$DomainPassword = "Password12345"

# Disable Windows Defender
Write-Host "Disabling Windows Defender..." -ForegroundColor Cyan
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    Uninstall-WindowsFeature -Name Windows-Defender -ErrorAction SilentlyContinue
} catch {
    Write-Host "Windows Defender already disabled" -ForegroundColor Yellow
}

# Configure network adapter
Write-Host "Configuring network adapter..." -ForegroundColor Cyan
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
if ($adapter) {
    Remove-NetIPAddress -InterfaceIndex $adapter.ifIndex -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceIndex $adapter.ifIndex -Confirm:$false -ErrorAction SilentlyContinue
    
    New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $SQLIPAddress -PrefixLength 24 -ErrorAction SilentlyContinue
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $DCAddress
    
    Write-Host "Network configured: $SQLIPAddress" -ForegroundColor Green
}

# Disable IPv6
Disable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue

# Wait for DC to be available
Write-Host "Waiting for Domain Controller at $DCAddress..." -ForegroundColor Cyan
$maxAttempts = 60
$attempt = 0
do {
    Start-Sleep -Seconds 5
    $dcReachable = Test-Connection -ComputerName $DCAddress -Count 1 -Quiet
    $attempt++
    if ($attempt % 10 -eq 0) {
        Write-Host "Still waiting... (attempt $attempt/$maxAttempts)" -ForegroundColor Yellow
    }
} while (-not $dcReachable -and $attempt -lt $maxAttempts)

if (-not $dcReachable) {
    Write-Host "ERROR: Cannot reach Domain Controller at $DCAddress" -ForegroundColor Red
    exit 1
}

# Check if already domain joined
$computerSystem = Get-WmiObject -Class Win32_ComputerSystem
if ($computerSystem.PartOfDomain -and $computerSystem.Domain -eq $DomainName) {
    Write-Host "Already joined to domain: $DomainName" -ForegroundColor Green
} else {
    # Join domain
    Write-Host "Joining domain: $DomainName..." -ForegroundColor Cyan
    $securePassword = ConvertTo-SecureString $DomainPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ($DomainAdmin, $securePassword)
    
    try {
        Add-Computer -DomainName $DomainName -Credential $credential -Force -ErrorAction Stop
        Write-Host "Successfully joined domain. Rebooting..." -ForegroundColor Green
        Restart-Computer -Force
        exit 0
    } catch {
        Write-Host "Error joining domain: $_" -ForegroundColor Red
        exit 1
    }
}

# Install .NET Framework 3.5 (required for SQL Server)
Write-Host "Installing .NET Framework 3.5..." -ForegroundColor Cyan
Install-WindowsFeature -Name NET-Framework-Core

# Install .NET Framework 4.8
Write-Host "Downloading .NET Framework 4.8..." -ForegroundColor Cyan
$downloadPath = "C:\Temp"
New-Item -ItemType Directory -Path $downloadPath -Force | Out-Null

$dotNetUrl = "https://go.microsoft.com/fwlink/?linkid=2088631"
$dotNetPath = "$downloadPath\ndp48-x86-x64-allos-enu.exe"

try {
    Invoke-WebRequest -Uri $dotNetUrl -OutFile $dotNetPath -UseBasicParsing
    Write-Host "Installing .NET Framework 4.8..." -ForegroundColor Cyan
    Start-Process -FilePath $dotNetPath -ArgumentList "/q /norestart" -Wait
    Write-Host ".NET Framework 4.8 installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error downloading/installing .NET 4.8: $_" -ForegroundColor Red
}

# Create SQL Server configuration file
Write-Host "Creating SQL Server configuration file..." -ForegroundColor Cyan
$sqlConfigPath = "C:\Temp\ConfigurationFile.ini"

$sqlConfig = @"
[OPTIONS]
ACTION="Install"
QUIET="True"
FEATURES=SQLENGINE,REPLICATION,FULLTEXT,RS,AS,IS
INSTANCENAME="MSSQLSERVER"
INSTANCEID="MSSQLSERVER"
SQLSVCACCOUNT="NT AUTHORITY\SYSTEM"
SQLSYSADMINACCOUNTS="BOOMBOX\Administrator"
AGTSVCACCOUNT="NT AUTHORITY\SYSTEM"
ASSVCACCOUNT="NT AUTHORITY\SYSTEM"
ISSVCACCOUNT="NT AUTHORITY\SYSTEM"
RSSVCACCOUNT="NT AUTHORITY\SYSTEM"
TCPENABLED="1"
NPENABLED="1"
BROWSERSVCSTARTUPTYPE="Automatic"
SQLBACKUPDIR="C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup"
SQLUSERDBDIR="C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA"
SQLUSERDBLOGDIR="C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA"
SQLTEMPDBDIR="C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA"
SQLTEMPDBLOGDIR="C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA"
IACCEPTSQLSERVERLICENSETERMS="True"
"@

Set-Content -Path $sqlConfigPath -Value $sqlConfig -Encoding ASCII

Write-Host "`n=====================================" -ForegroundColor Green
Write-Host "SQL Server Prerequisites Complete" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host "`nTo install SQL Server 2019:" -ForegroundColor Yellow
Write-Host "1. Mount the SQL Server 2019 ISO (should be at D:\)" -ForegroundColor Yellow
Write-Host "2. Open PowerShell as Administrator" -ForegroundColor Yellow
Write-Host "3. Run the automated installation script:" -ForegroundColor Yellow
Write-Host "   powershell -ExecutionPolicy Bypass -File C:\install-sql.ps1" -ForegroundColor Cyan
Write-Host "`nOr manually run:" -ForegroundColor Yellow
Write-Host "   D:\Setup.exe /ConfigurationFile=C:\Temp\ConfigurationFile.ini" -ForegroundColor Cyan

# Create automated SQL installation script
$installSQLScript = @'
$ErrorActionPreference = "Stop"

Write-Host "Starting automated SQL Server 2019 installation..." -ForegroundColor Green

$sqlIso = "D:"
$setupPath = "$sqlIso\Setup.exe"
$configPath = "C:\Temp\ConfigurationFile.ini"

if (-not (Test-Path $setupPath)) {
    Write-Host "ERROR: SQL Server setup not found at $setupPath" -ForegroundColor Red
    Write-Host "Please ensure SQL Server 2019 ISO is mounted" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $configPath)) {
    Write-Host "ERROR: Configuration file not found at $configPath" -ForegroundColor Red
    exit 1
}

Write-Host "Installing SQL Server 2019..." -ForegroundColor Cyan
Write-Host "This may take 30-60 minutes..." -ForegroundColor Yellow

$process = Start-Process -FilePath $setupPath -ArgumentList "/ConfigurationFile=$configPath" -Wait -PassThru

if ($process.ExitCode -eq 0) {
    Write-Host "`nSQL Server 2019 installation complete!" -ForegroundColor Green
    Write-Host "Configuring SQL Server..." -ForegroundColor Cyan
    
    # Enable SQL Server Browser
    Set-Service -Name SQLBrowser -StartupType Automatic
    Start-Service -Name SQLBrowser
    
    # Configure firewall rules
    New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
    New-NetFirewallRule -DisplayName "SQL Browser" -Direction Inbound -Protocol UDP -LocalPort 1434 -Action Allow
    
    Write-Host "SQL Server configuration complete!" -ForegroundColor Green
    Write-Host "`nConnection Details:" -ForegroundColor Yellow
    Write-Host "  Server: endofroads.boombox.com" -ForegroundColor Cyan
    Write-Host "  Instance: MSSQLSERVER (default)" -ForegroundColor Cyan
    Write-Host "  Authentication: Windows Authentication" -ForegroundColor Cyan
    Write-Host "  Admin Account: BOOMBOX\Administrator" -ForegroundColor Cyan
} else {
    Write-Host "`nERROR: SQL Server installation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
    Write-Host "Check the setup logs in: C:\Program Files\Microsoft SQL Server\150\Setup Bootstrap\Log" -ForegroundColor Yellow
    exit 1
}
'@

Set-Content -Path "C:\install-sql.ps1" -Value $installSQLScript -Encoding UTF8
Write-Host "`nAutomated installation script created at: C:\install-sql.ps1" -ForegroundColor Green

