$VMName = "Windows 11 Pro 25H2"
$BackupRoot = "D:\HyperVBackups"
$Date = Get-Date -Format "yyyy-MM-dd"

Stop-VM -Name $VMName -Force

Export-VM -Name $VMName -Path "$BackupRoot\$Date"

Start-VM -Name $VMName