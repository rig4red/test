### SCRIPT NAME:  CreateAcuUser.ps1
###
### DATE UPDATED: 06/13/2014
###
### AUTHOR:       Jesse Pifer (v-jpifer@microsoft.com)
###
### DESCRIPTION:  Creates an ACU account based off inputed paramaters $user and $acu.
###               After creating the account the username and password are write-hosted
###               to the console.


Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$user,

    [Parameter(Mandatory=$True)]
    [string]$acu
)

ipmo activedirectory

Function GET-Temppassword() {

# GET-Temppassword found at:
# http://blogs.technet.com/b/heyscriptingguy/archive/2013/06/03/generating-a-new-password-with-windows-powershell.aspx
	
	$ascii=$NULL;For ($a=33;$a –le 126;$a++) {$ascii+=,[char][byte]$a }
		
	For ($loop=1; $loop –le 15; $loop++) {

	    $TempPassword+=($ascii | GET-RANDOM)

	}

	return $TempPassword
}

switch ($acu)
{
	"REX" { 	$groupDisplayName = " - Remote Access (REX)"
				$groupAcronym = "_rex"
				$groupName = "CN=SWE Remote Access Users (REX),OU=Role Groups,OU=Accounts,DC=net"
				$PW = GET-Temppassword
				$secure = ConvertTo-SecureString $PW -AsPlainText -Force }
		
	"RFF" { 	$groupDisplayName = " - Remote Access (RFF)"
				$groupAcronym = "_rff"
				$groupName = "CN=SWE Remote Access Users (RFF),OU=Role Groups,OU=Accounts,DC=net"
				$PW = GET-Temppassword
				$secure = ConvertTo-SecureString $PW -AsPlainText -Force }
		
	"RLY" { 	$groupDisplayName = " - Remote Access (RLY)"
				$groupAcronym = "_rly"
				$groupName = "CN=SWE Remote Access Users (RLY),OU=Role Groups,OU=Accounts,DC=net"
				$PW = GET-Temppassword
				$secure = ConvertTo-SecureString $PW -AsPlainText -Force }
		
	"ROD" { 	$groupDisplayName = " - Remote Access (ROD)"
				$groupAcronym = "_rod"
				$groupName = "CN=SWE Remote Access Users (ROD),OU=Role Groups,OU=Accounts,DC=net"
				$PW = GET-Temppassword
				$secure = ConvertTo-SecureString $PW -AsPlainText -Force }

	"RNZ" {     $groupDisplayName = " - Remote Access (RNZ)"
        		$groupAcronym = "_rnz"
                $groupName = "CN=SWE Remote Access Users (RNZ),OU=Role Groups,OU=Accounts,DC=net"
                $PW = GET-Temppassword
                $secure = ConvertTo-SecureString $PW -AsPlainText -Force }
                        		
	"RSP" { 	$groupDisplayName = " - Remote Access (RSP)"
				$groupAcronym = "_rsp"
				$groupName = "CN=SWE Remote Access Users (RSP),OU=Role Groups,OU=Accounts,DC=net"
				$PW = GET-Temppassword
				$secure = ConvertTo-SecureString $PW -AsPlainText -Force }
		
	"RSW" { 	$groupDisplayName =  " - Remote Access (RSW)"
				$groupAcronym = "_rsw"
				$groupName = "CN=SWE Remote Access Users (RSW),OU=Role Groups,OU=Accounts,DC=net"
				$PW = GET-Temppassword
				$secure = ConvertTo-SecureString $PW -AsPlainText -Force }
		
	"RWC" { 	$groupDisplayName = " - Remote Access (RWC)"
				$groupAcronym = "_rwc"
				$groupName = "CN=SWE Remote Access Users (RWC),OU=Role Groups,OU=Accounts,DC=net"
				$PW = GET-Temppassword
				$secure = ConvertTo-SecureString $PW -AsPlainText -Force }
		
	"TST" { 	$groupDisplayName = " - Remote Access (TST)"
				$groupAcronym = "_tst"
				$groupName = "CN=SWE Remote Access Users (TST),OU=Role Groups,OU=Accounts,DC=net"
				$PW = GET-Temppassword
				$secure = ConvertTo-SecureString $PW -AsPlainText -Force }
		
	"AZU" { 	$groupDisplayName = " - Azure"
				$groupAcronym = "_azu"
				$groupName = "" #"CN=SWE Azure BOX Team,OU=Role Groups,OU=Accounts,DC=net"
				$PW = GET-Temppassword
				$secure = ConvertTo-SecureString $PW -AsPlainText -Force }
		
	"IDT" { 	$groupDisplayName = " - Remote Access (IDT)"
				$groupAcronym = "_idt"
				$groupName = "CN=SWE Identity Team,OU=Role Groups,OU=Accounts,DC=net"
				$PW = GET-Temppassword
				$secure = ConvertTo-SecureString $PW -AsPlainText -Force }
		
	"IMG" { 	$groupDisplayName = " - Imaging"
				$groupAcronym = "_img"
				$groupName = "CN=SWE Imaging Team,OU=Role Groups,OU=Accounts,DC=net"
				$PW = GET-Temppassword
				$secure = ConvertTo-SecureString $PW -AsPlainText -Force }
		
	"PLT" { 	$groupDisplayName = " - Platform"
				$groupAcronym = "_plt"
				$groupName = "CN=SWE Platform Team,OU=Role Groups,OU=Accounts,DC=net"
				$PW = GET-Temppassword
				$secure = ConvertTo-SecureString $PW -AsPlainText -Force }
		
	"SEC" { 	$groupDisplayName = " - Security"
				$groupAcronym = "_sec"
				$groupName = "CN=SWE Security Team,OU=Role Groups,OU=Accounts,DC=net"
				$PW = GET-Temppassword
				$secure = ConvertTo-SecureString $PW -AsPlainText -Force }
}
 
$userObject = Get-ADUser -LDAPFilter "(sAMAccountName=$user)"
$newSam = $userObject.SamAccountName + $groupAcronym
$newDisplayName = $userObject.GivenName + " " + $userObject.Surname + $groupDisplayName
New-ADUser -SamAccountName $newSam -Name $newDisplayName -GivenName $userObject.GivenName -Surname $userObject.Surname -CannotChangePassword $false -DisplayName $newDisplayName -Path "OU=Unmanaged,OU=Accounts,DC=net" -Enabled $true -ChangePasswordAtLogon $true -PasswordNeverExpires $false -AccountPassword $secure

$newUserObject = Get-ADUser -LDAPFilter "(sAMAccountName=$newSam)"
$dName = $newUserObject.DistinguishedName
$newUser = Get-ADUser $dName -Server "net"
$groupN = Get-ADGroup "$groupName" -Server "net"
Add-ADGroupMember $groupN -Members $newUser -Server "net"

write-host $newSam " " $PW