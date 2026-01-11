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

# Import modules
Import-Module (Join-Path $LibPath "PersistentTitle.psm1") -Force -ErrorAction SilentlyContinue

try {
    # Read hook input from stdin
    $inputJson = [Console]::In.ReadToEnd()
    $hookData = $inputJson | ConvertFrom-Json

    # 清除持久化标题（恢复默认显示）
    Clear-PersistentTitle

    # 清理旧的状态文件（向后兼容）
    $stateDir = Join-Path $ModuleRoot ".states"
    $titleFile = Join-Path $stateDir "persistent-title.txt"
    if (Test-Path $titleFile) {
        Remove-Item $titleFile -Force -ErrorAction SilentlyContinue
    }
    
    # Periodic cleanup (1 in 10 chance to reduce overhead)
    $cleanupRandom = Get-Random -Minimum 1 -Maximum 11
    if ($cleanupRandom -eq 1) {
        Import-Module (Join-Path $LibPath "StateManager.psm1") -Force -ErrorAction SilentlyContinue
        Clear-OldStateFiles -MaxAgeHours 4
    }

    exit 0
}
catch {
    # 不干扰用户提交流程
    exit 0
}
