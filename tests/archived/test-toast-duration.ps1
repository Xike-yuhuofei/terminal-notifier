# test-toast-duration.ps1
# 测试 Toast 通知显示时间

Write-Host "=== Toast 通知显示时间测试 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "正在发送测试通知，请观察 Windows 通知中心..." -ForegroundColor Yellow
Write-Host "通知应该显示更长时间 (约 25-30 秒)" -ForegroundColor Yellow
Write-Host ""

# 导入 ToastNotifier 模块
Import-Module "C:/Users/Xike/.claude/tools/terminal-notifier/lib/ToastNotifier.psm1" -Force

# 发送测试通知 (使用默认长持续时间)
Send-WindowsToast -Title "测试通知 (长持续时间)" -Message "这条通知应该显示约 25-30 秒，请观察时间"

Write-Host ""
Write-Host "✓ 通知已发送!" -ForegroundColor Green
Write-Host "请查看 Windows 通知中心的 Toast 通知" -ForegroundColor Green
Write-Host ""
Write-Host "提示: Windows Toast 通知的持续时间由系统设置控制" -ForegroundColor Gray
Write-Host "最长显示时间约 25-30 秒" -ForegroundColor Gray

