<#
.SYNOPSIS
Cleans up the Windows installation and runs Sysprep to generalize the image.

.DESCRIPTION
This script performs standard cleanup tasks (cache, logs) and, most importantly,
runs sysprep /generalize, which is MANDATORY for creating a reusable Vagrant base box.
The /shutdown switch ensures the VM is powered off correctly for packaging.
#>

Write-Host "Running cleanup tasks..."

# Clear Windows Update cache
Write-Host "Clearing Windows Update cache and restarting service..."
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service wuauserv -ErrorAction SilentlyContinue

# Clear temp files
Write-Host "Clearing temp files..."
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
# Clean user temp directories. The 'vagrant' user must exist for this path to work.
$TempPath = Join-Path (Get-Item "C:\Users\vagrant").FullName "AppData\Local\Temp\*"
Remove-Item -Path $TempPath -Recurse -Force -ErrorAction SilentlyContinue

# Clear event logs
Write-Host "Clearing event logs..."
# FIX: Using 2>$null to suppress errors from the native wevtutil command on protected logs.
wevtutil el | ForEach-Object { wevtutil cl $_ 2>$null }

Write-Host "Cleanup finished"
