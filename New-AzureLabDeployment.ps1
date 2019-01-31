<#
    .SYNOPSIS
        Deploys Azure resources via ARM templates#
#>

[cmdletbinding()]
Param (
    [ValidateSet("AzureUSGovernment","AzureCloud","AzureChinaCloud","AzureGermanCloud")]
    [System.String]$Environment = "AzureUSGovernment"
)

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()


#Move to the location of the script if you not threre already
Write-Host "Set-Location to script's directory..."
$Script:DirectoryPath = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) 
Set-Location $Script:DirectoryPath

#Import Helpers
Write-Host "Loading Modules and Helpers..."
Import-Module ".\Modules\AzureDeploymentHelper" -Force -Verbose:$false


#If not logged in to Azure, start login
$AzureConnectionStatus = Get-AzureConnection -Environment $Environment
If (-NOT $AzureConnectionStatus) {Write-Warning "Unable to verify Azure Connection Status!"; Break}
Else {Write-Host "Azure Connection Verified!"}

# Get the configuration data
#Write-Debug "Loading Configuration Data..."

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

Switch ($SizeChoice) {
    0 {$Size = "Small"}
    1 {$Size = "Medium"}
    2 {$Size = "Large"}
}

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

Switch ($OSChoice) {
    0 {$OperatingSystem = "Windows"}
    1 {$OperatingSystem = "Linux"}
    2 {$OperatingSystem = "Both"}
}

#$Configdata = . ("{0}\Environments\Data.ps1" -f $Script:Path)
#$configData = & $ConfigurationPath
$ConfigData = New-AzureLab -Size $Size -OperatingSystem $OperatingSystem -Verbose
If ($ConfigData -eq $false) {
    Write-Warning ("Failed to create Lab Config Data")
    Return $null
}

$Deployments = [Ordered]@{}
Foreach ($Key in $ConfigData.Keys) {
    For ($i=0;$i -lt $ConfigData.$($Key).AvailabilitySets.Count;$i++){
        $Deployments.$("$Key-CreateAvailabilitySet-$i") = $ConfigData.$($Key).AvailabilitySets[$i]
    }
    For ($i=0;$i -lt $ConfigData.$($Key).VirtualMachines.Count;$i++){
        $Deployments.$("$Key-CreateVirtualmachine-$i") = $ConfigData.$($Key).VirtualMachines[$i]
    }
}

Write-Host ("Saving Lab Configuration Data to Json")
$Deployments | ConvertTo-Json | Out-File -FilePath (".\Azure_Lab_ConfigData_{0}.json" -f (Get-Date -Format yyyyMMdd_HHmmss))
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

#Get-PSJobStatus -RefreshInterval 5 -RequiredJobs $Jobs.Count -MaximumJobs $Jobs.Count

$Stopwatch.Stop()
Write-Output ("Script Completed in: {0}" -f $Stopwatch.Elapsed.ToString())
