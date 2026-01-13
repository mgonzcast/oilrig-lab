# will run on first boot
# https://technet.microsoft.com/en-us/library/cc766314(v=ws.10).aspx
$setupComplete = @"
netsh advfirewall firewall set rule name="WinRM-HTTP" new action=allow
"@

New-Item -Path 'C:\Windows\Setup\Scripts' -ItemType Directory -Force
Set-Content -path "C:\Windows\Setup\Scripts\SetupComplete.cmd" -Value $setupComplete

Copy-Item -Path "A:\setup-winrm.ps1" -Destination "C:\Windows\Setup\Scripts\setup-winrm.ps1"
