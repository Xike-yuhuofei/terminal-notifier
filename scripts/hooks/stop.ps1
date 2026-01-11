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

# Early debug log - before any module import
$earlyDebugLog = Join-Path $ModuleRoot ".states/hook-debug.log"
$earlyStateDir = Join-Path $ModuleRoot ".states"
if (-not (Test-Path $earlyStateDir)) {
    New-Item -ItemType Directory -Path $earlyStateDir -Force | Out-Null
}
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
"[$ts] Stop Hook: Script started, LibPath=$LibPath" | Out-File -FilePath $earlyDebugLog -Append -Encoding UTF8

# Import HookBase module first
$hookBasePath = Join-Path $LibPath "HookBase.psm1"
"[$ts] Stop Hook: Importing HookBase from $hookBasePath" | Out-File -FilePath $earlyDebugLog -Append -Encoding UTF8
Import-Module $hookBasePath -Force -Global -ErrorAction SilentlyContinue

# Import other required modules DIRECTLY (not via Import-HookModules to avoid scope issues)
$modulesToImport = @("NotificationEnhancements", "ToastNotifier", "PersistentTitle", "StateManager", "TabTitleManager")
foreach ($mod in $modulesToImport) {
    $modPath = Join-Path $LibPath "$mod.psm1"
    if (Test-Path $modPath) {
        Import-Module $modPath -Force -Global -ErrorAction SilentlyContinue
    }
}
"[$ts] Stop Hook: Modules imported, Invoke-TerminalBell exists: $(Get-Command Invoke-TerminalBell -ErrorAction SilentlyContinue | Out-String)" | Out-File -FilePath $earlyDebugLog -Append -Encoding UTF8

try {
    # === DEBUG LOGGING START ===
    $stateDir = Join-Path $ModuleRoot ".states"
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }
    $debugLog = Join-Path $stateDir "hook-debug.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    "[$timestamp] === Stop Hook START ===" | Out-File -FilePath $debugLog -Append -Encoding UTF8
    "[$timestamp] ModuleRoot: $ModuleRoot" | Out-File -FilePath $debugLog -Append -Encoding UTF8
    # === DEBUG LOGGING END ===

    # Initialize environment
    $inputJson = [Console]::In.ReadToEnd()

    # DEBUG: Log input
    "[$timestamp] Input JSON: $inputJson" | Out-File -FilePath $debugLog -Append -Encoding UTF8

    $hookData = $inputJson | ConvertFrom-Json
    $cwd = $hookData.cwd
    $projectName = Split-Path -Leaf $cwd

    # DEBUG: Log parsed data
    "[$timestamp] CWD: $cwd, Project: $projectName" | Out-File -FilePath $debugLog -Append -Encoding UTF8

    # Get window name with fallback
    $windowName = Get-WindowNameWithFallback -ProjectName $projectName -ModuleRoot $ModuleRoot

    # DEBUG: Log window name
    "[$timestamp] WindowName: $windowName" | Out-File -FilePath $debugLog -Append -Encoding UTF8

    # Build title
    $title = Build-StopTitle -WindowName $windowName -ProjectName $projectName

    # DEBUG: Log title
    "[$timestamp] Title: $title" | Out-File -FilePath $debugLog -Append -Encoding UTF8

    # Set persistent title
    try {
        Set-PersistentTitle -Title $title -State "red" -Duration 0
    }
    catch {
        # Title setting failure should not block Hook execution
    }

    # Play sound
    Invoke-TerminalBell -Times 2 -SoundType 'Exclamation'

    # DEBUG: Log bell
    "[$timestamp] Bell played" | Out-File -FilePath $debugLog -Append -Encoding UTF8

    # Send toast notification
    Invoke-ToastWithFallback -ScriptBlock {
        Send-StopToast -WindowName $windowName -ProjectName $projectName
    }

    # DEBUG: Log toast and end
    "[$timestamp] Toast sent" | Out-File -FilePath $debugLog -Append -Encoding UTF8
    "[$timestamp] === Stop Hook END ===" | Out-File -FilePath $debugLog -Append -Encoding UTF8

    exit 0
}
catch {
    # DEBUG: Log error
    $errorLog = Join-Path $ModuleRoot ".states/hook-debug.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    "[$timestamp] STOP ERROR: $($_.Exception.Message)" | Out-File -FilePath $errorLog -Append -Encoding UTF8
    "[$timestamp] Stack: $($_.ScriptStackTrace)" | Out-File -FilePath $errorLog -Append -Encoding UTF8
    # Don't interfere with Claude's stop behavior
    exit 0
}
