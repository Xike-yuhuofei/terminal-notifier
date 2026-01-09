# Terminal Notifier - Enhanced Notification Features
# Generic Tool Library - Task tracking, Bell alerts, Title effects

$script:OriginalTitle = $Host.UI.RawUI.WindowTitle
$script:ActiveTasks = @{}


function Invoke-TerminalBell {
    <#
    .SYNOPSIS
        Trigger system sound notification
    .PARAMETER Times
        Number of times to play sound, default 1
    .PARAMETER DelayMs
        Delay between multiple sounds (milliseconds), default 300
    .PARAMETER SoundType
        Type of system sound: Beep, Asterisk, Exclamation, Hand, Question (default Asterisk)
    .EXAMPLE
        Invoke-TerminalBell -Times 3
        Invoke-TerminalBell -Times 2 -SoundType 'Asterisk'
        Invoke-TerminalBell -SoundType 'Asterisk'
    #>
    param(
        [int]$Times = 1,
        [int]$DelayMs = 300,
        [ValidateSet('Beep', 'Asterisk', 'Exclamation', 'Hand', 'Question')]
        [string]$SoundType = 'Asterisk'
    )

    try {
        for ($i = 0; $i -lt $Times; $i++) {
            # Use .NET SystemSounds for reliable audio notification
            [System.Media.SystemSounds]::$SoundType.Play()

            # Also send BEL character as fallback (for terminals that support it)
            [Console]::Write("`a")

            if ($Times -gt 1 -and $i -lt ($Times - 1)) {
                Start-Sleep -Milliseconds $DelayMs
            }
        }
        return $true
    }
    catch {
        try {
            # Fallback to rundll32 if .NET SystemSounds fails
            & rundll32 user32.dll,MessageBeep 0x00000040
        }
        catch {
            Write-Warning "Sound notification failed: $_"
        }
        return $false
    }
}

function Invoke-TitleFlash {
    <#
    .SYNOPSIS
        Flash the window title for attention
    .PARAMETER Title
        Title text to flash
    .PARAMETER Times
        Number of flash cycles, default 3
    .PARAMETER DelayMs
        Flash interval (milliseconds), default 400
    .EXAMPLE
        Invoke-TitleFlash "Task Complete!" -Times 5
        Invoke-TitleFlash "Error!" -DelayMs 200
    #>
    param(
        [string]$Title,
        [int]$Times = 3,
        [int]$DelayMs = 400
    )

    try {
        for ($i = 0; $i -lt $Times; $i++) {
            $Host.UI.RawUI.WindowTitle = ">>> $Title"
            Start-Sleep -Milliseconds $DelayMs
            $Host.UI.RawUI.WindowTitle = "<<< $Title"
            Start-Sleep -Milliseconds $DelayMs
        }
        return $true
    }
    catch {
        Write-Warning "Title flash failed: $_"
        return $false
    }
}

function Start-TrackedTask {
    <#
    .SYNOPSIS
        Start tracking a task (RAII-style task management)
    .PARAMETER TaskName
        Name of the task
    .PARAMETER TaskId
        Optional task ID for later updates
    .OUTPUTS
        PSCustomObject. Task tracking object
    .EXAMPLE
        $task = Start-TrackedTask "Building project"
        $task = Start-TrackedTask "Downloading files" -TaskId "download-001"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,

        [string]$TaskId = ([Guid]::NewGuid().ToString())
    )

    $task = [PSCustomObject]@{
        Id            = $TaskId
        Name          = $TaskName
        StartTime     = Get-Date
        OriginalTitle = $script:OriginalTitle
        Status        = "Running"
        Current       = 0
        Total         = 0
    }

    $script:ActiveTasks[$TaskId] = $task

    # Set title to show task in progress
    $Host.UI.RawUI.WindowTitle = "[...] $TaskName"

    # Debug output
    if ($env:TERMINAL_NOTIFIER_DEBUG -or $env:CLAUDE_NOTIFY_DEBUG) {
        Write-Host "[TaskTracker] Started: $TaskName (ID: $TaskId)" -ForegroundColor DarkGray
    }

    return $task
}

function Complete-TrackedTask {
    <#
    .SYNOPSIS
        Complete a tracked task
    .PARAMETER Task
        Task object (from Start-TrackedTask)
    .PARAMETER Success
        Whether task succeeded, default $true
    .PARAMETER Message
        Optional completion message
    .PARAMETER Level
        Notification level: Silent, Normal, Urgent (default Normal)
    .EXAMPLE
        $task | Complete-TrackedTask -Success $true -Message "Build succeeded"
        $task | Complete-TrackedTask -Success $false -Level "Urgent"
    #>
    param(
        [Parameter(ValueFromPipeline = $true)]
        $Task,

        [bool]$Success = $true,

        [string]$Message = "",

        [ValidateSet("Silent", "Normal", "Urgent")]
        [string]$Level = "Normal"
    )

    if (-not $Task) {
        Write-Warning "Task object is null"
        return $false
    }

    # Remove from active tasks
    if ($script:ActiveTasks.ContainsKey($Task.Id)) {
        $script:ActiveTasks.Remove($Task.Id)
    }

    # Calculate duration
    $duration = (Get-Date) - $Task.StartTime
    $durationText = Format-Duration -Milliseconds $duration.TotalMilliseconds

    # Determine message and icon
    $msg = if ($Message) { $Message } else {
        if ($Success) { "$($Task.Name) completed ($durationText)" } else { "$($Task.Name) failed" }
    }

    $icon = if ($Success) { "[OK]" } else { "[FAIL]" }
    $title = "$icon $msg"

    # Set notification based on level
    switch ($Level) {
        "Silent" {
            $Host.UI.RawUI.WindowTitle = $title
        }
        "Normal" {
            $Host.UI.RawUI.WindowTitle = $title
            $bellTimes = if ($Success) { 2 } else { 3 }
            Invoke-TerminalBell -Times $bellTimes
        }
        "Urgent" {
            Invoke-TitleFlash -Title $title -Times 3
            Start-Sleep -Milliseconds 200
            $bellTimes = if ($Success) { 2 } else { 3 }
            Invoke-TerminalBell -Times $bellTimes
        }
    }

    # Restore original title (with delay for Urgent)
    if ($Level -eq "Urgent") {
        Start-Sleep -Seconds 2
    }
    $Host.UI.RawUI.WindowTitle = $Task.OriginalTitle

    # Debug output
    if ($env:TERMINAL_NOTIFIER_DEBUG -or $env:CLAUDE_NOTIFY_DEBUG) {
        $status = if ($Success) { "SUCCESS" } else { "FAILED" }
        Write-Host "[TaskTracker] Completed: $($Task.Name) - $status (${durationText})" -ForegroundColor DarkGray
    }

    return $true
}

function Update-TaskProgress {
    <#
    .SYNOPSIS
        Update task progress
    .PARAMETER TaskId
        Task ID
    .PARAMETER Current
        Current progress value
    .PARAMETER Total
        Total value
    .PARAMETER TaskName
        Optional task name (overrides original task name)
    .EXAMPLE
        Update-TaskProgress -TaskId "download-001" -Current 50 -Total 100
        # Output: [...] Downloading [50/100] (50%)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId,

        [Parameter(Mandatory=$true)]
        [int]$Current,

        [Parameter(Mandatory=$true)]
        [int]$Total,

        [string]$TaskName = ""
    )

    if (-not $script:ActiveTasks.ContainsKey($TaskId)) {
        Write-Warning "Task $TaskId does not exist"
        return $false
    }

    $task = $script:ActiveTasks[$TaskId]
    $task.Current = $Current
    $task.Total = $Total

    $percent = if ($Total -gt 0) { [math]::Floor($Current * 100 / $Total) } else { 0 }
    $name = if ($TaskName) { $TaskName } else { $task.Name }

    $title = "[...] $name [$Current/$Total] ($percent%)"
    $Host.UI.RawUI.WindowTitle = $title

    # Debug output
    if ($env:TERMINAL_NOTIFIER_DEBUG -or $env:CLAUDE_NOTIFY_DEBUG) {
        Write-Host "[TaskTracker] Progress: $name - $percent%" -ForegroundColor DarkGray
    }

    return $true
}

function Get-ActiveTasks {
    <#
    .SYNOPSIS
        Get list of active tasks
    .OUTPUTS
        Array of task objects
    .EXAMPLE
        $tasks = Get-ActiveTasks
        $tasks | ForEach-Object { Write-Host $_.Name }
    #>
    return $script:ActiveTasks.Values
}

function Format-Duration {
    <#
    .SYNOPSIS
        Format duration from milliseconds to human-readable string
    .PARAMETER Milliseconds
        Duration in milliseconds
    .OUTPUTS
        System.String. Formatted duration
    .EXAMPLE
        Format-Duration 1500   # Output: 1.5s
        Format-Duration 125000 # Output: 2m5s
    #>
    param([long]$Milliseconds)

    if ($Milliseconds -lt 1000) {
        return "$Milliseconds ms"
    }
    elseif ($Milliseconds -lt 60000) {
        $sec = [math]::Round($Milliseconds / 1000.0, 1)
        return "${sec}s"
    }
    else {
        $min = [math]::Floor($Milliseconds / 60000)
        $sec = [math]::Floor(($Milliseconds % 60000) / 1000)
        return "${min}m${sec}s"
    }
}

function Restore-OriginalTitle {
    <#
    .SYNOPSIS
        Restore the original window title
    .EXAMPLE
        Restore-OriginalTitle
    #>
    $Host.UI.RawUI.WindowTitle = $script:OriginalTitle
}

function Set-OriginalTitle {
    <#
    .SYNOPSIS
        Set a new original title (for when the default captured title is wrong)
    .PARAMETER Title
        New original title to use
    .EXAMPLE
        Set-OriginalTitle "My Project"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title
    )
    $script:OriginalTitle = $Title
}

function Get-OriginalTitle {
    <#
    .SYNOPSIS
        Get the stored original title
    .OUTPUTS
        System.String. The original title
    .EXAMPLE
        $title = Get-OriginalTitle
    #>
    return $script:OriginalTitle
}

# Export functions
Export-ModuleMember -Function @(
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
)
