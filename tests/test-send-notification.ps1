# test-send-notification.ps1
# Test Send-Notification functionality

Write-Host '=== Test Send-Notification ===' -ForegroundColor Cyan
Write-Host 'Note: This test will change terminal title and color' -ForegroundColor Yellow
Write-Host ''

$modulePath = Join-Path $PSScriptRoot '..\TerminalNotifier.psd1'
Remove-Module TerminalNotifier -ErrorAction SilentlyContinue
Import-Module $modulePath -Force

# Save original title
$originalTitle = $Host.UI.RawUI.WindowTitle

# Initialize
Write-Host '1. Initializing TerminalNotifier...' -ForegroundColor Cyan
Initialize-TerminalNotifier -ProjectName 'TestProject' | Out-Null
Write-Host '[OK] Initialized' -ForegroundColor Green

# Test various notification types (using Silent mode to avoid delay and Bell)
$testCases = @(
    @{Type='info';          Message='Info notification test'},
    @{Type='working';       Message='Processing...'},
    @{Type='session_start'; Message='Session started'}
)

foreach ($test in $testCases) {
    Write-Host "2. Testing Type='$($test.Type)'..." -ForegroundColor Cyan
    try {
        Send-Notification -Type $test.Type -Message $test.Message -Level 'Silent'
        Write-Host "[OK] $($test.Type) notification sent" -ForegroundColor Green
        Write-Host "   Current title: $($Host.UI.RawUI.WindowTitle)"
    } catch {
        Write-Host "[FAIL] $($test.Type): $_" -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 300
}

# Test notification with Bell (Silent mode)
Write-Host ''
Write-Host '3. Testing Bell parameter...' -ForegroundColor Cyan
try {
    Send-Notification -Type 'error' -Message 'Error test' -Bell $false -Level 'Silent'
    Write-Host '[OK] Error notification (Silent, no bell)' -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Error notification: $_" -ForegroundColor Red
}

# Test notification levels
Write-Host ''
Write-Host '4. Testing notification levels...' -ForegroundColor Cyan
$levelTests = @('Silent', 'Normal')  # Skip 'Urgent' to avoid delays in test

foreach ($level in $levelTests) {
    try {
        Send-Notification -Type 'info' -Message "Level $level test" -Level $level -Bell $false
        Write-Host "[OK] Level=$level" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] Level=$level : $_" -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 200
}

# Restore title
$Host.UI.RawUI.WindowTitle = $originalTitle
Write-Host ''
Write-Host '[DONE] Send-Notification tests completed' -ForegroundColor Green
