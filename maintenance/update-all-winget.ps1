# ==========================================================
# Script: update-all-winget.ps1
# Purpose: Automate system-wide app updates using Winget
# Logs: <script folder>\logs\winget-update-YYYY-MM-DD_HH-mm-ss.txt
# Retention: Keeps logs for 60 days, deletes older ones
# ==========================================================

# ==========================================================
# HOW TO ADD THIS SCRIPT TO TASK SCHEDULER
# ==========================================================
# 1. Open Task Scheduler
# 2. Click "Create Task" (not "Create Basic Task")
# 3. General tab:
#      - Name: Winget Auto Update
#      - Select: Run with highest privileges
#      - Configure for: Windows 10/11
# 4. Triggers tab:
#      - Click "New"
#      - Choose how often (e.g. Weekly, Daily)
#      - Set time (e.g. 3:00 AM)
#      - Click OK
# 5. Actions tab:
#      - Click "New"
#      - Action: Start a program
#      - Program/script (choose one):
#          a) For PowerShell 5 (Windows built-in):
#             C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
#          b) For PowerShell 7+ (if installed):
#             C:\Program Files\PowerShell\7\pwsh.exe
#      - Add arguments:
#             -ExecutionPolicy Bypass -File "C:\path-to-script\update-all-winget.ps1"
#      - Click OK
# 6. Conditions tab:
#      - (Optional) Check "Start only if the computer is on AC power"
# 7. Settings tab:
#      - Check "Run task as soon as possible after a scheduled start is missed"
#      - Check "Stop the task if it runs longer than 2 hours"
# 8. Click OK to save the task
# 9. Run it manually once to confirm logging and updates work
# ==========================================================

# 1. Ensure log directory exists
$log_dir = Join-Path (Split-Path $MyInvocation.MyCommand.Path) ‘logs’
if (!(Test-Path $log_dir)) {
	New-Item -ItemType Directory -Path $log_dir | Out-Null
}

# 2. Clean up old logs
#    Deletes any Winget update logs older than 60 days
Get-ChildItem -Path $log_dir -Filter "winget-update-*.txt" -File | Where-Object {
	$_.LastWriteTime -lt (Get-Date).AddDays(-60)
} | Remove-Item -Force

# 3. Create timestamped log file
#    Each run generates a unique log file for historical tracking
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$log_path = "$log_dir\winget-update-$timestamp.txt"

# 4. Start log entry
Add-Content -Path $log_path -Value "=== Winget Update Started: $timestamp ===`n"

# 5. Perform update
#    - --all updates every package
#    - --silent and --disable-interactivity make it non-interactive
#    - --disable-progress removes spinner output
#    - Output is written to both console and log file
try {
	winget upgrade --all --accept-source-agreements --accept-package-agreements --silent --disable-interactivity | Tee-Object -FilePath $log_path -Append
	Add-Content -Path $log_path -Value "`n=== Winget Update Completed Successfully ===`n"
} catch {
	Add-Content -Path $log_path -Value "`n*** ERROR: $($_.Exception.Message) ***`n"
}