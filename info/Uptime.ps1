# Script Description: Retrieves the system uptime and saves it to a text file on the desktop.
# Author: Claire Rosario
# Website: Rosario.one
# Synopsis: This PowerShell script retrieves the system uptime of the computer and saves it to a text file named 'uptime.txt' in the 'System Information' folder on the desktop.

# Define the path to save the text file on the desktop
$desktopPath = [System.Environment]::GetFolderPath('Desktop')

# Define the folder name for saving system information
$systemInfoFolderName = "System Information"
$systemInfoFolderPath = Join-Path -Path $desktopPath -ChildPath $systemInfoFolderName

# Create the folder for system information if it doesn't exist
if (-not (Test-Path -Path $systemInfoFolderPath)) {
    New-Item -Path $systemInfoFolderPath -ItemType Directory
}

# Get system uptime
$uptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$uptime = (Get-Date) - $uptime
$uptimeString = $uptime.Days.ToString() + ' days, ' + $uptime.Hours.ToString() + ' hours'
$uptimeString | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath 'uptime.txt')

# Display a message indicating the completion of the uptime section
Write-Host "Uptime information saved to '$systemInfoFolderName\uptime.txt'."
