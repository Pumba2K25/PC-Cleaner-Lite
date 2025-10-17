# 🧠 SpeedBoost for Windows

Lightweight PowerShell maintenance: kills unnecessary background tasks, cleans temp files, frees RAM, and warns when memory is high. Auto-runs weekly via Task Scheduler.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## ⚡ Features
- Weekly auto-run (SYSTEM, highest privileges)
- Detects heavy background apps (CPU/Mem thresholds)
- Cleans `%TEMP%` + `C:\Windows\Temp`
- RAM warning + full logging to `C:\ProgramData\SpeedBoost\SpeedBoost.log`
- Whitelist via `KeepList.txt`

## Quick Start (copy–paste)
Open **PowerShell as Administrator**:
```powershell
$dst = "C:\ProgramData\SpeedBoost"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Invoke-WebRequest -UseBasicParsing -OutFile "$dst\SpeedBoost.ps1" -Uri "https://raw.githubusercontent.com/Pumba2K25/PC-Cleaner-Lite/main/SpeedBoost.ps1"
Invoke-WebRequest -UseBasicParsing -OutFile "$dst\Install-SpeedBoostTask.ps1" -Uri "https://raw.githubusercontent.com/Pumba2K25/PC-Cleaner-Lite/main/Install-SpeedBoostTask.ps1"
Invoke-WebRequest -UseBasicParsing -OutFile "$dst\KeepList.txt" -Uri "https://raw.githubusercontent.com/Pumba2K25/PC-Cleaner-Lite/main/KeepList.txt"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
& "$dst\Install-SpeedBoostTask.ps1"
