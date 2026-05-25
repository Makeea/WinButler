# maintenance

Scripts for keeping the system healthy — repairing Windows Update, backing up drivers and user data, and managing winget updates.

| Script | Description |
|---|---|
| `Update-System.ps1` | *(root)* Full system update: Windows Update, winget, and Chocolatey with Task Scheduler support |
| `update-all-winget.ps1` | Winget-only updater with timestamped logs and 60-day log retention |
| `Windows-Update-Reset.ps1` | Full Windows Update reset — stops services, clears cache, re-registers DLLs |
| `Windows-Update-Reset-Clean.ps1` | Lighter Windows Update reset for common stuck-update scenarios |
| `backup-or-restore-all-drivers.ps1` | Backs up or restores all installed drivers with a date-stamped archive |
| `backup-userdata-wsl-apps.ps1` | Backs up user profiles, WSL distros, and app data (Firefox, Chrome, Notepad++) |
| `Fix-SshConfigPermissions.ps1` | Locks down `.ssh` folder and key permissions to satisfy OpenSSH requirements |
