# Script Description: Retrieves time zone information and saves it to a text file on the desktop.
# Author: Claire Rosario
# Website: Rosario.one
# Synopsis: This PowerShell script retrieves time zone information of the computer and saves it to a text file named 'time_zone.txt' in the 'System Information' folder on the desktop.

# Define the path to save the text file on the desktop
$desktopPath = [System.Environment]::GetFolderPath('Desktop')

# Define the folder name for saving system information
$systemInfoFolderName = "System Information"
$systemInfoFolderPath = Join-Path -Path $desktopPath -ChildPath $systemInfoFolderName

# Create the folder for system information if it doesn't exist
if (-not (Test-Path -Path $systemInfoFolderPath)) {
    New-Item -Path $systemInfoFolderPath -ItemType Directory
}

# Get time zone information
$timeZone = (Get-TimeZone).Id
$timeZone | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath 'time_zone.txt')

# Display a message indicating the completion of the time zone information section
Write-Host "Time zone information saved to '$systemInfoFolderName\time_zone.txt'."
