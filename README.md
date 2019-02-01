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
| Resource | Count |
| ----------- | ----------- |
| Virtual Machines (VM) | 9 |
| Resource Groups | 3 |
| VM(s) per Resource Group | 3 |
| Availability Sets (AS) | 3 |
| AS(s) per Resource Group | 1 |
| VM(s) per Availability Set | 2 |
| VM(s) *not* in an Availability Set | 1 |
