$ErrorActionPreference = "Continue"

Write-Host "=====================================" -ForegroundColor Green
Write-Host "Provisioning Exchange Server: waterfalls" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$DomainName = "boombox.com"
$DCAddress = "10.1.0.4"
$ExchIPAddress = "10.1.0.6"
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
    
    New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $ExchIPAddress -PrefixLength 24 -ErrorAction SilentlyContinue
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $DCAddress
    
    Write-Host "Network configured: $ExchIPAddress" -ForegroundColor Green
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

# Install Exchange prerequisites
Write-Host "Installing Exchange 2019 prerequisites..." -ForegroundColor Cyan

# Install required Windows features
$features = @(
    "NET-Framework-45-Features",
    "RPC-over-HTTP-proxy",
    "RSAT-Clustering",
    "RSAT-Clustering-CmdInterface",
    "RSAT-Clustering-Mgmt",
    "RSAT-Clustering-PowerShell",
    "Web-Mgmt-Console",
    "WAS-Process-Model",
    "Web-Asp-Net45",
    "Web-Basic-Auth",
    "Web-Client-Auth",
    "Web-Digest-Auth",
    "Web-Dir-Browsing",
    "Web-Dyn-Compression",
    "Web-Http-Errors",
    "Web-Http-Logging",
    "Web-Http-Redirect",
    "Web-Http-Tracing",
    "Web-ISAPI-Ext",
    "Web-ISAPI-Filter",
    "Web-Lgcy-Mgmt-Console",
    "Web-Metabase",
    "Web-Mgmt-Service",
    "Web-Net-Ext45",
    "Web-Request-Monitor",
    "Web-Server",
    "Web-Stat-Compression",
    "Web-Static-Content",
    "Web-Windows-Auth",
    "Web-WMI",
    "Windows-Identity-Foundation",
    "RSAT-ADDS"
)

Write-Host "Installing Windows features..." -ForegroundColor Cyan
Install-WindowsFeature -Name $features -IncludeManagementTools

# Download and install prerequisites
$downloadPath = "C:\Temp"
New-Item -ItemType Directory -Path $downloadPath -Force | Out-Null

Write-Host "Downloading Unified Communications Managed API 4.0..." -ForegroundColor Cyan
$ucmaUrl = "https://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe"
$ucmaPath = "$downloadPath\UcmaRuntimeSetup.exe"

try {
    Invoke-WebRequest -Uri $ucmaUrl -OutFile $ucmaPath -UseBasicParsing
    Write-Host "Installing UCMA 4.0..." -ForegroundColor Cyan
    Start-Process -FilePath $ucmaPath -ArgumentList "/quiet /norestart" -Wait
    Write-Host "UCMA 4.0 installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error downloading/installing UCMA: $_" -ForegroundColor Red
}

# Install Visual C++ Redistributable 2013
Write-Host "Downloading Visual C++ 2013 Redistributable..." -ForegroundColor Cyan
$vcRedistUrl = "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD0D31A9/vcredist_x64.exe"
$vcRedistPath = "$downloadPath\vcredist_x64.exe"

try {
    Invoke-WebRequest -Uri $vcRedistUrl -OutFile $vcRedistPath -UseBasicParsing
    Write-Host "Installing Visual C++ 2013..." -ForegroundColor Cyan
    Start-Process -FilePath $vcRedistPath -ArgumentList "/quiet /norestart" -Wait
    Write-Host "Visual C++ 2013 installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error downloading/installing Visual C++ 2013: $_" -ForegroundColor Red
}

# Check for Exchange ISO
Write-Host "`n=====================================" -ForegroundColor Green
Write-Host "Exchange Prerequisites Complete" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host "`nTo install Exchange 2019:" -ForegroundColor Yellow
Write-Host "1. Mount the Exchange 2019 ISO (should be at D:\)" -ForegroundColor Yellow
Write-Host "2. Open PowerShell as Administrator" -ForegroundColor Yellow
Write-Host "3. Run: D:\Setup.exe /PrepareSchema /IAcceptExchangeServerLicenseTerms" -ForegroundColor Yellow
Write-Host "4. Run: D:\Setup.exe /PrepareAD /OrganizationName:BoomBox /IAcceptExchangeServerLicenseTerms" -ForegroundColor Yellow
Write-Host "5. Run: D:\Setup.exe /Mode:Install /Role:Mailbox /IAcceptExchangeServerLicenseTerms" -ForegroundColor Yellow
Write-Host "`nOr use the automated installation script:" -ForegroundColor Yellow
Write-Host "powershell -ExecutionPolicy Bypass -File C:\vagrant\scripts\install-exchange.ps1" -ForegroundColor Cyan

# Create automated Exchange installation script
$installExchangeScript = @'
$ErrorActionPreference = "Stop"

Write-Host "Starting automated Exchange 2019 installation..." -ForegroundColor Green

$exchangeIso = "D:"
$setupPath = "$exchangeIso\Setup.exe"

if (-not (Test-Path $setupPath)) {
    Write-Host "ERROR: Exchange setup not found at $setupPath" -ForegroundColor Red
    Write-Host "Please ensure Exchange 2019 ISO is mounted" -ForegroundColor Red
    exit 1
}

# Prepare Schema
Write-Host "Preparing Active Directory Schema..." -ForegroundColor Cyan
& $setupPath /PrepareSchema /IAcceptExchangeServerLicenseTerms

# Prepare AD
Write-Host "Preparing Active Directory..." -ForegroundColor Cyan
& $setupPath /PrepareAD /OrganizationName:"BoomBox" /IAcceptExchangeServerLicenseTerms

# Install Exchange
Write-Host "Installing Exchange 2019 Mailbox Role..." -ForegroundColor Cyan
& $setupPath /Mode:Install /Role:Mailbox /IAcceptExchangeServerLicenseTerms

Write-Host "Exchange 2019 installation complete!" -ForegroundColor Green
'@

Set-Content -Path "C:\install-exchange.ps1" -Value $installExchangeScript -Encoding UTF8
Write-Host "`nAutomated installation script created at: C:\install-exchange.ps1" -ForegroundColor Green
