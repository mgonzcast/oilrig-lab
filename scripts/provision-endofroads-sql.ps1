$ErrorActionPreference = "Continue"

Write-Host "=====================================" -ForegroundColor Green
Write-Host "Provisioning SQL Server: endofroads" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$DomainName = "boombox.com"
$DCAddress = "10.1.0.4"
$SQLIPAddress = "10.1.0.7"
$DomainAdmin = "BOOMBOX\Administrator"
$DomainPassword = "vagrant"

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

netsh.exe advfirewall set allprofiles state off

D:\setup.exe /Q /ACTION=Install /FEATURES=SQLENGINE /TCPEnabled=1 /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT="NT AUTHORITY\SYSTEM" /SQLSYSADMINACCOUNTS="BOOMBOX\Administrator" /SECURITYMODE=SQL /SAPWD="Password_123456" /IACCEPTSQLSERVERLICENSETERMS

New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow


Write-Host "`nInstallation SQL Server 2019 finished" -ForegroundColor Green

