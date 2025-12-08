# setup-lab-dc.ps1
# Run this on Windows Server as Administrator

# Install AD DS
Write-Host "[+] Installing AD Domain Services..." -ForegroundColor Green
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Promote to Domain Controller
Write-Host "[+] Promoting to Domain Controller..." -ForegroundColor Green
$SafePassword = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force

Install-ADDSForest `
    -DomainName "lab.local" `
    -DomainNetbiosName "LAB" `
    -SafeModeAdministratorPassword $SafePassword `
    -InstallDns `
    -NoRebootOnCompletion `
    -Force

Write-Host "[+] DC setup complete. Reboot required." -ForegroundColor Yellow
Write-Host "[+] After reboot, run setup-kerberoast-targets.ps1" -ForegroundColor Yellow
