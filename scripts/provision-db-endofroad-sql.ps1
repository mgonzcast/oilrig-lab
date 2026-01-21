$ErrorActionPreference = "Continue"

Write-Host "`n===============================================" -ForegroundColor Green
Write-Host "`nCreating sitedata DB on SQL Server: endofroad" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

$DomainName = "boombox.com"
$DCAddress = "10.1.0.4"
$SQLIPAddress = "10.1.0.7"
$DomainAdmin = "BOOMBOX\Administrator"
$DomainPassword = "vagrant"
$SQLUser = "BOOMBOX\tous"
$SQLUserPassword = "d0ntGoCH4ingW8trfalls"


# Check if already domain joined
$computerSystem = Get-WmiObject -Class Win32_ComputerSystem
if ($computerSystem.PartOfDomain -and $computerSystem.Domain -eq $DomainName) {
    Write-Host "Already joined to domain: $DomainName" -ForegroundColor Green
} else {
    # Join domain
    Write-Host "Joining domain: $DomainName..." -ForegroundColor Cyan
    $securePassword = ConvertTo-SecureString $DomainPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ($DomainAdmin, $securePassword)
    
    try {
        Add-Computer -DomainName $DomainName -Credential $credential -Force -ErrorAction Stop
        Write-Host "Successfully joined domain. Rebooting..." -ForegroundColor Green
        Restart-Computer -Force
        exit 0
    } catch {
        Write-Host "Error joining domain: $_" -ForegroundColor Red
        exit 1
    }
}

$creationDatabase = @"
CREATE DATABASE sitedata
GO
USE sitedata

DECLARE @sql NVARCHAR(MAX)
DECLARE @filePath NVARCHAR(MAX) = 'C:\tmp\minfac.csv'
DECLARE @tableName NVARCHAR(MAX) = 'minfac'
DECLARE @colString NVARCHAR(MAX)

SET @sql = 'SELECT @res = LEFT(BulkColumn, CHARINDEX(CHAR(10),BulkColumn)) FROM  OPENROWSET(BULK ''' + @filePath + ''', SINGLE_CLOB) AS x'
exec sp_executesql @sql, N'@res NVARCHAR(MAX) output', @colString output;

SELECT @sql = 'DROP TABLE IF EXISTS ' + @tableName + ';  CREATE TABLE [dbo].[' + @tableName + ']( ' + STRING_AGG(name, ', ') + ' ) '
FROM (
    SELECT ' [' + value + '] nvarchar(max) ' as name
    FROM STRING_SPLIT(@colString, ',')
) t

EXECUTE(@sql)

SET @sql = 'BULK INSERT [dbo].[' + @tableName + '] 
FROM ''' + @filePath + ''' 
WITH ( 
    FORMAT = ''CSV'', 
    FIRSTROW = 2, 
    FIELDQUOTE = ''"'',
    FIELDTERMINATOR = '','', 
    ROWTERMINATOR = ''0x0a'',
    KEEPNULLS 
);' 
EXECUTE(@sql);

BACKUP DATABASE sitedata TO DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\sitedata_db.bak'

"@

Set-Content -path "C:\tmp\creation_database.sql" -Value $creationDatabase

# We run queries as tous user

# 2. Convert the plain text password to a SecureString object
$secpasswd = ConvertTo-SecureString $SQLUserPassword -AsPlainText -Force

# 3. Create a PSCredential object
$cred = New-Object System.Management.Automation.PSCredential($SQLUser, $secpasswd)

#Invoke-Sqlcmd -InputFile "C:\tmp\creation_database.sql" -Username $SQLUser -Password $SQLUserPassword

#$ScriptBlock  = { return @{ Result = Invoke-Sqlcmd -InputFile "C:\tmp\creation_database.sql" }}

Write-Host "`nProvisioning sitedata database..." -ForegroundColor Green

$ScriptBlock  = { try {sqlcmd -i "C:\tmp\creation_database.sql" } catch {Write-Host "Error provisioning sitedata database"} Write-Host "`nCreation of sitedata database finished" -ForegroundColor Green }


Invoke-Command -ComputerName localhost -Credential $cred -ScriptBlock $ScriptBlock

#$Job = Start-Job -Credential $cred -ScriptBlock $ScriptBlock

#$JobResult = Wait-Job $Job

#if ($JobResult -eq 'Completed') {
#  Write-Host "`nCreation of sitedata database finished" -ForegroundColor Green
#  return (Receive.Job $Job).Result
#}



