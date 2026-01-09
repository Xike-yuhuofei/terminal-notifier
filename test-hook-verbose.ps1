# test-hook-verbose.ps1
# 调试版本：带有详细日志的 Stop Hook
# 用于诊断为什么标题没有显示

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Get script and module paths
$ScriptDir = Split-Path -Parent $PSCommandPath
$ModuleRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$LibPath = Join-Path $ModuleRoot "lib"

# Create log file
$logFile = Join-Path $ModuleRoot "debug-hook.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Log {
    param([string]$Message)
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $Message -ForegroundColor Cyan
}

Write-Log "=== Hook 调试开始 ==="
Write-Log "脚本路径: $PSCommandPath"
Write-Log "模块根目录: $ModuleRoot"

try {
    Write-Log "读取 Hook 输入..."

    # Read hook input from stdin
    $inputJson = [Console]::In.ReadToEnd()
    Write-Log "Hook 输入: $inputJson"

    $hookData = $inputJson | ConvertFrom-Json

    $cwd = $hookData.cwd
    $projectName = Split-Path -Leaf $cwd

    Write-Log "项目名称: $projectName"
    Write-Log "工作目录: $cwd"

    # Get custom window name (set by ccs command)
    $windowName = ""
    try {
        $windowName = Get-WindowDisplayName
        Write-Log "窗口名称: $windowName"
    }
    catch {
        Write-Log "获取窗口名称失败: $_"
        $windowName = $projectName
    }

    # Import modules
    Write-Log "导入模块..."

    Import-Module (Join-Path $LibPath "NotificationEnhancements.psm1") -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $LibPath "ToastNotifier.psm1") -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $LibPath "StateManager.psm1") -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $LibPath "TabTitleManager.psm1") -Force -ErrorAction SilentlyContinue

    Write-Log "模块导入完成"

    # Build title
    if ($windowName -and $windowName -ne $projectName) {
        $title = "[⚠️ $windowName] 需要输入 - $projectName"
    } else {
        $title = "[⚠️] 需要输入 - $projectName"
    }

    Write-Log "目标标题: $title"

    # Method 1: Direct RawUI
    Write-Log "方法 1: 设置 RawUI.WindowTitle..."
    try {
        $oldTitle = $Host.UI.RawUI.WindowTitle
        Write-Log "  原标题: $oldTitle"

        $Host.UI.RawUI.WindowTitle = $title

        $newTitle = $Host.UI.RawUI.WindowTitle
        Write-Log "  新标题: $newTitle"

        if ($newTitle -eq $title) {
            Write-Log "  ✅ RawUI 设置成功"
        } else {
            Write-Log "  ⚠️  RawUI 设置后标题不匹配"
        }
    }
    catch {
        Write-Log "  ❌ RawUI 设置失败: $_"
    }

    # Method 2: OSC sequence
    Write-Log "方法 2: 发送 OSC 序列..."
    try {
        $ESC = [char]27
        $BEL = [char]7
        $oscSequence = "$ESC]0;$title$BEL"
        Write-Log "  序列: $oscSequence"
        Write-Host $oscSequence -NoNewline
        Write-Log "  ✅ OSC 序列已发送"
    }
    catch {
        Write-Log "  ❌ OSC 序列发送失败: $_"
    }

    # Method 3: Write to file (for debugging)
    Write-Log "方法 3: 写入标题文件..."
    try {
        $stateDir = Join-Path $ModuleRoot ".states"
        if (-not (Test-Path $stateDir)) {
            New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
        }

        $titleFile = Join-Path $stateDir "current-title.txt"
        $title | Out-File -FilePath $titleFile -Encoding UTF8 -Force
        Write-Log "  ✅ 标题已写入: $titleFile"
    }
    catch {
        Write-Log "  ❌ 写入标题文件失败: $_"
    }

    # Test bell
    Write-Log "测试音效通知..."
    try {
        Invoke-TerminalBell -Times 1 -SoundType 'Asterisk'
        Write-Log "  ✅ 音效已播放"
    }
    catch {
        Write-Log "  ❌ 音效播放失败: $_"
    }

    # Test Toast
    Write-Log "测试 Toast 通知..."
    try {
        Send-StopToast -WindowName $windowName -ProjectName $projectName
        Write-Log "  ✅ Toast 已发送"
    }
    catch {
        Write-Log "  ❌ Toast 发送失败: $_"
    }

    Write-Log "=== Hook 执行完成 ==="

    # Output result
    $output = @{
        success = $true
        title = $title
        timestamp = $timestamp
    } | ConvertTo-Json -Compress

    Write-Output $output

    exit 0
}
catch {
    Write-Log "❌ Hook 执行失败: $_"
    Write-Log "堆栈跟踪: $($_.ScriptStackTrace)"
    exit 0
}
