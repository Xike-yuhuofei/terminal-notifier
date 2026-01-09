<#
测试脚本：验证Git Bash环境下的终端标题设置问题

此脚本用于验证在Git Bash环境中终端标题设置失败的根本原因
#>

Write-Host "=== Git Bash环境诊断测试 ===" -ForegroundColor Cyan
Write-Host "测试时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# 1. 检查环境变量
Write-Host "1. 环境变量检查:" -ForegroundColor Yellow
$envVars = @(
    "WT_SESSION",
    "TERM_PROGRAM",
    "ConEmuANSI",
    "COLORTERM",
    "TERM",
    "MSYSTEM",
    "SHELL",
    "PWD"
)

foreach ($var in $envVars) {
    $value = [Environment]::GetEnvironmentVariable($var)
    if ($value) {
        Write-Host "  $var = $value" -ForegroundColor Green
    } else {
        Write-Host "  $var = [未设置]" -ForegroundColor Gray
    }
}

Write-Host ""

# 2. 检查$Host对象属性
Write-Host "2. PowerShell Host对象检查:" -ForegroundColor Yellow
try {
    $hostType = $Host.GetType().FullName
    Write-Host "  Host类型: $hostType" -ForegroundColor Green

    $uiType = $Host.UI.GetType().FullName
    Write-Host "  UI类型: $uiType" -ForegroundColor Green

    if ($Host.UI.RawUI) {
        $rawUiType = $Host.UI.RawUI.GetType().FullName
        Write-Host "  RawUI类型: $rawUiType" -ForegroundColor Green

        $currentTitle = $Host.UI.RawUI.WindowTitle
        Write-Host "  当前窗口标题: '$currentTitle'" -ForegroundColor Green
    } else {
        Write-Host "  RawUI属性不存在" -ForegroundColor Red
    }
} catch {
    Write-Host "  检查失败: $_" -ForegroundColor Red
}

Write-Host ""

# 3. 测试标题设置功能
Write-Host "3. 标题设置功能测试:" -ForegroundColor Yellow

# 测试传统方法
Write-Host "  a) 测试传统方法 (`$Host.UI.RawUI.WindowTitle`):" -ForegroundColor White
try {
    $testTitle = "[测试] 传统方法 - $(Get-Date -Format 'HH:mm:ss')"
    $Host.UI.RawUI.WindowTitle = $testTitle
    Write-Host "    ✓ 设置成功: '$testTitle'" -ForegroundColor Green

    # 验证是否真的设置了
    $verifiedTitle = $Host.UI.RawUI.WindowTitle
    if ($verifiedTitle -eq $testTitle) {
        Write-Host "    ✓ 验证成功: 标题已更新" -ForegroundColor Green
    } else {
        Write-Host "    ⚠ 验证失败: 期望 '$testTitle', 实际 '$verifiedTitle'" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    ✗ 设置失败: $_" -ForegroundColor Red
}

# 测试OSC序列方法
Write-Host "  b) 测试OSC序列方法 (`[Console]::Write`):" -ForegroundColor White
try {
    $esc = [char]27
    $testTitle = "[测试] OSC方法 - $(Get-Date -Format 'HH:mm:ss')"
    [Console]::Write("${esc}]2;$testTitle`a")
    Write-Host "    ✓ OSC序列已发送: '$testTitle'" -ForegroundColor Green

    # 给终端一点时间处理
    Start-Sleep -Milliseconds 100

    # 检查当前标题
    $currentTitle = $Host.UI.RawUI.WindowTitle
    Write-Host "    ✓ 当前标题: '$currentTitle'" -ForegroundColor Green
} catch {
    Write-Host "    ✗ OSC发送失败: $_" -ForegroundColor Red
}

Write-Host ""

# 4. 测试现有Test-OscSupport函数
Write-Host "4. 现有Test-OscSupport函数测试:" -ForegroundColor Yellow
try {
    # 导入模块来测试现有函数
    $modulePath = Join-Path $PSScriptRoot "lib\OscSender.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -ErrorAction SilentlyContinue

        if (Get-Command Test-OscSupport -ErrorAction SilentlyContinue) {
            $oscSupport = Test-OscSupport
            Write-Host "  Test-OscSupport返回: $oscSupport" -ForegroundColor $(if ($oscSupport) { "Green" } else { "Yellow" })

            # 测试实际函数
            Write-Host "  c) 测试Send-OscTitle函数:" -ForegroundColor White
            $testTitle = "[测试] Send-OscTitle - $(Get-Date -Format 'HH:mm:ss')"
            $result = Send-OscTitle -Title $testTitle
            Write-Host "    返回结果: $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })

            Write-Host "  d) 测试Set-TermTitleLegacy函数:" -ForegroundColor White
            $testTitle = "[测试] Set-TermTitleLegacy - $(Get-Date -Format 'HH:mm:ss')"
            $result = Set-TermTitleLegacy -Title $testTitle
            Write-Host "    返回结果: $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })

            # 测试Set-NotificationVisual
            Write-Host "  e) 测试Set-NotificationVisual函数:" -ForegroundColor White
            $testTitle = "[测试] Visual - $(Get-Date -Format 'HH:mm:ss')"
            $result = Set-NotificationVisual -State "blue" -Title $testTitle
            Write-Host "    返回结果: $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })
        } else {
            Write-Host "  Test-OscSupport函数未找到" -ForegroundColor Red
        }
    } else {
        Write-Host "  模块文件未找到: $modulePath" -ForegroundColor Red
    }
} catch {
    Write-Host "  测试失败: $_" -ForegroundColor Red
}

Write-Host ""

# 5. 检测终端类型
Write-Host "5. 终端类型检测:" -ForegroundColor Yellow

# 检查是否在Git Bash中
$isGitBash = $false
if ($env:SHELL -like "*bash*" -or $env:MSYSTEM -or (Test-Path "C:\Program Files\Git\bin\bash.exe")) {
    $isGitBash = $true
    Write-Host "  ✓ 检测到Git Bash环境" -ForegroundColor Green
} else {
    Write-Host "  ✗ 非Git Bash环境" -ForegroundColor Gray
}

# 检查是否在Windows Terminal中
$isWindowsTerminal = $false
if ($env:WT_SESSION) {
    $isWindowsTerminal = $true
    Write-Host "  ✓ 检测到Windows Terminal环境" -ForegroundColor Green
} else {
    Write-Host "  ✗ 非Windows Terminal环境" -ForegroundColor Gray
}

# 检查是否在VS Code中
$isVSCode = $false
if ($env:TERM_PROGRAM -eq "vscode") {
    $isVSCode = $true
    Write-Host "  ✓ 检测到VS Code终端" -ForegroundColor Green
} else {
    Write-Host "  ✗ 非VS Code终端" -ForegroundColor Gray
}

Write-Host ""

# 6. 总结和建议
Write-Host "6. 诊断总结:" -ForegroundColor Cyan
Write-Host "  环境类型: $(if ($isGitBash) { 'Git Bash' } elseif ($isWindowsTerminal) { 'Windows Terminal' } elseif ($isVSCode) { 'VS Code' } else { '未知' })"
Write-Host "  OSC支持: $(if ($oscSupport) { '是' } else { '否' })"
Write-Host "  传统方法: $(try { $Host.UI.RawUI.WindowTitle = '测试'; '可用' } catch { '不可用' })"
Write-Host ""

Write-Host "=== 测试完成 ===" -ForegroundColor Cyan