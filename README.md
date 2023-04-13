# Setup AD DC  

Command to install AD services:  

- Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools  


^ Make static IP ^  
  

- Domain Name: ad.hyrule.com  

- Domain Controller Name: AlexDC1  

- Domain DNS IP: 10.0.0.19 (private)  34.200.110.131 (public)  

## Create OUs  

Create the following Organizational Units  

- [Domain] Computers - client / user machines  

  - Conference - publicly accessible kiosks and presentation devices  

  - Secure - machines for HR and finance users  

  - Workstations - machines for devs and engineers  

- [Domain] Servers - servers for org (data shares, repo hosts, HPCs)  

- [Domain] Users  

  - Finance - can log on to Secure computers, managed by hr_finance_admins group  

  - HR - can log on to Secure computers, managed by hr_finance_admins group  

  - Engineers - can log on to Workstations, managed by dev_eng_admins  

  - Developers - can log on to Workstations, managed by dev_eng_admins  
  

New-ADOrganizationalUnit -Name Conference -Path "OU=[Domain] Computers,DC=ad,DC=hyrule,DC=com" -Description "Kiosks/Presentations" -PassThru  

New-ADOrganizationalUnit -Name Secure -Path "OU=[Domain] Computers,DC=ad,DC=hyrule,DC=com" -Description "HR and finance" -PassThru  

New-ADOrganizationalUnit -Name Workstations -Path "OU=[Domain] Computers,DC=ad,DC=hyrule,DC=com" -Description "devs and engineers" -PassThru  

New-ADOrganizationalUnit -Name Finance -Path "OU=[Domain] Users,DC=ad,DC=hyrule,DC=com" -Description "can log on to Secure computers, managed by hr_finance_admins" -PassThru  

New-ADOrganizationalUnit -Name HR -Path "OU=[Domain] Users,DC=ad,DC=hyrule,DC=com" -Description "can log on to Secure computers, managed by hr_finance_admins" -PassThru  

New-ADOrganizationalUnit -Name Engineers -Path "OU=[Domain] Users,DC=ad,DC=hyrule,DC=com" -Description "can log on to Workstations, managed by dev_eng_admins" -PassThru  

New-ADOrganizationalUnit -Name Developers -Path "OU=[Domain] Users,DC=ad,DC=hyrule,DC=com" -Description "can log on to Workstations, managed by dev_eng_admins" -PassThru  
  


## Joining Users  

Using a PowerShell script, join the users in users.csv to your domain.  
  

### Set the domain name and OU  

$domain = "ad.hyrule.com"  

$ou = "OU=[Domain] Users,DC=ad,DC=hyrule,DC=com"  

### Import the CSV file and loop  

Import-Csv -Path $csvPath | foreach {  

    $ouPath = "OU={0},$ou" -f $_.OU1, $_.OU2  

    $ouDn = "LDAP://{0}/{1}" -f $domain, $ouPath  
  

    $newUser = New-Object -TypeName "System.DirectoryServices.DirectoryEntry" -ArgumentList $ouDn  

    $newUser.Username = $_.SamAccountName  

    $newUser.SetPassword("1234!")  #Unhackable Password  

    $newUser.Description = "$($_.FirstName) $($_.LastName)"  

    $newUser.DisplayName = "$($_.LastName), $($_.FirstName)"  

    $newUser.CommitChanges()  
  

    $usersGroup = [ADSI]"LDAP://CN=Users,$ou"  

    $usersGroup.PSBase.Invoke("Add", $newUser.Path)  

    Write-Host "User $($_.SamAccountName) added to OU $ouPath"  

}  
  

## Joining Computers  

Write the steps needed to join the Windows Server to the Domain:  
  

1. Open the Server Manager and click on the "Local Server" link.  

2. In the "Computer Name/Domain Changes" window, select Domain and enter ad.hyrule.com.  

3. Open the Active Directory Users and Computers tool on a domain controller.  

4. Right-click the [Domain] Computers OU and select "Delegate Control" from the context menu.  

5. Enter the name of the computer you just joined to the domain and click Check Names  

6. Select the "Create a custom task to delegate" option  

7. Select "Only the following objects in the folder", check the "Computer objects" checkbox.  

8. In the "Permissions" section, select the "Create selected objects in this folder" and "Delete selected objects in this folder" checkboxes.  

9. Click "Next" to continue, and then "Finish" to complete the delegation process.  


## Creating Groups  
  

1. Open the Active Directory Users and Computers management console.  

2. Right-click the OU and select "New" > "Group".  

3. Enter the name of the security group  

4. Once the group is created, right-click on it and select "Properties".  

5. In the "Properties" dialog box, select the "Managed By" tab.  

6. Click the "Change" button to specify who will manage the group.  
  

- project_repos_RW - users who have Read / Write access to project repositories  

  - This group should be placed within the OU that contains the project repositories that the users need access to  

  - finance_RW - users who have Read / Write access to finance share  

- Should be placed within the OU that contains the finance share that the users need access to  

  - onboarding_R - users who have Read access to onboarding documents  

  - Should be placed within the OU that contains the Onboarding folder.  

- server_access - users who can log on to Servers  

  - This group should be placed within the OU that contains the servers  

- dev_eng_admins - IT admins to handle Developer and Engineer accounts  

  - Should be placed within the OU that contains the Developer and Engineer user accounts

- hr_finance_admins - IT admins to handle HR and finance accounts  

  - Should be placed within the OU that contains the HR and finance user accounts  

- remote_workstation - Group of workstations that allow RDP connections  

  - Should be placed within the OU that contains the workstations that allow RDP connections  
  

## OUs & GPOs  

## Applying Group Policies  
  

- Lock out Workstations after 15 minutes of inactivity.  

  - https://activedirectorypro.com/group-policy-lock-screen/  

  - Create a new GPO by right-clicking on the Group Policy Objects folder. Configure within the GPO.  

- Prevent execution of programs on computers in Secure OU  

  - https://rdr-it.com/en/gpo-block-programs-and-prevent-software-installation-software-restriction/  

  - Under the "Security Levels" folder, right-click on "Disallowed" and select "New Path Rule  

- Disable Guest account login to computers in Secure OU  

  - https://4sysops.com/archives/deny-and-allow-workstation-logons-with-group-policy/  

  - Locate the "Accounts: Guest account status" policy, and set it to "Disabled"  

- Allow server_access to sign on to Servers  

  - https://www.anyviewer.com/how-to/allow-remote-access-to-server-2578.html  

  - Locate the "Allow log on through Remote Desktop Services" policy, and add the "server_access" group to the policy.  

- Set Desktop background for Conference computers to the company logo.  

  - https://technoresult.com/how-to-change-desktop-background-set-by-your-organization/  

  - Enable the "Desktop Wallpaper" policy, and specify the path to the company logo image file  

- Allow users in remote_workstation group to RDP to Workstations  

  - https://techdirectarchive.com/2021/10/07/allow-rdp-access-for-non-administrators-add-user-to-remote-desktop-users-group-in-active-directory/  

  - Locate the "Allow log on through Remote Desktop Services" policy, and add the "remote_workstation" group to the policy.  

## Managing OUs  

Join at least one person to the hr_finance_admins and eng_dev_admins groups, respectively. Delegate control of the OUs corresponding to the appropriate admin groups.

Add-ADGroupMember -Identity "eng_dev_admins" -Members "SamAdams"
Add-ADGroupMember -Identity "hr_finance_admins" -Members "JessyJones"
