<# Creates a weekly Scheduled Task to run SpeedBoost.ps1 as SYSTEM with highest privileges. #>

$scriptPath = "C:\ProgramData\SpeedBoost\SpeedBoost.ps1"
$taskName   = "SpeedBoost Weekly"
$logPath    = "C:\ProgramData\SpeedBoost\SpeedBoost.log"

if (-not (Test-Path $scriptPath)) {
  Write-Error "Script not found: $scriptPath. Copy SpeedBoost.ps1 there first."
  exit 1
}

# Sundays at 12:00 (noon). Change DaysOfWeek/At to taste.
$DaysOfWeek = @("Sunday")
$At         = [TimeSpan]::FromHours(12)

$trigger   = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DaysOfWeek -At $At
$action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -LogPath `"$logPath`"")
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew

try {
  if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false | Out-Null
  }
  Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null
  Write-Host "✅ Task '$taskName' registered. Weekly on $($DaysOfWeek -join ', ') at $([DateTime]::Today.Add($At).ToShortTimeString())."
  Write-Host "Log: $logPath"
} catch {
  Write-Error "Failed to register task: $($_.Exception.Message)"
}
