# session-start.ps1
# Claude Code Hook: SessionStart
# Initializes terminal notifier when a session starts

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
    "StateManager",
    "OscSender",
    "PersistentTitle",
    "TabTitleManager"
)

try {
    # Read hook input from stdin
    $inputJson = [Console]::In.ReadToEnd()
    $hookData = $inputJson | ConvertFrom-Json

    $sessionId = $hookData.session_id
    $cwd = $hookData.cwd
    $source = $hookData.source  # "startup", "resume", "clear", "compact"

    # Get project name from working directory
    $projectName = Split-Path -Leaf $cwd

    # Initialize state manager with session info
    Initialize-StateManager -SessionId $sessionId -ProjectName $projectName | Out-Null

    # 设置标题为 [ Running ] 窗口名（第一次标题修改）
    $windowName = Get-WindowDisplayName
    $runningTitle = "[ Running ] $windowName"
    
    # === 双重标题设置策略（参考Notification Hook）===
    try {
        # 方法1: 使用OSC转义序列
        Set-TabTitle -Title $runningTitle
        
        # 方法2: 直接设置RawUI标题
        $Host.UI.RawUI.WindowTitle = $runningTitle
        
        # 方法3: 输出OSC序列（备用方法）
        $ESC = [char]27
        $BEL = [char]7
        Write-Host "$ESC]0;$runningTitle$BEL" -NoNewline
    }
    catch {
        # 忽略标题设置失败
    }
    
    # 记录状态到 JSON（用于多窗口协调）
    switch ($source) {
        "startup" {
            Set-CurrentState -State "blue" -Reason "Session started" -ProjectName $projectName
        }
        "resume" {
            Set-CurrentState -State "blue" -Reason "Session resumed" -ProjectName $projectName
        }
        "compact" {
            Set-CurrentState -State "blue" -Reason "Context compacted" -ProjectName $projectName
        }
        default {
            Set-CurrentState -State "blue" -Reason "Session active" -ProjectName $projectName
        }
    }

    # Clean up old state files
    Clear-OldStateFiles -MaxAgeHours 4

    # 保存 ccs 设置的原始标题（供 Notification 和 SessionEnd 使用）
    if ($env:CLAUDE_WINDOW_NAME) {
        Set-OriginalTitle -ModuleRoot $ModuleRoot -Title $env:CLAUDE_WINDOW_NAME
    } else {
        $currentTitle = $Host.UI.RawUI.WindowTitle
        Set-OriginalTitle -ModuleRoot $ModuleRoot -Title $currentTitle
    }

    # 保存当前标题到文件，供其他hooks使用
    $stateDir = Join-Path $ModuleRoot ".states"
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }
    $currentTitleFile = Join-Path $stateDir "current-title.txt"
    $runningTitle | Out-File -FilePath $currentTitleFile -Force -Encoding UTF8

    # Output result for Claude Code
    $output = @{
        success = $true
        source = $source
    } | ConvertTo-Json -Compress

    Write-Output $output
    exit 0
}
catch {
    # Don't block session start on errors
    exit 0
}
