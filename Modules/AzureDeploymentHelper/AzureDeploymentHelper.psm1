#region Function Split-Array
Function Split-Array {
	[CmdletBinding()]
	Param(
		$InputObject,
		[Int]$Parts,
		[Int]$Size,
		[ValidateSet("ByIndex","ByName")]
		$KeyType
	)
	If ($Parts) {$PartSize = [Math]::Ceiling($InputObject.Count/$Parts)}
	If ($Size) {
		$PartSize = $Size
		$Parts = [Math]::Ceiling($InputObject.Count/$Size)
	}
	$OutputObject = [Ordered]@{}
	For ($i=1; $i -le $Parts; $i++) {
		$start = (($i-1) * $PartSize)
		$End = ($i * $PartSize) - 1
		If ($end -ge $InputObject.Count) {$End = $InputObject.Count}
		If ($KeyType -eq "ByIndex") {
			If ($i -le 9) {$Key = ("GroupIndex[0{0}]" -f $i)}
			Else {$Key = ("GroupIndex[{0}]" -f $i)}
			$OutputObject.Add($Key,$InputObject[$start..$End])
		}
		ElseIf ($KeyType -eq "ByName") {
			$Key = Read-Host "Enter Key Name ($i of $parts)"
			Write-Verbose "Hash Table Key: $Key"
			$OutputObject.Add($Key,$InputObject[$start..$End])
		}
	}
	Return $OutputObject
}
#endregion

#region Function Get-AzureConnection
Function Get-AzureConnection {
    [CmdletBinding()]
    Param ($Environment)

    If ($null -eq (Get-AzureRmContext).Account) {
        $Context = Login-AzureRmAccount -Environment $Environment -ErrorAction SilentlyContinue
        If ($Context) {Return $true}
        Else {Return $false}
    }
    Else {Return $true}
}
#endregion

#region Function Show-Menu
Function Show-Menu {
    Param(
        [string]$Menu,
        [string]$Title = $(Throw [System.Management.Automation.PSArgumentNullException]::new("Title")),
        [switch]$ClearScreen,
        [Switch]$DisplayOnly,
        [ValidateSet("Full","Mini","Info")]
        $Style = "Full",
        [ValidateSet("White","Cyan","Magenta","Yellow","Green","Red","Gray","DarkGray")]
        $Color = "Gray"
    )
    if ($ClearScreen) {[System.Console]::Clear()}

    If ($Style -eq "Full") {
        #build the menu prompt
        $menuPrompt = "`n`r"
        $menuPrompt = "/" * (95)
        $menuPrompt += "`n`r////`n`r//// $Title`n`r////`n`r"
        $menuPrompt += "/" * (95)
        $menuPrompt += "`n`n"
    }
    ElseIf ($Style -eq "Mini") {
        $menuPrompt = "`n`r"
        $menuPrompt = "\" * (80)
        $menuPrompt += "`n\\\\  $Title`n"
        $menuPrompt += "\" * (80)
        $menuPrompt += "`n"
    }
    ElseIf ($Style -eq "Info") {
        $menuPrompt = "`n`r"
        $menuPrompt = "-" * (80)
        $menuPrompt += "`n-- $Title`n"
        $menuPrompt += "-" * (80)
    }

    #add the menu
    $menuPrompt+=$menu

    [System.Console]::ForegroundColor = $Color
    If ($DisplayOnly) {Write-Host $menuPrompt}
    Else {Read-Host -Prompt $menuprompt}
    [system.console]::ResetColor()
}
#endregion

#region Function Find-AzureSubscription
Function Find-AzureSubscription {
    [CmdletBinding()]
    Param($Environment)
    Write-Verbose "Getting Azure Subscriptions..."
    If (@(Get-AzureConnection -Environment $Environment)) {
        $Subs = Get-AzureRmSubscription | Select Name,Id
        Write-Verbose ("Found {0} Azure Subscriptions" -f $Subs.Count)
        $SubSelection = (@"
`n
"@)
        If (($Subs | Measure-Object).Count -eq 1) {
            Write-Warning ("SINGLE Azure Subscription found, using: {0}" -f $Subs.Name)
            Return $Subs
        }
        Else {
            $SubRange = 0..(($Subs | Measure-Object).Count - 1)
            For ($i = 0; $i -lt ($Subs | Measure-Object).Count;$i++) {$SubSelection += " [$i] $($Subs[$i].Name)`n"}
            $SubSelection += "`n Please select a Subscription"

            Do {
                $SubChoice = Show-Menu -Title "Select an Azure Subscription" -Menu $SubSelection -Style Mini -Color Yellow
            }
            While (($SubRange -notcontains $SubChoice) -OR (-NOT $SubChoice.GetType().Name -eq "Int32"))
            Return $Subs[$SubChoice]
        }
    }
    Else {Return Write-Warning ("Unable to validate Azure Connection!")}
}
#endregion

#region Function Get-PSJobStatus
Function Get-PSJobStatus {
    Param(
        [Int]$RefreshInterval = 5,
        [Int]$RequiredJobs,
        [Int]$MaximumJobs = $RequiredJobs
    )
    While (@(Get-Job -State "Running").Count -ne 0) {
        Clear-Host
        $JobsHashtable = Get-Job | Select Name,State | Group State -AsHashTable -AsString
        $CurrentJobs = (Get-Job | Measure).Count
        $RunningJobs = $JobsHashtable["Running"].Count
        $CompletedJobs = $JobsHashtable["Completed"].Count
        $FailedJobs = $JobsHashtable["Failed"].Count
        $BlockedJobs = $JobsHashtable["Blocked"].Count
        $RemainingJobs = $RequiredJobs - $CurrentJobs
        [System.Collections.Arraylist]$RunningJobStatus = @()
        
        $Status = ("{0} OF {1} JOBS CREATED - MAXIMUM JOBS SET TO {2}" -f $CurrentJobs,$RequiredJobs,$MaximumJobs)
        If ($CurrentJobs -le $MaximumJobs) {Show-Menu -Title "All Background Jobs have been submitted!" -DisplayOnly -Style Mini -Color White}
        Show-Menu -Title $Status -DisplayOnly -Style Info -Color Yellow

        Write-Host " >>" -NoNewline; Write-Host " $RemainingJobs " -NoNewline -ForegroundColor DarkGray; Write-Host "Jobs Remaining" -ForegroundColor DarkGray
        Write-Host " >>" -NoNewline; Write-host " $CurrentJobs " -NoNewline -ForegroundColor White; Write-Host "Total Jobs Created" -ForegroundColor White
        Write-Host " >>" -NoNewline; Write-Host " $RunningJobs " -NoNewline -ForegroundColor Cyan; Write-Host "Jobs In Progress" -ForegroundColor Cyan
        Write-Host " >>" -NoNewline; Write-Host " $CompletedJobs " -NoNewline -ForegroundColor Green; Write-Host "Jobs Completed" -ForegroundColor Green
        Write-Host " >>" -NoNewline; Write-Host " $BlockedJobs " -NoNewline -ForegroundColor Yellow; Write-Host "Jobs Blocked" -ForegroundColor Yellow
        Write-Host " >>" -NoNewline; Write-Host " $FailedJobs " -NoNewline -ForegroundColor Red; Write-Host "Jobs Failed" -ForegroundColor Red

        $Jobs = Get-Job | Group-Object State -AsHashTable -AsString
        foreach ($Job in $Jobs["Running"]) {
            $JobName = $Job.Name
            $JobDuration = ($Job.PSBeginTime - (Get-Date)).Negate()
                                
            $objJob = [PSCustomObject][Ordered]@{
                JobName = ("{0}    " -f $JobName)
                ElapsedTime = ("{0:N0}.{1:N0}:{2:N0}:{3:N0}" -f $JobDuration.Days,$JobDuration.Hours,$JobDuration.Minutes,$JobDuration.Seconds)
                JobStatus = "Azure Deployment Job in Progress"
            }
            [Void]$RunningJobStatus.Add($objJob)
        }

        If ($RunningJobStatus) {
            Show-Menu -Title "Job Status" -DisplayOnly -Style Info -Color Cyan
            $RunningJobStatus | Sort 'JobName' -Descending | Format-Table -AutoSize | Out-Host
        }
        Else {Show-Menu -Title "Waiting for Jobs to Start" -DisplayOnly -Style Info -Color Gray}

        Write-Host "`n`rNext refresh in " -NoNewline
        Write-Host $RefreshInterval -ForegroundColor Magenta -NoNewline
        Write-Host " Seconds"
        Start-Sleep -Seconds $RefreshInterval
    }
}
#endregion

#region Function New-ArmConfig
Function New-ArmConfig {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("AvailabilitySet","VirtualMachine")]
        $Resource,
        [String]$ResourceName,
        [String]$ResourceGroupName,
        [String]$vNetResourceGroup,
        [String]$vNetName,
        [String]$vNetSubnetName,
        [String]$ScriptPath,
        [String]$AzureSubId,
        [String]$Location,
        [String]$UniqueName,
        [String]$OSName,
        [String]$ASName
    )

    Switch ($Resource) {
        "AvailabilitySet" {
            $Hashout = [Ordered]@{
                Name = $ResourceName
                ResourceGroupName = $ResourceGroupName
                TemplateFilePath = ("{0}\ArmTemplates\AVSet.json" -f $ScriptPath)
                Subscription = $AzureSubId
                Parameters = [Ordered]@{
                    avSetName = $ResourceName
                    faultDomains = 2
                    updateDomains = 5
                    location = $Location
                    sku = "Aligned"
                }
            }
        }
        "VirtualMachine" {
            If ([system.string]::IsNullOrEmpty($ASName)) {
                $Hashout = [Ordered]@{
                    Name = $ResourceName
                    ResourceGroupName = $ResourceGroupName
                    TemplateFilePath = ("{0}\ArmTemplates\lab-vm-{1}-noavset.json" -f $ScriptPath,$OSName)
                    Subscription = $AzureSubId
                    Parameters = @{
                        location = $Location
                        storageAccountName = ("{0}stgacct42" -f $ResourceGroupName.Split("-")[1])
                        mySourcePublicIpAddress = ("{0}" -f (Invoke-RestMethod http://ipinfo.io/json -Verbose:$false | % {$_.ip}))
                        publicIPAddressName = ("{0}-publicIP" -f $ResourceName)
                        publicIpAddressType = "Dynamic"
                        publicIpAddressSku = "Basic"
                        networkSecurityGroupName = ("{0}-nsg" -f $ResourceName)
                        vNetResourceGroup = $vNetResourceGroup
                        virtualNetworkName = $vNetName
                        networkInterfaceName = ("{0}-vNic" -f $ResourceName)
                        subnetName = $vNetSubnetName
                        virtualMachineName = $ResourceName
                        virtualMachineSize = "Standard_F1s"
                        adminUsername = "AzureLabAdmin"
                        adminPassword = '@zure@dm|n1!'
                    }
                }
            }
            Else {
                $Hashout = [Ordered]@{
                    Name = $ResourceName
                    ResourceGroupName = $ResourceGroupName
                    TemplateFilePath = ("{0}\ArmTemplates\Lab-VM-{1}.json" -f $ScriptPath,$OSName)
                    Subscription = $AzureSubId
                    Parameters = @{
                        location = $Location
                        storageAccountName = ("{0}stgacct42" -f $ResourceGroupName.Split("-")[1])
                        mySourcePublicIpAddress = ("{0}" -f (Invoke-RestMethod http://ipinfo.io/json -Verbose:$false | % {$_.ip}))
                        publicIPAddressName = ("{0}-publicIP" -f $ResourceName)
                        publicIpAddressType = "Dynamic"
                        publicIpAddressSku = "Basic"
                        networkSecurityGroupName = ("{0}-nsg" -f $ResourceName)
                        vNetResourceGroup = $vNetResourceGroup
                        virtualNetworkName = $vNetName
                        networkInterfaceName = ("{0}-vNic" -f $ResourceName)
                        subnetName = $vNetSubnetName
                        virtualMachineName = $ResourceName
                        virtualMachineSize = "Standard_F1s"
                        adminUsername = "AzureLabAdmin"
                        adminPassword = '@zure@dm|n1!' 
                        availabilitySetName = $ASName
                    }
                }
            }
        }
    }
    Return $Hashout
}
#endregion

#region Function New-AzureLab
Function New-AzureLab {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Small","Medium","Large")]
        [string]$Size,
        [Parameter(Mandatory=$true)]
        [ValidateSet("Windows","Linux","Both")]
        [string]$OperatingSystem
    )
    Write-Debug "Script Start"

    $NetworkResourceGroup = "lab-network-rg"
    $VirtualNetwork = "lab-virtualnetwork"
    $Subnet = "lab-subnet"

    $Path = Get-Location | % {$_.Path}
    $objAzureSub = Find-AzureSubscription -Verbose

    If (Get-AzureRmResourceGroup -Name $NetworkResourceGroup -ErrorAction SilentlyContinue) {
        Write-Verbose ("Found Network Resource Group for Azure Lab Deployment")
        If (Get-AzureRmVirtualNetwork -Name $VirtualNetwork -ResourceGroupName $NetworkResourceGroup -WarningAction SilentlyContinue -ErrorAction SilentlyContinue) {
            Write-Verbose ("Found Virtual Network for Azure Lab Deployment")
            $vNetInfo = Get-AzureRmVirtualNetwork -Name $VirtualNetwork -ResourceGroupName $NetworkResourceGroup -WarningAction SilentlyContinue
        }
        Else {
            Write-Warning ("Found Network Resource Group, but NO Virtual Network - Creating Lab Virtual Network")
            $NewVNetResult = New-AzureRmVirtualNetwork -Name $VirtualNetwork -ResourceGroupName $NetworkResourceGroup -Location $Locations[$LocationChoice].Location -AddressPrefix "172.16.0.0/16" -WarningAction SilentlyContinue
            If ($NewVNetResult.ProvisioningState -eq "Succeeded") {
                $SubnetConfig = Add-AzureRmVirtualNetworkSubnetConfig -Name $Subnet -VirtualNetwork $NewVNetResult -AddressPrefix "172.16.254.0/24" -WarningAction SilentlyContinue
                If ($SubnetConfig.ProvisioningState -eq "Succeeded") {
                    $NewVNetResult | Set-AzureRmVirtualNetwork -WarningAction SilentlyContinue
                }
                Else {
                    Write-Warning ("Failed to create Lab Subnet config")
                    Return $false
                }
            }
            Else {
                Write-Warning ("Failed to create Virtual Network Resource")
                Return $false
            }
        }
    }
    Else {
        Write-Warning ("[{0}] - Network Resource Group not found, Creating Resource Group!" -f $NetworkResourceGroup)
        Write-Verbose "Getting Azure Locations..."
        $Locations = Get-AzureRmLocation | Select DisplayName,Location
        Write-Verbose ("Found {0} Azure Locations" -f $Locations.Count)
        $LocationSelection = (@"
`n
"@)
        $LocationRange = 0..($Locations.Count - 1)
        For ($i = 0; $i -lt $Locations.Count;$i++) {$LocationSelection += " [$i] $($Locations[$i].DisplayName)`n"}
        $i = $null
        $LocationSelection += "`n Please select a Location"
    
        Do {
            $LocationChoice = Show-Menu -Title "Select an Azure Datacenter Location" -Menu $LocationSelection -Style Mini -Color Yellow
        }
        While (($LocationRange -notcontains $LocationChoice) -OR (-NOT $LocationChoice.GetType().Name -eq "Int32"))
        
        Write-Verbose ("Azure Datacenter Location: {0}" -f $Locations[$LocationChoice].DisplayName)
        $NewRGResult = New-AzureRmResourceGroup -Name $NetworkResourceGroup -Location $Locations[$LocationChoice].Location
        If ($NewRGResult.ProvisioningState -eq "Succeeded") {
            Write-Verbose ("Successfully created Network Resource Group - Creating Virtual Network Resource")
            $NewVNetResult = New-AzureRmVirtualNetwork -Name $Virtualnetwork -ResourceGroupName $NetworkResourceGroup -Location $Locations[$LocationChoice].Location -AddressPrefix "172.16.0.0/16" -WarningAction SilentlyContinue
            If ($NewVNetResult.ProvisioningState -eq "Succeeded") {
                $SubnetConfig = Add-AzureRmVirtualNetworkSubnetConfig -Name $Subnet -VirtualNetwork $NewVNetResult -AddressPrefix "172.16.254.0/24" -WarningAction SilentlyContinue
                If ($SubnetConfig.ProvisioningState -eq "Succeeded") {
                    $vNetInfo = $NewVNetResult | Set-AzureRmVirtualNetwork -WarningAction SilentlyContinue
                }
                Else {
                    Write-Warning ("Failed to create Lab Subnet config")
                    Return $false
                }
            }
            Else {
                Write-Warning ("Failed to create Virtual Network Resource")
                Return $false
            }
        }
        Else {
            Write-Warning ("Failed to create Network Resource Group")
            Return $false
        }
    }

    Write-Verbose ("Generating Azure Lab Configuration Data...")
    Switch($Size) {
        Small {
            $Labsize = [Ordered]@{
                VMs = 9
                ResourceGroups = 3
                VMsPerRG = 3
                AVSetsPerRG = 1
                VMsPerAS = 2
                NonASVMsPerRG = 1
            }
        }
        Medium {
            $Labsize = [Ordered]@{
                VMs = 24
                ResourceGroups = 4
                VMsPerRG = 6
                AVSetsPerRG = 2
                VMsPerAS = 2
                NonASVMsPerRG = 2
            }
        }
        Large {
            $Labsize = [Ordered]@{
                VMs = 63
                ResourceGroups = 7
                VMsPerRG = 9
                AVSetsPerRG = 2
                VMsPerAS = 4
                NonASVMsPerRG = 1
            }
        }
    }

    Write-Verbose ("Azure Lab Size Selected: {0} (RGs: {1} / VMs: {2})" -f $Size,$Labsize.ResourceGroups,$Labsize.VMs)
    Switch ($OperatingSystem) {
        "Windows" {[System.Collections.ArrayList]$OS = @("Windows")}
        "Linux" {[System.Collections.ArrayList]$OS = @("Linux")}
        "Both" {[System.Collections.ArrayList]$OS = @("Windows","Linux")}
    }

    $Elements = ("carbon","hellium","neon","argon","krypton","xenon","radon")
    [System.Collections.Hashtable]$LabDetails = [Ordered]@{}
    For ($i=0;$i -lt $Labsize.ResourceGroups;$i++) {
        $Element = $Elements[$i % $Labsize.ResourceGroups]
        $RGName = ("lab-{0}-rg" -f $Element)

        Write-Verbose ("[{0}] - Creating / Validating Resource Group" -f $RGName)
        $AzureResourceGroup = Get-AzureRmResourceGroup -Name $RGName -ErrorAction SilentlyContinue
        If ($AzureResourceGroup) {
            Write-Verbose ("[{0}] - Resource Group exists!" -f $RGName)
            $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $RGName
            If ($StorageAccount) {
                Write-Verbose ("[{0}] - Storage Account exists!" -f $RGName)
            }
            Else {
                Write-Warning ("[{0}] - No Storage Account found, creating Storage Account" -f $RGName)
                $StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $RGName -Name ("{0}stgacct42" -f $Element) -SkuName "Standard_LRS" -Location $AzureResourceGroup.Location -Kind "Storage"
            }
        }
        Else {
            Write-Warning ("[{0}] - Resource Group not found, Creating Resource Group and Storage Account!" -f $RGName)
            Write-Verbose "Getting Azure Locations..."
            $Locations = Get-AzureRmLocation | Select DisplayName,Location
            Write-Verbose ("Found {0} Azure Locations" -f $Locations.Count)
            $LocationSelection = (@"
`n
"@)
            $LocationRange = 0..($Locations.Count - 1)
            For ($b = 0; $b -lt $Locations.Count;$b++) {$LocationSelection += " [$b] $($Locations[$b].DisplayName)`n"}
            $LocationSelection += "`n Please select a Location"
        
            Do {
                $LocationChoice = Show-Menu -Title "Select an Azure Datacenter Location" -Menu $LocationSelection -Style Mini -Color Yellow
            }
            While (($LocationRange -notcontains $LocationChoice) -OR (-NOT $LocationChoice.GetType().Name -eq "Int32"))
            
            Write-Verbose ("Azure Datacenter Location: {0}" -f $Locations[$LocationChoice].DisplayName)

            $AzureResourceGroup = New-AzureRmResourceGroup -Name $RGName -Location $Locations[$LocationChoice].Location
            $StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $RGName -Name ("{0}stgacct42" -f $Element) -SkuName "Standard_LRS" -Location $AzureResourceGroup.Location -Kind "Storage"
        }

        $AVSets = 1..$Labsize.AVSetsPerRG | % {("lab-{0}-as{1}" -f $Element,$_)}
        $VMs = 1..$Labsize.VMsPerRG | % {("labvm{0}-{1}" -f $_,((([char[]]([char]97..[char]122)) + 0..9 | sort {Get-Random})[0..6] -join ""))}
        $ASVMRange = (($labsize.VMsPerAS * $labsize.AVSetsPerRG) - 1)
        $NonASVMRange = $ASVMRange + 1

        $tmpVMHash = Split-Array -InputObject $VMs[0..$ASVMRange] -Parts $Labsize.AVSetsPerRG -KeyType  ByIndex
        $tmpOSHash = Split-Array -InputObject $VMs -Parts $OS.Count -KeyType ByIndex
        $tmpOSHashKeys = ($tmpOSHash.Keys | Sort) | % {$_}
        $tmpVMHashKeys = ($tmpVMHash.Keys | Sort) | % {$_}

        $LabDetails.$($Element) = @{
            ResourceGroup = $RGName
            AvailabilitySets = [Ordered]@{}
            VirtualMachines = [Ordered]@{}
        }

        Write-Verbose ("[{0}] - Working on Availability Sets" -f $RGName)
        Foreach ($AS in $AVSets) {
            $LabDetails.$($Element).AvailabilitySets.$($AS) = New-ArmConfig -Resource AvailabilitySet -ResourceGroupName $AzureResourceGroup.ResourceGroupName -ResourceName $AS -ScriptPath $Path -AzureSubId $objAzureSub.Id -Location $AzureResourceGroup.Location
        }

        Write-Verbose ("[{0}] - Working on Virtual Machines" -f $RGName)
        If ($OS.Count -eq 1) {
            If ($tmpVMHashKeys.Count -gt 1) {
                For ($x=0;$x -lt $tmpVMHashKeys.Count;$x++) {
                    $AVSetName = $AVSets[$x % $tmpVMHashKeys.Count]
                    $tmpVMHashKey = $tmpVMHashKeys[$x]
                    Foreach ($VM in $tmpVMHash[$tmpVMHashKey]) {
                        $LabDetails.$($Element).VirtualMachines.$($VM) = New-ArmConfig -Resource VirtualMachine -ResourceName $VM -ResourceGroupName $AzureResourceGroup.ResourceGroupName -vNetResourceGroup $vNetInfo.ResourceGroupName -vNetName $vNetInfo.Name -vNetSubnetName $vNetInfo.Subnets.Name -ScriptPath $Path -AzureSubId $objAzureSub.id -Location $AzureResourceGroup.Location -UniqueName $Element -OSName $os -ASName $AVSetName
                    }
                }
            }
            Else {
                $AVSetName = $AVSets
                $tmpVMHashKey = $tmpVMHashKeys
                Foreach ($VM in $tmpVMHash[$tmpVMHashKey]) {
                    $LabDetails.$($Element).VirtualMachines.$($VM) = New-ArmConfig -Resource VirtualMachine -ResourceName $VM -ResourceGroupName $AzureResourceGroup.ResourceGroupName -vNetResourceGroup $vNetInfo.ResourceGroupName -vNetName $vNetInfo.Name -vNetSubnetName $vNetInfo.Subnets.Name -ScriptPath $Path -AzureSubId $objAzureSub.id -Location $AzureResourceGroup.Location -UniqueName $Element -OSName $os -ASName $AVSetName
                }
            }

            $VMs[$NonASVMRange..$VMs.Count] | % {
                $VM = $_
                $LabDetails.$($Element).VirtualMachines.$($VM) = New-ArmConfig -Resource VirtualMachine -ResourceName $VM -ResourceGroupName $AzureResourceGroup.ResourceGroupName -vNetResourceGroup $vNetInfo.ResourceGroupName -vNetName $vNetInfo.Name -vNetSubnetName $vNetInfo.Subnets.Name -ScriptPath $Path -AzureSubId $objAzureSub.id -Location $AzureResourceGroup.Location -UniqueName $Element -OSName $OS -ASName $null
            }
        }
        Else {
            If ($tmpVMHashKeys.Count -gt 1) {
                For ($x=0;$x -lt $tmpVMHashKeys.Count;$x++) {
                    $AVSetName = $AVSets[$x % $tmpVMHashKeys.Count]
                    $tmpVMHashKey = $tmpVMHashKeys[$x]
                    Foreach ($VM in $tmpVMHash[$tmpVMHashKey]) {
                        $LabDetails.$($Element).VirtualMachines.$($VM) = New-ArmConfig -Resource VirtualMachine -ResourceName $VM -ResourceGroupName $AzureResourceGroup.ResourceGroupName -vNetResourceGroup $vNetInfo.ResourceGroupName -vNetName $vNetInfo.Name -vNetSubnetName $vNetInfo.Subnets.Name -ScriptPath $Path -AzureSubId $objAzureSub.id -Location $AzureResourceGroup.Location -UniqueName $Element -OSName $os -ASName $AVSetName
                    }
                }
            }
            Else {
                $AVSetName = $AVSets
                $tmpVMHashKey = $tmpVMHashKeys
                Foreach ($VM in $tmpVMHash[$tmpVMHashKey]) {
                    $LabDetails.$($Element).VirtualMachines.$($VM) = New-ArmConfig -Resource VirtualMachine -ResourceName $VM -ResourceGroupName $AzureResourceGroup.ResourceGroupName -vNetResourceGroup $vNetInfo.ResourceGroupName -vNetName $vNetInfo.Name -vNetSubnetName $vNetInfo.Subnets.Name -ScriptPath $Path -AzureSubId $objAzureSub.id -Location $AzureResourceGroup.Location -UniqueName $Element -OSName $os -ASName $AVSetName
                }
            }

            $VMs[$NonASVMRange..$VMs.Count] | % {
                $VM = $_
                $LabDetails.$($Element).VirtualMachines.$($VM) = New-ArmConfig -Resource VirtualMachine -ResourceName $VM -ResourceGroupName $AzureResourceGroup.ResourceGroupName -vNetResourceGroup $vNetInfo.ResourceGroupName -vNetName $vNetInfo.Name -vNetSubnetName $vNetInfo.Subnets.Name -ScriptPath $Path -AzureSubId $objAzureSub.id -Location $AzureResourceGroup.Location -UniqueName $Element -OSName $OS -ASName $null
            }

            For ($a=0;$a -lt $tmpOSHashKeys.Count;$a++) {
                $OSName = $OS[$a % $tmpOSHashKeys.Count]
                $tmpOSHashKey = $tmpOSHashKeys[$a]
                Foreach ($VM in $tmpOSHash[$tmpOSHashKey]) {
                    If ([System.String]::IsNullOrEmpty($LabDetails.$($Element).VirtualMachines.$($VM).Parameters.availabilitySetName)) {
                        $LabDetails.$($Element).VirtualMachines.$($VM).TemplateFilePath = ("{0}\ArmTemplates\lab-vm-{1}-noavset.json" -f $Path,$OSName)
                    }
                    Else {
                        $LabDetails.$($Element).VirtualMachines.$($VM).TemplateFilePath = ("{0}\ArmTemplates\Lab-VM-{1}.json" -f $Path,$OSName)
                    }
                }
            }
        }
    }
    Return $LabDetails
}
#endregion

