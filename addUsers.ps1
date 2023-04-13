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
