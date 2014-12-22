### SCRIPT NAME:  AddNewMembers.ps1
###
### DATE UPDATED: 12/01/2014
###
### DEPENDENCIES: CreateAcuUser.ps1
###               fimtoswe.csv
###
### AUTHOR:       Jesse Pifer (v-jpifer@microsoft.com)
###
### DESCRIPTION:  Get list of users with ACU entitlements from FIM (fimtoswe.csv) and compare against
###               current ACU users in ADUC. Any users with FIM ACU entitlements that do not exist in
###               ADUC are created and the username/password outputted to screen to be sent to user
###               via encrypted e-mail.


ipmo activedirectory

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$fromfim = Get-Content -Path "$dir\fimtoswe.csv"
$path = "$dir\toAD.csv"

If ((Test-Path $path) -eq $true) { Clear-Content -Path $path }
"{0},{1}" -f "ACU","Alias" | add-content -Path $path

$ACUs = @("SWE TST ACU","SWE SEC ACU","SWE RWC ACU","SWE RSW ACU","SWE RSP ACU","SWE AZU ACU", "SWE IDT ACU", "SWE IMG ACU", "SWE PLT ACU","SWE REX ACU","SWE RFF ACU","SWE RLY ACU","SWE RNZ ACU","SWE ROD ACU")

Foreach ($ACU in $ACUs)
{

    Switch ($ACU)
        {
        "SWE AZU ACU" {$acronym = "AZU"}
        "SWE IDT ACU" {$acronym = "IDT"}
        "SWE IMG ACU" {$acronym = "IMG"}
        "SWE PLT ACU" {$acronym = "PLT"}
        "SWE REX ACU" {$acronym = "REX"}
        "SWE RFF ACU" {$acronym = "RFF"}
        "SWE RLY ACU" {$acronym = "RLY"}
        "SWE RNZ ACU" {$acronym = "RNZ"}
        "SWE ROD ACU" {$acronym = "ROD"}
        "SWE RSP ACU" {$acronym = "RSP"}
        "SWE RSW ACU" {$acronym = "RSW"}
        "SWE RWC ACU" {$acronym = "RWC"}
        "SWE SEC ACU" {$acronym = "SEC"}
        "SWE TST ACU" {$acronym = "TST"}
        }

    $ACUIndex = $fromfim.IndexOf($ACU)
    $i = 1
    $name = $fromfim[$ACUIndex + $i]

    Write-Host "Checking $ACU" -BackgroundColor DarkCyan

    while ($name -ne "")
    {
        #Write-Host "Checking $name"
        $filter = "displayName -like `"$name`""
        $alias = Get-ADUser -Filter $filter -SearchBase "OU=Managed,OU=Accounts,DC=swe,DC=prd,DC=msft,DC=net" | Select -ExpandProperty SamAccountName
   
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
                Write-Host "$name has not created their basic SWE account" -ForegroundColor "RED"
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

$AzureTeams = @("SWE Azure BOX Team","SWE Azure BXA Team","SWE Azure BXT Team","SWE Azure BXC Team","SWE Azure DC On Call Engineers","SWE Azure SLAM On Call Engineers","SWE Azure SUE On Call Engineers")

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
        $alias = Get-ADUser -Filter $filter -SearchBase "OU=Managed,OU=Accounts,DC=swe,DC=prd,DC=msft,DC=net" | Select -ExpandProperty SamAccountName
           
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
                Write-Host "$name has not created their basic SWE account" -ForegroundColor "RED"
            }
        }

        $i++
        $name = $fromfim[$TeamIndex + $i]
    }
}

Write-Host "Script complete"