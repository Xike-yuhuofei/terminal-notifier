# PersistentTitle.psm1
# 极简UI组件 - 持久化标题栏显示

# Import dependency modules
try {
    Import-Module (Join-Path $PSScriptRoot "OscSender.psm1") -Force -ErrorAction SilentlyContinue
} catch {
    Write-Warning "Failed to import OscSender module: $_"
}

$script:PersistentTitle = ""
$script:PersistentState = ""
$script:TitleUpdateThread = $null
$script:KeepRunning = $false
$script:EnvironmentNameEnabled = $false  # 🔴 是否启用环境名显示

function Set-PersistentTitle {
    <#
    .SYNOPSIS
        设置持久化标题（不会被后续操作覆盖）
    .PARAMETER Title
        要显示的标题文本
    .PARAMETER State
        状态颜色：red, blue, green, yellow, default
    .PARAMETER Duration
        持续时间（秒），0表示永久显示，默认30秒
    .EXAMPLE
        Set-PersistentTitle "[⚠️ 编译测试] 需要输入" -State "red" -Duration 0
        Set-PersistentTitle "[✅ 单元测试] 完成" -State "green" -Duration 10
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,

        [ValidateSet("red", "blue", "green", "yellow", "default")]
        [string]$State = "blue",

        [int]$Duration = 30
    )

    # 保存到脚本变量
    $script:PersistentTitle = $Title
    $script:PersistentState = $State

    # 🔴 添加环境前缀（GLM 或 CCClub）
    if ($env:CLAUDE_ENV_NAME) {
        $script:PersistentTitle = "[$($env:CLAUDE_ENV_NAME)] $Title"
    }

    # 启动后台更新线程
    if ($null -eq $script:TitleUpdateThread -or $script:TitleUpdateThread.IsCompleted) {
        $script:KeepRunning = $true

        # 🔴 修复：明确指定 Action 类型，避免重载歧义
        # 保存 Duration 到脚本变量以便闭包访问
        $script:CurrentDuration = $Duration

        $action = [System.Action]{
            Start-PersistentTitleUpdater -Duration $script:CurrentDuration
        }.GetNewClosure()

        $script:TitleUpdateThread = [System.Threading.Tasks.Task]::Run($action)
    }
}

function Start-PersistentTitleUpdater {
    param([int]$Duration)

    $startTime = Get-Date
    $endTime = if ($Duration -gt 0) { $startTime.AddSeconds($Duration) } else { [DateTime]::MaxValue }

    while ($script:KeepRunning -and (Get-Date) -lt $endTime) {
        # 持续刷新标题（防止被覆盖）
        if ($script:PersistentTitle) {
            # 使用健壮的标题设置方法（支持Git Bash和其他环境）
            $titleSuccess = Set-TermTitleLegacy -Title $script:PersistentTitle

            # 如果支持OSC序列，设置标签页颜色
            # 使用Test-OscSupport而不是直接检查环境变量
            if (Test-OscSupport) {
                $colorMap = @{
                    "red"    = "red"
                    "yellow" = "yellow"
                    "green"  = "green"
                    "blue"   = "blue"
                    "default" = "default"
                }
                $tabColor = $colorMap[$script:PersistentState]
                # 使用Send-OscTabColor而不是直接[Console]::Write
                $colorSuccess = Send-OscTabColor -Color $tabColor -Blink ($script:PersistentState -eq "red")
            }
        } elseif ($script:EnvironmentNameEnabled -and $env:CLAUDE_ENV_NAME) {
            # 🔴 启用了环境名显示时，显示 [GLM] 项目名
            $projectName = Get-ProjectName
            $envTitle = "[$($env:CLAUDE_ENV_NAME)] $projectName"
            Set-TermTitleLegacy -Title $envTitle | Out-Null
        }

        Start-Sleep -Milliseconds 500  # 每0.5秒刷新一次
    }

    # 时间到了，清理
    if ((Get-Date) -ge $endTime) {
        Clear-PersistentTitle
    }
}

function Clear-PersistentTitle {
    <#
    .SYNOPSIS
        清除持久化标题，恢复默认显示
    .EXAMPLE
        Clear-PersistentTitle
    #>
    $script:KeepRunning = $false
    $script:PersistentTitle = ""
    $script:PersistentState = ""

    # 恢复默认标题
    $currentDir = Split-Path -Leaf (Get-Location).Path
    $defaultTitle = "[Ready] - $currentDir"
    Set-TermTitleLegacy -Title $defaultTitle | Out-Null

    # 恢复默认标签页颜色（如果支持OSC）
    if (Test-OscSupport) {
        Send-OscTabColor -Color "default" -Blink $false | Out-Null
    }
}

function Enable-EnvironmentNameDisplay {
    <#
    .SYNOPSIS
        启用环境名显示（GLM/CCClub）在终端标题中
    .DESCRIPTION
        启动后台线程，持续显示环境名和项目名
    .EXAMPLE
        Enable-EnvironmentNameDisplay
    #>
    $script:EnvironmentNameEnabled = $true

    # 启动后台更新线程
    if ($null -eq $script:TitleUpdateThread -or $script:TitleUpdateThread.IsCompleted) {
        $script:KeepRunning = $true

        $action = [System.Action]{
            Start-PersistentTitleUpdater -Duration 0  # 0 = 永久运行
        }.GetNewClosure()

        $script:TitleUpdateThread = [System.Threading.Tasks.Task]::Run($action)
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Set-PersistentTitle',
    'Show-TitleNotification',
    'Clear-PersistentTitle',
    'Enable-EnvironmentNameDisplay'
)

function Get-PersistentTitle {
    <#
    .SYNOPSIS
        获取当前持久化标题
    .OUTPUTS
        System.String. 当前的持久化标题
    .EXAMPLE
        $title = Get-PersistentTitle
    #>
    return $script:PersistentTitle
}

function Show-TitleNotification {
    <#
    .SYNOPSIS
        显示标题通知（简化版，带自动清理）
    .PARAMETER Title
        标题文本
    .PARAMETER Type
        通知类型：Stop, Notification, Success
    .PARAMETER AutoClear
        是否自动清除，默认true
    .PARAMETER Duration
        显示时长（秒），默认Stop不自动清除，Notification显示5秒
    .EXAMPLE
        Show-TitleNotification -Title "编译测试" -Type "Stop"
        Show-TitleNotification -Title "单元测试" -Type "Notification" -Duration 10
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,

        [ValidateSet("Stop", "Notification", "Success")]
        [string]$Type = "Notification",

        [bool]$AutoClear = $true,

        [int]$Duration = 0
    )

    # 根据类型确定状态和时长
    $state = switch ($Type) {
        "Stop"       { "red"; break }
        "Notification" { "yellow"; break }
        "Success"    { "green"; break }
    }

    # 默认时长
    if ($Duration -eq 0) {
        $Duration = switch ($Type) {
            "Stop"       { 0 }  # Stop事件：不自动清除
            "Notification" { 5 }  # Notification事件：5秒
            "Success"    { 10 }  # Success事件：10秒
            default      { 5 }
        }
    }

    # 如果是Stop事件且不自动清除，使用无限时长
    if ($Type -eq "Stop" -and -not $AutoClear) {
        $Duration = 0
    }

    Set-PersistentTitle -Title $Title -State $state -Duration $Duration
}

Export-ModuleMember -Function @(
    'Set-PersistentTitle',
    'Clear-PersistentTitle',
    'Get-PersistentTitle',
    'Show-TitleNotification'
)
