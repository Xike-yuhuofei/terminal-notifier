# Terminal Notifier - 用户脚本和文档

本目录包含 Terminal Notifier 的用户使用脚本和配置文档。

---

## 目录结构

```
C:\Users\Xike\.claude\tools\terminal-notifier\
├── scripts/
│   ├── user/                              # 用户使用的脚本
│   │   ├── claude-start                   # Claude Code 启动脚本（支持自定义窗口名称）
│   │   ├── claude-start.bashrc            # Bash 函数代码（添加到 ~/.bashrc）
│   │   └── test-env-var-passing.sh        # 环境变量传递测试脚本
│   └── hooks/                             # Claude Code Hook 脚本
│       ├── session-start.ps1              # 会话启动 Hook（静默模式）
│       ├── stop.ps1                       # 停止 Hook（集成 Toast 通知）
│       ├── notification.ps1               # 通知 Hook（集成 Toast 通知）
│       └── session-end.ps1                # 会话结束 Hook
├── docs/                                  # 文档和配置示例
│   ├── README.md                          # 本文件
│   ├── claude-start-guide.md              # 方案 2 快速使用指南
│   ├── window-naming-guide.md             # 完整窗口命名配置指南
│   └── windows-terminal-profiles.json     # Windows Terminal Profile 配置示例
└── lib/                                   # PowerShell 模块
    ├── StateManager.psm1                  # 状态管理模块（包含 Get-WindowDisplayName）
    ├── OscSender.psm1                     # OSC 序列发送模块
    ├── NotificationEnhancements.psm1      # 响铃和标题闪烁模块
    └── ToastNotifier.psm1                 # Windows Toast 通知模块
```

---

## 快速开始

### 方案 2: Git Bash 启动脚本（推荐，任务不固定时使用）

#### 方法 A: 使用独立脚本

**安装**：
```bash
mkdir -p ~/bin
cp C:/Users/Xike/.claude/tools/terminal-notifier/scripts/user/claude-start ~/bin/
chmod +x ~/bin/claude-start
```

**使用**：
```bash
claude-start "编译测试"    # 启动 Claude Code，窗口名称为"编译测试"
```

#### 方法 B: 使用 Bash 函数（支持超短命令）

**安装**：
```bash
cat C:/Users/Xike/.claude/tools/terminal-notifier/scripts/user/claude-start.bashrc >> ~/.bashrc
source ~/.bashrc
```

**使用**：
```bash
cs "编译测试"    # 短命令
csc              # 快捷启动"编译测试"
cst              # 快捷启动"单元测试"
```

**详细说明**：参考 `docs/claude-start-guide.md`

---

### 方案 1: Windows Terminal Profiles（任务固定时使用）

**配置示例**：`docs/windows-terminal-profiles.json`

**详细说明**：参考 `docs/window-naming-guide.md`

---

## 核心功能

### 1. Windows Toast 通知

- **触发场景**：Stop Hook、Notification Hook
- **显示内容**：`[窗口自定义名称] 需要输入 - 项目名称`
- **实现模块**：`lib/ToastNotifier.psm1`

### 2. 窗口自定义命名

- **配置方式**：环境变量 `CLAUDE_WINDOW_NAME`
- **优先级**：
  1. `$env:CLAUDE_WINDOW_NAME`（用户显式设置）
  2. 项目名称（自动从工作目录提取）
  3. Session ID 前 8 位（自动生成）
- **实现函数**：`StateManager.psm1::Get-WindowDisplayName`

### 3. SessionStart 静默模式

- **行为**：会话启动时不显示任何视觉/音频通知
- **状态记录**：仍然记录状态到 JSON 文件（用于多窗口协调）
- **实现文件**：`scripts/hooks/session-start.ps1`

---

## 测试工具

### 环境变量传递测试

运行测试脚本检查你的环境是否支持方案 1/2：

```bash
bash C:/Users/Xike/.claude/tools/terminal-notifier/scripts/user/test-env-var-passing.sh
```

**测试内容**：
- ✓ Git Bash 能否设置环境变量
- ✓ PowerShell 能否读取 Git Bash 的环境变量（关键）
- ✓ StateManager 模块的 `Get-WindowDisplayName` 函数
- ✓ 发送测试 Toast 通知

---

## 文档索引

| 文档 | 路径 | 说明 |
|------|------|------|
| **快速开始指南** | `docs/claude-start-guide.md` | 方案 2（Git Bash 启动脚本）详细使用说明 |
| **完整配置指南** | `docs/window-naming-guide.md` | 所有方案的详细配置、常见问题、故障排除 |
| **Windows Terminal 配置** | `docs/windows-terminal-profiles.json` | 方案 1 的 Profile 配置示例 |

---

## 使用场景

### 场景 1: 同时进行多个任务（任务不固定）

使用**方案 2（Git Bash 启动脚本）**：

```bash
# 选项卡 1
cd /d/Projects/Backend_CPP
cs "编译测试"

# 选项卡 2
cd /d/Projects/Backend_CPP
cs "单元测试"

# 选项卡 3
cd /d/Projects/Backend_CPP
cs "代码审查"
```

**Toast 通知效果**：
- 选项卡 1 触发 Stop Hook → `[编译测试] 需要输入 - Backend_CPP`
- 选项卡 2 触发 Stop Hook → `[单元测试] 需要输入 - Backend_CPP`
- 选项卡 3 触发 Stop Hook → `[代码审查] 需要输入 - Backend_CPP`

### 场景 2: 固定日常任务

使用**方案 1（Windows Terminal Profiles）**：

在 Windows Terminal 下拉菜单中创建专用 Profile：
- "Claude - 编译测试"
- "Claude - 单元测试"
- "Claude - 代码审查"

一键启动，无需手动设置窗口名称。

---

## 故障排除

### 问题 1: Toast 通知显示项目名而不是自定义名称

**原因**：环境变量 `CLAUDE_WINDOW_NAME` 未正确设置或传递失败。

**解决方案**：
1. 运行测试脚本：`bash .../test-env-var-passing.sh`
2. 如果测试失败，使用方案 3（PowerShell Wrapper）
3. 参考 `docs/window-naming-guide.md` 的故障排除章节

### 问题 2: 运行 `claude-start` 提示 "command not found"

**原因**：脚本文件不在 PATH 目录中。

**解决方案**：
```bash
# 添加 ~/bin 到 PATH
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 复制脚本到 ~/bin
mkdir -p ~/bin
cp C:/Users/Xike/.claude/tools/terminal-notifier/scripts/user/claude-start ~/bin/
```

---

## 技术支持

如有问题，请参考：
1. **快速开始指南**：`docs/claude-start-guide.md`
2. **完整配置指南**：`docs/window-naming-guide.md`
3. **环境变量测试**：运行 `scripts/user/test-env-var-passing.sh`

---

## 版本历史

### v1.0.0 (2026-01-07)
- ✅ Windows Toast 通知（Stop Hook + Notification Hook）
- ✅ 窗口自定义命名机制（环境变量配置）
- ✅ SessionStart 静默模式
- ✅ Git Bash 启动脚本（方案 2）
- ✅ Windows Terminal Profiles（方案 1）
- ✅ 环境变量传递测试脚本

---

## 开发者信息

- **模块位置**：`lib/`
- **Hook 脚本**：`scripts/hooks/`
- **用户脚本**：`scripts/user/`
- **文档**：`docs/`

**Hook 脚本说明**：
- `session-start.ps1`：静默模式，仅记录状态到 JSON
- `stop.ps1`：集成 Toast 通知，显示自定义窗口名称
- `notification.ps1`：集成 Toast 通知，显示自定义窗口名称
- `session-end.ps1`：清理状态，恢复终端标题

**模块说明**：
- `StateManager.psm1`：状态管理，包含 `Get-WindowDisplayName` 函数
- `ToastNotifier.psm1`：Toast 通知，依赖 BurntToast 模块
- `OscSender.psm1`：OSC 序列发送，控制终端标题和标签色
- `NotificationEnhancements.psm1`：响铃和标题闪烁，作为 Toast 的降级方案
