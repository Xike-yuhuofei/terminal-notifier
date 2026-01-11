# HookBase.psm1
# Terminal Notifier - Hook Base Module
# Provides common utilities for all Hook scripts

function Initialize-HookEnvironment {
    <#
    .SYNOPSIS
        Initialize Hook environment and read input
    .OUTPUTS
        Hashtable with ModuleRoot, LibPath, HookData, ProjectName
    .EXAMPLE
        $env = Initialize-HookEnvironment
        $env.ProjectName
    #>
    $scriptDir = Split-Path -Parent $PSCommandPath
    $moduleRoot = Resolve-Path (Join-Path $scriptDir "..")
    $libPath = Join-Path $moduleRoot "lib"

    # Read hook input from stdin
    $inputJson = [Console]::In.ReadToEnd()
    $hookData = $inputJson | ConvertFrom-Json

    $cwd = $hookData.cwd
    $projectName = Split-Path -Leaf $cwd

    return @{
        ModuleRoot = $moduleRoot
        LibPath = $libPath
        HookData = $hookData
        ProjectName = $projectName
        Cwd = $cwd
    }
}

function Import-HookModules {
    <#
    .SYNOPSIS
        Import required modules for Hook scripts
    .PARAMETER LibPath
        Path to lib directory
    .PARAMETER Modules
        Array of module names (without .psm1 extension)
    .EXAMPLE
        Import-HookModules -LibPath $libPath -Modules @("StateManager", "ToastNotifier")
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$LibPath,

        [Parameter(Mandatory=$true)]
        [string[]]$Modules
    )

    foreach ($moduleName in $Modules) {
        $modulePath = Join-Path $LibPath "$moduleName.psm1"
        if (Test-Path $modulePath) {
            Import-Module $modulePath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-WindowNameWithFallback {
    <#
    .SYNOPSIS
        Get window display name with fallback logic
    .PARAMETER ProjectName
        Project name (fallback value)
    .PARAMETER ModuleRoot
        Module root path (for reading original-title.txt)
    .PARAMETER UseOriginalTitleFallback
        Whether to use original-title.txt as fallback
    .OUTPUTS
        System.String. Window display name
    .EXAMPLE
        $windowName = Get-WindowNameWithFallback -ProjectName "MyProject" -ModuleRoot $moduleRoot
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectName,

        [Parameter(Mandatory=$true)]
        [string]$ModuleRoot,

        [bool]$UseOriginalTitleFallback = $true
    )

    $windowName = ""

    # Try Get-WindowDisplayName first
    try {
        $windowName = Get-WindowDisplayName
    }
    catch {
        $windowName = $ProjectName
    }

    # If Get-WindowDisplayName returns project name, try original-title.txt
    if ($UseOriginalTitleFallback -and $windowName -eq $ProjectName) {
        $stateDir = Join-Path $ModuleRoot ".states"
        $originalTitleFile = Join-Path $stateDir "original-title.txt"

        if (Test-Path $originalTitleFile) {
            $savedTitle = Get-Content $originalTitleFile -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
            if ($savedTitle -and $savedTitle -ne "" -and $savedTitle -ne $ProjectName) {
                $windowName = $savedTitle
            }
        }
    }

    return $windowName
}

function Get-OriginalTitle {
    <#
    .SYNOPSIS
        Read original title from state file
    .PARAMETER ModuleRoot
        Module root path
    .OUTPUTS
        System.String. Original title or empty string
    .EXAMPLE
        $title = Get-OriginalTitle -ModuleRoot $moduleRoot
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModuleRoot
    )

    $stateDir = Join-Path $ModuleRoot ".states"
    $originalTitleFile = Join-Path $stateDir "original-title.txt"

    if (Test-Path $originalTitleFile) {
        $title = Get-Content $originalTitleFile -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
        return $title
    }

    return ""
}

function Set-OriginalTitle {
    <#
    .SYNOPSIS
        Save original title to state file
    .PARAMETER ModuleRoot
        Module root path
    .PARAMETER Title
        Title to save
    .EXAMPLE
        Set-OriginalTitle -ModuleRoot $moduleRoot -Title "My Title"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModuleRoot,

        [Parameter(Mandatory=$true)]
        [string]$Title
    )

    $stateDir = Join-Path $ModuleRoot ".states"
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }

    $originalTitleFile = Join-Path $stateDir "original-title.txt"
    $Title | Out-File -FilePath $originalTitleFile -Encoding UTF8 -Force
}

function Remove-OriginalTitle {
    <#
    .SYNOPSIS
        Remove original title state file
    .PARAMETER ModuleRoot
        Module root path
    .EXAMPLE
        Remove-OriginalTitle -ModuleRoot $moduleRoot
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModuleRoot
    )

    $stateDir = Join-Path $ModuleRoot ".states"
    $originalTitleFile = Join-Path $stateDir "original-title.txt"

    if (Test-Path $originalTitleFile) {
        Remove-Item -Path $originalTitleFile -Force -ErrorAction SilentlyContinue
    }
}

function Build-NotificationTitle {
    <#
    .SYNOPSIS
        Build notification title with emoji
    .PARAMETER WindowName
        Window display name
    .PARAMETER ProjectName
        Project name
    .PARAMETER OriginalTitle
        Original title from state file (optional)
    .OUTPUTS
        System.String. Formatted title
    .EXAMPLE
        $title = Build-NotificationTitle -WindowName "编译测试" -ProjectName "Backend_CPP"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$WindowName,

        [Parameter(Mandatory=$true)]
        [string]$ProjectName,

        [string]$OriginalTitle = ""
    )

    if ($OriginalTitle) {
        return "[📢] $OriginalTitle"
    }
    elseif ($WindowName -and $WindowName -ne $ProjectName) {
        return "[📢 $WindowName] 新通知 - $ProjectName"
    }
    else {
        return "[📢] 新通知 - $ProjectName"
    }
}

function Build-StopTitle {
    <#
    .SYNOPSIS
        Build stop hook title with emoji
    .PARAMETER WindowName
        Window display name
    .PARAMETER ProjectName
        Project name
    .OUTPUTS
        System.String. Formatted title
    .EXAMPLE
        $title = Build-StopTitle -WindowName "编译测试" -ProjectName "Backend_CPP"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$WindowName,

        [Parameter(Mandatory=$true)]
        [string]$ProjectName
    )

    if ($WindowName -and $WindowName -ne $ProjectName) {
        return "[⚠️ $WindowName] 需要输入 - $ProjectName"
    }
    else {
        return "[⚠️] 需要输入 - $ProjectName"
    }
}

function Invoke-ToastWithFallback {
    <#
    .SYNOPSIS
        Invoke toast notification with error handling
    .PARAMETER ScriptBlock
        Script block to execute
    .EXAMPLE
        Invoke-ToastWithFallback -ScriptBlock { Send-StopToast -WindowName $name -ProjectName $proj }
    #>
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock
    )

    try {
        & $ScriptBlock
    }
    catch {
        # Toast failure should not block Hook execution
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-HookEnvironment',
    'Import-HookModules',
    'Get-WindowNameWithFallback',
    'Get-OriginalTitle',
    'Set-OriginalTitle',
    'Remove-OriginalTitle',
    'Build-NotificationTitle',
    'Build-StopTitle',
    'Invoke-ToastWithFallback'
)
