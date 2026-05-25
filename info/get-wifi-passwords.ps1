<#
.SYNOPSIS
Retrieves saved Wi-Fi passwords on Windows 10 and Windows 11 and saves them to a text file on the desktop.

.DESCRIPTION
This script retrieves saved Wi-Fi passwords for all profiles and saves them to a text file named 'wifi_passwords.txt' in the 'System Information' folder on the desktop.

.AUTHOR
Author: Claire Rosario
Website: Rosario.one
This exports to a folder called System info on your desktop
#>

# Function to get saved Wi-Fi passwords
function Get-WifiPasswords {
    $wifiProfiles = (netsh wlan show profiles) | Select-String "All User Profile" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }
    $wifiPasswords = @{}
    foreach ($profile in $wifiProfiles) {
        $password = (netsh wlan show profile name="$profile" key=clear) | Select-String "Key Content"
        if ($password) {
            $wifiPasswords[$profile] = $password.ToString().Split(":")[1].Trim()
        }
    }
    return $wifiPasswords
}

# Get saved Wi-Fi passwords
$wifiPasswords = Get-WifiPasswords

# Define the path to save the text file in the "System Information" folder on the desktop
$desktopPath = [System.Environment]::GetFolderPath('Desktop')
$systemInfoFolderPath = Join-Path -Path $desktopPath -ChildPath 'System Information'

# Create the "System Information" folder if it doesn't exist
if (-not (Test-Path -Path $systemInfoFolderPath -PathType Container)) {
    New-Item -Path $systemInfoFolderPath -ItemType Directory
}

# Save the Wi-Fi passwords to a text file
$wifiPasswords | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath 'wifi_passwords.txt')

# Display a message indicating the file location
Write-Host "Saved Wi-Fi passwords to 'wifi_passwords.txt' in the 'System Information' folder on the desktop."
