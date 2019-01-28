    $Elements = ("carbon","hellium","neon","argon","krypton","xenon","radon")
    [System.Collections.Hashtable]$LabDetails = [Ordered]@{}
    For ($i=0;$i -lt $Labsize.ResourceGroups;$i++) {
        $Element = $Elements[$i % $Labsize.ResourceGroups]
        Write-Progress -Activity "Working on: $element" -Status ("$i of $($labsize.ResourceGroups)") -PercentComplete (($i/$Labsize.ResourceGroups)*100)
        $AVSets = 1..$Labsize.AVSetsPerRG | % {("lab-{0}-as{1}" -f $Element,$_)}
        $VMs = 1..$Labsize.VMsPerRG | % {("lab-vm{0}-{1}" -f $_,((([char[]]([char]97..[char]122)) + 0..9 | sort {Get-Random})[0..6] -join ""))}
        $ASVMRange = (($labsize.VMsPerAS * $labsize.AVSetsPerRG) - 1)
        $NonASVMRange = $ASVMRange + 1

        Write-Host "Splitting VM Array"
        $tmpVMHash = Split-Array -InputObject $VMs[0..$ASVMRange] -Parts $Labsize.AVSetsPerRG -KeyType  ByIndex
        $tmpVMHashKeys = ($tmpVMHash.Keys | Sort) | % {$_}

        $LabDetails.$($Element) = @{
            ResourceGroup = ("lab-{0}-rg" -f $Element)
            AvailabilitySets = $AVSets
            VirtualMachines = [Ordered]@{}
        }

        Write-Host "AS Loop"
        For ($x=0;$x -lt $tmpVMHashKeys.Count;$x++) {
            $AVSetName = $AVSets[$x % $tmpVMHashKeys.Count]
            $tmpVMHashKey = $tmpVMHashKeys[$x]
            Foreach ($VM in $tmpVMHash[$tmpVMHashKey]) {
                $LabDetails.$($Element).VirtualMachines.$($VM) = [Ordered]@{
                    AvailabilitySet = $AVSetName
                    OperatingSystem = ""
                }
            }
        }

        Write-Host "Non-AS loop"
        $VMs[$NonASVMRange..$VMs.Count] | % {
            $VM = $_
            $LabDetails.$($Element).VirtualMachines.$($VM) = [Ordered]@{
                AvailabilitySet = ""
                OperatingSystem = ""
            }
        }
    }