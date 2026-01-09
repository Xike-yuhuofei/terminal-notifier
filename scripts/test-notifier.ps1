# test-notifier.ps1
# Claude Code 通知系统测试脚本

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Claude Code 通知系统测试" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# 设置测试环境
$env:CLAUDE_PLUGIN_ROOT = Split-Path -Parent $PSScriptRoot
$env:CLAUDE_PROJECT_DIR = Get-Location
$env:CLAUDE_NOTIFY_DEBUG = "true"

Write-Host "插件根目录: $env:CLAUDE_PLUGIN_ROOT" -ForegroundColor Gray
Write-Host "项目目录: $env:CLAUDE_PROJECT_DIR" -ForegroundColor Gray
Write-Host ""

# 测试函数
function Test-Notification {
    param(
        [string]$Name,
        [string]$EventType,
        [string]$Context
    )

    Write-Host "测试: $Name" -ForegroundColor Yellow
    $notifyScript = Join-Path $env:CLAUDE_PLUGIN_ROOT "scripts\notify.ps1"
    & $notifyScript -EventType $EventType -Context $Context
    Start-Sleep -Seconds 2
    Write-Host ""
}

Write-Host "开始测试..." -ForegroundColor Green
Write-Host ""

# 测试 1: 蓝色状态（工作中）
Test-Notification -Name "蓝色 - 思考中" -EventType "working" -Context "💭 Thinking..."

# 测试 2: 蓝色状态（执行中）
Test-Notification -Name "蓝色 - 执行 Bash" -EventType "working" -Context "⚙️ Running: Bash"

# 测试 3: 红色状态（需要人）
Test-Notification -Name "红色 - 准备停止" -EventType "needs_human" -Context "[?] Ready to Stop?"

# 测试 4: 红色状态（错误）
Test-Notification -Name "红色 - 工具失败" -EventType "error" -Context "[!] Bash failed"

# 测试 5: 绿色状态（成功）
Test-Notification -Name "绿色 - 成功完成" -EventType "success" -Context "✅ Done"

# 测试 6: 会话结束
Test-Notification -Name "黑色 - 会话结束" -EventType "session_end" -Context "Bye"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "测试完成！" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "检查状态文件..." -ForegroundColor Yellow
$stateDir = Join-Path $env:CLAUDE_PLUGIN_ROOT ".states"
if (Test-Path $stateDir) {
    $stateFiles = Get-ChildItem -Path $stateDir -Filter "notification-state-*.json"
    Write-Host "找到 $($stateFiles.Count) 个状态文件:" -ForegroundColor Gray
    $stateFiles | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor DarkGray
    }
}
else {
    Write-Host "状态文件目录不存在" -ForegroundColor Red
}

Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
