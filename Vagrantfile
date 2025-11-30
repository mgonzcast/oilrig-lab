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
  
  config.vm.synced_folder ".", "/vagrant", disabled: true
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
    
    exch.vm.provider "virtualbox" do |vb|
      vb.name = "waterfalls"
      vb.memory = 8192
      vb.cpus = 4
      vb.linked_clone = false
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
      vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", "isos/ExchangeServer2019-x64-CU11.ISO"]
    end
    
    exch.vm.provision "shell", path: "scripts/provision-waterfalls-join-domain.ps1", privileged: true
    
    exch.vm.provision "reload"
    
    exch.vm.provision "shell", path: "scripts/provision-waterfalls-prerequisites-exchange.ps1", privileged: true
    
    exch.vm.provision "reload"
    
    exch.vm.provision "shell", path: "scripts/provision-waterfalls-exchange.ps1", privileged: true
    
    exch.vm.provision "reload"
    
  end

  # ------------------------------------------------------------- 
  # SQL Server - endofroads
  # ------------------------------------------------------------- 

  config.vm.define "endofroads" do |sql|
    sql.vm.hostname = "endofroads"
    sql.vm.network "private_network", 
      ip: "10.1.0.7",
      netmask: "255.255.255.0",
      virtualbox__intnet: "intnet-target",
      auto_config: false
    
    sql.vm.provider "virtualbox" do |vb|
      vb.name = "endofroads"
      vb.memory = 4096
      vb.cpus = 2
      vb.linked_clone = false
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
      vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", "isos/SQLServer2019-x64-ENU.iso"]
    end
             
    sql.vm.provision "shell", path: "scripts/provision-endofroads-join-domain.ps1", privileged: true
    
    sql.vm.provision "reload"
    
    sql.vm.provision "shell", path: "scripts/provision-endofroads-sql.ps1", privileged: true
    
    sql.vm.provision "reload"
    
  end
  
  # -------------------------------------------------------------
  # Windows 10 LTSC Client Definition
  # -------------------------------------------------------------
  config.vm.define "theblock" do |client|
    # NOTE: Use the box name created by the windows-10-ltsc-17763.pkr.hcl build
    client.vm.box = "windows-10-ltsc-17763" 
    client.vm.hostname = "theblock"
    client.vm.guest = :windows
    client.vbguest.auto_update = true  
      
    client.vm.network "private_network",  
      ip: "10.1.0.8", # Static IP for the client
      netmask: "255.255.255.0",
      virtualbox__intnet: "intnet-target",
      auto_config: true      

    client.vm.provider "virtualbox" do |vb|
      vb.name = "theblock"
      vb.memory = 4096
      vb.cpus = 2
      vb.linked_clone = false
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
    end
    
    # PowerShell script to set Gateway (10.1.0.1), DNS (10.1.0.5 DC), and join Domain (boombox.com)
    client.vm.provision "shell", inline: <<-SHELL
      $NIC = Get-NetAdapter | Where-Object { $_.Name -like "Ethernet*" }
      # Set Static IP, Gateway (OPNsense), and DNS (DC)
      New-NetIPAddress -InterfaceAlias $NIC.Name -IPAddress 10.1.0.8 -PrefixLength 24 -DefaultGateway 10.1.0.1
      Set-DnsClientServerAddress -InterfaceAlias $NIC.Name -ServerAddresses ("10.1.0.5")
      
      # Join the Domain (Requires diskjockey/DC to be running)
      # NOTE: This assumes the 'vagrant' user has domain join rights.
      Add-Computer -DomainName "boombox.com" -Credential "boombox\\vagrant" -Restart -Force
    SHELL
  end
  
  
  
end
