# To allow this script to run, set execution policy for your user:
# Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# ============================
# Driver Backup/Restore Tool - ZIP Only + Skip Existing Drivers
# ============================

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "This script needs Administrator privileges. Relaunch as Admin and try again."
    exit
}

# Setup paths
$date = Get-Date -Format "yyyy-MM-dd"
$desktop = [Environment]::GetFolderPath("Desktop")
$backupFolder = "$desktop\DriverBackup-$date"
$zipFile = "$desktop\DriverBackup-$date.zip"

# Main menu
Write-Host "`n=== DRIVER BACKUP TOOL ==="
Write-Host "1. Backup ALL installed drivers"
Write-Host "2. Restore drivers from ZIP only (skip existing)"
$choice = Read-Host "Choose an option (1 or 2)"

# ============================
# BACKUP MODE
# ============================
if ($choice -eq "1") {
    Write-Host "`n[!] Backing up ALL installed drivers..."

    New-Item -Path $backupFolder -ItemType Directory -Force | Out-Null

    try {
        Export-WindowsDriver -Online -Destination $backupFolder -ErrorAction Stop
        Write-Host "`n✔ Drivers exported to: $backupFolder"
    } catch {
        Write-Warning "❌ Failed to export drivers: $_"
        exit
    }

    $zipChoice = Read-Host "Do you want to compress the backup into a .zip file? (y/N)"
    if ($zipChoice -match '^(y|Y)$') {
        try {
            Compress-Archive -Path "$backupFolder\*" -DestinationPath $zipFile -Force
            Write-Host "✔ ZIP created at: $zipFile"
        } catch {
            Write-Warning "❌ Failed to compress backup: $_"
        }
    } else {
        Write-Host "Skipping ZIP compression."
    }

    Write-Host "`n✅ Driver backup complete!"
}

# ============================
# RESTORE MODE (ZIP ONLY + SKIP INSTALLED)
# ============================
elseif ($choice -eq "2") {
    Add-Type -AssemblyName System.Windows.Forms

    # ZIP file picker
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Select driver backup ZIP file"
    $dialog.Filter = "ZIP files (*.zip)|*.zip"
    $dialog.Multiselect = $false

    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host "No ZIP file selected. Aborting."
        exit
    }

    $zipPath = $dialog.FileName

    if (-not (Test-Path $zipPath)) {
        Write-Warning "Selected file doesn't exist. Aborting."
        exit
    }

    # Extract ZIP to temp folder
    $tempPath = Join-Path $env:TEMP "DriverRestore-$date"
    Write-Host "Extracting ZIP to temporary folder: $tempPath"
    try {
        Expand-Archive -Path $zipPath -DestinationPath $tempPath -Force
    } catch {
        Write-Warning "❌ Failed to extract ZIP file: $_"
        exit
    }

    # Get installed driver INF names
    Write-Host "Scanning installed drivers..."
    $installedDrivers = pnputil /enum-drivers | Select-String "Published Name" | ForEach-Object {
        ($_ -split ":\s+")[1].Trim().ToLower()
    }

    # Find and install .inf drivers from extracted content
    $driverFiles = Get-ChildItem -Path $tempPath -Recurse -Include *.inf
    if ($driverFiles.Count -eq 0) {
        Write-Warning "No .inf files found in the extracted ZIP. Aborting."
        exit
    }

    foreach ($file in $driverFiles) {
        $infName = Split-Path $file.FullName -Leaf

        if ($installedDrivers -contains $infName.ToLower()) {
            Write-Host "Skipping already installed driver: $infName"
            continue
        }

        Write-Host "Installing: $($file.FullName)"
        try {
            pnputil /add-driver "$($file.FullName)" /install
        } catch {
            Write-Warning "❌ Failed to install: $($file.FullName)"
        }
    }

    Write-Host "`n✅ Driver restore complete!"
}

# ============================
# INVALID OPTION
# ============================
else {
    Write-Warning "Invalid option. Please run the script again and choose 1 or 2."
}
