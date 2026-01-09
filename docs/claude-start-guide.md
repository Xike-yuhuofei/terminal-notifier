# 方案 2: Git Bash 启动脚本 - 快速使用指南

## 适用场景

- 任务不固定，每次启动 Claude Code 时临时指定窗口名称
- 不想预先配置多个 Windows Terminal Profile
- 希望启动命令简单快捷

---

## 快速开始（2 分钟配置）

### 方法 A: 使用独立脚本（推荐，最简单）

#### 步骤 1: 复制脚本到 PATH 目录

```bash
# 复制启动脚本到 Git Bash 的 bin 目录
cp C:/Users/Xike/.claude/tools/terminal-notifier/scripts/user/claude-start /usr/local/bin/

# 或者复制到用户 bin 目录
mkdir -p ~/bin
cp C:/Users/Xike/.claude/tools/terminal-notifier/scripts/user/claude-start ~/bin/
```

#### 步骤 2: 立即使用

```bash
# 交互式启动（询问窗口名称）
claude-start

# 直接指定窗口名称
claude-start "编译测试"

# 使用默认名称（项目名）
claude-start -
```

**预期效果**：
- 启动 Claude Code
- Stop Hook 触发时，Toast 显示：`[编译测试] 需要输入 - Backend_CPP`

---

### 方法 B: 添加 bash 函数到 ~/.bashrc（更灵活）

#### 步骤 1: 编辑 ~/.bashrc

```bash
# 使用 nano 编辑
nano ~/.bashrc

# 或使用 VS Code 编辑
code ~/.bashrc
```

#### 步骤 2: 复制函数定义

打开 `C:/Users/Xike/.claude/tools/terminal-notifier/scripts/user/claude-start-bashrc.sh`，复制全部内容到 `~/.bashrc` 文件末尾。

或者使用命令追加：

```bash
cat C:/Users/Xike/.claude/tools/terminal-notifier/scripts/user/claude-start-bashrc.sh >> ~/.bashrc
```

#### 步骤 3: 重新加载配置

```bash
source ~/.bashrc
```

#### 步骤 4: 使用函数和别名

```bash
# 完整命令
claude-start "编译测试"

# 使用短别名
cs "编译测试"

# 使用预设快捷命令
csc    # 编译测试
cst    # 单元测试
csr    # 代码审查
csp    # 性能优化
csf    # 重构工作
```

---

## 使用示例

### 场景 1: 同时进行 3 项任务

**窗口 1 - 选项卡 1**：
```bash
cd /d/Projects/Backend_CPP
claude-start "编译测试"
```
→ Stop Hook 触发时，Toast 显示：`[编译测试] 需要输入 - Backend_CPP`

**窗口 1 - 选项卡 2**：
```bash
cd /d/Projects/Backend_CPP
cs "单元测试"    # 使用别名
```
→ Stop Hook 触发时，Toast 显示：`[单元测试] 需要输入 - Backend_CPP`

**窗口 2 - 选项卡 1**：
```bash
cd /d/Projects/Backend_CPP
csr              # 使用预设快捷命令
```
→ Stop Hook 触发时，Toast 显示：`[代码审查] 需要输入 - Backend_CPP`

---

### 场景 2: 临时任务（不设置窗口名称）

```bash
cd /d/Projects/Backend_CPP
claude-start -    # 使用默认名称（项目名）
```
→ Stop Hook 触发时，Toast 显示：`[Backend_CPP] 需要输入 - Backend_CPP`

---

### 场景 3: 交互式启动（不确定任务时）

```bash
cd /d/Projects/Backend_CPP
claude-start      # 无参数，会询问窗口名称

# 脚本会提示：
# 请输入窗口名称（用于 Toast 通知识别）：
# 常用名称示例：编译测试、单元测试、代码审查、性能优化、重构工作
#
# 窗口名称（直接回车使用默认名称）: _

# 输入"编译测试"后按回车
```

---

## 自定义快捷命令

如果你有其他常用任务，可以在 `~/.bashrc` 中添加更多别名：

```bash
# 添加到 ~/.bashrc
alias css='claude-start "架构设计"'      # 架构设计
alias csd='claude-start "调试问题"'      # 调试问题
alias csi='claude-start "集成测试"'      # 集成测试
alias csh='claude-start "硬件调试"'      # 硬件调试
alias csm='claude-start "模块开发"'      # 模块开发
```

重新加载配置：
```bash
source ~/.bashrc
```

使用：
```bash
css    # 启动"架构设计"任务
csd    # 启动"调试问题"任务
```

---

## 典型工作流程

### 早晨启动（3 个并行任务）

**选项卡 1**：
```bash
cd /d/Projects/Backend_CPP
csc    # 编译测试
```

**选项卡 2**：
```bash
cd /d/Projects/Backend_CPP
cst    # 单元测试
```

**选项卡 3**：
```bash
cd /d/Projects/Backend_CPP
csr    # 代码审查
```

### 下午增加 2 个任务

**选项卡 4**：
```bash
cd /d/Projects/Backend_CPP
csp    # 性能优化
```

**选项卡 5**：
```bash
cd /d/Projects/Backend_CPP
claude-start "重构-运动控制模块"    # 临时任务，自定义名称
```

---

## 优势对比

### 方法 A vs 方法 B

| 特性 | 方法 A（独立脚本） | 方法 B（.bashrc 函数） |
|------|------------------|----------------------|
| 配置复杂度 | 低（复制文件） | 中（编辑 .bashrc） |
| 命令长度 | `claude-start "任务"` | `cs "任务"` 或 `csc` |
| 自定义快捷命令 | 不支持 | 支持（添加别名） |
| 跨项目使用 | 支持 | 支持 |
| 卸载 | 删除脚本文件 | 删除 .bashrc 中的代码 |

**推荐**：如果你需要超短命令（`cs`、`csc`）和自定义快捷命令，使用**方法 B**。

---

## 验证安装

### 测试 1: 检查命令是否可用

```bash
claude-start --help
```

**预期输出**：
```
用法：
  claude-start                    # 交互式询问窗口名称
  claude-start "编译测试"          # 直接指定窗口名称
  claude-start -                  # 使用默认名称（项目名）

窗口名称会显示在 Toast 通知中，用于区分多个 Claude Code 实例。
```

### 测试 2: 测试环境变量设置

```bash
# 设置窗口名称
export CLAUDE_WINDOW_NAME="测试窗口-12345"

# 验证 PowerShell 能否读取
powershell.exe -Command "Write-Output \$env:CLAUDE_WINDOW_NAME"
```

**预期输出**：`测试窗口-12345`

如果输出为空，说明环境变量传递失败，需要使用**方案 3（PowerShell Wrapper）**。

### 测试 3: 实际启动测试

```bash
cd /d/Projects/Backend_CPP
claude-start "测试窗口"

# 等待 Claude Code 的 Stop Hook 触发
# 观察 Windows 通知中心的 Toast 通知
# 预期标题：[测试窗口] 需要输入 - Backend_CPP
```

---

## 常见问题

### Q1: 运行 `claude-start` 提示 "command not found"

**原因**：脚本文件不在 PATH 目录中。

**解决方案**：

```bash
# 检查 ~/bin 是否在 PATH 中
echo $PATH | grep "$HOME/bin"

# 如果没有，添加到 ~/.bashrc
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 复制脚本到 ~/bin
mkdir -p ~/bin
cp C:/Users/Xike/.claude/tools/terminal-notifier/scripts/user/claude-start ~/bin/
```

### Q2: Toast 通知显示的是项目名而不是自定义名称

**原因**：环境变量未正确设置或传递失败。

**调试步骤**：

```bash
# 1. 检查环境变量是否设置
echo $CLAUDE_WINDOW_NAME

# 2. 检查 PowerShell 能否读取
powershell.exe -Command "Write-Output \$env:CLAUDE_WINDOW_NAME"

# 3. 如果步骤 2 失败，使用方案 3（PowerShell Wrapper）
```

### Q3: 如何修改预设快捷命令的名称

编辑 `~/.bashrc`，找到别名定义：

```bash
# 修改前
alias csc='claude-start "编译测试"'

# 修改后（改为你喜欢的名称）
alias csc='claude-start "构建测试"'
```

保存后重新加载：
```bash
source ~/.bashrc
```

### Q4: 如何同时使用方案 1 和方案 2

**可以同时使用**：
- **方案 1**：用于固定的常用任务（如每日必做的编译测试、单元测试）
- **方案 2**：用于临时的、不固定的任务（如临时调试、特定模块开发）

**示例**：
- 使用 Windows Terminal Profile "Claude - 编译测试" 启动固定任务
- 在新选项卡中使用 `claude-start "临时调试-CMP模块"` 启动临时任务

---

## 推荐配置（最佳实践）

### 步骤 1: 安装方法 B（bash 函数）

```bash
cat C:/Users/Xike/.claude/tools/terminal-notifier/scripts/user/claude-start-bashrc.sh >> ~/.bashrc
source ~/.bashrc
```

### 步骤 2: 添加自定义快捷命令

根据你的实际工作任务，编辑 `~/.bashrc` 添加 3-5 个常用快捷命令：

```bash
# 我的常用任务快捷命令
alias csc='claude-start "编译测试"'
alias cst='claude-start "单元测试"'
alias csd='claude-start "调试问题"'
```

### 步骤 3: 日常使用

```bash
# 固定任务：使用快捷命令
csc    # 编译测试
cst    # 单元测试

# 临时任务：使用完整命令
cs "重构-运动控制模块"
cs "实验-新插补算法"

# 不确定任务：交互式
cs     # 会询问窗口名称
```

---

## 文件位置

- **独立脚本**：`C:/Users/Xike/.claude/tools/terminal-notifier/scripts/user/claude-start`
- **bash 函数代码**：`C:/Users/Xike/.claude/tools/terminal-notifier/scripts/user/claude-start-bashrc.sh`
- **本指南**：`C:/Users/Xike/.claude/tools/terminal-notifier/scripts/user/claude-start-guide.md`
- **完整配置指南**：`C:/Users/Xike/.claude/tools/terminal-notifier/docs/window-naming-guide.md`

---

## 快速命令速查表

| 命令 | 说明 |
|------|------|
| `claude-start` | 交互式启动（询问窗口名称） |
| `claude-start "任务名"` | 指定窗口名称启动 |
| `claude-start -` | 使用默认名称启动 |
| `cs "任务名"` | 短命令（需要方法 B） |
| `csc` | 快捷启动"编译测试" |
| `cst` | 快捷启动"单元测试" |
| `csr` | 快捷启动"代码审查" |
| `csp` | 快捷启动"性能优化" |
| `csf` | 快捷启动"重构工作" |

---

## 下一步

1. **选择安装方法**：方法 A（简单）或方法 B（灵活）
2. **验证安装**：运行 `claude-start --help`
3. **实际测试**：启动 Claude Code，触发 Stop Hook 观察 Toast 通知
4. **自定义快捷命令**：根据实际任务添加别名到 `~/.bashrc`

如果遇到问题，参考完整指南：`C:/Users/Xike/.claude/tools/terminal-notifier/docs/window-naming-guide.md`
