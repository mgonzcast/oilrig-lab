#!/bin/bash
# Bash script to download Microsoft ISO files
# Requires curl or wget

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define download URLs and filenames
declare -A downloads=(
    ["17763.3650.221105-1748.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"]="https://software-static.download.prss.microsoft.com/dbazure/988969d5-f34g-4e03-ac9d-1f9786c66749/17763.3650.221105-1748.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
    ["ExchangeServer2019-x64-CU11.iso"]="https://download.microsoft.com/download/5/3/e/53e75dbd-ca33-496a-bd23-1d861feaa02a/ExchangeServer2019-x64-CU11.ISO"
    ["SQLServer2019-x64-ENU.iso"]="https://download.microsoft.com/download/7/c/1/7c14e92e-bdcb-4f89-b7cf-93543e7112d1/SQLServer2019-x64-ENU.iso"
    ["17763.107.101029-1455.rs5_release_svc_refresh_CLIENT_LTSC_EVAL_x64FRE_en-us.iso"]="https://software-static.download.prss.microsoft.com/pr/download/17763.107.101029-1455.rs5_release_svc_refresh_CLIENT_LTSC_EVAL_x64FRE_en-us.iso"
)

# Set download directory (change this to your preferred location)
DOWNLOAD_PATH="./isos"

# Create download directory if it doesn't exist
if [ ! -d "$DOWNLOAD_PATH" ]; then
    mkdir -p "$DOWNLOAD_PATH"
    echo -e "${GREEN}Created download directory: $DOWNLOAD_PATH${NC}"
fi

# Check if curl or wget is available
if command -v curl &> /dev/null; then
    DOWNLOADER="curl"
elif command -v wget &> /dev/null; then
    DOWNLOADER="wget"
else
    echo -e "${RED}Error: Neither curl nor wget is installed. Please install one of them.${NC}"
    exit 1
fi

echo -e "\n${CYAN}Starting downloads...${NC}"
echo -e "${YELLOW}Download location: $DOWNLOAD_PATH${NC}"
echo -e "${YELLOW}Using: $DOWNLOADER${NC}\n"

# Download each file
download_count=0
total_downloads=${#downloads[@]}

for filename in "${!downloads[@]}"; do
    ((download_count++))
    url="${downloads[$filename]}"
    destination="$DOWNLOAD_PATH/$filename"
    
    echo -e "${CYAN}[$download_count/$total_downloads] Downloading: $filename${NC}"
    
    # Check if file already exists
    if [ -f "$destination" ]; then
        echo -e "  ${YELLOW}File already exists. Skipping...${NC}\n"
        continue
    fi
    
    # Download based on available tool
    if [ "$DOWNLOADER" == "curl" ]; then
        if curl -k -L -o "$destination" --progress-bar "$url"; then
            file_size=$(du -h "$destination" | cut -f1)
            echo -e "  ${GREEN}Download complete! Size: $file_size${NC}\n"
        else
            echo -e "  ${RED}Error downloading file${NC}\n"
            # Remove partial download if it exists
            [ -f "$destination" ] && rm -f "$destination"
        fi
    else
        if wget --no-check-certificate -O "$destination" --show-progress "$url"; then
            file_size=$(du -h "$destination" | cut -f1)
            echo -e "  ${GREEN}Download complete! Size: $file_size${NC}\n"
        else
            echo -e "  ${RED}Error downloading file${NC}\n"
            # Remove partial download if it exists
            [ -f "$destination" ] && rm -f "$destination"
        fi
    fi
done

echo -e "${GREEN}All downloads completed!${NC}"
echo -e "${YELLOW}Files saved to: $DOWNLOAD_PATH${NC}"
