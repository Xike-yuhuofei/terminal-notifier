# session-end.ps1
# Claude Code Hook: SessionEnd
# Cleans up when a Claude Code session ends

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
    "OscSender"
)

try {
    # Read hook input from stdin
    $inputJson = [Console]::In.ReadToEnd()
    $hookData = $inputJson | ConvertFrom-Json

    $sessionId = $hookData.session_id
    $cwd = $hookData.cwd

    # Get project name
    $projectName = Split-Path -Leaf $cwd

    # Set final state before cleanup
    Set-CurrentState -State "black" -Reason "Session ended" -ProjectName $projectName

    # 读取并恢复原始标题（ccs 设置的）
    $originalTitle = Get-OriginalTitle -ModuleRoot $ModuleRoot

    if ($originalTitle) {
        # 恢复到原始标题
        $Host.UI.RawUI.WindowTitle = $originalTitle

        # 清理原始标题文件
        Remove-OriginalTitle -ModuleRoot $ModuleRoot
    } else {
        # 回退到默认逻辑
        $title = "[-] Bye - $projectName"
        Set-NotificationVisual -State "default" -Title $title | Out-Null

        # Brief display then reset title
        Start-Sleep -Milliseconds 500
        Reset-TerminalVisual | Out-Null
    }

    # Clean up state file for this session
    Remove-StateFile

    # Clean up old state files from other sessions
    Clear-OldStateFiles -MaxAgeHours 4

    exit 0
}
catch {
    # Don't block session end on errors
    exit 0
}
