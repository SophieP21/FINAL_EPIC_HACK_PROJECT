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
