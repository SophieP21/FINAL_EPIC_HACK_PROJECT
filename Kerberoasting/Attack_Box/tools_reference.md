# Tools Reference

## Impacket
Python library for network protocols. Includes tools for Kerberos attacks.
- `GetUserSPNs.py` - Enumerate and request Kerberoastable accounts
- `GetNPUsers.py` - AS-REP roasting
- `secretsdump.py` - Dump credentials from DC

## Hashcat
Password cracking tool. Used to crack Kerberos tickets offline.
- Mode 13100 for Kerberos TGS tickets

## John the Ripper
Alternative password cracker.

## Nmap
Network scanner for reconnaissance.

## SMBClient
Interact with SMB shares on Windows systems.

## LDAP Utils
Query Active Directory via LDAP protocol.

## CrackMapExec (optional)
Post-exploitation tool for AD environments.

## BloodHound (optional)
Maps AD relationships and attack paths.

## Rockyou.txt
Common password wordlist for cracking.
