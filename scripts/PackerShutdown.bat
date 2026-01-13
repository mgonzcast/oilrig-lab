REM netsh advfirewall firewall set rule name="Windows Remote Management (HTTPS-In)" new action=block
REM netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new action=block

REM del /f C:\Windows\Packer\unattend.xml

REM copy A:\unattend.xml C:\Windows\Panther\
copy A:\unattend.xml c:\windows\system32\sysprep

REM C:/windows/system32/sysprep/sysprep.exe /generalize /oobe /unattend:C:/Windows/Panther/unattend.xml /mode:vm /shutdown

C:/windows/system32/sysprep/sysprep.exe /generalize /oobe /unattend:C:/Windows/System32/sysprep/unattend.xml /mode:vm /shutdown


