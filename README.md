Setup AD DC
Command to install AD services:
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

^ Make static IP ^

Domain Name: ad.hyrule.com
Domain Controller Name: AlexDC1
Domain DNS IP: 10.0.0.19 (private)  34.200.110.131 (public)
Create OUs
Create the following Organizational Units
[Domain] Computers - client / user machines
Conference - publicly accessible kiosks and presentation devices
Secure - machines for HR and finance users
Workstations - machines for devs and engineers
[Domain] Servers - servers for org (data shares, repo hosts, HPCs)
[Domain] Users
Finance - can log on to Secure computers, managed by hr_finance_admins group
HR - can log on to Secure computers, managed by hr_finance_admins group
Engineers - can log on to Workstations, managed by dev_eng_admins
Developers - can log on to Workstations, managed by dev_eng_admins
New-ADOrganizationalUnit -Name Conference -Path "OU=[Domain] Computers,DC=ad,DC=hyrule,DC=com" -Description "Kiosks/Presentations" -PassThru
New-ADOrganizationalUnit -Name Secure -Path "OU=[Domain] Computers,DC=ad,DC=hyrule,DC=com" -Description "HR and finance" -PassThru
New-ADOrganizationalUnit -Name Workstations -Path "OU=[Domain] Computers,DC=ad,DC=hyrule,DC=com" -Description "devs and engineers" -PassThru
New-ADOrganizationalUnit -Name Finance -Path "OU=[Domain] Users,DC=ad,DC=hyrule,DC=com" -Description "can log on to Secure computers, managed by hr_finance_admins" -PassThru
New-ADOrganizationalUnit -Name HR -Path "OU=[Domain] Users,DC=ad,DC=hyrule,DC=com" -Description "can log on to Secure computers, managed by hr_finance_admins" -PassThru
New-ADOrganizationalUnit -Name Engineers -Path "OU=[Domain] Users,DC=ad,DC=hyrule,DC=com" -Description "can log on to Workstations, managed by dev_eng_admins" -PassThru
New-ADOrganizationalUnit -Name Developers -Path "OU=[Domain] Users,DC=ad,DC=hyrule,DC=com" -Description "can log on to Workstations, managed by dev_eng_admins" -PassThru

Joining Users
Using a PowerShell script, join the users in users.csv to your domain.

# Set the domain name and OU
$domain = "ad.hyrule.com"
$ou = "OU=[Domain] Users,DC=ad,DC=hyrule,DC=com"

# Import the CSV file and loop through each user
Import-Csv -Path $csvPath | foreach {
    # Build the distinguished name (DN) of the OU where the user should be added
    $ouPath = "OU={0},$ou" -f $_.OU1, $_.OU2
    $ouDn = "LDAP://{0}/{1}" -f $domain, $ouPath

# Create the user object and set the required attributes
    $newUser = New-Object -TypeName "System.DirectoryServices.DirectoryEntry" -ArgumentList $ouDn
    $newUser.Username = $_.SamAccountName
    $newUser.SetPassword("1234!")  #Unhackable Password
    $newUser.Description = "$($_.FirstName) $($_.LastName)"
    $newUser.DisplayName = "$($_.LastName), $($_.FirstName)"
    $newUser.CommitChanges()

# Add the user to the domain Users group
    $usersGroup = [ADSI]"LDAP://CN=Users,$ou"
    $usersGroup.PSBase.Invoke("Add", $newUser.Path)

    Write-Host "User $($_.SamAccountName) added to OU $ouPath"
}
