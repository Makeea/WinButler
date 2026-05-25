# Script Description:
# This PowerShell script connects to Microsoft 365 (Office 365) using the MSOnline module.
# It prompts the user for their Microsoft 365 username and password, establishes a session,
# and provides information about the successful login.
# You can use the connected session for various Microsoft 365 tasks.

# Install the MSOnline module if not already installed
if (-not (Get-Module -Name MSOnline -ListAvailable)) {
    Install-Module -Name MSOnline -Force -Scope CurrentUser
}

# Import the MSOnline module
Import-Module MSOnline

# Prompt the user for Microsoft 365 credentials
$Username = Read-Host -Prompt "Enter your Microsoft 365 username (e.g., user@contoso.com)"
$Password = Read-Host -Prompt "Enter your Microsoft 365 password" -AsSecureString

# Convert the password to plain text
$SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

# Create a new Microsoft 365 session
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePassword
Connect-MsolService -Credential $Credential

# Provide information to the user
Write-Host "Logged in to Microsoft 365 as $Username"

# You can now use the connected session for various Microsoft 365 tasks

# Disconnect from Microsoft 365 when done
Disconnect-MsolService
