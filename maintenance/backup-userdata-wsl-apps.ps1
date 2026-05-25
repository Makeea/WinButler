# Backup user data, WSL distros, and selected apps: Firefox, Chrome, Notepad++

$date = Get-Date -Format "yyyy-MM-dd"
$desktop = [Environment]::GetFolderPath("Desktop")
$backupRoot = "$desktop\UserDataBackup-$date"
New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null

# Known system folders and patterns to exclude
$excludedNames = @(
    'AppData\LocalLow\Microsoft\Windows',
    'AppData\Local\Microsoft\Windows',
    'AppData\Local\Temp',
    'AppData\Roaming\Microsoft\Windows',
    'AppData\Local\Packages',
    'AppData\Local\ConnectedDevicesPlatform',
    'AppData\Local\CrashDumps',
    'AppData\Local\Comms',
    'AppData\Roaming\Identities',
    'AppData\Local\Microsoft\OneDrive',
    'AppData\Local\MicrosoftEdge'
)
$excludedPatterns = @('NTUSER.*', '*.tmp', '*.log', '*.etl')

$users = Get-ChildItem -Path "C:\Users" -Directory | Where-Object {
    -not ($_ .Name -in @('Public', 'Default', 'Default User', 'All Users'))
}

foreach ($user in $users) {
    $userName = $user.Name
    $userProfile = $user.FullName
    $destRoot = Join-Path $backupRoot $userName

    Write-Host "Backing up profile: $userName"

    # Backup general user files
    Get-ChildItem -Path $userProfile -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
        -not ($_.Attributes -band [System.IO.FileAttributes]::System) -and
        ($excludedNames | Where-Object { $_ -in $_.FullName }) -eq $null -and
        ($excludedPatterns | Where-Object { $_ -like $_.Name }) -eq $null
    } | ForEach-Object {
        $relativePath = $_.FullName.Substring($userProfile.Length).TrimStart('\')
        $destinationPath = Join-Path $destRoot $relativePath
        $destinationDir = Split-Path $destinationPath -Parent

        if (-not (Test-Path $destinationDir)) {
            New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
        }

        if (-not $_.PSIsContainer) {
            Copy-Item -Path $_.FullName -Destination $destinationPath -Force -ErrorAction SilentlyContinue
        }
    }

    # Backup Firefox profiles
    $ffProfile = "$userProfile\AppData\Roaming\Mozilla"
    if (Test-Path $ffProfile) {
        $ffDest = Join-Path $backupRoot "$userName-Firefox"
        Copy-Item -Path $ffProfile -Destination $ffDest -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✔ Firefox backed up for $userName"
    }

    # Backup Chrome profiles
    $chromeProfile = "$userProfile\AppData\Local\Google\Chrome"
    if (Test-Path $chromeProfile) {
        $chromeDest = Join-Path $backupRoot "$userName-Chrome"
        Copy-Item -Path $chromeProfile -Destination $chromeDest -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✔ Chrome backed up for $userName"
    }

    # Backup Notepad++ config (AppData)
    $npProfile = "$userProfile\AppData\Roaming\Notepad++"
    if (Test-Path $npProfile) {
        $npDest = Join-Path $backupRoot "$userName-Notepad++"
        Copy-Item -Path $npProfile -Destination $npDest -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✔ Notepad++ (Roaming) backed up for $userName"
    }

    # Backup Notepad++ if installed in Program Files or portable
    $nppInstalledPaths = @(
        "$userProfile\Downloads\Notepad++",
        "C:\Program Files\Notepad++",
        "C:\Program Files (x86)\Notepad++"
    )
    foreach ($path in $nppInstalledPaths) {
        if (Test-Path $path) {
            $nppDest = Join-Path $backupRoot "$userName-Notepad++-Installed"
            Copy-Item -Path $path -Destination $nppDest -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "✔ Notepad++ install backed up for $userName"
            break
        }
    }

    Write-Host "✔ Finished backing up $userName`n"
}

# WSL Backup
Write-Host "Checking for WSL distros..."

$wslList = wsl --list --quiet 2>$null
if ($wslList) {
    $wslBackupRoot = Join-Path $backupRoot "WSL"
    New-Item -Path $wslBackupRoot -ItemType Directory -Force | Out-Null

    foreach ($distro in $wslList) {
        $safeName = $distro -replace '[^\w\-]', '_'
        $outputPath = Join-Path $wslBackupRoot "$safeName.tar"
        Write-Host "Backing up WSL distro: $distro"
        wsl --export "$distro" "$outputPath"
    }

    Write-Host "`n✔ WSL backups saved to: $wslBackupRoot"
} else {
    Write-Host "⚠ No WSL distributions found."
}

# All done
Write-Host "`n✅ Full backup complete! Files saved to: $backupRoot"
