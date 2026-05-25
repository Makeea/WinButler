$LogPath = "$env:USERPROFILE\scripts\logs\winget-update-machine.log"
New-Item -ItemType Directory -Force -Path (Split-Path $LogPath) | Out-Null
"==== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') Winget MACHINE run (SYSTEM) ====" | Out-File $LogPath -Append -Encoding utf8

$winget = Get-ChildItem "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_*__8wekyb3d8bbwe\winget.exe" -ErrorAction SilentlyContinue |
          Sort-Object FullName -Descending |
          Select-Object -First 1

if (-not $winget) {
  "ERROR: winget.exe not found under WindowsApps. Install 'App Installer' for the machine." | Out-File $LogPath -Append -Encoding utf8
  exit 1
}

# Machine scope
& $winget.FullName upgrade --all --scope machine --silent --force `
  --accept-package-agreements --accept-source-agreements --disable-interactivity --include-unknown *>> $LogPath

exit $LASTEXITCODE