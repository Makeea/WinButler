# Script Description: Retrieves system information, the Windows product key (may not work reliably), and Wi-Fi information for all network profiles (for Windows 10 and 11) using PowerShell. It saves the information to separate text files in a folder named "System Information" on the desktop.

# Define the path to save the text files in the "System Information" folder on the desktop
$desktopPath = [System.Environment]::GetFolderPath('Desktop')
$systemInfoFolderPath = Join-Path -Path $desktopPath -ChildPath 'System Information'

# Create the "System Information" folder if it doesn't exist
if (-not (Test-Path -Path $systemInfoFolderPath -PathType Container)) {
    New-Item -Path $systemInfoFolderPath -ItemType Directory
}

# Function to get a list of installed programs
function Get-InstalledPrograms {
    return Get-WmiObject -Class Win32_Product | Select-Object -ExpandProperty Name
}

# Function to get the Windows product key (may not work reliably)
function Get-WindowsProductKey {
    $productKey = (Get-WmiObject -Query "SELECT * FROM SoftwareLicensingService").OA3xOriginalProductKey
    return $productKey
}

# Function to get Wi-Fi information for all network profiles (for Windows 10 and 11)
function Get-WiFiInformation {
    $wifiProfiles = (netsh wlan show profiles | Select-String -Pattern "All User Profile" | ForEach-Object { $_.ToString() -replace '.*:\s' })
    $wifiInfoData = @{}
    foreach ($wifiProfile in $wifiProfiles) {
        $wifiInfo = (netsh wlan show profile name="$wifiProfile" key=clear)
        if ($wifiInfo) {
            $wifiInfoData[$wifiProfile] = $wifiInfo
        } else {
            $wifiInfoData[$wifiProfile] = "No information found for this Wi-Fi profile."
        }
    }
    return $wifiInfoData
}

# Get hostname
$hostname = hostname
$hostname | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath 'hostname.txt')

# Get system uptime
$uptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$uptime = (Get-Date) - $uptime
$uptimeString = $uptime.Days.ToString() + ' days, ' + $uptime.Hours.ToString() + ' hours'
$uptimeString | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath 'uptime.txt')

# Get operating system version
$osVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
$osVersion | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath 'os_version.txt')

# Get network information
$networkInfo = Get-NetIPConfiguration
$networkInfo | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath 'network_info.txt')

# Get time zone information
$timeZone = (Get-TimeZone).Id
$timeZone | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath 'time_zone.txt')

# Get a list of installed programs
$installedPrograms = Get-InstalledPrograms
$installedPrograms | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath 'installed_programs.txt')

# Get the Windows product key (may not work reliably)
$productKey = Get-WindowsProductKey
if ($productKey -ne $null) {
    $productKey | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath 'windows_product_key.txt')
    Write-Host "Windows product key saved to 'windows_product_key.txt' in the 'System Information' folder on the desktop."
} else {
    Write-Host "No Windows product key found (may not work reliably)."
}

# Get Wi-Fi information for all network profiles (for Windows 10 and 11)
$wifiInfoData = Get-WiFiInformation
foreach ($wifiProfile in $wifiInfoData.Keys) {
    $wifiInfoData[$wifiProfile] | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath "${wifiProfile}_wifi_info.txt")
}
Write-Host "Wi-Fi information saved to individual text files in the 'System Information' folder on the desktop."

# Display a message indicating the file locations
Write-Host "System information saved to the 'System Information' folder on the desktop."

# Script finished
Write-Host "Script completed successfully."
