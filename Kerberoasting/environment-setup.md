# Kerberoasting Environment Setup Guide

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

### Accept Marketplace Terms

Accept the terms for Ubuntu:
```bash
az vm image terms accept --publisher Canonical --offer 0001-com-ubuntu-server-jammy --plan 22_04-lts-gen2
```

### Create Project Structure
```bash
mkdir pentesting-lab
cd pentesting-lab
mkdir terraform
cd terraform
```

### Add Terraform Files

Create `main.tf` and `variables.tf` in the terraform directory using the files from this repository.

### Modify Terraform Passwords

Before deploying, change the default passwords in `main.tf`:
- Search for `P@ssw0rd123!ChangeMe`
- Replace with your own strong passwords
- Do not commit these passwords to GitHub

## Terraform Configuration Files

### main.tf

Defines the Azure infrastructure for the lab environment:

- **Resource Group**: Container for all lab resources
- **Virtual Network**: 10.0.0.0/16 network with 10.0.1.0/24 subnet
- **Domain Controller VM**: Windows Server 2022 (Standard_B2s) with static IP 10.0.1.10
- **Attacker VM**: Ubuntu 22.04 (Standard_B2s) with dynamic IP
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

## Running Terraform to Build Azure Infrastructure

### Terraform Commands

Initialize the working directory:
```bash
terraform init
```

(Optional) Preview the infrastructure plan:
```bash
terraform plan
```

Build the Azure infrastructure:
```bash
terraform apply
```

Confirm by typing:
```bash
yes
```

The output upon completion will show:
```
Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs:

attacker_public_ip = "XX.XXX.XXX.XX"
connection_info = <<EOT

Domain Controller:
  RDP: XX.XXX.XXX.XXX
  Username: labadmin
  Password: P@ssw0rd123!ChangeMe

Attacker Machine:
  SSH: ssh kali@XX.XXX.XXX.XX
  Password: P@ssw0rd123!ChangeMe

EOT
dc_public_ip = "XX.XXX.XXX.XXX"
```

Make note of this information. To see this output again from `/pentesting-lab/terraform/`:
```bash
terraform output
```

## Configuring Active Directory

Connect to the DC and upload the `setup-lab-dc.ps1` and `setup-kerberoast-targets.ps1` scripts from the PowerShell directory in the repo.

Setting up Azure Bastion can make connecting via GUI easier.

Open PowerShell as Administrator.

If you get an execution policy error, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Run the DC setup script:
```powershell
.\setup-lab-dc.ps1
```

**What it does:** Installs Active Directory Domain Services and promotes the server to a Domain Controller for the "lab.local" domain. Configures DNS automatically and prepares the server for reboot.

**Note:** You may see warnings about static IP assignment and DNS delegation. These can be ignored in a lab environment.

Reboot:
```powershell
Restart-Computer
```

After reboot, run the vulnerable accounts script:
```powershell
.\setup-kerberoast-targets.ps1
```

**What it does:** Creates vulnerable service accounts with SPNs and regular domain user accounts. Includes three service accounts with varying password strengths (weak, medium, strong) to demonstrate kerberoasting attacks.

## Setting Up Attack Box

### Installing Attacker Tools

Upload `install-tools.sh` to the attack box, modify permissions, and run:
```bash
chmod +x install-tools.sh
./install-tools.sh
```

Exit SSH and reconnect, then verify tools are working:
```bash
GetUserSPNs.py -h
```

## Lab Cleanup

### Removing Infrastructure

**Important Notes:**
- You may need to login to Azure again: `az login`
- If Bastion was used, delete it first:
```bash
  az network bastion delete --name lab-vnet-bastion --resource-group pentesting-lab-rg
```

Delete all infrastructure:
```bash
terraform destroy
```

Type `yes` to confirm deletion.
