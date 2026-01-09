# test-advanced-hooks.ps1
# 测试高级版 Hook 功能
#
# 预期效果：
# - ✅ 听到 1 次 Asterisk 音效
# - ✅ 看到 Windows Toast 通知
# - ✅ 标题变为 [⚠️] 需要输入 - 项目名
# - ✅ 标签页背景色变为红色
# - ✅ 状态文件已创建

#Requires -Version 5.1
$ErrorActionPreference = "Continue"

$ModuleRoot = "C:\Users\Xike\.claude\tools\terminal-notifier"

Write-Host ""
Write-Host "=== 测试高级版 Stop Hook ===" -ForegroundColor Cyan
Write-Host ""

# 模拟 Stop Hook 输入
$testInput = @{
    session_id = [Guid]::NewGuid().ToString()
    cwd = "C:\Users\Xike\test-project"
    stop_hook_active = $false
} | ConvertTo-Json -Compress

Write-Host "🔔 测试输入：" -ForegroundColor Yellow
Write-Host $testInput
Write-Host ""

Write-Host "⚡ 执行高级版 Stop Hook..." -ForegroundColor Green
$testInput | & "$ModuleRoot\scripts\hooks\stop.ps1"

Write-Host ""
Write-Host "=== 测试高级版 Notification Hook ===" -ForegroundColor Cyan
Write-Host ""

# 模拟 Notification Hook 输入
$testInput2 = @{
    session_id = [Guid]::NewGuid().ToString()
    cwd = "C:\Users\Xike\test-project"
} | ConvertTo-Json -Compress

Write-Host "🔔 测试输入：" -ForegroundColor Yellow
Write-Host $testInput2
Write-Host ""

Write-Host "⚡ 执行高级版 Notification Hook..." -ForegroundColor Green
$testInput2 | & "$ModuleRoot\scripts\hooks\notification.ps1"

Write-Host ""
Write-Host "=== 验证结果 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ 高级版 Hook 测试完成" -ForegroundColor Green
Write-Host ""
Write-Host "预期效果：" -ForegroundColor Yellow
Write-Host "  ✅ 听到 2 次 Asterisk 音效（Stop + Notification）" -ForegroundColor White
Write-Host "  ✅ 看到 2 个 Windows Toast 通知" -ForegroundColor White
Write-Host "  ✅ 标题变为 [⚠️] 需要输入 或 [📢] 通知" -ForegroundColor White
Write-Host "  ✅ 标签页背景色变为红色或黄色" -ForegroundColor White
Write-Host "  ✅ 状态文件已创建（检查 .states/ 目录）" -ForegroundColor White
Write-Host ""
Write-Host "如需对比基础版，请运行：test-basic-hooks.ps1" -ForegroundColor DarkGray
Write-Host ""
