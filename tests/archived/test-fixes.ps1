<#
测试修复脚本 - 验证终端标题设置在Windows Terminal和Git Bash中的兼容性

使用方法：
1. 在Windows Terminal中：.\test-fixes.ps1
2. 在Git Bash中：通过PowerShell运行
#>

Write-Host "=== 终端标题设置修复测试 ===" -ForegroundColor Cyan
Write-Host "测试时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# 导入模块
$moduleRoot = $PSScriptRoot
$libPath = Join-Path $moduleRoot "lib"

Write-Host "导入模块..." -ForegroundColor Yellow
try {
    Import-Module (Join-Path $libPath "OscSender.psm1") -Force
    Import-Module (Join-Path $libPath "PersistentTitle.psm1") -Force -ErrorAction SilentlyContinue
    Write-Host "✓ 模块导入成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 模块导入失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 1. 测试环境检测
Write-Host "1. 环境检测测试:" -ForegroundColor Yellow

$oscSupport = Test-OscSupport
Write-Host "  Test-OscSupport 返回: $oscSupport" -ForegroundColor $(if ($oscSupport) { "Green" } else { "Yellow" })

# 检测终端类型
$terminalType = "未知"
if ($env:WT_SESSION) {
    $terminalType = "Windows Terminal"
} elseif ($env:MSYSTEM -or ($env:SHELL -and $env:SHELL -like "*bash*")) {
    $terminalType = "Git Bash/Mintty"
} elseif ($env:TERM_PROGRAM -eq "vscode") {
    $terminalType = "VS Code"
} elseif ($env:ConEmuANSI -eq "ON") {
    $terminalType = "ConEmu/Cmder"
}

Write-Host "  检测到的终端类型: $terminalType" -ForegroundColor Cyan

Write-Host ""

# 2. 测试Set-TermTitleLegacy函数
Write-Host "2. Set-TermTitleLegacy函数测试:" -ForegroundColor Yellow

$testTitle = "[测试] Set-TermTitleLegacy - $(Get-Date -Format 'HH:mm:ss')"
Write-Host "  测试标题: '$testTitle'" -ForegroundColor White

$result = Set-TermTitleLegacy -Title $testTitle
Write-Host "  返回结果: $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })

if ($result) {
    Write-Host "  ✓ 标题设置成功" -ForegroundColor Green
} else {
    Write-Host "  ✗ 标题设置失败" -ForegroundColor Red
}

Write-Host ""

# 3. 测试Send-OscTitle函数
Write-Host "3. Send-OscTitle函数测试:" -ForegroundColor Yellow

if ($oscSupport) {
    $testTitle = "[测试] Send-OscTitle - $(Get-Date -Format 'HH:mm:ss')"
    Write-Host "  测试标题: '$testTitle'" -ForegroundColor White

    $result = Send-OscTitle -Title $testTitle
    Write-Host "  返回结果: $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })

    if ($result) {
        Write-Host "  ✓ OSC标题设置成功" -ForegroundColor Green
    } else {
        Write-Host "  ✗ OSC标题设置失败" -ForegroundColor Red
    }
} else {
    Write-Host "  ⚠ 跳过（终端不支持OSC序列）" -ForegroundColor Gray
}

Write-Host ""

# 4. 测试Set-NotificationVisual函数
Write-Host "4. Set-NotificationVisual函数测试:" -ForegroundColor Yellow

$testTitle = "[测试] Notification - $(Get-Date -Format 'HH:mm:ss')"
Write-Host "  测试标题: '$testTitle'" -ForegroundColor White

$result = Set-NotificationVisual -State "blue" -Title $testTitle
Write-Host "  返回结果: $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })

if ($result) {
    Write-Host "  ✓ 通知可视化设置成功" -ForegroundColor Green
} else {
    Write-Host "  ✗ 通知可视化设置失败" -ForegroundColor Red
}

Write-Host ""

# 5. 测试PersistentTitle功能（简略测试）
Write-Host "5. PersistentTitle功能测试:" -ForegroundColor Yellow

if (Get-Command Set-PersistentTitle -ErrorAction SilentlyContinue) {
    $testTitle = "[测试] Persistent - $(Get-Date -Format 'HH:mm:ss')"
    Write-Host "  测试标题: '$testTitle'" -ForegroundColor White

    try {
        Set-PersistentTitle -Title $testTitle -State "blue" -Duration 2
        Write-Host "  ✓ 持久化标题设置成功（显示2秒）" -ForegroundColor Green

        # 等待一下让用户看到效果
        Write-Host "  等待2秒..." -ForegroundColor Gray
        Start-Sleep -Seconds 2

        # 清理
        if (Get-Command Clear-PersistentTitle -ErrorAction SilentlyContinue) {
            Clear-PersistentTitle
            Write-Host "  ✓ 持久化标题清理成功" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ✗ 持久化标题设置失败: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  ⚠ 跳过（PersistentTitle模块不可用）" -ForegroundColor Gray
}

Write-Host ""

# 6. 测试Git Bash特定功能
Write-Host "6. Git Bash特定测试:" -ForegroundColor Yellow

if ($env:MSYSTEM -or ($env:SHELL -and $env:SHELL -like "*bash*")) {
    Write-Host "  ✓ 检测到Git Bash环境" -ForegroundColor Green

    # 测试环境变量
    Write-Host "  环境变量检查:" -ForegroundColor White
    Write-Host "    MSYSTEM: $($env:MSYSTEM)" -ForegroundColor Gray
    Write-Host "    SHELL: $($env:SHELL)" -ForegroundColor Gray
    Write-Host "    WT_SESSION: $($env:WT_SESSION)" -ForegroundColor Gray

    # 测试$Host对象
    Write-Host "  PowerShell Host对象测试:" -ForegroundColor White
    try {
        $hostType = $Host.GetType().FullName
        Write-Host "    Host类型: $hostType" -ForegroundColor Gray
        Write-Host "    RawUI可用: $($Host.UI.RawUI -ne $null)" -ForegroundColor Gray
    } catch {
        Write-Host "    Host检查失败: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  ✗ 非Git Bash环境" -ForegroundColor Gray
}

Write-Host ""

# 7. 兼容性总结
Write-Host "7. 兼容性测试总结:" -ForegroundColor Cyan

$testResults = @{
    "环境检测" = $true
    "Set-TermTitleLegacy" = $result
    "OSC支持" = $oscSupport
    "Set-NotificationVisual" = $result
}

if ($env:MSYSTEM -or ($env:SHELL -and $env:SHELL -like "*bash*")) {
    $testResults["Git Bash检测"] = $true
}

Write-Host "  测试项目:" -ForegroundColor White
foreach ($test in $testResults.Keys) {
    $status = $testResults[$test]
    $statusSymbol = if ($status) { "✓" } else { "✗" }
    $statusColor = if ($status) { "Green" } else { "Red" }
    Write-Host "    $statusSymbol $test" -ForegroundColor $statusColor
}

Write-Host ""

if ($testResults["Set-TermTitleLegacy"] -or $testResults["Set-NotificationVisual"]) {
    Write-Host "✅ 修复成功：至少有一种标题设置方法在工作" -ForegroundColor Green
} else {
    Write-Host "❌ 修复失败：所有标题设置方法都失败" -ForegroundColor Red
}

Write-Host ""

Write-Host "=== 测试完成 ===" -ForegroundColor Cyan
Write-Host "提示：在不同终端中运行此测试以验证兼容性" -ForegroundColor Yellow
Write-Host "- Windows Terminal：应支持OSC和传统方法" -ForegroundColor Gray
Write-Host "- Git Bash：应使用传统方法或Git Bash特定回退" -ForegroundColor Gray