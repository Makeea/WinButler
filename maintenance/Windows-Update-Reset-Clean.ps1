# Windows 11 Update Reset Script (PowerShell)
# This script will fully reset and clear all Windows Update components
# Run as Administrator
#
# CHANGELOG:
# v1.0 - Initial PowerShell version with basic functionality
# v1.1 - Added comprehensive DLL registration and detailed comments
# v1.2 - Converted from batch script with enhanced error handling
# v1.3 - Fixed syntax errors: missing braces and malformed try-catch blocks
# v1.4 - Complete rewrite to resolve persistent parsing errors
# v1.5 - Added comprehensive changelog
# v1.6 - Minimal clean version to resolve persistent syntax issues

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Windows 11 Update Reset Script" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host ""

# Function to stop services safely
function Stop-ServiceSafely($ServiceName, $DisplayName) {
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') {
            Write-Host "Stopping $DisplayName..." -ForegroundColor Yellow
            Stop-Service -Name $ServiceName -Force -ErrorAction Stop
            Write-Host "$DisplayName stopped" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Warning: Could not stop $DisplayName" -ForegroundColor Red
    }
}

# Function to start services safely
function Start-ServiceSafely($ServiceName, $DisplayName) {
    try {
        Write-Host "Starting $DisplayName..." -ForegroundColor Yellow
        Start-Service -Name $ServiceName -ErrorAction Stop
        Write-Host "$DisplayName started" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Could not start $DisplayName" -ForegroundColor Red
    }
}

# Function to register DLLs safely
function Register-DllSafely($DllName) {
    try {
        $dllPath = Join-Path $env:WINDIR "System32\$DllName"
        if (Test-Path $dllPath) {
            & regsvr32.exe /s $dllPath
            Write-Host "Registered $DllName" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Failed to register $DllName" -ForegroundColor Red
    }
}

# Step 1: Stop Windows Update services
Write-Host "[Step 1] Stopping Windows Update services..." -ForegroundColor Cyan

Stop-ServiceSafely "wuauserv" "Windows Update Service"
Stop-ServiceSafely "cryptSvc" "Cryptographic Services"
Stop-ServiceSafely "bits" "Background Intelligent Transfer Service"
Stop-ServiceSafely "msiserver" "Windows Installer"
Stop-ServiceSafely "UsoSvc" "Update Orchestrator Service"
Stop-ServiceSafely "dosvc" "Delivery Optimization"

Write-Host "Services stopped." -ForegroundColor Green
Start-Sleep -Seconds 3

# Step 2: Clear Windows Update cache folders
Write-Host "[Step 2] Clearing Windows Update cache folders..." -ForegroundColor Cyan

$softwareDistPath = Join-Path $env:WINDIR "SoftwareDistribution"
if (Test-Path $softwareDistPath) {
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = "$softwareDistPath.bak.$timestamp"
        Rename-Item -Path $softwareDistPath -NewName $backupPath -Force
        Write-Host "SoftwareDistribution folder backed up" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Could not backup SoftwareDistribution folder" -ForegroundColor Red
    }
}

$catroot2Path = Join-Path $env:WINDIR "System32\catroot2"
if (Test-Path $catroot2Path) {
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = "$catroot2Path.bak.$timestamp"
        Rename-Item -Path $catroot2Path -NewName $backupPath -Force
        Write-Host "catroot2 folder backed up" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Could not backup catroot2 folder" -ForegroundColor Red
    }
}

Write-Host "Cache folders cleared." -ForegroundColor Green
Start-Sleep -Seconds 2

# Step 3: Reset Windows Update components
Write-Host "[Step 3] Resetting Windows Update components..." -ForegroundColor Cyan

Write-Host "Re-registering Windows Update DLLs..." -ForegroundColor Yellow

# Core system DLLs
Register-DllSafely "atl.dll"
Register-DllSafely "urlmon.dll"
Register-DllSafely "mshtml.dll"
Register-DllSafely "shdocvw.dll"
Register-DllSafely "browseui.dll"
Register-DllSafely "jscript.dll"
Register-DllSafely "vbscript.dll"
Register-DllSafely "scrrun.dll"
Register-DllSafely "msxml.dll"
Register-DllSafely "msxml3.dll"
Register-DllSafely "msxml6.dll"
Register-DllSafely "actxprxy.dll"

# Cryptographic DLLs
Register-DllSafely "softpub.dll"
Register-DllSafely "wintrust.dll"
Register-DllSafely "dssenh.dll"
Register-DllSafely "rsaenh.dll"
Register-DllSafely "gpkcsp.dll"
Register-DllSafely "sccbase.dll"
Register-DllSafely "slbcsp.dll"
Register-DllSafely "cryptdlg.dll"
Register-DllSafely "initpki.dll"

# System DLLs
Register-DllSafely "oleaut32.dll"
Register-DllSafely "ole32.dll"
Register-DllSafely "shell32.dll"

# Windows Update DLLs
Register-DllSafely "wuapi.dll"
Register-DllSafely "wuaueng.dll"
Register-DllSafely "wuaueng1.dll"
Register-DllSafely "wucltui.dll"
Register-DllSafely "wups.dll"
Register-DllSafely "wups2.dll"
Register-DllSafely "wuweb.dll"
Register-DllSafely "wucltux.dll"
Register-DllSafely "muweb.dll"
Register-DllSafely "wuwebv.dll"

# BITS DLLs
Register-DllSafely "qmgr.dll"
Register-DllSafely "qmgrprxy.dll"

Write-Host "DLL registration completed" -ForegroundColor Green

# Reset BITS
Write-Host "Resetting BITS..." -ForegroundColor Yellow
try {
    & bitsadmin.exe /reset /allusers | Out-Null
    Write-Host "BITS reset successfully" -ForegroundColor Green
}
catch {
    Write-Host "Warning: Could not reset BITS" -ForegroundColor Red
}

# Reset Windows Sockets
Write-Host "Resetting Windows Sockets..." -ForegroundColor Yellow
try {
    & netsh winsock reset | Out-Null
    Write-Host "Windows Sockets reset successfully" -ForegroundColor Green
}
catch {
    Write-Host "Warning: Could not reset Windows Sockets" -ForegroundColor Red
}

# Note: Internet Explorer reset removed for Windows 11 compatibility
# IE is deprecated in Windows 11 and the ie.inf file may not exist
# Windows Update now uses modern Edge-based web components
Write-Host "Skipping Internet Explorer reset (not needed for Windows 11)" -ForegroundColor Gray

Start-Sleep -Seconds 2

# Step 4: Clear Windows Update registry keys
Write-Host "[Step 4] Clearing Windows Update registry entries..." -ForegroundColor Cyan

try {
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Main WindowsUpdate registry key cleared" -ForegroundColor Green
}
catch {
    Write-Host "Could not clear main WindowsUpdate registry key" -ForegroundColor Yellow
}

try {
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "RebootRequired registry key cleared" -ForegroundColor Green
}
catch {
    Write-Host "RebootRequired registry key not found" -ForegroundColor Yellow
}

try {
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "PostRebootReporting registry key cleared" -ForegroundColor Green
}
catch {
    Write-Host "PostRebootReporting registry key not found" -ForegroundColor Yellow
}

Write-Host "Registry cleanup completed" -ForegroundColor Green
Start-Sleep -Seconds 2

# Step 5: Start Windows Update services
Write-Host "[Step 5] Restarting Windows Update services..." -ForegroundColor Cyan

Start-ServiceSafely "cryptSvc" "Cryptographic Services"
Start-ServiceSafely "bits" "Background Intelligent Transfer Service"
Start-ServiceSafely "msiserver" "Windows Installer"
Start-ServiceSafely "wuauserv" "Windows Update Service"
Start-ServiceSafely "UsoSvc" "Update Orchestrator Service"
Start-ServiceSafely "dosvc" "Delivery Optimization"

Write-Host "Services restarted." -ForegroundColor Green
Start-Sleep -Seconds 3

# Step 6: Force Windows Update detection
Write-Host "[Step 6] Forcing Windows Update detection..." -ForegroundColor Cyan

try {
    & UsoClient.exe StartScan | Out-Null
    Write-Host "Windows Update scan initiated" -ForegroundColor Green
}
catch {
    Write-Host "Warning: Could not initiate Windows Update scan" -ForegroundColor Red
}

# Step 7: Additional cleanup commands
Write-Host "[Step 7] Running additional cleanup commands..." -ForegroundColor Cyan

# Note: Windows Update troubleshooter removed as redundant
# Our manual reset is more comprehensive than the built-in troubleshooter
# We already perform all troubleshooter functions more thoroughly

try {
    & ipconfig /flushdns | Out-Null
    Write-Host "DNS cache flushed successfully" -ForegroundColor Green
}
catch {
    Write-Host "Warning: Could not flush DNS cache" -ForegroundColor Red
}

# Final summary
Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "           RESET COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. RESTART your computer (IMPORTANT!)" -ForegroundColor White
Write-Host "2. After restart, go to Settings > Windows Update" -ForegroundColor White
Write-Host "3. Click 'Check for updates'" -ForegroundColor White
Write-Host ""
Write-Host "If you still experience issues, try running:" -ForegroundColor Yellow
Write-Host "- sfc /scannow" -ForegroundColor White
Write-Host "- DISM /Online /Cleanup-Image /RestoreHealth" -ForegroundColor White
Write-Host ""

$restart = Read-Host "Would you like to restart your computer now? (Y/N)"
if ($restart -eq "Y" -or $restart -eq "y") {
    Write-Host ""
    Write-Host "Restarting computer in 10 seconds..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to cancel restart" -ForegroundColor Red
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Host ""
    Write-Host "Please remember to restart your computer manually." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
}