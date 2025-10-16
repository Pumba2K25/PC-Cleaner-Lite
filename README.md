# PC-Cleaner-Lite
<#.SYNOPSIS
  Weekly performance maintenance: stop heavy background junk, clean temp files, and warn on high RAM.

.PARAMETERS
  -SampleSeconds <int>      : Sampling window to decide if a process is heavy (default 10).
  -CpuPctThreshold <double> : % of a single core during the sample to count as heavy (default 6).
  -MemMBThreshold <int>     : Working Set (MB) to count as heavy (default 200).
  -RamWarnPct <int>         : Warn when overall RAM use exceeds this % (default 85).
  -KeepList <string>        : Text file with process names (no .exe) to never kill.
  -LogPath <string>         : Log file path (default C:\ProgramData\SpeedBoost\SpeedBoost.log).
  -DryRun                   : Show actions but don’t kill anything.

.NOTES
  Runs safely in user session; avoids system-critical processes; logs everything.
#>
