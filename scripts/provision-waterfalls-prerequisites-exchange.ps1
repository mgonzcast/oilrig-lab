$ErrorActionPreference = "Continue"


$FlagFile = "C:\temp\exchange_setup_triggered.flag"
$InstallersSource = "C:\vagrant\installers" # Path mapped via Vagrant synced folder
$TempPath = "C:\Temp"

$DomainName = "boombox.com"
$DCAddress = "10.1.0.4"
$ExchIPAddress = "10.1.0.6"
$DomainAdmin = "BOOMBOX\Administrator"
$DomainPassword = "vagrant"

if (Test-Path $FlagFile) {
    Write-Host "Exchange setup was already triggered in a previous session. Exiting." -ForegroundColor Yellow
    exit
}

Write-Host "=====================================" -ForegroundColor Green
Write-Host "Provisioning Exchange Server: waterfalls" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# 1. Ensure Temp directory exists
if (!(Test-Path $TempPath)) { New-Item -ItemType Directory -Path $TempPath -Force }

# 2. Function to "Cache" or Download
function Install-Requirement {
    param (
        [string]$FileName,
        [string]$Url,
        [string]$Arguments = "/quiet /norestart"
    )
    
    $LocalPath = Join-Path $InstallersSource $FileName
    $DestinationPath = Join-Path $TempPath $FileName

    if (Test-Path $LocalPath) {
        Write-Host "Found cached installer for $FileName. Copying..." -ForegroundColor Cyan
        Copy-Item -Path $LocalPath -Destination $DestinationPath -Force
    } else {
        Write-Host "Installer $FileName not found in cache. Downloading from web..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $Url -OutFile $DestinationPath -UseBasicParsing
    }

    Write-Host "Installing $FileName..." -ForegroundColor Cyan
    $proc = Start-Process -FilePath $DestinationPath -ArgumentList $Arguments -Wait -PassThru
    
    if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
        Write-Host "$FileName installed successfully (Exit Code: $($proc.ExitCode))" -ForegroundColor Green
    } else {
        Write-Error "Failed to install $FileName (Exit Code: $($proc.ExitCode))"
    }
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

netsh.exe advfirewall set allprofiles state off


# --- WINDOWS FEATURES ---
Write-Host "Installing Windows Features (this may take a while)..." -ForegroundColor Cyan
$Features = @(
    "Web-WebServer","Web-Common-Http","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors",
    "Web-Static-Content","Web-Http-Redirect","Web-Health","Web-Http-Logging","Web-Log-Libraries",
    "Web-Request-Monitor","Web-Http-Tracing","Web-Performance","Web-Stat-Compression",
    "Web-Dyn-Compression","Web-Security","Web-Filtering","Web-Basic-Auth","Web-Client-Auth",
    "Web-Digest-Auth","Web-Windows-Auth","Web-App-Dev","Web-Net-Ext45","Web-Asp-Net45",
    "Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Mgmt-Tools","Web-Mgmt-Compat","Web-Metabase",
    "Web-WMI","Web-Mgmt-Service","NET-Framework-45-ASPNET","NET-WCF-HTTP-Activation45",
    "NET-WCF-MSMQ-Activation45","NET-WCF-Pipe-Activation45","NET-WCF-TCP-Activation45",
    "Server-Media-Foundation","MSMQ-Services","MSMQ-Server","RSAT-Feature-Tools","RSAT-Clustering",
    "RSAT-Clustering-PowerShell","RSAT-Clustering-CmdInterface","RPC-over-HTTP-Proxy",
    "WAS-Process-Model","WAS-Config-APIs","RSAT-ADDS"
)
Install-WindowsFeature $Features

# --- REDISTRIBUTABLES ---
# UCMA 4.0

$ucmaPath = "D:\UCMARedist\Setup.exe"

try {
    #Invoke-WebRequest -Uri $ucmaUrl -OutFile $ucmaPath -UseBasicParsing
    Write-Host "Installing UCMA 4.0..." -ForegroundColor Cyan
    #Start-Process -FilePath $ucmaPath -ArgumentList "/quiet /norestart" -Wait
    Start-Process -FilePath $ucmaPath -ArgumentList "/passive /promptrestart" -Wait
    Write-Host "UCMA 4.0 installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error installing UCMA: $_" -ForegroundColor Red
}

# Visual C++ 2013
Install-Requirement `
    -FileName "vcredist_x64.exe" `
    -Url "https://download.microsoft.com/download/2/e/6/2e61cfa4-993b-4dd4-91da-3737cd5cd6e3/vcredist_x64.exe"

# IIS Rewrite Module
Install-Requirement `
    -FileName "rewrite_amd64_en-US.msi" `
    -Url "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"

# .NET 4.8 Dev Pack
Install-Requirement `
    -FileName "ndp48-devpack-enu.exe" `
    -Url "https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/c8c829444416e811be84c5765ede6148/ndp48-devpack-enu.exe"

# Create the flag so it doesn't run again
New-Item -Path $FlagFile -ItemType File -Force

Write-Host "`n================================================" -ForegroundColor Green
Write-Host "Exchange Prerequisites Complete" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green



