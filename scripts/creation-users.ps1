$ServiceName = "ADWS"
$TimeoutSeconds = 600 # 5 minutes timeout
$SleepSeconds = 60
$ElapsedSeconds = 0

    Write-Host "Waiting for Active Directory Web Services (ADWS) to start..."

do {
	try {
	    $service = Get-Service -Name $ServiceName -ErrorAction Stop
	    if ($service.Status -eq "Running") {
		Write-Host "Active Directory Web Services are up and running." -ForegroundColor Green
		
		Write-Host "Creating accounts" -ForegroundColor Green

		New-ADGroup 'EWS Admins' -GroupScope Global
		New-ADGroup 'SQL Admins' -Groupscope Global

		$path="CN=Users,DC=boombox,DC=com"

		New-ADUser -Name gosta -UserPrincipalName gosta@boombox.com -Path $path -Enabled $True `
		-AccountPassword $(ConvertTo-SecureString 'd0ntGoCH4ingW8trfalls' -AsPlainText -Force) -passThru
		Set-ADUser gosta -PasswordNeverExpires $true
		
		Add-ADGroupMember -Identity "EWS Admins" -Members gosta
		
		New-ADUser -Name tous -UserPrincipalName tous@boombox.com -Path $path -Enabled $True `
		-AccountPassword $(ConvertTo-SecureString 'd0ntGoCH4ingW8trfalls' -AsPlainText -Force) -passThru
		Set-ADUser tous -PasswordNeverExpires $true
		
		Add-ADGroupMember -Identity "EWS Admins" -Members tous
		Add-ADGroupMember -Identity "SQL Admins" -Members tous
		
		New-ADUser -Name mariam -UserPrincipalName mariam@boombox.com -Path $path -Enabled $True `
		-AccountPassword $(ConvertTo-SecureString 'd0ntGoCH4ingW8trfalls' -AsPlainText -Force) -passThru
		Set-ADUser mariam -PasswordNeverExpires $true
		 
		New-ADUser -Name shiroyeh -UserPrincipalName shiroyeh@boombox.com -Path $path -Enabled $True `
		-AccountPassword $(ConvertTo-SecureString 'd0ntGoCH4ingW8trfalls' -AsPlainText -Force) -passThru
		Set-ADUser shiroyeh -PasswordNeverExpires $true
		
		New-ADUser -Name shiroyeh_admin -UserPrincipalName shiroyeh_admin@boombox.com -Path $path -Enabled $True `
		-AccountPassword $(ConvertTo-SecureString 'd0ntGoCH4ingW8trfalls' -AsPlainText -Force) -passThru
		Set-ADUser shiroyeh_admin -PasswordNeverExpires $true
		Add-ADGroupMember -Identity "Domain Admins" -Members shiroyeh_admin

        Set-ADUser vagrant -PasswordNeverExpires $true
		Set-ADUser Administrator -PasswordNeverExpires $true
		
		return $true
	    }
	}
	catch {
	    # Service not found or other connection error (e.g. during boot)
	}

	Write-Host "Services not fully running yet, sleeping for $SleepSeconds seconds..."
	Start-Sleep -Seconds $SleepSeconds
	$ElapsedSeconds += $SleepSeconds

	if ($ElapsedSeconds -ge $TimeoutSeconds) {
	    Write-Host "Timeout reached. AD services did not start within the time limit." -ForegroundColor Red
	    return $false
	}
} while ($true)





