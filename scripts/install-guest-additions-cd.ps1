<#
.SYNOPSIS
Installs VirtualBox Guest Additions silently and waits for completion.

.DESCRIPTION
This script finds the mounted VBox Guest Additions ISO, executes VBoxWindowsAdditions.exe
with the /S (silent) switch, and uses Start-Process -Wait to ensure the script does
not proceed until the installer finishes. It then checks the exit code.
#>

Write-Host "Starting installation of VirtualBox Guest Additions..."

# Set the expected success exit code (0 is standard for VBox installers)
$SUCCESS_EXIT_CODE = 0

try {
    # 1. Find the drive letter of the mounted Guest Additions ISO using the volume label pattern.
    # The -ErrorAction Stop parameter ensures that if the volume is not found, it triggers the catch block.
    $VBoxVolume = Get-Volume -FileSystemLabel "VBox_GAs_*" -ErrorAction Stop
    $cdrom = $VBoxVolume.DriveLetter
    $installerPath = $cdrom + ":\VBoxWindowsAdditions.exe"

    Write-Host "Found Guest Additions ISO on drive: $cdrom"
    Write-Host "Installer path: $installerPath"

    # 2. Run the installer silently (/S) and WAIT for it to complete.
    # -Wait: ensures synchronous execution.
    # -PassThru: returns the process object, allowing us to inspect the ExitCode.
    $Process = Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -PassThru

    # 3. Check the exit code of the completed process
    if ($Process.ExitCode -eq $SUCCESS_EXIT_CODE) {
        Write-Host "VirtualBox Guest Additions installation completed successfully (Exit Code: $($Process.ExitCode))."
    } else {
        # Installation failed. Write an error and exit with a non-zero code to fail the Packer build.
        Write-Error "VirtualBox Guest Additions installation failed. Installer returned non-zero exit code: $($Process.ExitCode)"
        exit 1
    }

} catch {
    # Catch block for when the ISO is not found or other errors occur during setup.
    Write-Error "Error during Guest Additions setup: Could not find the VBox Guest Additions ISO. Ensure it is mounted during the build."
    # Fail the Packer provisioner
    exit 1
}

# The Guest Additions install often requires a reboot.
# If your Packer step does not immediately include a reboot command (e.g., winrm-elevated shell: 'shutdown /r /t 0 /f'),
# you will need to add one after this script runs in your Packer configuration.
