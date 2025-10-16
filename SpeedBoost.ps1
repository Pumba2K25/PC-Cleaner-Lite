<# 
.SYNOPSIS
  Weekly performance maintenance: stop heavy background junk, clean temp files, and warn on high RAM.
#>

[CmdletBinding()]
param(
  [int]$SampleSeconds = 10,
  [double]$CpuPctThreshold = 6.0,
  [int]$MemMBThreshold = 200,
  [int]$RamWarnPct = 85,
  [string]$KeepList = "$PSScriptRoot\KeepList.txt",
  [string]$LogPath = "C:\ProgramData\SpeedBoost\SpeedBoost.log",
  [switch]$DryRun
)

# ------------------ Setup ------------------
$logDir = [IO.Path]::GetDirectoryName($LogPath)
if ($logDir) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
function Write-Log($msg) {
  $stamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  "$stamp $msg" | Tee-Object -FilePath $LogPath -Append
}

Write-Log "=== Run started ==="

# Default keep list
$defaultKeep = @(
  'explorer','powershell','pwsh','cmd','conhost','dwm','ctfmon',
  'discord','spotify','steam','chrome','msedge','firefox','opera','code',
  'devenv','obs64','notepad','teams','slack','zoom','outlook',
  'rtss','rainmeter','qbittorrent','parsecd','parsec'
)

# Load user keep list
$userKeep = @()
if (Test-Path $KeepList) {
  try {
    $userKeep = Get-Content -Path $KeepList | Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object { $_.Trim() }
    Write-Log "Loaded KeepList ($($userKeep.Count) entries)"
  } catch {
    Write-Log "WARN: Failed to read KeepList: $($_.Exception.Message)"
  }
}

$keepSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
($defaultKeep + $userKeep) | ForEach-Object { $null = $keepSet.Add($_) }

# Known background junk
$knownJunk = @(
  'OneDrive','OneDriveSetup','OneDriveStandaloneUpdater',
  'AcroCEF','AdobeCollabSync','AdobeIPCBroker','acrotray','armsvc','AGSService',
  'msedgewebview2','WidgetService','GameBarPresenceWriter','GameBarFTServer',
  'XboxApp','XboxGameBar','YourPhone','PhoneExperienceHost','SkypeApp',
  'Cortana','backgroundtaskhost','hpwuschd2','hpwcsi','DellTechHub',
  'Dell.CentralService','Dell.DCF.UA','EpicWebHelper','EpicGamesLauncher',
  'Battle.net Helper','RiotClientUx','RiotClientCrashHandler',
  'SlackHelper','TeamsBackground','TeamsUpdater','ZoomLauncher',
  'DropboxUpdate','GoogleCrashHandler','GoogleCrashHandler64','GoogleUpdate',
  'NvContainer','NVIDIA Web Helper','NVIDIA Share','NvNodeLauncher'
)

# ------------------ RAM Check ------------------
try {
  $os = Get-CimInstance Win32_OperatingSystem
  $totalMB = [math]::Round($os.TotalVisibleMemorySize / 1024)
  $freeMB  = [math]::Round($os.FreePhysicalMemory / 1024)
  $usedPct = [math]::Round((($totalMB - $freeMB) / $totalMB) * 100, 0)
  Write-Log ("RAM: {0}% used ({1} MB free / {2} MB total)" -f $usedPct, $freeMB, $totalMB)
  if ($usedPct -ge $RamWarnPct) {
    Write-Log "WARN: RAM usage ${usedPct}%"
    $ws = New-Object -ComObject WScript.Shell
    $ws.Popup("Warning: RAM usage is ${usedPct}% (threshold ${RamWarnPct}%).",5,"SpeedBoost",48) | Out-Null
  }
} catch { Write-Log "WARN: RAM check failed" }

# ------------------ Process Sampling ------------------
function Take-Snapshot {
  $snapshot = @{}
  foreach ($p in Get-Process) {
    if ($keepSet.Contains($p.ProcessName)) { continue }
    $snapshot[$p.Id] = [pscustomobject]@{
      Id=$p.Id; Name=$p.ProcessName; HasWindow=($p.MainWindowHandle -ne 0)
      CPU=$p.TotalProcessorTime.TotalSeconds; WS=$p.WorkingSet64
      IORead=$p.IOReadBytes; IOWrite=$p.IOWriteBytes
    }
  }
  return $snapshot
}

function Compare-Snapshot($a,$b,[int]$sec) {
  foreach ($id in $a.Keys) {
    if ($b.ContainsKey($id)) {
      $pa=$a[$id]; $pb=$b[$id]
      [pscustomobject]@{
        Id=$id; Name=$pa.Name; HasWindow=$pa.HasWindow
        CPU_Pct=[math]::Round((($pb.CPU - $pa.CPU)/$sec)*100,2)
        MemMB=[math]::Round($pb.WS/1MB)
        IO_Delta=[math]::Max(0,($pb.IORead+$pb.IOWrite)-($pa.IORead+$pa.IOWrite))
      }
    }
  }
}

$start=Take-Snapshot
Start-Sleep -Seconds $SampleSeconds
$end=Take-Snapshot
$rows=Compare-Snapshot $start $end $SampleSeconds

$targets=@()
$targets += $rows | Where-Object { -not $_.HasWindow -and ($_.CPU_Pct -ge $CpuPctThreshold -or $_.MemMB -ge $MemMBThreshold) }
$targets += $rows | Where-Object { -not $_.HasWindow -and ($_.Name -in $knownJunk) -and $_.CPU_Pct -lt 1 }
$targets = $targets | Sort-Object Name -Unique

if (-not $targets -or $targets.Count -eq 0) {
  Write-Log "No background targets found."
  Write-Host "No background targets found."
  Write-Log "=== Run complete ==="
  exit
}

Write-Host "Targets to stop:"
$targets | Sort-Object CPU_Pct -Descending | Format-Table Name,CPU_Pct,MemMB -AutoSize

$stopped=@(); $failed=@()

foreach ($t in $targets) {
  try {
    $procs = Get-Process -Name $t.Name -ErrorAction Stop | Where-Object { $_.MainWindowHandle -eq 0 -and -not $keepSet.Contains($_.ProcessName) }
    if ($DryRun) {
      Write-Log ("DRYRUN: Would stop {0} (CPU {1}% | {2} MB)" -f $t.Name,$t.CPU_Pct,$t.MemMB)
      continue
    }
    foreach ($p in $procs) { Stop-Process -Id $p.Id -Force -ErrorAction Stop }
    $stopped += $t.Name
    Write-Log ("KILLED: {0} (CPU {1}% | {2} MB)" -f $t.Name,$t.CPU_Pct,$t.MemMB)
  } catch {
    $failed += $t.Name
    Write-Log ("FAIL: {0} — {1}" -f $t.Name,$_.Exception.Message)
  }
}

# ------------------ Cleanup ------------------
try {
  $tempPaths=@("$env:TEMP","$env:WINDIR\Temp")
  foreach ($path in $tempPaths) {
    Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
  }
  Write-Log "Temp files cleaned."
} catch { Write-Log "WARN: Temp cleanup failed" }

try { [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); Write-Log "Memory GC triggered." } catch {}

# ------------------ Summary ------------------
function Join-OrNone($arr) { if ($arr -and $arr.Count -gt 0) { return ($arr -join ', ') } else { return '(none)' } }

$stoppedUnique=@(); $failedUnique=@()
if ($stopped) { $stoppedUnique=$stopped | Sort-Object -Unique }
if ($failed)  { $failedUnique=$failed | Sort-Object -Unique }

$stoppedText=Join-OrNone $stoppedUnique
$failedText=Join-OrNone $failedUnique

Write-Host "`nSummary"
Write-Host "Stopped: $stoppedText"
Write-Host "Failed:  $failedText"

Write-Log "SUMMARY: Stopped: $stoppedText"
Write-Log "SUMMARY: Failed:  $failedText"
Write-Log "=== Run complete ==="
