# PowerShell script to download installers
# Requires PowerShell 5.1 or higher

# Define download URLs and filenames
$downloads = @(
    @{
        Url = "https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/c8c829444416e811be84c5765ede6148/ndp48-devpack-enu.exe"
        FileName = "ndp48-devpack-enu.exe"
    },
    @{
        Url = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
        FileName = "rewrite_amd64_en-US.msi"
    },
    @{
        Url = "https://download.microsoft.com/download/2/e/6/2e61cfa4-993b-4dd4-91da-3737cd5cd6e3/vcredist_x64.exe"
        FileName = "vcredist_x64.exe"
    }
)

# Set download directory (change this to your preferred location)
$downloadPath = ".\installers"

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
