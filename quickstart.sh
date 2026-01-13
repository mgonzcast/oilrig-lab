#!/bin/bash

# --- Colors ---
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Symbols ---
CHECKMARK="✓"
BALLOT="✗"

# Clear screen and show Header
clear
echo -e "${GREEN}╔═══════════════════════════════════════════════════╗"
echo -e "║   Windows Domain Lab - BoomBox.com Setup          ║"
echo -e "║   Security Testing Environment                    ║"
echo -e "╚═══════════════════════════════════════════════════╝${NC}"

echo -e "\n${CYAN}This script will help you set up the lab environment.${NC}\n"

# Check for required tools
echo -e "${YELLOW}Checking prerequisites...${NC}"

tools=("packer" "vagrant" "VBoxManage")
missing_tools=()

for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo -e "  [${GREEN}${CHECKMARK}${NC}] $tool found"
    else
        echo -e "  [${RED}${BALLOT}${NC}] $tool NOT found"
        missing_tools+=("$tool")
    fi
done

if [ ${#missing_tools[@]} -ne 0 ]; then
    echo -e "\n${RED}Missing tools: ${missing_tools[*]}${NC}"
    echo -e "${RED}Please install them before continuing.${NC}"
    exit 1
fi

# Check for ISOs (Adjusting paths for Linux forward-slashes)
echo -e "\n${YELLOW}Checking for ISO files...${NC}"
required_isos=(
    "isos/17763.3650.221105-1748.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
    "isos/17763.107.101029-1455.rs5_release_svc_refresh_CLIENT_LTSC_EVAL_x64FRE_en-us.iso"
    "isos/ExchangeServer2019-x64-CU11.iso"
    "isos/SQLServer2019-x64-ENU.iso"
)

missing_isos=()
for iso in "${required_isos[@]}"; do
    if [ -f "$iso" ]; then
        echo -e "  [${GREEN}${CHECKMARK}${NC}] $(basename "$iso") found"
    else
        echo -e "  [${RED}${BALLOT}${NC}] $(basename "$iso") NOT found"
        missing_isos+=("$iso")
    fi
done

if [ ${#missing_isos[@]} -ne 0 ]; then
    echo -e "\n${YELLOW}Please place the required ISO files in the isos/ directory:${NC}"
    for iso in "${missing_isos[@]}"; do
        echo -e "  - ${CYAN}$(basename "$iso")${NC}"
    done
    echo -e "\n${YELLOW}See isos/README.md for download links.${NC}\n"
    exit 1
fi

echo -e "\n${GREEN}${CHECKMARK} All prerequisites met!${NC}\n"

# Menu Choice
echo -e "${CYAN}What would you like to do?${NC}"
echo "1. Build base box with Packer (required first time, ~60 minutes)"
echo "2. Deploy all VMs with Vagrant"
echo "3. Deploy individual VM"
echo "4. Exit"

read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo -e "\n${GREEN}Building base boxes with Packer...${NC}"
        cd packer || exit
        packer init .
        packer build windows-server-2019.pkr.hcl
        packer build windows-10-ltsc-17763.pkr.hcl
        
        echo -e "\n${GREEN}Adding boxes to Vagrant...${NC}"
        cd ..
        vagrant box add --name windows-server-2019 packer/windows-server-2019-virtualbox.box
        vagrant box add --name windows-10-ltsc-17763 packer/windows-10-ltsc-17763-virtualbox.box
        
        echo -e "\n${GREEN}${CHECKMARK} Base boxes created successfully!${NC}"
        echo -e "${YELLOW}Run this script again and choose option 2 to deploy VMs.${NC}"
        ;;
    
    2)
        echo -e "\n${GREEN}Deploying all VMs (this will take time)...${NC}"
        echo -e "${CYAN}Starting Domain Controller first...${NC}"
        vagrant up diskjockey
        
        echo -e "\n${CYAN}Waiting for DC to be ready...${NC}"
        sleep 30
        
        echo -e "\n${CYAN}Starting Exchange and SQL Servers...${NC}"
        vagrant up endofroads
        vagrant up waterfalls
        
        echo -e "\n${CYAN}Starting Windows 10 client...${NC}"
        vagrant up theblock

        echo -e "\n${GREEN}${CHECKMARK} All VMs deployed!${NC}"
        echo -e "\n${YELLOW}Next steps:${NC}"
        echo -e "1. ${CYAN}vagrant rdp waterfalls${NC}"
        echo -e "2. Run: ${CYAN}powershell -ExecutionPolicy Bypass -File C:\\install-exchange.ps1${NC}"
        echo -e "\n1. ${CYAN}vagrant rdp endofroads${NC}"
        echo -e "2. Run: ${CYAN}powershell -ExecutionPolicy Bypass -File C:\\install-sql.ps1${NC}"
        ;;
    
    3)
        echo -e "\n${CYAN}Available VMs:${NC}"
        echo "1. diskjockey (Domain Controller)"
        echo "2. endofroads (SQL Server 2019)"
        echo "3. waterfalls (Exchange 2019)"
        echo "4. theblock (Windows 10)"

        read -p "Enter VM number (1-4): " vmChoice
        case $vmChoice in
            1) vmName="diskjockey" ;;
            2) vmName="endofroads" ;;
            3) vmName="waterfalls" ;;
            4) vmName="theblock" ;;
            *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
        esac
        
        echo -e "\n${GREEN}Deploying $vmName...${NC}"
        vagrant up "$vmName"
        echo -e "\n${GREEN}${CHECKMARK} $vmName deployed!${NC}"
        ;;
    
    4)
        echo -e "\nExiting..."
        exit 0
        ;;
    
    *)
        echo -e "${RED}Invalid selection.${NC}"
        ;;
esac
