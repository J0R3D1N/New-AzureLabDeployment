
$deploymentName = $Configdata.Deployments[0].DeploymentName
$ResourceGroupName = $Configdata.Deployments[0].ResourceGroupName
$TemplateFile =  $Configdata.Deployments[0].TemplateFilePath
$TemplateParameterObject =  $Configdata.Deployments[0].Parameters


Set-AzureRmContext -SubscriptionId $Configdata.Deployments[0].Subscription
Set-AzureRmDefault -ResourceGroupName "Prod-RG"
Get-AzureRmDefault

Set-AzureRmContext -SubscriptionId $Configdata.Deployments[0].Subscription
Set-AzureRmDefault -ResourceGroupName "Prod-RG"

$Context = Get-AzureRmContext

New-AzureRmResourceGroupDeployment -Name $deploymentName `
                                    -ResourceGroupName $ResourceGroupName `
                                    -TemplateFile $TemplateFile `
                                    -TemplateParameterObject $TemplateParameterObject `
                                    -Force `
                                    -Verbose

New-AzureRmResourceGroupDeployment -Name $deploymentName `
                                    -DefaultProfile $Context `
                                    -TemplateFile $TemplateFile `
                                    -TemplateParameterObject $TemplateParameterObject `
                                    -Force `
                                    -Verbose

$Configdata.Deployments | Select-Object -Property Subscription,ResourceGroupName,DeploymentName,TemplateFilePath

$Configdata.Deployments.DeploymentName
$Configdata.Deployments | where-object -FilterScript {$_.DeploymentName -ne $Null} | ForEach-Object {$_.DeploymentName} 

$Configdata.Deployments | ForEach-Object {$_.DeploymentName} 

$TargetNodes = $ConfigData.AllNodes | where-object -FilterScript {$_.Env -eq $Env} | ForEach-Object {$_.NodeName} | Out-GridView -Title "Choose Target Nodes" -OutputMode Multiple
#

