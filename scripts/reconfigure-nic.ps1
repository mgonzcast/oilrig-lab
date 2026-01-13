<#
.SYNOPSIS
Reconfigures the IP address and DNS settings for the single active network adapter.

.DESCRIPTION
This is run after the host-level VBoxManage script moves the internal network 
from Adapter 2 to Adapter 1, which causes Windows to lose its IP configuration.
It relies on the fact that the only active adapter is the one we want to configure.
#>

$ErrorActionPreference = "Stop"

$DC_IP = "10.1.0.4"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Starting Guest NIC Reconfiguration" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# 1. Find the active adapter
try {
    # Find the last adapter that is UP. 
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.Name -like 'Ethernet*' } | Select-Object -First 1
    
    if (-not $adapter) {
        throw "Could not find an active Ethernet adapter."
    }
    
    Write-Host "Found adapter '$($adapter.Name)' with index $($adapter.ifIndex)." -ForegroundColor Green
    
    # 2. Configure the static IP address
    Write-Host "Setting IP Address to $DC_IP..." -ForegroundColor Cyan
    # Remove existing IP configurations if any (to prevent conflicts)
    Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
    
    # Set the new IP
    New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $DC_IP -PrefixLength 24 -ErrorAction Stop
    
    # 3. Configure DNS
    Write-Host "Setting DNS Server to self (127.0.0.1)..." -ForegroundColor Cyan
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses "127.0.0.1" -ErrorAction Stop

    Write-Host "Network configuration successful." -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: Failed to configure NIC inside the VM: $_" -ForegroundColor Red
    exit 1
}

# 4. Final check and stabilization
Write-Host "Sleeping for 10 seconds to allow network stack to stabilize..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

Write-Host "Guest NIC Reconfiguration Complete." -ForegroundColor Green
