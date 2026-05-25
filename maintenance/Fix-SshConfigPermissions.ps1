<# 
Fix-SshConfigPermissions.ps1

Locks down the .ssh folder, config file, and private keys so that
Windows OpenSSH no longer complains about "Bad permissions".

Run as your normal user (not elevated).  Uses only standard icacls
flags available on Windows 10/11.

Permissions applied
-------------------
Folder          : Full control for current user, Administrators, SYSTEM
config file     : Modify for current user, Full for Administrators & SYSTEM
private key(s)  : Modify for current user, Full for Administrators & SYSTEM
#>

# ----------------------------- VARIABLES -----------------------------
$sshDir  = "$HOME\.ssh"
$cfgFile = Join-Path $sshDir 'config'

# --------------------------- VALIDATION ------------------------------
Write-Host "[*] Checking if .ssh exists..."
if (-not (Test-Path $sshDir)) {
    Write-Error "The folder $sshDir does not exist. Aborting."
    exit 1
}

# Helper function to run icacls and show errors if any
function Invoke-Icacls {
    param (
        [string]$Target,
        [string[]]$Args
    )
    $cmd = @('icacls', $Target) + $Args
    $process = Start-Process -FilePath $cmd[0] -ArgumentList $cmd[1..($cmd.Length-1)] -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Warning "icacls exited with code $($process.ExitCode) for $Target"
    }
}

# ---------------------------------------------------------------
# Take ownership and set ACLs on the folder
# ---------------------------------------------------------------
Write-Host "[*] Taking ownership and locking down folder..."
takeown /f $sshDir | Out-Null

Invoke-Icacls -Target $sshDir -Args @(
    '/inheritance:r',
    '/remove', '"Authenticated Users"', '"Users"', '"Everyone"',
    '/grant:r', "$env:USERNAME:F",
    '/grant:r', 'Administrators:F',
    '/grant:r', 'SYSTEM:F'
)

# ---------------------------------------------------------------
# Lock down the config file (if present)
# ---------------------------------------------------------------
if (Test-Path $cfgFile) {
    Write-Host "[*] Locking down config file..."
    takeown /f $cfgFile | Out-Null

    Invoke-Icacls -Target $cfgFile -Args @(
        '/inheritance:r',
        '/remove', '"Authenticated Users"', '"Users"', '"Everyone"',
        '/grant:r', "$env:USERNAME:M",
        '/grant:r', 'Administrators:F',
        '/grant:r', 'SYSTEM:F'
    )
} else {
    Write-Host "[*] No config file found. Skipping..."
}

# ---------------------------------------------------------------
# Lock down private key files
# ---------------------------------------------------------------
$privateKeys = Get-ChildItem $sshDir -File | Where-Object {
    $_.Name -match '^(id_rsa|id_ed25519|id_ecdsa|id_dsa)$'
}

foreach ($key in $privateKeys) {
    Write-Host "[*] Locking down key: $($key.Name)"
    takeown /f $key.FullName | Out-Null

    Invoke-Icacls -Target $key.FullName -Args @(
        '/inheritance:r',
        '/remove', '"Authenticated Users"', '"Users"', '"Everyone"',
        '/grant:r', "$env:USERNAME:M",
        '/grant:r', 'Administrators:F',
        '/grant:r', 'SYSTEM:F'
    )
}

Write-Host "[OK] Permission fix complete. Try your SSH command again."
