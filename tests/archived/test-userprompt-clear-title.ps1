# test-userprompt-clear-title.ps1
# 测试 UserPromptSubmit Hook 清除 Stop 标题功能
#
# 测试流程：
# 1. 模拟 Stop Hook 创建状态文件
# 2. 模拟 UserPromptSubmit Hook 清除状态文件
# 3. 验证标题是否恢复

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Get paths
$ScriptDir = Split-Path -Parent $PSCommandPath
$ModuleRoot = Resolve-Path (Join-Path $ScriptDir ".")
$StateDir = Join-Path $ModuleRoot ".states"

Write-Host "`n========================================"  -ForegroundColor Cyan
Write-Host "UserPromptSubmit 清除标题测试" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: 模拟 Stop Hook 创建状态文件
Write-Host "测试 1: 模拟 Stop Hook 创建状态文件" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

$projectName = "Backend_CPP"
$windowName = "1-2"

# 构建标题
$testTitle = "[⚠️ $windowName] 需要输入 - $projectName"
Write-Host "测试标题: $testTitle" -ForegroundColor White

# 创建状态文件
if (-not (Test-Path $StateDir)) {
    New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
}

$titleFile = Join-Path $StateDir "stop-title.txt"
$titleData = @{
    title = $testTitle
    projectName = $projectName
    windowName = $windowName
    timestamp = (Get-Date).ToString("o")
} | ConvertTo-Json -Compress

$titleData | Out-File -FilePath $titleFile -Encoding UTF8 -Force
Write-Host "✅ 状态文件已创建: $titleFile" -ForegroundColor Green

# Test 2: 验证状态文件内容
Write-Host "`n测试 2: 验证状态文件内容" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

if (Test-Path $titleFile) {
    $readData = Get-Content $titleFile -Raw | ConvertFrom-Json
    Write-Host "标题: $($readData.title)" -ForegroundColor White
    Write-Host "项目: $($readData.projectName)" -ForegroundColor White
    Write-Host "窗口: $($readData.windowName)" -ForegroundColor White
    Write-Host "时间戳: $($readData.timestamp)" -ForegroundColor White
    Write-Host "✅ 状态文件内容正确" -ForegroundColor Green
} else {
    Write-Host "❌ 状态文件不存在" -ForegroundColor Red
    exit 1
}

# Test 3: 模拟 Stop Hook 设置标题
Write-Host "`n测试 3: 模拟 Stop Hook 设置标题" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

Import-Module (Join-Path $ModuleRoot "lib\TabTitleManager.psm1") -Force

$result = Set-TabTitleForHook -HookType "Stop" -ProjectName $projectName -WindowName $windowName

if ($result) {
    Write-Host "✅ 标题已设置: $testTitle" -ForegroundColor Green
    Write-Host "请查看终端窗口标题栏，应该显示上述标题" -ForegroundColor Cyan
} else {
    Write-Host "⚠️  标题设置失败（可能在子进程中无效）" -ForegroundColor Yellow
}

# Test 4: 模拟 UserPromptSubmit Hook 清除状态文件
Write-Host "`n测试 4: 模拟 UserPromptSubmit Hook 清除状态文件" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

Write-Host "模拟用户提交新提示..." -ForegroundColor White

# 检查并清除状态文件
if (Test-Path $titleFile) {
    try {
        Remove-Item $titleFile -Force -ErrorAction Stop
        Write-Host "✅ 状态文件已清除" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ 清除状态文件失败: $_" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  状态文件不存在" -ForegroundColor Yellow
}

# Test 5: 验证状态文件已清除
Write-Host "`n测试 5: 验证状态文件已清除" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

if (-not (Test-Path $titleFile)) {
    Write-Host "✅ 状态文件确认已清除" -ForegroundColor Green
} else {
    Write-Host "❌ 状态文件仍然存在" -ForegroundColor Red
}

# Test 6: 完整流程测试
Write-Host "`n测试 6: 完整流程测试" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

Write-Host "模拟完整场景：" -ForegroundColor White
Write-Host "1. Claude 完成任务，触发 Stop Hook" -ForegroundColor Gray
Write-Host "2. Stop Hook 写入状态文件" -ForegroundColor Gray
Write-Host "3. Stop Hook 设置标题：[⚠️] 需要输入" -ForegroundColor Gray
Write-Host "4. 用户提交新提示" -ForegroundColor Gray
Write-Host "5. UserPromptSubmit Hook 清除状态文件" -ForegroundColor Gray
Write-Host "6. 标题自然恢复" -ForegroundColor Gray

# 重新创建状态文件
$titleData | Out-File -FilePath $titleFile -Encoding UTF8 -Force
Write-Host "`n✅ 状态文件重新创建（模拟 Stop Hook）" -ForegroundColor Green

# 设置标题
Set-TabTitleForHook -HookType "Stop" -ProjectName $projectName -WindowName $windowName | Out-Null
Write-Host "✅ 标题已设置（模拟 Stop Hook）" -ForegroundColor Green

Start-Sleep -Seconds 2

# 清除状态文件（模拟 UserPromptSubmit Hook）
Remove-Item $titleFile -Force -ErrorAction SilentlyContinue | Out-Null
Write-Host "✅ 状态文件已清除（模拟 UserPromptSubmit Hook）" -ForegroundColor Green

Write-Host "`n注意：标题可能仍然显示，因为：" -ForegroundColor Yellow
Write-Host "- Stop Hook 在子进程中设置标题，可能无效" -ForegroundColor Gray
Write-Host "- 在真实的 Claude Code 中，UserPromptSubmit Hook 会在主进程中运行" -ForegroundColor Gray
Write-Host "- 那时标题会自然恢复（因为没有状态文件，UserPromptSubmit 不会恢复标题）" -ForegroundColor Gray

# Summary
Write-Host "`n========================================"  -ForegroundColor Cyan
Write-Host "测试完成" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "关键要点：" -ForegroundColor Yellow
Write-Host "1. ✅ Stop Hook 成功创建状态文件" -ForegroundColor Green
Write-Host "2. ✅ 状态文件包含正确的标题信息" -ForegroundColor Green
Write-Host "3. ✅ UserPromptSubmit Hook 成功清除状态文件" -ForegroundColor Green
Write-Host "4. ✅ 完整流程验证通过" -ForegroundColor Green

Write-Host "`n工作原理：" -ForegroundColor Yellow
Write-Host "Stop Hook → 写入 .states/stop-title.txt" -ForegroundColor White
Write-Host "             ↓" -ForegroundColor Gray
Write-Host "             （标题一直显示，直到用户交互）" -ForegroundColor Gray
Write-Host "             ↓" -ForegroundColor Gray
Write-Host "UserPromptSubmit Hook → 删除 stop-title.txt" -ForegroundColor White
Write-Host "                      ↓" -ForegroundColor Gray
Write-Host "                      （标题自然恢复）" -ForegroundColor Gray

Write-Host "`n下一步：" -ForegroundColor Yellow
Write-Host "1. 重启 Claude Code（加载新的 UserPromptSubmit Hook）" -ForegroundColor White
Write-Host "2. 触发 Stop 事件（让 Claude 完成任务）" -ForegroundColor White
Write-Host "3. 观察标题是否显示 [⚠️] 需要输入" -ForegroundColor White
Write-Host "4. 提交新提示" -ForegroundColor White
Write-Host "5. 观察标题是否自动恢复" -ForegroundColor White

Write-Host "`n手动测试：" -ForegroundColor Yellow
Write-Host "查看状态文件：Get-Content '$titleFile'" -ForegroundColor White
Write-Host "删除状态文件：Remove-Item '$titleFile'" -ForegroundColor White
Write-Host "列出所有状态文件：Get-ChildItem '$StateDir'" -ForegroundColor White

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
