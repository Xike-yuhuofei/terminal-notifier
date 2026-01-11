# notification-with-persistence.ps1
# Claude Code Hook: Notification (带 UserPromptSubmit 持久化)
#
# 工作原理：
# 1. 设置标题（即时效果，可能在子进程中无效）
# 2. 写入状态文件（供 UserPromptSubmit Hook 使用）
# 3. 播放音效
# 4. 发送 Toast 通知
# 5. 5秒后自动清除标题
#
#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# Get script and module paths
$ScriptDir = Split-Path -Parent $PSCommandPath
$ModuleRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$LibPath = Join-Path $ModuleRoot "lib"

# Import HookBase module first
Import-Module (Join-Path $LibPath "HookBase.psm1") -Force -Global -ErrorAction SilentlyContinue

# Import other required modules with proper error handling
$modulesToImport = @("NotificationEnhancements", "ToastNotifier", "TabTitleManager")
$importedModules = @()
foreach ($mod in $modulesToImport) {
    $modPath = Join-Path $LibPath "$mod.psm1"
    if (Test-Path $modPath) {
        try {
            Import-Module $modPath -Force -Global -ErrorAction Stop
            $importedModules += $mod
        }
        catch {
            # Log module import failure but don't fail the hook
            $debugLog = Join-Path $ModuleRoot ".states/hook-debug.log"
            $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            "[$ts] Notification Hook: Failed to import $mod : $($_.Exception.Message)" | Out-File -FilePath $debugLog -Append -Encoding UTF8
        }
    }
    else {
        $debugLog = Join-Path $ModuleRoot ".states/hook-debug.log"
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        "[$ts] Notification Hook: Module file not found: $modPath" | Out-File -FilePath $debugLog -Append -Encoding UTF8
    }
}

# Log successful imports
$debugLog = Join-Path $ModuleRoot ".states/hook-debug.log"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
"[$ts] Notification Hook: Successfully imported modules: $($importedModules -join ', ')" | Out-File -FilePath $debugLog -Append -Encoding UTF8

try {
    # === DEBUG LOGGING START ===
    $stateDir = Join-Path $ModuleRoot ".states"
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }
    $debugLog = Join-Path $stateDir "hook-debug.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    "[$timestamp] === Notification Hook START ===" | Out-File -FilePath $debugLog -Append -Encoding UTF8
    "[$timestamp] ModuleRoot: $ModuleRoot" | Out-File -FilePath $debugLog -Append -Encoding UTF8
    # === DEBUG LOGGING END ===

    # Initialize environment
    $inputJson = [Console]::In.ReadToEnd()

    # DEBUG: Log input
    "[$timestamp] Input JSON: $inputJson" | Out-File -FilePath $debugLog -Append -Encoding UTF8

    $hookData = $inputJson | ConvertFrom-Json
    $cwd = $hookData.cwd
    $projectName = Split-Path -Leaf $cwd

    # DEBUG: Log parsed data
    "[$timestamp] CWD: $cwd, Project: $projectName" | Out-File -FilePath $debugLog -Append -Encoding UTF8

    # Get window name with fallback
    $windowName = Get-WindowNameWithFallback -ProjectName $projectName -ModuleRoot $ModuleRoot

    # DEBUG: Log window name
    "[$timestamp] WindowName: $windowName" | Out-File -FilePath $debugLog -Append -Encoding UTF8

    # Build title
    $originalTitle = Get-OriginalTitleFromFile -ModuleRoot $ModuleRoot
    $title = Build-NotificationTitle -WindowName $windowName -ProjectName $projectName -OriginalTitle $originalTitle

    # DEBUG: Log title
    "[$timestamp] OriginalTitle: $originalTitle, Title: $title" | Out-File -FilePath $debugLog -Append -Encoding UTF8

    # === 2. 尝试即时设置标题（可能无效，因为是在子进程中）===
    try {
        $Host.UI.RawUI.WindowTitle = $title
        $ESC = [char]27
        $BEL = [char]7
        Write-Host "$ESC]0;$title$BEL" -NoNewline
    }
    catch {
        # 忽略标题设置失败
    }

    # === 3. 写入持久化状态文件（供 UserPromptSubmit Hook 使用）===
    try {
        $stateDir = Join-Path $ModuleRoot ".states"
        if (-not (Test-Path $stateDir)) {
            New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
        }

        $titleFile = Join-Path $stateDir "persistent-title.txt"
        $titleData = @{
            title = $title
            hookType = "Notification"
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json -Compress

        $titleData | Out-File -FilePath $titleFile -Encoding UTF8 -Force

        # 启动后台任务在5秒后清除标题
        $clearScript = {
            param($titleFilePath)
            Start-Sleep -Seconds 5
            if (Test-Path $titleFilePath) {
                Remove-Item $titleFilePath -Force -ErrorAction SilentlyContinue
            }
        }

        Start-Job -ScriptBlock $clearScript -ArgumentList $titleFile -Name "ClearNotificationTitle" -ErrorAction SilentlyContinue | Out-Null
    }
    catch {
        # 状态文件写入失败不应阻止 Hook 执行
    }

    # === 4. 播放音效（带错误处理）===
    try {
        if (Get-Command Invoke-TerminalBell -ErrorAction SilentlyContinue) {
            Invoke-TerminalBell -Times 1 -SoundType 'Asterisk'
            "[$timestamp] Bell played successfully" | Out-File -FilePath $debugLog -Append -Encoding UTF8
        }
        else {
            "[$timestamp] Bell function not available, skipping sound" | Out-File -FilePath $debugLog -Append -Encoding UTF8
        }
    }
    catch {
        "[$timestamp] Bell play failed: $($_.Exception.Message)" | Out-File -FilePath $debugLog -Append -Encoding UTF8
    }

    # === 5. 发送 Toast 通知（带错误处理）===
    try {
        if (Get-Command Invoke-ToastWithFallback -ErrorAction SilentlyContinue) {
            Invoke-ToastWithFallback -ScriptBlock {
                if ($originalTitle) {
                    Send-NotificationToast -WindowName $originalTitle -ProjectName $projectName
                } else {
                    Send-NotificationToast -WindowName $windowName -ProjectName $projectName
                }
            }
            "[$timestamp] Toast sent successfully" | Out-File -FilePath $debugLog -Append -Encoding UTF8
        }
        else {
            "[$timestamp] Toast function not available, skipping notification" | Out-File -FilePath $debugLog -Append -Encoding UTF8
        }
    }
    catch {
        "[$timestamp] Toast send failed: $($_.Exception.Message)" | Out-File -FilePath $debugLog -Append -Encoding UTF8
    }

    # DEBUG: Log end
    "[$timestamp] === Notification Hook END ===" | Out-File -FilePath $debugLog -Append -Encoding UTF8

    exit 0
}
catch {
    # DEBUG: Log error
    $errorLog = Join-Path $ModuleRoot ".states/hook-debug.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    "[$timestamp] ERROR: $($_.Exception.Message)" | Out-File -FilePath $errorLog -Append -Encoding UTF8
    "[$timestamp] Stack: $($_.ScriptStackTrace)" | Out-File -FilePath $errorLog -Append -Encoding UTF8
    # 不干扰 Claude 的 notification 行为
    exit 0
}
