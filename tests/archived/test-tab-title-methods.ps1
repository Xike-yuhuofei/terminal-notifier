# test-tab-title-methods.ps1
# 测试多种修改 Windows Terminal 标题的方案

#Requires -Version 5.1
Set-StrictMode -Version Latest

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Windows Terminal 标题修改方案测试" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# ============================================
# 方法 1: OSC 转义序列（最兼容）
# ============================================
function Set-TabTitleOSC {
    <#
    .SYNOPSIS
    使用 OSC 转义序列设置标题（推荐方法）

    .DESCRIPTION
    OSC (Operating System Command) 序列是标准的 ANSI 转义序列
    格式: ESC ] 0 ; 标题内容 BEL
    优点: 跨终端兼容，标准化方法
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title
    )

    try {
        $ESC = [char]27
        $BEL = [char]7

        # OSC 0; 序列（设置窗口和标签标题）
        Write-Host "$ESC]0;$Title$BEL" -NoNewline

        return $true
    }
    catch {
        Write-Host "  ❌ OSC 方法失败: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================
# 方法 2: PowerShell RawUI（Windows 原生）
# ============================================
function Set-TabTitleRawUI {
    <#
    .SYNOPSIS
    使用 PowerShell RawUI 设置标题

    .DESCRIPTION
    直接操作 Windows 终端的标题属性
    优点: 简单直接，仅适用于 Windows
    缺点: 可能不适用于所有终端模拟器
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title
    )

    try {
        $Host.UI.RawUI.WindowTitle = $Title
        return $true
    }
    catch {
        Write-Host "  ❌ RawUI 方法失败: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================
# 方法 3: 混合方法（OSC + RawUI 回退）
# ============================================
function Set-TabTitleHybrid {
    <#
    .SYNOPSIS
    混合方法：优先使用 OSC，失败时回退到 RawUI

    .DESCRIPTION
    结合两种方法的优点，确保最大兼容性
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title
    )

    # 先尝试 OSC 方法
    $oscResult = Set-TabTitleOSC -Title $Title

    if (-not $oscResult) {
        # OSC 失败，回退到 RawUI
        Write-Host "  ⚠️  OSC 方法失败，尝试 RawUI..." -ForegroundColor Yellow
        $rawResult = Set-TabTitleRawUI -Title $Title
        return $rawResult
    }

    return $true
}

# ============================================
# 方法 4: 带图标的标题
# ============================================
function Set-TabTitleWithIcon {
    <#
    .SYNOPSIS
    设置带图标的标题

    .DESCRIPTION
    在标题前添加图标，增强视觉识别
    支持的图标: ⚠️ 📢 🔔 ✅ ❌ 🚀 🛠️ 📝
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,

        [Parameter(Mandatory=$false)]
        [string]$Icon = ""
    )

    $displayTitle = if ($Icon) {
        "[$Icon] $Title"
    } else {
        $Title
    }

    return Set-TabTitleHybrid -Title $displayTitle
}

# ============================================
# 测试用例
# ============================================

function Test-TitleMethod {
    <#
    .SYNOPSIS
    测试单个标题修改方法
    #>
    param(
        [string]$MethodName,
        [scriptblock]$Method,
        [string]$TestTitle
    )

    Write-Host "`n测试: $MethodName" -ForegroundColor Green
    Write-Host "目标标题: $TestTitle" -ForegroundColor Gray
    Write-Host "当前标题: $($Host.UI.RawUI.WindowTitle)" -ForegroundColor DarkGray

    $result = & $Method -Title $TestTitle

    Write-Host "设置后标题: $($Host.UI.RawUI.WindowTitle)" -ForegroundColor Cyan

    if ($result) {
        Write-Host "✅ 成功" -ForegroundColor Green
    } else {
        Write-Host "❌ 失败" -ForegroundColor Red
    }

    return $result
}

# ============================================
# 开始测试
# ============================================

$testResults = @()

# 测试 1: OSC 方法
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试 1: OSC 转义序列方法" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

$result1 = Test-TitleMethod -MethodName "OSC 方法" -Method ${function:Set-TabTitleOSC} -TestTitle "测试 OSC 方法 - terminal-notifier"
$testResults += [PSCustomObject]@{
    Method = "OSC 转义序列"
    Result = if ($result1) { "✅ 成功" } else { "❌ 失败" }
}
Start-Sleep -Seconds 2

# 测试 2: RawUI 方法
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试 2: PowerShell RawUI 方法" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

$result2 = Test-TitleMethod -MethodName "RawUI 方法" -Method ${function:Set-TabTitleRawUI} -TestTitle "测试 RawUI 方法 - terminal-notifier"
$testResults += [PSCustomObject]@{
    Method = "PowerShell RawUI"
    Result = if ($result2) { "✅ 成功" } else { "❌ 失败" }
}
Start-Sleep -Seconds 2

# 测试 3: 混合方法
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试 3: 混合方法（OSC + RawUI 回退）" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

$result3 = Test-TitleMethod -MethodName "混合方法" -Method ${function:Set-TabTitleHybrid} -TestTitle "测试混合方法 - terminal-notifier"
$testResults += [PSCustomObject]@{
    Method = "混合方法（推荐）"
    Result = if ($result3) { "✅ 成功" } else { "❌ 失败" }
}
Start-Sleep -Seconds 2

# 测试 4: 带图标的标题
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试 4: 带图标的标题" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n测试图标: ⚠️（警告）" -ForegroundColor Green
$result4a = Set-TabTitleWithIcon -Title "需要输入 - terminal-notifier" -Icon "⚠️"
Write-Host "当前标题: $($Host.UI.RawUI.WindowTitle)" -ForegroundColor Cyan
Start-Sleep -Seconds 2

Write-Host "`n测试图标: 📢（通知）" -ForegroundColor Green
$result4b = Set-TabTitleWithIcon -Title "新通知 - terminal-notifier" -Icon "📢"
Write-Host "当前标题: $($Host.UI.RawUI.WindowTitle)" -ForegroundColor Cyan
Start-Sleep -Seconds 2

Write-Host "`n测试图标: 🔔（铃声）" -ForegroundColor Green
$result4c = Set-TabTitleWithIcon -Title "任务完成 - terminal-notifier" -Icon "🔔"
Write-Host "当前标题: $($Host.UI.RawUI.WindowTitle)" -ForegroundColor Cyan

$testResults += [PSCustomObject]@{
    Method = "带图标标题"
    Result = if ($result4a -and $result4b -and $result4c) { "✅ 成功" } else { "❌ 失败" }
}

# 测试 5: 模拟实际 Hook 场景
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试 5: 模拟实际 Hook 场景" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

$projectName = "terminal-notifier"
$windowName = "编译测试"

Write-Host "`n场景 1: Stop Hook（需要输入）" -ForegroundColor Yellow
Set-TabTitleWithIcon -Title "需要输入 - $projectName" -Icon "⚠️"
Write-Host "标题已设置为: $($Host.UI.RawUI.WindowTitle)" -ForegroundColor Cyan
Start-Sleep -Seconds 2

Write-Host "`n场景 2: Notification Hook（新通知）" -ForegroundColor Yellow
Set-TabTitleWithIcon -Title "新通知 - $projectName" -Icon "📢"
Write-Host "标题已设置为: $($Host.UI.RawUI.WindowTitle)" -ForegroundColor Cyan
Start-Sleep -Seconds 2

Write-Host "`n场景 3: 带自定义窗口名称" -ForegroundColor Yellow
Set-TabTitleWithIcon -Title "需要输入 - $projectName" -Icon "⚠️"
Write-Host "窗口名称: $windowName" -ForegroundColor Gray
Write-Host "标题已设置为: $($Host.UI.RawUI.WindowTitle)" -ForegroundColor Cyan

# ============================================
# 测试结果汇总
# ============================================

Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "测试结果汇总" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

$testResults | Format-Table -AutoSize

Write-Host "`n✅ 所有测试完成！" -ForegroundColor Green
Write-Host "`n💡 推荐使用混合方法（Set-TabTitleHybrid 或 Set-TabTitleWithIcon）" -ForegroundColor Yellow
Write-Host "   该方法结合了 OSC 序列的兼容性和 RawUI 的可靠性" -ForegroundColor Yellow
Write-Host "`n📝 下一步: 创建 TabTitleManager.psm1 模块并集成到 Hook 脚本中" -ForegroundColor Cyan

# 恢复默认标题
Write-Host "`n恢复默认标题..." -ForegroundColor Gray
Set-TabTitleHybrid -Title "Windows Terminal"
Start-Sleep -Seconds 1

Write-Host "`n按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
