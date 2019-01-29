<#
    .SYNOPSIS
        Deploys Azure resources via ARM templates#
#>

[cmdletbinding()]
Param (
    [ValidateSet("AzureUSGovernment","AzureCloud","AzureChinaCloud","AzureGermanCloud")]
    [System.String]$Environment = "AzureUSGovernment"
)

$elapsed = [System.Diagnostics.Stopwatch]::StartNew()


#Move to the location of the script if you not threre already
Write-Host "Set-Location to script's directory..."
$Script:DirectoryPath = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) 
Set-Location $Script:DirectoryPath

#Import Helpers
Write-Host "Loading Modules and Helpers..."
Import-Module ".\Modules\AzureDeploymentHelper" -Force -Verbose


#If not logged in to Azure, start login
$AzureConnectionStatus = Get-AzureConnection -Environment $Environment
If (-NOT $AzureConnectionStatus) {Write-Warning "Unable to verify Azure Connection Status!"; Break}
Else {Write-Verbose "Azure Connection Verified!"}

#Save Starting Sub
Write-Host "Pop Up - Select Starting Subscription in Out-Gridview"
#$StartingSub = Get-AzureRmSubscription | Out-GridView -OutputMode Single -Title "Select Starting Subscription"
#$Script:objAzureSub = Find-AzureSubscription -Verbose

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
$ConfigData = Generate-LabDetails -Size $Size -OperatingSystem $OperatingSystem -Verbose

$Deployments = [Ordered]@{}
Foreach ($Key in $ConfigData.Keys) {
    For ($i=0;$i -lt $ConfigData.$($Key).AvailabilitySets.Count;$i++){
        $Deployments.$("$Key-CreateAvailabilitySet-$i") = $ConfigData.$($Key).AvailabilitySets[$i]
    }
    For ($i=0;$i -lt $ConfigData.$($Key).VirtualMachines.Count;$i++){
        $Deployments.$("$Key-CreateVirtualmachine-$i") = $ConfigData.$($Key).VirtualMachines[$i]
    }
}

$deploymentJobs = @()
foreach($Deployment in $Deployments.Keys)
{
    Write-Debug "Deploying $($Deployments[$Deployment])"

    $deploymentJobs += @{
        Job = New-ArmDeployment -TemplateFile $Deployment.TemplateFilePath `
                                -DeploymentName $Deployment.DeploymentName `
                                -ResourceGroupName $Deployment.ResourceGroupName `
                                -Subscription $Deployment.Subscription `
                                -TemplateParameterObject $Deployment.Parameters `
                                -Verbose
        DeploymentName = $Deployment.DeploymentName
    }

    # Pause for 5 seconds otherwise we can have name collision issues
    Start-Sleep -Second 5
}

do
{
    $jobsStillRunning = $false
    foreach($deploymentJob in $deploymentJobs)
    {
        Receive-Job -Job $deploymentJob.Job

        $currentStatus = Get-Job -Id $deploymentJob.Job.Id

        if(@("NotStarted", "Running") -contains $currentStatus.State)
        {
            $jobsStillRunning = $true
            Start-Sleep -Second 10
        }
    }
}
while($jobsStillRunning)

If ((Get-AzureRmContext).Subscription.ID -ne $StartingSub) {
    Write-Host "Changing back to starting Subscription $($StartingSub)"
    Set-AzureRmContext -SubscriptionId $StartingSub 
}

Write-Output "Total Elapsed Time: $($elapsed.Elapsed.ToString())"

$elapsed.Stop()
