# switch-to-basic.ps1
# 快速切换到基础版 Hook
# 基础版：仅音效 + Toast 通知

#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$settingsPath = "$env:USERPROFILE\.claude\settings.json"

Write-Host ""
Write-Host "=== 切换到基础版 Hook ===" -ForegroundColor Cyan
Write-Host ""

# 检查配置文件是否存在
if (-not (Test-Path $settingsPath)) {
    Write-Host "❌ 配置文件不存在：$settingsPath" -ForegroundColor Red
    exit 1
}

# 读取配置
try {
    $settings = Get-Content $settingsPath | ConvertFrom-Json
}
catch {
    Write-Host "❌ 无法读取配置文件：$_" -ForegroundColor Red
    exit 1
}

# 检查 hooks 配置是否存在
if (-not $settings.hooks) {
    Write-Host "❌ 配置文件中没有 hooks 配置" -ForegroundColor Red
    exit 1
}

# 修改 Stop Hook
if ($settings.hooks.Stop -and $settings.hooks.Stop[0].hooks) {
    $oldCommand = $settings.hooks.Stop[0].hooks[0].command
    $newCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"C:/Users/Xike/.claude/tools/terminal-notifier/scripts/hooks/stop-basic.ps1`""
    $settings.hooks.Stop[0].hooks[0].command = $newCommand

    if ($oldCommand -ne $newCommand) {
        Write-Host "✏️  Stop Hook：" -ForegroundColor Yellow
        Write-Host "   旧配置：$oldCommand" -ForegroundColor DarkGray
        Write-Host "   新配置：$newCommand" -ForegroundColor Green
    } else {
        Write-Host "✅ Stop Hook 已经是基础版" -ForegroundColor Green
    }
}

# 修改 Notification Hook
if ($settings.hooks.Notification -and $settings.hooks.Notification[0].hooks) {
    $oldCommand = $settings.hooks.Notification[0].hooks[0].command
    $newCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"C:/Users/Xike/.claude/tools/terminal-notifier/scripts/hooks/notification-basic.ps1`""
    $settings.hooks.Notification[0].hooks[0].command = $newCommand

    if ($oldCommand -ne $newCommand) {
        Write-Host "✏️  Notification Hook：" -ForegroundColor Yellow
        Write-Host "   旧配置：$oldCommand" -ForegroundColor DarkGray
        Write-Host "   新配置：$newCommand" -ForegroundColor Green
    } else {
        Write-Host "✅ Notification Hook 已经是基础版" -ForegroundColor Green
    }
}

# 添加注释
if ($settings.hooks.Stop -and $settings.hooks.Stop[0].hooks) {
    $settings.hooks.Stop[0].hooks[0]._comment = "基础版：仅音效 + Toast。切换到高级版请使用 switch-to-advanced.ps1"
}

if ($settings.hooks.Notification -and $settings.hooks.Notification[0].hooks) {
    $settings.hooks.Notification[0].hooks[0]._comment = "基础版：仅音效 + Toast。切换到高级版请使用 switch-to-advanced.ps1"
}

# 保存配置
try {
    $jsonOutput = $settings | ConvertTo-Json -Depth 32
    $jsonOutput | Set-Content $settingsPath -Encoding UTF8

    Write-Host ""
    Write-Host "✅ 已切换到基础版 Hook" -ForegroundColor Green
    Write-Host ""
    Write-Host "基础版功能：" -ForegroundColor Cyan
    Write-Host "  ✅ 音效通知（系统提示音）" -ForegroundColor White
    Write-Host "  ✅ Windows Toast 通知" -ForegroundColor White
    Write-Host "  ❌ 状态管理" -ForegroundColor White
    Write-Host "  ❌ 持久化标题" -ForegroundColor White
    Write-Host "  ❌ OSC 标签页颜色" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  请重启 Claude Code 以应用更改" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "验证方法：" -ForegroundColor Cyan
    Write-Host "  1. 重启 Claude Code" -ForegroundColor White
    Write-Host "  2. 运行 /hooks 命令查看配置" -ForegroundColor White
    Write-Host "  3. 运行 .\test-basic-hooks.ps1 测试功能" -ForegroundColor White
    Write-Host ""
}
catch {
    Write-Host "❌ 无法保存配置文件：$_" -ForegroundColor Red
    exit 1
}
