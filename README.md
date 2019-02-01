# New-AzureLabDeployment

## Overview
Many times I find myself needing to test a specific scenario in my Azure tenant.  Depending on what I need to test, I require a specific number of Virutal Machines / Resource Groups / Availability Sets.  To help decrease the amount of time it takes to stand up such an environment, I wrote this script *New-AzureLabDeployment.ps1* which meets this exact need.

## What does this script do?
With either NO or *minor* edits, this script  will deploy all the required resources for an Azure Lab using a "t-shirt" size deployment model.  When ran, the script will ask you to deploy a Small, Medium or Large sized lab.

> #### Base Configuration Resource
> - Network Resource Group
> - Single Virtual Network
> - One (1) Address Space - 172.16.0.0/16
> - One (1) Subnet - 172.16.254.24

### **Small Lab**
| Resource(s) | Count |
| - | - |
| Virtual Machines (VM) | 9 |
| Resource Groups | 3 |
| VM(s) per Resource Group | 3 |
| Availability Sets (AS) | 3 |
| AS(s) per Resource Group | 1 |
| VM(s) per Availability Set | 2 |
| VM(s) *not* in an Availability Set | 1 |

### **Medium Lab**
| Resource(s) | Count |
| - | - |
| Virtual Machines (VM) | 24 |
| Resource Groups | 4 |
| VM(s) per Resource Group | 6 |
| Availability Sets (AS) | 8 |
| AS(s) per Resource Group | 2 |
| VM(s) per Availability Set | 2 |
| VM(s) *not* in an Availability Set | 2 |

### **Large Lab**
| Resource(s) | Count |
| - | - |
| Virtual Machines (VM) | 63 |
| Resource Groups | 7 |
| VM(s) per Resource Group | 9 |
| Availability Sets (AS) | 18 |
| AS(s) per Resource Group | 2 |
| VM(s) per Availability Set | 4 |
| VM(s) *not* in an Availability Set | 1 |

## How to build your lab?
Clone or Download this repo and run:

```
.\New-AzureLabDeployment.ps1 -Environment AzureCloud -Verbose
```

The script will prompt you for any details:
- What "t-shirt" size lab to build
- Which Operating Systems to deploy **(hard coded to Windows Server 2016 Datacenter and RHEL 7.4)**
- Select your subscription (if you have multiple)
- *First time runs*, the script will create the Resource Groups, Storage Accounts, and Virtual Network
- *Subsequent runs*, the script will verify the requirements and build the deployment file

### Labsize Selection Screen
![lab size](media/labsize.png)

### OS Selection Screen
![os](media/operatingsystems.png)

### Subsequent Lab Deployments with existing Resource Groups
![Verbose Output](media/verboseoutput.png)
