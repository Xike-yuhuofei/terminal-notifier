# stop.ps1
# Claude Code Hook: Stop
# Notifies user when Claude stops working and needs attention

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
Import-Module (Join-Path $LibPath "NotificationEnhancements.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $LibPath "ToastNotifier.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $LibPath "PersistentTitle.psm1") -Force -ErrorAction SilentlyContinue

try {
    # Read hook input from stdin
    $inputJson = [Console]::In.ReadToEnd()
    $hookData = $inputJson | ConvertFrom-Json

    $sessionId = $hookData.session_id
    $cwd = $hookData.cwd
    $stopHookActive = $hookData.stop_hook_active  # true if already in continue loop

    # Get project name
    $projectName = Split-Path -Leaf $cwd

    # Update state to "needs human attention"
    Set-CurrentState -State "red" -Reason "Awaiting input" -ProjectName $projectName

    # Get custom window name if set
    $windowName = ""
    try {
        $windowName = Get-WindowDisplayName
    }
    catch {
        # Fallback to project name
        $windowName = $projectName
    }

    # 显示持久化标题通知（极简UI组件）
    $displayTitle = if ($windowName -and $windowName -ne $projectName) {
        "[⚠️ $windowName] 需要输入"
    } else {
        "[⚠️] 需要输入 - $projectName"
    }

    # Write to persistent state file (for UserPromptSubmit Hook to clear)
    try {
        $stateDir = Join-Path $ModuleRoot ".states"
        if (-not (Test-Path $stateDir)) {
            New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
        }

        $titleFile = Join-Path $stateDir "stop-title.txt"
        $titleData = @{
            title = $displayTitle
            projectName = $projectName
            windowName = $windowName
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json -Compress

        $titleData | Out-File -FilePath $titleFile -Encoding UTF8 -Force
    }
    catch {
        # State file write failure should not block Hook execution
    }

    Show-TitleNotification -Title $displayTitle -Type "Stop" -AutoClear $false

    # Legacy: Set visual notification for compatibility
    $title = "[?] Input needed - $projectName"
    Set-NotificationVisual -State "red" -Title $title | Out-Null

    # Ring bell to get attention (1 time for stop event)
    Invoke-TerminalBell -Times 1 -SoundType 'Asterisk'

    # Send Windows Toast notification
    try {
        $windowName = Get-WindowDisplayName
        Send-StopToast -WindowName $windowName -ProjectName $projectName
    }
    catch {
        # Toast failure should not block Hook execution
    }

    # Optional: Flash title for extra visibility
    # Invoke-TitleFlash -Title $title -Times 2 -DelayMs 300

    exit 0
}
catch {
    # Don't interfere with Claude's stop behavior on errors
    exit 0
}
