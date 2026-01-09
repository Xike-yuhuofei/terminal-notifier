@{
    # Module manifest for TerminalNotifier
    # Generic terminal notification library for PowerShell

    # Script module or binary module file associated with this manifest.
    RootModule = 'TerminalNotifier.psm1'

    # Version number of this module.
    ModuleVersion = '2.0.0'

    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

    # Author of this module
    Author = 'Terminal Notifier Team'

    # Company or vendor of this module
    CompanyName = 'Open Source'

    # Copyright statement for this module
    Copyright = '(c) 2025. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Generic terminal notification library providing OSC sequences, task tracking, Bell alerts, and visual effects for Windows Terminal, VS Code, and other modern terminals.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @(
        'lib\StateManager.psm1',
        'lib\OscSender.psm1',
        'lib\NotificationEnhancements.psm1'
    )

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
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
        'Get-OriginalTitle',

        # Main module functions
        'Send-Notification',
        'Initialize-TerminalNotifier'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @(
        'tn-notify',
        'tn-bell',
        'tn-title'
    )

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Terminal', 'Notification', 'OSC', 'Bell', 'Task', 'Progress', 'Windows-Terminal')

            # A URL to the license for this module.
            LicenseUri = ''

            # A URL to the main website for this project.
            ProjectUri = ''

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = @'
Version 2.0.0:
- Refactored to generic tool library (removed Claude Code specific dependencies)
- Added backward compatibility with legacy environment variables
- Improved terminal detection (ConEmu, iTerm2, etc.)
- Added new ANSI helper functions
- Added configurable initialization
- English documentation
'@
        }
    }

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}
