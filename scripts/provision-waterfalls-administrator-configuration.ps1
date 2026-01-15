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

#Without adding EWS Admins to local administrators, gosta can´t RDP to waterfalls
Add-LocalGroupMember -Group administrators -member "BOOMBOX\EWS Admins"
Write-Host "";Write-Host "Adding EWS Admins to Local Administrators"

Write-Host "Granting BOOMBOX\Administrator explicit access to local WinRM group..."
net localgroup "Remote Management Users" "BOOMBOX\Administrator" /add

# Set Administrator Primary Group to Schema Admins
# https://absoblogginlutely.net/fixed-the-active-directory-schema-isnt-up-to-date-and-this-user-account-isnt-a-member-of-the-schema-admins-and-or-enterprise-admins-groups/

# 1. Define the username and the target primary group name
$userName = "CN=Administrator,CN=Users,DC=boombox,DC=com"
$groupName = "Schema Admins"

# 2. Ensure the user is a member of the group first (if not already)
# This step is crucial; you cannot set a non-member as the primary group
try {
    Add-ADGroupMember -Identity $groupName -Members $userName -ErrorAction Stop
    Write-Host "User $userName added to $groupName (if not already a member)."
}
catch {
    Write-Host "Could not add user to group, check permissions or if they are already a member." -ForegroundColor Yellow
}

# 3. Get the SID of the new primary group
try {
    $group = Get-ADGroup -Identity $groupName -ErrorAction Stop
    $groupSid = $group.SID
    # The PrimaryGroupID is the last part of the SID
    $primaryGroupID = $groupSid.Value.Substring($groupSid.Value.LastIndexOf('-') + 1)
}
catch {
    Write-Host "Error: Unable to find the Group SID for $groupName. Check the group name." -ForegroundColor Red
    exit
}

# 4. Set the PrimaryGroupID attribute for the user object
try {
    # We use Set-ADObject with the -Replace parameter to change the primaryGroupID attribute
    Set-ADObject -Identity $userName -Replace @{primaryGroupID = "$primaryGroupID"} -ErrorAction Stop
    Write-Host "$groupName set as primary group for user $userName successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error: Unable to set the primary group for $userName. Check permissions." -ForegroundColor Red
}




