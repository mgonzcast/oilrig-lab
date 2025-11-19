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
  config.winrm.timeout = 1800
  config.winrm.retry_limit = 30
  config.winrm.retry_delay = 10
  
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vbguest.auto_update = true  
  
  # Domain Controller - diskjockey
  config.vm.define "diskjockey" do |dc|
    dc.vm.hostname = "diskjockey"    
    dc.vm.network "private_network",  
      ip: "10.1.0.4",
      netmask: "255.255.255.0",
      virtualbox__intnet: "intnet-target",
      auto_config: true
      
    dc.vm.provider "virtualbox" do |vb|
      vb.name = "diskjockey"
      vb.memory = 2048
      vb.cpus = 2
      vb.linked_clone = true
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
    end    
    
    # 1. Provision DC - REMOVED 'reboot: true' parameter
    dc.vm.provision "shell", path: "scripts/provision-dc.ps1"
    
    # 2. Reload after DC promotion
    dc.vm.provision :reload
    
    # 3. Post-reboot verification
    dc.vm.provision "shell", inline: <<-SHELL
      Write-Host "Waiting for Active Directory to fully start..." -ForegroundColor Cyan
      Start-Sleep -Seconds 60
      
      Write-Host "Verifying Domain Controller status..." -ForegroundColor Cyan
      try {
        Import-Module ActiveDirectory -ErrorAction Stop
        $domain = Get-ADDomain
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host "Domain Controller: READY" -ForegroundColor Green
        Write-Host "Domain: $($domain.DNSRoot)" -ForegroundColor Green
        Write-Host "NetBIOS: $($domain.NetBIOSName)" -ForegroundColor Green
        Write-Host "=====================================" -ForegroundColor Green
      } catch {
        Write-Host "WARNING: Could not verify domain - $_" -ForegroundColor Yellow
      }
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

