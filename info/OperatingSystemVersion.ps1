# Script Description: Retrieves the operating system version and saves it to a text file on the desktop.
# Author: Claire Rosario
# Website: Rosario.one
# Synopsis: This PowerShell script retrieves the operating system version of the computer and saves it to a text file named 'os_version.txt' in the 'System Information' folder on the desktop.

# Define the path to save the text file on the desktop
$desktopPath = [System.Environment]::GetFolderPath('Desktop')

# Define the folder name for saving system information
$systemInfoFolderName = "System Information"
$systemInfoFolderPath = Join-Path -Path $desktopPath -ChildPath $systemInfoFolderName

# Create the folder for system information if it doesn't exist
if (-not (Test-Path -Path $systemInfoFolderPath)) {
    New-Item -Path $systemInfoFolderPath -ItemType Directory
}

# Get operating system version
$osVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
$osVersion | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath 'os_version.txt')

# Display a message indicating the completion of the operating system version section
Write-Host "Operating system version information saved to '$systemInfoFolderName\os_version.txt'."
