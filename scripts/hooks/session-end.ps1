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

# Import modules
Import-Module (Join-Path $LibPath "StateManager.psm1") -Force
Import-Module (Join-Path $LibPath "OscSender.psm1") -Force

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

    # Reset visual to default
    $title = "[-] Bye - $projectName"
    Set-NotificationVisual -State "default" -Title $title | Out-Null

    # Brief display then reset title
    Start-Sleep -Milliseconds 500
    Reset-TerminalVisual | Out-Null

    # Clean up state file for this session
    Remove-StateFile

    exit 0
}
catch {
    # Don't block session end on errors
    exit 0
}
