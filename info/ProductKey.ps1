# Script Description: Retrieves the Windows product key using WMI and saves it to a text file on the desktop.
# Author: Claire Rosario
# Website: Rosario.one
# Synopsis: This PowerShell script retrieves the Windows product key using WMI and saves it to a text file named 'windows_product_key.txt' in the 'System Information' folder on the desktop.

# MAY NOT WORK ANYMORE

# Define the path to save the text file on the desktop
$desktopPath = [System.Environment]::GetFolderPath('Desktop')

# Define the folder name for saving system information
$systemInfoFolderName = "System Information"
$systemInfoFolderPath = Join-Path -Path $desktopPath -ChildPath $systemInfoFolderName

# Create the folder for system information if it doesn't exist
if (-not (Test-Path -Path $systemInfoFolderPath)) {
    New-Item -Path $systemInfoFolderPath -ItemType Directory
}

# Run the WMI query to get the Windows product key
$productKey = (Get-WmiObject -Query "select * from SoftwareLicensingService").OA3xOriginalProductKey

# Check if a product key was found
if ($productKey -ne $null) {
    $productKey | Out-File -FilePath (Join-Path -Path $systemInfoFolderPath -ChildPath 'windows_product_key.txt')
    Write-Host "Windows product key saved to '$systemInfoFolderName\windows_product_key.txt'."
} else {
    Write-Host "No Windows product key found."
}
