# test-custom-window-name.ps1
# 测试基础版 Hook 自定义窗口名称功能

#Requires -Version 5.1
$ErrorActionPreference = "Continue"

$ModuleRoot = "C:\Users\Xike\.claude\tools\terminal-notifier"

Write-Host ""
Write-Host "=== 测试基础版 Stop Hook（带自定义窗口名称）===" -ForegroundColor Cyan
Write-Host ""

# 设置环境变量（模拟 ccs 命令）
$env:CLAUDE_WINDOW_NAME = "编译测试"
Write-Host "📝 设置环境变量 CLAUDE_WINDOW_NAME: $env:CLAUDE_WINDOW_NAME" -ForegroundColor Yellow
Write-Host ""

# 模拟 Stop Hook 输入
$testInput = @{
    session_id = [Guid]::NewGuid().ToString()
    cwd = "C:\Users\Xike\test-project"
    stop_hook_active = $false
} | ConvertTo-Json -Compress

Write-Host "🔔 Hook 输入：" -ForegroundColor Yellow
Write-Host $testInput
Write-Host ""

Write-Host "⚡ 执行 Stop Hook..." -ForegroundColor Green
$testInput | & "$ModuleRoot\scripts\hooks\stop-basic.ps1"

Write-Host ""
Write-Host "=== 测试基础版 Notification Hook（带自定义窗口名称）===" -ForegroundColor Cyan
Write-Host ""

# 模拟 Notification Hook 输入
$testInput2 = @{
    session_id = [Guid]::NewGuid().ToString()
    cwd = "C:\Users\Xike\test-project"
} | ConvertTo-Json -Compress

Write-Host "🔔 Hook 输入：" -ForegroundColor Yellow
Write-Host $testInput2
Write-Host ""

Write-Host "⚡ 执行 Notification Hook..." -ForegroundColor Green
Write-Host "注意：此 Hook 会等待 5 秒后清除标题" -ForegroundColor DarkGray
$testInput2 | & "$ModuleRoot\scripts\hooks\notification-basic.ps1"

Write-Host ""
Write-Host "=== 测试完成 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "预期效果：" -ForegroundColor Yellow
Write-Host "  ✅ 终端标题显示: [⚠️ 编译测试] 需要输入 - test-project" -ForegroundColor White
Write-Host "  ✅ Toast 通知显示: [编译测试] 需要输入 - test-project" -ForegroundColor White
Write-Host "  ✅ 听到 2 次 Asterisk 音效" -ForegroundColor White
Write-Host ""
Write-Host "清除环境变量..." -ForegroundColor DarkGray
Remove-Item Env:\CLAUDE_WINDOW_NAME -ErrorAction SilentlyContinue
Write-Host ""
