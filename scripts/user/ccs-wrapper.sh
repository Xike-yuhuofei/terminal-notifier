#!/bin/bash
# ccs-wrapper.sh - Claude Code 环境包装脚本
# 用于确保环境变量正确传递到子进程

set -e

# 🔴 调试：记录脚本执行
echo "[WRAPPER] 脚本已启动" >> ~/ccs-wrapper-debug.log
echo "[WRAPPER] 参数1(ENV_NAME): $1" >> ~/ccs-wrapper-debug.log
echo "[WRAPPER] 参数2(WINDOW_NAME): $2" >> ~/ccs-wrapper-debug.log

# 从参数获取环境和窗口名称
ENV_NAME="$1"
WINDOW_NAME="$2"
shift 2

# 密钥文件路径
KEY_FILE="$HOME/.claude-env-keys"

# 加载密钥
source "$KEY_FILE"
echo "[WRAPPER] 密钥已加载" >> ~/ccs-wrapper-debug.log

# 设置环境变量
case "$ENV_NAME" in
    "GLM")
        export ANTHROPIC_BASE_URL="$GLM_BASE_URL"
        export ANTHROPIC_AUTH_TOKEN="$GLM_AUTH_TOKEN"
        export CLAUDE_ENV_NAME="GLM"
        echo "[WRAPPER] ✅ GLM 环境变量已设置" >> ~/ccs-wrapper-debug.log
        ;;
    "CCClub")
        export ANTHROPIC_BASE_URL="$CCClub_BASE_URL"
        export ANTHROPIC_AUTH_TOKEN="$CCClub_AUTH_TOKEN"
        export CLAUDE_ENV_NAME="CCClub"
        echo "[WRAPPER] ✅ CCClub 环境变量已设置" >> ~/ccs-wrapper-debug.log
        ;;
esac

# 清理临时变量
unset GLM_BASE_URL GLM_AUTH_TOKEN CCClub_BASE_URL CCClub_AUTH_TOKEN

# 设置窗口名称
if [ -n "$WINDOW_NAME" ]; then
    export CLAUDE_WINDOW_NAME="$WINDOW_NAME"
    echo "[WRAPPER] ✅ 窗口名称: $WINDOW_NAME" >> ~/ccs-wrapper-debug.log
fi

echo "[WRAPPER] 最终环境变量:" >> ~/ccs-wrapper-debug.log
echo "CLAUDE_ENV_NAME=$CLAUDE_ENV_NAME" >> ~/ccs-wrapper-debug.log
echo "CLAUDE_WINDOW_NAME=$CLAUDE_WINDOW_NAME" >> ~/ccs-wrapper-debug.log
echo "[WRAPPER] 准备启动 Claude..." >> ~/ccs-wrapper-debug.log

# 设置终端标题
echo -ne "\033]0;$ENV_NAME\007"

# 启动 Claude
exec claude --dangerously-skip-permissions
