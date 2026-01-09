# Claude Code 多环境启动器 - 使用说明

## 📋 功能概述

`ccs` 是一个 Claude Code 多环境启动器，支持：
- ✅ **GLM 环境**：处理简单任务（快速、成本低）
- ✅ **CCClub 环境**：处理复杂任务（强大、能力全面）
- ✅ **自定义窗口名称**：在 Toast 通知中区分不同会话
- ✅ **密钥安全保护**：权限检查、自动修复、防止泄露

---

## 🚀 快速安装

### 步骤 1：配置密钥文件

```bash
# 1. 复制模板到用户主目录
cp ~/.claude/tools/terminal-notifier/scripts/user/.claude-env-keys.template ~/.claude-env-keys

# 2. 编辑密钥文件
nano ~/.claude-env-keys
# 或使用 VS Code
code ~/.claude-env-keys
```

**填写你的密钥：**
```bash
# GLM 环境（用于简单任务）
export GLM_BASE_URL="https://open.bigmodel.cn/api/paas/v4/"
export GLM_AUTH_TOKEN="你的GLM密钥"

# CCClub 环境（用于复杂任务）
export CCClub_BASE_URL="你的CCClub的BaseURL"
export CCClub_AUTH_TOKEN="你的CCClub密钥"
```

### 步骤 2：设置安全权限

```bash
# 设置文件权限（仅当前用户可读写）
chmod 600 ~/.claude-env-keys
```

### 步骤 3：安装启动脚本

**方法 A：复制到 ~/.bashrc（推荐）**

```bash
# 将脚本内容追加到 ~/.bashrc
cat ~/.claude/tools/terminal-notifier/scripts/user/claude-start.bashrc >> ~/.bashrc

# 重新加载配置
source ~/.bashrc
```

**方法 B：创建符号链接**

```bash
# 在 ~/.bashrc 中添加：
echo "source ~/.claude/tools/terminal-notifier/scripts/user/claude-start.bashrc" >> ~/.bashrc
source ~/.bashrc
```

### 步骤 4：验证安装

```bash
# 查看帮助信息
ccs-start --help
```

---

## 💡 使用方法

### 1. 交互式启动（推荐）

```bash
ccs
```

**流程：**
1. 选择环境（GLM 或 CCClub）
2. 输入窗口名称（可选）
3. 自动启动 Claude Code

**示例交互：**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Claude Code 多环境启动器
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

请选择运行环境：

  1) GLM     - 简单任务（快速、成本低）
  2) CCClub  - 复杂任务（强大、能力全面）

选择 [1/2] (默认: 1): 1

✓ 已选择：GLM 环境（简单任务）

请输入窗口名称（用于 Toast 通知识别）：
常用名称示例：编译测试、单元测试、代码审查、性能优化、重构工作

窗口名称（直接回车使用默认名称）: 代码审查

✓ 窗口名称: 代码审查

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
环境：GLM | 启动 Claude Code...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### 2. 命令行参数启动

#### 指定环境（自动选择默认窗口名）
```bash
ccs glm      # 使用 GLM 环境
ccs ccclub   # 使用 CCClub 环境
ccs cc       # CCClub 的简写
```

#### 同时指定环境和窗口名称
```bash
ccs glm "代码审查"           # GLM 环境 + 窗口名称
ccs ccclub "性能优化"        # CCClub 环境 + 窗口名称
ccs cc "重构工作"            # 使用简写
```

#### 使用默认窗口名称
```bash
ccs glm -    # GLM 环境 + 默认窗口名（项目名）
ccs -        # 交互式选择环境 + 默认窗口名
```

---

## 🔒 安全特性

### 1. 文件权限检查
- 自动检查密钥文件权限
- 如果权限不安全（不是 600），自动修复
- 防止其他用户读取密钥

### 2. 变量清理
- 密钥加载后立即清理临时变量
- 防止密钥泄露到 shell 环境

### 3. 错误提示
- 密钥文件不存在时，提供详细的创建步骤
- 权限问题时，自动修复或提供手动修复命令

---

## 📝 使用场景示例

### 场景 1：简单代码审查
```bash
# 使用 GLM（快速、成本低）
ccs glm "代码审查"
```

### 场景 2：复杂架构设计
```bash
# 使用 CCClub（强大、能力全面）
ccs ccclub "架构设计"
```

### 场景 3：快速调试
```bash
# 使用 GLM，使用默认窗口名
ccs glm
```

### 场景 4：多任务并行
```bash
# 终端 1：GLM 环境处理简单任务
ccs glm "单元测试"

# 终端 2：CCClub 环境处理复杂任务
ccs ccclub "性能优化"

# Toast 通知会清楚显示是哪个会话
```

---

## 🛠️ 高级配置

### 修改默认环境

编辑脚本，修改这行（第 88 行）：
```bash
read -p "选择 [1/2] (默认: 1): " ENV_CHOICE
```

将 `默认: 1` 改为 `默认: 2`，默认选择 CCClub。

### 自定义密钥文件路径

如果你的密钥文件不在 `~/.claude-env-keys`，修改脚本第 97 行：
```bash
local KEY_FILE="$HOME/.claude-env-keys"
```

改为你的自定义路径。

### 添加更多环境

如果需要添加第三个环境（例如：其他 API）：

1. 在密钥文件中添加：
```bash
export OTHER_BASE_URL="https://..."
export OTHER_AUTH_TOKEN="your-token"
```

2. 在脚本的 `case` 语句中添加：
```bash
3)
    ENV_NAME="Other"
    export ANTHROPIC_BASE_URL="$OTHER_BASE_URL"
    export ANTHROPIC_AUTH_TOKEN="$OTHER_AUTH_TOKEN"
    echo "✓ 已选择：Other 环境"
    ;;
```

---

## 🔍 故障排除

### 问题 1：命令找不到
```bash
bash: ccs: command not found
```

**解决：**
```bash
# 确认脚本已加载
source ~/.bashrc

# 检查脚本是否正确加载
type ccs-start
```

### 问题 2：密钥文件权限错误
```bash
⚠️  警告：密钥文件权限不安全
```

**解决：**
```bash
# 手动修复权限
chmod 600 ~/.claude-env-keys
```

### 问题 3：密钥文件不存在
```bash
❌ 错误：密钥文件不存在
```

**解决：**
```bash
# 按照提示步骤创建密钥文件
cp ~/.claude/tools/terminal-notifier/scripts/user/.claude-env-keys.template ~/.claude-env-keys
nano ~/.claude-env-keys
chmod 600 ~/.claude-env-keys
```

### 问题 4：环境变量未生效
```bash
# 检查环境变量是否正确设置
echo $ANTHROPIC_BASE_URL
echo $ANTHROPIC_AUTH_TOKEN
```

**解决：**
- 确保密钥文件中的变量名正确（`GLM_BASE_URL`、`GLM_AUTH_TOKEN` 等）
- 检查是否有拼写错误

---

## 📚 命令速查表

| 命令 | 说明 |
|------|------|
| `ccs` | 交互式启动（询问环境 + 窗口名） |
| `ccs glm` | 使用 GLM 环境 |
| `ccs ccclub` | 使用 CCClub 环境 |
| `ccs glm "任务名"` | 指定环境和窗口名称 |
| `ccs -` | 使用默认窗口名称 |
| `ccs --help` | 显示帮助信息 |

---

## 🎯 最佳实践

1. **密钥安全**
   - ✅ 定期更换密钥
   - ✅ 不要将密钥文件提交到 Git
   - ✅ 确保文件权限始终为 600

2. **环境选择**
   - 简单任务（代码审查、小修复）→ GLM
   - 复杂任务（架构设计、重构）→ CCClub

3. **窗口命名**
   - 使用描述性名称：代码审查、性能优化、单元测试
   - 避免过长（建议 2-6 个字）
   - 多任务并行时尤为重要

4. **多会话管理**
   - 使用不同窗口名称区分多个会话
   - Toast 通知会显示对应的窗口名称
   - 便于快速定位到正确的终端

---

## 📄 相关文件

| 文件 | 说明 |
|------|------|
| `~/.claude-env-keys` | 密钥配置文件（需手动创建） |
| `~/.claude/tools/terminal-notifier/scripts/user/claude-start.bashrc` | 启动脚本 |
| `~/.claude/tools/terminal-notifier/scripts/user/.claude-env-keys.template` | 密钥模板 |

---

## ⚠️ 重要提示

1. **永远不要**将 `~/.claude-env-keys` 提交到版本控制系统
2. **建议**将 `.claude-env-keys` 添加到全局 `.gitignore`
3. **定期**检查密钥文件权限（`ls -l ~/.claude-env-keys`）
4. **如果密钥泄露**，立即在平台撤销并重新生成

---

## 📞 获取帮助

```bash
# 查看完整帮助
ccs-start --help

# 查看函数定义
type ccs-start

# 查看别名
alias ccs
```

---

**版本**: 1.0
**更新日期**: 2025-01-08
**维护者**: Claude Code Terminal Notifier
