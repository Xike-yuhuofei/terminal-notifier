# handle-posttooluse.ps1
# 处理 PostToolUse Hook 的 prompt 结果
#
# 这个脚本接收来自 prompt hook 的输出，解析后调用 notify.ps1

param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$PromptOutput
)

Write-DebugOutput {
    param([string]$Message)
    if ($env:CLAUDE_NOTIFY_DEBUG) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [PostToolUse] $Message" -ForegroundColor DarkGray
    }
}

try {
    Write-DebugOutput "Prompt 输出: $PromptOutput"

    # 解析 prompt 输出
    if ($PromptOutput -match "^needs_human\|(.+?)\|(.+)$") {
        # 需要用户介入
        $errorType = $matches[1]
        $description = $matches[2]
        $context = "[!] $errorType`: $description"

        Write-DebugOutput "检测到需要用户介入: $errorType - $description"

        # 调用 notify.ps1
        & powershell -NoProfile -ExecutionPolicy Bypass `
            -File "$env:CLAUDE_PLUGIN_ROOT/scripts/notify.ps1" `
            -EventType "needs_human" `
            -Context $context
    }
    elseif ($PromptOutput -match "^continue\|") {
        # 不需要介入，继续工作
        $description = $matches[1]

        Write-DebugOutput "无需介入，继续: $description"

        # 调用 notify.ps1 设置为工作状态
        & powershell -NoProfile -ExecutionPolicy Bypass `
            -File "$env:CLAUDE_PLUGIN_ROOT/scripts/notify.ps1" `
            -EventType "working" `
            -Context "🔄 Processing..."
    }
    else {
        # 无法解析的输出，默认继续工作
        Write-DebugOutput "无法解析的输出，默认为继续工作"

        & powershell -NoProfile -ExecutionPolicy Bypass `
            -File "$env:CLAUDE_PLUGIN_ROOT/scripts/notify.ps1" `
            -EventType "working" `
            -Context "🔄 Processing..."
    }
}
catch {
    Write-Warning "PostToolUse 处理失败: $_"
    exit 1
}
