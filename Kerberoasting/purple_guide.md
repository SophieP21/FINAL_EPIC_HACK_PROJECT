# Kerberoasting Mitigation Guide

## Overview

Defensive measures to detect and prevent kerberoasting attacks in Active Directory.

## Prevention

### Strong Service Account Passwords

Enforce 25+ character passwords for service accounts:
```powershell
Set-ADAccountPassword -Identity svc_sql -Reset -NewPassword (ConvertTo-SecureString "ComplexPassword25Chars!!" -AsPlainText -Force)
```
## Result
Before enforing the password character count, we cracked the svc_sql password in 46 seconds as seen in the screenshot below.
After applying a more complex password, the screen show below shows the dictionairy attack fail.

### Managed Service Accounts (gMSA)

Use gMSA for automatic password management:
```powershell
New-ADServiceAccount -Name gMSA_SQL -DNSHostName sql01.lab.local -PrincipalsAllowedToRetrieveManagedPassword "Domain Controllers"
Install-ADServiceAccount -Identity gMSA_SQL
```

Benefits: 120-character passwords, auto-rotation every 30 days.

### Force AES Encryption

Disable RC4, enforce AES:
```powershell
Set-ADUser -Identity svc_sql -KerberosEncryptionType AES128, AES256
```

### Least Privilege

Remove service accounts from privileged groups:
```powershell
Get-ADUser svc_sql -Properties MemberOf
Remove-ADGroupMember -Identity "Domain Admins" -Members svc_sql
```

### Protected Users Group

Add service accounts to Protected Users (forces AES, limits TGT to 4 hours):
```powershell
Add-ADGroupMember -Identity "Protected Users" -Members svc_sql
```

Note: Test first - may break legacy apps.

## Detection

### Audit Kerberos Tickets

Enable Event ID 4769 auditing:
```powershell
auditpol /set /subcategory:"Kerberos Service Ticket Operations" /success:enable
```

Alert on:
- Single user requesting multiple SPNs rapidly
- RC4 tickets when AES should be used
- Unusual request sources

### Honeypot Accounts

Create decoy service accounts:
```powershell
New-ADUser -Name "svc_backup_admin" -SamAccountName "svc_backup_admin" -AccountPassword (ConvertTo-SecureString "HoneypotPass123!" -AsPlainText -Force) -Enabled $true
Set-ADUser -Identity "svc_backup_admin" -ServicePrincipalNames @{Add="BackupExec/backup-dr.lab.local"}
```

Alert on any TGS request for this account.

### Detection Tools

**Windows Defender for Endpoint**

Built-in detection for common tools:
```powershell
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -MAPSReporting Advanced
```

Detects: Mimikatz, Rubeus, Invoke-Kerberoast

**Sysmon**

Log detailed system activity:
```powershell
# Download and install Sysmon
Invoke-WebRequest -Uri https://download.sysinternals.com/files/Sysmon.zip -OutFile sysmon.zip
Expand-Archive sysmon.zip
.\sysmon64.exe -accepteula -i
```

Monitors process creation and network connections (Event IDs 1 and 3).

**Snort/Suricata (IDS)**

Network-based detection:
```bash
# Suricata rule for Kerberos anomalies
alert tcp any any -> any 88 (msg:"Possible Kerberoasting - Multiple TGS Requests"; threshold:type threshold, track by_src, count 10, seconds 60; sid:1000001;)
```

**Elastic Security / Wazuh (Free SIEM)**

- Install agent on DC
- Forward Security logs
- Create detection rules for multiple TGS requests from single user

## Validation

### Before Mitigation
```bash
GetUserSPNs.py lab.local/jdoe:Welcome123! -dc-ip 10.0.1.10 -request -outputfile before.txt
hashcat -m 13100 before.txt /usr/share/wordlists/rockyou.txt --force
```

Result: svc_sql cracked in 46 seconds.

### After Mitigation

Reset password:
```powershell
Set-ADAccountPassword -Identity svc_sql -Reset -NewPassword (ConvertTo-SecureString "Xy9#mK2$pL8@qR5&nF3!vB7@hT4$" -AsPlainText -Force)
```

Retest:
```bash
GetUserSPNs.py lab.local/jdoe:Welcome123! -dc-ip 10.0.1.10 -request -outputfile after.txt
hashcat -m 13100 after.txt /usr/share/wordlists/rockyou.txt --force
```

Result: Password not cracked.

## Summary

| Control | Difficulty | Effectiveness |
|---------|-----------|---------------|
| Strong Passwords | Easy | High |
| gMSA | Medium | Very High |
| AES Only | Easy | Medium |
| Protected Users | Medium | High |
| Least Privilege | Medium | Medium |
| Audit 4769 | Easy | Medium |
| Honeypots | Easy | High |

## Implementation Order

1. Day 1: Enable auditing, identify weak passwords, create honeypots
2. Week 1: Reset weak passwords (25+ chars), enforce AES, reduce privileges
3. Month 1: Migrate to gMSA, implement monitoring
4. Ongoing: Regular audits, quarterly access reviews

## References

- MITRE ATT&CK T1558.003
- Microsoft Kerberos Security Documentation
