#!/bin/bash
# Bash script to download installers
# Requires curl or wget

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define download URLs and filenames
declare -A downloads=(
    ["ndp48-devpack-enu.exe"]="https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/c8c829444416e811be84c5765ede6148/ndp48-devpack-enu.exe"
    ["rewrite_amd64_en-US.msi"]="https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
    ["vcredist_x64.exe"]="https://download.microsoft.com/download/2/e/6/2e61cfa4-993b-4dd4-91da-3737cd5cd6e3/vcredist_x64.exe"
)

# Set download directory (change this to your preferred location)
DOWNLOAD_PATH="./installers"

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
        if curl -L -o "$destination" --progress-bar "$url"; then
            file_size=$(du -h "$destination" | cut -f1)
            echo -e "  ${GREEN}Download complete! Size: $file_size${NC}\n"
        else
            echo -e "  ${RED}Error downloading file${NC}\n"
            # Remove partial download if it exists
            [ -f "$destination" ] && rm -f "$destination"
        fi
    else
        if wget -O "$destination" --show-progress "$url"; then
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
