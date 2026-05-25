# Script Description: Retrieves the last used date for installed applications and saves it to a text file on the desktop.
# Author: Claire Rosario
# Website: Rosario.one
# Synopsis: This PowerShell script retrieves the last used date for installed applications and saves it to a text file named 'last_used_dates.txt' in the 'System Information' folder on the desktop.

# Define the path to save the text file on the desktop
$desktopPath = [System.Environment]::GetFolderPath('Desktop')

# Define the folder name for saving system information
$systemInfoFolderName = "System Information"
$systemInfoFolderPath = Join-Path -Path $desktopPath -ChildPath $systemInfoFolderName

# Create the folder for system information if it doesn't exist
if (-not (Test-Path -Path $systemInfoFolderPath)) {
    New-Item -Path $systemInfoFolderPath -ItemType Directory
}

# Function to get a list of installed programs
function Get-InstalledPrograms {
    return Get-WmiObject -Class Win32_Product | Select-Object -ExpandProperty Name
}

# Function to get the last used date for installed applications
function Get-LastUsedDate {
    $programs = Get-InstalledPrograms
    $lastUsedDates = @{}
    foreach ($program in $programs) {
        $lastUsedDate = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object DisplayName -eq $program).InstallDate
        if ($lastUsedDate) {
            $lastUsedDates[$program] = $lastUsedDate
        }
    }
    return $lastUsedDates
}

# Get the last used dates for installed applications
$lastUsedDates = Get-LastUsedDate
$lastUsedDates | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath 'last_used_dates.txt')

# Display a message indicating the completion of the last used dates section
Write-Host "Last used dates for installed applications saved to '$systemInfoFolderName\last_used_dates.txt'."
