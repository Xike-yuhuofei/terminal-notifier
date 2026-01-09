# test-bell-and-cli.ps1
# Test Bell and CLI Script

Write-Host '=== Test Bell and CLI Script ===' -ForegroundColor Cyan
Write-Host ''

$modulePath = Join-Path $PSScriptRoot '..\TerminalNotifier.psd1'
Remove-Module TerminalNotifier -ErrorAction SilentlyContinue
Import-Module $modulePath -Force

# 1. Test Invoke-TerminalBell
Write-Host '1. Testing Invoke-TerminalBell...' -ForegroundColor Cyan
try {
    $result = Invoke-TerminalBell -Times 1
    Write-Host "[OK] Bell rang once (returned: $result)" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Invoke-TerminalBell: $_" -ForegroundColor Red
}

# 2. Test Invoke-TitleFlash (shortened for test)
Write-Host ''
Write-Host '2. Testing Invoke-TitleFlash...' -ForegroundColor Cyan
try {
    $result = Invoke-TitleFlash -Title "Test Flash" -Times 1 -DelayMs 100
    Write-Host "[OK] Title flashed (returned: $result)" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Invoke-TitleFlash: $_" -ForegroundColor Red
}

# 3. Test CLI script (notify.ps1)
Write-Host ''
Write-Host '3. Testing CLI script (notify.ps1)...' -ForegroundColor Cyan
$scriptPath = Join-Path $PSScriptRoot 'notify.ps1'

# Check if script exists
if (Test-Path $scriptPath) {
    Write-Host "[OK] notify.ps1 exists" -ForegroundColor Green
} else {
    # Try parent scripts folder
    $scriptPath = Join-Path $PSScriptRoot '..\scripts\notify.ps1'
    if (Test-Path $scriptPath) {
        Write-Host "[OK] notify.ps1 found at $scriptPath" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] notify.ps1 not found" -ForegroundColor Red
        exit 1
    }
}

# Test CLI with different parameters
Write-Host ''
Write-Host '4. Testing CLI with various parameters...' -ForegroundColor Cyan

$cliTests = @(
    @{EventType='info';    Context='CLI Info Test';     Level='Silent'},
    @{EventType='working'; Context='CLI Working Test';  Level='Silent'},
    @{EventType='error';   Context='CLI Error Test';    Level='Silent'}
)

foreach ($test in $cliTests) {
    try {
        & $scriptPath -EventType $test.EventType -Context $test.Context -Level $test.Level
        Write-Host "[OK] CLI: EventType=$($test.EventType)" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] CLI EventType=$($test.EventType): $_" -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 200
}

# 5. Test CLI with ProjectName
Write-Host ''
Write-Host '5. Testing CLI with ProjectName parameter...' -ForegroundColor Cyan
try {
    & $scriptPath -EventType 'info' -Context 'Project Name Test' -Level 'Silent' -ProjectName 'MyCustomProject'
    Write-Host "[OK] CLI with custom ProjectName" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] CLI with ProjectName: $_" -ForegroundColor Red
}

# 6. Test Original Title functions
Write-Host ''
Write-Host '6. Testing Original Title functions...' -ForegroundColor Cyan
try {
    $orig = Get-OriginalTitle
    Write-Host "[OK] Get-OriginalTitle: $orig" -ForegroundColor Green

    Set-OriginalTitle -Title "New Original"
    $newOrig = Get-OriginalTitle
    Write-Host "[OK] Set-OriginalTitle -> $newOrig" -ForegroundColor Green

    Restore-OriginalTitle
    Write-Host "[OK] Restore-OriginalTitle" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Original Title functions: $_" -ForegroundColor Red
}

Write-Host ''
Write-Host '[DONE] Bell and CLI tests completed' -ForegroundColor Green
