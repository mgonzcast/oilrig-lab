$ErrorActionPreference = "Continue"

Write-Host "=====================================" -ForegroundColor Green
Write-Host "Provisioning Domain Controller: diskjockey" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$DomainName = "boombox.com"
$NetbiosName = "BOOMBOX"
$SafeModePassword = "Password12345"
$DCIPAddress = "10.1.0.4"

# Disable Windows Defender
Write-Host "Disabling Windows Defender..." -ForegroundColor Cyan
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    Uninstall-WindowsFeature -Name Windows-Defender -ErrorAction SilentlyContinue
} catch {
    Write-Host "Windows Defender already disabled or not present" -ForegroundColor Yellow
}

# Configure network adapter
Write-Host "Configuring network adapter..." -ForegroundColor Cyan
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
if ($adapter) {
    # Remove existing IP configuration
    Remove-NetIPAddress -InterfaceIndex $adapter.ifIndex -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceIndex $adapter.ifIndex -Confirm:$false -ErrorAction SilentlyContinue
    
    # Set static IP
    New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $DCIPAddress -PrefixLength 24 -ErrorAction SilentlyContinue
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $DCIPAddress
    
    Write-Host "Network configured: $DCIPAddress" -ForegroundColor Green
}

# Disable IPv6
Write-Host "Disabling IPv6..." -ForegroundColor Cyan
Disable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue

# Set timezone
Write-Host "Setting timezone..." -ForegroundColor Cyan
Set-TimeZone -Id "UTC" -ErrorAction SilentlyContinue

# Install AD DS Role
Write-Host "Installing Active Directory Domain Services..." -ForegroundColor Cyan
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Check if domain already exists
$isDC = $false
try {
    $domain = Get-ADDomain -ErrorAction SilentlyContinue
    if ($domain) {
        $isDC = $true
        Write-Host "Domain already configured: $($domain.DNSRoot)" -ForegroundColor Yellow
    }
} catch {
    $isDC = $false
}

if (-not $isDC) {
    # Install AD DS Forest
    Write-Host "Creating new Active Directory forest: $DomainName..." -ForegroundColor Cyan
    $securePassword = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force
    
    try {
        # Before Install-ADDSForest
	Write-Host "Configuring system for post-domain WinRM access..."
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" ` -Name "LocalAccountTokenFilterPolicy" -Value 1 -Type DWord -Force
	
        Install-ADDSForest `
            -DomainName $DomainName `
            -DomainNetbiosName $NetbiosName `
           # -ForestMode "WinThreshold" `
           # -DomainMode "WinThreshold" `
            -InstallDns:$true `
            -SafeModeAdministratorPassword $securePassword `
            -Force:$true `
            -NoRebootOnCompletion:$true
        
        Write-Host "Domain Controller installation complete. System will reboot..." -ForegroundColor Green
    } catch {
        Write-Host "Error installing AD DS: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Domain Controller already configured. Skipping installation." -ForegroundColor Green
}
