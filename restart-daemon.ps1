Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -NoProfile -File "C:\Users\Xike\.claude\plugins\windows-terminal-tab-color\hooks\scripts\start-title-daemon.ps1"' -WindowStyle Hidden
Start-Sleep -Seconds 2
$daemonPid = Get-Content 'C:\Users\Xike\.claude\title-daemon.pid'
Write-Host "Daemon restarted with PID: $daemonPid"
