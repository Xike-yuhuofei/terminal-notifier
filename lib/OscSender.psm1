# OscSender.psm1
# Terminal Notifier - OSC Sequence Sending Module
# Generic Tool Library - Handles terminal visual effects

function Send-OscTitle {
    <#
    .SYNOPSIS
        Send OSC 2 sequence to set window title
    .PARAMETER Title
        The title text to set
    .EXAMPLE
        Send-OscTitle "Task Complete"
        Send-OscTitle "[ERROR] Build failed"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title
    )

    $esc = [char]27

    try {
        # OSC 2 sequence: ESC ] 2 ; title BEL
        # Use [Console]::Write to bypass stdout redirection
        [Console]::Write("$esc]2;$Title`a")
        return $true
    }
    catch {
        Write-Warning "Failed to send OSC 2 title: $_"
        return $false
    }
}

function Send-OscTabColor {
    <#
    .SYNOPSIS
        Send OSC 9;4 sequence to set Tab progress indicator (Windows Terminal)
    .PARAMETER Color
        Color name: "red", "blue", "green", "yellow", "orange", "default"
    .PARAMETER Blink
        (Ignored - OSC 9;4 does not support blinking)
    .EXAMPLE
        Send-OscTabColor -Color "red"
        Send-OscTabColor -Color "default"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("red", "blue", "green", "yellow", "orange", "default")]
        [string]$Color,

        [bool]$Blink = $false
    )

    $esc = [char]27

    # OSC 9;4 state mapping
    # state: 0=hidden, 1=normal, 2=error(red), 3=indeterminate, 4=warning(yellow)
    $stateMap = @{
        "red"     = 2  # Error state (red progress)
        "yellow"  = 4  # Warning state (yellow progress)
        "orange"  = 4  # Same as warning
        "blue"    = 1  # Normal state (default color)
        "green"   = 1  # Normal state
        "default" = 0  # Hide progress indicator
    }

    $state = $stateMap[$Color]
    $progress = if ($state -eq 0) { 0 } else { 100 }

    try {
        # OSC 9;4 sequence: ESC ] 9 ; 4 ; state ; progress BEL
        # Use [Console]::Write to bypass stdout redirection
        [Console]::Write("$esc]9;4;$state;$progress`a")
        return $true
    }
    catch {
        Write-Warning "Failed to send OSC 9;4 progress: $_"
        return $false
    }
}

function Set-TermTitleLegacy {
    <#
    .SYNOPSIS
        Set terminal title using legacy method (fallback)
    .PARAMETER Title
        The title text to set
    .EXAMPLE
        Set-TermTitleLegacy "My Title"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title
    )

    # Method 1: Try PowerShell Host API (works in most PowerShell environments)
    try {
        $Host.UI.RawUI.WindowTitle = $Title
        Write-Debug "Title set via PowerShell Host API"
        return $true
    }
    catch {
        Write-Debug "PowerShell Host API failed: $_"
    }

    # Method 2: Check if we're in Git Bash/Mintty environment
    # Mintty (Git Bash's terminal) supports OSC sequences but may need different approach
    if ($env:MSYSTEM -or ($env:SHELL -and $env:SHELL -like "*bash*")) {
        try {
            # Try Mintty-specific escape sequence (same as OSC but may work in Git Bash)
            $esc = [char]27
            [Console]::Write("${esc}]2;$Title`a")
            Write-Debug "Title set via OSC sequence in Git Bash/Mintty"

            # Give terminal time to process
            Start-Sleep -Milliseconds 50

            return $true
        }
        catch {
            Write-Debug "Git Bash/Mintty OSC sequence failed: $_"
        }
    }

    # Method 3: Try Windows console title command (Windows only)
    if ($env:OS -eq "Windows_NT") {
        try {
            # Use cmd /c title command
            $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "title", $Title -WindowStyle Hidden -PassThru -Wait
            if ($process.ExitCode -eq 0) {
                Write-Debug "Title set via Windows title command"
                return $true
            } else {
                Write-Debug "Windows title command failed with exit code $($process.ExitCode)"
            }
        }
        catch {
            Write-Debug "Windows title command failed: $_"
        }
    }

    # Method 4: Try direct console output as last resort
    try {
        # Some terminals may respond to simple output
        Write-Host "`e]2;$Title`a" -NoNewline
        Write-Debug "Title set via direct Write-Host"
        return $true
    }
    catch {
        Write-Debug "Direct Write-Host failed: $_"
    }

    # All methods failed
    Write-Warning "Failed to set terminal title using any legacy method"
    return $false
}

function Test-OscSupport {
    <#
    .SYNOPSIS
        Test if terminal supports OSC sequences
    .OUTPUTS
        System.Boolean. Returns $true if supported
    .EXAMPLE
        if (Test-OscSupport) { Send-OscTitle "Hello" }
    #>
    # Priority 1: Check for terminals that DEFINITELY support OSC sequences

    # Check if in Windows Terminal (even if running inside Git Bash)
    if ($env:WT_SESSION) {
        # Windows Terminal supports OSC sequences regardless of shell
        return $true
    }

    # Check if in VS Code integrated terminal
    if ($env:TERM_PROGRAM -eq "vscode") {
        return $true
    }

    # Check if in ConEmu/Cmder
    if ($env:ConEmuANSI -eq "ON") {
        return $true
    }

    # Check for iTerm2
    if ($env:TERM_PROGRAM -eq "iTerm.app") {
        return $true
    }

    # Check for other terminals via COLORTERM
    if ($env:COLORTERM -eq "truecolor" -or $env:COLORTERM -eq "24bit") {
        return $true
    }

    # Priority 2: Check for terminals with LIMITED or NO OSC support

    # Check for Git Bash/Mintty environment
    # Git Bash typically sets MSYSTEM (e.g., MSYSTEM=MINGW64) or has bash in SHELL
    if ($env:MSYSTEM -or ($env:SHELL -and $env:SHELL -like "*bash*")) {
        # Git Bash/Mintty has limited OSC support.
        # However, if we're in Windows Terminal WITH Git Bash shell, WT_SESSION should have been caught above.
        # If we reach here, it means we're in native Git Bash/Mintty without WT_SESSION.
        return $false
    }

    # Priority 3: Unknown environment - try to detect

    # Check if we can access console properties (indicates modern terminal)
    try {
        $consoleWidth = [Console]::WindowWidth
        $consoleHeight = [Console]::WindowHeight
        # If we can read console properties, it's likely a modern terminal
        # but we'll be conservative and return false unless explicitly detected
    }
    catch {
        # Cannot access console, likely limited terminal
    }

    # Default: conservative approach for unknown terminals
    # Return false to use legacy methods, which have better fallback handling
    return $false
}

function Set-NotificationVisual {
    <#
    .SYNOPSIS
        Set notification visual effects (title + color)
    .PARAMETER State
        State type: "red", "blue", "green", "yellow", "white", "black"
    .PARAMETER Title
        Title text
    .PARAMETER ProjectName
        Project name (optional, appended to title)
    .EXAMPLE
        Set-NotificationVisual -State "red" -Title "[?] Ready to Stop?" -ProjectName "MyProject"
        Set-NotificationVisual -State "green" -Title "Build Complete"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("red", "blue", "green", "yellow", "white", "black")]
        [string]$State,

        [Parameter(Mandatory=$true)]
        [string]$Title,

        [string]$ProjectName = ""
    )

    # Build display title
    if ($ProjectName) {
        $displayTitle = "$Title - $ProjectName"
    }
    else {
        $displayTitle = $Title
    }

    # Test OSC support
    $oscSupported = Test-OscSupport

    if ($oscSupported) {
        # Use OSC sequences
        $colorMap = @{
            "red"    = "red"
            "blue"   = "blue"
            "green"  = "green"
            "yellow" = "yellow"
            "white"  = "default"
            "black"  = "default"
        }

        $tabColor = $colorMap[$State]
        $blink = ($State -eq "red")

        $titleSuccess = Send-OscTitle -Title $displayTitle
        $colorSuccess = Send-OscTabColor -Color $tabColor -Blink $blink

        return ($titleSuccess -and $colorSuccess)
    }
    else {
        # Use legacy method
        return Set-TermTitleLegacy -Title $displayTitle
    }
}

function Reset-TerminalVisual {
    <#
    .SYNOPSIS
        Reset terminal visual effects to default state
    .PARAMETER ProjectName
        Project name to display in reset title (optional)
    .PARAMETER Title
        Custom title to set after reset (optional, defaults to "[Ready]")
    .EXAMPLE
        Reset-TerminalVisual
        Reset-TerminalVisual -ProjectName "MyProject"
        Reset-TerminalVisual -Title "Idle"
    #>
    param(
        [string]$ProjectName = "",
        [string]$Title = ""
    )

    $esc = [char]27

    try {
        # Reset all ANSI attributes
        [Console]::Write("$esc[0m")

        # Restore default Tab color (hide progress indicator)
        Send-OscTabColor -Color "default" -Blink $false

        # Build reset title
        if ($Title) {
            $resetTitle = $Title
        }
        elseif ($ProjectName) {
            $resetTitle = "[Ready] - $ProjectName"
        }
        else {
            # Use current directory name as fallback
            $currentDir = Split-Path -Leaf (Get-Location).Path
            $resetTitle = "[Ready] - $currentDir"
        }

        Send-OscTitle -Title $resetTitle

        return $true
    }
    catch {
        Write-Warning "Failed to reset terminal visual effects: $_"
        return $false
    }
}

function Send-AnsiReset {
    <#
    .SYNOPSIS
        Send ANSI reset sequence
    .EXAMPLE
        Send-AnsiReset
    #>
    $esc = [char]27
    [Console]::Write("$esc[0m")
}

function Send-AnsiBold {
    <#
    .SYNOPSIS
        Send ANSI bold sequence
    .EXAMPLE
        Send-AnsiBold
    #>
    $esc = [char]27
    [Console]::Write("$esc[1m")
}

function Send-AnsiBlink {
    <#
    .SYNOPSIS
        Send ANSI blink sequence
    .EXAMPLE
        Send-AnsiBlink
    #>
    $esc = [char]27
    [Console]::Write("$esc[5m")
}

# Export functions
Export-ModuleMember -Function @(
    'Send-OscTitle',
    'Send-OscTabColor',
    'Set-TermTitleLegacy',
    'Test-OscSupport',
    'Set-NotificationVisual',
    'Reset-TerminalVisual',
    'Send-AnsiReset',
    'Send-AnsiBold',
    'Send-AnsiBlink'
)
