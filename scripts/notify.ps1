# notify.ps1
# Terminal Notifier - Command Line Entry Script
# Generic tool library - Works standalone or with Claude Code hooks
#
# Usage:
#   .\notify.ps1 -EventType "working" -Context "Thinking..."
#   .\notify.ps1 -EventType "needs_human" -Context "Awaiting input"
#   .\notify.ps1 -EventType "success" -Context "Done" -Bell $true
#   .\notify.ps1 -EventType "error" -Context "Failed" -Level "Urgent"
#   .\notify.ps1 -EventType "info" -Context "Processing" -ProjectName "MyProject"

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("session_start", "working", "needs_human", "session_end", "error", "success", "warning", "info")]
    [string]$EventType,

    [Parameter(Mandatory=$true)]
    [string]$Context,

    [Parameter(Mandatory=$false)]
    [bool]$Bell = $false,

    [Parameter(Mandatory=$false)]
    [ValidateSet("Silent", "Normal", "Urgent")]
    [string]$Level = "Normal",

    [Parameter(Mandatory=$false)]
    [string]$ProjectName = ""
)

# Determine module path (auto-detect script location)
$scriptDir = $PSScriptRoot
$moduleRoot = Split-Path -Parent $scriptDir

# Import modules (supports both new and legacy paths)
$modulePath = Join-Path $moduleRoot "lib"

# Check if we're being called from Claude Code plugin context
if ($env:CLAUDE_PLUGIN_ROOT -and (Test-Path (Join-Path $env:CLAUDE_PLUGIN_ROOT "lib"))) {
    $modulePath = Join-Path $env:CLAUDE_PLUGIN_ROOT "lib"
}

Import-Module (Join-Path $modulePath "StateManager.psm1") -Force
Import-Module (Join-Path $modulePath "OscSender.psm1") -Force
Import-Module (Join-Path $modulePath "NotificationEnhancements.psm1") -Force -ErrorAction SilentlyContinue

# Debug output helper
function Write-DebugOutput {
    param([string]$Message)
    if ($env:TERMINAL_NOTIFIER_DEBUG -or $env:CLAUDE_NOTIFY_DEBUG) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] $Message" -ForegroundColor DarkGray
    }
}

# Check if needs human attention
function Test-NeedsHuman {
    param([string]$EventType)
    $humanRequiredEvents = @("needs_human", "error")
    return $EventType -in $humanRequiredEvents
}

# Get state color
function Get-StateColor {
    param([string]$EventType)
    $colorMap = @{
        "session_start" = "blue"
        "working"       = "blue"
        "needs_human"   = "red"
        "session_end"   = "black"
        "error"         = "red"
        "success"       = "green"
        "warning"       = "yellow"
        "info"          = "blue"
    }
    return $colorMap[$EventType]
}

# Get state icon based on type and context
function Get-StateIcon {
    param([string]$EventType, [string]$Context)

    # Context-based icons (check message content)
    if ($Context -match "Error|Failed|error|failed") { return "[X]" }
    elseif ($Context -match "Warning|warning") { return "[!]" }
    elseif ($Context -match "Stop|stop") { return "[?]" }
    elseif ($Context -match "Notification|notification") { return "[N]" }
    elseif ($Context -match "Thinking|thinking") { return "[...]" }
    elseif ($Context -match "Running|running") { return "[>]" }
    elseif ($Context -match "Editing|editing") { return "[~]" }
    elseif ($Context -match "Success|Done|done|Complete|complete") { return "[OK]" }

    # Default icons by type
    $iconMap = @{
        "session_start" = "[+]"
        "working"       = "[...]"
        "needs_human"   = "[?]"
        "session_end"   = "[-]"
        "error"         = "[X]"
        "success"       = "[OK]"
        "warning"       = "[!]"
        "info"          = "[i]"
    }

    return $iconMap[$EventType]
}

# Get bell times based on type and level
function Get-BellTimesLocal {
    param([string]$EventType, [string]$Level, [bool]$BellEnabled)

    if ($Level -eq "Silent") {
        return 0
    }

    if ($Level -eq "Urgent") {
        $urgentMap = @{
            "needs_human" = 3
            "error"       = 3
            "success"     = 2
            "warning"     = 2
            "info"        = 1
        }
        return $urgentMap[$EventType]
    }

    if ($BellEnabled) {
        $normalMap = @{
            "needs_human" = 2
            "error"       = 2
            "success"     = 1
            "warning"     = 1
            "info"        = 1
        }
        return $normalMap[$EventType]
    }

    return 0
}

# Main logic
try {
    Write-DebugOutput "Event Type: $EventType"
    Write-DebugOutput "Context: $Context"
    Write-DebugOutput "Bell: $Bell, Level: $Level"

    # Get project name (use parameter, or auto-detect)
    if (-not $ProjectName) {
        $ProjectName = Get-ProjectName
    }

    $needsHuman = Test-NeedsHuman -EventType $EventType
    $stateColor = Get-StateColor -EventType $EventType
    $icon = Get-StateIcon -EventType $EventType -Context $Context

    # Build title and state
    if ($needsHuman -or $EventType -eq "error") {
        $title = "[!] $icon $Context [!]"
        $visualState = "red"
    }
    elseif ($EventType -eq "warning") {
        $title = "[WARN] $icon $Context"
        $visualState = "yellow"
    }
    elseif ($EventType -eq "success") {
        $title = "[OK] $icon $Context"
        $visualState = "green"
    }
    else {
        $title = "$icon $Context"
        $visualState = $stateColor
    }

    # Handle special event types
    switch ($EventType) {
        "session_start" {
            Set-CurrentState -State $visualState -Reason "Session started" -ProjectName $ProjectName
            Clear-OldStateFiles -MaxAgeHours 24
        }

        "session_end" {
            Remove-StateFile
            $title = "[Bye] - $ProjectName"
        }

        "success" {
            Set-CurrentState -State $visualState -Reason $Context -ProjectName $ProjectName
            Set-NotificationVisual -State $visualState -Title $title -ProjectName $ProjectName

            $bellTimes = Get-BellTimesLocal -EventType $EventType -Level $Level -BellEnabled $Bell
            if ($bellTimes -gt 0) { Invoke-TerminalBell -Times $bellTimes }

            Start-Sleep -Seconds 2
            $title = "[Ready] - $ProjectName"
            $visualState = "blue"
            Set-NotificationVisual -State $visualState -Title $title -ProjectName $ProjectName
            Set-CurrentState -State $visualState -Reason "Ready" -ProjectName $ProjectName
            return
        }

        "error" {
            Set-CurrentState -State $visualState -Reason $Context -ProjectName $ProjectName
            Set-NotificationVisual -State $visualState -Title $title -ProjectName $ProjectName
            $bellTimes = Get-BellTimesLocal -EventType $EventType -Level $Level -BellEnabled $Bell
            if ($bellTimes -gt 0) { Invoke-TerminalBell -Times $bellTimes }
            return
        }

        "warning" {
            Set-NotificationVisual -State $visualState -Title $title -ProjectName $ProjectName
            $bellTimes = Get-BellTimesLocal -EventType $EventType -Level $Level -BellEnabled $Bell
            if ($bellTimes -gt 0) { Invoke-TerminalBell -Times $bellTimes }
            Start-Sleep -Seconds 1.5
            $title = "[Ready] - $ProjectName"
            $visualState = "blue"
            Set-NotificationVisual -State $visualState -Title $title -ProjectName $ProjectName
            return
        }

        default {
            Set-CurrentState -State $visualState -Reason $Context -ProjectName $ProjectName
        }
    }

    Set-NotificationVisual -State $visualState -Title $title -ProjectName $ProjectName

    $bellTimes = Get-BellTimesLocal -EventType $EventType -Level $Level -BellEnabled $Bell
    if ($bellTimes -gt 0) { Invoke-TerminalBell -Times $bellTimes }

    Write-DebugOutput "[TerminalNotifier] $EventType | $icon $Context"
}
catch {
    Write-Warning "Notification script failed: $_"
    Write-Warning $_.ScriptStackTrace
    exit 1
}
