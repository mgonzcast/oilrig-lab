Write-Host "Installing VirtualBox Guest Additions..."

$isoPath = "C:\Windows\Temp\windows.iso"

if (Test-Path $isoPath) {
    Write-Host "Mounting Guest Additions ISO..."
    $mount = Mount-DiskImage -ImagePath $isoPath -PassThru
    $driveLetter = ($mount | Get-Volume).DriveLetter
    
    if ($driveLetter) {
        Write-Host "Mounted to drive: ${driveLetter}:"
        Write-Host "Installing Guest Additions (this may take several minutes)..."
        
        # Install with certificate support and no reboot
        $installerPath = "${driveLetter}:\VBoxWindowsAdditions.exe"
        
        if (Test-Path $installerPath) {
            $arguments = @(
                '/S',           # Silent install
                '/with_wddm',   # Include WDDM driver
                '/norestart'    # Don't restart automatically
            )
            
            $process = Start-Process -FilePath $installerPath -ArgumentList $arguments -Wait -PassThru
            
            Write-Host "Guest Additions installation completed with exit code: $($process.ExitCode)"
            
            # Exit codes: 0 = success, 3010 = success but reboot required
            if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                Write-Host "Guest Additions installed successfully!"
            } else {
                Write-Host "WARNING: Guest Additions installation may have encountered issues."
            }
        } else {
            Write-Host "ERROR: VBoxWindowsAdditions.exe not found on the mounted ISO!"
        }
        
        Write-Host "Dismounting ISO..."
        Dismount-DiskImage -ImagePath $isoPath
    } else {
        Write-Host "ERROR: Could not get drive letter for mounted ISO!"
    }
    
    Write-Host "Removing ISO file..."
    Remove-Item $isoPath -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "ERROR: Guest Additions ISO not found at $isoPath"
}

Write-Host "Guest Additions installation process complete."
