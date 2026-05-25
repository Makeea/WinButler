# Script Description: This PowerShell script downloads and installs the latest QEMU Guest Agent on a Windows computer.

# Check if running with administrator privileges
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as an administrator." -ForegroundColor Red
    exit 1
}

# Define the URL to fetch the latest installer
$installerUrl = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win-guest-tools.exe"

# Define the installer file path
$installerPath = "$env:TEMP\virtio-win-guest-tools.exe"

# Download the QEMU Guest Agent installer
Write-Host "Downloading the latest QEMU Guest Agent installer..."
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

# Install QEMU Guest Agent
Write-Host "Installing QEMU Guest Agent..."
Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait

# Verify installation (customize the path if needed)
if (Test-Path "C:\Program Files\QEMU\qemu-ga.exe") {
    Write-Host "QEMU Guest Agent installed successfully." -ForegroundColor Green
} else {
    Write-Host "QEMU Guest Agent installation failed." -ForegroundColor Red
}

# Cleanup: Remove the installer
Remove-Item -Path $installerPath -Force

# Optional: Configure QEMU Guest Agent settings here if needed

Write-Host "QEMU Guest Agent installation and configuration completed."
