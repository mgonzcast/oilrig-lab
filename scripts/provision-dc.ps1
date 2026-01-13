# scripts/provision-dc.ps1

$ErrorActionPreference = "Continue"

Write-Host "=====================================" -ForegroundColor Green
Write-Host "Provisioning Domain Controller: diskjockey" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$DomainName = "boombox.com"
$NetbiosName = "BOOMBOX"
$SafeModePassword = "Password12345"
$DCIPAddress = "10.1.0.4"

# Check if already a Domain Controller
$isDC = $false
try {
    $domain = Get-ADDomain -ErrorAction SilentlyContinue
    if ($domain) {
        $isDC = $true
        Write-Host "Domain already configured: $($domain.DNSRoot)" -ForegroundColor Yellow
        exit 0
    }
} catch {
    $isDC = $false
}

# Disable Windows Defender
Write-Host "Disabling Windows Defender..." -ForegroundColor Cyan
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    Uninstall-WindowsFeature -Name Windows-Defender -ErrorAction SilentlyContinue
    Write-Host "Windows Defender disabled" -ForegroundColor Green
} catch {
    Write-Host "Windows Defender already disabled or not present" -ForegroundColor Yellow
}

# Wait for network to stabilize after Vagrant configuration
Write-Host "Waiting for network to stabilize..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Configure second network adapter since first one is the Vagrant one
$adapter = Get-NetAdapter | Where-Object {$_.Name -eq "Ethernet 2"} 
if ($adapter) {
    Write-Host "Network adapter found: $($adapter.Name)" -ForegroundColor Green
    
    # Verify current IP
    $currentIP = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($currentIP) {
        Write-Host "Current IP Address: $($currentIP.IPAddress)" -ForegroundColor Green
        if ($currentIP -ne $DCIPAddress) {
        Write-Host "Correcting IP Address..."
        Remove-NetRoute -InterfaceIndex $adapter.ifIndex -Confirm:$false
        Remove-NetIPAddress -InterfaceIndex $adapter.ifIndex -Confirm:$false
        New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $DCIPAddress -PrefixLength 24 -Confirm:$false -ErrorAction SilentlyContinue
        #Write-Host "New DC IP Address : $($(Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4).IPAddress)" -ForegroundColor Green
        }
    }
    
    # Only configure DNS 
    Write-Host "Configuring DNS to point to self (127.0.0.1)..." -ForegroundColor Cyan
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses "127.0.0.1"
    
    # Disable IPv6
    Write-Host "Disabling IPv6..." -ForegroundColor Cyan
    Disable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
    
    Write-Host "Network configuration complete" -ForegroundColor Green
} else {
    Write-Host "ERROR: No active network adapter found!" -ForegroundColor Red
    exit 1
}

# Set timezone
Write-Host "Setting timezone to UTC..." -ForegroundColor Cyan
Set-TimeZone -Id "UTC" -ErrorAction SilentlyContinue

# Install AD DS Role
Write-Host "Installing Active Directory Domain Services..." -ForegroundColor Cyan
$adInstall = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

if ($adInstall.Success) {
    Write-Host "AD DS Role installed successfully" -ForegroundColor Green
} else {
    Write-Host "ERROR: Failed to install AD DS Role" -ForegroundColor Red
    exit 1
}

# Install AD DS Forest
Write-Host "Creating new Active Directory forest: $DomainName..." -ForegroundColor Cyan
Write-Host "This process will take several minutes..." -ForegroundColor Yellow

$securePassword = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force

try {
    Write-Host "Configuring system for post-domain WinRM access..." -ForegroundColor Cyan
    
    # Enable local account access after domain promotion
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
        -Name "LocalAccountTokenFilterPolicy" -Value 1 -Type DWord -Force
    
    # Configure WinRM to survive domain promotion
    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    
    Write-Host "Starting domain forest installation..." -ForegroundColor Cyan
    
    Import-Module ADDSDeployment
    
    Install-ADDSForest `
        -DomainName $DomainName `
        -DomainNetbiosName $NetbiosName `
        -InstallDns:$true `
        -SafeModeAdministratorPassword $securePassword `
        -Force:$true `
        -NoRebootOnCompletion:$true `
        -WarningAction SilentlyContinue
    
    Write-Host "Domain Controller installation complete!" -ForegroundColor Green
    Write-Host "System is ready for reboot" -ForegroundColor Green
 
    exit 0
    
} catch {
    Write-Host "ERROR installing AD DS Forest: $_" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "=====================================" -ForegroundColor Green
Write-Host "DC Promotion Complete - Ready for Reboot" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
