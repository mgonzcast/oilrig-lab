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

Write-Host "Enabling gosta mailbox..." -ForegroundColor Cyan

# 2. Convert the plain text password to a SecureString object
$secpasswd = ConvertTo-SecureString $DomainPassword -AsPlainText -Force

# 3. Create a PSCredential object
$cred = New-Object System.Management.Automation.PSCredential($DomainAdmin, $secpasswd)

# 4. Define the Exchange server connection URI
# Replace "your_exchange_server" with the actual FQDN or IP of your Exchange server
$SessionUri = "http://$ExchIPAddress/powershell" 

# 5. Create a new PSSession with the specified credentials and configuration
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $SessionUri -Credential $cred -Authentication Kerberos 

# 6. Import the cmdlets from the remote session into your local PowerShell session
Import-PSSession $Session -DisableNameChecking

# 7. Now you can run Enable-Mailbox
# Replace "username" with the identity of the user you want to enable a mailbox for
Enable-Mailbox -Identity "gosta@boombox.com" 

# 8. (Optional) When finished, close the session
Remove-PSSession $Session




