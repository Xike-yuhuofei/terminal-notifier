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

# Import modules
Import-Module (Join-Path $LibPath "NotificationEnhancements.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $LibPath "ToastNotifier.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $LibPath "TabTitleManager.psm1") -Force -ErrorAction SilentlyContinue

try {
    # Read hook input from stdin
    $inputJson = [Console]::In.ReadToEnd()
    $hookData = $inputJson | ConvertFrom-Json

    $cwd = $hookData.cwd
    $projectName = Split-Path -Leaf $cwd

    # Get custom window name (set by ccs command)
    $windowName = ""
    try {
        $windowName = Get-WindowDisplayName

        # 如果Get-WindowDisplayName返回项目名称，尝试从保存的文件读取自定义标题
        if ($windowName -eq $projectName) {
            $stateDir = Join-Path $ModuleRoot ".states"
            $originalTitleFile = Join-Path $stateDir "original-title.txt"

            if (Test-Path $originalTitleFile) {
                $savedTitle = Get-Content $originalTitleFile -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
                if ($savedTitle -and $savedTitle -ne "" -and $savedTitle -ne $projectName) {
                    $windowName = $savedTitle
                }
            }
        }
    }
    catch {
        # Fallback to project name
        $windowName = $projectName
    }

    # === 1. 构建标题 ===
    # 读取 SessionStart 保存的原始标题
    $stateDir = Join-Path $ModuleRoot ".states"
    $originalTitleFile = Join-Path $stateDir "original-title.txt"

    if (Test-Path $originalTitleFile) {
        # 使用原始标题（ccs 设置的）
        $originalTitle = Get-Content $originalTitleFile -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
        $title = "[📢] $originalTitle"
    } else {
        # 回退到默认逻辑
        if ($windowName -and $windowName -ne $projectName) {
            $title = "[📢 $windowName] 新通知 - $projectName"
        } else {
            $title = "[📢] 新通知 - $projectName"
        }
    }

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

    # === 4. 播放音效 ===
    Invoke-TerminalBell -Times 1 -SoundType 'Asterisk'

    # === 5. 发送 Toast 通知 ===
    try {
        # 如果有原始标题，传递给 Toast 通知
        if (Test-Path $originalTitleFile) {
            $originalTitle = Get-Content $originalTitleFile -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
            Send-NotificationToast -WindowName $originalTitle -ProjectName $projectName
        } else {
            Send-NotificationToast -WindowName $windowName -ProjectName $projectName
        }
    }
    catch {
        # Toast 失败不应阻止 Hook 执行
    }

    exit 0
}
catch {
    # 不干扰 Claude 的 notification 行为
    exit 0
}
