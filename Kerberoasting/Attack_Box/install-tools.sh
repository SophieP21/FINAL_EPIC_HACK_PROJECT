#!/bin/bash

# Disable interactive prompts during package installation
export DEBIAN_FRONTEND=noninteractive

echo "[+] Updating system..."
sudo apt update && sudo apt upgrade -y

echo "[+] Updating system..."
sudo apt update && sudo apt upgrade -y

echo "[+] Installing Impacket..."
sudo apt install python3-impacket -y

echo "[+] Installing additional tools..."
sudo apt install -y \
    nmap \
    hashcat \
    john \
    smbclient \
    ldap-utils \
    curl \
    wget \
    git

echo "[+] Installing pip and additional Python tools..."
sudo apt install python3-pip -y
pip3 install ldap3 bloodhound

echo "[+] Installing CrackMapExec via pipx..."
sudo apt install pipx -y
pipx ensurepath
pipx install crackmapexec

echo "[+] Adding Impacket to PATH..."
echo 'export PATH=$PATH:/usr/share/doc/python3-impacket/examples' >> ~/.bashrc
export PATH=$PATH:/usr/share/doc/python3-impacket/examples

echo "[+] Downloading rockyou wordlist..."
sudo mkdir -p /usr/share/wordlists
cd /usr/share/wordlists
sudo wget -q https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt

echo "[+] Testing Impacket installation..."
GetUserSPNs.py -h > /dev/null 2>&1 && echo "Impacket working!" || echo "Impacket test failed - reopen terminal"

echo "[+] Setup complete!"
echo "Tools installed: impacket, nmap, hashcat, john, crackmapexec"
echo "Wordlist: /usr/share/wordlists/rockyou.txt"
echo ""
echo "Note: Close and reopen your terminal for PATH changes to take effect"
