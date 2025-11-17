
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
  
  config.winrm.username = "vagrant"
  config.winrm.password = "vagrant"
  #config.winrm.transport = :plaintext
  #config.winrm.basic_auth_only = true

  config.winrm.timeout = 1800
  config.winrm.retry_limit = 30
  config.winrm.retry_delay = 10
  
  # Disable default synced folder
  config.vm.synced_folder ".", "/vagrant", disabled: true
  
  # Domain Controller - diskjockey
  config.vm.define "diskjockey" do |dc|
    dc.vm.hostname = "diskjockey"   
    dc.vm.network "private_network", 
      ip: "10.1.0.4",
      virtualbox__intnet: "intnet-target"    
    
    dc.vm.provider "virtualbox" do |vb|
      vb.name = "diskjockey"
      vb.memory = 2048
      vb.cpus = 2
      vb.linked_clone = true
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
    end   
   
      
    dc.vm.provision "shell", path: "scripts/provision-dc.ps1"
    
    # Reboot after DC promotion
    dc.vm.provision :reload
        
    # Optional: Post-reboot configuration
    dc.vm.provision "shell", inline: <<-SHELL
      Write-Host "Waiting for system to stabilize after DC promotion..."
      Start-Sleep -Seconds 30
      Write-Host "Domain Controller is now ready!"
      Get-ADDomain
    SHELL
  end
  
  # Exchange Server - waterfalls
  config.vm.define "waterfalls" do |exch|
    exch.vm.hostname = "waterfalls"
    exch.vm.network "private_network", 
      ip: "10.1.0.6",
      virtualbox__intnet: "internal-target"
    
    exch.vm.provider "virtualbox" do |vb|
      vb.name = "waterfalls"
      vb.memory = 8192
      vb.cpus = 4
      vb.linked_clone = true
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
      vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", "isos/ExchangeServer2019-x64-CU11.ISO"]
    end
    
    exch.vm.provision "shell", path: "scripts/provision-exchange.ps1"
  end
  
  # SQL Server - endofroads
  config.vm.define "endofroads" do |sql|
    sql.vm.hostname = "endofroads"
    sql.vm.network "private_network", 
      ip: "10.1.0.7",
      virtualbox__intnet: "internal-target"
    
    sql.vm.provider "virtualbox" do |vb|
      vb.name = "endofroads"
      vb.memory = 4096
      vb.cpus = 2
      vb.linked_clone = true
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
      vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", "isos/SQLServer2019-x64-ENU.iso"]
    end
    
    sql.vm.provision "shell", path: "scripts/provision-sql.ps1"
  end
end



