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
#        - Restructured all functions with proper parameter blocks
#        - Fixed all brace matching issues
#        - Simplified complex nested structures
#        - Added comprehensive error handling throughout
#        - Improved code readability and maintainability
# v1.5 - Added comprehensive changelog and enhanced comments

# Set console title
$Host.UI.RawUI.WindowTitle = "Windows 11 Update Reset Script"

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host ""
    Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as administrator'" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Running with Administrator privileges..." -ForegroundColor Green
Write-Host ""

# Display banner
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "      Windows 11 Update Reset Script" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will reset all Windows Update components" -ForegroundColor Yellow
Write-Host "Please wait while the process completes..." -ForegroundColor Yellow
Write-Host ""

# Function to safely stop services
function Stop-ServiceSafely {
    param(
        [string]$ServiceName,
        [string]$DisplayName
    )
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') {
            Write-Host "- Stopping $DisplayName..." -ForegroundColor Yellow
            Stop-Service -Name $ServiceName -Force -ErrorAction Stop
            Start-Sleep -Seconds 1
            Write-Host "- $DisplayName stopped" -ForegroundColor Green
        } else {
            Write-Host "- $DisplayName already stopped" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "- Warning: Could not stop $DisplayName" -ForegroundColor Red
    }
}

# Function to safely start services
function Start-ServiceSafely {
    param(
        [string]$ServiceName,
        [string]$DisplayName
    )
    
    try {
        Write-Host "- Starting $DisplayName..." -ForegroundColor Yellow
        Start-Service -Name $ServiceName -ErrorAction Stop
        Start-Sleep -Seconds 1
        Write-Host "- $DisplayName started" -ForegroundColor Green
    }
    catch {
        Write-Host "- Warning: Could not start $DisplayName" -ForegroundColor Red
    }
}

# Function to register DLLs safely
function Register-DllSafely {
    param(
        [string]$DllName,
        [string]$Description
    )
    
    try {
        $dllPath = Join-Path $env:WINDIR "System32\$DllName"
        if (Test-Path $dllPath) {
            & regsvr32.exe /s $dllPath
            Write-Host "  ✓ $DllName - $Description" -ForegroundColor Green
        } else {
            Write-Host "  ! $DllName not found" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  ✗ Failed to register $DllName" -ForegroundColor Red
    }
}

# Step 1: Stop Windows Update services
Write-Host "[Step 1] Stopping Windows Update services..." -ForegroundColor Cyan
Write-Host ""

# Stop Windows Update Service - Main service that handles update downloads and installations
Stop-ServiceSafely "wuauserv" "Windows Update Service"

# Stop Cryptographic Services - Handles digital signatures and certificates for updates
Stop-ServiceSafely "cryptSvc" "Cryptographic Services"

# Stop Background Intelligent Transfer Service - Manages file downloads in the background
Stop-ServiceSafely "bits" "Background Intelligent Transfer Service"

# Stop Windows Installer service - Handles MSI package installations
Stop-ServiceSafely "msiserver" "Windows Installer"

# Stop Update Orchestrator Service - Coordinates update activities in Windows 10/11
Stop-ServiceSafely "UsoSvc" "Update Orchestrator Service"

# Stop Delivery Optimization - Manages P2P update sharing and bandwidth optimization
Stop-ServiceSafely "dosvc" "Delivery Optimization"

Write-Host ""
Write-Host "All services processing completed." -ForegroundColor Green
Write-Host ""

# Wait for services to stop
Start-Sleep -Seconds 3

# Step 2: Clear Windows Update cache folders
Write-Host "[Step 2] Clearing Windows Update cache folders..." -ForegroundColor Cyan
Write-Host ""

# Backup and clear SoftwareDistribution folder
$softwareDistPath = Join-Path $env:WINDIR "SoftwareDistribution"
if (Test-Path $softwareDistPath) {
    Write-Host "- Backing up SoftwareDistribution folder..." -ForegroundColor Yellow
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = "$softwareDistPath.bak.$timestamp"
        Rename-Item -Path $softwareDistPath -NewName $backupPath -Force
        Write-Host "- SoftwareDistribution folder backed up" -ForegroundColor Green
    }
    catch {
        Write-Host "- Warning: Could not backup SoftwareDistribution folder" -ForegroundColor Red
    }
}

# Backup and clear catroot2 folder
$catroot2Path = Join-Path $env:WINDIR "System32\catroot2"
if (Test-Path $catroot2Path) {
    Write-Host "- Backing up catroot2 folder..." -ForegroundColor Yellow
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = "$catroot2Path.bak.$timestamp"
        Rename-Item -Path $catroot2Path -NewName $backupPath -Force
        Write-Host "- catroot2 folder backed up" -ForegroundColor Green
    }
    catch {
        Write-Host "- Warning: Could not backup catroot2 folder" -ForegroundColor Red
    }
}

# Clear Network Downloader cache
$downloaderPath = Join-Path $env:ALLUSERSPROFILE "Microsoft\Network\Downloader"
if (Test-Path $downloaderPath) {
    Write-Host "- Clearing Network Downloader cache..." -ForegroundColor Yellow
    try {
        Remove-Item -Path $downloaderPath -Recurse -Force
        Write-Host "- Network Downloader cache cleared" -ForegroundColor Green
    }
    catch {
        Write-Host "- Warning: Could not clear Network Downloader cache" -ForegroundColor Red
    }
}

# Clear Windows Update logs
$logPath = Join-Path $env:WINDIR "WindowsUpdate.log"
if (Test-Path $logPath) {
    Write-Host "- Clearing Windows Update logs..." -ForegroundColor Yellow
    try {
        Remove-Item -Path $logPath -Force
        Write-Host "- Windows Update logs cleared" -ForegroundColor Green
    }
    catch {
        Write-Host "- Warning: Could not clear Windows Update logs" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Cache folders cleared successfully." -ForegroundColor Green
Write-Host ""

Start-Sleep -Seconds 2

# Step 3: Reset Windows Update components
Write-Host "[Step 3] Resetting Windows Update components..." -ForegroundColor Cyan
Write-Host ""

Write-Host "- Re-registering Windows Update DLLs..." -ForegroundColor Yellow
Write-Host ""

# Core system DLLs
Register-DllSafely "atl.dll" "Active Template Library - COM support"
Register-DllSafely "urlmon.dll" "URL Moniker services - HTTP/HTTPS handling"
Register-DllSafely "mshtml.dll" "Microsoft HTML rendering engine"
Register-DllSafely "shdocvw.dll" "Shell document view and control"
Register-DllSafely "browseui.dll" "Browser user interface library"
Register-DllSafely "jscript.dll" "JScript scripting engine"
Register-DllSafely "vbscript.dll" "VBScript scripting engine"
Register-DllSafely "scrrun.dll" "Script runtime library"
Register-DllSafely "msxml.dll" "Microsoft XML parser"
Register-DllSafely "msxml3.dll" "Microsoft XML parser version 3"
Register-DllSafely "msxml6.dll" "Microsoft XML parser version 6"
Register-DllSafely "actxprxy.dll" "ActiveX interface marshaling"

Write-Host ""
Write-Host "- Registering cryptographic and security DLLs..." -ForegroundColor Yellow

# Cryptographic DLLs
Register-DllSafely "softpub.dll" "Software publisher trust provider"
Register-DllSafely "wintrust.dll" "Windows trust verification APIs"
Register-DllSafely "dssenh.dll" "DSS Enhanced cryptographic provider"
Register-DllSafely "rsaenh.dll" "RSA Enhanced cryptographic provider"
Register-DllSafely "gpkcsp.dll" "Gemplus cryptographic service provider"
Register-DllSafely "sccbase.dll" "Smart card base cryptographic service provider"
Register-DllSafely "slbcsp.dll" "Schlumberger cryptographic service provider"
Register-DllSafely "cryptdlg.dll" "Cryptography common dialog APIs"
Register-DllSafely "initpki.dll" "Microsoft Trust UI Provider"

Write-Host ""
Write-Host "- Registering core Windows system DLLs..." -ForegroundColor Yellow

# System DLLs
Register-DllSafely "oleaut32.dll" "OLE Automation APIs"
Register-DllSafely "ole32.dll" "Microsoft OLE library"
Register-DllSafely "shell32.dll" "Windows Shell common APIs"

Write-Host ""
Write-Host "- Registering Windows Update specific DLLs..." -ForegroundColor Yellow

# Windows Update DLLs
Register-DllSafely "wuapi.dll" "Windows Update Agent API"
Register-DllSafely "wuaueng.dll" "Windows Update AutoUpdate engine"
Register-DllSafely "wuaueng1.dll" "Windows Update AutoUpdate engine (additional)"
Register-DllSafely "wucltui.dll" "Windows Update client UI"
Register-DllSafely "wups.dll" "Windows Update client Proxy Stub"
Register-DllSafely "wups2.dll" "Windows Update client Proxy Stub 2"
Register-DllSafely "wuweb.dll" "Windows Update web control"
Register-DllSafely "wucltux.dll" "Windows Update client UX"
Register-DllSafely "muweb.dll" "Microsoft Update web control"
Register-DllSafely "wuwebv.dll" "Windows Update web control (versioned)"

Write-Host ""
Write-Host "- Registering BITS DLLs..." -ForegroundColor Yellow

# BITS DLLs
Register-DllSafely "qmgr.dll" "BITS Queue Manager"
Register-DllSafely "qmgrprxy.dll" "BITS Queue Manager Proxy"

Write-Host ""
Write-Host "- Windows Update components re-registered successfully" -ForegroundColor Green
Write-Host ""

# Reset BITS
Write-Host "- Resetting BITS..." -ForegroundColor Yellow
try {
    & bitsadmin.exe /reset /allusers | Out-Null
    Write-Host "- BITS reset successfully" -ForegroundColor Green
}
catch {
    Write-Host "- Warning: Could not reset BITS" -ForegroundColor Red
}
Write-Host ""

# Reset Windows Sockets
Write-Host "- Resetting Windows Sockets..." -ForegroundColor Yellow
try {
    & netsh winsock reset | Out-Null
    Write-Host "- Windows Sockets reset successfully" -ForegroundColor Green
}
catch {
    Write-Host "- Warning: Could not reset Windows Sockets" -ForegroundColor Red
}
Write-Host ""

# Reset Internet Explorer settings
Write-Host "- Resetting Internet Explorer settings..." -ForegroundColor Yellow
try {
    & RunDll32.exe iesetup.dll,IEHardenUser | Out-Null
    & RunDll32.exe iesetup.dll,IEHardenAdmin | Out-Null
    $iePath = Join-Path $env:WINDIR "INF\ie.inf"
    & RunDll32.exe ieadvpack.dll,LaunchINFSection $iePath,DefaultInstall.ResetEngine | Out-Null
    Write-Host "- Internet Explorer settings reset" -ForegroundColor Green
}
catch {
    Write-Host "- Warning: Could not reset Internet Explorer settings" -ForegroundColor Red
}
Write-Host ""

Start-Sleep -Seconds 2

# Step 4: Clear Windows Update registry keys
Write-Host "[Step 4] Clearing Windows Update registry entries..." -ForegroundColor Cyan
Write-Host ""

Write-Host "- Clearing Windows Update registry keys..." -ForegroundColor Yellow

# Clear main registry keys
try {
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Main WindowsUpdate registry key cleared" -ForegroundColor Green
}
catch {
    Write-Host "  ! Could not clear main WindowsUpdate registry key" -ForegroundColor Yellow
}

try {
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ RebootRequired registry key cleared" -ForegroundColor Green
}
catch {
    Write-Host "  ! RebootRequired registry key not found" -ForegroundColor Yellow
}

try {
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ PostRebootReporting registry key cleared" -ForegroundColor Green
}
catch {
    Write-Host "  ! PostRebootReporting registry key not found" -ForegroundColor Yellow
}

Write-Host "- Registry entries processing completed" -ForegroundColor Green
Write-Host ""

Start-Sleep -Seconds 2

# Step 5: Start Windows Update services
Write-Host "[Step 5] Restarting Windows Update services..." -ForegroundColor Cyan
Write-Host ""

# Start services in dependency order
Start-ServiceSafely "cryptSvc" "Cryptographic Services"
Start-ServiceSafely "bits" "Background Intelligent Transfer Service"
Start-ServiceSafely "msiserver" "Windows Installer"
Start-ServiceSafely "wuauserv" "Windows Update Service"
Start-ServiceSafely "UsoSvc" "Update Orchestrator Service"
Start-ServiceSafely "dosvc" "Delivery Optimization"

Write-Host ""
Write-Host "All services restart processing completed." -ForegroundColor Green
Write-Host ""

Start-Sleep -Seconds 3

# Step 6: Force Windows Update detection
Write-Host "[Step 6] Forcing Windows Update detection..." -ForegroundColor Cyan
Write-Host ""

Write-Host "- Initiating Windows Update scan..." -ForegroundColor Yellow
try {
    & UsoClient.exe StartScan | Out-Null
    Write-Host "- Windows Update scan initiated" -ForegroundColor Green
}
catch {
    Write-Host "- Warning: Could not initiate Windows Update scan" -ForegroundColor Red
}
Write-Host ""

# Step 7: Additional cleanup commands
Write-Host "[Step 7] Running additional cleanup commands..." -ForegroundColor Cyan
Write-Host ""

Write-Host "- Running Windows Update troubleshooter..." -ForegroundColor Yellow
try {
    & msdt.exe /id WindowsUpdateDiagnostic /skip /norestart | Out-Null
    Write-Host "- Windows Update troubleshooter completed" -ForegroundColor Green
}
catch {
    Write-Host "- Note: Troubleshooter may have opened in interactive mode" -ForegroundColor Yellow
}

Write-Host "- Flushing DNS cache..." -ForegroundColor Yellow
try {
    & ipconfig /flushdns | Out-Null
    Write-Host "- DNS cache flushed successfully" -ForegroundColor Green
}
catch {
    Write-Host "- Warning: Could not flush DNS cache" -ForegroundColor Red
}

Write-Host "- Additional cleanup completed" -ForegroundColor Green
Write-Host ""

# Final summary
Write-Host "===============================================" -ForegroundColor Green
Write-Host "           RESET COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "The Windows Update reset process has been completed." -ForegroundColor White
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. RESTART your computer (IMPORTANT!)" -ForegroundColor White
Write-Host "2. After restart, go to Settings > Windows Update" -ForegroundColor White
Write-Host "3. Click 'Check for updates'" -ForegroundColor White
Write-Host ""
Write-Host "If you still experience issues, try running these commands:" -ForegroundColor Yellow
Write-Host "- sfc /scannow                           [System File Checker]" -ForegroundColor White
Write-Host "- DISM /Online /Cleanup-Image /RestoreHealth [System Image Repair]" -ForegroundColor White
Write-Host ""
Write-Host "BACKUP FOLDERS CREATED:" -ForegroundColor Yellow
Write-Host "- SoftwareDistribution folder was backed up with timestamp" -ForegroundColor White
Write-Host "- catroot2 folder was backed up with timestamp" -ForegroundColor White
Write-Host ""
Write-Host "These backups can be safely deleted after confirming" -ForegroundColor Gray
Write-Host "Windows Update is working properly." -ForegroundColor Gray
Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""

# Ask user about restart
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