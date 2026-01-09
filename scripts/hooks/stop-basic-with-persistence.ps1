# stop-basic-with-persistence.ps1
# Claude Code Hook: Stop (Basic Version with Persistent Title)
# 基础版：音效 + Toast + 持久化窗口标题
#
# 功能：
# - 音效通知（系统提示音）
# - Windows Toast 通知
# - 自定义窗口标题显示（使用 ccs 命令设置的窗口名称）
# - 持久化标题（防止被其他进程覆盖）
#
# 不包含：
# - 状态管理
# - OSC 标签页颜色

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
Import-Module (Join-Path $LibPath "StateManager.psm1") -Force -ErrorAction SilentlyContinue
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
    }
    catch {
        # Fallback to project name
        $windowName = $projectName
    }

    # === BASIC VERSION: Sound + Toast + Persistent Window Title ===

    # 1. Build title
    if ($windowName -and $windowName -ne $projectName) {
        $title = "[⚠️ $windowName] 需要输入 - $projectName"
    } else {
        $title = "[⚠️] 需要输入 - $projectName"
    }

    # 2. Set title using multiple methods for maximum visibility
    try {
        # Method 1: Direct RawUI
        $Host.UI.RawUI.WindowTitle = $title

        # Method 2: OSC sequence (for Windows Terminal)
        $ESC = [char]27
        $BEL = [char]7
        Write-Host "$ESC]0;$title$BEL" -NoNewline

        # Method 3: Create a persistent title file
        $stateDir = Join-Path $ModuleRoot ".states"
        if (-not (Test-Path $stateDir)) {
            New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
        }

        $titleFile = Join-Path $stateDir "current-title.txt"
        $title | Out-File -FilePath $titleFile -Encoding UTF8 -Force

        # Method 4: Start background job to persist title (if possible)
        $persistScript = {
            param($targetTitle, $duration)
            $endTime = (Get-Date).AddSeconds($duration)
            while ((Get-Date) -lt $endTime) {
                try {
                    $Host.UI.RawUI.WindowTitle = $targetTitle
                }
                catch {
                    # Ignore errors in background job
                }
                Start-Sleep -Milliseconds 500
            }
        }

        # Start background job for 10 seconds
        Start-Job -ScriptBlock $persistScript -ArgumentList $title, 10 -Name "PersistTitle" -ErrorAction SilentlyContinue | Out-Null

    }
    catch {
        # Fallback: at least try direct RawUI
        try {
            $Host.UI.RawUI.WindowTitle = $title
        }
        catch {
            # Last resort: silent failure
        }
    }

    # 3. Ring bell for attention (1 time)
    Invoke-TerminalBell -Times 1 -SoundType 'Asterisk'

    # 4. Send Windows Toast notification
    try {
        Send-StopToast -WindowName $windowName -ProjectName $projectName
    }
    catch {
        # Toast failure should not block Hook execution
    }

    exit 0
}
catch {
    # Don't interfere with Claude's stop behavior on errors
    exit 0
}
