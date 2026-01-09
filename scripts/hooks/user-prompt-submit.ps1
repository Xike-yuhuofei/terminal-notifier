# user-prompt-submit.ps1
# Claude Code Hook: UserPromptSubmit
# 在用户每次提交提示时恢复持久化标题
#
# 工作原理：
# 1. Stop Hook 将需要的标题写入状态文件
# 2. UserPromptSubmit Hook 在用户提交提示时读取状态文件并重新设置标题
# 3. 这样可以在主 Shell 进程中设置标题，真正影响 Windows Terminal 显示
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
        try {
            # 读取标题数据
            $titleData = Get-Content $titleFile -Raw | ConvertFrom-Json

            # 检查标题是否过期（超过5分钟自动清除）
            $titleTime = [DateTime]::Parse($titleData.timestamp)
            $elapsed = (Get-Date) - $titleTime

            if ($elapsed.TotalMinutes -lt 5) {
                # 标题未过期，重新设置
                $title = $titleData.title
                $hookType = $titleData.hookType

                # 使用 TabTitleManager 设置标题（在主进程中）
                if ($hookType -eq "Stop") {
                    Set-TabTitle -Title $title | Out-Null
                } elseif ($hookType -eq "Notification") {
                    Set-TabTitle -Title $title | Out-Null
                }
            } else {
                # 标题已过期，清除状态文件
                Remove-Item $titleFile -Force -ErrorAction SilentlyContinue
            }
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
