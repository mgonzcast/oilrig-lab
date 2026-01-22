These files are meant to construct the Windows domain Lab for Oilrig emulation from the CTID (Center for Threat Informed Defense)

https://github.com/center-for-threat-informed-defense/adversary_emulation_library/blob/master/oilrig/Emulation_Plan/Infrastructure.md

Most information for installing is in the quickstart script (either the ps1 or sh script)

You need to download all the installers and isos using the following scripts:

```
download_isos.sh
download_installers.sh
```

And then you can run the quickstart script or manually run

```
packer build windows-server-2019.pkr.hcl
packer build windows-10-ltsc-17763.pkr.hcl      

vagrant box add --name windows-server-2019 packer/windows-server-2019-virtualbox.box
vagrant box add --name windows-10-ltsc-17763 packer/windows-10-ltsc-17763-virtualbox.box

vagrant up diskjockey 
vagrant up endofroad
vagrant up waterfalls
vagrant up theblock

```
Vagrant creates a first network device in each VM with NAT connection so the installation can be performed using Win RM. 

Once the VMs are created, they can be unplugged and only use the second NIC with the internal network configured intnet-target

You need to create a router to interconnect the Kali VM or any VM you use to attack the lab


