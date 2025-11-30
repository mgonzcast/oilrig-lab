#!/bin/bash

vagrant box remove windows-server-2019
rm -f windows-server-2019-virtualbox.box
packer build windows-server-2019.pkr.hcl
vagrant box add windows-server-2019 windows-server-2019-virtualbox.box 
