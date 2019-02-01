<#
.SYNOPSIS
  Creates a new Azure Lab from upto three lab size choices (small, medium, large) using Resource Group Deployment methodology.

.DESCRIPTION
  This script is pre-configured to create an Azure IaaS lab.  The 3 unique sizes take into account the desire to have multiple Resource Groups, Virtual Machines in each Resource Group, some Virtual Machines in Availability Sets, a Single common Virtual Network and Address Space, and shared Storage Accounts within each Resource Group.

  ------------------------------------------------------------------------------------------------------------
  Default Resources:    1 Network Resource Group (lab-network-rg)
                        1 Virtual Network (lab-virtualnetwork)
                        1 Address Space / Subnet (172.16.0.0/16 / 172.16.254.0/24)

  Labsize Small:        9 Virtual Machines (VM), 3 Resource Groups (RG), 1 Storage Account (SA) per RG,
                        3 VM(s) per RG, 1 Availability Set (AS) per RG

  Labsize Medium:       24 Virtual Machines (VM), 4 Resource Groups (RG), 1 Storage Account (SA) per RG,
                        6 VM(s) per RG, 2 Availability Sets (AS) per RG

  Labsize Large:        63 Virtual Machines (VM), 7 Resource Groups (RG), 1 Storage Account (SA) per RG,
                        9 VM(s) per RG, 2 Availability Set (AS) per RG

  
  Resource Groups:      With 7 maximum RG(s), the script will use 7 elements from the periodic table
                        as the unique name for the RG

  Virtual Machines:     Each VM will be labled as labvm followed by a numeric increment, a hyphen, and a
                        random 6 character string
                        e.g. labvm1-ak8sf9

  Operating System:     Choose All Windows (2016-Datacenter), All Linux (RHEL 7.4) or a Both
  ------------------------------------------------------------------------------------------------------------
#>
[CmdletBinding()]
Param (
    [ValidateSet("AzureUSGovernment","AzureCloud","AzureChinaCloud","AzureGermanCloud")]
    [System.String]$Environment = "AzureUSGovernment"
)
# Create Script timer object
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Move to the script directory if not already there
Write-Host "Set-Location to script's directory..."
$Script:DirectoryPath = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) 
Set-Location $Script:DirectoryPath

# Import Deployment Module for dependant functions
Write-Host "Loading Module..."
Import-Module ".\Modules\AzureDeploymentHelper" -Force -Verbose:$false

# Validate / Connect to Azure Subscription
$AzureConnectionStatus = Get-AzureConnection -Environment $Environment
If (-NOT $AzureConnectionStatus) {Write-Warning "Unable to verify Azure Connection Status!"; Break}
Else {Write-Host "Azure Connection Verified!"}

# Create Lab Size Selection Menu
$SizeSelection = (@"
`n
 [0] Small (9 VMs / 3 Resource Groups)
 [1] Medium (24 VMs / 4 Resource Groups)
 [2] Large (63 VMs / 7 Resource Groups)
 `n
  Please select a Lab Size
"@)

$SizeRange = 0..2
Do {
    $SizeChoice = Show-Menu -Title "Select an Azure Lab Size" -Menu $SizeSelection -Style Mini -Color Yellow
}
While (($SizeRange -notcontains $SizeChoice) -OR (-NOT $SizeChoice.GetType().Name -eq "Int32"))

# Sets the Size varible used in the New-AzureLab function
Switch ($SizeChoice) {
    0 {$Size = "Small"}
    1 {$Size = "Medium"}
    2 {$Size = "Large"}
}

# Create Operating System deployment selection
$OSSelection = (@"
`n
 [0] Windows Server
 [1] Linux (RHEL)
 [2] Windows Server and Linux (RHEL)
 `n
  Please select an Operating System
"@)

$OSRange = 0..2
Do {
    $OSChoice = Show-Menu -Title "Select an Operating System deployment" -Menu $OSSelection -Style Mini -Color Yellow
}
While (($OSRange -notcontains $OSChoice) -OR (-NOT $OSChoice.GetType().Name -eq "Int32"))

# Sets the OperatingSystem variable for the New-AzureLab function
Switch ($OSChoice) {
    0 {$OperatingSystem = "Windows"}
    1 {$OperatingSystem = "Linux"}
    2 {$OperatingSystem = "Both"}
}

# Creates lab configuration hashtable based on the parameters
$ConfigData = New-AzureLab -Size $Size -OperatingSystem $OperatingSystem -Verbose
If ($ConfigData -eq $false) {
    Write-Warning ("Failed to create Lab Config Data")
    Return $null
}

# Builds a Deployment hashtable from the lab configuration hashtable
$Deployments = [Ordered]@{}
Foreach ($Key in $ConfigData.Keys) {
    For ($i=0;$i -lt $ConfigData.$($Key).AvailabilitySets.Count;$i++){
        $Deployments.$("$Key-CreateAvailabilitySet-$i") = $ConfigData.$($Key).AvailabilitySets[$i]
    }
    For ($i=0;$i -lt $ConfigData.$($Key).VirtualMachines.Count;$i++){
        $Deployments.$("$Key-CreateVirtualmachine-$i") = $ConfigData.$($Key).VirtualMachines[$i]
    }
}

# Exports the lab deployment hashtable to a json file for review and history
$Exportfile = ("{0}\Exports\Azure_Lab_ConfigData_{1}" -f $Script:DirectoryPath,(Get-Date -Format yyyyMMdd_HHmmss))
Write-Host ("Saving Lab Configuration Data to Json: {0}" -f $Exportfile)
$Deployments | ConvertTo-Json | Out-File -FilePath $Exportfile

Write-Host ("Found {0} Deployments in the lab configuration data" -f $Deployments.Count)
[System.Collections.ArrayList]$Jobs = @()
foreach($DeploymentName in $Deployments.Keys) {
    Write-Host "Deploying $DeploymentName"
    $DeploymentParams = [Ordered]@{
        Name = $DeploymentName
        ResourceGroupName = $Deployments[$DeploymentName].ResourceGroupName
        TemplateFile = $Deployments[$DeploymentName].TemplateFilePath
        TemplateParameterObject = $Deployments[$DeploymentName].Parameters
    }
    $DeploymentJob = New-AzureRmResourceGroupDeployment @DeploymentParams -AsJob
    [Void]$Jobs.Add($DeploymentJob)
}

Write-Host ("Created {0} Deployment Jobs" -f $Jobs.Count)

Start-Sleep -Milliseconds 1750
Read-Host "Press any key to monitor the background jobs..."

Get-PSJobStatus -RefreshInterval 5 -RequiredJobs $Jobs.Count -MaximumJobs $Jobs.Count

$Stopwatch.Stop()
Write-Output ("Script Completed in: {0}" -f $Stopwatch.Elapsed.ToString())
