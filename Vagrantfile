Vagrant.configure("2") do |config|

# -------------------------------------------------------------
# 1. PLUGIN CHECK AND INSTALLATION (vbguest and reload)
# -------------------------------------------------------------
  config.vagrant.plugins = ["vagrant-vbguest", "vagrant-reload"]

  config.vm.box = "windows-server-2019"
  config.vm.guest = :windows
  config.vm.communicator = "winrm"
  config.vm.boot_timeout = 600
  config.vm.graceful_halt_timeout = 600
  
  config.winrm.transport = :plaintext
  config.winrm.basic_auth_only = true
  
  config.winrm.username = "vagrant"
  config.winrm.password = "vagrant"
  config.winrm.timeout = 1800
  config.winrm.retry_limit = 30
  config.winrm.retry_delay = 10
  
  #config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder ".", "/vagrant"
  config.vbguest.auto_update = true  
  
  
  
  # -------------------------------------------------------------
  # Domain Controller - diskjockey
  # -------------------------------------------------------------
  
  
  config.vm.define "diskjockey" do |dc|
    dc.vm.hostname = "diskjockey"    
    dc.vm.network "private_network",  
      ip: "10.1.0.4",
      netmask: "255.255.255.0",
      virtualbox__intnet: "intnet-target",
      #auto_config: true # We set the second NIC in the provision-dc.ps1
      auto_config: false
      
    dc.vm.provider "virtualbox" do |vb|
      vb.name = "diskjockey"
      vb.memory = 2048
      vb.cpus = 2
      vb.linked_clone = false
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
    end       
    
    dc.vm.provision "shell", path: "scripts/provision-dc.ps1", privileged: true
    
    dc.vm.provision "reload"
    
    dc.vm.provision "shell", path: "scripts/creation-users.ps1", privileged: true
       
  end
  
  # ------------------------------------------------------------- 
  # Exchange Server - waterfalls
  # -------------------------------------------------------------
  
  config.vm.define "waterfalls" do |exch|
    exch.vm.hostname = "waterfalls"
    exch.vm.network "private_network", 
      ip: "10.1.0.6",
      netmask: "255.255.255.0",
      virtualbox__intnet: "intnet-target",
      auto_config: false
    #exch.winrm.username = "Administrator"
    #exch.winrm.password = "vagrant"
    
    
    exch.vm.provider "virtualbox" do |vb|
      vb.name = "waterfalls"
      vb.memory = 8192
      vb.cpus = 4
      vb.linked_clone = false
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
      vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "0", "--device", "0", "--type", "dvddrive", "--medium", "isos/ExchangeServer2019-x64-CU11.iso"]
      vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "0", "--device", "1", "--type", "dvddrive", "--medium", "isos/SQLServer2019-x64-ENU.iso"]
    end
    
    exch.vm.provision "shell", path: "scripts/provision-waterfalls-join-domain.ps1", privileged: true
    
    exch.vm.provision "reload"
    
    exch.vm.provision "shell", path: "scripts/provision-waterfalls-prerequisites-exchange.ps1", privileged: true
    
    exch.vm.provision "sql-install", type: "shell", path: "scripts/provision-waterfalls-sql.ps1", privileged: true
    
    exch.vm.provision "reload"
     
    exch.vm.provision "administrator-configuration", type: "shell", path: "scripts/provision-waterfalls-administrator-configuration.ps1", privileged: true
    
    exch.vm.provision "file", source: "scripts/provision-waterfalls-exchange.ps1", destination: "C:\\tmp\\provision-waterfalls-exchange.ps1"
    
    exch.vm.provision "reload"
    
    exch.vm.provision "file", source: "web.config", destination: "C:\\tmp\\web.config"
    
    exch.vm.provision "autologon", type: "shell", privileged: "true", inline: <<-'POWERSHELL'
    
      $Domain = "boombox.com"
      $User = "Administrator@boombox.com"
      $Password = "vagrant"
             
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value "1" 
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value "$User" 
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value $Password
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefautDomainName -value $Domain  
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value "1" 
      
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name ScriptLogon -Value "powershell.exe -ExecutionPolicy Bypass -File C:\tmp\provision-waterfalls-exchange.ps1"         
      
    POWERSHELL
    
    exch.vm.provision "reload"
    
    exch.vm.provision "remove-autologon", type: "shell", privileged: "true", inline: <<-'POWERSHELL'       
      
      # We back up file in Exchange configuration once is created
      $file = "C:\Program Files\Microsoft\Exchange Server\V15\ClientAccess\exchweb\ews\web.config"
      $backup = "C:\Program Files\Microsoft\Exchange Server\V15\ClientAccess\exchweb\ews\web.config.bkp"
      
      Write-Host "Esperando a que Exchange se instale..." -ForegroundColor Cyan
      
      while (-not (Test-Path -Path $file)) {
          Start-Sleep -s 60
      }
      
      Write-Host "Modificando web.config Exchange..." -ForegroundColor Cyan

      Copy-Item $file -Destination $backup
      
      # We update web.config configuration with the entry <add assembly="Microsoft.Exchange.Diagnostics" ...
      Copy-Item "C:\tmp\web.config" -Destination $file
      
      # We disable autologon 
      
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value "0"   
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value "" 
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value ""
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefautDomainName -value ""             
      
      # We wait until the Exchange installation might have finished at least 2 hours (30 minutes first Start-Sleep + 150 minutes second Start-Sleep )
      Start-Sleep -s 5400 
       
    POWERSHELL   
  
  end

  # ------------------------------------------------------------- 
  # SQL Server - endofroad
  # ------------------------------------------------------------- 

  config.vm.define "endofroad" do |sql|
    sql.vm.hostname = "endofroad"
    sql.vm.network "private_network", 
      ip: "10.1.0.7",
      netmask: "255.255.255.0",
      virtualbox__intnet: "intnet-target",
      auto_config: false
    
    sql.vm.provider "virtualbox" do |vb|
      vb.name = "endofroad"
      vb.memory = 4096
      vb.cpus = 2
      vb.linked_clone = false
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
      vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", "isos/SQLServer2019-x64-ENU.iso"]
    end
             
    sql.vm.provision "shell", path: "scripts/provision-endofroad-join-domain.ps1", privileged: true
    
    sql.vm.provision "reload"
    
    sql.vm.provision "provision-sql", type: "shell", path: "scripts/provision-endofroad-sql.ps1", privileged: true
    
    sql.vm.provision "reload"
    
    sql.vm.provision "configure-sql", type: "shell", path: "scripts/configure-endofroad-sql.ps1", privileged: true
    
    sql.vm.provision "reload"
    
    sql.vm.provision "file", source: "minfac.csv", destination: "C:\\tmp\\minfac.csv"
    
    sql.vm.provision "provision-db", type: "shell", path: "scripts/provision-db-endofroad-sql.ps1", privileged: true 
    
  end
  
  # -------------------------------------------------------------
  # Windows 10 LTSC Client Definition
  # -------------------------------------------------------------
  config.vm.define "theblock" do |client|
    # NOTE: Use the box name created by the windows-10-ltsc-17763.pkr.hcl build
    client.vm.box = "windows-10-ltsc-17763" 
    client.vm.hostname = "theblock"
      
    client.vm.network "private_network",  
      ip: "10.1.0.5", # Static IP for the client
      netmask: "255.255.255.0",
      virtualbox__intnet: "intnet-target",
      auto_config: false      

    client.vm.provider "virtualbox" do |vb|
      vb.name = "theblock"
      vb.memory = 4096
      vb.cpus = 2
      vb.linked_clone = false
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
    end
    
    client.vm.provision "shell", path: "scripts/provision-theblock-join-domain.ps1", privileged: true
    
    client.vm.provision "reload"

    client.vm.provision "configure-rdp", type: "shell", privileged: "true", inline: <<-'POWERSHELL'           
    
      # gosta user hasn´t logged in yet. So We add to the Default user the registry for Default Terminal Server Client searched in the Oilrig Operation
            
    	$userName = "gosta"
    	$domain = "BOOMBOX"
    	$fullAccount = "$domain\$userName"
    
    	# Get Gosta User's SID
    	try {
    	    $sid = (New-Object System.Security.Principal.NTAccount($fullAccount)).Translate([System.Security.Principal.SecurityIdentifier]).Value
    	    Write-Host "Target SID identified: $sid" -ForegroundColor Cyan
    	} catch {
    	    Write-Warning "Could not find SID for $fullAccount. This is fine if the user has never logged in."
    	}
    
    	# Forcefully Delete Existing gosta Profile (if it exists)
    	if ($sid) {
    	    $existingProfile = Get-CimInstance -Class Win32_UserProfile | Where-Object { $_.SID -eq $sid }
    	    
    	    if ($existingProfile) {
    		Write-Host "Existing profile found for $fullAccount. Deleting..." -ForegroundColor Yellow
    		# This removes the folder AND the registry entry in HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList
    		Remove-CimInstance -InputObject $existingProfile
    		Write-Host "Profile wiped successfully." -ForegroundColor Green
    	    } else {
    		Write-Host "No existing profile found for $userName. Proceeding to template modification."
    	    }
    	}
            
        	# Path to the Default User's registry hive
    	$defaultHivePath = "C:\Users\Default\NTUSER.DAT"
    
    	# Check if the file exists (it's hidden/system, but Test-Path handles it)
    	if (-not (Test-Path $defaultHivePath)) {
    	    Write-Error "Default NTUSER.DAT not found."
    	    return
    	}
    
    	Write-Host "Loading Default User Hive..." -ForegroundColor Cyan
    
    	# Mount the hive into HKEY_USERS under a temporary name 'DefaultTemplate'
    	# Using 'reg.exe' is the most reliable way to handle the mount
    	reg load "HKU\DefaultTemplate" $defaultHivePath
    
    	try {
    	    # Define the target path within the mounted hive
    	    $targetPath = "Registry::HKEY_USERS\DefaultTemplate\SOFTWARE\Microsoft\Terminal Server Client\Default"
    
    	    # Create the key if it doesn't exist
    	    if (-not (Test-Path $targetPath)) {
    		Write-Host "Creating key in Default User profile..."
    		New-Item -Path $targetPath -Force | Out-Null
    		Write-Host "Successfully added key to template." -ForegroundColor Green
    	    } else {
    		Write-Host "Key already exists in the template." -ForegroundColor Yellow
    	    }
    	}
    	catch {
    	    Write-Error "An error occurred: $($_.Exception.Message)"
    	}
    	finally {
    	    # Crucial: Release the file lock and unload
    	    # We call the Garbage Collector to ensure PowerShell has dropped the handle
    	    [gc]::Collect()
    	    [gc]::WaitForPendingFinalizers()
    	    
    	    Write-Host "Unloading Default User Hive..." -ForegroundColor Cyan
    	    reg unload "HKU\DefaultTemplate"
    	}   
       
    POWERSHELL
    
    client.vm.provision "shell", path: "scripts/provision-theblock-provision.ps1", privileged: true
    
    client.vm.provision "reload"
    
  end
  
  
  
end







