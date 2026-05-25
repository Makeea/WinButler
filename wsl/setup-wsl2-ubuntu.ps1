# To allow this script to run:
# Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# ========================================
# Script to Install WSL 2 and Ubuntu
# ========================================

# Make sure you're running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator."
    exit
}

# Enable required Windows features
Write-Host "`n[+] Enabling Windows Subsystem for Linux and Virtual Machine Platform..."
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -ErrorAction Stop
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -ErrorAction Stop

# Set WSL 2 as default
Write-Host "[+] Setting WSL 2 as default version..."
wsl --set-default-version 2

# Install Ubuntu (default)
Write-Host "[+] Installing Ubuntu via wsl --install..."
try {
    wsl --install -d Ubuntu
} catch {
    Write-Warning "Automatic install failed or WSL is already installed. Continuing..."
}

# Optional: Wait and confirm installed distros
Start-Sleep -Seconds 5
Write-Host "`n[+] Installed distros:"
wsl --list --verbose

Write-Host "`n✅ WSL 2 setup with Ubuntu complete!"
