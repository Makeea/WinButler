# This script lists installed programs and saves them to a file on the desktop

# Get the path to the current user's desktop
$desktopPath = [Environment]::GetFolderPath("Desktop")

# Set the output file path
$outputFile = "$desktopPath\installed-programs.txt"

# Get installed programs from the registry and export them
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Where-Object { $_.DisplayName } |
    Out-File -FilePath $outputFile -Encoding UTF8

# Also check the 32-bit registry path on 64-bit systems
Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Where-Object { $_.DisplayName } |
    Out-File -FilePath $outputFile -Append -Encoding UTF8

# Print confirmation message
Write-Output "Installed programs list saved to: $outputFile"
