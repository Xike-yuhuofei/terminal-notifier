# persistent-title-quickstart.ps1
# 快速上手：持久化标题UI组件

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   持久化标题UI组件 - 快速上手示例                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$ModuleRoot = Split-Path -Parent $PSScriptRoot
$LibPath = Join-Path $ModuleRoot "lib"

# 导入模块
Import-Module (Join-Path $LibPath "PersistentTitle.psm1") -Force

Write-Host "【示例1】模拟Stop Hook触发 - 红色持久化标题" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "在真实场景中，当Claude Code需要你的输入时会显示："
Write-Host ""
Write-Host "  窗口标题: [⚠️ 编译测试] 需要输入" -ForegroundColor Red
Write-Host "  标签页颜色: 红色" -ForegroundColor Red
Write-Host "  持续时间: 永久（直到你继续对话）" -ForegroundColor Red
Write-Host ""

Write-Host "按任意键演示..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Show-TitleNotification -Title "[⚠️ 编译测试] 需要输入" -Type "Stop" -AutoClear $false

Write-Host ""
Write-Host "[✓] 已显示！观察你的窗口标题..." -ForegroundColor Green
Write-Host "[提示] 这个标题会一直显示，直到你手动清除" -ForegroundColor Yellow
Write-Host ""
Write-Host "按任意键清除..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Clear-PersistentTitle

Write-Host ""
Write-Host "[✓] 标题已清除！" -ForegroundColor Green
Write-Host ""

Write-Host "【示例2】模拟Notification Hook触发 - 黄色临时标题" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "在真实场景中，当Claude Code发送通知时会显示："
Write-Host ""
Write-Host "  窗口标题: [📢 单元测试] 通知" -ForegroundColor Yellow
Write-Host "  标签页颜色: 黄色" -ForegroundColor Yellow
Write-Host "  持续时间: 5秒后自动清除" -ForegroundColor Yellow
Write-Host ""

Write-Host "按任意键演示..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Show-TitleNotification -Title "[📢 单元测试] 通知" -Type "Notification" -Duration 5

Write-Host ""
Write-Host "[✓] 已显示！观察你的窗口标题..." -ForegroundColor Green
Write-Host "[提示] 5秒后会自动清除，请耐心等待..." -ForegroundColor Yellow
Write-Host ""

Start-Sleep -Seconds 6

Write-Host ""
Write-Host "[✓] 标题应该已自动清除！" -ForegroundColor Green
Write-Host ""

Write-Host "【示例3】模拟任务完成 - 绿色成功标题" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "在真实场景中，当任务完成时会显示："
Write-Host ""
Write-Host "  窗口标题: [✅ 性能优化] 完成" -ForegroundColor Green
Write-Host "  标签页颜色: 绿色" -ForegroundColor Green
Write-Host "  持续时间: 10秒后自动清除" -ForegroundColor Green
Write-Host ""

Write-Host "按任意键演示..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Show-TitleNotification -Title "[✅ 性能优化] 完成" -Type "Success" -Duration 10

Write-Host ""
Write-Host "[✓] 已显示！观察你的窗口标题..." -ForegroundColor Green
Write-Host "[提示] 10秒后会自动清除，请耐心等待..." -ForegroundColor Yellow
Write-Host ""

Start-Sleep -Seconds 11

Write-Host ""
Write-Host "[✓] 标题应该已自动清除！" -ForegroundColor Green
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   演示完成！                                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "📖 实际使用：" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 配置不同的窗口任务名称：" -ForegroundColor Yellow
Write-Host "   export CLAUDE_WINDOW_NAME='编译测试'  # Git Bash" -ForegroundColor Gray
Write-Host "   claude" -ForegroundColor Gray
Write-Host ""
Write-Host "2. 当Claude Code触发Hook时：" -ForegroundColor Yellow
Write-Host "   - Stop Hook → 标题显示 [⚠️ 编译测试] 需要输入" -ForegroundColor Gray
Write-Host "   - Notification Hook → 标题显示 [📢 编译测试] 通知" -ForegroundColor Gray
Write-Host ""
Write-Host "3. 多个任务窗口同时工作时：" -ForegroundColor Yellow
Write-Host "   窗口1: [⚠️ 编译测试] 需要输入      ← 红色" -ForegroundColor Gray
Write-Host "   窗口2: [📢 单元测试] 通知          ← 黄色（5秒后消失）" -ForegroundColor Gray
Write-Host "   窗口3: [⚠️ 代码审查] 需要输入      ← 红色" -ForegroundColor Gray
Write-Host ""
Write-Host "✨ 优势：" -ForegroundColor Green
Write-Host "   ✓ 持久化显示（不会被覆盖）" -ForegroundColor Gray
Write-Host "   ✓ 颜色编码（红/黄/绿）" -ForegroundColor Gray
Write-Host "   ✓ 零依赖（纯PowerShell）" -ForegroundColor Gray
Write-Host "   ✓ 性能开销极小（< 0.1% CPU）" -ForegroundColor Gray
Write-Host ""
Write-Host "📚 详细文档: docs/PERSISTENT_TITLE_UI.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "🧪 完整测试: .\test-persistent-title.ps1" -ForegroundColor Cyan
Write-Host ""
