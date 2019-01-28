<#
    .SYNOPSIS
        Deploys Azure resources via ARM templates
#>

[cmdletbinding()]
Param (
    [ValidateSet("AzureUSGovernment","AzureCloud","AzureChinaCloud","AzureGermanCloud")]
    [System.String]$Environment = "AzureUSGovernment"
)

$elapsed = [System.Diagnostics.Stopwatch]::StartNew()


#Move to the location of the script if you not threre already
Write-Host "Set-Location to script's directory..."
$Script:Path = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) 
Set-Location $Script:Path

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
$objAzureSub = Find-AzureSubscription -Verbose

# Get the configuration data
Write-Debug "Loading Configuration Data..."
$Configdata = . ("{0}\Environments\Data.ps1" -f $Script:Path)
#$configData = & $ConfigurationPath

#Select Deployments
Write-Host "Pop Up - Select Select Deployments in Out-Gridview"
$DeploymentFilters = $Configdata.Deployments | ForEach-Object {$_.DeploymentName} | Out-GridView -Title "Select Deployments" -OutputMode Multiple

# Apply filter to only deploy the correct Deployments.
$deployDeployment = @()
if($DeploymentFilters)
{
    Write-Verbose "Appling filter to Deployments being deployed"

    foreach($DeploymentFilter in $DeploymentFilters)
    {
        # find any vm that has a name like the VM filter and add it to $deployDeployment unless it is already there
        $deployDeployment += $configData.Deployments.Where{ `
            ($_.DeploymentName -like $DeploymentFilter) `
            -and ($deployDeployment.DeploymentName -notcontains $_.DeploymentName)`
        }
    }
}
else
{
    Write-Verbose "No filter applied, deploying all Deployments"

    $deployDeployment = $configData.Deployments
}

# Start Deployments
Write-Output "`n$($deployDeployment.Count) Deployments Selected"

Write-Host "`nType ""Deploy"" to start Deployments, or Ctrl-C to Exit" -ForegroundColor Green
$HostInput = $Null
$HostInput = Read-Host "Final Answer" 
If ($HostInput -ne "Deploy" ) {
    Write-Host "Exiting"
    break
}

Write-Output "Starting $($deployDeployment.Count) Deployments"

$deploymentJobs = @()
foreach($Deployment in $deployDeployment)
{
    Write-Output "Deploying $($Deployment.DeploymentName)"

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
