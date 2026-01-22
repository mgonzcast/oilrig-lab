packer {
  required_version = ">= 1.8.0"
  required_plugins {
    virtualbox = {
      version = ">=1.0.0"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

variable "iso_url" {
  type        = string
  description = "windows server 2019 evaluation iso"
  default     = "isos/17763.3650.221105-1748.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
}

variable "iso_checksum" {
  type        = string
  description = "Checksum of the ISO file"
  default     = "sha256:6DAE072E7F78F4CCAB74A45341DE0D6E2D45C39BE25F1F5920A2AB4F51D7BCBB"
}

variable "vm_name" {
  type    = string
  default = "windows-server-2019-base"
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

source "virtualbox-iso" "windows-server-2019" {
  guest_os_type        = "Windows2019_64"
  iso_url              = var.iso_url
  iso_checksum         = var.iso_checksum
  
  vm_name              = var.vm_name
  cpus                 = var.cpus
  memory               = var.memory
  disk_size            = var.disk_size

  chipset              = "ich9"
  hard_drive_interface = "sata"
  headless             = false
  
  communicator         = "winrm"
  winrm_username       = "vagrant"
  winrm_password       = "vagrant"
  winrm_timeout        = "12h"
  winrm_use_ssl        = false
  winrm_insecure       = true
  
  boot_wait = "5m"  # Instead of default timing
  virtualbox_version_file = ""
  
  shutdown_command = "A:/PackerShutdown.bat" #; shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  #shutdown_command     = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  # shutdown_command = "C:\\Windows\\system32\\sysprep\\sysprep.exe /unattend:A:\\autounattend.xml /quiet /generalize /oobe /shutdown"
  shutdown_timeout     = "15m"
  
  floppy_files = [
    "winserver2019/autounattend.xml",
    "scripts/PackerShutdown.bat",
    "winserver2019/unattend.xml",
    "scripts/setup-winrm.ps1"
  ]
  
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--nat-localhostreachable1", "on"],
    ["modifyvm", "{{.Name}}", "--vram", "128"],
    ["modifyvm", "{{.Name}}", "--clipboard", "bidirectional"],
    ["modifyvm", "{{.Name}}", "--draganddrop", "bidirectional"],
    ["modifyvm", "{{.Name}}", "--audio", "none"]
  ]
  
  #vboxmanage_post = [
  #  ["modifyvm", "{{.Name}}", "--natpf1", "delete", "winrm"]
  #]
  
  # Add this line to skip the .vbox_version upload
  skip_export = false
  
  # Try attach mode
  guest_additions_mode = "disable"
  #guest_additions_mode = "upload"
  #guest_additions_path = "C:/Windows/Temp/windows.iso"
}

  build {
  sources = ["source.virtualbox-iso.windows-server-2019"]    
  
  # Disable Windows Update Service
  provisioner "powershell" {
    inline = [
      "Write-Host 'Disabling Windows Update Service...'",
      "Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue",
      "Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue"      
    ]
  }
    
  provisioner "powershell" {
    inline = [
      "Write-Host 'Disabling Windows Defender...'",
      "Set-MpPreference -DisableRealtimeMonitoring $true -DisableIOAVProtection $true -DisableBehaviorMonitoring $true -DisableBlockAtFirstSeen $true -DisableScriptScanning $true",
      "Uninstall-WindowsFeature -Name Windows-Defender"
    ]
  } 
     
  # REBOOT: Forces a reboot and waits for WinRM reconnection
  provisioner "windows-restart" {}
  
  provisioner "powershell" {
  script = "scripts/save_shutdown.ps1" 
  }
    
  # REBOOT: Forces a reboot and waits for WinRM reconnection
  #provisioner "windows-restart" {}  
  
    provisioner "powershell" {
    #script = "scripts/cleanup.ps1"    
    inline = [      
      "Write-Host 'Running cleanup tasks...'",
      "Write-Host 'Clearing Windows Update cache and restarting service...'",
      "Stop-Service wuauserv -Force -ErrorAction SilentlyContinue",
      "Remove-Item -Path \"C:\\Windows\\SoftwareDistribution\\Download\\*\" -Recurse -Force -ErrorAction SilentlyContinue",
      "Start-Service wuauserv -ErrorAction SilentlyContinue",
      "Write-Host 'Clearing temp files...'",
      "Remove-Item -Path 'C:\\Windows\\Temp\\*' -Recurse -Force -ErrorAction SilentlyContinue",
      "$TempPath = Join-Path (Get-Item 'C:\\Users\\vagrant').FullName 'AppData\\Local\\Temp\\*'",
      "Remove-Item -Path $TempPath -Recurse -Force -ErrorAction SilentlyContinue",
      "Write-Host 'Clearing event logs...'",
      "wevtutil el | ForEach-Object { wevtutil cl $_ 2>$null }",
      "Write-Host 'Cleanup finished'"
    ]
  }
    
  post-processor "vagrant" {
    output               = "windows-server-2019-{{.Provider}}.box"
    keep_input_artifact  = false
    #vagrantfile_template = "windows-server-2019.template"
  }
}
