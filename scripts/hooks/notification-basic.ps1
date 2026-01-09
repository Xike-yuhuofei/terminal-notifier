# notification-basic.ps1
# Claude Code Hook: Notification (Basic Version)
# 基础版：音效 + Toast + 自定义窗口标题
#
# 功能：
# - 音效通知（系统提示音）
# - Windows Toast 通知
# - 自定义窗口标题显示（使用 ccs 命令设置的窗口名称）
#
# 不包含：
# - 状态管理
# - 持久化标题
# - OSC 标签页颜色
# - 状态切换逻辑

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# Get script and module paths
$ScriptDir = Split-Path -Parent $PSCommandPath
$ModuleRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$LibPath = Join-Path $ModuleRoot "lib"

# Import modules
Import-Module (Join-Path $LibPath "NotificationEnhancements.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $LibPath "ToastNotifier.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $LibPath "StateManager.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $LibPath "TabTitleManager.psm1") -Force -ErrorAction SilentlyContinue

try {
    # Read hook input from stdin
    $inputJson = [Console]::In.ReadToEnd()
    $hookData = $inputJson | ConvertFrom-Json

    $cwd = $hookData.cwd
    $projectName = Split-Path -Leaf $cwd

    # Get custom window name (set by ccs command)
    $windowName = ""
    try {
        $windowName = Get-WindowDisplayName
    }
    catch {
        # Fallback to project name
        $windowName = $projectName
    }

    # === BASIC VERSION: Sound + Toast + Window Title ===

    # 1. Display custom window name in terminal title (using TabTitleManager)
    try {
        if ($windowName -and $windowName -ne $projectName) {
            Set-TabTitleForHook -HookType "Notification" -ProjectName $projectName -WindowName $windowName
        } else {
            Set-TabTitleForHook -HookType "Notification" -ProjectName $projectName
        }
    }
    catch {
        # Fallback to direct RawUI setting if TabTitleManager fails
        if ($windowName -and $windowName -ne $projectName) {
            $Host.UI.RawUI.WindowTitle = "[📢 $windowName] 通知 - $projectName"
        } else {
            $Host.UI.RawUI.WindowTitle = "[📢] 通知 - $projectName"
        }
    }

    # 2. Ring bell once for notification
    Invoke-TerminalBell -Times 1 -SoundType 'Asterisk'

    # 3. Send Windows Toast notification
    try {
        Send-NotificationToast -WindowName $windowName -ProjectName $projectName
    }
    catch {
        # Toast failure should not block Hook execution
    }

    # Note: Notification title will be automatically cleared by the shell
    # No need to set a persistent "clear" title

    exit 0
}
catch {
    # Don't block notification on errors
    exit 0
}
