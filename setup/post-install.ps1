#=============================================================================
# Windows Post-Installation Setup Script
# Author: Claire R
# Version:  2.5.0
# Last Updated: June 2025
# Purpose: Automated Windows system setup after fresh installation
#
# EXECUTION INSTRUCTIONS:
# 1. Right-click PowerShell and select "Run as Administrator"
# 2. Execute: powershell -ExecutionPolicy Bypass -File .\post-install-setup.ps1
#
# If you encounter execution policy issues:
# - Run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# - Or use the bypass method shown above
#
# CHANGELOG:
# v2.5.0 (June 2025) - Added SSH permissions fix feature
# v2.4.0 (June 2025) - Corrected script structure to resolve ParserError.
# v2.3.0 (June 2025) - Added driver backup and restore functionality.
# v2.2.0 (June 2025) - Added undo/revert options for many settings. Added Rust installer.
# v2.1.0 (June 2025) - Expanded menu with individual app installations
# v2.0.0 (June 2025) - Complete rewrite with modular architecture
# v1.5.0 (May 2025) - Added WSL2 and Ubuntu installation
# v1.2.0 (April 2025) - Added Winget detection and fallback methods
# v1.0.0 (March 2025) - Initial release
#=============================================================================

# Check if running as Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Global variables
$script:LogPath = "$env:TEMP\PostInstallSetup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:TempPath = "$env:TEMP\PostInstallTemp"
$script:WingetInstalled = $false

# Create temp directory if it doesn't exist
if (!(Test-Path $script:TempPath)) {
    New-Item -ItemType Directory -Path $script:TempPath -Force | Out-Null
}

#=============================================================================
# LOGGING FUNCTIONS
#=============================================================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    Add-Content -Path $script:LogPath -Value $logEntry
    
    # Also display to console with color coding
    switch ($Level) {
        "ERROR"   { Write-Host $Message -ForegroundColor Red }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        "INFO"    { Write-Host $Message -ForegroundColor Cyan }
        default   { Write-Host $Message }
    }
}

#=============================================================================
# UTILITY FUNCTIONS
#=============================================================================

function Test-CommandExists {
    param([string]$Command)
    
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Test-WingetInstalled {
    # Check if winget is available
    if (Test-CommandExists "winget") {
        $script:WingetInstalled = $true
        return $true
    }
    
    Write-Log "Winget not found. Attempting to install App Installer..." "WARNING"
    
    try {
        # Download and install App Installer (includes winget)
        $appInstallerUrl = "https://aka.ms/getwinget"
        $installerPath = "$script:TempPath\AppInstaller.msixbundle"
        
        Write-Log "Downloading App Installer..."
        Invoke-WebRequest -Uri $appInstallerUrl -OutFile $installerPath -UseBasicParsing
        
        Write-Log "Installing App Installer..."
        Add-AppxPackage -Path $installerPath
        @@
 function Setup-GitOnly {
     Write-Log "`n=== Setting up Git Configuration Only ===" "INFO"
     Setup-GitConfiguration
 }
+
+    Write-Log "`n=== Checking and correcting SSH directory permissions ===" "INFO"
+    $sshDir = "$env:USERPROFILE\.ssh"
+    if (!(Test-Path $sshDir)) {
+        Write-Log "No .ssh directory found at $sshDir" "WARNING"
+        return
+    }
+    if ($IsWindows) {
+        icacls $sshDir /inheritance:r /grant:r "$env:USERNAME:(OI)(CI)F" | Out-Null
+    } else {
+        chmod 700 $sshDir
+    }
+    Get-ChildItem -Path $sshDir | ForEach-Object {
+        $file = $_.FullName; $name = $_.Name
+        if ($name -match '^id_.*' -and -not ($name -like '*.pub')) {
+            if ($IsWindows) { icacls $file /inheritance:r /grant:r "$env:USERNAME:F" | Out-Null } else { chmod 600 $file }
+            Write-Log "Set 600 for $name" "INFO"
+        } elseif ($name -like '*.pub') {
+            if ($IsWindows) { icacls $file /inheritance:r /grant:r "$env:USERNAME:R" | Out-Null } else { chmod 644 $file }
+            Write-Log "Set 644 for $name" "INFO"
+        } elseif ($name -in 'authorized_keys','known_hosts') {
+            if ($IsWindows) { icacls $file /inheritance:r /grant:r "$env:USERNAME:F" | Out-Null } else { chmod 600 $file }
+            Write-Log "Set 600 for $name" "INFO"
+        } else {
+            if ($IsWindows) { icacls $file /inheritance:r /grant:r "$env:USERNAME:F" | Out-Null } else { chmod 600 $file }
+            Write-Log "Set 600 for $name" "INFO"
+        }
+    }
+    Write-Log "SSH permissions corrected." "SUCCESS"
+}
@@ 
function Do-MyNewFeature {
    [CmdletBinding()]
    param()
    Write-Log "Starting SSH permissions fix" "INFO"
    try {
        $sshDir = Join-Path $Env:USERPROFILE '.ssh'
        if (-Not (Test-Path $sshDir)) {
            Write-Log "SSH directory not found at $sshDir" "WARNING"
            Write-Host "No SSH directory found for current user. Skipping." -ForegroundColor Yellow
            return
        }
        Write-Log "Setting ACLs on SSH directory: $sshDir" "INFO"
        icacls $sshDir /inheritance:r /grant:r "$Env:USERNAME:(OI)(CI)F" /grant:r "SYSTEM:F" | Out-Null
        Write-Log "Setting ACLs on files within SSH directory" "INFO"
        icacls (Join-Path $sshDir '*') /inheritance:r /grant:r "$Env:USERNAME:F" /grant:r "SYSTEM:F" | Out-Null
        Write-Log "SSH permissions fixed successfully" "SUCCESS"
        Write-Host "SSH directory permissions updated." -ForegroundColor Green
    } catch {
        Write-Log "Error fixing SSH permissions: $_" "ERROR"
        Write-Host "Failed to fix SSH permissions: $_" -ForegroundColor Red
    }
}
function Show-Menu {
-       Write-Host " 101. Fix SSH Directory Permissions" -ForegroundColor White
    Write-Host " 100. Exit" -ForegroundColor Red
+       Write-Host " 101. Fix SSH Directory Permissions" -ForegroundColor White
    Write-Host " 100. Exit" -ForegroundColor Red
+   Write-Host " 101. Check and correct SSH directory permissions" -ForegroundColor White
@@ function Start-MainMenu {
             "999" { 
@@
-            # EXIT (100)
+            # EXIT (100)
             "100" {
                 Write-Log "Exiting script..." "INFO"
@@
        
        # Verify installation
        if (Test-CommandExists "winget") {
            $script:WingetInstalled = $true
            Write-Log "Winget installed successfully!" "SUCCESS"
            return $true
        }
    }
    catch {
        Write-Log "Failed to install winget: $_" "ERROR"
    }
    
    return $false
}

function Show-Progress {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete
    )
    
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
}

function Test-FeatureInstalled {
    param([string]$FeatureName)
    
    $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction SilentlyContinue
    return ($feature -and $feature.State -eq "Enabled")
}

#=============================================================================
# SYSTEM FEATURE FUNCTIONS
#=============================================================================

function Enable-WindowsSandbox {
    Write-Log "`n=== Enabling Windows Sandbox ===" "INFO"
    
    if (Test-FeatureInstalled "Containers-DisposableClientVM") {
        Write-Log "Windows Sandbox is already enabled!" "SUCCESS"
        return
    }
    
    try {
        Write-Log "Enabling Windows Sandbox feature..."
        Enable-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -All -NoRestart
        Write-Log "Windows Sandbox enabled successfully! A restart is required." "SUCCESS"
    }
    catch {
        Write-Log "Failed to enable Windows Sandbox: $_" "ERROR"
    }
}

function Enable-HyperV {
    Write-Log "`n=== Enabling Hyper-V ===" "INFO"
    
    if (Test-FeatureInstalled "Microsoft-Hyper-V-All") {
        Write-Log "Hyper-V is already enabled!" "SUCCESS"
        return
    }
    
    try {
        Write-Log "Enabling Hyper-V features..."
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All -NoRestart
        Write-Log "Hyper-V enabled successfully! A restart is required." "SUCCESS"
    }
    catch {
        Write-Log "Failed to enable Hyper-V: $_" "ERROR"
    }
}

function Install-WSL2 {
    Write-Log "`n=== Installing WSL2 with Ubuntu ===" "INFO"
    
    try {
        # Check if WSL is already installed
        $wslStatus = wsl --status 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "WSL is already installed!" "SUCCESS"
            
            # Check if Ubuntu is installed
            $distros = wsl --list --quiet
            if ($distros -match "Ubuntu") {
                Write-Log "Ubuntu is already installed!" "SUCCESS"
                return
            }
        }
        else {
            Write-Log "Installing WSL2..."
            wsl --install --no-launch
            
            # Wait for installation to complete
            Start-Sleep -Seconds 5
        }
        
        # Install Ubuntu
        Write-Log "Installing Ubuntu distribution..."
        wsl --install -d Ubuntu --no-launch
        
        Write-Log "WSL2 with Ubuntu installed successfully!" "SUCCESS"
        Write-Log "You'll need to restart and then launch Ubuntu to complete setup." "INFO"
    }
    catch {
        Write-Log "Failed to install WSL2: $_" "ERROR"
    }
}

#=============================================================================
# BROWSER INSTALLATION FUNCTIONS
#=============================================================================

function Install-ChromeEnterprise {
    Write-Log "`n=== Installing Chrome Enterprise ===" "INFO"
    
    # Check if Chrome is already installed
    $chromePath = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
    $chromePath86 = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
    
    if ((Test-Path $chromePath) -or (Test-Path $chromePath86)) {
        Write-Log "Google Chrome is already installed!" "SUCCESS"
        return
    }
    
    try {
        # Construct the Chrome Enterprise URL properly to handle the ampersand
        $baseUrl = "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi"
        $chromeUrl = $baseUrl + "?standalone=1"
        $chromeMsi = "$script:TempPath\ChromeEnterprise.msi"
        
        Write-Log "Downloading Chrome Enterprise MSI..."
        Show-Progress -Activity "Installing Chrome Enterprise" -Status "Downloading..." -PercentComplete 25
        
        Invoke-WebRequest -Uri $chromeUrl -OutFile $chromeMsi -UseBasicParsing
        
        Write-Log "Installing Chrome Enterprise..."
        Show-Progress -Activity "Installing Chrome Enterprise" -Status "Installing..." -PercentComplete 75
        
        Start-Process msiexec.exe -ArgumentList "/i", "`"$chromeMsi`"", "/quiet", "/norestart" -Wait
        
        Write-Log "Chrome Enterprise installed successfully!" "SUCCESS"
        Show-Progress -Activity "Installing Chrome Enterprise" -Status "Complete" -PercentComplete 100
        Start-Sleep -Seconds 1
    }
    catch {
        Write-Log "Failed to install Chrome Enterprise: $_" "ERROR"
    }
    finally {
        Write-Progress -Activity "Installing Chrome Enterprise" -Completed
    }
}

function Install-Firefox {
    Write-Log "`n=== Installing Mozilla Firefox ===" "INFO"
    
    # First try with winget if available
    if ($script:WingetInstalled) {
        try {
            $firefoxCheck = winget list --id Mozilla.Firefox --exact 2>$null
            if ($LASTEXITCODE -eq 0 -and $firefoxCheck -match "Mozilla.Firefox") {
                Write-Log "Firefox is already installed! Checking for updates..."
                winget upgrade --id Mozilla.Firefox --exact --silent --accept-package-agreements --accept-source-agreements
                Write-Log "Firefox is up to date!" "SUCCESS"
                return
            }
            
            Write-Log "Installing Firefox via winget..."
            winget install --id Mozilla.Firefox --exact --silent --accept-package-agreements --accept-source-agreements
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Firefox installed successfully via winget!" "SUCCESS"
                return
            }
        }
        catch {
            Write-Log "Winget installation failed, falling back to direct download..." "WARNING"
        }
    }
    
    # Fallback to direct download
    try {
        $firefoxUrl = "https://download.mozilla.org/?product=firefox-latest-ssl" + "&" + "os=win64" + "&" + "lang=en-US"
        $firefoxInstaller = "$script:TempPath\FirefoxSetup.exe"
        
        Write-Log "Downloading Firefox installer..."
        Invoke-WebRequest -Uri $firefoxUrl -OutFile $firefoxInstaller -UseBasicParsing
        
        Write-Log "Installing Firefox..."
        Start-Process $firefoxInstaller -ArgumentList "/S" -Wait
        
        Write-Log "Firefox installed successfully!" "SUCCESS"
    }
    catch {
        Write-Log "Failed to install Firefox: $_" "ERROR"
    }
}

#=============================================================================
# INDIVIDUAL APPLICATION INSTALLATION FUNCTIONS
#=============================================================================

function Install-SingleApp {
    param(
        [string]$AppName,
        [string]$WingetID,
        [string]$FallbackUrl = "",
        [string]$InstallerArgs = "/S"
    )
    
    Write-Log "`n=== Installing $AppName ===" "INFO"
    
    # First try with winget if available
    if ($script:WingetInstalled) {
        try {
            # Check if already installed
            $appCheck = winget list --id $WingetID --exact 2>$null
            if ($LASTEXITCODE -eq 0 -and $appCheck -match $WingetID) {
                Write-Log "$AppName is already installed! Checking for updates..."
                winget upgrade --id $WingetID --exact --silent --accept-package-agreements --accept-source-agreements
                Write-Log "$AppName is up to date!" "SUCCESS"
                return
            }
            
            # Install the app
            Write-Log "Installing $AppName via winget..."
            winget install --id $WingetID --exact --silent --accept-package-agreements --accept-source-agreements
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "$AppName installed successfully!" "SUCCESS"
                return
            }
        }
        catch {
            Write-Log "Winget installation failed for $AppName" "WARNING"
        }
    }
    
    # Fallback to direct download if URL provided
    if ($FallbackUrl -ne "") {
        try {
            $extension = [System.IO.Path]::GetExtension($FallbackUrl)
            if ($extension -eq "") { $extension = ".exe" }
            $installerPath = "$script:TempPath\$AppName$extension"
            
            Write-Log "Downloading $AppName from official website..."
            Invoke-WebRequest -Uri $FallbackUrl -OutFile $installerPath -UseBasicParsing
            
            Write-Log "Installing $AppName..."
            if ($extension -eq ".msi") {
                Start-Process msiexec.exe -ArgumentList "/i", "`"$installerPath`"", "/quiet", "/norestart" -Wait
            }
            else {
                Start-Process $installerPath -ArgumentList $InstallerArgs -Wait
            }
            
            Write-Log "$AppName installed successfully!" "SUCCESS"
        }
        catch {
            Write-Log "Failed to install $AppName`: $($_)" "ERROR"
        }
    }
    else {
        Write-Log "No fallback URL available for $AppName. Winget is required." "ERROR"
    }
}

# Individual app installation functions
function Install-7Zip { Install-SingleApp -AppName "7-Zip" -WingetID "7zip.7zip" }
function Install-BCUninstaller { Install-SingleApp -AppName "BCUninstaller" -WingetID "Klocman.BulkCrapUninstaller" }
function Install-BulkRenameUtility { Install-SingleApp -AppName "Bulk Rename Utility" -WingetID "TGRMNSoftware.BulkRenameUtility" }
function Install-CPUZ { Install-SingleApp -AppName "CPU-Z" -WingetID "CPUID.CPU-Z" }
function Install-FileConverter { Install-SingleApp -AppName "File Converter" -WingetID "AdrienAllard.FileConverter" }
function Install-Git { Install-SingleApp -AppName "Git" -WingetID "Git.Git" }
function Install-GitExtensions { Install-SingleApp -AppName "Git Extensions" -WingetID "GitExtensionsTeam.GitExtensions" }
function Install-GoogleChrome { Install-SingleApp -AppName "Google Chrome" -WingetID "Google.Chrome" }
function Install-Krita { Install-SingleApp -AppName "Krita" -WingetID "KDE.Krita" }
function Install-LogiOptionsPlus { Install-SingleApp -AppName "Logi Options+" -WingetID "Logitech.OptionsPlus" }
function Install-MozillaFirefox { Install-SingleApp -AppName "Mozilla Firefox" -WingetID "Mozilla.Firefox" }
function Install-NotepadPlusPlus { Install-SingleApp -AppName "Notepad++" -WingetID "Notepad++.Notepad++" }
function Install-OpenSCAD { Install-SingleApp -AppName "OpenSCAD" -WingetID "OpenSCAD.OpenSCAD" }
function Install-VirtualBox { Install-SingleApp -AppName "VirtualBox" -WingetID "Oracle.VirtualBox" }
function Install-PeaZip { Install-SingleApp -AppName "PeaZip" -WingetID "Giorgiotani.Peazip" }
function Install-PrusaSlicer { Install-SingleApp -AppName "PrusaSlicer" -WingetID "Prusa3D.PrusaSlicer" }
function Install-Tabby { Install-SingleApp -AppName "Tabby" -WingetID "Eugeny.Tabby" }
function Install-Rust { Install-SingleApp -AppName "Rust" -WingetID "Rustlang.Rustup" }

#=============================================================================
# SECURITY & PRIVACY FUNCTIONS
#=============================================================================

function Disable-WindowsTelemetry {
    Write-Log "`n=== Disabling Windows Telemetry & Data Collection ===" "INFO"
    
    try {
        # Check current telemetry level
        $currentLevel = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
        if ($currentLevel) {
            Write-Log "BEFORE: Telemetry level = $($currentLevel.AllowTelemetry)" "INFO"
        } else {
            Write-Log "BEFORE: Telemetry policy not set (default enabled)" "INFO"
        }
        
        Write-Log "Configuring telemetry and privacy settings..."
        
        # Disable telemetry
        $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-ItemProperty -Path $regPath -Name "AllowTelemetry" -Value 0 -Type DWord -Force
        
        # Disable activity feed
        $sysPolPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        if (!(Test-Path $sysPolPath)) { New-Item -Path $sysPolPath -Force | Out-Null }
        Set-ItemProperty -Path $sysPolPath -Name "EnableActivityFeed" -Value 0 -Type DWord -Force
        
        # Disable advertising ID
        $adInfoPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"
        if (!(Test-Path $adInfoPath)) { New-Item -Path $adInfoPath -Force | Out-Null }
        Set-ItemProperty -Path $adInfoPath -Name "DisabledByGroupPolicy" -Value 1 -Type DWord -Force
        
        # Disable location tracking
        $locationPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
        if (!(Test-Path $locationPath)) { New-Item -Path $locationPath -Force | Out-Null }
        Set-ItemProperty -Path $locationPath -Name "DisableLocation" -Value 1 -Type DWord -Force
        
        Write-Log "AFTER: Telemetry disabled (level 0)" "SUCCESS"
        Write-Log "Windows telemetry and data collection disabled successfully!" "SUCCESS"
        Write-Log "A restart is recommended for all changes to take effect." "INFO"
        
    }
    catch {
        Write-Log "Failed to disable telemetry: $($_)" "ERROR"
    }
}

function Restore-DefaultTelemetry {
    Write-Log "`n=== Restoring Default Telemetry & Data Collection ===" "INFO"
    
    try {
        Write-Log "Restoring default telemetry and privacy settings..."
        
        # The cleanest way to restore defaults is to remove the policies, letting the OS manage them.
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Force -ErrorAction SilentlyContinue
        Write-Log "Restored default telemetry level" "SUCCESS"
        
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Force -ErrorAction SilentlyContinue
        Write-Log "Restored default activity feed setting" "SUCCESS"

        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Force -ErrorAction SilentlyContinue
        Write-Log "Restored default advertising ID setting" "SUCCESS"
        
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Force -ErrorAction SilentlyContinue
        Write-Log "Restored default location tracking setting" "SUCCESS"
        
        Write-Log "Default telemetry and data collection settings restored!" "SUCCESS"
        Write-Log "A restart is recommended for all changes to take effect." "INFO"
    }
    catch {
        Write-Log "Failed to restore telemetry settings: $($_)" "ERROR"
    }
}

function Remove-WindowsBloatware {
    Write-Log "`n=== Removing Windows Bloatware ===" "INFO"
    
    try {
        # List of bloatware to remove
        $bloatwareApps = @(
            "Microsoft.3DBuilder",
            "Microsoft.BingNews",
            "Microsoft.BingWeather",
            "Microsoft.GetHelp",
            "Microsoft.Getstarted",
            "Microsoft.Messaging",
            "Microsoft.Microsoft3DViewer",
            "Microsoft.MicrosoftSolitaireCollection",
            "Microsoft.MixedReality.Portal",
            "Microsoft.OneConnect",
            "Microsoft.People",
            "Microsoft.Print3D",
            "Microsoft.SkypeApp",
            "Microsoft.Wallet",
            "Microsoft.WindowsCamera",
            "Microsoft.WindowsFeedbackHub",
            "Microsoft.WindowsMaps",
            "Microsoft.YourPhone",
            "Microsoft.ZuneMusic",
            "Microsoft.ZuneVideo"
        )
        
        Write-Log "BEFORE: Scanning for bloatware apps..." "INFO"
        $installedBloat = @()
        foreach ($app in $bloatwareApps) {
            $installed = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
            if ($installed) {
                $installedBloat += $app
            }
        }
        
        if ($installedBloat.Count -eq 0) {
            Write-Log "No bloatware apps found to remove" "SUCCESS"
            return
        }
        
        Write-Log "Found $($installedBloat.Count) bloatware apps to remove" "INFO"
        
        $removedCount = 0
        foreach ($app in $installedBloat) {
            try {
                Write-Log "Removing $app..." "INFO"
                Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
                Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                $removedCount++
            }
            catch {
                Write-Log "Failed to remove $app" "WARNING"
            }
        }
        
        Write-Log "AFTER: Removed $removedCount out of $($installedBloat.Count) bloatware apps" "SUCCESS"
        Write-Log "Windows bloatware removal completed!" "SUCCESS"
        
    }
    catch {
        Write-Log "Failed to remove bloatware: $($_)" "ERROR"
    }
}

function Disable-Cortana {
    Write-Log "`n=== Disabling Cortana ===" "INFO"
    
    try {
        # Check current state
        $currentValue = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -ErrorAction SilentlyContinue
        if ($currentValue -and $currentValue.AllowCortana -eq 0) {
            Write-Log "BEFORE: Cortana is already disabled" "INFO"
        } else {
            Write-Log "BEFORE: Cortana is enabled" "INFO"
        }
        
        Write-Log "Disabling Cortana..."
        
        # Create registry path if it doesn't exist
        $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        
        # Disable Cortana
        Set-ItemProperty -Path $regPath -Name "AllowCortana" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $regPath -Name "DisableWebSearch" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $regPath -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord -Force
        
        Write-Log "AFTER: Cortana disabled successfully" "SUCCESS"
        Write-Log "A restart is recommended for changes to take effect." "INFO"
        
    }
    catch {
        Write-Log "Failed to disable Cortana: $($_)" "ERROR"
    }
}

function Enable-Cortana {
    Write-Log "`n=== Enabling Cortana ===" "INFO"
    
    try {
        Write-Log "Enabling Cortana by removing group policies..."
        
        $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        if (Test-Path $regPath) {
            Remove-ItemProperty -Path $regPath -Name "AllowCortana" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $regPath -Name "DisableWebSearch" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $regPath -Name "ConnectedSearchUseWeb" -Force -ErrorAction SilentlyContinue
            Write-Log "AFTER: Cortana policies removed. Cortana is now enabled." "SUCCESS"
            Write-Log "A restart is recommended for changes to take effect." "INFO"
        }
        else {
            Write-Log "No Cortana policies found. Cortana should already be enabled." "INFO"
        }
    }
    catch {
        Write-Log "Failed to enable Cortana: $($_)" "ERROR"
    }
}


function Configure-DefenderExclusions {
    Write-Log "`n=== Configuring Windows Defender Exclusions ===" "INFO"
    
    try {
        # Common development folders to exclude
        $devFolders = @(
            "$env:USERPROFILE\Documents\GitHub",
            "$env:USERPROFILE\Documents\Projects",
            "$env:USERPROFILE\Source",
            "C:\Dev",
            "C:\Projects",
            "$env:USERPROFILE\AppData\Local\Temp"
        )
        
        Write-Log "Adding development folders to Windows Defender exclusions..." "INFO"
        
        $addedCount = 0
        foreach ($folder in $devFolders) {
            try {
                if (Test-Path $folder) {
                    Add-MpPreference -ExclusionPath $folder -ErrorAction SilentlyContinue
                    Write-Log "Added exclusion: $folder" "SUCCESS"
                    $addedCount++
                } else {
                    Write-Log "Folder not found, skipping: $folder" "INFO"
                }
            }
            catch {
                Write-Log "Failed to add exclusion for: $folder" "WARNING"
            }
        }
        
        # Add common development file extensions
        $devExtensions = @(".tmp", ".log", ".cache", ".node_modules")
        foreach ($ext in $devExtensions) {
            try {
                Add-MpPreference -ExclusionExtension $ext -ErrorAction SilentlyContinue
                Write-Log "Added extension exclusion: $ext" "SUCCESS"
            }
            catch {
                Write-Log "Failed to add extension exclusion: $ext" "WARNING"
            }
        }
        
        Write-Log "Windows Defender exclusions configured successfully!" "SUCCESS"
        Write-Log "Added $addedCount folder exclusions" "INFO"
        
    }
    catch {
        Write-Log "Failed to configure Defender exclusions: $($_)" "ERROR"
    }
}

function Remove-DefenderExclusions {
    Write-Log "`n=== Removing Windows Defender Exclusions ===" "INFO"
    
    try {
        # List of previously added folders and extensions
        $devFolders = @(
            "$env:USERPROFILE\Documents\GitHub",
            "$env:USERPROFILE\Documents\Projects",
            "$env:USERPROFILE\Source",
            "C:\Dev",
            "C:\Projects",
            "$env:USERPROFILE\AppData\Local\Temp"
        )
        $devExtensions = @(".tmp", ".log", ".cache", ".node_modules")
        
        Write-Log "Removing development-related Defender exclusions..." "INFO"
        
        foreach ($folder in $devFolders) {
            try {
                Remove-MpPreference -ExclusionPath $folder -ErrorAction SilentlyContinue
                Write-Log "Removed exclusion: $folder" "SUCCESS"
            }
            catch {
                Write-Log "Failed to remove exclusion for: $folder" "WARNING"
            }
        }
        
        foreach ($ext in $devExtensions) {
            try {
                Remove-MpPreference -ExclusionExtension $ext -ErrorAction SilentlyContinue
                Write-Log "Removed extension exclusion: $ext" "SUCCESS"
            }
            catch {
                Write-Log "Failed to remove extension exclusion: $ext" "WARNING"
            }
        }
        
        Write-Log "Windows Defender exclusions removed successfully!" "SUCCESS"
    }
    catch {
        Write-Log "Failed to remove Defender exclusions: $($_)" "ERROR"
    }
}


function Disable-WindowsUpdateAutoRestart {
    Write-Log "`n=== Disabling Windows Update Auto-Restart ===" "INFO"
    
    try {
        # Check current state
        $currentValue = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -ErrorAction SilentlyContinue
        if ($currentValue -and $currentValue.NoAutoRebootWithLoggedOnUsers -eq 1) {
            Write-Log "BEFORE: Auto-restart is already disabled" "INFO"
        } else {
            Write-Log "BEFORE: Auto-restart is enabled" "INFO"
        }
        
        Write-Log "Disabling Windows Update auto-restart..."
        
        # Create registry path if it doesn't exist
        $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        
        # Disable auto-restart
        Set-ItemProperty -Path $regPath -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $regPath -Name "AUOptions" -Value 3 -Type DWord -Force  # Download and notify for install
        
        Write-Log "AFTER: Windows Update auto-restart disabled" "SUCCESS"
        Write-Log "Windows will no longer automatically restart after updates!" "SUCCESS"
        
    }
    catch {
        Write-Log "Failed to disable Windows Update auto-restart: $($_)" "ERROR"
    }
}

function Enable-WindowsUpdateAutoRestart {
    Write-Log "`n=== Enabling Windows Update Auto-Restart ===" "INFO"
    
    try {
        Write-Log "Enabling Windows Update auto-restart by removing group policies..."
        
        $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (Test-Path $regPath) {
            Remove-ItemProperty -Path $regPath -Name "NoAutoRebootWithLoggedOnUsers" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $regPath -Name "AUOptions" -Force -ErrorAction SilentlyContinue
            Write-Log "AFTER: Windows Update auto-restart policies removed." "SUCCESS"
        }
        else {
            Write-Log "No auto-restart policies found. Default behavior is already active." "INFO"
        }
        
        Write-Log "Windows Update auto-restart settings restored to default!" "SUCCESS"
    }
    catch {
        Write-Log "Failed to enable Windows Update auto-restart: $($_)" "ERROR"
    }
}

#=============================================================================
# PERFORMANCE & SYSTEM FUNCTIONS
#=============================================================================

function Set-HighPerformancePower {
    Write-Log "`n=== Setting High Performance Power Plan ===" "INFO"
    
    try {
        # Get current power plan
        $currentPlan = powercfg /getactivescheme
        Write-Log "BEFORE: $currentPlan" "INFO"
        
        Write-Log "Setting High Performance power plan..."
        
        # Set to High Performance
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        
        # Verify change
        $newPlan = powercfg /getactivescheme
        Write-Log "AFTER: $newPlan" "SUCCESS"
        Write-Log "High Performance power plan activated!" "SUCCESS"
        
    }
    catch {
        Write-Log "Failed to set High Performance power plan: $($_)" "ERROR"
    }
}

function Set-BalancedPower {
    Write-Log "`n=== Setting Balanced Power Plan ===" "INFO"
    
    try {
        $currentPlan = powercfg /getactivescheme
        Write-Log "BEFORE: $currentPlan" "INFO"
        
        Write-Log "Setting Balanced (default) power plan..."
        
        # GUID for Balanced power plan
        $balancedGuid = "381b4222-f694-41f0-9685-ff5bb260df2e"
        powercfg /setactive $balancedGuid
        
        $newPlan = powercfg /getactivescheme
        Write-Log "AFTER: $newPlan" "SUCCESS"
        Write-Log "Balanced power plan activated!" "SUCCESS"
    }
    catch {
        Write-Log "Failed to set Balanced power plan: $($_)" "ERROR"
    }
}

function Disable-VisualEffects {
    Write-Log "`n=== Disabling Visual Effects for Performance ===" "INFO"
    
    try {
        # Check current state
        $currentValue = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -ErrorAction SilentlyContinue
        if ($currentValue) {
            Write-Log "BEFORE: Visual effects setting = $($currentValue.VisualFXSetting)" "INFO"
        } else {
            Write-Log "BEFORE: Visual effects setting not configured" "INFO"
        }
        
        Write-Log "Configuring visual effects for best performance..."
        
        # Set to performance mode (2 = best performance, 1 = best appearance, 0 = let Windows choose, 3 = custom)
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value 2 -Type DWord -Force
        
        # Additional performance settings
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](144,18,3,128,16,0,0,0)) -Type Binary -Force
        
        Write-Log "AFTER: Visual effects set to best performance" "SUCCESS"
        Write-Log "Visual effects disabled for better performance!" "SUCCESS"
        Write-Log "Changes will take effect after next login." "INFO"
        
    }
    catch {
        Write-Log "Failed to disable visual effects: $($_)" "ERROR"
    }
}

function Enable-VisualEffects {
    Write-Log "`n=== Enabling Visual Effects for Appearance ===" "INFO"
    
    try {
        Write-Log "Configuring visual effects for best appearance..."
        
        # Set to best appearance mode (1 = best appearance)
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value 1 -Type DWord -Force
        
        # Reset UserPreferencesMask to default (letting Windows manage it)
        Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Force -ErrorAction SilentlyContinue
        
        Write-Log "AFTER: Visual effects set to best appearance" "SUCCESS"
        Write-Log "Visual effects enabled for best appearance!" "SUCCESS"
        Write-Log "Changes will take effect after next login." "INFO"
    }
    catch {
        Write-Log "Failed to enable visual effects: $($_)" "ERROR"
    }
}

function Configure-VirtualMemory {
    Write-Log "`n=== Configuring Virtual Memory ===" "INFO"
    
    try {
        # Get total RAM
        $totalRAM = [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        Write-Log "BEFORE: Total RAM detected = $totalRAM GB" "INFO"
        
        # Calculate optimal page file size (1.5x RAM)
        $optimalSize = [math]::Round($totalRAM * 1.5 * 1024)  # Convert to MB
        
        Write-Log "Configuring virtual memory to $optimalSize MB..." "INFO"
        
        # Note: This requires WMI and can be complex, so we'll provide guidance instead
        Write-Log "Recommended page file size: $optimalSize MB" "INFO"
        Write-Log "To manually configure:" "INFO"
        Write-Log "1. Open System Properties > Advanced > Performance Settings" "INFO"
        Write-Log "2. Go to Advanced tab > Virtual Memory > Change" "INFO"
        Write-Log "3. Uncheck 'Automatically manage' and set custom size" "INFO"
        Write-Log "4. Set Initial size: $optimalSize MB" "INFO"
        Write-Log "5. Set Maximum size: $optimalSize MB" "INFO"
        
        Write-Log "Virtual memory configuration guidance provided!" "SUCCESS"
        
    }
    catch {
        Write-Log "Failed to configure virtual memory: $($_)" "ERROR"
    }
}

function Invoke-SystemCleanup {
    Write-Log "`n=== Performing System Cleanup ===" "INFO"
    
    try {
        Write-Log "Cleaning temporary files and system cache..." "INFO"
        
        $cleanupPaths = @(
            "$env:TEMP",
            "$env:LOCALAPPDATA\Temp",
            "$env:windir\Temp",
            "$env:windir\Prefetch",
            "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
        )
        
        $totalCleaned = 0
        foreach ($path in $cleanupPaths) {
            if (Test-Path $path) {
                try {
                    $beforeSize = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                    Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                    $afterSize = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                    $cleaned = ($beforeSize - $afterSize) / 1MB
                    $totalCleaned += $cleaned
                    Write-Log "Cleaned $path - Freed: $([math]::Round($cleaned, 2)) MB" "SUCCESS"
                }
                catch {
                    Write-Log "Could not fully clean $path (some files in use)" "WARNING"
                }
            }
        }
        
        # Run Disk Cleanup
        Write-Log "Running Windows Disk Cleanup..." "INFO"
        Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -NoNewWindow -Wait -ErrorAction SilentlyContinue
        
        Write-Log "System cleanup completed! Total freed: $([math]::Round($totalCleaned, 2)) MB" "SUCCESS"
        
    }
    catch {
        Write-Log "Failed to perform system cleanup: $($_)" "ERROR"
    }
}

function Disable-StartupPrograms {
    Write-Log "`n=== Managing Startup Programs ===" "INFO"
    
    try {
        Write-Log "Analyzing startup programs..." "INFO"
        
        # Get startup items from registry
        $startupItems = @()
        $registryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        )
        
        foreach ($regPath in $registryPaths) {
            if (Test-Path $regPath) {
                $items = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
                $items.PSObject.Properties | Where-Object { $_.Name -notmatch "PS" } | ForEach-Object {
                    $startupItems += [PSCustomObject]@{
                        Name = $_.Name
                        Path = $_.Value
                        Location = $regPath
                    }
                }
            }
        }
        
        Write-Log "BEFORE: Found $($startupItems.Count) startup programs" "INFO"
        
        # Display startup programs for user review
        if ($startupItems.Count -gt 0) {
            Write-Log "Current startup programs:" "INFO"
            $startupItems | ForEach-Object { Write-Log "- $($_.Name): $($_.Path)" "INFO" }
        }
        
        Write-Log "Use Task Manager > Startup tab to disable unwanted programs" "INFO"
        Write-Log "Startup programs analysis completed!" "SUCCESS"
        
    }
    catch {
        Write-Log "Failed to analyze startup programs: $($_)" "ERROR"
    }
}

#=============================================================================
# DEVELOPMENT ENVIRONMENT FUNCTIONS
#=============================================================================

function Install-WindowsTerminal {
    Write-Log "`n=== Installing Windows Terminal ===" "INFO"
    
    # Check if already installed
    $terminal = Get-AppxPackage -Name "Microsoft.WindowsTerminal" -ErrorAction SilentlyContinue
    if ($terminal) {
        Write-Log "Windows Terminal is already installed!" "SUCCESS"
        return
    }
    
    if ($script:WingetInstalled) {
        try {
            Write-Log "Installing Windows Terminal via winget..."
            winget install --id Microsoft.WindowsTerminal --exact --silent --accept-package-agreements --accept-source-agreements
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Windows Terminal installed successfully!" "SUCCESS"
                return
            }
        }
        catch {
            Write-Log "Winget installation failed, trying Microsoft Store..." "WARNING"
        }
    }
    
    # Fallback to Microsoft Store
    Write-Log "Opening Microsoft Store for Windows Terminal installation..." "INFO"
    Start-Process "ms-windows-store://pdp/?productid=9N0DX20HK701"
}

function Install-PackageManagers {
    Write-Log "`n=== Installing Package Managers ===" "INFO"
    
    try {
        # Install Chocolatey
        Write-Log "Installing Chocolatey package manager..." "INFO"
        
        # Check if Chocolatey is already installed
        if (Test-CommandExists "choco") {
            Write-Log "Chocolatey is already installed!" "SUCCESS"
        } else {
            Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            
            if (Test-CommandExists "choco") {
                Write-Log "Chocolatey installed successfully!" "SUCCESS"
            } else {
                Write-Log "Failed to install Chocolatey" "ERROR"
            }
        }
        
        # Install Scoop
        Write-Log "Installing Scoop package manager..." "INFO"
        
        if (Test-CommandExists "scoop") {
            Write-Log "Scoop is already installed!" "SUCCESS"
        } else {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
            irm get.scoop.sh | iex
            
            if (Test-CommandExists "scoop") {
                Write-Log "Scoop installed successfully!" "SUCCESS"
            } else {
                Write-Log "Failed to install Scoop" "ERROR"
            }
        }
        
    }
    catch {
        Write-Log "Failed to install package managers: $($_)" "ERROR"
    }
}

function Install-DockerDesktop {
    Write-Log "`n=== Installing Docker Desktop ===" "INFO"
    
    # Check if already installed
    $dockerPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerPath) {
        Write-Log "Docker Desktop is already installed!" "SUCCESS"
        return
    }
    
    if ($script:WingetInstalled) {
        try {
            Write-Log "Installing Docker Desktop via winget..."
            winget install --id Docker.DockerDesktop --exact --silent --accept-package-agreements --accept-source-agreements
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Docker Desktop installed successfully!" "SUCCESS"
                Write-Log "You may need to restart and enable WSL2 for Docker to work properly." "INFO"
                return
            }
        }
        catch {
            Write-Log "Winget installation failed" "WARNING"
        }
    }
    
    # Fallback to direct download
    try {
        $dockerUrl = "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
        $dockerInstaller = "$script:TempPath\DockerDesktopInstaller.exe"
        
        Write-Log "Downloading Docker Desktop installer..."
        Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller -UseBasicParsing
        
        Write-Log "Installing Docker Desktop..."
        Start-Process $dockerInstaller -ArgumentList "install", "--quiet" -Wait
        
        Write-Log "Docker Desktop installed successfully!" "SUCCESS"
    }
    catch {
        Write-Log "Failed to install Docker Desktop: $($_)" "ERROR"
    }
}

function Setup-DevFolderStructure {
    Write-Log "`n=== Setting up Development Folder Structure ===" "INFO"
    
    try {
        $devFolders = @(
            "$env:USERPROFILE\Documents\Projects",
            "$env:USERPROFILE\Documents\GitHub",
            "$env:USERPROFILE\Documents\Scripts",
            "$env:USERPROFILE\Documents\Tools",
            "C:\Dev",
            "C:\Tools"
        )
        
        $createdCount = 0
        foreach ($folder in $devFolders) {
            if (!(Test-Path $folder)) {
                try {
                    New-Item -ItemType Directory -Path $folder -Force | Out-Null
                    Write-Log "Created: $folder" "SUCCESS"
                    $createdCount++
                } catch {
                    Write-Log "Failed to create: $folder" "WARNING"
                }
            } else {
                Write-Log "Already exists: $folder" "INFO"
            }
        }
        
        Write-Log "Development folder structure setup completed!" "SUCCESS"
        Write-Log "Created $createdCount new folders" "INFO"
        
    }
    catch {
        Write-Log "Failed to setup dev folder structure: $($_)" "ERROR"
    }
}

function Install-NodeJS {
    Write-Log "`n=== Installing Node.js ===" "INFO"
    
    # Check if already installed
    if (Test-CommandExists "node") {
        $nodeVersion = node --version
        Write-Log "Node.js is already installed: $nodeVersion" "SUCCESS"
        return
    }
    
    if ($script:WingetInstalled) {
        try {
            Write-Log "Installing Node.js LTS via winget..."
            winget install --id OpenJS.NodeJS.LTS --exact --silent --accept-package-agreements --accept-source-agreements
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Node.js installed successfully!" "SUCCESS"
                Write-Log "You may need to restart your terminal to use Node.js" "INFO"
                return
            }
        }
        catch {
            Write-Log "Winget installation failed" "WARNING"
        }
    }
    
    Write-Log "Please install Node.js manually from https://nodejs.org" "INFO"
}

function Install-Python {
    Write-Log "`n=== Installing Python ===" "INFO"
    
    # Check if already installed
    if (Test-CommandExists "python") {
        $pythonVersion = python --version
        Write-Log "Python is already installed: $pythonVersion" "SUCCESS"
        return
    }
    
    if ($script:WingetInstalled) {
        try {
            Write-Log "Installing Python via winget..."
            winget install --id Python.Python.3.11 --exact --silent --accept-package-agreements --accept-source-agreements
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Python installed successfully!" "SUCCESS"
                Write-Log "You may need to restart your terminal to use Python" "INFO"
                return
            }
        }
        catch {
            Write-Log "Winget installation failed" "WARNING"
        }
    }
    
    Write-Log "Please install Python manually from https://python.org" "INFO"
}

#=============================================================================
# NETWORK & CONNECTIVITY FUNCTIONS
#=============================================================================

function Configure-DNSSettings {
    Write-Log "`n=== Configuring DNS Settings ===" "INFO"
    
    try {
        # Get network adapters
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and ($_.MediaType -eq "802.3" -or $_.MediaType -eq "Wireless") }
        
        if ($adapters.Count -eq 0) {
            Write-Log "No active network adapters found" "ERROR"
            return
        }
        
        Write-Log "BEFORE: Getting current DNS settings..." "INFO"
        foreach ($adapter in $adapters) {
            $currentDNS = Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4
            Write-Log "Adapter: $($adapter.Name) - Current DNS: $($currentDNS.ServerAddresses -join ', ')" "INFO"
        }
        
        Write-Host "`nDNS Configuration Options:" -ForegroundColor Cyan
        Write-Host "1. Cloudflare (1.1.1.1, 1.0.0.1) - Fast & Privacy-focused" -ForegroundColor White
        Write-Host "2. Google (8.8.8.8, 8.8.4.4) - Reliable & Fast" -ForegroundColor White
        Write-Host "3. Quad9 (9.9.9.9, 149.112.112.112) - Security-focused" -ForegroundColor White
        Write-Host "4. Restore to Automatic (DHCP)" -ForegroundColor Yellow
        Write-Host "5. Skip DNS configuration" -ForegroundColor White
        
        $choice = Read-Host "Choose DNS provider (1-5)"
        
        $dnsServers = $null
        $providerName = ""

        switch ($choice) {
            "1" { $dnsServers = @("1.1.1.1", "1.0.0.1"); $providerName = "Cloudflare" }
            "2" { $dnsServers = @("8.8.8.8", "8.8.4.4"); $providerName = "Google" }
            "3" { $dnsServers = @("9.9.9.9", "149.112.112.112"); $providerName = "Quad9" }
            "4" { # Restore to DHCP
                Write-Log "Setting DNS to Automatic (DHCP)..." "INFO"
                foreach ($adapter in $adapters) {
                    try {
                        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses
                        Write-Log "Restored DNS for adapter: $($adapter.Name)" "SUCCESS"
                    }
                    catch {
                        Write-Log "Failed to restore DNS for adapter: $($adapter.Name)" "WARNING"
                    }
                }
                Write-Log "AFTER: DNS configuration restored to Automatic (DHCP)!" "SUCCESS"
                return
            }
            "5" { Write-Log "DNS configuration skipped" "INFO"; return }
            default { Write-Log "Invalid choice, skipping DNS configuration" "ERROR"; return }
        }
        
        Write-Log "Setting DNS to $providerName ($($dnsServers -join ', '))..." "INFO"
        
        foreach ($adapter in $adapters) {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $dnsServers
                Write-Log "Updated DNS for adapter: $($adapter.Name)" "SUCCESS"
            }
            catch {
                Write-Log "Failed to update DNS for adapter: $($adapter.Name)" "WARNING"
            }
        }
        
        Write-Log "AFTER: DNS configuration completed!" "SUCCESS"
        Write-Log "New DNS servers: $($dnsServers -join ', ')" "INFO"
        
    }
    catch {
        Write-Log "Failed to configure DNS settings: $($_)" "ERROR"
    }
}

function Enable-SSHServer {
    Write-Log "`n=== Enabling SSH Server ===" "INFO"
    
    try {
        # Check if OpenSSH Server is installed
        $sshServerFeature = Get-WindowsCapability -Online -Name OpenSSH.Server*
        
        if ($sshServerFeature.State -eq "Installed") {
            Write-Log "BEFORE: OpenSSH Server is already installed" "INFO"
        } else {
            Write-Log "BEFORE: OpenSSH Server is not installed" "INFO"
            Write-Log "Installing OpenSSH Server..." "INFO"
            Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
        }
        
        # Start and enable SSH service
        Write-Log "Configuring SSH service..." "INFO"
        Start-Service sshd
        Set-Service -Name sshd -StartupType 'Automatic'
        
        # Configure firewall
        Write-Log "Configuring Windows Firewall for SSH..." "INFO"
        New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -ErrorAction SilentlyContinue
        
        Write-Log "AFTER: SSH Server enabled and running!" "SUCCESS"
        Write-Log "SSH is now accessible on port 22" "INFO"
        Write-Log "Default authentication is password-based" "INFO"
        
    }
    catch {
        Write-Log "Failed to enable SSH server: $($_)" "ERROR"
    }
}

function Configure-RemoteDesktop {
    Write-Log "`n=== Configuring Remote Desktop ===" "INFO"
    
    try {
        # Check current state
        $currentRDP = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -ErrorAction SilentlyContinue
        if ($currentRDP -and $currentRDP.fDenyTSConnections -eq 0) {
            Write-Log "BEFORE: Remote Desktop is already enabled" "INFO"
        } else {
            Write-Log "BEFORE: Remote Desktop is disabled" "INFO"
        }
        
        $enable = Read-Host "Do you want to enable Remote Desktop? (Y/N)"
        if ($enable -ne "Y" -and $enable -ne "y") {
            Write-Log "Remote Desktop configuration skipped" "INFO"
            return
        }
        
        Write-Log "Enabling Remote Desktop..." "INFO"
        
        # Enable Remote Desktop
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
        
        # Enable Network Level Authentication (more secure)
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1 -Force
        
        # Configure firewall
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
        
        Write-Log "AFTER: Remote Desktop enabled successfully!" "SUCCESS"
        Write-Log "RDP is now accessible on port 3389" "INFO"
        Write-Log "Network Level Authentication is enabled for security" "INFO"
        
    }
    catch {
        Write-Log "Failed to configure Remote Desktop: $($_)" "ERROR"
    }
}

function Optimize-NetworkSettings {
    Write-Log "`n=== Optimizing Network Settings ===" "INFO"
    
    try {
        Write-Log "Applying network optimizations..." "INFO"
        
        # TCP optimizations
        netsh int tcp set global autotuninglevel=normal
        netsh int tcp set global rss=enabled
        netsh int tcp set global netdma=enabled
        netsh int tcp set global dca=enabled
        
        # Disable bandwidth throttling
        $mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        if (!(Test-Path $mmPath)) { New-Item -Path $mmPath -Force | Out-Null }
        Set-ItemProperty -Path $mmPath -Name "NetworkThrottlingIndex" -Value 4294967295 -PropertyType DWord -Force
        
        Write-Log "Network optimizations applied successfully!" "SUCCESS"
        Write-Log "Optimizations include TCP auto-tuning, RSS, and bandwidth throttling removal" "INFO"
        
    }
    catch {
        Write-Log "Failed to optimize network settings: $($_)" "ERROR"
    }
}

#=============================================================================
# FILE SYSTEM & UI FUNCTIONS
#=============================================================================

function Show-FileExtensions {
    Write-Log "`n=== Showing File Extensions ===" "INFO"
    
    try {
        # Check current state
        $currentValue = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -ErrorAction SilentlyContinue
        if ($currentValue -and $currentValue.HideFileExt -eq 0) {
            Write-Log "BEFORE: File extensions are already visible" "INFO"
            return
        } else {
            Write-Log "BEFORE: File extensions are hidden" "INFO"
        }
        
        Write-Log "Enabling file extension display..." "INFO"
        
        # Show file extensions
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -Force
        
        # Restart Explorer to apply changes
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 2
        Start-Process explorer
        
        Write-Log "AFTER: File extensions are now visible!" "SUCCESS"
        Write-Log "Explorer restarted to apply changes" "INFO"
        
    }
    catch {
        Write-Log "Failed to show file extensions: $($_)" "ERROR"
    }
}

function Hide-FileExtensions {
    Write-Log "`n=== Hiding File Extensions ===" "INFO"
    
    try {
        Write-Log "Hiding file extension display..." "INFO"
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 1 -Type DWord -Force
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 2
        Start-Process explorer
        Write-Log "AFTER: File extensions are now hidden!" "SUCCESS"
    }
    catch {
        Write-Log "Failed to hide file extensions: $($_)" "ERROR"
    }
}

function Show-HiddenFiles {
    Write-Log "`n=== Showing Hidden Files ===" "INFO"
    
    try {
        # Check current state
        $currentValue = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -ErrorAction SilentlyContinue
        if ($currentValue -and $currentValue.Hidden -eq 1) {
            Write-Log "BEFORE: Hidden files are already visible" "INFO"
            return
        } else {
            Write-Log "BEFORE: Hidden files are not visible" "INFO"
        }
        
        Write-Log "Enabling hidden files display..." "INFO"
        
        # Show hidden files and folders
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden" -Value 1 -Type DWord -Force
        
        # Restart Explorer to apply changes
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 2
        Start-Process explorer
        
        Write-Log "AFTER: Hidden files and system files are now visible!" "SUCCESS"
        Write-Log "Explorer restarted to apply changes" "INFO"
        
    }
    catch {
        Write-Log "Failed to show hidden files: $($_)" "ERROR"
    }
}

function Hide-HiddenFiles {
    Write-Log "`n=== Hiding Hidden Files ===" "INFO"
    
    try {
        Write-Log "Hiding hidden files display..." "INFO"
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden" -Value 0 -Type DWord -Force
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 2
        Start-Process explorer
        Write-Log "AFTER: Hidden files are now hidden (default)!" "SUCCESS"
    }
    catch {
        Write-Log "Failed to hide hidden files: $($_)" "ERROR"
    }
}

function Configure-DarkMode {
    Write-Log "`n=== Configuring Dark Mode ===" "INFO"
    
    try {
        # Check current theme
        $currentAppTheme = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue
        
        if ($currentAppTheme -and $currentAppTheme.AppsUseLightTheme -eq 0) {
            Write-Log "BEFORE: Dark mode is already enabled for apps" "INFO"
        } else {
            Write-Log "BEFORE: Light mode is enabled for apps" "INFO"
        }
        
        Write-Host "`nTheme Configuration:" -ForegroundColor Cyan
        Write-Host "1. Enable Dark Mode (apps and system)" -ForegroundColor White
        Write-Host "2. Enable Light Mode (apps and system)" -ForegroundColor White
        Write-Host "3. Skip theme configuration" -ForegroundColor White
        
        $choice = Read-Host "Choose theme option (1-3)"
        
        $themesPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        if (!(Test-Path $themesPath)) { New-Item -Path $themesPath -Force | Out-Null }
        
        switch ($choice) {
            "1" {
                Write-Log "Enabling Dark Mode..." "INFO"
                Set-ItemProperty -Path $themesPath -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force
                Set-ItemProperty -Path $themesPath -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force
                Write-Log "AFTER: Dark Mode enabled!" "SUCCESS"
            }
            "2" {
                Write-Log "Enabling Light Mode..." "INFO"
                Set-ItemProperty -Path $themesPath -Name "AppsUseLightTheme" -Value 1 -Type DWord -Force
                Set-ItemProperty -Path $themesPath -Name "SystemUsesLightTheme" -Value 1 -Type DWord -Force
                Write-Log "AFTER: Light Mode enabled!" "SUCCESS"
            }
            "3" {
                Write-Log "Theme configuration skipped" "INFO"
                return
            }
            default {
                Write-Log "Invalid choice, skipping theme configuration" "ERROR"
                return
            }
        }
        
        Write-Log "Theme changes applied! Some apps may require restart to reflect changes." "INFO"
        
    }
    catch {
        Write-Log "Failed to configure dark mode: $($_)" "ERROR"
    }
}

function Set-DefaultApps {
    Write-Log "`n=== Setting Default Applications ===" "INFO"
    
    try {
        Write-Log "Opening Default Apps settings..." "INFO"
        Write-Log "You can manually configure your preferred default applications" "INFO"
        
        # Open Windows Settings to Default Apps
        Start-Process "ms-settings:defaultapps"
        
        Write-Log "Default Apps settings opened!" "SUCCESS"
        Write-Log "Configure your preferred browser, email client, and other defaults" "INFO"
        
    }
    catch {
        Write-Log "Failed to open default apps settings: $($_)" "ERROR"
    }
}

function Configure-TaskbarCustomizations {
    Write-Log "`n=== Configuring Taskbar Customizations ===" "INFO"
    
    try {
        Write-Log "Applying taskbar optimizations..." "INFO"
        
        # Hide search box
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type DWord -Force
        
        # Hide task view button
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Type DWord -Force
        
        # Hide widgets (Windows 11)
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        
        # Small taskbar icons
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -Value 1 -Type DWord -Force
        
        # Never combine taskbar buttons
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarGlomLevel" -Value 2 -Type DWord -Force
        
        # Restart Explorer to apply changes
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 2
        Start-Process explorer
        
        Write-Log "Taskbar customizations applied successfully!" "SUCCESS"
        Write-Log "Changes: Hidden search box, task view, widgets; small icons; never combine buttons" "INFO"
        
    }
    catch {
        Write-Log "Failed to configure taskbar customizations: $($_)" "ERROR"
    }
}

function Restore-DefaultTaskbar {
    Write-Log "`n=== Restoring Default Taskbar Settings ===" "INFO"
    
    try {
        Write-Log "Restoring default taskbar settings..." "INFO"
        
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarGlomLevel" -Value 0 -Type DWord -Force
        
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 2
        Start-Process explorer
        
        Write-Log "Default taskbar settings restored successfully!" "SUCCESS"
    }
    catch {
        Write-Log "Failed to restore taskbar settings: $($_)" "ERROR"
    }
}

#=============================================================================
# BACKUP & RECOVERY FUNCTIONS
#=============================================================================

function Create-SystemRestorePoint {
    Write-Log "`n=== Creating System Restore Point ===" "INFO"
    
    try {
        # Check if System Restore is enabled
        $restoreStatus = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        
        Write-Log "Creating system restore point..." "INFO"
        
        # Enable System Restore if not enabled
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        
        # Create restore point
        $restorePointName = "Post-Install Setup - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        Checkpoint-Computer -Description $restorePointName -RestorePointType "MODIFY_SETTINGS"
        
        Write-Log "System restore point created successfully!" "SUCCESS"
        Write-Log "Restore point name: $restorePointName" "INFO"
        
    }
    catch {
        Write-Log "Failed to create system restore point: $($_)" "ERROR"
        Write-Log "You can manually create one in System Properties > System Protection" "INFO"
    }
}

function Export-InstalledPrograms {
    Write-Log "`n=== Exporting Installed Programs List ===" "INFO"
    
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $outputPath = Join-Path -Path $desktopPath -ChildPath "InstalledPrograms_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        
        Write-Log "Generating installed programs list..." "INFO"
        
        # Get installed programs from registry
        $programs = @()
        
        # 64-bit programs
        $programs += Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                     Where-Object { $_.DisplayName } | 
                     Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
        
        # 32-bit programs on 64-bit systems
        if (Test-Path "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall") {
            $programs += Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                         Where-Object { $_.DisplayName } | 
                         Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
        }
        
        # Sort and remove duplicates
        $programs = $programs | Sort-Object DisplayName | Get-Unique -AsString
        
        # Export to file
        "Installed Programs List - Generated on $(Get-Date)" | Out-File -FilePath $outputPath -Encoding UTF8
        "=" * 50 | Out-File -FilePath $outputPath -Append -Encoding UTF8
        "" | Out-File -FilePath $outputPath -Append -Encoding UTF8
        
        $programs | ForEach-Object {
            "Program: $($_.DisplayName)" | Out-File -FilePath $outputPath -Append -Encoding UTF8
            "Version: $($_.DisplayVersion)" | Out-File -FilePath $outputPath -Append -Encoding UTF8
            "Publisher: $($_.Publisher)" | Out-File -FilePath $outputPath -Append -Encoding UTF8
            "Install Date: $($_.InstallDate)" | Out-File -FilePath $outputPath -Append -Encoding UTF8
            "" | Out-File -FilePath $outputPath -Append -Encoding UTF8
        }
        
        Write-Log "Installed programs list exported successfully!" "SUCCESS"
        Write-Log "File saved to: $outputPath" "INFO"
        Write-Log "Found $($programs.Count) installed programs" "INFO"
        
    }
    catch {
        Write-Log "Failed to export installed programs list: $($_)" "ERROR"
    }
}

function Configure-WindowsBackup {
    Write-Log "`n=== Configuring Windows Backup ===" "INFO"
    
    try {
        Write-Log "Opening Windows Backup settings..." "INFO"
        
        # Check Windows version and open appropriate backup settings
        $osVersion = [System.Environment]::OSVersion.Version
        
        if ($osVersion.Major -ge 10) {
            # Windows 10/11 - Open Settings app
            Start-Process "ms-settings:backup"
            Write-Log "Windows 10/11 Backup settings opened" "SUCCESS"
            Write-Log "Configure File History or OneDrive backup as needed" "INFO"
        } else {
            # Older Windows - Open Control Panel backup
            Start-Process "control" -ArgumentList "/name Microsoft.BackupAndRestore"
            Write-Log "Windows Backup and Restore opened" "SUCCESS"
        }
        
        Write-Log "Backup configuration guidance:" "INFO"
        Write-Log "- Enable File History for user files" "INFO"
        Write-Log "- Consider OneDrive for cloud backup" "INFO"
        Write-Log "- Set up regular backup schedule" "INFO"
        
    }
    catch {
        Write-Log "Failed to open backup settings: $($_)" "ERROR"
    }
}

function Backup-Drivers {
    Write-Log "`n=== Backing Up All Third-Party Drivers ===" "INFO"
    
    try {
        $date = Get-Date -Format "yyyy-MM-dd"
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $backupFolderPath = Join-Path -Path $desktopPath -ChildPath "DriverBackup-$date"
        $zipFilePath = "$desktopPath\DriverBackup-$date.zip"
        
        Write-Log "Creating backup folder: $backupFolderPath" "INFO"
        New-Item -Path $backupFolderPath -ItemType Directory -Force | Out-Null
        
        Write-Log "Exporting drivers. This may take a few minutes..." "INFO"
        Export-WindowsDriver -Online -Destination $backupFolderPath -ErrorAction Stop
        Write-Log "Drivers exported successfully to: $backupFolderPath" "SUCCESS"
        
        $zipChoice = Read-Host "Do you want to compress the backup into a .zip file? (Y/N)"
        if ($zipChoice -match '^(y|Y)$') {
            Write-Log "Compressing backup to $zipFilePath..." "INFO"
            Compress-Archive -Path "$backupFolderPath\*" -DestinationPath $zipFilePath -Force
            Write-Log "ZIP archive created successfully at: $zipFilePath" "SUCCESS"
            Write-Log "You may remove the uncompressed folder: $backupFolderPath" "INFO"
        } else {
            Write-Log "Skipping ZIP compression." "INFO"
        }
        
        Write-Log "Driver backup complete!" "SUCCESS"
    }
    catch {
        Write-Log "An error occurred during driver backup: $_" "ERROR"
    }
}

function Restore-Drivers {
    Write-Log "`n=== Restoring Drivers from Backup ===" "INFO"

    try {
        # Load Windows Forms for the file dialog
        Add-Type -AssemblyName System.Windows.Forms

        # Create and configure the OpenFileDialog
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Title = "Select driver backup ZIP file"
        $dialog.Filter = "ZIP files (*.zip)|*.zip"
        $dialog.Multiselect = $false

        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            Write-Log "No ZIP file selected. Restore operation cancelled." "WARNING"
            return
        }

        $zipPath = $dialog.FileName
        Write-Log "Selected backup file: $zipPath" "INFO"

        # Use the script's temp path for extraction
        $tempExtractPath = Join-Path $script:TempPath "DriverRestore"
        if (Test-Path $tempExtractPath) {
            Remove-Item -Path $tempExtractPath -Recurse -Force
        }
        
        Write-Log "Extracting ZIP to temporary folder: $tempExtractPath" "INFO"
        Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force

        Write-Log "Scanning for drivers to install..." "INFO"
        # The /install switch will automatically handle duplicates and newer versions.
        # It recursively searches the directory for all valid driver packages.
        pnputil /add-driver "$tempExtractPath\*.inf" /subdirs /install

        Write-Log "Driver restore process completed. Check console output above for details." "SUCCESS"
        Write-Log "It is recommended to restart the system to finalize driver installations." "WARNING"
        
        # Clean up the extraction folder
        Remove-Item -Path $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Log "An error occurred during driver restore: $_" "ERROR"
    }
}


#=============================================================================
# ENTERPRISE/PROFESSIONAL FUNCTIONS
#=============================================================================

function Configure-DomainJoin {
    Write-Log "`n=== Domain Join Assistant ===" "INFO"
    
    try {
        # Check if already domain-joined
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
        
        if ($computerSystem.PartOfDomain) {
            Write-Log "BEFORE: Computer is already joined to domain: $($computerSystem.Domain)" "INFO"
            $unjoin = Read-Host "Do you want to unjoin from the current domain? (Y/N)"
            if ($unjoin -match '^(y|Y)$') {
                Write-Log "Please use 'Remove-Computer' cmdlet manually for domain unjoin" "INFO"
                return
            } else {
                Write-Log "Domain join assistant cancelled" "INFO"
                return
            }
        } else {
            Write-Log "BEFORE: Computer is in workgroup: $($computerSystem.Workgroup)" "INFO"
        }
        
        Write-Host "`nDomain Join Configuration:" -ForegroundColor Cyan
        $domainName = Read-Host "Enter domain name (e.g., company.local)"
        $username = Read-Host "Enter domain admin username"
        
        if ([string]::IsNullOrWhiteSpace($domainName) -or [string]::IsNullOrWhiteSpace($username)) {
            Write-Log "Domain name or username cannot be empty" "ERROR"
            return
        }
        
        Write-Log "Attempting to join domain: $domainName" "INFO"
        Write-Log "This will require domain admin credentials and a restart" "WARNING"
        
        $proceed = Read-Host "Proceed with domain join? (Y/N)"
        if ($proceed -ne "Y" -and $proceed -ne "y") {
            Write-Log "Domain join cancelled" "INFO"
            return
        }
        
        # Domain join command (will prompt for password)
        Add-Computer -DomainName $domainName -Credential (Get-Credential -UserName $username -Message "Enter domain admin password") -Restart
        
    }
    catch {
        Write-Log "Failed to join domain: $($_)" "ERROR"
        Write-Log "Ensure network connectivity and valid domain credentials" "INFO"
    }
}

function Configure-ProxySettings {
    Write-Log "`n=== Configuring Proxy Settings ===" "INFO"
    
    try {
        # Check current proxy settings
        $currentProxy = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
        
        if ($currentProxy.ProxyEnable -eq 1) {
            Write-Log "BEFORE: Proxy is enabled - Server: $($currentProxy.ProxyServer)" "INFO"
        } else {
            Write-Log "BEFORE: Proxy is disabled" "INFO"
        }
        
        Write-Host "`nProxy Configuration:" -ForegroundColor Cyan
        Write-Host "1. Configure HTTP proxy" -ForegroundColor White
        Write-Host "2. Disable proxy" -ForegroundColor White
        Write-Host "3. Skip proxy configuration" -ForegroundColor White
        
        $choice = Read-Host "Choose option (1-3)"
        
        switch ($choice) {
            "1" {
                $proxyServer = Read-Host "Enter proxy server (e.g., proxy.company.com:8080)"
                $bypassList = Read-Host "Enter bypass list (e.g., *.local;127.0.0.1) or press Enter for default"
                
                if ([string]::IsNullOrWhiteSpace($bypassList)) {
                    $bypassList = "*.local;127.0.0.1;localhost"
                }
                
                Write-Log "Enabling proxy: $proxyServer" "INFO"
                
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "ProxyEnable" -Value 1 -Type DWord -Force
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "ProxyServer" -Value $proxyServer -Force
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "ProxyOverride" -Value $bypassList -Force
                
                Write-Log "AFTER: Proxy enabled successfully!" "SUCCESS"
            }
            "2" {
                Write-Log "Disabling proxy..." "INFO"
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "ProxyEnable" -Value 0 -Type DWord -Force
                Write-Log "AFTER: Proxy disabled successfully!" "SUCCESS"
            }
            "3" {
                Write-Log "Proxy configuration skipped" "INFO"
                return
            }
            default {
                Write-Log "Invalid choice, skipping proxy configuration" "ERROR"
                return
            }
        }
        
    }
    catch {
        Write-Log "Failed to configure proxy settings: $($_)" "ERROR"
    }
}

function Install-Certificates {
    Write-Log "`n=== Installing Certificates ===" "INFO"
    
    try {
        Write-Log "Certificate installation guidance:" "INFO"
        Write-Log "Common certificate scenarios:" "INFO"
        Write-Log "1. Root CA certificates for corporate networks" "INFO"
        Write-Log "2. Development certificates for local testing" "INFO"
        Write-Log "3. Client certificates for authentication" "INFO"
        Write-Log "" "INFO"
        
        Write-Host "Certificate installation options:" -ForegroundColor Cyan
        Write-Host "1. Open Certificate Manager (certmgr.msc)" -ForegroundColor White
        Write-Host "2. Open Local Computer Certificates (certlm.msc)" -ForegroundColor White
        Write-Host "3. Import certificate from file" -ForegroundColor White
        Write-Host "4. Skip certificate installation" -ForegroundColor White
        
        $choice = Read-Host "Choose option (1-4)"
        
        switch ($choice) {
            "1" {
                Write-Log "Opening Certificate Manager for current user..." "INFO"
                Start-Process "certmgr.msc"
                Write-Log "User Certificate Manager opened" "SUCCESS"
            }
            "2" {
                Write-Log "Opening Local Computer Certificate Manager..." "INFO"
                Start-Process "certlm.msc"
                Write-Log "Computer Certificate Manager opened" "SUCCESS"
            }
            "3" {
                $certPath = Read-Host "Enter full path to certificate file (.cer, .crt, .p12, .pfx)"
                if (Test-Path $certPath) {
                    Write-Log "Opening certificate: $certPath" "INFO"
                    Invoke-Item $certPath
                    Write-Log "Certificate import wizard launched" "SUCCESS"
                } else {
                    Write-Log "Certificate file not found: $certPath" "ERROR"
                }
            }
            "4" {
                Write-Log "Certificate installation skipped" "INFO"
                return
            }
            default {
                Write-Log "Invalid choice, skipping certificate installation" "ERROR"
                return
            }
        }
        
    }
    catch {
        Write-Log "Failed to manage certificates: $($_)" "ERROR"
    }
}

function Configure-GroupPolicies {
    Write-Log "`n=== Configuring Group Policies ===" "INFO"
    
    try {
        Write-Log "Group Policy configuration guidance:" "INFO"
        Write-Log "Opening Local Group Policy Editor..." "INFO"
        
        # Check if gpedit.msc is available (Pro/Enterprise editions)
        if (Test-Path "$env:SystemRoot\System32\gpedit.msc") {
            try {
                Start-Process "gpedit.msc"
                Write-Log "Local Group Policy Editor opened successfully!" "SUCCESS"
                Write-Log "Common policy configurations:" "INFO"
                Write-Log "- Computer Configuration > Administrative Templates > Windows Components" "INFO"
                Write-Log "- User Configuration > Administrative Templates > System" "INFO"
                Write-Log "- Security Settings > Local Policies > Security Options" "INFO"
            }
            catch {
                Write-Log "Failed to start Group Policy Editor: $_" "ERROR"
            }
        }
        else {
            Write-Log "Local Group Policy Editor not available (requires Pro/Enterprise edition)" "WARNING"
            Write-Log "Alternative: Use Registry Editor or PowerShell for policy-like configurations" "INFO"
        }
        
    }
    catch {
        Write-Log "An unexpected error occurred while trying to open Group Policy Editor: $($_)" "ERROR"
    }
}

#=============================================================================
# DEVELOPER SETUP FUNCTIONS
#=============================================================================

function Setup-SSHKeyAndGit {
    Write-Log "`n=== Setting up SSH Key + Git Configuration ===" "INFO"
    
    try {
        # Get computer name for SSH key comment
        $sshKeyPath = "$env:USERPROFILE\.ssh\id_ed25519"
        $sshKeyPubPath = "$env:USERPROFILE\.ssh\id_ed25519.pub"
        
        # Create .ssh directory if it doesn't exist
        $sshDir = "$env:USERPROFILE\.ssh"
        if (!(Test-Path $sshDir)) {
            New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
            Write-Log "Created .ssh directory" "INFO"
        }
        
        # Check if SSH key already exists
        if (Test-Path $sshKeyPath) {
            Write-Log "BEFORE: SSH key already exists at $sshKeyPath" "WARNING"
            Write-Host ""
            Write-Host "An SSH key already exists!" -ForegroundColor Yellow
            Write-Host "1. Create new key (backup existing)" -ForegroundColor White
            Write-Host "2. Replace existing key" -ForegroundColor White
            Write-Host "3. Skip SSH key creation" -ForegroundColor White
            $choice = Read-Host "Choose option (1-3)"
            
            switch ($choice) {
                "1" {
                    # Backup existing key
                    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                    Copy-Item $sshKeyPath "$sshKeyPath.backup_$timestamp" -Force
                    Copy-Item $sshKeyPubPath "$sshKeyPubPath.backup_$timestamp" -Force
                    Write-Log "Backed up existing SSH key with timestamp" "SUCCESS"
                }
                "2" {
                    Write-Log "Will replace existing SSH key" "INFO"
                }
                "3" {
                    Write-Log "Skipping SSH key creation, proceeding to Git setup..." "INFO"
                    Setup-GitConfiguration
                    return
                }
                default {
                    Write-Log "Invalid choice, skipping SSH key setup" "ERROR"
                    return
                }
            }
        } else {
            Write-Log "BEFORE: No SSH key found, will create new one" "INFO"
        }
        
        # Generate SSH key with computer name as comment
        Write-Log "Generating ed25519 SSH key..."
        $keyComment = "$env:USERNAME@$env:COMPUTERNAME"
        
        # Use ssh-keygen to generate the key
        ssh-keygen.exe -t ed25519 -f $sshKeyPath -C $keyComment -N '""'
        
        if (Test-Path $sshKeyPath -and Test-Path $sshKeyPubPath) {
            Write-Log "AFTER: SSH key generated successfully!" "SUCCESS"
            Write-Log "Private key: $sshKeyPath" "INFO"
            Write-Log "Public key: $sshKeyPubPath" "INFO"
            
            # Display the public key
            $publicKey = Get-Content $sshKeyPubPath
            Write-Log "`nYour SSH Public Key:" "INFO"
            Write-Host $publicKey -ForegroundColor Green
            Write-Host "`nCopy this key to your Git hosting service (GitHub, GitLab, etc.)" -ForegroundColor Yellow
        } else {
            Write-Log "Failed to generate SSH key" "ERROR"
            return
        }
        
        # Start SSH agent and add key
        Write-Log "Starting SSH agent and adding key..."
        Start-Service ssh-agent -ErrorAction SilentlyContinue
        ssh-add $sshKeyPath 2>$null
        
        Write-Log "SSH key setup completed successfully!" "SUCCESS"
        
        # Now configure Git
        Setup-GitConfiguration
        
    }
    catch {
        Write-Log "Failed to setup SSH key: $($_)" "ERROR"
    }
}

function Setup-GitConfiguration {
    Write-Log "`n=== Configuring Git ===" "INFO"
    
    try {
        # Check if git is installed
        if (!(Test-CommandExists "git")) {
            Write-Log "Git is not installed! Please install Git first (option 17)." "ERROR"
            return
        }
        
        # Get current git configuration
        $currentName = git config --global user.name 2>$null
        $currentEmail = git config --global user.email 2>$null
        
        if ($currentName) {
            Write-Log "BEFORE: Git user.name = '$currentName'" "INFO"
        } else {
            Write-Log "BEFORE: Git user.name not set" "INFO"
        }
        
        if ($currentEmail) {
            Write-Log "BEFORE: Git user.email = '$currentEmail'" "INFO"
        } else {
            Write-Log "BEFORE: Git user.email not set" "INFO"
        }
        
        # Get user input for Git configuration
        Write-Host "`nGit Configuration Setup:" -ForegroundColor Cyan
        
        $newName = Read-Host "Enter your Git user name (current: $currentName, press Enter to keep)"
        if ([string]::IsNullOrWhiteSpace($newName)) {
            $newName = $currentName
        }
        
        $newEmail = Read-Host "Enter your Git user email (current: $currentEmail, press Enter to keep)"
        if ([string]::IsNullOrWhiteSpace($newEmail)) {
            $newEmail = $currentEmail
        }
        
        # Configure Git with best practices
        Write-Log "Applying Git configuration and best practices..."
        
        # Basic user configuration
        git config --global user.name "$newName"
        git config --global user.email "$newEmail"
        
        # Best practices configuration
        git config --global init.defaultBranch main
        git config --global pull.rebase true
        git config --global push.default simple
        git config --global core.autocrlf true  # Windows line endings
        git config --global core.editor "notepad"
        git config --global credential.helper manager-core
        git config --global fetch.prune true
        git config --global rebase.autoStash true
        
        # Useful aliases
        git config --global alias.st status
        git config --global alias.co checkout
        git config --global alias.br branch
        git config --global alias.ci commit
        git config --global alias.unstage "reset HEAD --"
        git config --global alias.last "log -1 HEAD"
        git config --global alias.visual "!gitk"
        git config --global alias.lg "log --oneline --decorate --graph --all"
        
        # Safety configurations
        git config --global safe.directory "*"
        
        Write-Log "AFTER: Git user.name = '$newName'" "SUCCESS"
        Write-Log "AFTER: Git user.email = '$newEmail'" "SUCCESS"
        Write-Log "Applied Git best practices:" "SUCCESS"
        Write-Log "- Default branch: main" "INFO"
        Write-Log "- Pull strategy: rebase" "INFO"
        Write-Log "- Line endings: Windows (CRLF)" "INFO"
        Write-Log "- Credential helper: manager-core" "INFO"
        Write-Log "- Added useful aliases (st, co, br, ci, lg, etc.)" "INFO"
        Write-Log "- Enabled auto-stash and prune" "INFO"
        
        Write-Log "Git configuration completed successfully!" "SUCCESS"
        
    }
    catch {
        Write-Log "Failed to configure Git: $($_)" "ERROR"
    }
}

function Setup-GitOnly {
    Write-Log "`n=== Setting up Git Configuration Only ===" "INFO"
    Setup-GitConfiguration
}

function Set-ComputerHostname {
    Write-Log "`n=== Setting Computer Hostname ===" "INFO"
    
    try {
        # Get current computer name
        $currentName = $env:COMPUTERNAME
        Write-Log "BEFORE: Current computer name is '$currentName'" "INFO"
        
        Write-Host "`nComputer Hostname Setup:" -ForegroundColor Cyan
        Write-Host "Current computer name: $currentName" -ForegroundColor Yellow
        $newName = Read-Host "Enter new computer name (or press Enter to cancel)"
        
        if ([string]::IsNullOrWhiteSpace($newName)) {
            Write-Log "Computer name change cancelled" "INFO"
            return
        }
        
        # Validate computer name (basic validation)
        if ($newName.Length -gt 15) {
            Write-Log "Computer name must be 15 characters or less" "ERROR"
            return
        }
        
        if ($newName -match '[^a-zA-Z0-9\-]') {
            Write-Log "Computer name can only contain letters, numbers, and hyphens" "ERROR"
            return
        }
        
        if ($newName -eq $currentName) {
            Write-Log "New name is the same as current name" "INFO"
            return
        }
        
        Write-Log "Changing computer name to '$newName'..."
        
        # Use Rename-Computer cmdlet
        Rename-Computer -NewName $newName -Force
        
        Write-Log "AFTER: Computer name changed to '$newName'" "SUCCESS"
        Write-Log "A system restart is REQUIRED for the name change to take effect!" "WARNING"
        
        $restart = Read-Host "Would you like to restart now? (Y/N)"
        if ($restart -match '^(y|Y)$') {
            Write-Log "Restarting computer in 10 seconds..." "WARNING"
            Write-Host "Restarting in 10 seconds... Press Ctrl+C to cancel" -ForegroundColor Red
            Start-Sleep -Seconds 10
            Restart-Computer -Force
        } else {
            Write-Log "Please restart your computer manually to complete the hostname change" "INFO"
        }
        
    }
    catch {
        Write-Log "Failed to change computer hostname: $($_)" "ERROR"
    }
}

#=============================================================================
# WINDOWS CUSTOMIZATION FUNCTIONS
#=============================================================================

function Enable-ClassicRightClick {
    Write-Log "`n=== Enabling Classic Right-Click Menu ===" "INFO"
    
    try {
        # Check current state
        $regPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
        $currentValue = Get-ItemProperty -Path $regPath -Name "(Default)" -ErrorAction SilentlyContinue
        
        if ($currentValue) {
            Write-Log "Classic right-click menu is already enabled!" "SUCCESS"
            return
        }
        
        Write-Log "Configuring registry for classic context menu..."
        
        if (!(Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        
        # Set the default value to empty string to enable classic menu
        Set-ItemProperty -Path $regPath -Name "(Default)" -Value "" -Force
        
        Write-Log "Classic right-click menu enabled successfully!" "SUCCESS"
        Write-Log "You need to restart Explorer or log off/on for changes to take effect." "INFO"
        
        # Offer to restart Explorer
        $restart = Read-Host "Would you like to restart Explorer now? (Y/N)"
        if ($restart -match '^(y|Y)$') {
            Write-Log "Restarting Explorer..."
            Stop-Process -Name explorer -Force
            Start-Sleep -Seconds 2
            Start-Process explorer
            Write-Log "Explorer restarted successfully!" "SUCCESS"
        }
    }
    catch {
        Write-Log "Failed to enable classic right-click menu: $($_)" "ERROR"
    }
}

function Enable-TaskbarEndTask {
    Write-Log "`n=== Enabling End Task in Taskbar Right-Click ===" "INFO"
    
    try {
        # Registry path for the End Task feature
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        
        # Check if already enabled
        $currentValue = Get-ItemProperty -Path $regPath -Name "TaskbarDeveloperSettings" -ErrorAction SilentlyContinue
        
        if ($currentValue -and $currentValue.TaskbarDeveloperSettings -eq 1) {
            Write-Log "End Task in taskbar is already enabled!" "SUCCESS"
            return
        }
        
        Write-Log "Configuring registry for End Task in taskbar..."
        
        # Enable End Task in taskbar (DWORD value = 1)
        Set-ItemProperty -Path $regPath -Name "TaskbarDeveloperSettings" -Value 1 -Type DWord -Force
        
        Write-Log "End Task in taskbar enabled successfully!" "SUCCESS"
        Write-Log "You need to restart Explorer or log off/on for changes to take effect." "INFO"
        
        # Offer to restart Explorer
        $restart = Read-Host "Would you like to restart Explorer now? (Y/N)"
        if ($restart -match '^(y|Y)$') {
            Write-Log "Restarting Explorer..."
            Stop-Process -Name explorer -Force
            Start-Sleep -Seconds 2
            Start-Process explorer
            Write-Log "Explorer restarted successfully!" "SUCCESS"
        }
    }
    catch {
        Write-Log "Failed to enable End Task in taskbar: $($_)" "ERROR"
    }
}

function Disable-TaskbarEndTask {
    Write-Log "`n=== Disabling End Task in Taskbar Right-Click ===" "INFO"
    
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if(Get-ItemProperty -Path $regPath -Name "TaskbarDeveloperSettings" -ErrorAction SilentlyContinue) {
            Set-ItemProperty -Path $regPath -Name "TaskbarDeveloperSettings" -Value 0 -Type DWord -Force
            Write-Log "'End Task' feature disabled in taskbar right-click." "SUCCESS"
            
            # Offer to restart Explorer
            $restart = Read-Host "Would you like to restart Explorer now? (Y/N)"
            if ($restart -match '^(y|Y)$') {
                Write-Log "Restarting Explorer..."
                Stop-Process -Name explorer -Force
                Start-Sleep -Seconds 2
                Start-Process explorer
                Write-Log "Explorer restarted successfully!" "SUCCESS"
            }
        } else {
            Write-Log "'End Task' feature is already disabled." "INFO"
        }
    }
    catch {
        Write-Log "Failed to disable 'End Task' in taskbar: $($_)" "ERROR"
    }
}

function Disable-FastBoot {
    Write-Log "`n=== Disabling Fast Boot ===" "INFO"
    
    try {
        # Registry path for Fast Boot setting
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
        $regName = "HiberbootEnabled"
        
        # Check current state before making changes
        $currentValue = Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue
        if ($currentValue) {
            if ($currentValue.HiberbootEnabled -eq 0) {
                Write-Log "BEFORE: Fast Boot is already disabled" "INFO"
                Write-Log "Fast Boot is already disabled!" "SUCCESS"
                return
            } else {
                Write-Log "BEFORE: Fast Boot is currently enabled (value: $($currentValue.HiberbootEnabled))" "INFO"
            }
        } else {
            Write-Log "BEFORE: Fast Boot registry value not found (default enabled)" "INFO"
        }
        
        Write-Log "Disabling Fast Boot..."
        
        # Set HiberbootEnabled to 0 to disable Fast Boot
        Set-ItemProperty -Path $regPath -Name $regName -Value 0 -Type DWord -Force
        
        # Verify the change
        $newValue = Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue
        if ($newValue -and $newValue.HiberbootEnabled -eq 0) {
            Write-Log "AFTER: Fast Boot is now disabled (value: $($newValue.HiberbootEnabled))" "SUCCESS"
            Write-Log "Fast Boot disabled successfully!" "SUCCESS"
            Write-Log "A system restart is required for changes to take effect." "WARNING"
        } else {
            Write-Log "Failed to verify Fast Boot disable setting" "ERROR"
        }
    }
    catch {
        Write-Log "Failed to disable Fast Boot: $($_)" "ERROR"
    }
}

function Enable-FastBoot {
    Write-Log "`n=== Enabling Fast Boot ===" "INFO"
    
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
        $regName = "HiberbootEnabled"
        
        Write-Log "Enabling Fast Boot..."
        Set-ItemProperty -Path $regPath -Name $regName -Value 1 -Type DWord -Force
        
        Write-Log "AFTER: Fast Boot is now enabled." "SUCCESS"
        Write-Log "A system restart is required for changes to take effect." "WARNING"
    }
    catch {
        Write-Log "Failed to enable Fast Boot: $($_)" "ERROR"
    }
}

function Disable-ClassicRightClick {
    Write-Log "`n=== Restoring Windows 11 Right-Click Menu ===" "INFO"
    
    try {
        $regPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
        
        if (Test-Path $regPath) {
            Remove-Item -Path $regPath -Recurse -Force
            Write-Log "Windows 11 right-click menu restored successfully!" "SUCCESS"
            Write-Log "You need to restart Explorer or log off/on for changes to take effect." "INFO"
            
            # Offer to restart Explorer
            $restart = Read-Host "Would you like to restart Explorer now? (Y/N)"
            if ($restart -match '^(y|Y)$') {
                Write-Log "Restarting Explorer..."
                Stop-Process -Name explorer -Force
                Start-Sleep -Seconds 2
                Start-Process explorer
                Write-Log "Explorer restarted successfully!" "SUCCESS"
            }
        }
        else {
            Write-Log "Windows 11 right-click menu is already active!" "SUCCESS"
        }
    }
    catch {
        Write-Log "Failed to restore Windows 11 right-click menu: $($_)" "ERROR"
    }
}

#=============================================================================
# BULK OPERATIONS
#=============================================================================

function Update-AllApps {
    Write-Log "`n=== Updating All Applications via Winget ===" "INFO"
    
    if (!$script:WingetInstalled) {
        Write-Log "Winget is not available. Cannot update apps." "ERROR"
        return
    }
    
    try {
        Write-Log "Checking for application updates..."
        winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "All applications updated successfully!" "SUCCESS"
        }
        else {
            Write-Log "Some applications may have failed to update. Check the log for details." "WARNING"
        }
    }
    catch {
        Write-Log "Failed to update applications: $_" "ERROR"
    }
}

function Install-AllApplications {
    Write-Log "`n=== INSTALLING ALL APPLICATIONS ONLY ===" "INFO"
    Write-Log "This will install browsers and essential applications only (no system features or customizations)..." "INFO"
    
    # Install browsers
    Install-ChromeEnterprise
    Install-Firefox
    
    # Install all essential apps
    Install-7Zip
    Install-BCUninstaller
    Install-BulkRenameUtility
    Install-CPUZ
    Install-FileConverter
    Install-Git
    Install-GitExtensions
    Install-GoogleChrome
    Install-Krita
    Install-LogiOptionsPlus
    Install-MozillaFirefox
    Install-NotepadPlusPlus
    Install-OpenSCAD
    Install-VirtualBox
    Install-PeaZip
    Install-PrusaSlicer
    Install-Tabby
    
    Write-Log "`n=== ALL APPLICATIONS INSTALLATION FINISHED ===" "SUCCESS"
}

function Install-Everything {
    Write-Log "`n=== INSTALLING EVERYTHING - ONE-CLICK SETUP ===" "INFO"
    Write-Log "This will install all components and apply optimizations. Please be patient..." "INFO"
    
    # Create system restore point first
    Create-SystemRestorePoint
    
    # Install system features
    Enable-WindowsSandbox
    Enable-HyperV
    Install-WSL2
    
    # Windows customizations
    Enable-ClassicRightClick
    Enable-TaskbarEndTask
    Disable-FastBoot
    
    # Security & Privacy
    Disable-WindowsTelemetry
    Remove-WindowsBloatware
    Disable-Cortana
    Configure-DefenderExclusions
    
    # Performance optimizations
    Set-HighPerformancePower
    Show-FileExtensions
    Show-HiddenFiles
    Configure-TaskbarCustomizations
    
    # Install browsers
    Install-ChromeEnterprise
    Install-Firefox
    
    # Install all essential apps
    Install-7Zip
    Install-BCUninstaller
    Install-BulkRenameUtility
    Install-CPUZ
    Install-FileConverter
    Install-Git
    Install-GitExtensions
    Install-GoogleChrome
    Install-Krita
    Install-LogiOptionsPlus
    Install-MozillaFirefox
    Install-NotepadPlusPlus
    Install-OpenSCAD
    Install-VirtualBox
    Install-PeaZip
    Install-PrusaSlicer
    Install-Tabby
    
    # Development environment
    Install-WindowsTerminal
    Install-PackageManagers
    Setup-DevFolderStructure
    Install-NodeJS
    Install-Python
    Install-Rust
    
    # Network optimizations
    Configure-DNSSettings
    Optimize-NetworkSettings
    
    # Developer setup (Git configuration only, user can manually setup SSH if needed)
    Write-Log "`n=== Setting up Git Configuration ===" "INFO"
    Setup-GitConfiguration
    
    Write-Log "`n=== COMPLETE INSTALLATION FINISHED ===" "SUCCESS"
    Write-Log "Note: A system restart is required to complete the installation of some features." "WARNING"
    Write-Log "Reminder: You can use individual options for SSH keys, domain join, and other specific configurations." "INFO"
}

#=============================================================================
# MENU SYSTEM
#=============================================================================


function Do-MyNewFeature {
    [CmdletBinding()]
    param()
    Write-Log "Starting SSH permissions fix" "INFO"
    try {
        $sshDir = Join-Path $Env:USERPROFILE '.ssh'
        if (-Not (Test-Path $sshDir)) {
            Write-Log "SSH directory not found at $sshDir" "WARNING"
            Write-Host "No SSH directory found for current user. Skipping." -ForegroundColor Yellow
            return
        }
        Write-Log "Setting ACLs on SSH directory: $sshDir" "INFO"
        icacls $sshDir /inheritance:r /grant:r "$Env:USERNAME:(OI)(CI)F" /grant:r "SYSTEM:F" | Out-Null
        Write-Log "Setting ACLs on files within SSH directory" "INFO"
        icacls (Join-Path $sshDir '*') /inheritance:r /grant:r "$Env:USERNAME:F" /grant:r "SYSTEM:F" | Out-Null
        Write-Log "SSH permissions fixed successfully" "SUCCESS"
        Write-Host "SSH directory permissions updated." -ForegroundColor Green
    } catch {
        Write-Log "Error fixing SSH permissions: $_" "ERROR"
        Write-Host "Failed to fix SSH permissions: $_" -ForegroundColor Red
    }
}
function Show-Menu {
    Clear-Host
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "    Windows Post-Installation Setup Script    " -ForegroundColor White
    Write-Host "           Author: Claire R (v2.5.0)          " -ForegroundColor Gray
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "SYSTEM FEATURES:" -ForegroundColor Yellow
    Write-Host " 1.  Enable Windows Sandbox" -ForegroundColor White
    Write-Host " 2.  Enable Hyper-V" -ForegroundColor White
    Write-Host " 3.  Install WSL2 with Ubuntu" -ForegroundColor White
    Write-Host ""
    Write-Host "WINDOWS CUSTOMIZATIONS:" -ForegroundColor Yellow
    Write-Host " 4.  Enable Classic Right-Click Menu (Win10 Style)" -ForegroundColor White
    Write-Host " 5.  Restore Default Right-Click Menu (Win11 Style)" -ForegroundColor Yellow
    Write-Host " 6.  Enable 'End Task' in Taskbar Right-Click" -ForegroundColor White
    Write-Host " 7.  Disable 'End Task' in Taskbar Right-Click" -ForegroundColor Yellow
    Write-Host " 8.  Disable Fast Boot (Recommended)" -ForegroundColor White
    Write-Host " 9.  Enable Fast Boot" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "BROWSERS:" -ForegroundColor Yellow
    Write-Host " 10. Install Chrome Enterprise" -ForegroundColor White
    Write-Host " 11. Install Mozilla Firefox" -ForegroundColor White
    Write-Host ""
    Write-Host "ESSENTIAL APPLICATIONS:" -ForegroundColor Yellow
    Write-Host " 12. Install 7-Zip" -ForegroundColor White
    Write-Host " 13. Install BCUninstaller" -ForegroundColor White
    Write-Host " 14. Install Bulk Rename Utility" -ForegroundColor White
    Write-Host " 15. Install CPU-Z" -ForegroundColor White
    Write-Host " 16. Install File Converter" -ForegroundColor White
    Write-Host " 17. Install Git" -ForegroundColor White
    Write-Host " 18. Install Git Extensions" -ForegroundColor White
    Write-Host " 19. Install Google Chrome" -ForegroundColor White
    Write-Host " 20. Install Krita" -ForegroundColor White
    Write-Host " 21. Install Logi Options+" -ForegroundColor White
    Write-Host " 22. Install Mozilla Firefox" -ForegroundColor White
    Write-Host " 23. Install Notepad++" -ForegroundColor White
    Write-Host " 24. Install OpenSCAD" -ForegroundColor White
    Write-Host " 25. Install VirtualBox" -ForegroundColor White
    Write-Host " 26. Install PeaZip" -ForegroundColor White
    Write-Host " 27. Install PrusaSlicer" -ForegroundColor White
    Write-Host " 28. Install Tabby" -ForegroundColor White
    Write-Host ""
    Write-Host "DEVELOPER SETUP:" -ForegroundColor Magenta
    Write-Host " 29. Setup SSH Key + Git Configuration" -ForegroundColor White
    Write-Host " 30. Setup Git Only (no SSH key)" -ForegroundColor White
    Write-Host " 31. Set Computer Hostname" -ForegroundColor White
    Write-Host ""
    Write-Host "SECURITY & PRIVACY:" -ForegroundColor Red
    Write-Host " 32. Disable Windows Telemetry" -ForegroundColor White
    Write-Host " 33. Restore Default Telemetry Settings" -ForegroundColor Yellow
    Write-Host " 34. Remove Windows Bloatware" -ForegroundColor White
    Write-Host " 35. Disable Cortana" -ForegroundColor White
    Write-Host " 36. Enable Cortana" -ForegroundColor Yellow
    Write-Host " 37. Add Dev Folders to Defender Exclusions" -ForegroundColor White
    Write-Host " 38. Remove Dev Folders from Defender Exclusions" -ForegroundColor Yellow
    Write-Host " 39. Disable Windows Update Auto-Restart" -ForegroundColor White
    Write-Host " 40. Enable Windows Update Auto-Restart" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "PERFORMANCE & SYSTEM:" -ForegroundColor Blue
    Write-Host " 41. Set High Performance Power Plan" -ForegroundColor White
    Write-Host " 42. Set Balanced Power Plan (Default)" -ForegroundColor Yellow
    Write-Host " 43. Disable Visual Effects (for Performance)" -ForegroundColor White
    Write-Host " 44. Enable Visual Effects (for Appearance)" -ForegroundColor Yellow
    Write-Host " 45. Configure Virtual Memory (Guidance)" -ForegroundColor White
    Write-Host " 46. System Cleanup" -ForegroundColor White
    Write-Host " 47. Manage Startup Programs (Guidance)" -ForegroundColor White
    Write-Host ""
    Write-Host "DEVELOPMENT ENVIRONMENT:" -ForegroundColor DarkMagenta
    Write-Host " 48. Install Windows Terminal" -ForegroundColor White
    Write-Host " 49. Install Package Managers (Chocolatey/Scoop)" -ForegroundColor White
    Write-Host " 50. Install Docker Desktop" -ForegroundColor White
    Write-Host " 51. Setup Dev Folder Structure" -ForegroundColor White
    Write-Host " 52. Install Node.js" -ForegroundColor White
    Write-Host " 53. Install Python" -ForegroundColor White
    Write-Host " 54. Install Rust" -ForegroundColor White
    Write-Host ""
    Write-Host "NETWORK & CONNECTIVITY:" -ForegroundColor DarkCyan
    Write-Host " 55. Configure DNS Settings" -ForegroundColor White
    Write-Host " 56. Enable SSH Server" -ForegroundColor White
    Write-Host " 57. Configure Remote Desktop" -ForegroundColor White
    Write-Host " 58. Optimize Network Settings" -ForegroundColor White
    Write-Host ""
    Write-Host "FILE SYSTEM & UI:" -ForegroundColor DarkYellow
    Write-Host " 59. Show File Extensions" -ForegroundColor White
    Write-Host " 60. Hide File Extensions (Default)" -ForegroundColor Yellow
    Write-Host " 61. Show Hidden Files" -ForegroundColor White
    Write-Host " 62. Hide Hidden Files (Default)" -ForegroundColor Yellow
    Write-Host " 63. Configure Dark/Light Mode" -ForegroundColor White
    Write-Host " 64. Set Default Apps (Opens Settings)" -ForegroundColor White
    Write-Host " 65. Apply Taskbar Customizations" -ForegroundColor White
    Write-Host " 66. Restore Default Taskbar" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "BACKUP & RECOVERY:" -ForegroundColor DarkGreen
    Write-Host " 67. Create System Restore Point" -ForegroundColor White
    Write-Host " 68. Export Installed Programs List" -ForegroundColor White
    Write-Host " 69. Configure Windows Backup (Opens Settings)" -ForegroundColor White
    Write-Host " 70. Backup All Drivers to Desktop" -ForegroundColor White
    Write-Host " 71. Restore Drivers from ZIP Backup" -ForegroundColor White
    Write-Host ""
    Write-Host "ENTERPRISE/PROFESSIONAL:" -ForegroundColor Gray
    Write-Host " 72. Domain Join Assistant" -ForegroundColor White
    Write-Host " 73. Configure Proxy Settings" -ForegroundColor White
    Write-Host " 74. Install Certificates (Guidance)" -ForegroundColor White
    Write-Host " 75. Configure Group Policies (Opens gpedit.msc)" -ForegroundColor White
    Write-Host ""
    Write-Host "BULK OPERATIONS:" -ForegroundColor Green
    Write-Host " 76. Update All Installed Apps via Winget" -ForegroundColor White
    Write-Host " 77. Install All Applications Only" -ForegroundColor White
    Write-Host ""
    Write-Host " 999. INSTALL EVERYTHING (One-Click Setup)" -ForegroundColor Magenta
    Write-Host ""
        Write-Host " 101. Fix SSH Directory Permissions" -ForegroundColor White
    Write-Host " 100. Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "Log file: $script:LogPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Enter your choice:" -ForegroundColor Yellow
}

function Start-MainMenu {
    # Initial setup
    Write-Log "Windows Post-Installation Setup Script Started" "INFO"
    Write-Log "Checking for winget..." "INFO"
    Test-WingetInstalled | Out-Null
    
    do {
        Show-Menu
        $choice = Read-Host
        
        # Handle empty input (just Enter key) - exit script
        if ([string]::IsNullOrWhiteSpace($choice)) {
            Write-Log "No option selected, exiting script..." "INFO"
            $choice = "100" # Set choice to exit value
        }
        
        switch ($choice) {
            # SYSTEM FEATURES (1-3)
            "1"  { Enable-WindowsSandbox; Pause }
            "2"  { Enable-HyperV; Pause }
            "3"  { Install-WSL2; Pause }
            
            # WINDOWS CUSTOMIZATIONS (4-9)
            "4"  { Enable-ClassicRightClick; Pause }
            "5"  { Disable-ClassicRightClick; Pause }
            "6"  { Enable-TaskbarEndTask; Pause }
            "7"  { Disable-TaskbarEndTask; Pause }
            "8"  { Disable-FastBoot; Pause }
            "9"  { Enable-FastBoot; Pause }
            
            # BROWSERS (10-11)
            "10" { Install-ChromeEnterprise; Pause }
            "11" { Install-Firefox; Pause }
            
            # ESSENTIAL APPLICATIONS (12-28)
            "12" { Install-7Zip; Pause }
            "13" { Install-BCUninstaller; Pause }
            "14" { Install-BulkRenameUtility; Pause }
            "15" { Install-CPUZ; Pause }
            "16" { Install-FileConverter; Pause }
            "17" { Install-Git; Pause }
            "18" { Install-GitExtensions; Pause }
            "19" { Install-GoogleChrome; Pause }
            "20" { Install-Krita; Pause }
            "21" { Install-LogiOptionsPlus; Pause }
            "22" { Install-MozillaFirefox; Pause }
            "23" { Install-NotepadPlusPlus; Pause }
            "24" { Install-OpenSCAD; Pause }
            "25" { Install-VirtualBox; Pause }
            "26" { Install-PeaZip; Pause }
            "27" { Install-PrusaSlicer; Pause }
            "28" { Install-Tabby; Pause }
            
            # DEVELOPER SETUP (29-31)
            "29" { Setup-SSHKeyAndGit; Pause }
            "30" { Setup-GitOnly; Pause }
            "31" { Set-ComputerHostname; Pause }
            
            # SECURITY & PRIVACY (32-40)
            "32" { Disable-WindowsTelemetry; Pause }
            "33" { Restore-DefaultTelemetry; Pause }
            "34" { Remove-WindowsBloatware; Pause }
            "35" { Disable-Cortana; Pause }
            "36" { Enable-Cortana; Pause }
            "37" { Configure-DefenderExclusions; Pause }
            "38" { Remove-DefenderExclusions; Pause }
            "39" { Disable-WindowsUpdateAutoRestart; Pause }
            "40" { Enable-WindowsUpdateAutoRestart; Pause }
            
            # PERFORMANCE & SYSTEM (41-47)
            "41" { Set-HighPerformancePower; Pause }
            "42" { Set-BalancedPower; Pause }
            "43" { Disable-VisualEffects; Pause }
            "44" { Enable-VisualEffects; Pause }
            "45" { Configure-VirtualMemory; Pause }
            "46" { Invoke-SystemCleanup; Pause }
            "47" { Disable-StartupPrograms; Pause }
            
            # DEVELOPMENT ENVIRONMENT (48-54)
            "48" { Install-WindowsTerminal; Pause }
            "49" { Install-PackageManagers; Pause }
            "50" { Install-DockerDesktop; Pause }
            "51" { Setup-DevFolderStructure; Pause }
            "52" { Install-NodeJS; Pause }
            "53" { Install-Python; Pause }
            "54" { Install-Rust; Pause }
            
            # NETWORK & CONNECTIVITY (55-58)
            "55" { Configure-DNSSettings; Pause }
            "56" { Enable-SSHServer; Pause }
            "57" { Configure-RemoteDesktop; Pause }
            "58" { Optimize-NetworkSettings; Pause }
            
            # FILE SYSTEM & UI (59-66)
            "59" { Show-FileExtensions; Pause }
            "60" { Hide-FileExtensions; Pause }
            "61" { Show-HiddenFiles; Pause }
            "62" { Hide-HiddenFiles; Pause }
            "63" { Configure-DarkMode; Pause }
            "64" { Set-DefaultApps; Pause }
            "65" { Configure-TaskbarCustomizations; Pause }
            "66" { Restore-DefaultTaskbar; Pause }
            
            # BACKUP & RECOVERY (67-71)
            "67" { Create-SystemRestorePoint; Pause }
            "68" { Export-InstalledPrograms; Pause }
            "69" { Configure-WindowsBackup; Pause }
            "70" { Backup-Drivers; Pause }
            "71" { Restore-Drivers; Pause }
            
            # ENTERPRISE/PROFESSIONAL (72-75)
            "72" { Configure-DomainJoin; Pause }
            "73" { Configure-ProxySettings; Pause }
            "74" { Install-Certificates; Pause }
            "75" { Configure-GroupPolicies; Pause }
            
            # BULK OPERATIONS (76-77)
            "76" { Update-AllApps; Pause }
            "77" { 
                $confirm = Read-Host "This will install all applications only (no system features). Continue? (Y/N)"
                if ($confirm -match '^(y|Y)$') {
                    Install-AllApplications
                }
                Pause
            }
            
            # EXIT (100)
            "100" { 
                Write-Log "Exiting script..." "INFO"
                break 
            }
            
            # INSTALL EVERYTHING (999)
            "999" { 
                Write-Host ""
                Write-Host "⚠️  WARNING: This will install EVERYTHING! ⚠️" -ForegroundColor Red
                Write-Host "This includes all features, apps, optimizations, and security settings." -ForegroundColor Yellow
                Write-Host "This process will take a significant amount of time." -ForegroundColor Yellow
                Write-Host ""
                $confirm = Read-Host "Are you absolutely sure you want to proceed? Type 'YES' to continue"
                if ($confirm -eq "YES") {
                    Install-Everything
                } else {
                    Write-Log "Install Everything cancelled by user" "INFO"
                }
                Pause
            }
            
            default { 
                Write-Host "Invalid choice. Please select a valid option or 100 to exit." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($choice -ne "100")
}

function Pause {
    Write-Host ""
    Write-Host "Press any key to return to menu..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

#=============================================================================
# CLEANUP FUNCTION
#=============================================================================

function Cleanup-TempFiles {
    Write-Log "Cleaning up temporary files..." "INFO"
    
    try {
        if (Test-Path $script:TempPath) {
            Remove-Item -Path $script:TempPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Temporary files cleaned up successfully." "SUCCESS"
        }
    }
    catch {
        Write-Log "Failed to clean up some temporary files: $_" "WARNING"
    }
}

#=============================================================================
# MAIN EXECUTION
#=============================================================================

try {
    # Start the main menu
    Start-MainMenu
}
catch {
    Write-Log "An unexpected error occurred: $_" "ERROR"
}
finally {
    # Always cleanup
    Cleanup-TempFiles
    
    Write-Log "Script execution completed." "INFO"
    Write-Host ""
    Write-Host "Script finished. Log saved to: $script:LogPath" -ForegroundColor Green
    Write-Host "Thank you for using the Windows Post-Installation Setup Script!" -ForegroundColor Cyan
    Start-Sleep -Seconds 3
}