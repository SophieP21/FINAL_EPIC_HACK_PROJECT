Kerberoasting Enironment Setup Guide

# Environment Setup Guide

## Prerequisites

- Windows computer with administrator access
- Azure account (Azure for Students recommended)
- Internet connection

## Steps

### Install Chocolatey

Open PowerShell as Administrator:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### Install Tools
```powershell
choco install azure-cli terraform git -y
```

Close and reopen PowerShell.

### Login to Azure
```bash
az login
```

Sign in when the browser opens.

### Create Project Structure
```bash
mkdir pentesting-lab
cd pentesting-lab
mkdir terraform
cd terraform
```

### Add Terraform Files

Create `main.tf` and `variables.tf` in the terraform directory using the files from this repository.

### Modify Terraform main.tf passwords

## Terraform Configuration Files

### main.tf

Defines the Azure infrastructure for the lab environment:

- **Resource Group**: Container for all lab resources
- **Virtual Network**: 10.0.0.0/16 network with 10.0.1.0/24 subnet
- **Domain Controller VM**: Windows Server 2022 (Standard_B2s) with static IP 10.0.1.10
- **Attacker VM**: Kali Linux (Standard_B2s) with dynamic IP
- **Public IPs**: Assigned to both VMs for external access
- **Network Security Groups**: Allow RDP to DC, SSH to attacker, and internal network traffic
- **Outputs**: Displays public IPs and connection information after deployment

### variables.tf

Optional configuration file that defines customizable parameters:

- Azure region (default: East US)
- Resource group name
- Admin credentials
- VM sizes
- Network settings

Variables allow you to modify the deployment without editing main.tf directly.

## Running Terraform from host to build the Azure infrastruction

### Terraform Commands
With the configuration files in your directory, set up the working directory with 
```bash
terraform init
```

OPTIONAL: Ensuring the terraform plan is correct, check the output of 'plan' to verify the infrastructure build
```bash
terraform plan
```

To build the Azure infrastructure
```bash
terraform apply
```

Terraform will output the build plan and confirm the build actions
```bash
yes
```
Terraform will output the Ip addresses of the 



