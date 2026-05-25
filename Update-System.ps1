<#
.SYNOPSIS
    All-in-one Windows system maintenance script.
    Runs Windows Updates, winget upgrades, and Chocolatey upgrades.
    Also manages its own Windows Task Scheduler entry.

.DESCRIPTION
    This script has four operating modes selected by a single flag:

      -Install    Register a scheduled task that runs this script automatically.
                  Combine with -Frequency, -DayOfWeek, -DayOfMonth, and -Time
                  to control when the task fires. Requires Administrator.

      -Uninstall  Remove the scheduled task. The script itself and all log files
                  are left untouched. Requires Administrator.

      -Configure  Interactively change the schedule of an existing task.
                  Walks you through menus for frequency, day, and time.
                  Requires Administrator.

      -Run        Execute all updates right now. This is also the default when
                  you call the script with no flags at all. Requires Administrator.

    All output is appended to:
        <script folder>\logs\update-log.txt

.PARAMETER Install
    Switch: register the scheduled task using the schedule parameters below.

.PARAMETER Uninstall
    Switch: remove the scheduled task from Task Scheduler.

.PARAMETER Configure
    Switch: interactively update the schedule of the existing task.

.PARAMETER Run
    Switch: run all updates immediately (default behavior).

.PARAMETER Frequency
    How often the task runs. Accepted values: Daily, Weekly, Monthly.
    Default: Weekly

.PARAMETER DayOfWeek
    Day of the week for a Weekly task. Accepted values: Sunday, Monday,
    Tuesday, Wednesday, Thursday, Friday, Saturday.
    Default: Sunday

.PARAMETER DayOfMonth
    Day of the month (1-28) for a Monthly task.
    Default: 1

.PARAMETER Time
    Time of day in 24-hour HH:MM format (e.g. "10:00", "22:30").
    Default: 10:00

.EXAMPLE
    # Set up a weekly task (defaults: Sunday 10:00 AM)
    .\Update-System.ps1 -Install

.EXAMPLE
    # Set up a daily task at 11 PM
    .\Update-System.ps1 -Install -Frequency Daily -Time "23:00"

.EXAMPLE
    # Set up a monthly task on the 15th at 9 AM
    .\Update-System.ps1 -Install -Frequency Monthly -DayOfMonth 15 -Time "09:00"

.EXAMPLE
    # Change the schedule interactively after it is already installed
    .\Update-System.ps1 -Configure

.EXAMPLE
    # Run all updates right now
    .\Update-System.ps1 -Run

.EXAMPLE
    # Remove the scheduled task
    .\Update-System.ps1 -Uninstall

.NOTES
    Requires PowerShell 5.1+ and Administrator privileges.
    PSWindowsUpdate is installed automatically from PSGallery if missing.
    Windows updates will NOT auto-reboot — patches are applied on your next
    natural restart.
#>

# ---------------------------------------------------------------------------
# PARAMETER BLOCK
# Defines all accepted flags. CmdletBinding enables -Verbose, -WhatIf, etc.
# ---------------------------------------------------------------------------
[CmdletBinding(DefaultParameterSetName = 'Run')]
param (
    # --- Operating modes (mutually exclusive parameter sets) ---
    [Parameter(ParameterSetName = 'Install',   Mandatory = $true)]
    [switch]$Install,

    [Parameter(ParameterSetName = 'Uninstall', Mandatory = $true)]
    [switch]$Uninstall,

    [Parameter(ParameterSetName = 'Configure', Mandatory = $true)]
    [switch]$Configure,

    [Parameter(ParameterSetName = 'Run',       Mandatory = $false)]
    [switch]$Run,

    # --- Schedule parameters (used by -Install and -Configure) ---

    # Frequency of the scheduled task
    [Parameter(ParameterSetName = 'Install')]
    [Parameter(ParameterSetName = 'Configure')]
    [ValidateSet('Daily', 'Weekly', 'Monthly')]
    [string]$Frequency = 'Weekly',

    # Day of the week (only relevant when Frequency = Weekly)
    [Parameter(ParameterSetName = 'Install')]
    [Parameter(ParameterSetName = 'Configure')]
    [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
    [string]$DayOfWeek = 'Sunday',

    # Day of the month 1-28 (only relevant when Frequency = Monthly)
    # Capped at 28 so it fires every month — avoids the Feb 29/30/31 problem.
    [Parameter(ParameterSetName = 'Install')]
    [Parameter(ParameterSetName = 'Configure')]
    [ValidateRange(1, 28)]
    [int]$DayOfMonth = 1,

    # Time of day in HH:MM 24-hour format
    [Parameter(ParameterSetName = 'Install')]
    [Parameter(ParameterSetName = 'Configure')]
    [ValidatePattern('^\d{2}:\d{2}$')]
    [string]$Time = '10:00'
)

# ---------------------------------------------------------------------------
# CONSTANTS
# Change these if you ever move the script or rename the task.
# ---------------------------------------------------------------------------
$TASK_NAME   = 'System Maintenance Updates'
$TASK_PATH   = "\$env:USERNAME\"                   # folder in Task Scheduler
$SCRIPT_PATH = $MyInvocation.MyCommand.Path        # null when run via irm | iex
$LOG_DIR     = if ($SCRIPT_PATH) { Join-Path (Split-Path $SCRIPT_PATH) 'logs' } `
               else { Join-Path $env:TEMP 'WinButler\logs' }
$LOG_FILE    = Join-Path $LOG_DIR 'update-log.txt'

# ---------------------------------------------------------------------------
# HELPER: Write-Log
# Appends a timestamped line (or block) to the log file and also writes
# to the console. Use this everywhere instead of plain Write-Output so the
# log stays complete.
# ---------------------------------------------------------------------------
function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"
    # Ensure log directory exists even if someone deleted it
    if (-not (Test-Path $LOG_DIR)) { New-Item -ItemType Directory -Force $LOG_DIR | Out-Null }
    Add-Content -Path $LOG_FILE -Value $line
    # Color-code the console output by severity
    switch ($Level) {
        'ERROR' { Write-Host $line -ForegroundColor Red }
        'WARN'  { Write-Host $line -ForegroundColor Yellow }
        'OK'    { Write-Host $line -ForegroundColor Green }
        default { Write-Host $line }
    }
}

# ---------------------------------------------------------------------------
# HELPER: Assert-Admin
# Stops with a clear error if the script is not running elevated.
# Task Scheduler actions run as SYSTEM so they are always elevated; this
# check matters for interactive use.
# ---------------------------------------------------------------------------
function Assert-Admin {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host ""
        Write-Host "  This script must run as Administrator." -ForegroundColor Red
        Write-Host "  Right-click PowerShell -> 'Run as administrator', then try again." -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
}

# ---------------------------------------------------------------------------
# HELPER: Ensure-PSWindowsUpdate
# Installs the PSWindowsUpdate module from PSGallery if it is not already
# present. This module wraps the Windows Update COM API in clean cmdlets.
# ---------------------------------------------------------------------------
function Ensure-PSWindowsUpdate {
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Log "PSWindowsUpdate module not found. Installing from PSGallery..."
        # NuGet provider is required before Install-Module will work
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers | Out-Null
        Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers -AllowClobber
        Write-Log "PSWindowsUpdate installed successfully." -Level OK
    }
    Import-Module PSWindowsUpdate -Force
}

# ---------------------------------------------------------------------------
# HELPER: Build-Trigger
# Returns a Task Scheduler trigger object for the requested schedule.
# Called by both Install-Task and Configure-Task so the logic lives once.
# ---------------------------------------------------------------------------
function Build-Trigger {
    param (
        [string]$FreqParam,
        [string]$DayOfWeekParam,
        [int]$DayOfMonthParam,
        [string]$TimeParam
    )

    # Parse the time string into a proper DateTime for the trigger
    $runAt = [DateTime]::ParseExact($TimeParam, 'HH:mm', $null)

    switch ($FreqParam) {
        'Daily' {
            # Fires every day at the specified time
            New-ScheduledTaskTrigger -Daily -At $runAt
        }
        'Weekly' {
            # Fires once a week on the chosen day
            New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 `
                -DaysOfWeek $DayOfWeekParam -At $runAt
        }
        'Monthly' {
            # Fires once a month on the chosen day-of-month
            # New-ScheduledTaskTrigger doesn't support monthly directly,
            # so we use the CIM class to build a custom trigger.
            $trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -At $runAt -DaysOfWeek Sunday
            # Override with a proper monthly trigger via raw XML trick
            $trigger = New-Object Microsoft.Management.Infrastructure.CimInstance `
                'MSFT_TaskMonthlyTrigger', 'Root/Microsoft/Windows/TaskScheduler'
            $trigger.CimInstanceProperties['DaysOfMonth'].Value = [Math]::Pow(2, $DayOfMonthParam - 1)
            $trigger.CimInstanceProperties['MonthsOfYear'].Value = 4095  # all 12 months
            $trigger.CimInstanceProperties['StartBoundary'].Value = `
                (Get-Date -Hour $runAt.Hour -Minute $runAt.Minute -Second 0 -Day $DayOfMonthParam).ToString('yyyy-MM-ddTHH:mm:ss')
            $trigger.CimInstanceProperties['Enabled'].Value = $true
            $trigger
        }
    }
}

# ---------------------------------------------------------------------------
# HELPER: Register-MaintenanceTask
# Creates or replaces the scheduled task with the given trigger.
# Runs as SYSTEM so no UAC prompt appears at task time.
# ---------------------------------------------------------------------------
function Register-MaintenanceTask {
    param($Trigger)

    # The action: run this same script with the -Run flag
    $action = New-ScheduledTaskAction `
        -Execute 'powershell.exe' `
        -Argument "-ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -File `"$SCRIPT_PATH`" -Run"

    # Settings: only run on AC power, allow starting if the scheduled time was missed
    $settings = New-ScheduledTaskSettingsSet `
        -ExecutionTimeLimit (New-TimeSpan -Hours 2) `
        -StartWhenAvailable `
        -AC                          # AC power only — skip if on battery

    # Principal: SYSTEM account, highest privilege, no interactive session needed
    $principal = New-ScheduledTaskPrincipal `
        -UserId 'SYSTEM' `
        -LogonType ServiceAccount `
        -RunLevel Highest

    # Ensure the task folder exists in Task Scheduler
    $scheduler = New-Object -ComObject Schedule.Service
    $scheduler.Connect()
    try {
        $scheduler.GetFolder($TASK_PATH) | Out-Null
    } catch {
        $rootFolder = $scheduler.GetFolder('\')
        $rootFolder.CreateFolder($TASK_PATH) | Out-Null
    }

    # Register (or replace) the task — Force overwrites if it already exists
    Register-ScheduledTask `
        -TaskName  $TASK_NAME `
        -TaskPath  $TASK_PATH `
        -Action    $action `
        -Trigger   $Trigger `
        -Settings  $settings `
        -Principal $principal `
        -Force | Out-Null

    Write-Log "Scheduled task '$TASK_NAME' registered in Task Scheduler folder '$TASK_PATH'." -Level OK
}

# ---------------------------------------------------------------------------
# HELPER: Show-CurrentSchedule
# Reads the existing task from Task Scheduler and prints its trigger summary.
# Used by -Configure to show the user what is currently set.
# ---------------------------------------------------------------------------
function Show-CurrentSchedule {
    $task = Get-ScheduledTask -TaskName $TASK_NAME -TaskPath $TASK_PATH -ErrorAction SilentlyContinue
    if ($null -eq $task) {
        Write-Host "  (No task named '$TASK_NAME' is currently registered.)" -ForegroundColor Yellow
    } else {
        $info = $task.Triggers | Select-Object -First 1
        Write-Host "  Current trigger: $($info.CimClass.CimClassName)" -ForegroundColor Cyan
        Write-Host "  Start boundary : $($info.StartBoundary)" -ForegroundColor Cyan
    }
}

# ---------------------------------------------------------------------------
# HELPER: Prompt-Schedule
# Interactive menu for -Configure mode. Returns a hashtable of schedule
# parameters that can be passed to Build-Trigger.
# ---------------------------------------------------------------------------
function Prompt-Schedule {
    Write-Host ""
    Write-Host "  ---- Configure Schedule ----" -ForegroundColor Cyan

    # --- Frequency ---
    Write-Host ""
    Write-Host "  How often should updates run?"
    Write-Host "    [1] Daily"
    Write-Host "    [2] Weekly  (default)"
    Write-Host "    [3] Monthly"
    $freqChoice = Read-Host "  Enter 1, 2, or 3 (press Enter for Weekly)"
    $freqMap = @{ '1' = 'Daily'; '2' = 'Weekly'; '3' = 'Monthly' }
    $chosenFreq = if ($freqMap.ContainsKey($freqChoice)) { $freqMap[$freqChoice] } else { 'Weekly' }

    # --- Day selection (only shown for Weekly or Monthly) ---
    $chosenDow      = 'Sunday'
    $chosenDayOfMon = 1

    if ($chosenFreq -eq 'Weekly') {
        Write-Host ""
        Write-Host "  Which day of the week?"
        $days = @('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')
        for ($i = 0; $i -lt $days.Count; $i++) {
            $marker = if ($days[$i] -eq 'Sunday') { ' (default)' } else { '' }
            Write-Host "    [$($i+1)] $($days[$i])$marker"
        }
        $dowChoice = Read-Host "  Enter 1-7 (press Enter for Sunday)"
        $dowIndex  = if ($dowChoice -match '^\d+$' -and [int]$dowChoice -ge 1 -and [int]$dowChoice -le 7) {
            [int]$dowChoice - 1
        } else { 0 }
        $chosenDow = $days[$dowIndex]
    }

    if ($chosenFreq -eq 'Monthly') {
        Write-Host ""
        $domInput = Read-Host "  Day of month (1-28, press Enter for 1)"
        $chosenDayOfMon = if ($domInput -match '^\d+$' -and [int]$domInput -ge 1 -and [int]$domInput -le 28) {
            [int]$domInput
        } else { 1 }
    }

    # --- Time ---
    Write-Host ""
    $timeInput = Read-Host "  Time of day in HH:MM 24-hour format (press Enter for 10:00)"
    $chosenTime = if ($timeInput -match '^\d{2}:\d{2}$') { $timeInput } else { '10:00' }

    Write-Host ""
    Write-Host "  Selected: $chosenFreq" -NoNewline
    if ($chosenFreq -eq 'Weekly')  { Write-Host " on $chosenDow" -NoNewline }
    if ($chosenFreq -eq 'Monthly') { Write-Host " on day $chosenDayOfMon" -NoNewline }
    Write-Host " at $chosenTime" -ForegroundColor Green

    return @{
        Frequency   = $chosenFreq
        DayOfWeek   = $chosenDow
        DayOfMonth  = $chosenDayOfMon
        Time        = $chosenTime
    }
}

# ===========================================================================
# MAIN LOGIC — dispatch to the correct mode based on which flag was passed
# ===========================================================================

Assert-Admin   # all modes require elevation

# Install/Configure/Uninstall require the script to exist on disk so the
# scheduled task action has a real file path to reference.
if (-not $SCRIPT_PATH -and $PSCmdlet.ParameterSetName -in 'Install','Configure','Uninstall') {
    Write-Host ""
    Write-Host "  The '$($PSCmdlet.ParameterSetName)' mode requires the script to be saved on disk." -ForegroundColor Yellow
    Write-Host "  Download Update-System.ps1 first, then run it directly." -ForegroundColor Yellow
    Write-Host "  https://github.com/Makeea/WinButler" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

# ---------------------------------------------------------------------------
# MODE: -Install
# First-time setup. Creates the log directory and registers the task.
# ---------------------------------------------------------------------------
if ($PSCmdlet.ParameterSetName -eq 'Install') {
    Write-Log "=== INSTALL: Registering scheduled task ==="

    # Ensure log directory exists
    if (-not (Test-Path $LOG_DIR)) {
        New-Item -ItemType Directory -Force $LOG_DIR | Out-Null
        Write-Log "Created log directory: $LOG_DIR"
    }

    # Build the trigger from the parameters passed on the command line
    $trigger = Build-Trigger -FreqParam $Frequency -DayOfWeekParam $DayOfWeek `
                             -DayOfMonthParam $DayOfMonth -TimeParam $Time
    Register-MaintenanceTask -Trigger $trigger

    Write-Host ""
    Write-Host "  Setup complete." -ForegroundColor Green
    Write-Host "  Task : $TASK_PATH$TASK_NAME"
    Write-Host "  Schedule : $Frequency" -NoNewline
    if ($Frequency -eq 'Weekly')  { Write-Host " on $DayOfWeek" -NoNewline }
    if ($Frequency -eq 'Monthly') { Write-Host " on day $DayOfMonth" -NoNewline }
    Write-Host " at $Time"
    Write-Host "  Log  : $LOG_FILE"
    Write-Host ""
    Write-Log "=== INSTALL COMPLETE ===" -Level OK
    exit 0
}

# ---------------------------------------------------------------------------
# MODE: -Uninstall
# Removes the scheduled task. Script and logs are NOT deleted.
# ---------------------------------------------------------------------------
if ($PSCmdlet.ParameterSetName -eq 'Uninstall') {
    Write-Log "=== UNINSTALL: Removing scheduled task ==="

    $task = Get-ScheduledTask -TaskName $TASK_NAME -TaskPath $TASK_PATH -ErrorAction SilentlyContinue
    if ($null -eq $task) {
        Write-Log "No task named '$TASK_NAME' was found. Nothing to remove." -Level WARN
    } else {
        Unregister-ScheduledTask -TaskName $TASK_NAME -TaskPath $TASK_PATH -Confirm:$false
        Write-Log "Task '$TASK_NAME' removed." -Level OK
    }

    Write-Host ""
    Write-Host "  The script and log files at $LOG_DIR are untouched." -ForegroundColor Cyan
    Write-Host "  To reinstall at any time, run:  .\Update-System.ps1 -Install" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# ---------------------------------------------------------------------------
# MODE: -Configure
# Shows the current schedule then prompts interactively for a new one.
# If schedule parameters were also passed on the CLI they are used directly
# (no interactive prompt), making this scriptable too.
# ---------------------------------------------------------------------------
if ($PSCmdlet.ParameterSetName -eq 'Configure') {
    Write-Log "=== CONFIGURE: Updating task schedule ==="
    Write-Host ""
    Write-Host "  Current schedule:" -ForegroundColor Cyan
    Show-CurrentSchedule

    # Check if the caller already provided schedule params on the CLI.
    # $PSBoundParameters tracks which parameters were explicitly passed.
    $hasCliSchedule = $PSBoundParameters.ContainsKey('Frequency') -or
                      $PSBoundParameters.ContainsKey('DayOfWeek') -or
                      $PSBoundParameters.ContainsKey('DayOfMonth') -or
                      $PSBoundParameters.ContainsKey('Time')

    if ($hasCliSchedule) {
        # Non-interactive path: use the values supplied on the command line
        $cfg = @{
            Frequency  = $Frequency
            DayOfWeek  = $DayOfWeek
            DayOfMonth = $DayOfMonth
            Time       = $Time
        }
    } else {
        # Interactive path: walk the user through menus
        $cfg = Prompt-Schedule
    }

    $trigger = Build-Trigger -FreqParam $cfg.Frequency -DayOfWeekParam $cfg.DayOfWeek `
                             -DayOfMonthParam $cfg.DayOfMonth -TimeParam $cfg.Time
    Register-MaintenanceTask -Trigger $trigger

    Write-Log "=== CONFIGURE COMPLETE ===" -Level OK
    exit 0
}

# ---------------------------------------------------------------------------
# MODE: -Run  (also the default when no flag is given)
# Executes all three update sources in sequence and logs everything.
# ---------------------------------------------------------------------------
Write-Log "=== UPDATE RUN STARTED ==="
$overallSuccess = $true

# --- Step 1: Windows OS Updates via PSWindowsUpdate ---
Write-Log "--- Step 1 of 3: Windows Update ---"
try {
    Ensure-PSWindowsUpdate

    # Get-WindowsUpdate lists available patches; Install-WindowsUpdate applies them.
    # -AcceptAll   : accept all EULAs automatically (no interactive prompt)
    # -AutoReboot:$false : never reboot automatically — you decide when to restart
    # -Verbose     : pipe detailed output so it shows in the log
    $wuOutput = Install-WindowsUpdate -AcceptAll -AutoReboot:$false -Verbose 4>&1
    $wuOutput | ForEach-Object { Write-Log "  [WU] $_" }
    Write-Log "Windows Update step completed." -Level OK
} catch {
    Write-Log "Windows Update step failed: $_" -Level ERROR
    $overallSuccess = $false
}

# --- Step 2: winget package upgrades ---
Write-Log "--- Step 2 of 3: winget upgrade --all ---"
try {
    # --silent                      : no interactive prompts during install
    # --accept-package-agreements   : auto-accept per-package license terms
    # --accept-source-agreements    : auto-accept winget source license
    $wingetOutput = winget upgrade --all --silent `
        --accept-package-agreements `
        --accept-source-agreements 2>&1
    $wingetOutput | ForEach-Object { Write-Log "  [winget] $_" }
    Write-Log "winget upgrade completed." -Level OK
} catch {
    Write-Log "winget upgrade failed: $_" -Level ERROR
    $overallSuccess = $false
}

# --- Step 3: Chocolatey upgrades ---
Write-Log "--- Step 3 of 3: choco upgrade all ---"
try {
    # -y           : answer yes to all prompts automatically
    # --no-progress: cleaner log output (no progress bars)
    # To pin (skip) a specific package add: --except="packagename"
    $chocoOutput = choco upgrade all -y --no-progress 2>&1
    $chocoOutput | ForEach-Object { Write-Log "  [choco] $_" }
    Write-Log "Chocolatey upgrade completed." -Level OK
} catch {
    Write-Log "Chocolatey upgrade failed: $_" -Level ERROR
    $overallSuccess = $false
}

# --- Final summary line in the log ---
if ($overallSuccess) {
    Write-Log "=== UPDATE RUN FINISHED SUCCESSFULLY ===" -Level OK
} else {
    Write-Log "=== UPDATE RUN FINISHED WITH ERRORS — review log above ===" -Level WARN
}

Write-Host ""
Write-Host "  Log saved to: $LOG_FILE" -ForegroundColor Cyan
Write-Host ""
