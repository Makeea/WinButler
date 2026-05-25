$DateDaily   = Get-Date -Format "yyyy-MM-dd"
$DateWeekly  = Get-Date -Format "yyyy-'W'ww"
$DateMonthly = Get-Date -Format "yyyy-MM"

$BasePath = "C:\WSL-Backups"
$DailyPath = "$BasePath\Daily"
$WeeklyPath = "$BasePath\Weekly"
$MonthlyPath = "$BasePath\Monthly"

# Create folders if missing
New-Item -ItemType Directory -Force -Path $DailyPath, $WeeklyPath, $MonthlyPath | Out-Null

$Distros = @("Ubuntu", "Debian", "Ubuntu-24.04")

# Shutdown WSL safely
wsl --shutdown

foreach ($Distro in $Distros) {

    # Daily Backup
    $DailyFile = "$DailyPath\$Distro-$DateDaily.tar"
    wsl --export $Distro $DailyFile

    # Weekly Backup (Sunday only)
    if ((Get-Date).DayOfWeek -eq "Sunday") {
        $WeeklyFile = "$WeeklyPath\$Distro-$DateWeekly.tar"
        Copy-Item $DailyFile $WeeklyFile -Force
    }

    # Monthly Backup (1st of month only)
    if ((Get-Date).Day -eq 1) {
        $MonthlyFile = "$MonthlyPath\$Distro-$DateMonthly.tar"
        Copy-Item $DailyFile $MonthlyFile -Force
    }
}

# ===== ROTATION POLICY =====

# Keep last 7 daily backups
Get-ChildItem $DailyPath -Filter "*.tar" | 
Sort-Object CreationTime -Descending | 
Select-Object -Skip 7 | 
Remove-Item -Force

# Keep last 4 weekly backups
Get-ChildItem $WeeklyPath -Filter "*.tar" | 
Sort-Object CreationTime -Descending | 
Select-Object -Skip 4 | 
Remove-Item -Force

# Keep last 30 monthly backups
Get-ChildItem $MonthlyPath -Filter "*.tar" | 
Sort-Object CreationTime -Descending | 
Select-Object -Skip 30 | 
Remove-Item -Force
