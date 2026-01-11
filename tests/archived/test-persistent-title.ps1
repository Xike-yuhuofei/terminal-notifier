# test-persistent-title.ps1
# 测试持久化标题UI组件

#Requires -Version 5.1

$ModuleRoot = Split-Path -Parent $PSScriptRoot
$LibPath = Join-Path $ModuleRoot "lib"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "持久化标题UI组件测试" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 导入模块
Import-Module (Join-Path $LibPath "PersistentTitle.psm1") -Force

Write-Host "测试场景 1: Stop事件（红色持久化标题，不自动清除）" -ForegroundColor Yellow
Write-Host "预期效果：标题显示 '[⚠️ 编译测试] 需要输入'，保持红色，直到手动清除" -ForegroundColor Gray
Write-Host "按任意键继续..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Show-TitleNotification -Title "[⚠️ 编译测试] 需要输入" -Type "Stop" -AutoClear $false
Write-Host "[✓] Stop事件已触发" -ForegroundColor Green
Write-Host "观察窗口标题：应该显示 '[⚠️ 编译测试] 需要输入'" -ForegroundColor Cyan
Write-Host "按任意键清除..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Clear-PersistentTitle
Write-Host "[✓] 标题已清除" -ForegroundColor Green
Write-Host ""

Write-Host "测试场景 2: Notification事件（黄色，5秒后自动清除）" -ForegroundColor Yellow
Write-Host "预期效果：标题显示 '[📢 单元测试] 通知'，保持黄色，5秒后自动清除" -ForegroundColor Gray
Write-Host "按任意键继续..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Show-TitleNotification -Title "[📢 单元测试] 通知" -Type "Notification" -Duration 5
Write-Host "[✓] Notification事件已触发" -ForegroundColor Green
Write-Host "观察窗口标题：应该显示 '[📢 单元测试] 通知'" -ForegroundColor Cyan
Write-Host "请观察5秒，标题会自动清除..."
Start-Sleep -Seconds 6
Write-Host "[✓] 标题应该已自动清除" -ForegroundColor Green
Write-Host ""

Write-Host "测试场景 3: Success事件（绿色，10秒后自动清除）" -ForegroundColor Yellow
Write-Host "预期效果：标题显示 '[✅ 性能优化] 完成'，保持绿色，10秒后自动清除" -ForegroundColor Gray
Write-Host "按任意键继续..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Show-TitleNotification -Title "[✅ 性能优化] 完成" -Type "Success" -Duration 10
Write-Host "[✓] Success事件已触发" -ForegroundColor Green
Write-Host "观察窗口标题：应该显示 '[✅ 性能优化] 完成'" -ForegroundColor Cyan
Write-Host "请观察10秒，标题会自动清除..."
Start-Sleep -Seconds 11
Write-Host "[✓] 标题应该已自动清除" -ForegroundColor Green
Write-Host ""

Write-Host "测试场景 4: 自定义标题和持续时间" -ForegroundColor Yellow
Write-Host "预期效果：显示自定义标题，持续3秒" -ForegroundColor Gray
Write-Host "按任意键继续..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Set-PersistentTitle -Title "[自定义] 我的任务" -State "blue" -Duration 3
Write-Host "[✓] 自定义标题已设置" -ForegroundColor Green
Write-Host "观察窗口标题：应该显示 '[自定义] 我的任务'" -ForegroundColor Cyan
Write-Host "请观察3秒，标题会自动清除..."
Start-Sleep -Seconds 4
Write-Host "[✓] 标题应该已自动清除" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "所有测试完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "注意事项：" -ForegroundColor Yellow
Write-Host "1. 持久化标题每0.5秒刷新一次，防止被覆盖" -ForegroundColor Gray
Write-Host "2. Stop事件默认不自动清除，需要手动调用 Clear-PersistentTitle" -ForegroundColor Gray
Write-Host "3. Notification事件默认5秒后自动清除" -ForegroundColor Gray
Write-Host "4. Success事件默认10秒后自动清除" -ForegroundColor Gray
Write-Host ""
Write-Host "在Claude Code Hook中使用：" -ForegroundColor Yellow
Write-Host "  Stop Hook: Show-TitleNotification -Title '[⚠️ 任务名] 需要输入' -Type 'Stop'" -ForegroundColor Gray
Write-Host "  Notification Hook: Show-TitleNotification -Title '[📢 任务名] 通知' -Type 'Notification'" -ForegroundColor Gray
Write-Host ""
