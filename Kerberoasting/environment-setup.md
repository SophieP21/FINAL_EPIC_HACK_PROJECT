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
The output upon completion will show
```bash
Apply complete! Resources: 1 added, 1 changed, 0 destroyed.

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
Make note of this information. To see this output again use the output command from the working directory `/pentesting-lab/terraform/`
```bash
terraform output
```
## Configuring Active Directory

Connect to the DC and upload the `setup-lab-dc.ps1` and `setup-kerberoast-targets.ps1` scripts from the PowerShell dir in the repo.

Setting up and connecting through bastion to utilize the GUI can make this process easier.

Open PowerShell as Administrator.

If you get an execution policy error, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Run the `setup-lab-dc.ps1` script to configure the DC:
```powershell
.\setup-lab-dc.ps1
```
`setup-lab-dc.ps1` Installs Active Directory Domain Services and promotes the server to a Domain Controller for the "lab.local" domain. Configures DNS automatically and prepares the server for reboot.
Note: You may see warnings about static IP assignment and DNS delegation. These can be ignored in a lab environment.
Reboot:
```powershell
Restart-Computer
```

Run the `setup-kerberoast-targets.ps1` after the DC has rebooted:
```powershell
.\setup-kerberoast-targets.ps1
```
`setup-kerberoast-targets.ps1` Creates vulnerable service accounts with SPNs and regular domain user accounts. Includes three service accounts with varying password strengths (weak, medium, strong) to demonstrate kerberoasting attacks.

## Setting Up Attack Box

### Installing attacker tools
Upload the `install-tools.sh` to the attack box, modify permissions and then run the script to install the needed tools.
```bash
chmod +x install-tools.sh
```
Run the install script 
```bash
./install-tools.sh
```
Exit SSH and reconnect to your Attack Box then verify the tools are working
```bach
GetUserSPNs.py -h
``` 
## Removing Infrastructure

To clean up the lab enviorment we can use terraform again.
NOTE: You may need to login to Azure through the cli again.

To delete the infrastructure.
```bash
terraform destory
```

