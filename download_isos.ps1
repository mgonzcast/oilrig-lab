# PowerShell script to download Microsoft ISO files
# Requires PowerShell 5.1 or higher

# Define download URLs and filenames
$downloads = @(
    @{
        Url = "https://software-static.download.prss.microsoft.com/dbazure/988969d5-f34g-4e03-ac9d-1f9786c66749/17763.3650.221105-1748.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
        FileName = "17763.3650.221105-1748.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
    },
    @{
        Url = "https://download.microsoft.com/download/5/3/e/53e75dbd-ca33-496a-bd23-1d861feaa02a/ExchangeServer2019-x64-CU11.ISO"
        FileName = "ExchangeServer2019-CU11.iso"
    },
    @{
        Url = "https://download.microsoft.com/download/7/c/1/7c14e92e-bdcb-4f89-b7cf-93543e7112d1/SQLServer2019-x64-ENU.iso"
        FileName = "SQLServer2019-x64-ENU.iso"
    }
)

# Set download directory (change this to your preferred location)
$downloadPath = ".\isos"

# Create download directory if it doesn't exist
if (-not (Test-Path -Path $downloadPath)) {
    New-Item -ItemType Directory -Path $downloadPath -Force | Out-Null
    Write-Host "Created download directory: $downloadPath" -ForegroundColor Green
}

Write-Host "`nStarting downloads..." -ForegroundColor Cyan
Write-Host "Download location: $downloadPath`n" -ForegroundColor Yellow

# Download each file
$downloadCount = 0
foreach ($item in $downloads) {
    $downloadCount++
    $destination = Join-Path -Path $downloadPath -ChildPath $item.FileName
    
    Write-Host "[$downloadCount/$($downloads.Count)] Downloading: $($item.FileName)" -ForegroundColor Cyan
    
    # Check if file already exists
    if (Test-Path -Path $destination) {
        Write-Host "  File already exists. Skipping..." -ForegroundColor Yellow
        continue
    }
    
    try {
        # Download with progress
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $item.Url -OutFile $destination -UseBasicParsing
        $ProgressPreference = 'Continue'
        
        # Get file size
        $fileSize = (Get-Item $destination).Length / 1GB
        Write-Host "  Download complete! Size: $([math]::Round($fileSize, 2)) GB" -ForegroundColor Green
    }
    catch {
        Write-Host "  Error downloading file: $($_.Exception.Message)" -ForegroundColor Red
        # Remove partial download if it exists
        if (Test-Path -Path $destination) {
            Remove-Item -Path $destination -Force
        }
    }
    
    Write-Host ""
}

Write-Host "All downloads completed!" -ForegroundColor Green
Write-Host "Files saved to: $downloadPath" -ForegroundColor Yellow