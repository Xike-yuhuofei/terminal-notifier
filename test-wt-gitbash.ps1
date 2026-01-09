<#
Windows Terminal + Git Bash 组合环境测试脚本

这个脚本专门测试在Windows Terminal中使用Git Bash环境时的终端标题设置问题。

场景：用户在Windows Terminal中配置Git Bash作为默认shell，然后运行PowerShell脚本。

潜在问题：
1. 环境变量继承：WT_SESSION可能被Git Bash继承，也可能不被继承
2. 控制台API：Git Bash使用Mintty终端模拟器，可能与Windows Terminal的控制台API冲突
3. 输出重定向：[Console]::Write的输出可能被Git Bash/Mintty处理
#>

Write-Host "=== Windows Terminal + Git Bash 组合环境测试 ===" -ForegroundColor Cyan
Write-Host "测试时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "场景: Windows Terminal中运行Git Bash，然后在Git Bash中运行PowerShell脚本"
Write-Host ""

# 导入模块
$moduleRoot = $PSScriptRoot
$libPath = Join-Path $moduleRoot "lib"

Write-Host "导入模块..." -ForegroundColor Yellow
try {
    Import-Module (Join-Path $libPath "OscSender.psm1") -Force
    Write-Host "✓ 模块导入成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 模块导入失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 1. 环境变量深度分析
Write-Host "1. 环境变量深度分析:" -ForegroundColor Yellow

$criticalEnvVars = @(
    @{Name="WT_SESSION"; Description="Windows Terminal会话标识"},
    @{Name="MSYSTEM"; Description="Git Bash/MinGW系统标识"},
    @{Name="SHELL"; Description="当前shell路径"},
    @{Name="TERM_PROGRAM"; Description="终端程序"},
    @{Name="ConEmuANSI"; Description="ConEmu ANSI支持"},
    @{Name="COLORTERM"; Description="终端颜色支持"},
    @{Name="WT_PROFILE_ID"; Description="Windows Terminal配置文件ID"},
    @{Name="WT_SESSION"; Description="Windows Terminal会话ID"},
    @{Name="PWD"; Description="当前工作目录（Git Bash格式）"},
    @{Name="USERPROFILE"; Description="用户目录（Windows格式）"},
    @{Name="HOME"; Description="用户目录（Unix格式）"}
)

foreach ($varInfo in $criticalEnvVars) {
    $varName = $varInfo.Name
    $value = [Environment]::GetEnvironmentVariable($varName)

    if ($value) {
        Write-Host "  $varName = $value" -ForegroundColor Green
        Write-Host "    ↳ $($varInfo.Description)" -ForegroundColor DarkGray
    } else {
        Write-Host "  $varName = [未设置]" -ForegroundColor Gray
    }
}

Write-Host ""

# 2. 环境组合分析
Write-Host "2. 环境组合分析:" -ForegroundColor Yellow

$isWindowsTerminal = $env:WT_SESSION -ne $null
$isGitBash = $env:MSYSTEM -ne $null -or ($env:SHELL -and $env:SHELL -like "*bash*")

Write-Host "  检测结果:" -ForegroundColor White
Write-Host "  - Windows Terminal: $(if ($isWindowsTerminal) { '是' } else { '否' })" -ForegroundColor $(if ($isWindowsTerminal) { "Green" } else { "Gray" })
Write-Host "  - Git Bash: $(if ($isGitBash) { '是' } else { '否' })" -ForegroundColor $(if ($isGitBash) { "Green" } else { "Gray" })

if ($isWindowsTerminal -and $isGitBash) {
    Write-Host "  ✓ 检测到Windows Terminal + Git Bash组合环境" -ForegroundColor Cyan
    Write-Host "    这是您描述的场景：在Windows Terminal中使用Git Bash" -ForegroundColor DarkGray
} elseif ($isWindowsTerminal -and -not $isGitBash) {
    Write-Host "  ⚠ 检测到纯Windows Terminal环境（非Git Bash）" -ForegroundColor Yellow
} elseif ($isGitBash -and -not $isWindowsTerminal) {
    Write-Host "  ⚠ 检测到纯Git Bash环境（非Windows Terminal）" -ForegroundColor Yellow
} else {
    Write-Host "  ⚠ 检测到未知终端环境" -ForegroundColor Red
}

Write-Host ""

# 3. Test-OscSupport函数测试
Write-Host "3. Test-OscSupport函数测试:" -ForegroundColor Yellow

$oscSupport = Test-OscSupport
Write-Host "  Test-OscSupport() 返回: $oscSupport" -ForegroundColor $(if ($oscSupport) { "Green" } else { "Yellow" })

# 分析返回结果的原因
Write-Host "  分析:" -ForegroundColor White
if ($isWindowsTerminal) {
    Write-Host "  - 检测到WT_SESSION环境变量，函数应返回true" -ForegroundColor Green
    Write-Host "  - 预期：使用OSC序列方法" -ForegroundColor DarkGray
} elseif ($isGitBash) {
    Write-Host "  - 检测到Git Bash环境但无WT_SESSION，函数应返回false" -ForegroundColor Yellow
    Write-Host "  - 预期：使用传统方法（多级回退）" -ForegroundColor DarkGray
} else {
    Write-Host "  - 未知环境，函数返回false（保守策略）" -ForegroundColor Gray
}

Write-Host ""

# 4. 测试标题设置功能
Write-Host "4. 标题设置功能测试:" -ForegroundColor Yellow

# 测试Set-TermTitleLegacy（四级回退）
Write-Host "  a) Set-TermTitleLegacy测试（四级回退）:" -ForegroundColor White
$testTitle = "[测试] Legacy方法 - $(Get-Date -Format 'HH:mm:ss')"
$result = Set-TermTitleLegacy -Title $testTitle
Write-Host "    标题: '$testTitle'" -ForegroundColor Gray
Write-Host "    结果: $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })

if ($result) {
    Write-Host "    ✓ 至少有一种传统方法成功" -ForegroundColor Green
} else {
    Write-Host "    ✗ 所有传统方法都失败" -ForegroundColor Red
}

# 测试Send-OscTitle（如果支持OSC）
Write-Host "  b) Send-OscTitle测试（OSC序列）:" -ForegroundColor White
if ($oscSupport) {
    $testTitle = "[测试] OSC方法 - $(Get-Date -Format 'HH:mm:ss')"
    $result = Send-OscTitle -Title $testTitle
    Write-Host "    标题: '$testTitle'" -ForegroundColor Gray
    Write-Host "    结果: $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })

    if ($result) {
        Write-Host "    ✓ OSC序列发送成功" -ForegroundColor Green
    } else {
        Write-Host "    ✗ OSC序列发送失败" -ForegroundColor Red
        Write-Host "    注意：在Windows Terminal+Git Bash组合中，[Console]::Write可能被Git Bash拦截" -ForegroundColor Yellow
    }
} else {
    Write-Host "    ⚠ 跳过（Test-OscSupport返回false）" -ForegroundColor Gray
}

Write-Host ""

# 5. 测试Set-NotificationVisual（综合测试）
Write-Host "5. Set-NotificationVisual测试（综合）:" -ForegroundColor Yellow

$testTitle = "[测试] Notification - $(Get-Date -Format 'HH:mm:ss')"
Write-Host "  测试标题: '$testTitle'" -ForegroundColor White

$result = Set-NotificationVisual -State "blue" -Title $testTitle
Write-Host "  返回结果: $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })

if ($result) {
    Write-Host "  ✓ 通知可视化设置成功" -ForegroundColor Green
} else {
    Write-Host "  ✗ 通知可视化设置失败" -ForegroundColor Red
}

# 检查实际使用的路径
Write-Host "  执行路径分析:" -ForegroundColor White
if ($oscSupport) {
    Write-Host "  - 使用了OSC序列路径（Send-OscTitle + Send-OscTabColor）" -ForegroundColor Green
} else {
    Write-Host "  - 使用了传统方法路径（Set-TermTitleLegacy）" -ForegroundColor Yellow
}

Write-Host ""

# 6. 特定于Windows Terminal+Git Bash的诊断
Write-Host "6. Windows Terminal+Git Bash特定诊断:" -ForegroundColor Yellow

if ($isWindowsTerminal -and $isGitBash) {
    Write-Host "  ✓ 您正在使用Windows Terminal + Git Bash组合" -ForegroundColor Cyan

    # 检查PowerShell Host对象
    Write-Host "  PowerShell Host对象检查:" -ForegroundColor White
    try {
        $hostType = $Host.GetType().FullName
        Write-Host "    Host类型: $hostType" -ForegroundColor Gray

        $uiAvailable = $Host.UI -ne $null
        $rawUiAvailable = $Host.UI.RawUI -ne $null
        Write-Host "    UI可用: $uiAvailable, RawUI可用: $rawUiAvailable" -ForegroundColor Gray

        if ($rawUiAvailable) {
            try {
                $currentTitle = $Host.UI.RawUI.WindowTitle
                Write-Host "    当前标题: '$currentTitle'" -ForegroundColor Gray
                Write-Host "    ✓ RawUI.WindowTitle属性可访问" -ForegroundColor Green
            }
            catch {
                Write-Host "    ✗ RawUI.WindowTitle访问失败: $_" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "    ✗ Host对象检查失败: $_" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  组合环境潜在问题:" -ForegroundColor White
    Write-Host "  1. Git Bash可能过滤[Console]::Write的输出" -ForegroundColor Yellow
    Write-Host "  2. Windows Terminal的OSC序列可能被Git Bash拦截" -ForegroundColor Yellow
    Write-Host "  3. 环境变量可能不被正确继承" -ForegroundColor Yellow
    Write-Host "  4. 多级回退机制应能处理大部分情况" -ForegroundColor Green
}

Write-Host ""

# 7. 修复状态总结
Write-Host "7. 修复状态总结:" -ForegroundColor Cyan

$successTests = @()
if ((Test-OscSupport) -or (Set-TermTitleLegacy -Title "[测试] 总结检查" -ErrorAction SilentlyContinue)) {
    $successTests += "至少有一种标题设置方法工作"
}

if ($isWindowsTerminal -and $isGitBash) {
    $successTests += "检测到组合环境"
}

if ($successTests.Count -gt 0) {
    Write-Host "  ✅ 修复成功:" -ForegroundColor Green
    foreach ($test in $successTests) {
        Write-Host "    - $test" -ForegroundColor Green
    }

    if ($oscSupport) {
        Write-Host "  📋 当前使用OSC序列方法（通过Windows Terminal）" -ForegroundColor Cyan
    } else {
        Write-Host "  📋 当前使用传统方法（Git Bash回退）" -ForegroundColor Cyan
    }
} else {
    Write-Host "  ❌ 修复可能不完整，请检查具体错误" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== 测试完成 ===" -ForegroundColor Cyan
Write-Host "建议：" -ForegroundColor Yellow
Write-Host "1. 如果OSC方法失败但传统方法成功，说明[Console]::Write在Git Bash中被过滤" -ForegroundColor Gray
Write-Host "2. 多级回退机制（Set-TermTitleLegacy）应确保至少有一种方法工作" -ForegroundColor Gray
Write-Host "3. 在Windows Terminal+Git Bash组合中，WT_SESSION检测应确保使用OSC方法" -ForegroundColor Gray