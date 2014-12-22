### SCRIPT NAME:  AddNewMembers.ps1
###
### DATE UPDATED: 12/01/2014
###
### DEPENDENCIES: CreateAcuUser.ps1
###               fimtoENV.csv
###
### AUTHOR:       Jesse Pifer
###
### DESCRIPTION:  Get list of users with ACU entitlements from FIM (fimtoENV.csv) and compare against
###               current ACU users in ADUC. Any users with FIM ACU entitlements that do not exist in
###               ADUC are created and the username/password outputted to screen to be sent to user
###               via encrypted e-mail.


ipmo activedirectory

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$fromfim = Get-Content -Path "$dir\fimtoENV.csv"
$path = "$dir\toAD.csv"

If ((Test-Path $path) -eq $true) { Clear-Content -Path $path }
"{0},{1}" -f "ACU","Alias" | add-content -Path $path

$ACUs = @("ENV TST ACU","ENV SEC ACU","ENV RWC ACU","ENV RSW ACU","ENV RSP ACU","ENV AZU ACU", "ENV IDT ACU", "ENV IMG ACU", "ENV PLT ACU","ENV REX ACU","ENV RFF ACU","ENV RLY ACU","ENV RNZ ACU","ENV ROD ACU")

Foreach ($ACU in $ACUs)
{

    Switch ($ACU)
        {
        "ENV AZU ACU" {$acronym = "AZU"}
        "ENV IDT ACU" {$acronym = "IDT"}
        "ENV IMG ACU" {$acronym = "IMG"}
        "ENV PLT ACU" {$acronym = "PLT"}
        "ENV REX ACU" {$acronym = "REX"}
        "ENV RFF ACU" {$acronym = "RFF"}
        "ENV RLY ACU" {$acronym = "RLY"}
        "ENV RNZ ACU" {$acronym = "RNZ"}
        "ENV ROD ACU" {$acronym = "ROD"}
        "ENV RSP ACU" {$acronym = "RSP"}
        "ENV RSW ACU" {$acronym = "RSW"}
        "ENV RWC ACU" {$acronym = "RWC"}
        "ENV SEC ACU" {$acronym = "SEC"}
        "ENV TST ACU" {$acronym = "TST"}
        }

    $ACUIndex = $fromfim.IndexOf($ACU)
    $i = 1
    $name = $fromfim[$ACUIndex + $i]

    Write-Host "Checking $ACU" -BackgroundColor DarkCyan

    while ($name -ne "")
    {
        #Write-Host "Checking $name"
        $filter = "displayName -like `"$name`""
        $alias = Get-ADUser -Filter $filter -SearchBase "OU=Managed,OU=Accounts,DC=ENV,DC=prd,DC=msft,DC=net" | Select -ExpandProperty SamAccountName
   
        if (($alias -ne $null) -and (-not($alias -like "*_ratst*")))
        {
            $aliasacu = $alias + "_" + $acronym
            $filter = "sAMAccountName -like `"$aliasacu`""
            $validateUser = Get-ADUser -Filter $filter | Select -ExpandProperty sAMAccountName

            if ($validateUser -eq $null)
            {
                Write-Host "Creating $acronym - $name - $alias" -ForegroundColor "Green"
                "{0},{1}" -f $acronym,$alias | add-content -Path $path
            }
        }
    
        else
        {
            if (-not($alias -like "*_ratst*"))
            {
                Write-Host "$name has not created their basic ENV account" -ForegroundColor "RED"
            }
        }

        $i++
        $name = $fromfim[$ACUIndex + $i]
    }

}


$toCreate = Import-Csv -Path $path

if ($toCreate -ne $null)
{
    Write-Host "#                    CREATED                    #" -BackgroundColor Green
    Foreach ($user in $toCreate)
    {
       & $dir\CreateAcuUser.ps1 -user $user.Alias -acu $user.ACU
    }
}

Write-Host "`n"

$AzureTeams = @("ENV Azure BOX Team","ENV Azure BXA Team","ENV Azure BXT Team","ENV Azure BXC Team","ENV On Call Engineers","ENV SLAM On Call Engineers","ENV SUE On Call Engineers")

Foreach ($team in $AzureTeams)
{
    $TeamIndex = $fromfim.IndexOf($team)
    $i = 1
    $name = $fromfim[$TeamIndex + $i]

    $membership = Get-ADGroupMember -Identity $team

    Write-Host "Checking $team" -BackgroundColor DarkCyan

    while ($name -ne "")
    {
        $filter = "displayName -like `"$name`""
        $alias = Get-ADUser -Filter $filter -SearchBase "OU=Managed,OU=Accounts,DC=ENV,DC=prd,DC=msft,DC=net" | Select -ExpandProperty SamAccountName
           
        if (($alias -ne $null) -and (-not($alias -like "*_ratst*")))
        {
            $alias += "_azu"
            if ((Get-ADUser -Filter {SamAccountName -like $alias} | Select -ExpandProperty SamAccountName) -ne $null)
            {            
                if (-not($membership.SamAccountName -contains $alias))
                {
                    Write-Host "Adding $alias"
                    Add-ADGroupMember -Identity $team -Members $alias
                }
            }
            else
            {
                Write-Host "$alias does not exist"
            }
        }
        
        else
        {
            if (-not($alias -like "*_ratst*"))
            {
                Write-Host "$name has not created their basic ENV account" -ForegroundColor "RED"
            }
        }

        $i++
        $name = $fromfim[$TeamIndex + $i]
    }
}

Write-Host "Script complete"