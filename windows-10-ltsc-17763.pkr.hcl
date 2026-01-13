packer {
  required_plugins {
    virtualbox = {
      source  = "github.com/hashicorp/virtualbox"
      version = "~> 1"
    }
  }
}

variable "iso_url" {
  type        = string
  description = "windows 10 evaluation iso"
  default     = "isos/17763.107.101029-1455.rs5_release_svc_refresh_CLIENT_LTSC_EVAL_x64FRE_en-us.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:668fe1af70c2f7416328aee3a0bb066b12dc6bbd2576f40f812b95741e18bc3a" 
}

variable "vm_name" {
  type    = string
  default = "windows-10-ltsc-base"
}

variable "cpus" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 4096
}

variable "disk_size" {
  type    = number
  default = 61440
}

source "virtualbox-iso" "windows-10" {
  guest_os_type        = "Windows10_64"
  iso_url              = var.iso_url
  iso_checksum         = var.iso_checksum
  
  vm_name              = var.vm_name
  cpus                 = var.cpus
  memory               = var.memory
  disk_size            = var.disk_size
  
  headless             = false
  
  communicator         = "winrm"
  winrm_username       = "vagrant"
  winrm_password       = "vagrant"
  winrm_timeout        = "12h"
  winrm_use_ssl        = false
  winrm_insecure       = true
  
  boot_wait            = "5m"
  virtualbox_version_file = ""
  
  #shutdown_command     = "A:/PackerShutdown.bat"
  shutdown_command     = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  shutdown_timeout     = "8m"
  
  floppy_files = [
    "win10/autounattend.xml",  # Use the Windows 10-specific file
    "scripts/setup-winrm.ps1",
    "win10/unattend.xml",
    "scripts/PackerShutdown.bat"
  ]
  
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--nat-localhostreachable1", "on"],
    ["modifyvm", "{{.Name}}", "--vram", "128"],
    ["modifyvm", "{{.Name}}", "--clipboard", "bidirectional"],
    ["modifyvm", "{{.Name}}", "--draganddrop", "bidirectional"],
    ["modifyvm", "{{.Name}}", "--audio", "none"]
  ]
    
  skip_export = false
  guest_additions_mode = "disable"
  #guest_additions_path = "C:/Windows/Temp/windows.iso"
}

build {
  sources = ["source.virtualbox-iso.windows-10"]
    
  # Disable Windows Update Service
  provisioner "powershell" {
    inline = [
      "Write-Host 'Disabling Windows Update Service...'",
      "Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue",
      "Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue",
      
      "# Disable via registry as well",
      # "New-Item -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate' -Force | Out-Null",
      # "New-Item -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU' -Force | Out-Null",
      # "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU' -Name 'NoAutoUpdate' -Value 1 -Type DWord",
      # "Write-Host 'Windows Update disabled'"
    ]
  }
  
  # Disable Windows Defender thoroughly
  provisioner "powershell" {
    inline = [
      "Write-Host 'Disabling Windows Defender...'",
      "# Disable real-time protection",
      "Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue",
      "Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue",
      "Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue",
      "Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue",
      "Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue",
      "# Disable via registry",
      "New-Item -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender' -Force | Out-Null",
      "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender' -Name 'DisableAntiSpyware' -Value 1 -Type DWord",
      "New-Item -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender\\Real-Time Protection' -Force | Out-Null",
      "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender\\Real-Time Protection' -Name 'DisableRealtimeMonitoring' -Value 1 -Type DWord",
      "Write-Host 'Windows Defender disabled'"
    ]
  }
  
  # Disable telemetry and other privacy concerns
  #provisioner "powershell" {
  #  inline = [
  #    "Write-Host 'Disabling telemetry and privacy features...'",
  #    "# Disable telemetry",
  #    "New-Item -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection' -Force | Out-Null",
  #    "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection' -Name 'AllowTelemetry' -Value 0 -Type DWord",
  #    "# Disable Cortana",
  #    "New-Item -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Windows Search' -Force | Out-Null",
  #    "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Windows Search' -Name 'AllowCortana' -Value 0 -Type DWord",
  #    "Write-Host 'Privacy features disabled'"
  #  ]
  #}
  
  # Cleanup
  provisioner "powershell" {
    inline = [
      "Write-Host 'Running cleanup...'",
      "# Clear Windows Update cache",
      "Remove-Item -Path 'C:\\Windows\\SoftwareDistribution\\Download\\*' -Recurse -Force -ErrorAction SilentlyContinue",
      "# Clear temp files",
      "Remove-Item -Path 'C:\\Windows\\Temp\\*' -Recurse -Force -ErrorAction SilentlyContinue",
      "# Clear event logs",
      "wevtutil el | ForEach-Object { wevtutil cl $_ }",
      "Write-Host 'Cleanup complete'"
    ]
  }
  
  # REBOOT: Forces a reboot and waits for WinRM reconnection
  provisioner "windows-restart" {}
  
  provisioner "powershell" {
  script = "scripts/save_shutdown.ps1" 
  }
  
  # Post-Processor Settings for Vagrant
  post-processor "vagrant" {
    output               = "windows-10-ltsc-17763-{{.Provider}}.box"
    keep_input_artifact  = false
  }
}
