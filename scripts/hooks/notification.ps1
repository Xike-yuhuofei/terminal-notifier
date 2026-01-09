# notification.ps1
# Claude Code Hook: Notification
# Handles Claude Code notification events with visual/audio feedback

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# Get script and module paths
$ScriptDir = Split-Path -Parent $PSCommandPath
$ModuleRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$LibPath = Join-Path $ModuleRoot "lib"

# Import modules
Import-Module (Join-Path $LibPath "StateManager.psm1") -Force
Import-Module (Join-Path $LibPath "OscSender.psm1") -Force
Import-Module (Join-Path $LibPath "NotificationEnhancements.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $LibPath "ToastNotifier.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $LibPath "PersistentTitle.psm1") -Force -ErrorAction SilentlyContinue

try {
    # Read hook input from stdin
    $inputJson = [Console]::In.ReadToEnd()
    $hookData = $inputJson | ConvertFrom-Json

    $sessionId = $hookData.session_id
    $cwd = $hookData.cwd

    # Get project name
    $projectName = Split-Path -Leaf $cwd

    # Notification events typically mean Claude needs attention
    # Update state to indicate notification received
    Set-CurrentState -State "yellow" -Reason "Notification" -ProjectName $projectName

    # Get custom window name if set
    $windowName = ""
    try {
        $windowName = Get-WindowDisplayName
    }
    catch {
        # Fallback to project name
        $windowName = $projectName
    }

    # 显示持久化标题通知（极简UI组件）- 自动5秒后清除
    $displayTitle = if ($windowName -and $windowName -ne $projectName) {
        "[📢 $windowName] 通知"
    } else {
        "[📢] 通知 - $projectName"
    }
    Show-TitleNotification -Title $displayTitle -Type "Notification" -Duration 5

    # Legacy: Set visual notification for compatibility
    $title = "[N] Notification - $projectName"
    Set-NotificationVisual -State "yellow" -Title $title | Out-Null

    # Ring bell once for notification
    Invoke-TerminalBell -Times 1 -SoundType 'Asterisk'

    # Send Windows Toast notification
    try {
        $windowName = Get-WindowDisplayName
        Send-NotificationToast -WindowName $windowName -ProjectName $projectName
    }
    catch {
        # Toast failure should not block Hook execution
    }

    # Brief pause then return to ready state
    Start-Sleep -Seconds 1

    # Return to blue (ready) state
    Set-CurrentState -State "blue" -Reason "Ready" -ProjectName $projectName

    # Only restore tab color, don't set a persistent title
    # The title will be managed by other hooks or the shell itself

    exit 0
}
catch {
    # Don't block notification on errors
    exit 0
}
