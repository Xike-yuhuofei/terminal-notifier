param(
    [string]$Title = "Claude Code",
    [string]$Message = "Notification",
    [int]$Duration = 5000
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.Visible = $true
$notify.ShowBalloonTip($Duration, $Title, $Message, [System.Windows.Forms.ToolTipIcon]::Info)
Start-Sleep -Seconds 3
$notify.Dispose()
