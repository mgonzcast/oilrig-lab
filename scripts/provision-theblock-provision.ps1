$ErrorActionPreference = "Continue"

Write-Host "=====================================" -ForegroundColor Green
Write-Host "Provisioning Windows 10 Client: theblock" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$DomainName = "boombox.com"
$DCAddress = "10.1.0.4"
$ClientIPAddress = "10.1.0.5"
$DomainAdmin = "BOOMBOX\Administrator"
$DomainPassword = "vagrant"
$AdapterName = "Ethernet"

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
        #Restart-Computer -Force
        exit 0
    } catch {
        Write-Host "Error joining domain: $_" -ForegroundColor Red
        exit 1
    }
}

# REVERT DNS TO DHCP so RSAT Capabilities can be installed
Write-Host "Reverting DNS on '$AdapterName' to DHCP for internet access..." -ForegroundColor Cyan
try {
    # This resets the DNS server addresses to be obtained via DHCP
    Set-DnsClientServerAddress -InterfaceAlias $AdapterName -ResetServerAddresses -ErrorAction Stop
    
    # Optional: Force a DNS registration refresh
    Register-DnsClient
    
    Write-Host "DNS reverted to DHCP. Waiting 5s for network to stabilize..." -ForegroundColor Green
    Start-Sleep -Seconds 5
} catch {
    Write-Host "Warning: Could not reset DNS. Checking if interface name is correct..." -ForegroundColor Yellow
    Get-NetAdapter | Select-Object Name, InterfaceAlias, Status
}


Write-Host "Installing Windows features..." -ForegroundColor Cyan

sc.exe config "wuauserv" start=demand

Get-WindowsCapability -Name RSAT* -Online | Add-windowsCapability -Online



