# user-prompt-submit.ps1
# Claude Code Hook: UserPromptSubmit
# 在用户提交新提示时清除标题
#
# 工作原理：
# 1. Stop/Notification Hook 将标题写入状态文件
# 2. UserPromptSubmit Hook 在用户提交提示时删除状态文件
# 3. 标题自然恢复，不再显示 [⚠️] 或 [📢]
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

# Import required modules using the same approach as Notification Hook
Import-HookModules -LibPath $LibPath -Modules @("StateManager", "PersistentTitle", "TabTitleManager", "NotificationEnhancements")

# Log successful imports
$importedModules = @("StateManager", "PersistentTitle", "TabTitleManager", "NotificationEnhancements")
$debugLog = Join-Path $ModuleRoot ".states/hook-debug.log"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
"[$ts] UserPromptSubmit Hook: Successfully imported modules: $($importedModules -join ', ')" | Out-File -FilePath $debugLog -Append -Encoding UTF8

# Log successful imports
$debugLog = Join-Path $ModuleRoot ".states/hook-debug.log"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
"[$ts] UserPromptSubmit Hook: Successfully imported modules: $($importedModules -join ', ')" | Out-File -FilePath $debugLog -Append -Encoding UTF8

try {
    # === DEBUG LOGGING START ===
    $stateDir = Join-Path $ModuleRoot ".states"
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }
    $debugLog = Join-Path $stateDir "hook-debug.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    "[$timestamp] === UserPromptSubmit Hook START ===" | Out-File -FilePath $debugLog -Append -Encoding UTF8
    "[$timestamp] ModuleRoot: $ModuleRoot" | Out-File -FilePath $debugLog -Append -Encoding UTF8
    # === DEBUG LOGGING END ===

    # Read hook input from stdin
    $inputJson = [Console]::In.ReadToEnd()
    
    # DEBUG: Log input
    "[$timestamp] Input JSON: $inputJson" | Out-File -FilePath $debugLog -Append -Encoding UTF8

    $hookData = $inputJson | ConvertFrom-Json
    
    # DEBUG: Log parsed data
    if ($hookData) {
        "[$timestamp] Session ID: $($hookData.session_id), CWD: $($hookData.cwd)" | Out-File -FilePath $debugLog -Append -Encoding UTF8
    }

    # 获取窗口名 (使用与Notification Hook相同的方法)
    # Note: $hookData is already parsed above
    $cwd = $hookData.cwd
    $projectName = Split-Path -Leaf $cwd
    $windowName = Get-WindowNameWithFallback -ProjectName $projectName -ModuleRoot $ModuleRoot
    
    # DEBUG: Log window name
    "[$timestamp] WindowName: $windowName" | Out-File -FilePath $debugLog -Append -Encoding UTF8
    
    # 检查是否是第一次运行（SessionStart 后第一次提交）
    $stateDir = Join-Path $ModuleRoot ".states"
    $firstRunFile = Join-Path $stateDir "first-run.txt"
    
    if (-not (Test-Path $firstRunFile)) {
        # 第一次运行：设置标题为 [ Running ] 窗口名
        $runningTitle = "[ Running ] $windowName"
        
        # === 三重标题设置策略（完全参考Notification Hook）===
        try {
            # 方法1: 使用OSC转义序列
            Set-TabTitle -Title $runningTitle
            
            # 方法2: 直接设置RawUI标题
            $Host.UI.RawUI.WindowTitle = $runningTitle
            
            # 方法3: 输出OSC序列（备用方法）
            $ESC = [char]27
            $BEL = [char]7
            Write-Host "$ESC]0;$runningTitle$BEL" -NoNewline
        }
        catch {
            # 记录标题设置失败
            "[$timestamp] Failed to set title: $($_.Exception.Message)" | Out-File -FilePath $debugLog -Append -Encoding UTF8
        }
        
        # === 持久化机制（完全参考Notification Hook）===
        try {
            # 写入持久化状态文件
            $titleFile = Join-Path $stateDir "persistent-title.txt"
            $titleData = @{
                title = $runningTitle
                hookType = "UserPromptSubmit"
                timestamp = (Get-Date).ToString("o")
            } | ConvertTo-Json -Compress

            $titleData | Out-File -FilePath $titleFile -Encoding UTF8 -Force

            # 启动后台任务保持标题持久化（直到会话结束）
            $persistScript = {
                param($titleFilePath, $debugLogPath)
                # 持续运行，直到文件被删除或进程结束
                while (Test-Path $titleFilePath) {
                    # 每30秒重新设置一次标题，防止被覆盖
                    Start-Sleep -Seconds 30
                    
                    # 重新读取标题并设置
                    if (Test-Path $titleFilePath) {
                        try {
                            $titleData = Get-Content $titleFilePath -Raw | ConvertFrom-Json
                            $title = $titleData.title
                            
                            # 重新设置标题
                            $ESC = [char]27
                            $BEL = [char]7
                            Write-Host "$ESC]0;$title$BEL" -NoNewline
                        }
                        catch {
                            # 记录错误但继续运行
                            $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                            "[$ts] Persistence job error: $($_.Exception.Message)" | Out-File -FilePath $debugLogPath -Append -Encoding UTF8
                        }
                    }
                }
            }

            Start-Job -ScriptBlock $persistScript -ArgumentList $titleFile, $debugLog -Name "PersistUserPromptTitle" -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            # 状态文件写入失败不应阻止 Hook 执行
            "[$timestamp] Persistence setup failed: $($_.Exception.Message)" | Out-File -FilePath $debugLog -Append -Encoding UTF8
        }
        
        # 标记已经运行过
        "1" | Out-File -FilePath $firstRunFile -Force -Encoding UTF8
    } else {
        # 后续运行：清除持久化标题（恢复默认显示）
        try {
            Clear-PersistentTitle
        }
        catch {
            "[$timestamp] Clear-PersistentTitle failed: $($_.Exception.Message)" | Out-File -FilePath $debugLog -Append -Encoding UTF8
        }
    }

    # 清理旧的状态文件（向后兼容）- 仅清理非当前会话的状态
    $titleFile = Join-Path $stateDir "persistent-title.txt"
    if (Test-Path $titleFile) {
        try {
            $existingTitleData = Get-Content $titleFile -Raw | ConvertFrom-Json
            if ($existingTitleData.hookType -ne "UserPromptSubmit") {
                Remove-Item $titleFile -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            # 如果文件格式无效，删除它
            Remove-Item $titleFile -Force -ErrorAction SilentlyContinue
        }
    }

    # Periodic cleanup (1 in 10 chance to reduce overhead)
    $cleanupRandom = Get-Random -Minimum 1 -Maximum 11
    if ($cleanupRandom -eq 1) {
        Import-Module (Join-Path $LibPath "StateManager.psm1") -Force -ErrorAction SilentlyContinue
        Clear-OldStateFiles -MaxAgeHours 4
    }

    # DEBUG: Log end
    "[$timestamp] === UserPromptSubmit Hook END ===" | Out-File -FilePath $debugLog -Append -Encoding UTF8

    # Output result for Claude Code
    $output = @{
        success = $true
        message = "User prompt submitted"
    } | ConvertTo-Json -Compress

    Write-Output $output
    exit 0
}
catch {
    # 记录错误但不干扰用户提交流程
    $errorLog = Join-Path $ModuleRoot ".states/hook-debug.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    "[$timestamp] ERROR: $($_.Exception.Message)" | Out-File -FilePath $errorLog -Append -Encoding UTF8
    "[$timestamp] Stack: $($_.ScriptStackTrace)" | Out-File -FilePath $errorLog -Append -Encoding UTF8
    
    # 输出成功结果给 Claude Code
    $output = @{
        success = $true
        message = "User prompt submitted with minor errors"
    } | ConvertTo-Json -Compress

    Write-Output $output
    exit 0
}
