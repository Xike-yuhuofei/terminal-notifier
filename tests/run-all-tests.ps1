# run-all-tests.ps1
# Terminal Notifier - Run All Tests

param(
    [switch]$Verbose
)

$testDir = $PSScriptRoot
$passCount = 0
$failCount = 0
$startTime = Get-Date

Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' Terminal Notifier - Test Suite' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

$tests = @(
    'test-send-notification.ps1',
    'test-task-tracking.ps1',
    'test-osc-sequences.ps1',
    'test-bell-and-cli.ps1',
    'test-env-config.ps1'
)

foreach ($test in $tests) {
    $testPath = Join-Path $testDir $test
    if (Test-Path $testPath) {
        Write-Host "Running: $test" -ForegroundColor Yellow
        Write-Host '----------------------------------------' -ForegroundColor DarkGray

        try {
            & $testPath
            $passCount++
            Write-Host ''
        } catch {
            Write-Host "[ERROR] $test failed: $_" -ForegroundColor Red
            $failCount++
        }

        Write-Host ''
    } else {
        Write-Host "[SKIP] $test not found" -ForegroundColor DarkGray
    }
}

$duration = (Get-Date) - $startTime

Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' Test Summary' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host "Tests Run:    $($passCount + $failCount)"
Write-Host "Passed:       $passCount" -ForegroundColor Green
Write-Host "Failed:       $failCount" -ForegroundColor $(if ($failCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "Duration:     $([math]::Round($duration.TotalSeconds, 2))s"
Write-Host ''

if ($failCount -gt 0) {
    Write-Host 'SOME TESTS FAILED' -ForegroundColor Red
    exit 1
} else {
    Write-Host 'ALL TESTS PASSED' -ForegroundColor Green
    exit 0
}
