# Script Description: Retrieves network information and saves it to a text file on the desktop.
# Author: Claire Rosario
# Website: Rosario.one
# Synopsis: This PowerShell script retrieves network information of the computer and saves it to a text file named 'network_info.txt' in the 'System Information' folder on the desktop.

# Define the path to save the text file on the desktop
$desktopPath = [System.Environment]::GetFolderPath('Desktop')

# Define the folder name for saving system information
$systemInfoFolderName = "System Information"
$systemInfoFolderPath = Join-Path -Path $desktopPath -ChildPath $systemInfoFolderName

# Create the folder for system information if it doesn't exist
if (-not (Test-Path -Path $systemInfoFolderPath)) {
    New-Item -Path $systemInfoFolderPath -ItemType Directory
}

# Get network information
$networkInfo = Get-NetIPConfiguration
$networkInfo | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath 'network_info.txt')

# Display a message indicating the completion of the network information section
Write-Host "Network information saved to '$systemInfoFolderName\network_info.txt'."
