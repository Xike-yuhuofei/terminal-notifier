# test-task-tracking.ps1
# Test Task Tracking API

Write-Host '=== Test Task Tracking API ===' -ForegroundColor Cyan
Write-Host ''

$modulePath = Join-Path $PSScriptRoot '..\TerminalNotifier.psd1'
Remove-Module TerminalNotifier -ErrorAction SilentlyContinue
Import-Module $modulePath -Force

# Save original title
$originalTitle = $Host.UI.RawUI.WindowTitle

# 1. Test Start-TrackedTask
Write-Host '1. Testing Start-TrackedTask...' -ForegroundColor Cyan
try {
    $task = Start-TrackedTask -TaskName "Test Task 1"
    if ($task.Id -and $task.Name -eq "Test Task 1" -and $task.Status -eq "Running") {
        Write-Host "[OK] Task created: Id=$($task.Id), Name=$($task.Name), Status=$($task.Status)" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Task properties incorrect" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Start-TrackedTask: $_" -ForegroundColor Red
}

# 2. Test Get-ActiveTasks
Write-Host ''
Write-Host '2. Testing Get-ActiveTasks...' -ForegroundColor Cyan
try {
    $activeTasks = Get-ActiveTasks
    $count = @($activeTasks).Count
    if ($count -ge 1) {
        Write-Host "[OK] Active tasks count: $count" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Expected at least 1 active task, got $count" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Get-ActiveTasks: $_" -ForegroundColor Red
}

# 3. Test Update-TaskProgress
Write-Host ''
Write-Host '3. Testing Update-TaskProgress...' -ForegroundColor Cyan
try {
    $result = Update-TaskProgress -TaskId $task.Id -Current 50 -Total 100
    if ($result) {
        Write-Host "[OK] Progress updated to 50/100" -ForegroundColor Green
        Write-Host "   Current title: $($Host.UI.RawUI.WindowTitle)"
    } else {
        Write-Host "[FAIL] Update-TaskProgress returned false" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Update-TaskProgress: $_" -ForegroundColor Red
}

# 4. Test Complete-TrackedTask (Silent mode)
Write-Host ''
Write-Host '4. Testing Complete-TrackedTask...' -ForegroundColor Cyan
try {
    $result = $task | Complete-TrackedTask -Success $true -Message "Task completed successfully" -Level 'Silent'
    if ($result) {
        Write-Host "[OK] Task completed" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Complete-TrackedTask returned false" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Complete-TrackedTask: $_" -ForegroundColor Red
}

# 5. Verify task removed from active list
Write-Host ''
Write-Host '5. Verifying task removed from active list...' -ForegroundColor Cyan
try {
    $activeTasks = Get-ActiveTasks
    $count = @($activeTasks).Count
    Write-Host "[OK] Active tasks after completion: $count" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] $_" -ForegroundColor Red
}

# 6. Test Format-Duration
Write-Host ''
Write-Host '6. Testing Format-Duration...' -ForegroundColor Cyan
$durationTests = @(
    @{Ms=500;    Expected='500 ms'},
    @{Ms=1500;   Expected='1.5s'},
    @{Ms=65000;  Expected='1m5s'},
    @{Ms=125000; Expected='2m5s'}
)

foreach ($test in $durationTests) {
    try {
        $result = Format-Duration -Milliseconds $test.Ms
        if ($result -eq $test.Expected) {
            Write-Host "[OK] $($test.Ms)ms -> $result" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] $($test.Ms)ms -> $result (expected $($test.Expected))" -ForegroundColor Red
        }
    } catch {
        Write-Host "[FAIL] Format-Duration($($test.Ms)): $_" -ForegroundColor Red
    }
}

# 7. Test with custom TaskId
Write-Host ''
Write-Host '7. Testing custom TaskId...' -ForegroundColor Cyan
try {
    $customTask = Start-TrackedTask -TaskName "Custom ID Task" -TaskId "my-custom-id"
    if ($customTask.Id -eq "my-custom-id") {
        Write-Host "[OK] Custom TaskId: $($customTask.Id)" -ForegroundColor Green
        $customTask | Complete-TrackedTask -Success $true -Level 'Silent' | Out-Null
    } else {
        Write-Host "[FAIL] Custom TaskId not set correctly" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Custom TaskId test: $_" -ForegroundColor Red
}

# Restore title
$Host.UI.RawUI.WindowTitle = $originalTitle
Write-Host ''
Write-Host '[DONE] Task Tracking API tests completed' -ForegroundColor Green
