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
      vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", "isos/ExchangeServer2019-x64-CU11.ISO"]
      vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "1", "--device", "1", "--type", "dvddrive", "--medium", "isos/SQLServer2019-x64-ENU.iso"]
    end
    
    exch.vm.provision "shell", path: "scripts/provision-waterfalls-join-domain.ps1", privileged: true
    
    exch.vm.provision "reload"
    
    exch.vm.provision "shell", path: "scripts/provision-waterfalls-prerequisites-exchange.ps1", privileged: true
    
    exch.vm.provision "sql-install", type: "shell", path: "scripts/provision-waterfalls-sql.ps1", privileged: true
    
    exch.vm.provision "reload"
     
    exch.vm.provision "administrator-configuration", type: "shell", path: "scripts/provision-waterfalls-administrator-configuration.ps1", privileged: true
    
    exch.vm.provision "file", source: "scripts/provision-waterfalls-exchange.ps1", destination: "C:\\tmp\\provision-waterfalls-exchange.ps1"
    
    exch.vm.provision "reload"
    
    #exch.vm.provision "autologon-script", type: "shell", privileged: "true", inline: <<-'POWERSHELL'        
      
      	#$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File "C:\tmp\provision-waterfalls-exchange.ps1"'
	#$Trigger = New-ScheduledTaskTrigger -AtLogOn
	#$User = "BOOMBOX\Administrator" # Or a specific user
	#$Principal = New-ScheduledTaskPrincipal -UserId $User -LogonType Interactive -RunLevel Highest

	#Register-ScheduledTask -TaskName "RunScriptAtLogon" -Action $Action -Trigger $Trigger -Principal $Principal	      
       
    #POWERSHELL
    
    exch.vm.provision "autologon", type: "shell", privileged: "true", inline: <<-'POWERSHELL'
    
      $Domain = "boombox.com"
      $User = "Administrator@boombox.com"
      $Password = "vagrant"
      
      #New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value "1" -PropertyType String
      #New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value "$User" -PropertyType String
      #New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value $Password -PropertyType String
      #New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefautDomainName -value $Domain -PropertyType String  
       
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value "1" 
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value "$User" 
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value $Password
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefautDomainName -value $Domain  
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value "1" 
      
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name ScriptLogon -Value "powershell.exe -ExecutionPolicy Bypass -File C:\tmp\provision-waterfalls-exchange.ps1"         
      
    POWERSHELL
    
    exch.vm.provision "reload"
    
    exch.vm.provision "remove-autologon", type: "shell", privileged: "true", inline: <<-'POWERSHELL'       
      
      # We wait to the autologon and provisioning script for exchange to be launched
      Start-Sleep -s 1800 
      
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
    
    client.vm.provision "shell", path: "scripts/provision-theblock-provision.ps1", privileged: true
    
    client.vm.provision "reload"
    
  end
  
  
  
end


