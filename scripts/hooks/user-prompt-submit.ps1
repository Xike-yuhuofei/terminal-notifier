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
Import-Module (Join-Path $LibPath "TabTitleManager.psm1") -Force -ErrorAction SilentlyContinue

try {
    # Read hook input from stdin
    $inputJson = [Console]::In.ReadToEnd()
    $hookData = $inputJson | ConvertFrom-Json

    # 检查持久化标题状态文件
    $stateDir = Join-Path $ModuleRoot ".states"
    $titleFile = Join-Path $stateDir "persistent-title.txt"

    if (Test-Path $titleFile) {
        # 用户提交新提示，清除所有标题（不管是 Stop 还是 Notification）
        Remove-Item $titleFile -Force -ErrorAction SilentlyContinue
    }

    exit 0
}
catch {
    # 不干扰用户提交流程
    exit 0
}
