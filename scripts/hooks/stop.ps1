# stop.ps1
# Claude Code Hook: Stop
# 在 Claude 停止等待用户输入时触发

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
