# Complete WSL Removal Script
# 
# SETUP INSTRUCTIONS:
# 1. Right-click PowerShell and select "Run as Administrator"
# 2. Set execution policy to allow script running:
#    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# 3. Navigate to the script directory and run:
#    .\Remove-WSL.ps1
# 4. After completion, optionally restore execution policy:
#    Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope CurrentUser
#
# This script will completely remove WSL and all Linux distributions from your system.

Write-Host "=== Complete WSL Removal Script ===" -ForegroundColor Green
Write-Host "This script will completely remove WSL and all Linux distributions from your system." -ForegroundColor Yellow
Write-Host ""

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Red
    pause
    exit 1
}

Write-Host "Running as Administrator - proceeding with WSL removal..." -ForegroundColor Green
Write-Host ""

# Step 1: Stop WSL services and processes
Write-Host "Step 1: Stopping WSL services and processes..." -ForegroundColor Cyan
try {
    wsl --shutdown 2>$null
    Write-Host "  ✓ WSL shutdown command executed" -ForegroundColor Green
} catch {
    Write-Host "  ! WSL shutdown failed (may not be running)" -ForegroundColor Yellow
}

try {
    Stop-Process -Name "wslservice" -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ WSL service stopped" -ForegroundColor Green
} catch {
    Write-Host "  ! WSL service not running" -ForegroundColor Yellow
}

# Step 2: Unregister all WSL distributions
Write-Host ""
Write-Host "Step 2: Unregistering all WSL distributions..." -ForegroundColor Cyan
try {
    $distributions = wsl --list --quiet 2>$null
    if ($distributions) {
        foreach ($distro in $distributions) {
            if ($distro.Trim() -ne "") {
                wsl --unregister $distro.Trim() 2>$null
                Write-Host "  ✓ Unregistered: $($distro.Trim())" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "  ✓ No distributions found to unregister" -ForegroundColor Green
    }
} catch {
    Write-Host "  ! Error unregistering distributions" -ForegroundColor Yellow
}

# Step 3: Disable WSL Windows features
Write-Host ""
Write-Host "Step 3: Disabling WSL Windows features..." -ForegroundColor Cyan
try {
    dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart | Out-Null
    Write-Host "  ✓ Disabled Windows Subsystem for Linux" -ForegroundColor Green
} catch {
    Write-Host "  ! Failed to disable WSL feature" -ForegroundColor Red
}

try {
    dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart | Out-Null
    Write-Host "  ✓ Disabled Virtual Machine Platform" -ForegroundColor Green
} catch {
    Write-Host "  ! Failed to disable Virtual Machine Platform" -ForegroundColor Red
}

# Step 4: Disable WSL services
Write-Host ""
Write-Host "Step 4: Disabling WSL services..." -ForegroundColor Cyan
try {
    sc.exe config LxssManager start= disabled | Out-Null
    Write-Host "  ✓ Disabled LxssManager service" -ForegroundColor Green
} catch {
    Write-Host "  ! Failed to disable LxssManager service" -ForegroundColor Yellow
}

# Step 5: Remove WSL folders and files
Write-Host ""
Write-Host "Step 5: Removing WSL folders and files..." -ForegroundColor Cyan

# Main WSL folder
$wslPath = "C:\Users\$env:USERNAME\AppData\Local\wsl"
if (Test-Path $wslPath) {
    Remove-Item -Recurse -Force $wslPath -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed WSL folder" -ForegroundColor Green
} else {
    Write-Host "  ✓ WSL folder not found" -ForegroundColor Green
}

# Windows Terminal WSL fragments
$terminalPath = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\Windows Terminal\Fragments\Microsoft.WSL"
if (Test-Path $terminalPath) {
    Remove-Item -Recurse -Force $terminalPath -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed Windows Terminal WSL fragments" -ForegroundColor Green
} else {
    Write-Host "  ✓ Windows Terminal WSL fragments not found" -ForegroundColor Green
}

# Temporary WSL files
$tempPaths = @(
    "C:\Users\$env:USERNAME\AppData\Local\Temp\wsl-crashes",
    "C:\Users\$env:USERNAME\AppData\Local\Temp\WSLDVCPlugin"
)

foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
        Write-Host "  ✓ Removed $(Split-Path $path -Leaf)" -ForegroundColor Green
    }
}

# WinGet cache for Ubuntu
$wingetPaths = @(
    "C:\Users\$env:USERNAME\AppData\Local\Temp\WinGet\cache\V2_M\Microsoft.Winget.Source_8wekyb3d8bbwe\manifests\c\Canonical\Ubuntu",
    "C:\Users\$env:USERNAME\AppData\Local\Temp\WinGet\cache\V2_PVD\Microsoft.Winget.Source_8wekyb3d8bbwe\packages\Canonical.Ubuntu"
)

foreach ($path in $wingetPaths) {
    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
        Write-Host "  ✓ Removed WinGet Ubuntu cache" -ForegroundColor Green
    }
}

# Check for and remove distribution packages
$packagesPath = "C:\Users\$env:USERNAME\AppData\Local\Packages"
$wslPackages = Get-ChildItem $packagesPath -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -like "*Ubuntu*" -or 
    $_.Name -like "*Debian*" -or 
    $_.Name -like "*Kali*" -or
    $_.Name -like "*CanonicalGroupLimited*" -or
    $_.Name -like "*TheDebianProject*"
}

foreach ($package in $wslPackages) {
    Remove-Item -Recurse -Force $package.FullName -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed package: $($package.Name)" -ForegroundColor Green
}

# Remove lxss folder if it exists
$lxssPath = "C:\Users\$env:USERNAME\AppData\Local\lxss"
if (Test-Path $lxssPath) {
    Remove-Item -Recurse -Force $lxssPath -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed lxss folder" -ForegroundColor Green
}

# Step 6: Clean up registry entries
Write-Host ""
Write-Host "Step 6: Cleaning up registry entries..." -ForegroundColor Cyan
try {
    Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed HKCU WSL registry entries" -ForegroundColor Green
} catch {
    Write-Host "  ✓ HKCU WSL registry entries not found" -ForegroundColor Green
}

try {
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed HKLM WSL registry entries" -ForegroundColor Green
} catch {
    Write-Host "  ✓ HKLM WSL registry entries not found" -ForegroundColor Green
}

# Step 7: Final verification
Write-Host ""
Write-Host "Step 7: Final verification..." -ForegroundColor Cyan

# Check for remaining WSL processes
$wslProcesses = Get-Process | Where-Object {$_.ProcessName -like "*wsl*"} -ErrorAction SilentlyContinue
if ($wslProcesses) {
    Write-Host "  ! Warning: Some WSL processes are still running:" -ForegroundColor Yellow
    foreach ($process in $wslProcesses) {
        Write-Host "    - $($process.ProcessName)" -ForegroundColor Yellow
        try {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            Write-Host "    ✓ Stopped $($process.ProcessName)" -ForegroundColor Green
        } catch {
            Write-Host "    ! Failed to stop $($process.ProcessName)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  ✓ No WSL processes running" -ForegroundColor Green
}

# Check WSL distributions
try {
    $distroCheck = wsl --list --all 2>&1
    if ($distroCheck -like "*no installed distributions*") {
        Write-Host "  ✓ No WSL distributions remain" -ForegroundColor Green
    } else {
        Write-Host "  ! Warning: Some distributions may still be registered" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ✓ WSL command not available (good!)" -ForegroundColor Green
}

# Check Windows features
$wslFeatures = Get-WindowsOptionalFeature -Online | Where-Object {
    $_.FeatureName -like "*WSL*" -or $_.FeatureName -like "*VirtualMachine*"
} -ErrorAction SilentlyContinue

foreach ($feature in $wslFeatures) {
    if ($feature.State -eq "Enabled") {
        Write-Host "  ! Warning: $($feature.FeatureName) is still enabled" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ $($feature.FeatureName) is disabled" -ForegroundColor Green
    }
}

# Final summary
Write-Host ""
Write-Host "=== WSL Removal Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Summary of actions performed:" -ForegroundColor White
Write-Host "  • Stopped all WSL services and processes" -ForegroundColor White
Write-Host "  • Unregistered all Linux distributions" -ForegroundColor White
Write-Host "  • Disabled WSL Windows features" -ForegroundColor White
Write-Host "  • Removed all WSL folders and files" -ForegroundColor White
Write-Host "  • Cleaned up registry entries" -ForegroundColor White
Write-Host "  • Removed distribution packages" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: Please restart your computer to complete the removal process." -ForegroundColor Red
Write-Host ""
Write-Host "After restart, WSL will be completely removed from your system." -ForegroundColor Green
Write-Host "If you need WSL again in the future, you'll need to reinstall it completely." -ForegroundColor Yellow
Write-Host ""

# Prompt for restart
$restart = Read-Host "Would you like to restart your computer now? (y/n)"
if ($restart.ToLower() -eq "y" -or $restart.ToLower() -eq "yes") {
    Write-Host "Restarting computer in 10 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Host "Please restart your computer manually to complete the WSL removal." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Script completed. Press any key to exit..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")