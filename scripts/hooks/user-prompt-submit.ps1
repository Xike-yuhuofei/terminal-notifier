# user-prompt-submit.ps1
# Claude Code Hook: UserPromptSubmit
# 在用户提交新提示时清除 Stop 标题
#
# 工作原理：
# - 检查是否存在 Stop Hook 创建的持久化状态文件
# - 如果存在，删除状态文件，让标题自然恢复
# - 这样可以清除 "[⚠️] 需要输入" 这样的 Stop 标题

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

    $cwd = $hookData.cwd
    $projectName = Split-Path -Leaf $cwd

    # 检查 Stop Hook 创建的持久化状态文件
    $stateDir = Join-Path $ModuleRoot ".states"
    $titleFile = Join-Path $stateDir "stop-title.txt"

    if (Test-Path $titleFile) {
        try {
            # 读取标题数据
            $titleData = Get-Content $titleFile -Raw | ConvertFrom-Json

            # 删除状态文件（这会清除 Stop 标题）
            Remove-Item $titleFile -Force -ErrorAction SilentlyContinue

            # 可选：设置一个恢复标题，或者让系统自然恢复
            # 这里选择让系统自然恢复，不设置任何标题
        }
        catch {
            # 状态文件损坏，删除
            Remove-Item $titleFile -Force -ErrorAction SilentlyContinue
        }
    }

    exit 0
}
catch {
    # 不干扰用户提交流程
    exit 0
}
