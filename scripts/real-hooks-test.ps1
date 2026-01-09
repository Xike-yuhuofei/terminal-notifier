# real-hooks-test.ps1
# 实际 Hooks 集成测试 - 通过模拟真实场景验证

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Claude Code 真实场景 Hooks 测试" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 设置环境变量
$env:CLAUDE_PLUGIN_ROOT = "D:\Projects\Backend_CPP\.claude\plugins\terminal-notifier"
$env:CLAUDE_PROJECT_DIR = "D:\Projects\Backend_CPP"
$env:CLAUDE_NOTIFY_DEBUG = "false"  # 关闭调试，只看效果

Write-Host "环境变量已设置：" -ForegroundColor Gray
Write-Host "  CLAUDE_PLUGIN_ROOT = $env:CLAUDE_PLUGIN_ROOT" -ForegroundColor DarkGray
Write-Host "  CLAUDE_PROJECT_DIR = $env:CLAUDE_PROJECT_DIR" -ForegroundColor DarkGray
Write-Host ""

$notifyScript = Join-Path $env:CLAUDE_PLUGIN_ROOT "scripts\notify.ps1"

Write-Host "开始模拟 Claude Code 工作流程..." -ForegroundColor Green
Write-Host ""

# ========== 场景 1: 用户提交问题 ==========
Write-Host "[场景 1] 用户提交问题给 Claude" -ForegroundColor Yellow
Write-Host "→ UserPromptSubmit Hook 触发" -ForegroundColor Gray
& $notifyScript -EventType "working" -Context "💭 Thinking..." 2>$null
Write-Host "   你应该看到：蓝色背景 + '💭 Thinking...'" -ForegroundColor Cyan
Write-Host ""
Start-Sleep -Seconds 2

# ========== 场景 2: Claude 读取文件 ==========
Write-Host "[场景 2] Claude 读取文件" -ForegroundColor Yellow
Write-Host "→ PreToolUse Hook 触发 (Read)" -ForegroundColor Gray
& $notifyScript -EventType "working" -Context "📖 Reading: README.md" 2>$null
Write-Host "   你应该看到：蓝色背景 + '📖 Reading: README.md'" -ForegroundColor Cyan
Write-Host ""
Start-Sleep -Seconds 2

# ========== 场景 3: Claude 执行命令 ==========
Write-Host "[场景 3] Claude 执行 Bash 命令" -ForegroundColor Yellow
Write-Host "→ PreToolUse Hook 触发 (Bash)" -ForegroundColor Gray
& $notifyScript -EventType "working" -Context "⚙️ Running: git status" 2>$null
Write-Host "   你应该看到：蓝色背景 + '⚙️ Running: git status'" -ForegroundColor Cyan
Write-Host ""
Start-Sleep -Seconds 2

# ========== 场景 4: 命令执行成功 ==========
Write-Host "[场景 4] 命令执行成功" -ForegroundColor Yellow
Write-Host "→ PostToolUse Hook 触发 (成功)" -ForegroundColor Gray
& $notifyScript -EventType "working" -Context "🔄 Processing result..." 2>$null
Write-Host "   你应该看到：蓝色背景 + '🔄 Processing result...'" -ForegroundColor Cyan
Write-Host ""
Start-Sleep -Seconds 2

# ========== 场景 5: Claude 准备停止 ==========
Write-Host "[场景 5] Claude 完成任务，准备停止" -ForegroundColor Yellow
Write-Host "→ Stop Hook 触发" -ForegroundColor Gray
& $notifyScript -EventType "needs_human" -Context "[?] Ready to Stop?" 2>$null
Write-Host "   你应该看到：红色背景 + '🔴🔴🔴 [?] Ready to Stop? 🔴🔴🔴' + 闪烁" -ForegroundColor Red
Write-Host ""
Write-Host "   ⚠️  这表示需要你确认是否完成！" -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Seconds 3

# ========== 场景 6: 用户确认停止 ==========
Write-Host "[场景 6] 用户确认，任务完成" -ForegroundColor Yellow
& $notifyScript -EventType "success" -Context "✅ Task completed" 2>$null
Write-Host "   你应该看到：绿色背景 + '✅ Task completed'" -ForegroundColor Green
Write-Host "   (2 秒后自动恢复为蓝色)" -ForegroundColor Gray
Write-Host ""
Start-Sleep -Seconds 3

# ========== 场景 7: 发生错误 ==========
Write-Host "[场景 7] 执行命令时发生错误" -ForegroundColor Yellow
Write-Host "→ PostToolUse Hook 检测到错误" -ForegroundColor Gray
& $notifyScript -EventType "error" -Context "[!] Build failed" 2>$null
Write-Host "   你应该看到：红色背景 + '🔴🔴🔴 ❌ [!] Build failed 🔴🔴🔴'" -ForegroundColor Red
Write-Host ""
Write-Host "   ⚠️  这表示需要你立即处理错误！" -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Seconds 3

# ========== 总结 ==========
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "测试完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "你看到了什么？" -ForegroundColor Yellow
Write-Host "  1. 蓝色状态 = Claude 自动工作中（无需关注）" -ForegroundColor Cyan
Write-Host "  2. 红色状态 = 需要你介入（必须响应）" -ForegroundColor Red
Write-Host "  3. 绿色状态 = 任务完成（正面反馈）" -ForegroundColor Green
Write-Host ""
Write-Host "这就是极简二元法的核心：" -ForegroundColor White
Write-Host "  🔴 红色 = 需要我" -ForegroundColor Red
Write-Host "  🔵 蓝色 = 自动" -ForegroundColor Cyan
Write-Host ""
