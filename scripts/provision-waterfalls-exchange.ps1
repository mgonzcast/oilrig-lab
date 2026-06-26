$ErrorActionPreference = "Continue"

Write-Host "=====================================" -ForegroundColor Green
Write-Host "Provisioning Exchange Server: waterfalls" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$DomainName = "boombox.com"
$DCAddress = "10.1.0.4"
$ExchIPAddress = "10.1.0.6"
$DomainAdmin = "BOOMBOX\Administrator"
$DomainPassword = "vagrant"

Write-Host "`n=====================================" -ForegroundColor Green
Write-Host "`nTo install Exchange 2019:" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Green

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
& $setupPath /IAcceptExchangeServerLicenseTerms_DiagnosticDataON /PrepareSchema

# Prepare AD
Write-Host "Preparing Active Directory..." -ForegroundColor Cyan
& $setupPath /IAcceptExchangeServerLicenseTerms_DiagnosticDataON /PrepareAD /OrganizationName:"Boombox"

# Install Exchange
Write-Host "Installing Exchange 2019 Mailbox Role..." -ForegroundColor Cyan
& $setupPath /m:install /roles:m /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /InstallWindowsComponents 

Write-Host "Exchange 2019 installation complete!" -ForegroundColor Green





