# Quick Start Script for Windows Domain Lab

$symbols = [PSCustomObject] @{
SMILEY_WHITE = ([char]9786)
SMILEY_BLACK = ([char]9787)
GEAR = ([char]9788)
HEART = ([char]9829)
DIAMOND = ([char]9830)
CLUB = ([char]9827)
SPADE = ([char]9824)
CIRCLE = ([char]8226)
NOTE1 = ([char]9834)
NOTE2 = ([char]9835)
MALE = ([char]9794)
FEMALE = ([char]9792)
YEN = ([char]165)
COPYRIGHT = ([char]169)
PI = ([char]960)
TRADEMARK = ([char]8482)
CHECKMARK = ([char]8730)
BALLOT = ([char]10007)
}

Write-Host @"
╔═══════════════════════════════════════════════════╗
║   Windows Domain Lab - BoomBox.com Setup          ║
║   Security Testing Environment                    ║
╚═══════════════════════════════════════════════════╝
"@ -ForegroundColor Green

Write-Host "`nThis script will help you set up the lab environment.`n" -ForegroundColor Cyan

# Check for required tools
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

$tools = @{
    "Packer" = "packer"
    "Vagrant" = "vagrant"
    "VBoxManage" = "VBoxManage"
}

$missingTools = @()
foreach ($tool in $tools.GetEnumerator()) {
    try {
        $null = Get-Command $tool.Value -ErrorAction Stop
        Write-Host "  [$($symbols.CHECKMARK)] $($tool.Key) found" -ForegroundColor Green
    } catch {
        Write-Host "  [$($symbols.BALLOT)] $($tool.Key) NOT found" -ForegroundColor Red
        $missingTools += $tool.Key
    }
}

if ($missingTools.Count -gt 0) {
    Write-Host "`nMissing tools: $($missingTools -join ', ')" -ForegroundColor Red
    Write-Host "Please install them before continuing." -ForegroundColor Red
    exit 1
}

# Check for ISOs
Write-Host "`nChecking for ISO files..." -ForegroundColor Yellow
$requiredISOs = @(
    "isos\17763.3650.221105-1748.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso",
    "isos\17763.107.101029-1455.rs5_release_svc_refresh_CLIENT_LTSC_EVAL_x64FRE_en-us.iso",
    "isos\ExchangeServer2019-x64-CU11.iso",
    "isos\SQLServer2019-x64-ENU.iso"
)


$missingISOs = @()
foreach ($iso in $requiredISOs) {
    if (Test-Path $iso) {
        Write-Host "  [$($symbols.CHECKMARK)] $(Split-Path $iso -Leaf) found" -ForegroundColor Green
    } else {
        Write-Host "  [$($symbols.BALLOT)] $(Split-Path $iso -Leaf) NOT found" -ForegroundColor Red
        $missingISOs += $iso
    }
}

if ($missingISOs.Count -gt 0) {
    Write-Host "`nPlease place the required ISO files in the isos\ directory:" -ForegroundColor Yellow
    foreach ($iso in $missingISOs) {
        Write-Host "  - $(Split-Path $iso -Leaf)" -ForegroundColor Cyan
    }
    Write-Host "`nSee isos\README.md for download links.`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n$($symbols.CHECKMARK) All prerequisites met!`n" -ForegroundColor Green

# Ask user what to do
Write-Host "What would you like to do?" -ForegroundColor Cyan
Write-Host "1. Build base box with Packer (required first time, ~60 minutes)"
Write-Host "2. Deploy all VMs with Vagrant"
Write-Host "3. Deploy individual VM"
Write-Host "4. Exit"

$choice = Read-Host "`nEnter choice (1-4)"

switch ($choice) {
    "1" {
        Write-Host "`nBuilding base boxes with Packer..." -ForegroundColor Green
        Set-Location packer
        packer init .
        packer build windows-server-2019.pkr.hcl
        packer build windows-10-ltsc-17763.pkr.hcl
        
        
        Write-Host "`nAdding box to Vagrant..." -ForegroundColor Green
        Set-Location ..
        vagrant box add --name windows-server-2019 windows-server-2019-virtualbox.box
        vagrant box add --name windows-10-ltsc-17763-virtualbox.box
        
        Write-Host "`n$($symbols.CHECKMARK) Base box created successfully!" -ForegroundColor Green
        Write-Host "Run this script again and choose option 2 to deploy VMs." -ForegroundColor Yellow
    }
    
    "2" {
        Write-Host "`nDeploying all VMs (this will take time)..." -ForegroundColor Green
        Write-Host "Starting Domain Controller first..." -ForegroundColor Cyan
        vagrant up diskjockey
        
        Write-Host "`nWaiting for DC to be ready..." -ForegroundColor Cyan
        Start-Sleep -Seconds 30
        
        Write-Host "`nStarting Exchange and SQL Servers..." -ForegroundColor Cyan
        vagrant up endofroads
        vagrant up waterfalls
        
        Write-Host "`nStarting Windows 10 client..." -ForegroundColor Cyan
        vagrant up theblock

        
        Write-Host "`n$($symbols.CHECKMARK) All VMs deployed!" -ForegroundColor Green
        Write-Host "`nNext steps:" -ForegroundColor Yellow
        Write-Host "1. vagrant rdp waterfalls" -ForegroundColor Cyan
        Write-Host "2. Run: powershell -ExecutionPolicy Bypass -File C:\install-exchange.ps1" -ForegroundColor Cyan
        Write-Host "`n1. vagrant rdp endofroads" -ForegroundColor Cyan
        Write-Host "2. Run: powershell -ExecutionPolicy Bypass -File C:\install-sql.ps1" -ForegroundColor Cyan
    }
    
    "3" {
        Write-Host "`nAvailable VMs:" -ForegroundColor Cyan
        Write-Host "1. diskjockey (Domain Controller)"
        Write-Host "2. endofroads (SQL Server 2019)"
        Write-Host "3. waterfalls (Exchange 2019)"
        Write-Host "4. theblock (Windows 10)"

        
        $vmChoice = Read-Host "`nEnter VM number (1-4)"
        
        $vmName = switch ($vmChoice) {
            "1" { "diskjockey" }
            "2" { "endofroads" }
            "3" { "waterfalls" }
            "4" { "theblock" }
            
            default { Write-Host "Invalid choice" -ForegroundColor Red; exit 1 }
        }
        
        Write-Host "`nDeploying $vmName..." -ForegroundColor Green
        vagrant up $vmName
        
        Write-Host "`n$($symbols.CHECKMARK) $vmName deployed!" -ForegroundColor Green
    }
    
    "4" {
        Write-Host "`nExiting..."
	}
}
