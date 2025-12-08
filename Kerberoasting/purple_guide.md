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
<img width="1897" height="859" alt="Screenshot 2025-12-08 114326" src="https://github.com/user-attachments/assets/05d1bc9c-2590-4c6a-aa69-60a90e37b9bb" />

After applying a more complex password with the powershell command above, the image below shows the dictionairy attack was a failure.
<img width="1244" height="522" alt="image" src="https://github.com/user-attachments/assets/7cb480db-3a38-4531-9452-40604698e533" />

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
First we enable auditing using the command above
<img width="788" height="55" alt="image" src="https://github.com/user-attachments/assets/c2a9aa7a-ed93-4d1f-8416-f1fb58b618a8" />

Following this we can run the attack
<img width="1886" height="278" alt="image" src="https://github.com/user-attachments/assets/39ca3eaa-9037-4728-99dc-09edd5efe76d" />

Show ID 4769 event logs 
```powershell
Get-WinEvent -FilterHashtable @{LogName='Security';ID=4769} -MaxEvents 5 | Format-List TimeCreated, Message
```
The screenshot below shows Event ID 4769 capturing a kerberoasting attempt. It reveals the requesting account (jdoe@LAB.LOCAL), the targeted service account (svc_backup), the weak RC4 encryption type (0x17), and the attacker's IP address (10.0.1.4). This demonstrates that kerberoasting activity is logged and can be monitored for detection and incident response.
<img width="1854" height="825" alt="image" src="https://github.com/user-attachments/assets/cc765d67-b8d8-4557-af67-7b0fc40a366c" />



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
