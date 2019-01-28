<#
    .SYNOPSIS
        Configuration data file for Dev environment
#>
[CmdletBinding()]
Param()

$Deployments= @(
    @{  CreateAvailabilitySet = @{
            Name = 
            ResourceGroupName = ""
            TemplateFilePath = ("{0}\ArmTemplates\AVSet.json" -f $Script:Path)
            Subscription = $objAzureSub.id
            Parameters = @{
                avSetName = 'ResizeAVSet'
                faultDomains = 2
                updateDomains = 5
                location = ""
                sku = "Aligned"
            }
        }
    }
)

Write-Debug "Loaded Configuration Data..."

Return $Deployments

<#
    @{  DeploymentName = "ResizeVM01"
        ResourceGroupName = "Prod-RG"
        TemplateFilePath = "ArmTemplates\WindowsServer2016_SmallDisk.json"
        Subscription = "ed347077-d367-4401-af11-a87b73bbae0e"
        Parameters = @{
            location = "usgovvirginia"
            virtualMachineName = "ResizeVM01"
            virtualMachineSize = "Standard_D2s_v3"
            adminUsername = "azureuser"
            virtualNetworkName = "prodnet"
            networkInterfaceName = "ResizeVM01_300"
            diskSizeGB = "31"
            networkSecurityGroupName = "ResizeVM01-nsg"
            adminPassword = "S3cedit12345618!" 
            availabilitySetName = "ResizeAVSet"
            diagnosticsStorageAccountName = "diagsa"
            diagnosticsStorageAccountType = "Standard_LRS"
            diagnosticsStorageAccountId = "Microsoft.Storage/storageAccounts/diagsa"
            subnetName = "Subnet1"
            publicIpAddressName = "ResizeVM01-ip"
            publicIpAddressType = "Dynamic"
            publicIpAddressSku = "Basic"
        }
    }
    @{  DeploymentName = "ResizeVM02"
        ResourceGroupName = "Prod-RG"
        TemplateFilePath = ".\ArmTemplates\WindowsServer2016_SmallDisk.json"
        Subscription = "ed347077-d367-4401-af11-a87b73bbae0e"
        Parameters = @{
            location = "usgovvirginia"
            virtualMachineName = "ResizeVM02"
            virtualMachineSize = "Standard_D2s_v3"
            adminUsername = "azureuser"
            virtualNetworkName = "prodnet"
            networkInterfaceName = "ResizeVM02_300"
            diskSizeGB = "31"
            networkSecurityGroupName = "ResizeVM02-nsg"
            adminPassword = "S3cedit12345618!" 
            availabilitySetName = "ResizeAVSet"
            diagnosticsStorageAccountName = "diagsa"
            diagnosticsStorageAccountType = "Standard_LRS"
            diagnosticsStorageAccountId = "Microsoft.Storage/storageAccounts/diagsa"
            subnetName = "Subnet1"
            publicIpAddressName = "ResizeVM02-ip"
            publicIpAddressType = "Dynamic"
            publicIpAddressSku = "Basic"
        }
}#>
