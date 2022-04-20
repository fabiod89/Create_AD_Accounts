#Import System.web assembly for "Generated Password"
Add-Type -AssemblyName System.Web


    #--VARIABLES--

#How long do you want the AD Mnemonic to be
$length_of_mnemonic = 8

#The OU path where the AD account will be created
$OUPath = "OU=Users,DC=test,DC=com"


    #--FUNCTIONS--

function Take-User-Input{
    do {    
        $firstname = Read-Host "First Name"
    } while ([string]::IsNullOrEmpty($firstname))

    do {    
        $lastname = Read-Host "Last Name"
    } while ([string]::IsNullOrEmpty($lastname))

    do {    
        $job_title = Read-Host "Job Title"
    } while ([string]::IsNullOrEmpty($job_title))

    return $firstname, $lastname, $job_title
}

# Function - Double checks if "$lastname, $firstname" is already in Active Directory. If it is, it will close the script
function Check-For-Duplicate{
    $duplicate_user_check = [bool](Get-ADUser -Filter ({ Givenname -eq $firstname -and sn -eq $lastname}))
    if ($duplicate_user_check -eq $True){
        write-host "User $lastname, $firstname already exists in Active Directory. Closing script"
        pause
        exit
    }
}

# Function - This takes the first letter $firstname and 6 characters of $lastname entered and generates an AD 
# mnemonic out of it (Adds a number at the end if duplicate nmnemonic is found)
function Generate-Mnemonic{
    #this is a counter that will go up by "1" for each duplicate found when generting the AD mnemonic
    $duplicate_number = 0

    #This command combines (firstname,lastname, removes spaces, cuts down to "$length_of_mnemonic" characters, 
    #converts to lower-case, adds "$count" to the end of the name (will not display if 0)
    #The DO command will keep going until an AD duplicate is not found
    DO{ $mnemonic = ($firstname[0] + ($lastname.replace(' ' , '').Substring(0,[System.Math]::Min($length_of_mnemonic, ($lastname | Measure-Object -Character -IgnoreWhiteSpace | Select -ExpandProperty Characters))) + ("{0:D2}" -f $duplicate_number | where {$_ -ne "00"}))).Tolower()
        $duplicate_number++}
    UNTIL (([bool] (Get-ADUser -Filter { SamAccountName -eq $mnemonic })) -eq $False)
    return $mnemonic
    }

#This function will generate a password
function Generate-Password{
    $password = ([System.Web.Security.Membership]::GeneratePassword(10,2))
    return $password
}

#Function - Creates AD account
function Create-AD-Account{
    
    #This section of code is used as a way to confirm the user creation, to double check over what you have entered
    cls
    write-host "Confirm. The following user will be created in Active Directory"
    write-host "First Name: $firstname"
    write-host "Last Name: $lastname"
    write-host "Job Title: $job_title"
    write-host "Generated Mnemonic: $mnemonic"
    write-host "Generated Password: $password"
    write-host "OU Path: $OUpath"
    pause
    #Command to Create AD account
    New-ADUser -Name "$lastname, $firstname" -displayName "$lastname, $firstname" -givenName $firstname -Surname $lastname -SamAccountName $mnemonic -UserPrincipalName ($mnemonic + "@example.com") -Title $job_title -Path $OUPath -AccountPassword ($password | ConvertTo-SecureString -AsPlainText -Force) -Enabled $true
    sleep 3
    #This "If" statement is to confirm the User has been created. If User is NOT created, the script will force close
    if (![bool](Get-ADUser -Filter { SamAccountName -eq $mnemonic })) {
        write-host "Error has occured. User has not been created. Closing script"
        pause
        exit
    }
    else{
        write-host "AD account = $mnemonic"
        write-host "First Name = $firstname"
        write-host "Last Name = $lastname"
        write-host "Password = $password"
        write-host "User has been created"
    }
}


function End-Summary{

}

    #-- MAIN --

$firstname, $lastname, $job_title = Take-User-Input
Check-For-Duplicate
$mnemonic = Generate-Mnemonic
$password = Generate-Password
Create-AD-Account
End-Summary
