# analyze-result.ps1
# 分析工具执行结果并更新通知状态
#
# 用法:
#   .\analyze-result.ps1 -ToolName "Bash"

param(
    [Parameter(Mandatory=$true)]
    [string]$ToolName
)

# 导入模块
$modulePath = Join-Path $env:CLAUDE_PLUGIN_ROOT "lib"
Import-Module (Join-Path $modulePath "StateManager.psm1") -Force

# 调试输出
function Write-DebugOutput {
    param([string]$Message)
    if ($env:CLAUDE_NOTIFY_DEBUG) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [AnalyzeResult] $Message" -ForegroundColor DarkGray
    }
}

# 分析工具结果（从 stdin 读取）
function Analyze-ToolResult {
    param([string]$ToolName)

    # 读取 stdin（工具输出）
    $inputData = @($Input)

    if ($inputData.Count -eq 0) {
        Write-DebugOutput "没有输入数据"
        return "continue"
    }

    $output = $inputData -join "`n"
    Write-DebugOutput "工具输出: $($output.Substring(0, [Math]::Min(200, $output.Length)))..."

    # 检查错误关键词
    $errorPatterns = @(
        "error", "Error", "ERROR",
        "failed", "Failed", "FAILED",
        "exception", "Exception",
        "fatal", "Fatal", "FATAL",
        "cannot", "Cannot", "CANNOT",
        "unable to", "Unable to", "UNABLE TO"
    )

    foreach ($pattern in $errorPatterns) {
        if ($output -like "*$pattern*") {
            Write-DebugOutput "检测到错误关键词: $pattern"
            return "error"
        }
    }

    # 检查警告关键词
    $warningPatterns = @(
        "warning", "Warning", "WARNING",
        "deprecated", "Deprecated"
    )

    foreach ($pattern in $warningPatterns) {
        if ($output -like "*$pattern*") {
            Write-DebugOutput "检测到警告关键词: $pattern"
            return "warning"
        }
    }

    # 默认：正常执行
    Write-DebugOutput "未检测到错误或警告"
    return "success"
}

try {
    Write-DebugOutput "分析工具: $ToolName"

    # 分析结果
    $result = Analyze-ToolResult -ToolName $ToolName

    # 根据结果调用 notify.ps1
    switch ($result) {
        "error" {
            Write-DebugOutput "结果: 错误 - 需要用户介入"

            & powershell -NoProfile -ExecutionPolicy Bypass `
                -File "$env:CLAUDE_PLUGIN_ROOT/scripts/notify.ps1" `
                -EventType "error" `
                -Context "[!] $ToolName failed"
        }
        "warning" {
            Write-DebugOutput "结果: 警告 - 但可继续"

            & powershell -NoProfile -ExecutionPolicy Bypass `
                -File "$env:CLAUDE_PLUGIN_ROOT/scripts/notify.ps1" `
                -EventType "working" `
                -Context "⚠️  $ToolName completed with warnings"
        }
        "success" {
            Write-DebugOutput "结果: 成功 - 继续工作"

            & powershell -NoProfile -ExecutionPolicy Bypass `
                -File "$env:CLAUDE_PLUGIN_ROOT/scripts/notify.ps1" `
                -EventType "working" `
                -Context "🔄 $ToolName completed"
        }
        default {
            Write-DebugOutput "结果: 未知 - 默认继续"

            & powershell -NoProfile -ExecutionPolicy Bypass `
                -File "$env:CLAUDE_PLUGIN_ROOT/scripts/notify.ps1" `
                -EventType "working" `
                -Context "🔄 Processing..."
        }
    }
}
catch {
    Write-Warning "分析工具结果失败: $_"
    exit 1
}
