# stop-with-persistence.ps1
# Claude Code Hook: Stop (带 UserPromptSubmit 持久化)
#
# 工作原理：
# 1. 设置标题（即时效果，可能在子进程中无效）
# 2. 写入状态文件（供 UserPromptSubmit Hook 使用）
# 3. 播放音效
# 4. 发送 Toast 通知
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
    }
    catch {
        # Fallback to project name
        $windowName = $projectName
    }

    # === 1. 构建标题 ===
    if ($windowName -and $windowName -ne $projectName) {
        $title = "[⚠️ $windowName] 需要输入 - $projectName"
    } else {
        $title = "[⚠️] 需要输入 - $projectName"
    }

    # === 2. 尝试即时设置标题（可能无效，因为是在子进程中）===
    try {
        $Host.UI.RawUI.WindowTitle = $title
        $ESC = [char]27
        $BEL = [char]7
        Write-Host "$ESC]0;$title$BEL" -NoNewline
    }
    catch {
        # 忽略标题设置失败
    }

    # === 3. 写入持久化状态文件（供 UserPromptSubmit Hook 使用）===
    try {
        $stateDir = Join-Path $ModuleRoot ".states"
        if (-not (Test-Path $stateDir)) {
            New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
        }

        $titleFile = Join-Path $stateDir "persistent-title.txt"
        $titleData = @{
            title = $title
            hookType = "Stop"
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json -Compress

        $titleData | Out-File -FilePath $titleFile -Encoding UTF8 -Force
    }
    catch {
        # 状态文件写入失败不应阻止 Hook 执行
    }

    # === 4. 播放音效 ===
    Invoke-TerminalBell -Times 1 -SoundType 'Asterisk'

    # === 5. 发送 Toast 通知 ===
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
