# TabTitleManager.psm1
# Windows Terminal 标题管理模块
# 提供跨平台兼容的终端标题修改功能

#Requires -Version 5.1

# ============================================
# 私有函数
# ============================================

function Set-TabTitleOSC {
    <#
    .SYNOPSIS
    使用 OSC 转义序列设置终端标题

    .DESCRIPTION
    OSC (Operating System Command) 序列是标准的 ANSI 转义序列
    格式: ESC ] 0 ; 标题内容 BEL

    注意：在 Hook 环境中（作为子进程运行），OSC 序列可能不生效
    因为子进程的 stdout 不会自动转发到父终端

    .PARAMETER Title
    要设置的标题文本

    .RETURNS
    Boolean - 成功返回 true，失败返回 false
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title
    )

    try {
        # 转义特殊字符，防止注入
        $safeTitle = $Title -replace '\x1b', '' -replace '\x07', ''

        # OSC 0; 序列（设置窗口和标签标题）
        # ESC = [char]27, BEL = [char]7
        $oscSequence = "$([char]27)]0;$safeTitle$([char]7)"

        # 发送到终端（使用 Write-Host 确保输出到 stdout）
        Write-Host $oscSequence -NoNewline

        return $true
    }
    catch {
        Write-Verbose "OSC 方法失败: $_"
        return $false
    }
}

function Set-TabTitleRawUI {
    <#
    .SYNOPSIS
    使用 PowerShell RawUI 设置终端标题

    .DESCRIPTION
    直接操作 Windows 终端的标题属性
    适用于 PowerShell 和 Windows Terminal

    .PARAMETER Title
    要设置的标题文本

    .RETURNS
    Boolean - 成功返回 true，失败返回 false
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title
    )

    try {
        $Host.UI.RawUI.WindowTitle = $Title
        return $true
    }
    catch {
        Write-Verbose "RawUI 方法失败: $_"
        return $false
    }
}

# ============================================
# 公共函数
# ============================================

function Set-TabTitle {
    <#
    .SYNOPSIS
    设置 Windows Terminal 标签标题（混合方法）

    .DESCRIPTION
    在 Hook 环境中（作为子进程运行），优先使用 OSC 转义序列
    在直接运行时，优先使用 RawUI（更可靠）

    适用于 Windows Terminal、VS Code 集成终端等多种终端

    .PARAMETER Title
    要设置的标题文本

    .PARAMETER ForceOSC
    强制使用 OSC 序列（Hook 环境推荐）

    .PARAMETER ForceRawUI
    强制使用 RawUI 方法（直接运行推荐）

    .EXAMPLE
    Set-TabTitle -Title "编译测试 - terminal-notifier"

    .EXAMPLE
    Set-TabTitle -Title "需要输入" -ForceOSC

    .NOTES
    作者: Terminal Notifier 项目
    版本: 1.0.0
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

        [Parameter(Mandatory=$false)]
        [switch]$ForceOSC,

        [Parameter(Mandatory=$false)]
        [switch]$ForceRawUI
    )

    # 检测是否在 Hook 环境中运行
    $isHookEnvironment = $env:CLAUDE_SESSION_ID -or (-not $Host.UI.RawUI)

    # 方法 1: 强制使用 OSC
    if ($ForceOSC -or $isHookEnvironment) {
        Write-Verbose "Hook 环境检测: 使用 OSC 序列"
        return Set-TabTitleOSC -Title $Title
    }

    # 方法 2: 强制使用 RawUI
    if ($ForceRawUI) {
        Write-Verbose "使用强制 RawUI 方法"
        return Set-TabTitleRawUI -Title $Title
    }

    # 方法 3: 默认 - 优先尝试 RawUI（直接运行时更可靠）
    $rawResult = Set-TabTitleRawUI -Title $Title

    if ($rawResult) {
        Write-Verbose "RawUI 设置成功"
        return $true
    }

    # 方法 4: RawUI 失败，回退到 OSC
    Write-Verbose "RawUI 失败，回退到 OSC 序列"
    $oscResult = Set-TabTitleOSC -Title $Title

    return $oscResult
}

function Set-TabTitleWithIcon {
    <#
    .SYNOPSIS
    设置带图标的终端标签标题

    .DESCRIPTION
    在标题前添加图标，增强视觉识别效果
    支持的图标: ⚠️ 📢 🔔 ✅ ❌ 🚀 🛠️ 📝 💡 ⭐

    .PARAMETER Title
    要设置的标题文本

    .PARAMETER Icon
    图标符号（可选）

    .PARAMETER Position
    图标位置（默认: Before）

    .EXAMPLE
    Set-TabTitleWithIcon -Title "需要输入" -Icon "⚠️"
    # 输出: [⚠️] 需要输入

    .EXAMPLE
    Set-TabTitleWithIcon -Title "编译完成" -Icon "✅"
    # 输出: [✅] 编译完成

    .EXAMPLE
    Set-TabTitleWithIcon -Title "terminal-notifier" -Icon "🛠️" -Position After
    # 输出: terminal-notifier [🛠️]
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

        [Parameter(Mandatory=$false)]
        [string]$Icon = "",

        [Parameter(Mandatory=$false)]
        [ValidateSet("Before", "After")]
        [string]$Position = "Before"
    )

    # 构建显示标题
    $displayTitle = if ($Icon) {
        if ($Position -eq "Before") {
            "[$Icon] $Title"
        } else {
            "$Title [$Icon]"
        }
    } else {
        $Title
    }

    # 调用基础函数
    return Set-TabTitle -Title $displayTitle
}

function Set-TabTitleForHook {
    <#
    .SYNOPSIS
    为 Claude Code Hook 场景优化的标题设置函数

    .DESCRIPTION
    专为 Stop Hook 和 Notification Hook 设计
    自动处理项目名称、窗口名称等上下文信息

    .PARAMETER HookType
    Hook 类型: Stop 或 Notification

    .PARAMETER ProjectName
    项目名称

    .PARAMETER WindowName
    自定义窗口名称（可选，来自 ccs 命令）

    .PARAMETER CustomMessage
    自定义消息（可选，覆盖默认消息）

    .EXAMPLE
    Set-TabTitleForHook -HookType "Stop" -ProjectName "terminal-notifier"
    # 输出: [⚠️] 需要输入 - terminal-notifier

    .EXAMPLE
    Set-TabTitleForHook -HookType "Notification" -ProjectName "terminal-notifier" -WindowName "编译测试"
    # 输出: [📢 编译测试] 新通知 - terminal-notifier

    .EXAMPLE
    Set-TabTitleForHook -HookType "Stop" -ProjectName "my-project" -CustomMessage "编译错误"
    # 输出: [⚠️] 编译错误 - my-project
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Stop", "Notification")]
        [string]$HookType,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProjectName,

        [Parameter(Mandatory=$false)]
        [string]$WindowName = "",

        [Parameter(Mandatory=$false)]
        [string]$CustomMessage = ""
    )

    # 确定图标和默认消息
    $icon = switch ($HookType) {
        "Stop" { "⚠️" }
        "Notification" { "📢" }
    }

    $message = if ($CustomMessage) {
        $CustomMessage
    } else {
        switch ($HookType) {
            "Stop" { "需要输入" }
            "Notification" { "新通知" }
        }
    }

    # 构建标题
    # 格式: [图标 窗口名] 消息 - 项目名
    $title = if ($WindowName) {
        "[$icon $WindowName] $message - $ProjectName"
    } else {
        "[$icon] $message - $ProjectName"
    }

    # 设置标题
    return Set-TabTitle -Title $title
}

function Get-CurrentTabTitle {
    <#
    .SYNOPSIS
    获取当前终端标签标题

    .DESCRIPTION
    读取当前终端的标题（仅适用于 RawUI 环境）

    .RETURNS
    String - 当前标题文本

    .NOTES
    注意: 此函数只能读取通过 RawUI 设置的标题
    无法读取通过 OSC 序列设置的跨终端标题
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    try {
        return $Host.UI.RawUI.WindowTitle
    }
    catch {
        Write-Verbose "读取标题失败: $_"
        return ""
    }
}

# ============================================
# 导出函数
# ============================================

Export-ModuleMember -Function @(
    'Set-TabTitle',
    'Set-TabTitleWithIcon',
    'Set-TabTitleForHook',
    'Get-CurrentTabTitle'
)
