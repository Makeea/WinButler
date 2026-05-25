# WinButler

A PowerShell script that keeps your Windows system up to date — automatically. WinButler runs Windows Update, winget, and Chocolatey upgrades in sequence, logs everything, and manages its own scheduled task so you never have to think about it.

## What it does

- Installs available Windows OS patches (via PSWindowsUpdate)
- Upgrades all winget packages
- Upgrades all Chocolatey packages
- Logs all output to `logs\update-log.txt` inside the script folder
- Never auto-reboots — patches are applied on your next natural restart

## Requirements

- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges
- [winget](https://github.com/microsoft/winget-cli) (included in Windows 11, available for Windows 10)
- [Chocolatey](https://chocolatey.org/install) (optional — step is skipped if not installed)
- PSWindowsUpdate — installed automatically from PSGallery if missing

---

## Option 1 — Run directly (no download needed)

Open PowerShell **as Administrator**, then run:

```powershell
irm https://raw.githubusercontent.com/Makeea/WinButler/refs/heads/main/Update-System.ps1 | iex
```

This runs all updates immediately and logs output to your system temp folder. No files are saved to your machine.

> **Note:** This method only supports running updates. To set up a scheduled task, use Option 2.

---

## Option 2 — Download and install

Open PowerShell **as Administrator**, then run:

```powershell
irm https://raw.githubusercontent.com/Makeea/WinButler/refs/heads/main/Update-System.ps1 -OutFile "$env:USERPROFILE\Scripts\WinButler\Update-System.ps1"
```

Then run the script from its saved location:

```powershell
# Run updates right now
.\Update-System.ps1 -Run

# Set up a scheduled task (defaults: Weekly, Sunday, 10:00 AM)
.\Update-System.ps1 -Install

# Set up with a custom schedule
.\Update-System.ps1 -Install -Frequency Daily -Time "23:00"
.\Update-System.ps1 -Install -Frequency Weekly -DayOfWeek Friday -Time "08:00"
.\Update-System.ps1 -Install -Frequency Monthly -DayOfMonth 15 -Time "09:00"

# Change the schedule interactively
.\Update-System.ps1 -Configure

# Remove the scheduled task
.\Update-System.ps1 -Uninstall
```

---

## Schedule parameters

| Parameter     | Values                        | Default  |
|---------------|-------------------------------|----------|
| `-Frequency`  | `Daily`, `Weekly`, `Monthly`  | `Weekly` |
| `-DayOfWeek`  | `Sunday` – `Saturday`         | `Sunday` |
| `-DayOfMonth` | `1` – `28`                    | `1`      |
| `-Time`       | `HH:MM` (24-hour)             | `10:00`  |

Day of month is capped at 28 so the task fires every month without skipping February.

## Scheduled task

The task runs as `SYSTEM` (no UAC prompt at run time) and is created in a Task Scheduler folder named after the current user. It only runs on AC power and will catch up if the machine was off at the scheduled time.

## Logs

All output is appended to `logs\update-log.txt` in the same folder as the script. The `logs\` directory is created automatically and is excluded from version control.
