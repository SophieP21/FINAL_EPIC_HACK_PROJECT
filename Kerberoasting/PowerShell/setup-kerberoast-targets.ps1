# setup-kerberoast-targets.ps1
# Run after DC is promoted and rebooted

Import-Module ActiveDirectory

Write-Host "[+] Creating vulnerable service accounts..." -ForegroundColor Green

# Account 1: Weak password, easy to crack
New-ADUser -Name "svc_sql" `
    -SamAccountName "svc_sql" `
    -UserPrincipalName "svc_sql@lab.local" `
    -AccountPassword (ConvertTo-SecureString "Password1" -AsPlainText -Force) `
    -Enabled $true `
    -PasswordNeverExpires $true

Set-ADUser -Identity "svc_sql" -ServicePrincipalNames @{Add="MSSQLSvc/sql01.lab.local:1433"}

# Account 2: Medium password
New-ADUser -Name "svc_web" `
    -SamAccountName "svc_web" `
    -UserPrincipalName "svc_web@lab.local" `
    -AccountPassword (ConvertTo-SecureString "Summer2024!" -AsPlainText -Force) `
    -Enabled $true `
    -PasswordNeverExpires $true

Set-ADUser -Identity "svc_web" -ServicePrincipalNames @{Add="HTTP/web01.lab.local"}

# Account 3: Strong password (won't crack easily)
New-ADUser -Name "svc_backup" `
    -SamAccountName "svc_backup" `
    -UserPrincipalName "svc_backup@lab.local" `
    -AccountPassword (ConvertTo-SecureString "Xy9#mK2$pL8@qR5&nF3!" -AsPlainText -Force) `
    -Enabled $true `
    -PasswordNeverExpires $true

Set-ADUser -Identity "svc_backup" -ServicePrincipalNames @{Add="BackupSvc/backup01.lab.local"}

# Create regular users
Write-Host "[+] Creating regular user accounts..." -ForegroundColor Green

$users = @("jdoe", "asmith", "bwilliams")
foreach ($user in $users) {
    New-ADUser -Name $user `
        -SamAccountName $user `
        -UserPrincipalName "$user@lab.local" `
        -AccountPassword (ConvertTo-SecureString "Welcome123!" -AsPlainText -Force) `
        -Enabled $true `
        -ChangePasswordAtLogon $false
}

Write-Host "[+] Setup complete!" -ForegroundColor Green
Write-Host "Domain: lab.local" -ForegroundColor Cyan
Write-Host "Service Accounts: svc_sql, svc_web, svc_backup" -ForegroundColor Cyan
Write-Host "Regular Users: jdoe, asmith, bwilliams (password: Welcome123!)" -ForegroundColor Cyan
