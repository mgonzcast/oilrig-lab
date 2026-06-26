These files are meant to construct automatically a vulnerable Windows domain (BOOMBOX.COM) Lab for Oilrig emulation from the CTID (Center for Threat Informed Defense) using Packer and Vagrant:

https://github.com/center-for-threat-informed-defense/adversary_emulation_library/blob/master/oilrig/Emulation_Plan/Infrastructure.md

Most information for installing is in the quickstart script (either the ps1 or sh script)

You need to download all the installers and isos using the following scripts:

```
download_isos.sh
download_installers.sh
```
The Packer and Vagrant files are built for Virtualbox and VMware workstation. 

Virtualbox, at least with the versions that I tried sometimes hang, specially Kali. I decided to switch to VMware workstation.

And then you can run the quickstart script or manually run

```
packer build windows-server-2019.pkr.hcl 
packer build windows-10-ltsc-17763.pkr.hcl
```

if you want to create Virtualbox and VMware boxes and select the provider with the -only flag

```
packer build -only=vmware-iso.windows-server-2019 windows-server-2019.pkr.hcl 
packer build -only=vmware-iso.windows-10 windows-10-ltsc-17763.pkr.hcl
```

Once built with Packer you have to add them to your Vagrant boxes list:

```
vagrant box add --name windows-server-2019 windows-server-2019-vmware.box
vagrant box add --name windows-10-ltsc-17763 windows-10-ltsc-17763-vmware.box
```

and you can start deploying the lab:

```
vagrant up diskjockey 
vagrant up endofroad
vagrant up waterfalls
vagrant up theblock
```

Vagrant creates a first network device in each VM with NAT connection so the installation can be performed using Win RM. 

Once diskjockey is set up, unplug the NAT network so the rest of the machines can join the domain.

Once the VMs are created, they can be unplugged and only use the second NIC with the internal network configured intnet-target

Make sure you use the PVN ID for your LAN networks, modify the Vagrantfile accordingly:

```
v.vmx["ethernet1.connectionType"] = "pvn"
v.vmx["ethernet1.pvnID"] = "52 3d 44 e8 0e 9a 0b ca-29 7a 57 3c 4f 95 14 89" # Place your ID here in the preferences.ini file or vmx
```


You need to create a router to interconnect the Kali VM or any VM you use to attack the lab. You can check my opnsense-lab and my caldera-emu-kali repositories.


