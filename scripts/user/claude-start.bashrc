# Claude Code 启动函数（添加到 ~/.bashrc）
# 支持多环境切换：GLM（简单任务）和 CCClub（复杂任务）

# ============================================
# 安全检查函数
# ============================================
check_key_file_security() {
    local key_file="$1"

    if [ ! -f "$key_file" ]; then
        echo "❌ 错误：密钥文件不存在"
        echo "   位置：$key_file"
        echo ""
        echo "请按以下步骤创建："
        echo "1. 复制模板：cp ~/.claude/tools/terminal-notifier/scripts/user/.claude-env-keys.template ~/.claude-env-keys"
        echo "2. 编辑文件：nano ~/.claude-env-keys"
        echo "3. 填写你的 GLM 和 CCClub 密钥"
        echo "4. 设置权限：chmod 600 ~/.claude-env-keys"
        return 1
    fi

    # 检查文件权限（应该是 600，即仅所有者可读写）
    # 注意：Windows/MSYS 环境下权限检查会放宽，因为 NTFS 使用 ACL 而非 Unix 权限位
    if command -v stat &> /dev/null; then
        local perms=$(stat -c %a "$key_file" 2>/dev/null || stat -f %A "$key_file" 2>/dev/null)

        # 检测是否为 Windows 环境
        local is_windows=false
        case "$(uname -s)" in
            MINGW*|MSYS*|CYGWIN*|Windows*|WINNT*)
                is_windows=true
                ;;
        esac

        if [ "$is_windows" = true ]; then
            # Windows 环境：放宽权限检查（仅警告，不阻止）
            # Windows 使用 ACL 安全模型，chmod 600 不完全生效
            if [ "$perms" != "600" ] && [ "$perms" != "644" ]; then
                echo "⚠️  警告：密钥文件权限过于开放 ($perms)"
                echo "   提示：Windows 环境下建议确保文件位于用户目录下"
            fi
        else
            # Unix/Linux/macOS 环境：严格检查
            if [ "$perms" != "600" ]; then
                echo "⚠️  警告：密钥文件权限不安全 ($perms)"
                echo "   正在自动修复权限为 600..."
                chmod 600 "$key_file"
                if [ $? -eq 0 ]; then
                    echo "   ✓ 权限已修复"
                else
                    echo "   ❌ 权限修复失败，请手动执行：chmod 600 $key_file"
                    return 1
                fi
            fi
        fi
    fi

    return 0
}

# ============================================
# Claude Code 启动函数（支持环境选择）
# ============================================
ccs-start() {
    # 🔴 调试：函数开始
    echo "[1] ccs-start 函数已调用" >> ~/ccs-debug.log
    echo "[1] 参数: $@" >> ~/ccs-debug.log
    echo "[1] 当前时间: $(date)" >> ~/ccs-debug.log

    # 显示帮助信息
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "用法："
        echo "  ccs-start                       # 交互式选择环境和窗口名称"
        echo "  ccs-start glm                  # 使用 GLM 环境"
        echo "  ccs-start ccclub               # 使用 CCClub 环境"
        echo "  ccs-start glm \"编译测试\"        # 指定环境和窗口名称"
        echo ""
        echo "环境说明："
        echo "  GLM     - 适用于简单任务（快速、成本低）"
        echo "  CCClub  - 适用于复杂任务（强大、能力全面）"
        echo ""
        echo "窗口名称会显示在 Toast 通知中，用于区分多个 Claude Code 实例。"
        return
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Claude Code 多环境启动器"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # ========================================
    # 步骤 1：选择运行环境
    # ========================================
    echo "[2] 开始选择环境" >> ~/ccs-debug.log

    local ENV_CHOICE=""
    local ENV_NAME=""

    # 检查命令行参数
    echo "[2] 检查参数 \$1: $1" >> ~/ccs-debug.log

    if [ "$1" = "glm" ] || [ "$1" = "GLM" ]; then
        ENV_CHOICE="1"
        ENV_NAME="GLM"
        echo "[2] 选择 GLM（参数）" >> ~/ccs-debug.log
        shift  # 移除环境参数，保留窗口名称参数
    elif [ "$1" = "ccclub" ] || [ "$1" = "CCClub" ] || [ "$1" = "cc" ]; then
        ENV_CHOICE="2"
        ENV_NAME="CCClub"
        echo "[2] 选择 CCClub（参数）" >> ~/ccs-debug.log
        shift
    else
        # 交互式询问
        echo "请选择运行环境："
        echo ""
        echo "  1) GLM     - 简单任务（快速、成本低）"
        echo "  2) CCClub  - 复杂任务（强大、能力全面）"
        echo ""
        read -p "选择 [1/2] (默认: 1): " ENV_CHOICE

        # 默认选择 GLM
        if [ -z "$ENV_CHOICE" ]; then
            ENV_CHOICE="1"
        fi
        echo "[2] 交互式选择: $ENV_CHOICE" >> ~/ccs-debug.log
    fi

    # 加载对应环境变量
    local KEY_FILE="$HOME/.claude-env-keys"
    echo "[3] 密钥文件路径: $KEY_FILE" >> ~/ccs-debug.log

    if ! check_key_file_security "$KEY_FILE"; then
        echo "[3] ❌ 密钥文件检查失败，退出" >> ~/ccs-debug.log
        return 1
    fi

    echo "[3] ✅ 密钥文件检查通过" >> ~/ccs-debug.log

    # 加载密钥文件（临时，不泄露到环境）
    source "$KEY_FILE"
    echo "[3] 密钥文件已加载" >> ~/ccs-debug.log

    # 🔴 调试：记录环境变量设置
    echo "[3] 准备执行 case 语句" >> ~/ccs-debug.log
    echo "[3] ENV_CHOICE=$ENV_CHOICE" >> ~/ccs-debug.log

    case $ENV_CHOICE in
        1)
            ENV_NAME="GLM"
            echo "✓ 已选择：GLM 环境（简单任务）"
            echo "[4] ✅ GLM 环境已设置, ENV_NAME=$ENV_NAME" >> ~/ccs-debug.log
            ;;
        2)
            ENV_NAME="CCClub"
            echo "✓ 已选择：CCClub 环境（复杂任务）"
            echo "[4] ✅ CCClub 环境已设置, ENV_NAME=$ENV_NAME" >> ~/ccs-debug.log
            ;;
        *)
            echo "❌ 无效选择，退出"
            echo "[4] ❌ 无效选择: $ENV_CHOICE，退出" >> ~/ccs-debug.log
            return 1
            ;;
    esac

    echo "[4] 准备调用包装脚本: ENV_NAME=$ENV_NAME, WINDOW_NAME=$1" >> ~/ccs-debug.log

    # 清理临时变量（安全措施）
    unset GLM_BASE_URL GLM_AUTH_TOKEN CCClub_BASE_URL CCClub_AUTH_TOKEN

    # 🔴 调用包装脚本（使用 exec 确保环境变量传递）
    # 注意：exec 之后的代码不会执行，因为当前进程会被包装脚本替换
    exec ~/.claude/tools/terminal-notifier/scripts/user/ccs-wrapper.sh "$ENV_NAME" "$1"
}

# 快捷别名（可选）
alias ccs='ccs-start'              # 超短命令
alias claude-start='ccs-start'     # 兼容旧命令名

# ============================================
# 安装说明
# ============================================

# 1. 编辑 ~/.bashrc
#    nano ~/.bashrc
#    或
#    code ~/.bashrc

# 2. 将上面的函数和别名复制到文件末尾

# 3. 重新加载配置
#    source ~/.bashrc

# 4. 使用方式
#    claude-start                    # 交互式询问
#    claude-start "编译测试"          # 直接指定
#    cs "编译测试"                    # 使用别名（更短）

# ============================================
# 验证安装
# ============================================

# 运行以下命令测试：
#   claude-start --help
#   claude-start "测试窗口"
#   cs "测试窗口"

# 预期效果：
#   - 启动 Claude Code
#   - Stop Hook 触发时，Toast 显示：[测试窗口] 需要输入 - Backend_CPP
