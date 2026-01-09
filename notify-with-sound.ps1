param(
    [string]$Title = "Claude Code",
    [string]$Message = "Notification",
    [string]$Sound = "",  # 空字符串表示使用默认声音，或指定 Windows 系统音频文件路径
    [int]$Duration = 5000
)

# 显示桌面通知
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.Visible = $true
$notify.ShowBalloonTip($Duration, $Title, $Message, [System.Windows.Forms.ToolTipIcon]::Info)

# 播放声音（如果指定）
if ($Sound -ne "") {
    if (Test-Path $Sound) {
        # 播放指定的音频文件
        $soundPlayer = New-Object System.Media.SoundPlayer
        $soundPlayer.SoundLocation = $Sound
        $soundPlayer.Play()
    } else {
        # 尝试播放 Windows 系统声音
        try {
            $soundPlayer = New-Object System.Media.SoundPlayer
            $soundPlayer.SoundLocation = $Sound
            $soundPlayer.Play()
        } catch {
            # 降级到系统提示音
            [System.Media.SystemSounds]::Beep.Play()
        }
    }
}

Start-Sleep -Seconds 3
$notify.Dispose()
