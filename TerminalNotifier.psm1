# TerminalNotifier.psm1
# Terminal Notifier - Main Module Entry Point
# Generic terminal notification library for PowerShell
#
# Usage:
#   Import-Module TerminalNotifier
#   Send-Notification -Type "success" -Message "Build complete"
#   Send-Notification -Type "error" -Message "Test failed" -Bell $true
#
# Or use individual modules:
#   Import-Module TerminalNotifier
#   $task = Start-TrackedTask "Building"
#   $task | Complete-TrackedTask -Success $true

$script:ModuleRoot = $PSScriptRoot
$script:Initialized = $false

function Initialize-TerminalNotifier {
    <#
    .SYNOPSIS
        Initialize the Terminal Notifier module with custom settings
    .PARAMETER StateDirectory
        Directory to store state files (default: module/.states)
    .PARAMETER ProjectName
        Project name to display in titles (default: current directory name)
    .PARAMETER SessionId
        Custom session ID (default: auto-generated GUID)
    .PARAMETER Debug
        Enable debug output (default: false, or from env var)
    .EXAMPLE
        Initialize-TerminalNotifier -ProjectName "MyApp" -Debug $true
        Initialize-TerminalNotifier -StateDirectory "C:\temp\states"
    #>
    param(
        [string]$StateDirectory = "",
        [string]$ProjectName = "",
        [string]$SessionId = "",
        [bool]$Debug = $false
    )

    # Initialize StateManager
    $result = Initialize-StateManager -StateDirectory $StateDirectory -ProjectName $ProjectName -SessionId $SessionId -Debug $Debug

    # Store original title for later restoration
    Set-OriginalTitle -Title $Host.UI.RawUI.WindowTitle

    $script:Initialized = $true

    return $result
}

function Send-Notification {
    <#
    .SYNOPSIS
        Send a terminal notification with visual effects
    .PARAMETER Type
        Notification type: session_start, working, needs_human, session_end, error, success, warning, info
    .PARAMETER Message
        Notification message/context
    .PARAMETER Bell
        Whether to ring the terminal bell (default: false)
    .PARAMETER Level
        Notification level: Silent, Normal, Urgent (default: Normal)
    .PARAMETER ProjectName
        Optional project name to display (overrides default)
    .EXAMPLE
        Send-Notification -Type "success" -Message "Build complete"
        Send-Notification -Type "error" -Message "Test failed" -Bell $true
        Send-Notification -Type "needs_human" -Message "Awaiting input" -Level "Urgent"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("session_start", "working", "needs_human", "session_end", "error", "success", "warning", "info")]
        [string]$Type,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [bool]$Bell = $false,

        [ValidateSet("Silent", "Normal", "Urgent")]
        [string]$Level = "Normal",

        [string]$ProjectName = ""
    )

    # Auto-initialize if not done
    if (-not $script:Initialized) {
        Initialize-TerminalNotifier | Out-Null
    }

    # Get project name if not provided
    if (-not $ProjectName) {
        $ProjectName = Get-ProjectName
    }

    # Determine state color
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
    $stateColor = $colorMap[$Type]

    # Determine if needs human attention
    $needsHuman = ($Type -in @("needs_human", "error"))

    # Get state icon based on type and message content
    $icon = Get-NotificationIcon -Type $Type -Message $Message

    # Build title
    if ($needsHuman) {
        $title = "[!] $icon $Message [!]"
        $visualState = "red"
    }
    elseif ($Type -eq "warning") {
        $title = "[WARN] $icon $Message"
        $visualState = "yellow"
    }
    elseif ($Type -eq "success") {
        $title = "[OK] $icon $Message"
        $visualState = "green"
    }
    else {
        $title = "$icon $Message"
        $visualState = $stateColor
    }

    # Get bell times based on type and level
    $bellTimes = Get-BellTimes -Type $Type -Level $Level -Bell $Bell

    # Handle special cases
    switch ($Type) {
        "session_start" {
            Set-CurrentState -State $visualState -Reason "Session started" -ProjectName $ProjectName
            Clear-OldStateFiles -MaxAgeHours 24
        }

        "session_end" {
            Remove-StateFile
            $title = "[Bye] - $ProjectName"
        }

        "success" {
            Set-CurrentState -State $visualState -Reason $Message -ProjectName $ProjectName
            Set-NotificationVisual -State $visualState -Title $title -ProjectName $ProjectName

            if ($bellTimes -gt 0) { Invoke-TerminalBell -Times $bellTimes }

            Start-Sleep -Seconds 2
            $title = "[Ready] - $ProjectName"
            $visualState = "blue"
            Set-NotificationVisual -State $visualState -Title $title -ProjectName $ProjectName
            Set-CurrentState -State $visualState -Reason "Ready" -ProjectName $ProjectName
            return
        }

        "error" {
            Set-CurrentState -State $visualState -Reason $Message -ProjectName $ProjectName
            Set-NotificationVisual -State $visualState -Title $title -ProjectName $ProjectName
            if ($bellTimes -gt 0) { Invoke-TerminalBell -Times $bellTimes }
            return
        }

        "warning" {
            Set-NotificationVisual -State $visualState -Title $title -ProjectName $ProjectName
            if ($bellTimes -gt 0) { Invoke-TerminalBell -Times $bellTimes }
            Start-Sleep -Seconds 1.5
            $title = "[Ready] - $ProjectName"
            $visualState = "blue"
            Set-NotificationVisual -State $visualState -Title $title -ProjectName $ProjectName
            return
        }

        default {
            Set-CurrentState -State $visualState -Reason $Message -ProjectName $ProjectName
        }
    }

    Set-NotificationVisual -State $visualState -Title $title -ProjectName $ProjectName

    if ($bellTimes -gt 0) { Invoke-TerminalBell -Times $bellTimes }

    # Debug output
    if (Test-DebugEnabled) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [TerminalNotifier] $Type | $icon $Message" -ForegroundColor DarkGray
    }
}

function Get-NotificationIcon {
    <#
    .SYNOPSIS
        Get appropriate icon for notification type
    #>
    param(
        [string]$Type,
        [string]$Message
    )

    # Check message content for context clues
    if ($Message -match "Error|Failed|error|failed") { return "[X]" }
    elseif ($Message -match "Warning|warning") { return "[!]" }
    elseif ($Message -match "Stop|stop") { return "[?]" }
    elseif ($Message -match "Thinking|thinking") { return "[...]" }
    elseif ($Message -match "Running|running") { return "[>]" }
    elseif ($Message -match "Editing|editing") { return "[~]" }
    elseif ($Message -match "Success|Done|done|Complete|complete") { return "[OK]" }

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

    return $iconMap[$Type]
}

function Get-BellTimes {
    <#
    .SYNOPSIS
        Get number of bell rings based on type and level
    #>
    param(
        [string]$Type,
        [string]$Level,
        [bool]$Bell
    )

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
        return $urgentMap[$Type]
    }

    if ($Bell) {
        $normalMap = @{
            "needs_human" = 2
            "error"       = 2
            "success"     = 1
            "warning"     = 1
            "info"        = 1
        }
        return $normalMap[$Type]
    }

    return 0
}

# Import nested modules explicitly
$libPath = Join-Path $script:ModuleRoot "lib"
Import-Module (Join-Path $libPath "StateManager.psm1") -Force
Import-Module (Join-Path $libPath "OscSender.psm1") -Force
Import-Module (Join-Path $libPath "NotificationEnhancements.psm1") -Force

# Aliases for convenience
Set-Alias -Name tn-notify -Value Send-Notification
Set-Alias -Name tn-bell -Value Invoke-TerminalBell
Set-Alias -Name tn-title -Value Send-OscTitle

# Export all functions and aliases
Export-ModuleMember -Function @(
    # Main module functions
    'Initialize-TerminalNotifier',
    'Send-Notification',
    'Get-NotificationIcon',
    'Get-BellTimes',

    # StateManager
    'Initialize-StateManager',
    'Get-SessionId',
    'Get-StateFilePath',
    'Get-CurrentState',
    'Set-CurrentState',
    'Remove-StateFile',
    'Clear-OldStateFiles',
    'Get-ProjectName',
    'Get-StateDirectory',
    'Test-DebugEnabled',

    # OscSender
    'Send-OscTitle',
    'Send-OscTabColor',
    'Set-TermTitleLegacy',
    'Test-OscSupport',
    'Set-NotificationVisual',
    'Reset-TerminalVisual',
    'Send-AnsiReset',
    'Send-AnsiBold',
    'Send-AnsiBlink',

    # NotificationEnhancements
    'Invoke-TerminalBell',
    'Invoke-TitleFlash',
    'Start-TrackedTask',
    'Complete-TrackedTask',
    'Update-TaskProgress',
    'Get-ActiveTasks',
    'Format-Duration',
    'Restore-OriginalTitle',
    'Set-OriginalTitle',
    'Get-OriginalTitle'
) -Alias @(
    'tn-notify',
    'tn-bell',
    'tn-title'
)
