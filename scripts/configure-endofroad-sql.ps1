$ErrorActionPreference = "Continue"

Write-Host "`n==============================================" -ForegroundColor Green
Write-Host "`nConfiguring permissions SQL Server: endofroad" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green

$DomainName = "boombox.com"
$DCAddress = "10.1.0.4"
$SQLIPAddress = "10.1.0.7"
$DomainAdmin = "BOOMBOX\Administrator"
$DomainPassword = "vagrant"

$SQLAdminUser = "sa"
$SQLAdminPassword = "Password_123456"


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

Add-LocalGroupMember -Group administrators -member "BOOMBOX\SQL Admins"

Write-Host "`nAdding SQL Admins to Local Administrators"

# Check SQL admins were added

Get-LocalGroupMember administrators

Write-Host "`nConfiguring SQL Admins permissions"

# We run this command as administrator

"USE master`nCREATE LOGIN [BOOMBOX\SQL Admins] FROM WINDOWS`nGRANT ADMINISTER BULK OPERATIONS TO [BOOMBOX\SQL Admins]`nALTER SERVER ROLE sysadmin ADD MEMBER [BOOMBOX\SQL Admins]`n`n`nGO" | Out-File C:\tmp\sql_configuration.sql

# 2. Convert the plain text password to a SecureString object
#$secpasswd = ConvertTo-SecureString $DomainPassword -AsPlainText -Force

# 3. Create a PSCredential object
#$cred = New-Object System.Management.Automation.PSCredential($DomainAdmin, $secpasswd)

Invoke-Sqlcmd -InputFile "C:\tmp\sql_configuration.sql" -Username $SQLAdminUser -Password $SQLAdminPassword

Write-Host "`nConfiguration of SQL Server 2019 finished" -ForegroundColor Green


