$LogPath = "$env:USERPROFILE\scripts\logs\winget-update-user-$env:USERNAME.log"
New-Item -ItemType Directory -Force -Path (Split-Path $LogPath) | Out-Null
"==== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') Winget USER run ($env:USERNAME) ====" | Out-File $LogPath -Append -Encoding utf8

# In user context, winget is usually available via WindowsApps alias; fall back if needed
$winget = (Get-Command winget.exe -ErrorAction SilentlyContinue)?.Source
if (-not $winget) { $winget = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\winget.exe" }

if (-not (Test-Path $winget)) {
  "ERROR: winget.exe not found for user $env:USERNAME. Install/update 'App Installer' for this user." |
    Out-File $LogPath -Append -Encoding utf8
  exit 1
}

# User scope
& $winget upgrade --all --scope user --silent --force `
  --accept-package-agreements --accept-source-agreements --disable-interactivity --include-unknown *>> $LogPath

exit $LASTEXITCODE