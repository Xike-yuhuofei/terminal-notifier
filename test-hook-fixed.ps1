# test-hook-fixed.ps1
# 测试修复后的 Hook 标题功能

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "修复后的 Hook 标题功能测试" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# 导入 TabTitleManager 模块
$ScriptDir = Split-Path -Parent $PSCommandPath
$ModuleRoot = Resolve-Path (Join-Path $ScriptDir ".")
$LibPath = Join-Path $ModuleRoot "lib"

Write-Host "导入 TabTitleManager 模块..." -ForegroundColor Yellow
Import-Module (Join-Path $LibPath "TabTitleManager.psm1") -Force

# 测试 1: 直接运行（应该使用 RawUI）
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试 1: 直接运行 Set-TabTitle" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n当前标题:" -ForegroundColor Gray
Write-Host "   $($Host.UI.RawUI.WindowTitle)" -ForegroundColor DarkGray

Write-Host "`n设置标题..." -ForegroundColor Yellow
Set-TabTitle -Title "[⚠️] 测试直接运行 - terminal-notifier"

Write-Host "`n设置后标题:" -ForegroundColor Gray
Write-Host "   $($Host.UI.RawUI.WindowTitle)" -ForegroundColor DarkGray

Write-Host "`n✅ 测试完成（如果标题已更改，说明 RawUI 工作正常）" -ForegroundColor Green
Start-Sleep -Seconds 2

# 测试 2: 强制使用 OSC（模拟 Hook 环境）
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试 2: 强制使用 OSC 序列（-ForceOSC）" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n当前标题:" -ForegroundColor Gray
Write-Host "   $($Host.UI.RawUI.WindowTitle)" -ForegroundColor DarkGray

Write-Host "`n设置标题（使用 OSC）..." -ForegroundColor Yellow
Set-TabTitle -Title "[📢] 测试 OSC 序列 - terminal-notifier" -ForceOSC

Write-Host "`n注意: OSC 序列已发送到 stdout" -ForegroundColor Yellow
Write-Host "   如果 Windows Terminal 支持，标题应该已经更改" -ForegroundColor Gray

Write-Host "`n当前 PowerShell 标题（可能未更改）:" -ForegroundColor Gray
Write-Host "   $($Host.UI.RawUI.WindowTitle)" -ForegroundColor DarkGray

Write-Host "`n✅ 测试完成（检查 Windows Terminal 标题是否更改）" -ForegroundColor Green
Start-Sleep -Seconds 2

# 测试 3: 模拟 Hook 环境
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试 3: 模拟 Hook 环境调用" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

$hookScript = "C:/Users/Xike/.claude/tools/terminal-notifier/scripts/hooks/stop-basic.ps1"
$hookInput = @{
    session_id = [Guid]::NewGuid().ToString()
    cwd = "C:\Users\Xike\terminal-notifier"
    stop_hook_active = $false
} | ConvertTo-Json -Compress

Write-Host "`nHook 输入:" -ForegroundColor Gray
Write-Host "   $hookInput" -ForegroundColor DarkGray

Write-Host "`n调用 Hook 脚本..." -ForegroundColor Yellow
$output = $hookInput | powershell.exe -NoProfile -ExecutionPolicy Bypass -File $hookScript 2>&1
$exitCode = $LASTEXITCODE

Write-Host "`n退出代码: $exitCode" -ForegroundColor Cyan

if ($output) {
    Write-Host "`nHook 输出:" -ForegroundColor Cyan
    $output | ForEach-Object {
        # 只显示非空的输出行
        if ($_ -match '\S') {
            Write-Host "   $_" -ForegroundColor Gray
        }
    }
}

Write-Host "`n当前 PowerShell 标题:" -ForegroundColor Gray
Write-Host "   $($Host.UI.RawUI.WindowTitle)" -ForegroundColor DarkGray

Write-Host "`n💡 说明:" -ForegroundColor Yellow
Write-Host "   - Hook 脚本检测到 Hook 环境，使用 OSC 序列" -ForegroundColor Gray
Write-Host "   - OSC 序列已发送到 stdout" -ForegroundColor Gray
Write-Host "   - 如果 Windows Terminal 标题已更改，说明功能正常" -ForegroundColor Gray
Write-Host "   - 如果标题未更改，可能需要其他方法" -ForegroundColor Gray

Write-Host "`n✅ 测试完成" -ForegroundColor Green
Start-Sleep -Seconds 2

# 总结
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试总结" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n📋 测试结果:" -ForegroundColor Yellow
Write-Host "   1. 直接运行 - RawUI 方法" -ForegroundColor Gray
Write-Host "   2. 强制 OSC - OSC 序列方法" -ForegroundColor Gray
Write-Host "   3. Hook 调用 - 自动检测并使用 OSC" -ForegroundColor Gray

Write-Host "`n💡 下一步:" -ForegroundColor Yellow
Write-Host "   - 如果 Windows Terminal 标题在测试 3 中更改：功能正常 ✅" -ForegroundColor Gray
Write-Host "   - 如果标题未更改：需要使用其他方法（如持久化标题）❌" -ForegroundColor Gray

Write-Host "`n按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
