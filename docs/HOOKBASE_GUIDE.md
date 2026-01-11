# HookBase模块使用指南

## 概述

HookBase.psm1提供了一组抽象方法，用于简化Hook脚本的开发，避免重复代码。

## 核心功能

### 1. 环境初始化

```powershell
# 旧方式（10行）
$ScriptDir = Split-Path -Parent $PSCommandPath
$ModuleRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$LibPath = Join-Path $ModuleRoot "lib"
$inputJson = [Console]::In.ReadToEnd()
$hookData = $inputJson | ConvertFrom-Json
$cwd = $hookData.cwd
$projectName = Split-Path -Leaf $cwd

# 新方式（1行）
$env = Initialize-HookEnvironment
# 访问: $env.ModuleRoot, $env.LibPath, $env.HookData, $env.ProjectName, $env.Cwd
```

### 2. 模块导入

```powershell
# 旧方式（5行）
Import-Module (Join-Path $LibPath "NotificationEnhancements.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $LibPath "ToastNotifier.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $LibPath "PersistentTitle.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $LibPath "StateManager.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $LibPath "TabTitleManager.psm1") -Force -ErrorAction SilentlyContinue

# 新方式（1行）
Import-HookModules -LibPath $LibPath -Modules @(
    "NotificationEnhancements", "ToastNotifier", "PersistentTitle", "StateManager", "TabTitleManager"
)
```

### 3. 窗口名称获取

```powershell
# 旧方式（15行，含fallback逻辑）
$windowName = ""
try {
    $windowName = Get-WindowDisplayName
}
catch {
    $windowName = $projectName
}
if ($windowName -eq $projectName) {
    $stateDir = Join-Path $ModuleRoot ".states"
    $originalTitleFile = Join-Path $stateDir "original-title.txt"
    if (Test-Path $originalTitleFile) {
        $savedTitle = Get-Content $originalTitleFile -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
        if ($savedTitle -and $savedTitle -ne "" -and $savedTitle -ne $projectName) {
            $windowName = $savedTitle
        }
    }
}

# 新方式（1行）
$windowName = Get-WindowNameWithFallback -ProjectName $projectName -ModuleRoot $ModuleRoot
```

### 4. 标题构建

```powershell
# 旧方式（Stop Hook）
if ($windowName -and $windowName -ne $projectName) {
    $title = "[⚠️ $windowName] 需要输入 - $projectName"
} else {
    $title = "[⚠️] 需要输入 - $projectName"
}

# 新方式
$title = Build-StopTitle -WindowName $windowName -ProjectName $projectName

# 旧方式（Notification Hook）
if (Test-Path $originalTitleFile) {
    $originalTitle = Get-Content $originalTitleFile -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
    $title = "[📢] $originalTitle"
} else {
    if ($windowName -and $windowName -ne $projectName) {
        $title = "[📢 $windowName] 新通知 - $projectName"
    } else {
        $title = "[📢] 新通知 - $projectName"
    }
}

# 新方式
$originalTitle = Get-OriginalTitle -ModuleRoot $ModuleRoot
$title = Build-NotificationTitle -WindowName $windowName -ProjectName $projectName -OriginalTitle $originalTitle
```

### 5. Toast通知发送

```powershell
# 旧方式
try {
    Send-StopToast -WindowName $windowName -ProjectName $projectName
}
catch {
    # Toast 失败不应阻止 Hook 执行
}

# 新方式
Invoke-ToastWithFallback -ScriptBlock {
    Send-StopToast -WindowName $windowName -ProjectName $projectName
}
```

### 6. Original Title文件操作

```powershell
# 读取
$title = Get-OriginalTitle -ModuleRoot $ModuleRoot

# 写入
Set-OriginalTitle -ModuleRoot $ModuleRoot -Title "My Title"

# 删除
Remove-OriginalTitle -ModuleRoot $ModuleRoot
```

## 完整示例：重构后的Hook脚本

```powershell
#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# Get script and module paths
$ScriptDir = Split-Path -Parent $PSCommandPath
$ModuleRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$LibPath = Join-Path $ModuleRoot "lib"

# Import HookBase module first
Import-Module (Join-Path $LibPath "HookBase.psm1") -Force -ErrorAction SilentlyContinue

# Import other required modules
Import-HookModules -LibPath $LibPath -Modules @(
    "NotificationEnhancements",
    "ToastNotifier",
    "PersistentTitle",
    "StateManager",
    "TabTitleManager"
)

try {
    # Initialize environment
    $inputJson = [Console]::In.ReadToEnd()
    $hookData = $inputJson | ConvertFrom-Json
    $cwd = $hookData.cwd
    $projectName = Split-Path -Leaf $cwd

    # Get window name with fallback
    $windowName = Get-WindowNameWithFallback -ProjectName $projectName -ModuleRoot $ModuleRoot

    # Build title
    $title = Build-StopTitle -WindowName $windowName -ProjectName $projectName

    # Set persistent title
    try {
        Set-PersistentTitle -Title $title -State "red" -Duration 0
    }
    catch {
        # Title setting failure should not block Hook execution
    }

    # Play sound
    Invoke-TerminalBell -Times 2 -SoundType 'Exclamation'

    # Send toast notification
    Invoke-ToastWithFallback -ScriptBlock {
        Send-StopToast -WindowName $windowName -ProjectName $projectName
    }

    exit 0
}
catch {
    # Don't interfere with Claude's stop behavior
    exit 0
}
```

## 代码减少统计

| Hook脚本 | 原始行数 | 重构后行数 | 减少比例 |
|---------|---------|-----------|---------|
| stop.ps1 | 70 | 60 | 14% |
| notification-with-persistence.ps1 | 140 | ~80 (预估) | 43% |
| session-start.ps1 | 90 | ~60 (预估) | 33% |
| session-end.ps1 | 80 | ~50 (预估) | 38% |
| user-prompt-submit.ps1 | 100 | ~60 (预估) | 40% |

## 维护优势

1. **单一职责**：每个函数只做一件事
2. **易于测试**：可以单独测试每个抽象方法
3. **统一修改**：修改逻辑只需改HookBase.psm1一处
4. **代码复用**：所有Hook脚本共享相同的逻辑
5. **可读性强**：函数名清晰表达意图

## 未来扩展

可以继续添加更多抽象方法：

- `Build-SessionStartTitle` - SessionStart标题构建
- `Build-SessionEndTitle` - SessionEnd标题构建
- `Get-StateFilePath` - 统一状态文件路径获取
- `Invoke-HookWithErrorHandling` - 统一错误处理包装

## 迁移指南

1. 导入HookBase模块
2. 使用`Import-HookModules`替换手动导入
3. 使用`Get-WindowNameWithFallback`替换窗口名称获取逻辑
4. 使用`Build-*Title`函数替换标题构建逻辑
5. 使用`Invoke-ToastWithFallback`替换Toast发送逻辑
6. 测试验证功能正常
