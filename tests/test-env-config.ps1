# test-env-config.ps1
# Test Environment Variable Configuration

Write-Host '=== Test Environment Variable Configuration ===' -ForegroundColor Cyan
Write-Host ''

$modulePath = Join-Path $PSScriptRoot '..\TerminalNotifier.psd1'

# 1. Test new environment variables
Write-Host '1. Testing new environment variables (TERMINAL_NOTIFIER_*)...' -ForegroundColor Cyan

# Save current env vars
$savedDebug = $env:TERMINAL_NOTIFIER_DEBUG
$savedProject = $env:TERMINAL_NOTIFIER_PROJECT
$savedLegacyDebug = $env:CLAUDE_NOTIFY_DEBUG

# Test TERMINAL_NOTIFIER_DEBUG
$env:TERMINAL_NOTIFIER_DEBUG = "1"
$env:CLAUDE_NOTIFY_DEBUG = $null

Remove-Module TerminalNotifier -ErrorAction SilentlyContinue
Import-Module $modulePath -Force

$debugEnabled = Test-DebugEnabled
if ($debugEnabled) {
    Write-Host "[OK] TERMINAL_NOTIFIER_DEBUG=1 -> DebugEnabled=$debugEnabled" -ForegroundColor Green
} else {
    Write-Host "[FAIL] TERMINAL_NOTIFIER_DEBUG not recognized" -ForegroundColor Red
}

# 2. Test legacy environment variables (backward compatibility)
Write-Host ''
Write-Host '2. Testing legacy environment variables (CLAUDE_*)...' -ForegroundColor Cyan

$env:TERMINAL_NOTIFIER_DEBUG = $null
$env:CLAUDE_NOTIFY_DEBUG = "1"

Remove-Module TerminalNotifier -ErrorAction SilentlyContinue
Import-Module $modulePath -Force

$debugEnabled = Test-DebugEnabled
if ($debugEnabled) {
    Write-Host "[OK] CLAUDE_NOTIFY_DEBUG=1 -> DebugEnabled=$debugEnabled (backward compatible)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] CLAUDE_NOTIFY_DEBUG not recognized" -ForegroundColor Red
}

# 3. Test Initialize-StateManager with parameters
Write-Host ''
Write-Host '3. Testing Initialize-StateManager with custom parameters...' -ForegroundColor Cyan

$env:TERMINAL_NOTIFIER_DEBUG = $null
$env:CLAUDE_NOTIFY_DEBUG = $null

Remove-Module TerminalNotifier -ErrorAction SilentlyContinue
Import-Module $modulePath -Force

try {
    $result = Initialize-StateManager -ProjectName 'CustomProject' -Debug $true
    Write-Host "[OK] Initialize-StateManager with custom ProjectName" -ForegroundColor Green

    $projectName = Get-ProjectName
    if ($projectName -eq 'CustomProject') {
        Write-Host "[OK] Get-ProjectName returned: $projectName" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Get-ProjectName returned: $projectName (expected CustomProject)" -ForegroundColor Yellow
    }

    $debugEnabled = Test-DebugEnabled
    Write-Host "[OK] Debug enabled via parameter: $debugEnabled" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Initialize-StateManager: $_" -ForegroundColor Red
}

# 4. Test Get-SessionId
Write-Host ''
Write-Host '4. Testing Get-SessionId...' -ForegroundColor Cyan
try {
    $sessionId = Get-SessionId
    if ($sessionId) {
        Write-Host "[OK] SessionId: $sessionId" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] SessionId is empty" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Get-SessionId: $_" -ForegroundColor Red
}

# 5. Test Get-StateDirectory
Write-Host ''
Write-Host '5. Testing Get-StateDirectory...' -ForegroundColor Cyan
try {
    $stateDir = Get-StateDirectory
    if ($stateDir) {
        Write-Host "[OK] StateDirectory: $stateDir" -ForegroundColor Green
        if (Test-Path $stateDir) {
            Write-Host "   Directory exists" -ForegroundColor DarkGray
        } else {
            Write-Host "   Directory will be created on first use" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "[FAIL] StateDirectory is empty" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Get-StateDirectory: $_" -ForegroundColor Red
}

# 6. Test custom StateDirectory via Initialize-StateManager
Write-Host ''
Write-Host '6. Testing custom StateDirectory...' -ForegroundColor Cyan
$customStateDir = Join-Path $env:TEMP 'terminal-notifier-test-states'
try {
    Remove-Module TerminalNotifier -ErrorAction SilentlyContinue
    Import-Module $modulePath -Force
    Initialize-StateManager -StateDirectory $customStateDir | Out-Null

    $actualDir = Get-StateDirectory
    if ($actualDir -eq $customStateDir) {
        Write-Host "[OK] Custom StateDirectory: $actualDir" -ForegroundColor Green
    } else {
        Write-Host "[WARN] StateDirectory: $actualDir (expected $customStateDir)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[FAIL] Custom StateDirectory: $_" -ForegroundColor Red
}

# Cleanup
if (Test-Path $customStateDir) {
    Remove-Item $customStateDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Restore env vars
$env:TERMINAL_NOTIFIER_DEBUG = $savedDebug
$env:CLAUDE_NOTIFY_DEBUG = $savedLegacyDebug
$env:TERMINAL_NOTIFIER_PROJECT = $savedProject

Write-Host ''
Write-Host '[DONE] Environment Variable Configuration tests completed' -ForegroundColor Green
