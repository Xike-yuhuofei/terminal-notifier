# StateManager.psm1
# Terminal Notifier - State Management Module
# Generic Tool Library - No external dependencies required

# Module-level state storage
$script:ModuleRoot = $PSScriptRoot | Split-Path -Parent
$script:SessionId = $null
$script:StateDir = $null
$script:ProjectName = $null
$script:DebugEnabled = $false

function Initialize-StateManager {
    <#
    .SYNOPSIS
        Initialize the state manager
    .PARAMETER StateDirectory
        State file storage directory, defaults to .states under module directory
    .PARAMETER SessionId
        Session ID, defaults to auto-generated GUID
    .PARAMETER ProjectName
        Project name, defaults to current directory name
    .PARAMETER Debug
        Enable debug output
    .EXAMPLE
        Initialize-StateManager -StateDirectory "C:\temp\states"
        Initialize-StateManager -ProjectName "MyProject" -Debug $true
    #>
    param(
        [string]$StateDirectory = "",
        [string]$SessionId = "",
        [string]$ProjectName = "",
        [bool]$Debug = $false
    )

    # Set debug mode (priority: parameter > env var)
    if ($Debug) {
        $script:DebugEnabled = $true
    }
    elseif ($env:TERMINAL_NOTIFIER_DEBUG -or $env:CLAUDE_NOTIFY_DEBUG) {
        $script:DebugEnabled = $true
    }

    # Set state directory (priority: parameter > env var > legacy var > default)
    if ($StateDirectory) {
        $script:StateDir = $StateDirectory
    }
    elseif ($env:TERMINAL_NOTIFIER_STATE_DIR) {
        $script:StateDir = $env:TERMINAL_NOTIFIER_STATE_DIR
    }
    elseif ($env:CLAUDE_PLUGIN_ROOT) {
        # Backward compatibility
        $script:StateDir = Join-Path $env:CLAUDE_PLUGIN_ROOT ".states"
    }
    else {
        $script:StateDir = Join-Path $script:ModuleRoot ".states"
    }

    # Set session ID (priority: parameter > env var > legacy var > auto-generate)
    if ($SessionId) {
        $script:SessionId = $SessionId
    }
    elseif ($env:TERMINAL_NOTIFIER_SESSION_ID) {
        $script:SessionId = $env:TERMINAL_NOTIFIER_SESSION_ID
    }
    elseif ($env:CLAUDE_SESSION_ID) {
        # Backward compatibility
        $script:SessionId = $env:CLAUDE_SESSION_ID
    }
    else {
        $script:SessionId = [Guid]::NewGuid().ToString()
    }

    # Set project name (priority: parameter > env var > legacy var > current dir)
    if ($ProjectName) {
        $script:ProjectName = $ProjectName
    }
    elseif ($env:TERMINAL_NOTIFIER_PROJECT) {
        $script:ProjectName = $env:TERMINAL_NOTIFIER_PROJECT
    }
    elseif ($env:CLAUDE_PROJECT_DIR) {
        # Backward compatibility
        $script:ProjectName = Split-Path -Leaf $env:CLAUDE_PROJECT_DIR
    }
    else {
        $script:ProjectName = Split-Path -Leaf (Get-Location).Path
    }

    # Ensure state directory exists
    if (-not (Test-Path $script:StateDir)) {
        New-Item -ItemType Directory -Path $script:StateDir -Force | Out-Null
    }

    return @{
        StateDirectory = $script:StateDir
        SessionId = $script:SessionId
        ProjectName = $script:ProjectName
        Debug = $script:DebugEnabled
    }
}

function Get-SessionId {
    <#
    .SYNOPSIS
        Get the current session's unique ID
    .OUTPUTS
        System.String. Session ID (GUID format)
    #>
    if (-not $script:SessionId) {
        Initialize-StateManager | Out-Null
    }
    return $script:SessionId
}

function Get-StateFilePath {
    <#
    .SYNOPSIS
        Get the full path to the state file
    .OUTPUTS
        System.String. State file path
    #>
    if (-not $script:StateDir) {
        Initialize-StateManager | Out-Null
    }

    $sessionId = Get-SessionId
    return Join-Path $script:StateDir "notification-state-$sessionId.json"
}

function Get-CurrentState {
    <#
    .SYNOPSIS
        Read the current state file
    .OUTPUTS
        PSCustomObject. State object, or $null if file doesn't exist
    #>
    $stateFile = Get-StateFilePath

    if (-not (Test-Path $stateFile)) {
        return $null
    }

    try {
        $content = Get-Content $stateFile -Raw -ErrorAction Stop
        return $content | ConvertFrom-Json
    }
    catch {
        Write-Warning "Unable to read state file: $_"
        return $null
    }
}

function Set-CurrentState {
    <#
    .SYNOPSIS
        Write current state to the state file
    .PARAMETER State
        State type: "red", "blue", "green", "yellow", "white", "black"
    .PARAMETER Reason
        State reason description
    .PARAMETER ProjectName
        Project name (optional, overrides default)
    .EXAMPLE
        Set-CurrentState -State "red" -Reason "Error occurred"
        Set-CurrentState -State "green" -Reason "Task completed" -ProjectName "MyApp"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("red", "blue", "green", "yellow", "white", "black")]
        [string]$State,

        [Parameter(Mandatory=$false)]
        [string]$Reason,

        [Parameter(Mandatory=$false)]
        [string]$ProjectName
    )

    $stateFile = Get-StateFilePath
    $sessionId = Get-SessionId

    # Read existing state or create new
    $currentState = Get-CurrentState
    if (-not $currentState) {
        $currentState = @{
            sessionId = $sessionId
            windowId = "unknown"
            currentState = "blue"
            stateReason = "Initialized"
            projectName = (Get-ProjectName)
            startTime = (Get-Date -Format "o")
            lastUpdate = (Get-Date -Format "o")
            redTriggerCount = 0
            totalDuration = 0
        }
    }

    # Update state
    $currentState.currentState = $State
    $currentState.lastUpdate = (Get-Date -Format "o")
    if ($Reason) {
        $currentState.stateReason = $Reason
    }
    if ($ProjectName) {
        $currentState.projectName = $ProjectName
    }
    if ($State -eq "red") {
        $currentState.redTriggerCount++
    }

    # Calculate duration (seconds)
    $startTime = [DateTime]::Parse($currentState.startTime)
    $duration = ([DateTime]::Now - $startTime).TotalSeconds
    $currentState.totalDuration = [int]$duration

    # Write file (with retry mechanism)
    $maxRetries = 3
    $retryDelay = 100 # milliseconds

    for ($i = 0; $i -lt $maxRetries; $i++) {
        try {
            $currentState | ConvertTo-Json -Depth 10 | Out-File -FilePath $stateFile -Force -ErrorAction Stop
            return $true
        }
        catch {
            if ($i -eq ($maxRetries - 1)) {
                Write-Warning "Unable to write state file (retried $maxRetries times): $_"
                return $false
            }
            Start-Sleep -Milliseconds $retryDelay
        }
    }

    return $false
}

function Remove-StateFile {
    <#
    .SYNOPSIS
        Delete the current session's state file
    .OUTPUTS
        System.Boolean. Returns $true on success
    #>
    $stateFile = Get-StateFilePath

    if (Test-Path $stateFile) {
        try {
            Remove-Item -Path $stateFile -Force -ErrorAction Stop
            return $true
        }
        catch {
            Write-Warning "Unable to delete state file: $_"
            return $false
        }
    }

    return $true
}

function Clear-OldStateFiles {
    <#
    .SYNOPSIS
        Clean up state files older than specified time
    .PARAMETER MaxAgeHours
        Maximum retention time (hours), default 24 hours
    .EXAMPLE
        Clear-OldStateFiles -MaxAgeHours 48
    #>
    param(
        [int]$MaxAgeHours = 24
    )

    if (-not $script:StateDir) {
        Initialize-StateManager | Out-Null
    }

    if (-not (Test-Path $script:StateDir)) {
        return
    }

    $cutoffTime = (Get-Date).AddHours(-$MaxAgeHours)
    $removedCount = 0

    Get-ChildItem -Path $script:StateDir -Filter "notification-state-*.json" | ForEach-Object {
        if ($_.LastWriteTime -lt $cutoffTime) {
            try {
                Remove-Item -Path $_.FullName -Force -ErrorAction Stop
                $removedCount++
            }
            catch {
                Write-Warning "Unable to delete old state file $($_.FullName): $_"
            }
        }
    }

    if ($removedCount -gt 0 -and $script:DebugEnabled) {
        Write-Host "Cleaned up $removedCount old state files" -ForegroundColor Yellow
    }
}

function Get-ProjectName {
    <#
    .SYNOPSIS
        Get the current project name
    .OUTPUTS
        System.String. Project name
    #>
    if ($script:ProjectName) {
        return $script:ProjectName
    }

    # Check env vars for backward compatibility
    if ($env:TERMINAL_NOTIFIER_PROJECT) {
        return $env:TERMINAL_NOTIFIER_PROJECT
    }
    if ($env:CLAUDE_PROJECT_DIR) {
        return Split-Path -Leaf $env:CLAUDE_PROJECT_DIR
    }

    return Split-Path -Leaf (Get-Location).Path
}


function Get-WindowDisplayName {
    <#
    .SYNOPSIS
        Get display name for current window/tab
    .DESCRIPTION
        Priority: CLAUDE_WINDOW_NAME > ProjectName > Session ID (first 8 chars)
    .OUTPUTS
        System.String. Window display name
    .EXAMPLE
        $name = Get-WindowDisplayName
        # Output: "编译测试" (if CLAUDE_WINDOW_NAME is set)
        # Output: "Backend_CPP" (if project name available)
        # Output: "窗口-a1b2c3d4" (fallback to session ID)
    #>

    # Priority 1: Explicit window name from environment variable
    if ($env:CLAUDE_WINDOW_NAME) {
        return $env:CLAUDE_WINDOW_NAME
    }

    # Priority 2: Project name
    $projectName = Get-ProjectName
    if ($projectName -and $projectName -ne "") {
        return $projectName
    }

    # Priority 3: Session ID (first 8 chars)
    $sessionId = Get-SessionId
    if ($sessionId -and $sessionId.Length -ge 8) {
        return "窗口-" + $sessionId.Substring(0, 8)
    }

    # Fallback
    return "Claude Code"
}

function Get-StateDirectory {
    <#
    .SYNOPSIS
        Get the state file storage directory
    .OUTPUTS
        System.String. State directory path
    #>
    if (-not $script:StateDir) {
        Initialize-StateManager | Out-Null
    }
    return $script:StateDir
}

function Test-DebugEnabled {
    <#
    .SYNOPSIS
        Check if debug mode is enabled
    .OUTPUTS
        System.Boolean
    #>
    # Check script variable first
    if ($script:DebugEnabled) {
        return $true
    }
    # Fallback to environment variables
    if ($env:TERMINAL_NOTIFIER_DEBUG -or $env:CLAUDE_NOTIFY_DEBUG) {
        return $true
    }
    return $false
}

# Export functions
Export-ModuleMember -Function @(
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
    'Get-WindowDisplayName'
)
