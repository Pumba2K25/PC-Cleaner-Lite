SpeedBoost for Windows
A lightweight, script-based performance optimizer for Windows

Stops background junk, cleans temporary files, and automatically maintains your PC’s performance — safely and transparently.

⚡ Features

🕐 Weekly Auto-Run: Automatically scheduled via Windows Task Scheduler.

🧠 Smart Process Detection: Finds and kills background apps hogging CPU or RAM.

🧹 Temp Cleanup: Deletes %TEMP% and C:\Windows\Temp files weekly.

💾 Memory Optimization: Frees RAM and warns if system memory exceeds safe levels.

📜 Logging: All actions logged to C:\ProgramData\SpeedBoost\SpeedBoost.log.

🛑 Whitelist Support: KeepList.txt ensures critical apps stay untouched.

📂 Folder Layout
C:\ProgramData\SpeedBoost\
│
├── SpeedBoost.ps1              # Main performance optimization script
├── Install-SpeedBoostTask.ps1  # Creates weekly auto-run task
├── KeepList.txt                # Optional process whitelist
└── SpeedBoost.log              # Auto-generated log file

🚀 Installation

Copy the files into:

C:\ProgramData\SpeedBoost\


Open PowerShell as Administrator, then run:

Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
& "C:\ProgramData\SpeedBoost\Install-SpeedBoostTask.ps1"


Confirm the task exists in Task Scheduler under:

Task Scheduler Library → SpeedBoost Weekly

🧩 Manual Usage

Run anytime:

powershell -ExecutionPolicy Bypass -File "C:\ProgramData\SpeedBoost\SpeedBoost.ps1"

Optional Parameters
Parameter	Default	Description
-SampleSeconds	10	How long to sample processes before judging heavy usage
-CpuPctThreshold	6	CPU% threshold to consider a process heavy
-MemMBThreshold	200	Memory (MB) threshold to consider a process heavy
-RamWarnPct	85	Show warning popup if RAM usage above this %
-DryRun	—	Preview actions without killing anything
📝 Logs

All activity is logged to:

C:\ProgramData\SpeedBoost\SpeedBoost.log


Example:

2025-10-16 12:00:03 === Run started (Sample=10s, CPU>=6%, MEM>=200MB)
2025-10-16 12:00:14 KILLED: OneDrive (CPU 0.5% | 45 MB)
2025-10-16 12:00:15 CLEAN: Temp directories purged.
2025-10-16 12:00:16 SUMMARY: Stopped: OneDrive
2025-10-16 12:00:16 === Run complete ===

🧾 KeepList Example

KeepList.txt

steam
spotify
discord
parsecd
obs64


These processes will never be closed, even if heavy.

🛠️ Uninstall

To remove SpeedBoost:

Unregister-ScheduledTask -TaskName "SpeedBoost Weekly" -Confirm:$false
Remove-Item -Path "C:\ProgramData\SpeedBoost" -Recurse -Force

💡 Recommendations

Use High Performance power plan (powercfg.cpl)

Disable unnecessary Startup apps via Task Manager

Clean disk manually using cleanmgr /sageset:1 and cleanmgr /sagerun:1

Add trusted apps to KeepList.txt if needed

🧠 Author

Pumba
Windows SysAdmin / Optimization Enthusiast
Built for performance without bloatware 💪
