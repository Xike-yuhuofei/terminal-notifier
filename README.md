# Terminal Notifier

**Terminal Notifier** - A generic PowerShell terminal notification library for Windows Terminal, VS Code, ConEmu, and other modern terminals.

## Features

- **Real-time Status Display**: Window title shows current task status
- **Tab Background Color**: Red/Blue/Yellow/Green backgrounds for quick identification
- **Bell Alerts**: Configurable terminal bell notifications
- **Multi-Window Support**: Each tab maintains independent state
- **Task Tracking**: RAII-style task progress tracking
- **Auto Cleanup**: State files older than 24 hours are automatically cleaned
- **Debug Mode**: Detailed logging output

## Quick Start

### Installation

```powershell
# Import the module
Import-Module C:\Users\Xike\.claude\tools\terminal-notifier\TerminalNotifier.psd1

# Or add to your PowerShell profile for automatic loading
```

### Basic Usage

```powershell
# Send notifications
Send-Notification -Type "success" -Message "Build complete"
Send-Notification -Type "error" -Message "Test failed" -Bell $true
Send-Notification -Type "warning" -Message "Low memory" -Level "Urgent"

# Using aliases
tn-notify -Type "info" -Message "Processing..."
tn-bell -Times 3
tn-title "My Custom Title"
```

### Command Line Usage

```powershell
# From scripts directory
.\scripts\notify.ps1 -EventType "success" -Context "Done" -Bell $true
.\scripts\notify.ps1 -EventType "error" -Context "Failed" -Level "Urgent"
.\scripts\notify.ps1 -EventType "working" -Context "Processing..." -ProjectName "MyProject"
```

## Notification Types

| Type | Color | Description |
|------|-------|-------------|
| `session_start` | Blue | Session started |
| `working` | Blue | Work in progress |
| `needs_human` | Red | Requires human attention |
| `session_end` | Black | Session ended |
| `error` | Red | Error occurred |
| `success` | Green | Task completed successfully |
| `warning` | Yellow | Warning message |
| `info` | Blue | General information |

## Notification Levels

| Level | Bell Behavior |
|-------|---------------|
| `Silent` | No bell |
| `Normal` | Bell only if explicitly enabled |
| `Urgent` | Always bell + title flash |

Bell ring counts by type:

| Level | needs_human | error | success | warning | info |
|-------|-------------|-------|---------|---------|------|
| Silent | 0 | 0 | 0 | 0 | 0 |
| Normal | 2 | 2 | 1 | 1 | 1 |
| Urgent | 3 | 3 | 2 | 2 | 1 |

## Task Tracking API

RAII-style task tracking for long-running operations:

```powershell
Import-Module TerminalNotifier

# Start tracking a task
$task = Start-TrackedTask "Building project"

# Do work...

# Complete the task
$task | Complete-TrackedTask -Success $true -Message "Build succeeded"
```

### Progress Updates

```powershell
$task = Start-TrackedTask "Downloading files" -TaskId "download-001"

# Update progress (title shows: [...] Downloading [50/100] (50%))
Update-TaskProgress -TaskId "download-001" -Current 50 -Total 100

# Complete
$task | Complete-TrackedTask -Success $true
```

### Completion Levels

```powershell
# Silent completion
$task | Complete-TrackedTask -Success $true -Level "Silent"

# Normal (bell)
$task | Complete-TrackedTask -Success $true -Level "Normal"

# Urgent (flash + bell)
$task | Complete-TrackedTask -Success $true -Level "Urgent"
```

### Active Tasks

```powershell
# List all active tasks
Get-ActiveTasks
```

## Configuration

### Environment Variables

| Variable | Description |
|----------|-------------|
| `TERMINAL_NOTIFIER_DEBUG` | Enable debug output |
| `TERMINAL_NOTIFIER_STATE_DIR` | Custom state file directory |
| `TERMINAL_NOTIFIER_SESSION_ID` | Custom session ID |
| `TERMINAL_NOTIFIER_PROJECT` | Project name for titles |

Legacy variables (backward compatible):
- `CLAUDE_NOTIFY_DEBUG`
- `CLAUDE_PLUGIN_ROOT`
- `CLAUDE_SESSION_ID`
- `CLAUDE_PROJECT_DIR`

### Programmatic Configuration

```powershell
Initialize-TerminalNotifier -ProjectName "MyApp" -Debug $true
Initialize-TerminalNotifier -StateDirectory "C:\temp\states"
```

## File Structure

```
terminal-notifier/
  TerminalNotifier.psd1       # Module manifest
  TerminalNotifier.psm1       # Main module entry point
  lib/
    StateManager.psm1         # State file management
    OscSender.psm1            # OSC sequence sending
    NotificationEnhancements.psm1  # Task tracking, Bell, etc.
  scripts/
    notify.ps1                # Command line entry script
  .states/                    # State files (auto-created)
  README.md
```

## API Reference

### Main Module Functions

- `Initialize-TerminalNotifier` - Initialize with custom settings
- `Send-Notification` - Send a notification

### State Management (StateManager.psm1)

- `Initialize-StateManager` - Initialize state manager
- `Get-SessionId` - Get current session ID
- `Get-StateFilePath` - Get state file path
- `Get-CurrentState` - Read current state
- `Set-CurrentState` - Write state
- `Remove-StateFile` - Delete state file
- `Clear-OldStateFiles` - Clean up old files
- `Get-ProjectName` - Get project name
- `Test-DebugEnabled` - Check debug mode

### OSC Sequences (OscSender.psm1)

- `Send-OscTitle` - Set window title (OSC 2)
- `Send-OscTabColor` - Set tab background color (OSC 6)
- `Set-TermTitleLegacy` - Fallback title setting
- `Test-OscSupport` - Check terminal OSC support
- `Set-NotificationVisual` - Combined title + color
- `Reset-TerminalVisual` - Reset to defaults
- `Send-AnsiReset` - Send ANSI reset
- `Send-AnsiBold` - Send ANSI bold
- `Send-AnsiBlink` - Send ANSI blink

### Task Tracking (NotificationEnhancements.psm1)

- `Start-TrackedTask` - Start tracking a task
- `Complete-TrackedTask` - Complete a tracked task
- `Update-TaskProgress` - Update task progress
- `Get-ActiveTasks` - Get active tasks
- `Invoke-TerminalBell` - Ring terminal bell
- `Invoke-TitleFlash` - Flash title for attention
- `Format-Duration` - Format duration string
- `Restore-OriginalTitle` - Restore original title
- `Set-OriginalTitle` - Set original title
- `Get-OriginalTitle` - Get original title

## Supported Terminals

| Terminal | OSC 2 (Title) | OSC 6 (Tab Color) | Bell |
|----------|---------------|-------------------|------|
| Windows Terminal | Yes | Yes | Yes |
| VS Code Terminal | Yes | Yes | Yes |
| ConEmu/Cmder | Yes | Partial | Yes |
| iTerm2 (macOS) | Yes | No | Yes |
| Classic PowerShell | Fallback | No | Yes |

## Troubleshooting

### Bell Not Working

Configure Windows Terminal bell style:

```json
{
    "profiles": {
        "defaults": {
            "bellStyle": "all"
        }
    }
}
```

### Tab Color Not Changing

Ensure you're using Windows Terminal or another terminal that supports OSC 6 sequences.

### State Files Accumulating

Manual cleanup:
```powershell
Remove-Item (Join-Path (Get-StateDirectory) "*") -Force
```

Or automatic cleanup:
```powershell
Clear-OldStateFiles -MaxAgeHours 24
```

## Integration with Claude Code

This library can be used as a Claude Code plugin. When the `CLAUDE_PLUGIN_ROOT` environment variable is set, it automatically uses Claude Code's plugin directory for state files.

Hook events supported:
- SessionStart, SessionEnd
- PreToolUse, PostToolUse
- Stop, SubagentStop
- Notification

## License

MIT

## Contributing

Issues and Pull Requests welcome!

## References

- [Windows Terminal OSC Sequences](https://aka.ms/terminal-sequences)
- [ANSI Escape Codes](https://en.wikipedia.org/wiki/ANSI_escape_code)
