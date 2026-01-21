$ErrorActionPreference = "Continue"

Write-Host "=====================================" -ForegroundColor Green
Write-Host "Provisioning SQL Server: endofroads" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$DomainName = "boombox.com"
$DCAddress = "10.1.0.4"
$SQLIPAddress = "10.1.0.7"
$DomainAdmin = "BOOMBOX\Administrator"
$DomainPassword = "vagrant"

# Disable Windows Defender
Write-Host "Disabling Windows Defender..." -ForegroundColor Cyan
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    Uninstall-WindowsFeature -Name Windows-Defender -ErrorAction SilentlyContinue
} catch {
    Write-Host "Windows Defender already disabled" -ForegroundColor Yellow
}

# Configure second network adapter since first one is the Vagrant one
Write-Host "Configuring network adapter..." -ForegroundColor Cyan
$adapter = Get-NetAdapter | Where-Object {$_.Name -eq "Ethernet 2"} 
if ($adapter) {
    Write-Host "Network adapter found: $($adapter.Name)" -ForegroundColor Green

    # Verify current IP
    $currentIP = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    
    if ($currentIP){
    
        Write-Host "Current IP Address: $($currentIP.IPAddress)" -ForegroundColor Green
        if ($currentIP -ne $SQLIPAddress) {
          Write-Host "Correcting IP Address..."
          #Remove-NetRoute -InterfaceIndex $adapter.ifIndex -Confirm:$false
          Remove-NetIPAddress -InterfaceIndex $adapter.ifIndex -Confirm:$false
    
          New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $SQLIPAddress -PrefixLength 24 -ErrorAction SilentlyContinue
          Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $DCAddress
          #Write-Host "Network configured: $SQLIPAddress" -ForegroundColor Green
        }
    }
}


Write-Host "Setting DNS for Vagrant NIC..." -ForegroundColor Yellow
# Set DNS the Vagrant NIC to our DC so no request goes to the Internet through NAT
$adapterVagrant = Get-NetAdapter | Where-Object {$_.Name -eq "Ethernet"} 
Set-DnsClientServerAddress -InterfaceIndex $adapterVagrant.ifIndex -ServerAddresses $DCAddress


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

