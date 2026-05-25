# Script Description: Retrieves the hostname of the computer and saves it to a text file on the desktop.
# Author: Claire Rosario
# Website: Rosario.one
# Synopsis: This PowerShell script retrieves the hostname of the computer and saves it to a text file named 'hostname.txt' in the 'System Information' folder on the desktop.

# Define the path to save the text file on the desktop
$desktopPath = [System.Environment]::GetFolderPath('Desktop')

# Define the folder name for saving system information
$systemInfoFolderName = "System Information"
$systemInfoFolderPath = Join-Path -Path $desktopPath -ChildPath $systemInfoFolderName

# Create the folder for system information if it doesn't exist
if (-not (Test-Path -Path $systemInfoFolderPath)) {
    New-Item -Path $systemInfoFolderPath -ItemType Directory
}

# Get hostname
$hostname = hostname
$hostname | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath 'hostname.txt')

# Display a message indicating the completion of the hostname section
Write-Host "Hostname information saved to '$systemInfoFolderName\hostname.txt'."
