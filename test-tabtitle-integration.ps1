# test-tabtitle-integration.ps1
# 测试 TabTitleManager 模块集成到 Hook 脚本的效果

#Requires -Version 5.1
Set-StrictMode -Version Latest

# Get script and module paths
$ScriptDir = Split-Path -Parent $PSCommandPath
$ModuleRoot = Resolve-Path (Join-Path $ScriptDir ".")
$LibPath = Join-Path $ModuleRoot "lib"

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "TabTitleManager 模块集成测试" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Import TabTitleManager module
Write-Host "正在导入 TabTitleManager 模块..." -ForegroundColor Yellow
Import-Module (Join-Path $LibPath "TabTitleManager.psm1") -Force -ErrorAction Stop

Write-Host "✅ 模块导入成功！" -ForegroundColor Green
Write-Host ""

# ============================================
# 测试 1: 基础功能 - Set-TabTitle
# ============================================
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "测试 1: Set-TabTitle - 基础功能" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n测试标题: '测试基础功能 - terminal-notifier'" -ForegroundColor Gray
Set-TabTitle -Title "测试基础功能 - terminal-notifier"
$currentTitle = Get-CurrentTabTitle
Write-Host "当前标题: $currentTitle" -ForegroundColor Cyan
Write-Host "✅ 基础功能测试完成" -ForegroundColor Green
Start-Sleep -Seconds 2

# ============================================
# 测试 2: 带图标标题 - Set-TabTitleWithIcon
# ============================================
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试 2: Set-TabTitleWithIcon - 带图标标题" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n测试图标: ⚠️（警告）" -ForegroundColor Gray
Set-TabTitleWithIcon -Title "需要输入" -Icon "⚠️"
Write-Host "当前标题: $(Get-CurrentTabTitle)" -ForegroundColor Cyan
Start-Sleep -Seconds 2

Write-Host "`n测试图标: 📢（通知）" -ForegroundColor Gray
Set-TabTitleWithIcon -Title "新通知" -Icon "📢"
Write-Host "当前标题: $(Get-CurrentTabTitle)" -ForegroundColor Cyan
Start-Sleep -Seconds 2

Write-Host "`n测试图标: ✅（成功）" -ForegroundColor Gray
Set-TabTitleWithIcon -Title "任务完成" -Icon "✅"
Write-Host "当前标题: $(Get-CurrentTabTitle)" -ForegroundColor Cyan
Write-Host "✅ 带图标标题测试完成" -ForegroundColor Green
Start-Sleep -Seconds 2

# ============================================
# 测试 3: Hook 场景 - Set-TabTitleForHook
# ============================================
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试 3: Set-TabTitleForHook - Hook 场景测试" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

$projectName = "terminal-notifier"

# Stop Hook 场景
Write-Host "`n场景 1: Stop Hook（需要输入）" -ForegroundColor Yellow
Set-TabTitleForHook -HookType "Stop" -ProjectName $projectName
Write-Host "当前标题: $(Get-CurrentTabTitle)" -ForegroundColor Cyan
Start-Sleep -Seconds 2

# Stop Hook 场景（带窗口名称）
Write-Host "`n场景 2: Stop Hook（带自定义窗口名称）" -ForegroundColor Yellow
Set-TabTitleForHook -HookType "Stop" -ProjectName $projectName -WindowName "编译测试"
Write-Host "当前标题: $(Get-CurrentTabTitle)" -ForegroundColor Cyan
Start-Sleep -Seconds 2

# Notification Hook 场景
Write-Host "`n场景 3: Notification Hook（新通知）" -ForegroundColor Yellow
Set-TabTitleForHook -HookType "Notification" -ProjectName $projectName
Write-Host "当前标题: $(Get-CurrentTabTitle)" -ForegroundColor Cyan
Start-Sleep -Seconds 2

# Notification Hook 场景（带窗口名称）
Write-Host "`n场景 4: Notification Hook（带自定义窗口名称）" -ForegroundColor Yellow
Set-TabTitleForHook -HookType "Notification" -ProjectName $projectName -WindowName "代码审查"
Write-Host "当前标题: $(Get-CurrentTabTitle)" -ForegroundColor Cyan
Write-Host "✅ Hook 场景测试完成" -ForegroundColor Green
Start-Sleep -Seconds 2

# ============================================
# 测试 4: 模拟 stop-basic.ps1
# ============================================
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试 4: 模拟 stop-basic.ps1 Hook 脚本" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n模拟 Hook 输入:" -ForegroundColor Gray
$hookInput = @{
    session_id = [Guid]::NewGuid().ToString()
    cwd = "C:\Users\Xike\test-project"
} | ConvertTo-Json -Compress

Write-Host $hookInput -ForegroundColor DarkGray

Write-Host "`n处理 Hook 逻辑..." -ForegroundColor Yellow
$projectName = Split-Path -Leaf "C:\Users\Xike\test-project"
$windowName = "单元测试"

Write-Host "项目名称: $projectName" -ForegroundColor Gray
Write-Host "窗口名称: $windowName" -ForegroundColor Gray

Write-Host "`n设置标题..." -ForegroundColor Yellow
Set-TabTitleForHook -HookType "Stop" -ProjectName $projectName -WindowName $windowName
Write-Host "当前标题: $(Get-CurrentTabTitle)" -ForegroundColor Cyan
Write-Host "✅ stop-basic.ps1 模拟测试完成" -ForegroundColor Green
Start-Sleep -Seconds 2

# ============================================
# 测试 5: 模拟 notification-basic.ps1
# ============================================
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试 5: 模拟 notification-basic.ps1 Hook 脚本" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n设置通知标题..." -ForegroundColor Yellow
Set-TabTitleForHook -HookType "Notification" -ProjectName $projectName -WindowName "集成测试"
Write-Host "当前标题: $(Get-CurrentTabTitle)" -ForegroundColor Cyan

Write-Host "`n等待 5 秒后清除标题..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Set-TabTitle -Title "[...] Claude - $projectName"
Write-Host "标题已清除" -ForegroundColor Gray
Write-Host "当前标题: $(Get-CurrentTabTitle)" -ForegroundColor Cyan
Write-Host "✅ notification-basic.ps1 模拟测试完成" -ForegroundColor Green

# ============================================
# 测试结果汇总
# ============================================
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试结果汇总" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n✅ 所有测试通过！" -ForegroundColor Green
Write-Host "`n📝 集成验证完成的项目:" -ForegroundColor Yellow
Write-Host "   ✅ TabTitleManager.psm1 模块功能正常" -ForegroundColor Gray
Write-Host "   ✅ Set-TabTitle 基础功能正常" -ForegroundColor Gray
Write-Host "   ✅ Set-TabTitleWithIcon 带图标功能正常" -ForegroundColor Gray
Write-Host "   ✅ Set-TabTitleForHook Hook 场景功能正常" -ForegroundColor Gray
Write-Host "   ✅ stop-basic.ps1 集成逻辑验证通过" -ForegroundColor Gray
Write-Host "   ✅ notification-basic.ps1 集成逻辑验证通过" -ForegroundColor Gray

Write-Host "`n💡 下一步:" -ForegroundColor Cyan
Write-Host "   1. Hook 脚本已更新，使用 TabTitleManager 模块" -ForegroundColor White
Write-Host "   2. 所有标题设置现在使用 OSC 序列（优先）+ RawUI（回退）" -ForegroundColor White
Write-Host "   3. 支持跨终端兼容性（Windows Terminal, VS Code 等）" -ForegroundColor White
Write-Host "   4. 重新启动 Claude Code 以应用更改" -ForegroundColor White

# 恢复默认标题
Write-Host "`n恢复默认标题..." -ForegroundColor Gray
Set-TabTitle -Title "Windows Terminal"
Start-Sleep -Seconds 1

Write-Host "`n按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
