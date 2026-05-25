$LogPath = "$env:USERPROFILE\scripts\logs\winget-update.log"

# Ensure log folder exists
New-Item -ItemType Directory -Force -Path (Split-Path $LogPath) | Out-Null

"==== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') Winget update run (SYSTEM) ====" |
Out-File -FilePath $LogPath -Append -Encoding utf8

# Find winget.exe (SYSTEM-safe). Prefer DesktopAppInstaller package location.
$winget = Get-ChildItem "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_*__8wekyb3d8bbwe\winget.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        Select-Object -First 1

if (-not $winget) {
"ERROR: winget.exe not found under WindowsApps. Is 'App Installer' installed for the machine?" |
    Out-File -FilePath $LogPath -Append -Encoding utf8
exit 1
}

# Run upgrades. (SYSTEM will mainly affect machine-scope installs.)
& $winget.FullName upgrade --all --silent --force `
  --accept-package-agreements --accept-source-agreements --disable-interactivity --include-unknown *>> $LogPath

# Optional: propagate winget exit code for task history
exit $LASTEXITCODE