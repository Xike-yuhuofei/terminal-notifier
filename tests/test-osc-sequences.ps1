# test-osc-sequences.ps1
# Test OSC Sequence Functions

Write-Host '=== Test OSC Sequences ===' -ForegroundColor Cyan
Write-Host ''

$modulePath = Join-Path $PSScriptRoot '..\TerminalNotifier.psd1'
Remove-Module TerminalNotifier -ErrorAction SilentlyContinue
Import-Module $modulePath -Force

# Save original title
$originalTitle = $Host.UI.RawUI.WindowTitle

# 1. Test Test-OscSupport
Write-Host '1. Testing Test-OscSupport...' -ForegroundColor Cyan
try {
    $oscSupported = Test-OscSupport
    Write-Host "[OK] OSC Support: $oscSupported" -ForegroundColor Green
    Write-Host "   Environment: WT_SESSION=$($env:WT_SESSION), TERM_PROGRAM=$($env:TERM_PROGRAM)"
} catch {
    Write-Host "[FAIL] Test-OscSupport: $_" -ForegroundColor Red
}

# 2. Test Send-OscTitle
Write-Host ''
Write-Host '2. Testing Send-OscTitle...' -ForegroundColor Cyan
try {
    $result = Send-OscTitle -Title "OSC Title Test"
    Write-Host "[OK] Send-OscTitle executed (returned: $result)" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Send-OscTitle: $_" -ForegroundColor Red
}

# 3. Test Send-OscTabColor
Write-Host ''
Write-Host '3. Testing Send-OscTabColor...' -ForegroundColor Cyan
$colors = @('red', 'green', 'blue', 'yellow', 'black')
foreach ($color in $colors) {
    try {
        $result = Send-OscTabColor -Color $color
        Write-Host "[OK] Color=$color (returned: $result)" -ForegroundColor Green
        Start-Sleep -Milliseconds 200
    } catch {
        Write-Host "[FAIL] Send-OscTabColor($color): $_" -ForegroundColor Red
    }
}

# 4. Test Set-NotificationVisual
Write-Host ''
Write-Host '4. Testing Set-NotificationVisual...' -ForegroundColor Cyan
$visualTests = @(
    @{State='blue';   Title='Working...'},
    @{State='red';    Title='Error!'},
    @{State='green';  Title='Success!'},
    @{State='yellow'; Title='Warning!'}
)

foreach ($test in $visualTests) {
    try {
        $result = Set-NotificationVisual -State $test.State -Title $test.Title -ProjectName 'TestProject'
        Write-Host "[OK] State=$($test.State), Title=$($test.Title)" -ForegroundColor Green
        Start-Sleep -Milliseconds 300
    } catch {
        Write-Host "[FAIL] Set-NotificationVisual: $_" -ForegroundColor Red
    }
}

# 5. Test Set-TermTitleLegacy
Write-Host ''
Write-Host '5. Testing Set-TermTitleLegacy (fallback)...' -ForegroundColor Cyan
try {
    Set-TermTitleLegacy -Title "Legacy Title Test"
    Write-Host "[OK] Legacy title set" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Set-TermTitleLegacy: $_" -ForegroundColor Red
}

# 6. Test ANSI helpers
Write-Host ''
Write-Host '6. Testing ANSI helpers...' -ForegroundColor Cyan
try {
    Send-AnsiReset
    Write-Host "[OK] Send-AnsiReset" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Send-AnsiReset: $_" -ForegroundColor Red
}

try {
    Send-AnsiBold
    Write-Host "[OK] Send-AnsiBold" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Send-AnsiBold: $_" -ForegroundColor Red
}

try {
    Send-AnsiBlink
    Write-Host "[OK] Send-AnsiBlink" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Send-AnsiBlink: $_" -ForegroundColor Red
}

# 7. Test Reset-TerminalVisual
Write-Host ''
Write-Host '7. Testing Reset-TerminalVisual...' -ForegroundColor Cyan
try {
    Reset-TerminalVisual -ProjectName 'TestProject'
    Write-Host "[OK] Visual reset" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Reset-TerminalVisual: $_" -ForegroundColor Red
}

# Restore title
$Host.UI.RawUI.WindowTitle = $originalTitle
Write-Host ''
Write-Host '[DONE] OSC Sequences tests completed' -ForegroundColor Green
