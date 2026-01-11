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

# Import modules
Import-Module (Join-Path $LibPath "StateManager.psm1") -Force
Import-Module (Join-Path $LibPath "OscSender.psm1") -Force
Import-Module (Join-Path $LibPath "PersistentTitle.psm1") -Force -ErrorAction SilentlyContinue

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

    # SessionStart 静默模式：不更新终端标题和标签色
    # 仅记录状态到 JSON（用于多窗口协调）
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
    $stateDir = Join-Path $ModuleRoot ".states"
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }

    $originalTitleFile = Join-Path $stateDir "original-title.txt"

    # 优先保存 CLAUDE_WINDOW_NAME，否则保存当前标题
    if ($env:CLAUDE_WINDOW_NAME) {
        $env:CLAUDE_WINDOW_NAME | Out-File -FilePath $originalTitleFile -Encoding UTF8 -Force

        # 设置会话开始标题（显示自定义标题）
        $sessionTitle = "[$($env:CLAUDE_WINDOW_NAME)] Ready - $projectName"
        Set-PersistentTitle -Title $sessionTitle -State "blue" -Duration 0
    } else {
        $currentTitle = $Host.UI.RawUI.WindowTitle
        $currentTitle | Out-File -FilePath $originalTitleFile -Encoding UTF8 -Force

        # 设置默认会话开始标题
        $sessionTitle = "[Ready] - $projectName"
        Set-PersistentTitle -Title $sessionTitle -State "blue" -Duration 0
    }

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
