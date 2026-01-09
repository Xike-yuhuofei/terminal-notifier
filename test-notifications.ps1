# test-notifications.ps1
# 测试终端通知系统的视觉效果
# 用法：在 Windows Terminal 中直接运行此脚本
#   powershell.exe -ExecutionPolicy Bypass -File test-notifications.ps1

$ScriptDir = Split-Path -Parent $PSCommandPath
$LibPath = Join-Path $ScriptDir "lib"

# 导入模块
Import-Module (Join-Path $LibPath "OscSender.psm1") -Force

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 终端通知系统测试" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1] 测试窗口标题 (OSC 2 序列)" -ForegroundColor Yellow
Send-OscTitle "【测试】Claude Code 通知系统"
Write-Host "    ✓ 窗口标题已设置为: '【测试】Claude Code 通知系统'" -ForegroundColor Green
Write-Host "    请查看 Windows Terminal 标题栏" -ForegroundColor Gray
Start-Sleep -Seconds 3
Write-Host ""

Write-Host "[2] 测试进度指示器 (OSC 9;4 序列)" -ForegroundColor Yellow
Write-Host ""

Write-Host "    [2.1] 正常状态 (蓝色/默认)" -ForegroundColor White
Send-OscTabColor -Color "blue" | Out-Null
Write-Host "          ✓ 已发送正常状态" -ForegroundColor Green
Write-Host "          请查看 Tab 图标 - 应该显示进度条" -ForegroundColor Gray
Start-Sleep -Seconds 3

Write-Host "    [2.2] 警告状态 (黄色)" -ForegroundColor Yellow
Send-OscTabColor -Color "yellow" | Out-Null
Write-Host "          ✓ 已发送警告状态" -ForegroundColor Green
Write-Host "          请查看 Tab 图标和任务栏 - 应该变成黄色" -ForegroundColor Gray
Start-Sleep -Seconds 3

Write-Host "    [2.3] 错误状态 (红色)" -ForegroundColor Red
Send-OscTabColor -Color "red" | Out-Null
Write-Host "          ✓ 已发送错误状态" -ForegroundColor Green
Write-Host "          请查看 Tab 图标和任务栏 - 应该变成红色" -ForegroundColor Gray
Start-Sleep -Seconds 3

Write-Host "    [2.4] 恢复默认 (隐藏进度条)" -ForegroundColor White
Send-OscTabColor -Color "default" | Out-Null
Write-Host "          ✓ 已隐藏进度条" -ForegroundColor Green
Write-Host "          Tab 图标应该恢复正常" -ForegroundColor Gray
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "[3] 测试响铃" -ForegroundColor Yellow
Write-Host "    尝试发出 3 次响铃..." -ForegroundColor Gray
[Console]::Write("`a")
Start-Sleep -Milliseconds 200
[Console]::Write("`a")
Start-Sleep -Milliseconds 200
[Console]::Write("`a")
Write-Host "    ✓ 响铃命令已发送" -ForegroundColor Green
Write-Host "    如果听不到声音，请检查 Windows Terminal 设置：" -ForegroundColor Gray
Write-Host "      1. 打开 Windows Terminal 设置" -ForegroundColor Gray
Write-Host "      2. 选择当前配置文件 (PowerShell)" -ForegroundColor Gray
Write-Host "      3. 高级 → 启用响铃 (Bell notification style)" -ForegroundColor Gray
Write-Host "      4. 选择 'Audible' 或 'All'" -ForegroundColor Gray
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "[4] 完整场景演示" -ForegroundColor Yellow
Write-Host ""

Write-Host "    模拟 Claude 启动..." -ForegroundColor Cyan
Send-OscTitle "[+] Claude 启动中 - Backend_CPP"
Send-OscTabColor -Color "blue" | Out-Null
Start-Sleep -Seconds 2

Write-Host "    模拟 Claude 工作..." -ForegroundColor Cyan
Send-OscTitle "[...] Claude 工作中 - Backend_CPP"
Start-Sleep -Seconds 2

Write-Host "    模拟 Claude 停止 (需要输入)..." -ForegroundColor Red
Send-OscTitle "[?] 需要输入 - Backend_CPP"
Send-OscTabColor -Color "red" | Out-Null
[Console]::Write("`a")
Start-Sleep -Milliseconds 200
[Console]::Write("`a")
Start-Sleep -Seconds 3

Write-Host "    模拟会话结束..." -ForegroundColor Cyan
Send-OscTitle "[✓] 会话结束 - Backend_CPP"
Send-OscTabColor -Color "default" | Out-Null
Start-Sleep -Seconds 2

# 恢复默认
Send-OscTitle "PowerShell"
Send-OscTabColor -Color "default" | Out-Null

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 测试完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "如果你看到了以下效果，说明修复成功：" -ForegroundColor Green
Write-Host "  ✓ 窗口标题在不同阶段显示不同内容" -ForegroundColor Green
Write-Host "  ✓ Tab 图标显示了进度条和颜色变化" -ForegroundColor Green
Write-Host "  ✓ 任务栏图标显示了红色/黄色状态" -ForegroundColor Green
Write-Host "  ✓ (可选) 听到了响铃声" -ForegroundColor Green
Write-Host ""
