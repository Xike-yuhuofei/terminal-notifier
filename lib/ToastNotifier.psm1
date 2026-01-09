# ToastNotifier.psm1
# Terminal Notifier - Windows Toast Notification Module
# Requires BurntToast module (fallback to sound/flash)

function Test-ToastSupport {
    <#
    .SYNOPSIS
        Check if Windows Toast notifications are supported
    .OUTPUTS
        System.Boolean
    #>
    try {
        $module = Get-Module -ListAvailable BurntToast -ErrorAction SilentlyContinue
        if ($module) {
            Import-Module BurntToast -ErrorAction Stop
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

function Send-WindowsToast {
    <#
    .SYNOPSIS
        Send Windows Toast notification
    .PARAMETER Title
        Toast title
    .PARAMETER Message
        Toast message body
    .PARAMETER AppLogo
        Optional app icon (emoji or file path)
    .PARAMETER SoundType
        System sound: Default, Alarm, Call, Reminder, SMS (default: Default)
    .PARAMETER LongDuration
        Use long duration (~25 seconds maximum for Windows Toast)
    .EXAMPLE
        Send-WindowsToast -Title "Task Complete" -Message "Build succeeded"
        Send-WindowsToast -Title "Error" -Message "Test failed" -SoundType "Alarm"
        Send-WindowsToast -Title "Long task" -Message "Please wait" -LongDuration
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [string]$AppLogo = "",

        [ValidateSet("Default", "Alarm", "Call", "Reminder", "SMS", "Silent")]
        [string]$SoundType = "Silent",  # 禁用 Toast 音效，避免叠加

        [switch]$LongDuration = $true  # 默认使用长持续时间 (~25秒)
    )

    # Check if BurntToast is available
    if (-not (Test-ToastSupport)) {
        Write-Warning "BurntToast module not available, using fallback notification"

        # Fallback: Bell + Title flash
        Import-Module (Join-Path $PSScriptRoot "NotificationEnhancements.psm1") -Force

        $bellType = switch ($SoundType) {
            "Alarm" { "Asterisk" }
            "Call" { "Asterisk" }
            default { "Asterisk" }
        }

        #         Invoke-TerminalBell -Times 2 -SoundType $bellType
        Invoke-TitleFlash -Title $Title -Times 3

        return $false
    }

    try {
        # Build toast parameters
        $toastParams = @{
            Text = @($Title, $Message)
        }

        # Add sound
        if ($SoundType -ne "Silent") {
            $toastParams['Sound'] = $SoundType
        }

        # Add app logo if specified
        if ($AppLogo -and (Test-Path $AppLogo)) {
            $toastParams['AppLogo'] = $AppLogo
        }

        # Add ExpirationTime to extend display time (通知在操作中心保留更长时间)
        if ($LongDuration) {
            $toastParams['ExpirationTime'] = (Get-Date).AddSeconds(30)
        }

        # Send toast
        New-BurntToastNotification @toastParams -ErrorAction Stop

        return $true
    }
    catch {
        Write-Warning "Failed to send toast notification: $_"

        # Fallback to sound notification
        Import-Module (Join-Path $PSScriptRoot "NotificationEnhancements.psm1") -Force
        #         Invoke-TerminalBell -Times 2 -SoundType "Asterisk"

        return $false
    }
}

function Send-StopToast {
    <#
    .SYNOPSIS
        Send Stop Hook toast notification
    .PARAMETER WindowName
        Window/tab display name
    .PARAMETER ProjectName
        Project name
    .EXAMPLE
        Send-StopToast -WindowName "编译测试" -ProjectName "Backend_CPP"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$WindowName,

        [string]$ProjectName = ""
    )

    $title = if ($ProjectName) {
        "[$WindowName] 需要输入 - $ProjectName"
    } else {
        "[$WindowName] 需要输入"
    }

    $message = "Claude Code 正在等待您的响应"

    Send-WindowsToast -Title $title -Message $message -SoundType "Silent"  # 禁用音效
}

function Send-NotificationToast {
    <#
    .SYNOPSIS
        Send Notification Hook toast notification
    .PARAMETER WindowName
        Window/tab display name
    .PARAMETER ProjectName
        Project name
    .EXAMPLE
        Send-NotificationToast -WindowName "代码审查" -ProjectName "Backend_CPP"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$WindowName,

        [string]$ProjectName = ""
    )

    $title = if ($ProjectName) {
        "[$WindowName] 通知 - $ProjectName"
    } else {
        "[$WindowName] 通知"
    }

    $message = "Claude Code 有新通知"

    Send-WindowsToast -Title $title -Message $message -SoundType "Silent"  # 禁用音效
}

# Export functions
Export-ModuleMember -Function @(
    'Test-ToastSupport',
    'Send-WindowsToast',
    'Send-StopToast',
    'Send-NotificationToast'
)
