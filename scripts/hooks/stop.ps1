# stop.ps1
# Claude Code Hook: Stop
# 在 Claude 停止等待用户输入时触发

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
Import-Module (Join-Path $LibPath "PersistentTitle.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $LibPath "StateManager.psm1") -Force -ErrorAction SilentlyContinue

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
        $windowName = $projectName
    }

    # === 1. 构建标题 ===
    if ($windowName -and $windowName -ne $projectName) {
        $title = "[⚠️ $windowName] 需要输入 - $projectName"
    } else {
        $title = "[⚠️] 需要输入 - $projectName"
    }

    # === 2. 设置持久化标题（使用 PersistentTitle 模块）===
    try {
        # 使用 PersistentTitle 模块设置标题（后台线程持续刷新，不自动清除）
        Set-PersistentTitle -Title $title -State "red" -Duration 0
    }
    catch {
        # 标题设置失败不应阻止 Hook 执行
    }

    # === 3. 播放音效 ===
    Invoke-TerminalBell -Times 2 -SoundType 'Exclamation'

    # === 4. 发送 Toast 通知 ===
    try {
        Send-StopToast -WindowName $windowName -ProjectName $projectName
    }
    catch {
        # Toast 失败不应阻止 Hook 执行
    }

    exit 0
}
catch {
    # 不干扰 Claude 的 stop 行为
    exit 0
}
