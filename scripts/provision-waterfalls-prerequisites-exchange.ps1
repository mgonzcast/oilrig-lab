$ErrorActionPreference = "Continue"

Write-Host "=====================================" -ForegroundColor Green
Write-Host "Provisioning Exchange Server: waterfalls" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$DomainName = "boombox.com"
$DCAddress = "10.1.0.4"
$ExchIPAddress = "10.1.0.6"
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

# Install Exchange prerequisites
Write-Host "Installing Exchange 2019 prerequisites..." -ForegroundColor Cyan

Write-Host "Installing Windows features..." -ForegroundColor Cyan
Install-WindowsFeature Web-WebServer,Web-Common-Http,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Static-Content,Web-Http-Redirect,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Security,Web-Filtering,Web-Basic-Auth,Web-Client-Auth,Web-Digest-Auth,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext45,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Mgmt-Tools,Web-Mgmt-Compat,Web-Metabase,Web-WMI,Web-Mgmt-Service,NET-Framework-45-ASPNET,NET-WCF-HTTP-Activation45,NET-WCF-MSMQ-Activation45,NET-WCF-Pipe-Activation45,NET-WCF-TCP-Activation45,Server-Media-Foundation,MSMQ-Services,MSMQ-Server,RSAT-Feature-Tools,RSAT-Clustering,RSAT-Clustering-PowerShell,RSAT-Clustering-CmdInterface,RPC-over-HTTP-Proxy,WAS-Process-Model,WAS-Config-APIs,Server-Media-Foundation, RSAT-ADDS


# Download and install prerequisites
$downloadPath = "C:\Temp"
New-Item -ItemType Directory -Path $downloadPath -Force | Out-Null

#Write-Host "Downloading Unified Communications Managed API 4.0..." -ForegroundColor Cyan
#$ucmaUrl = "https://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe"
#$ucmaPath = "$downloadPath\UcmaRuntimeSetup.exe"
$ucmaPath = "D:\UCMARedist\Setup.exe"

try {
    #Invoke-WebRequest -Uri $ucmaUrl -OutFile $ucmaPath -UseBasicParsing
    Write-Host "Installing UCMA 4.0..." -ForegroundColor Cyan
    #Start-Process -FilePath $ucmaPath -ArgumentList "/quiet /norestart" -Wait
    Start-Process -FilePath $ucmaPath -ArgumentList "/passive /promptrestart" -Wait
    Write-Host "UCMA 4.0 installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error downloading/installing UCMA: $_" -ForegroundColor Red
}

# Install Visual C++ Redistributable 2013
Write-Host "Downloading Visual C++ 2013 Redistributable..." -ForegroundColor Cyan
$vcRedistUrl = "https://download.microsoft.com/download/2/e/6/2e61cfa4-993b-4dd4-91da-3737cd5cd6e3/vcredist_x64.exe" 
$vcRedistPath = "$downloadPath\vcredist_x64.exe"

try {
    Invoke-WebRequest -Uri $vcRedistUrl -OutFile $vcRedistPath -UseBasicParsing
    Write-Host "Installing Visual C++ 2013..." -ForegroundColor Cyan
    Start-Process -FilePath $vcRedistPath -ArgumentList "/quiet /norestart" -Wait
    Write-Host "Visual C++ 2013 installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error downloading/installing Visual C++ 2013: $_" -ForegroundColor Red
}

# Install Rewrite AMD 64
Write-Host "Downloading Rewrite AMD 64 Redistributable..." -ForegroundColor Cyan
$vcRewriteUrl = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi" 
$vcRewritePath = "$downloadPath\rewrite_amd64_en-US.msi"

try {
    Invoke-WebRequest -Uri $vcRewriteUrl -OutFile $vcRewritePath -UseBasicParsing
    Write-Host "Installing Rewrite ..." -ForegroundColor Cyan
    Start-Process -FilePath $vcRewritePath -ArgumentList "/quiet /norestart" -Wait
    Write-Host "Rewrite installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error downloading/installing Rewrite $_" -ForegroundColor Red
}

# Install .NET 4.8
Write-Host "Downloading .NET 4.8 Redistributable..." -ForegroundColor Cyan
$vcNet48Url = "https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/c8c829444416e811be84c5765ede6148/ndp48-devpack-enu.exe" 
$vcNet48Path = "$downloadPath\ndp48-devpack-enu.exe"

try {
    Invoke-WebRequest -Uri $vcNet48Url -OutFile $vcNet48Path -UseBasicParsing
    Write-Host "Installing .NET 4.8  ..." -ForegroundColor Cyan
    Start-Process -FilePath $vcNet48Path -ArgumentList "/quiet /norestart" -Wait
    Write-Host "Rewrite installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error downloading/installing .NET 4.8 $_" -ForegroundColor Red
}

# Set Administrator Primary Group to Schema Admins
# https://absoblogginlutely.net/fixed-the-active-directory-schema-isnt-up-to-date-and-this-user-account-isnt-a-member-of-the-schema-admins-and-or-enterprise-admins-groups/

# 1. Define the username and the target primary group name
$userName = "BOOMBOX\Administrator"
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



Write-Host "`n================================================" -ForegroundColor Green
Write-Host "Exchange Prerequisites Complete" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green






