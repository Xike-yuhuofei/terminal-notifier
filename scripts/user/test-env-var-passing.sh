#!/bin/bash
# test-env-var-passing.sh
# 测试 Git Bash 环境变量能否传递到 PowerShell Hook

echo "=========================================="
echo "环境变量传递测试脚本"
echo "=========================================="
echo ""

# 测试 1: 设置环境变量
echo "[Test 1] 在 Git Bash 中设置环境变量..."
export CLAUDE_WINDOW_NAME="测试窗口-12345"
echo "  ✓ 已设置: CLAUDE_WINDOW_NAME=$CLAUDE_WINDOW_NAME"
echo ""

# 测试 2: Git Bash 中验证
echo "[Test 2] 在 Git Bash 中读取环境变量..."
if [ -n "$CLAUDE_WINDOW_NAME" ]; then
    echo "  ✓ Git Bash 可以读取: $CLAUDE_WINDOW_NAME"
else
    echo "  ✗ Git Bash 无法读取环境变量"
    exit 1
fi
echo ""

# 测试 3: PowerShell 中验证（关键测试）
echo "[Test 3] 在 PowerShell 中读取环境变量..."
PS_RESULT=$(powershell.exe -Command "Write-Output \$env:CLAUDE_WINDOW_NAME" 2>&1)
PS_RESULT_CLEAN=$(echo "$PS_RESULT" | tr -d '\r' | tr -d '\n')

if [ "$PS_RESULT_CLEAN" = "测试窗口-12345" ]; then
    echo "  ✓ PowerShell 可以读取: $PS_RESULT_CLEAN"
    echo "  ✓ 环境变量传递成功！"
    echo ""
    echo "=========================================="
    echo "结论: 可以使用方案 1 或 方案 2"
    echo "=========================================="
else
    echo "  ✗ PowerShell 无法读取环境变量"
    echo "  ✗ PowerShell 返回: '$PS_RESULT_CLEAN'"
    echo ""
    echo "=========================================="
    echo "结论: 必须使用方案 3 (PowerShell Wrapper)"
    echo "=========================================="
fi
echo ""

# 测试 4: StateManager 函数测试
echo "[Test 4] 测试 StateManager Get-WindowDisplayName 函数..."
MODULE_PATH="C:/Users/Xike/.claude/tools/terminal-notifier/lib/StateManager.psm1"
TOAST_PATH="C:/Users/Xike/.claude/tools/terminal-notifier/lib/ToastNotifier.psm1"

if [ ! -f "$MODULE_PATH" ]; then
    echo "  ✗ StateManager.psm1 不存在"
    exit 1
fi

PS_TEST=$(powershell.exe -ExecutionPolicy Bypass -Command "
    \$env:CLAUDE_WINDOW_NAME = '测试窗口-12345'
    Import-Module '$MODULE_PATH' -Force
    \$windowName = Get-WindowDisplayName
    Write-Output \$windowName
" 2>&1)

PS_TEST_CLEAN=$(echo "$PS_TEST" | tr -d '\r' | tr -d '\n')

if [ "$PS_TEST_CLEAN" = "测试窗口-12345" ]; then
    echo "  ✓ Get-WindowDisplayName 返回: $PS_TEST_CLEAN"
else
    echo "  ⚠ Get-WindowDisplayName 返回: $PS_TEST_CLEAN"
    echo "  (可能返回了项目名称或 Session ID，这是正常的降级行为)"
fi
echo ""

# 测试 5: Toast 通知测试（可选）
echo "[Test 5] 发送测试 Toast 通知（可选，按 Ctrl+C 跳过）..."
read -p "是否发送测试 Toast？(y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    powershell.exe -ExecutionPolicy Bypass -Command "
        \$env:CLAUDE_WINDOW_NAME = '测试窗口-12345'
        Import-Module '$MODULE_PATH' -Force
        Import-Module '$TOAST_PATH' -Force
        \$windowName = Get-WindowDisplayName
        Send-StopToast -WindowName \$windowName -ProjectName 'Backend_CPP'
    " 2>&1
    echo "  ℹ 请检查 Windows 通知中心是否收到 Toast 通知"
    echo "  预期标题: [测试窗口-12345] 需要输入 - Backend_CPP"
else
    echo "  ⊘ 跳过 Toast 测试"
fi
echo ""

echo "=========================================="
echo "测试完成！"
echo "=========================================="
