# test-hook-debug.ps1
# 调试 Hook 脚本执行问题

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Hook 脚本调试测试" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# 检查脚本路径
$hookScript = "C:/Users/Xike/.claude/tools/terminal-notifier/scripts/hooks/stop-basic.ps1"
Write-Host "📝 Hook 脚本路径:" -ForegroundColor Yellow
Write-Host "   $hookScript" -ForegroundColor Gray

if (Test-Path $hookScript) {
    Write-Host "   ✅ 文件存在" -ForegroundColor Green
} else {
    Write-Host "   ❌ 文件不存在！" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 创建模拟 Hook 输入
$hookInput = @{
    session_id = [Guid]::NewGuid().ToString()
    cwd = "C:\Users\Xike\terminal-notifier"
    stop_hook_active = $false
} | ConvertTo-Json -Compress

Write-Host "📥 模拟 Hook 输入:" -ForegroundColor Yellow
Write-Host "   $hookInput" -ForegroundColor Gray
Write-Host ""

# 方法 1: 直接调用脚本（通过管道传递输入）
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "测试 1: 直接调用 Hook 脚本（模拟真实 Hook 调用）" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n🔧 调用方法:" -ForegroundColor Yellow
Write-Host "   echo '$hookInput' | powershell.exe -NoProfile -ExecutionPolicy Bypass -File '$hookScript'" -ForegroundColor Gray
Write-Host ""

Write-Host "⏱️  开始执行..." -ForegroundColor Yellow
$startTime = Get-Date

try {
    # 执行 Hook 脚本
    $output = $hookInput | powershell.exe -NoProfile -ExecutionPolicy Bypass -File $hookScript 2>&1
    $exitCode = $LASTEXITCODE

    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds

    Write-Host "`n⏱️  执行时间: $duration ms" -ForegroundColor Cyan
    Write-Host "📤 退出代码: $exitCode" -ForegroundColor Cyan

    if ($output) {
        Write-Host "`n📤 Hook 输出:" -ForegroundColor Cyan
        $output | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    } else {
        Write-Host "`n⚠️  无输出" -ForegroundColor Yellow
    }

    # 检查当前标题
    Write-Host "`n📌 当前终端标题:" -ForegroundColor Cyan
    Write-Host "   $($Host.UI.RawUI.WindowTitle)" -ForegroundColor Gray

    if ($exitCode -eq 0) {
        Write-Host "`n✅ Hook 执行成功！" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  Hook 执行完成，但退出代码非零: $exitCode" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "`n❌ Hook 执行失败！" -ForegroundColor Red
    Write-Host "   错误: $_" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 3

# 方法 2: 测试 TabTitleManager 模块
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "测试 2: 直接测试 TabTitleManager 模块" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n🔧 导入模块..." -ForegroundColor Yellow

$ScriptDir = Split-Path -Parent $PSCommandPath
$ModuleRoot = Resolve-Path (Join-Path $ScriptDir ".")
$LibPath = Join-Path $ModuleRoot "lib"

Write-Host "   模块路径: $LibPath\TabTitleManager.psm1" -ForegroundColor Gray

try {
    Import-Module (Join-Path $LibPath "TabTitleManager.psm1") -Force -ErrorAction Stop
    Write-Host "   ✅ 模块导入成功" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ 模块导入失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n🔧 测试 Set-TabTitleForHook..." -ForegroundColor Yellow

try {
    Set-TabTitleForHook -HookType "Stop" -ProjectName "terminal-notifier" -WindowName "调试测试"
    Write-Host "   ✅ 标题设置成功" -ForegroundColor Green

    Write-Host "`n📌 当前终端标题:" -ForegroundColor Cyan
    Write-Host "   $($Host.UI.RawUI.WindowTitle)" -ForegroundColor Gray
}
catch {
    Write-Host "   ❌ 标题设置失败: $_" -ForegroundColor Red
    Write-Host "   详细错误: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
}

Write-Host ""
Start-Sleep -Seconds 2

# 方法 3: 测试 OSC 序列
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "测试 3: 直接测试 OSC 序列" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n🔧 发送 OSC 序列..." -ForegroundColor Yellow

try {
    $ESC = [char]27
    $BEL = [char]7
    $title = "[⚠️ 调试测试] OSC 序列 - terminal-notifier"
    $oscSequence = "$ESC]0;$title$BEL"

    Write-Host "   序列: $oscSequence" -ForegroundColor Gray
    Write-Host "   标题: $title" -ForegroundColor Gray

    [Console]::Write($oscSequence)

    Write-Host "`n   ✅ OSC 序列发送成功" -ForegroundColor Green

    Write-Host "`n📌 当前终端标题:" -ForegroundColor Cyan
    Write-Host "   $($Host.UI.RawUI.WindowTitle)" -ForegroundColor Gray
}
catch {
    Write-Host "   ❌ OSC 序列发送失败: $_" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 2

# 诊断信息
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "诊断信息" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n🖥️  环境信息:" -ForegroundColor Yellow
Write-Host "   PowerShell 版本: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host "   操作系统: $([System.Environment]::OSVersion.VersionString)" -ForegroundColor Gray
Write-Host "   终端: $($Host.Name)" -ForegroundColor Gray

Write-Host "`n📋 可能的问题:" -ForegroundColor Yellow
Write-Host "   1. Hook 脚本中的错误被静默忽略（catch { exit 0 }）" -ForegroundColor Gray
Write-Host "   2. OSC 序列在当前终端中不生效" -ForegroundColor Gray
Write-Host "   3. 标题被后续命令快速覆盖" -ForegroundColor Gray
Write-Host "   4. Hook 没有被正确触发" -ForegroundColor Gray

Write-Host "`n💡 建议:" -ForegroundColor Yellow
Write-Host "   1. 检查 Claude Code 日志（使用 --debug 参数）" -ForegroundColor Gray
Write-Host "   2. 在 Hook 脚本中添加日志输出" -ForegroundColor Gray
Write-Host "   3. 验证 Hook 配置是否生效" -ForegroundColor Gray

Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试完成" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
