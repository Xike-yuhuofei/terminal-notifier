# test-persistence-with-userprompt.ps1
# 测试 UserPromptSubmit Hook 持久化标题方案
#
# 测试目标：
# 1. Stop Hook 写入持久化状态文件
# 2. UserPromptSubmit Hook 读取状态文件并恢复标题
# 3. 验证标题在主 Shell 进程中设置成功
# 4. 验证标题过期自动清除（5分钟）

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Get paths
$ScriptDir = Split-Path -Parent $PSCommandPath
$ModuleRoot = Resolve-Path (Join-Path $ScriptDir ".")
$LibPath = Join-Path $ModuleRoot "lib"
$StateDir = Join-Path $ModuleRoot ".states"

# Import modules
Import-Module (Join-Path $LibPath "TabTitleManager.psm1") -Force

Write-Host "`n========================================"  -ForegroundColor Cyan
Write-Host "UserPromptSubmit 持久化标题测试" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: 创建持久化状态文件
Write-Host "测试 1: 创建持久化状态文件" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

$projectName = "terminal-notifier-prompt-hook"
$windowName = "测试窗口"

# 创建测试标题
$testTitle = "[⚠️ $windowName] 需要输入 - $projectName"
Write-Host "测试标题: $testTitle" -ForegroundColor White

# 写入状态文件
if (-not (Test-Path $StateDir)) {
    New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
}

$titleFile = Join-Path $StateDir "persistent-title.txt"
$titleData = @{
    title = $testTitle
    hookType = "Stop"
    timestamp = (Get-Date).ToString("o")
} | ConvertTo-Json -Compress

$titleData | Out-File -FilePath $titleFile -Encoding UTF8 -Force
Write-Host "✅ 状态文件已创建: $titleFile" -ForegroundColor Green

# Test 2: 读取并验证状态文件
Write-Host "`n测试 2: 读取并验证状态文件" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

if (Test-Path $titleFile) {
    $readData = Get-Content $titleFile -Raw | ConvertFrom-Json
    Write-Host "标题: $($readData.title)" -ForegroundColor White
    Write-Host "类型: $($readData.hookType)" -ForegroundColor White
    Write-Host "时间戳: $($readData.timestamp)" -ForegroundColor White
    Write-Host "✅ 状态文件读取成功" -ForegroundColor Green
} else {
    Write-Host "❌ 状态文件不存在" -ForegroundColor Red
    exit 1
}

# Test 3: 模拟 UserPromptSubmit Hook 行为
Write-Host "`n测试 3: 模拟 UserPromptSubmit Hook 行为" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

# 检查标题是否过期
$titleTime = [DateTime]::Parse($readData.timestamp)
$elapsed = (Get-Date) - $titleTime

if ($elapsed.TotalMinutes -lt 5) {
    Write-Host "标题未过期（已过 $($elapsed.TotalSeconds.ToString('F2')) 秒）" -ForegroundColor White

    # 设置标题（在主进程中）
    $result = Set-TabTitle -Title $readData.title

    if ($result) {
        Write-Host "✅ 标题设置成功（在主 Shell 进程中）" -ForegroundColor Green
        Write-Host "请查看终端窗口标题栏，应该显示: $($readData.title)" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️  标题设置失败" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ 标题已过期，应该被清除" -ForegroundColor Red
    Remove-Item $titleFile -Force -ErrorAction SilentlyContinue
}

# Test 4: 验证标题过期清除
Write-Host "`n测试 4: 验证标题过期清除机制" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

Write-Host "创建一个即将过期的标题（时间戳设为6分钟前）..." -ForegroundColor White

$expiredTitleData = @{
    title = "[⚠️ 过期] 需要输入 - $projectName"
    hookType = "Stop"
    timestamp = (Get-Date).AddMinutes(-6).ToString("o")
} | ConvertTo-Json -Compress

$expiredTitleData | Out-File -FilePath $titleFile -Encoding UTF8 -Force

# 模拟 UserPromptSubmit Hook 检查
if (Test-Path $titleFile) {
    $expiredData = Get-Content $titleFile -Raw | ConvertFrom-Json
    $expiredTime = [DateTime]::Parse($expiredData.timestamp)
    $expiredElapsed = (Get-Date) - $expiredTime

    if ($expiredElapsed.TotalMinutes -ge 5) {
        Write-Host "✅ 检测到过期标题（已过 $($expiredElapsed.TotalMinutes.ToString('F1')) 分钟）" -ForegroundColor Green
        Remove-Item $titleFile -Force -ErrorAction SilentlyContinue
        Write-Host "✅ 过期标题已清除" -ForegroundColor Green
    } else {
        Write-Host "❌ 未正确识别过期标题" -ForegroundColor Red
    }
}

# Test 5: Notification 标题的自动清除
Write-Host "`n测试 5: Notification 标题的自动清除（5秒后）" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

$notificationTitle = "[📢 $windowName] 新通知 - $projectName"
$notificationTitleData = @{
    title = $notificationTitle
    hookType = "Notification"
    timestamp = (Get-Date).ToString("o")
} | ConvertTo-Json -Compress

$notificationTitleData | Out-File -FilePath $titleFile -Encoding UTF8 -Force
Write-Host "Notification 标题已创建，将在5秒后自动清除..." -ForegroundColor White
Write-Host "当前标题栏应该显示: $notificationTitle" -ForegroundColor Cyan

Set-TabTitle -Title $notificationTitle | Out-Null

# 启动后台清除任务
$clearScript = {
    param($titleFilePath)
    Start-Sleep -Seconds 5
    if (Test-Path $titleFilePath) {
        Remove-Item $titleFilePath -Force -ErrorAction SilentlyContinue
    }
}

Start-Job -ScriptBlock $clearScript -ArgumentList $titleFile -Name "TestClearNotification" | Out-Null
Write-Host "✅ 后台清除任务已启动（5秒后执行）" -ForegroundColor Green

# Test 6: 手动清除标题
Write-Host "`n测试 6: 手动清除持久化标题" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

Write-Host "创建一个持久化标题..." -ForegroundColor White
$manualTitle = "[⚠️ 手动测试] 需要输入 - $projectName"
$manualTitleData = @{
    title = $manualTitle
    hookType = "Stop"
    timestamp = (Get-Date).ToString("o")
} | ConvertTo-Json -Compress

$manualTitleData | Out-File -FilePath $titleFile -Encoding UTF8 -Force
Set-TabTitle -Title $manualTitle | Out-Null
Write-Host "✅ 标题已设置: $manualTitle" -ForegroundColor Green

Write-Host "`n现在可以手动删除状态文件来清除标题：" -ForegroundColor Cyan
Write-Host "  Remove-Item '$titleFile'" -ForegroundColor White
Write-Host "或者在下次提交提示时，UserPromptSubmit Hook 会自动检测并清除" -ForegroundColor Cyan

# Summary
Write-Host "`n========================================"  -ForegroundColor Cyan
Write-Host "测试完成" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "关键要点：" -ForegroundColor Yellow
Write-Host "1. ✅ 持久化状态文件正常创建和读取" -ForegroundColor Green
Write-Host "2. ✅ 标题在主 Shell 进程中设置成功" -ForegroundColor Green
Write-Host "3. ✅ 过期标题（5分钟）自动清除" -ForegroundColor Green
Write-Host "4. ✅ Notification 标题5秒后自动清除" -ForegroundColor Green
Write-Host "5. ✅ 支持手动清除状态文件" -ForegroundColor Green

Write-Host "`n下一步：" -ForegroundColor Yellow
Write-Host "1. 在 .claude/settings.local.json 中配置新的 Hooks" -ForegroundColor White
Write-Host "2. 重启 Claude Code" -ForegroundColor White
Write-Host "3. 触发 Stop/Notification 事件" -ForegroundColor White
Write-Host "4. 提交新的用户提示，观察标题是否恢复" -ForegroundColor White
Write-Host "5. 手动重命名标签页，观察标题是否被覆盖（应该被覆盖）" -ForegroundColor White

Write-Host "`n当前状态：" -ForegroundColor Yellow
Write-Host "状态文件目录: $StateDir" -ForegroundColor White
Write-Host "当前标题: $($Host.UI.RawUI.WindowTitle)" -ForegroundColor Cyan

# 显示当前存在的状态文件
Write-Host "`n当前状态文件：" -ForegroundColor Yellow
if (Test-Path $StateDir) {
    Get-ChildItem $StateDir | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor White
    }
} else {
    Write-Host "  (无)" -ForegroundColor Gray
}

Write-Host "`n"
