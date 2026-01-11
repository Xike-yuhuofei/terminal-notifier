# notification-with-persistence.ps1
# Claude Code Hook: Notification (带 UserPromptSubmit 持久化)
#
# 工作原理：
# 1. 设置标题（即时效果，可能在子进程中无效）
# 2. 写入状态文件（供 UserPromptSubmit Hook 使用）
# 3. 播放音效
# 4. 发送 Toast 通知
# 5. 5秒后自动清除标题
#
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

        # 如果Get-WindowDisplayName返回项目名称，尝试从保存的文件读取自定义标题
        if ($windowName -eq $projectName) {
            $stateDir = Join-Path $ModuleRoot ".states"
            $originalTitleFile = Join-Path $stateDir "original-title.txt"

            if (Test-Path $originalTitleFile) {
                $savedTitle = Get-Content $originalTitleFile -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
                if ($savedTitle -and $savedTitle -ne "" -and $savedTitle -ne $projectName) {
                    $windowName = $savedTitle
                }
            }
        }
    }
    catch {
        # Fallback to project name
        $windowName = $projectName
    }

    # === 1. 构建标题 ===
    # 读取 SessionStart 保存的原始标题
    $stateDir = Join-Path $ModuleRoot ".states"
    $originalTitleFile = Join-Path $stateDir "original-title.txt"

    if (Test-Path $originalTitleFile) {
        # 使用原始标题（ccs 设置的）
        $originalTitle = Get-Content $originalTitleFile -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
        $title = "[📢] $originalTitle"
    } else {
        # 回退到默认逻辑
        if ($windowName -and $windowName -ne $projectName) {
            $title = "[📢 $windowName] 新通知 - $projectName"
        } else {
            $title = "[📢] 新通知 - $projectName"
        }
    }

    # === 2. 设置持久化标题（使用 PersistentTitle 模块）===
    try {
        # 使用 PersistentTitle 模块设置标题（后台线程持续刷新，5秒后自动清除）
        Set-PersistentTitle -Title $title -State "yellow" -Duration 5
    }
    catch {
        # 标题设置失败不应阻止 Hook 执行
    }

    # === 4. 播放音效 ===
    Invoke-TerminalBell -Times 1 -SoundType 'Asterisk'

    # === 5. 发送 Toast 通知 ===
    try {
        # 总是使用 $windowName（来自 CLAUDE_WINDOW_NAME 环境变量）
        Send-NotificationToast -WindowName $windowName -ProjectName $projectName
    }
    catch {
        # Toast 失败不应阻止 Hook 执行
    }

    exit 0
}
catch {
    # 不干扰 Claude 的 notification 行为
    exit 0
}
