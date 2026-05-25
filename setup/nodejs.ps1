<#
.SYNOPSIS
	Installs the latest LTS version of Node.js (x64) on Windows.

.DESCRIPTION
	Downloads and installs Node.js silently from the official source, with logging and verification.

.NOTES
	Author: Claire Rosario
	Date Created: 2025-07-10
	Version: 1.4
	Last Updated: 2025-07-10
	Changelog:
	- v1.0: Initial release
	- v1.1: Added fallback paths and elevation check
	- v1.2: Fixed node detection and error handling
	- v1.3: Admin logic corrected for Terminal/Windows quirks
	- v1.4: Final stable release for Windows x64

.EMAIL
	claire@users.noreply.github.com
.GITHUB
	https://github.com/Makeea
#>

# === Setup Logging ===
$log_dir = "logs"
$log_file = "$log_dir\install-nodejs.log"
if (-not (Test-Path $log_dir)) {
	New-Item -ItemType Directory -Path $log_dir | Out-Null
}
Start-Transcript -Path $log_file -Append

# === Bulletproof Admin Check ===
function Test-IsAdmin {
	$current_user = [Security.Principal.WindowsIdentity]::GetCurrent()
	$principal = New-Object Security.Principal.WindowsPrincipal($current_user)
	return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
	Write-Error "You must run this script as Administrator."
	Stop-Transcript
	exit 1
}

# === Check if Node.js Already Installed ===
Write-Host "`n[+] Checking if Node.js is already installed..." -ForegroundColor Cyan
try {
	$node_cmd = Get-Command node -ErrorAction Stop
	$version = & $node_cmd.Source -v
	Write-Host "[!] Node.js is already installed. Version: $version" -ForegroundColor Yellow
	Stop-Transcript
	exit 0
} catch {
	Write-Host "[+] Node.js not found. Proceeding with installation..." -ForegroundColor Cyan
}

# === Fetch Latest LTS Version ===
Write-Host "`n[+] Fetching latest Node.js LTS version..." -ForegroundColor Cyan
try {
	$lts_json = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json"
	$lts_release = $lts_json | Where-Object { $_.lts } | Select-Object -First 1
	$version = $lts_release.version
} catch {
	Write-Error "Could not fetch Node.js version metadata."
	Stop-Transcript
	exit 1
}
Write-Host "[+] Latest LTS version: $version" -ForegroundColor Green

# === Build Download URL for x64 Windows MSI ===
$installer_url = "https://nodejs.org/dist/$version/node-$version-x64.msi"
$installer_path = "$env:TEMP\node-$version-x64.msi"

# === Download MSI Installer ===
Write-Host "[+] Downloading installer from: $installer_url" -ForegroundColor Cyan
try {
	Invoke-WebRequest -Uri $installer_url -OutFile $installer_path -UseBasicParsing
} catch {
	Write-Error "Failed to download Node.js MSI from $installer_url"
	Stop-Transcript
	exit 1
}

# === Run Silent Installer ===
Write-Host "[+] Running silent install via msiexec..." -ForegroundColor Cyan
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installer_path`" /quiet /norestart" -Wait
Start-Sleep -Seconds 5

# === Detect Installed Node.js Location ===
$possible_paths = @(
	"$env:ProgramFiles\nodejs\node.exe",
	"$env:ProgramFiles(x86)\nodejs\node.exe",
	"$env:LOCALAPPDATA\Programs\nodejs\node.exe"
)
$node_exe = $possible_paths | Where-Object { Test-Path $_ } | Select-Object -First 1

# === Verify Node.js Installation ===
if ($node_exe) {
	$env:Path += ";" + (Split-Path $node_exe)
	$node_version = & "$node_exe" -v
	Write-Host "[+] Node.js installed successfully. Version: $node_version" -ForegroundColor Green
} else {
	Write-Error "Node.js was not found after installation. Something went wrong."
	Stop-Transcript
	exit 1
}

# === Cleanup ===
Remove-Item $installer_path -Force -ErrorAction SilentlyContinue
Stop-Transcript
