# stop-basic.ps1
# Claude Code Hook: Stop (Basic Version)
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

    # 1. Build title
    if ($windowName -and $windowName -ne $projectName) {
        $title = "[⚠️ $windowName] 需要输入 - $projectName"
    } else {
        $title = "[⚠️] 需要输入 - $projectName"
    }

    # 2. Write to persistent state file (for UserPromptSubmit Hook to clear)
    try {
        $stateDir = Join-Path $ModuleRoot ".states"
        if (-not (Test-Path $stateDir)) {
            New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
        }

        $titleFile = Join-Path $stateDir "stop-title.txt"
        $titleData = @{
            title = $title
            projectName = $projectName
            windowName = $windowName
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json -Compress

        $titleData | Out-File -FilePath $titleFile -Encoding UTF8 -Force
    }
    catch {
        # State file write failure should not block Hook execution
    }

    # 3. Display custom window name in terminal title (using TabTitleManager)
    try {
        if ($windowName -and $windowName -ne $projectName) {
            Set-TabTitleForHook -HookType "Stop" -ProjectName $projectName -WindowName $windowName
        } else {
            Set-TabTitleForHook -HookType "Stop" -ProjectName $projectName
        }
    }
    catch {
        # Fallback to direct RawUI setting if TabTitleManager fails
        if ($windowName -and $windowName -ne $projectName) {
            $Host.UI.RawUI.WindowTitle = "[⚠️ $windowName] 需要输入 - $projectName"
        } else {
            $Host.UI.RawUI.WindowTitle = "[⚠️] 需要输入 - $projectName"
        }
    }

    # 4. Ring bell for attention (1 time)
    Invoke-TerminalBell -Times 1 -SoundType 'Asterisk'

    # 3. Send Windows Toast notification
    try {
        Send-StopToast -WindowName $windowName -ProjectName $projectName
    }
    catch {
        # Toast failure should not block Hook execution
    }

    exit 0
}
catch {
    # Don't interfere with Claude's stop behavior on errors
    exit 0
}
