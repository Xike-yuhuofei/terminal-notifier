# test-hooks-integration.ps1
# Claude Code Hooks 集成测试脚本
#
# 这个脚本模拟 Claude Code 的 Hook 触发，验证集成是否正常

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Claude Code Hooks 集成测试" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 设置环境
$env:CLAUDE_PLUGIN_ROOT = Split-Path -Parent $PSScriptRoot
$env:CLAUDE_PROJECT_DIR = "D:\Projects\Backend_CPP"
$env:CLAUDE_NOTIFY_DEBUG = "true"

$pluginRoot = $env:CLAUDE_PLUGIN_ROOT
$notifyScript = Join-Path $pluginRoot "scripts\notify.ps1"

Write-Host "插件根目录: $pluginRoot" -ForegroundColor Gray
Write-Host "通知脚本: $notifyScript" -ForegroundColor Gray
Write-Host ""

# 测试计数器
$testCount = 0
$passCount = 0
$failCount = 0

function Test-Hook {
    param(
        [string]$HookName,
        [string]$EventType,
        [string]$Context,
        [string]$ExpectedPattern
    )

    $script:testCount++

    Write-Host "[$testCount] 测试: $HookName" -ForegroundColor Yellow
    Write-Host "   事件: $EventType" -ForegroundColor Gray
    Write-Host "   上下文: $Context" -ForegroundColor Gray

    try {
        # 执行通知脚本
        $output = & $notifyScript -EventType $EventType -Context $Context 2>&1

        # 检查输出中是否包含预期的模式
        if ($output -match $ExpectedPattern) {
            Write-Host "   ✓ 通过" -ForegroundColor Green
            $script:passCount++
        }
        else {
            Write-Host "   ✗ 失败: 输出不匹配预期模式" -ForegroundColor Red
            Write-Host "   预期包含: $ExpectedPattern" -ForegroundColor DarkRed
            $script:failCount++
        }

        # 显示实际输出的 OSC 序列
        $oscOutput = $output | Where-Object { $_ -match "\033\]" }
        if ($oscOutput) {
            Write-Host "   OSC 序列: $oscOutput" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Host "   ✗ 失败: $_" -ForegroundColor Red
        $script:failCount++
    }

    Write-Host ""

    # 等待观察效果
    Start-Sleep -Seconds 1
}

# 开始测试
Write-Host "开始测试 Hooks 集成..." -ForegroundColor Green
Write-Host ""

# ========== 测试 SessionStart ==========
Test-Hook -HookName "SessionStart" `
          -EventType "session_start" `
          -Context "Ready" `
          -ExpectedPattern "session_start|Ready"

# ========== 测试 UserPromptSubmit ==========
Test-Hook -HookName "UserPromptSubmit" `
          -EventType "working" `
          -Context "💭 Thinking..." `
          -ExpectedPattern "working|Thinking"

# ========== 测试 PreToolUse (Read) ==========
Test-Hook -HookName "PreToolUse (Read)" `
          -EventType "working" `
          -Context "📖 Reading file..." `
          -ExpectedPattern "working|Reading"

# ========== 测试 PreToolUse (Bash) ==========
Test-Hook -HookName "PreToolUse (Bash)" `
          -EventType "working" `
          -Context "⚙️ Running: Bash" `
          -ExpectedPattern "working|Running"

# ========== 测试 PreToolUse (Edit) ==========
Test-Hook -HookName "PreToolUse (Edit)" `
          -EventType "working" `
          -Context "✏️ Editing file..." `
          -ExpectedPattern "working|Editing"

# ========== 测试 PostToolUse (成功) ==========
Test-Hook -HookName "PostToolUse (成功)" `
          -EventType "working" `
          -Context "🔄 Processing..." `
          -ExpectedPattern "working|Processing"

# ========== 测试 Stop Hook ==========
Test-Hook -HookName "Stop Hook" `
          -EventType "needs_human" `
          -Context "[?] Ready to Stop?" `
          -ExpectedPattern "needs_human|Ready to Stop"

# ========== 测试 SubagentStop ==========
Test-Hook -HookName "SubagentStop" `
          -EventType "working" `
          -Context "🤖 Subagent completed" `
          -ExpectedPattern "working|Subagent"

# ========== 测试 Notification ==========
Test-Hook -HookName "Notification Hook" `
          -EventType "needs_human" `
          -Context "[🔔] Notification received" `
          -ExpectedPattern "needs_human|Notification"

# ========== 测试 SessionEnd ==========
Test-Hook -HookName "SessionEnd" `
          -EventType "session_end" `
          -Context "Bye" `
          -ExpectedPattern "session_end|Bye"

# ========== 测试结果总结 ==========
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "测试结果总结" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "总测试数: $testCount" -ForegroundColor White
Write-Host "通过: $passCount" -ForegroundColor Green
Write-Host "失败: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "✅ 所有测试通过！Hooks 集成正常工作。" -ForegroundColor Green
}
else {
    Write-Host "❌ 有 $failCount 个测试失败，请检查配置。" -ForegroundColor Red
}

Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
