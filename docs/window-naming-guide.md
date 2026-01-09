# Windows Terminal + Git Bash + Claude Code 窗口命名配置指南

## 场景描述
同一项目，多个 Windows Terminal 窗口/选项卡，每个选项卡运行独立的 Claude Code 实例，需要通过 Toast 通知区分不同工作任务。

---

## 配置方案总览

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| **方案 1: Windows Terminal Profiles** | 最可靠，一键启动，持久化配置 | 需要预先配置多个 Profile | ⭐⭐⭐⭐⭐ |
| **方案 2: Git Bash 启动脚本** | 灵活，无需修改 Terminal 配置 | 每次手动运行，易忘记 | ⭐⭐⭐ |
| **方案 3: PowerShell Wrapper** | 绕过 Git Bash 环境变量传递问题 | 需要在 PowerShell 中启动 | ⭐⭐⭐⭐ |

---

## 方案 1: Windows Terminal Profiles 配置（推荐）

### 步骤 1: 编辑 Windows Terminal settings.json

1. 打开 Windows Terminal
2. 按 `Ctrl + ,` 打开设置
3. 点击左下角 "打开 JSON 文件"
4. 在 `profiles.list` 数组中添加以下配置：

```json
{
    "guid": "{10000001-0000-0000-0000-000000000001}",
    "name": "Claude - 编译测试",
    "commandline": "C:/Program Files/Git/bin/bash.exe -c \"export CLAUDE_WINDOW_NAME='编译测试' && cd /d/Projects/Backend_CPP && exec bash\"",
    "icon": "🔨",
    "tabTitle": "编译测试",
    "startingDirectory": "D:/Projects/Backend_CPP"
}
```

**关键参数说明**：
- `export CLAUDE_WINDOW_NAME='编译测试'`：设置窗口自定义名称
- `cd /d/Projects/Backend_CPP`：切换到项目目录（Git Bash 路径格式）
- `exec bash`：用新的 bash 进程替换，继承环境变量

### 步骤 2: 创建多个任务专用 Profile

根据你的工作任务创建多个配置：

```json
// 编译测试
{
    "guid": "{10000001-0000-0000-0000-000000000001}",
    "name": "Claude - 编译测试",
    "commandline": "C:/Program Files/Git/bin/bash.exe -c \"export CLAUDE_WINDOW_NAME='编译测试' && cd /d/Projects/Backend_CPP && exec bash\"",
    "icon": "🔨",
    "tabTitle": "编译测试"
}

// 单元测试
{
    "guid": "{10000002-0000-0000-0000-000000000002}",
    "name": "Claude - 单元测试",
    "commandline": "C:/Program Files/Git/bin/bash.exe -c \"export CLAUDE_WINDOW_NAME='单元测试' && cd /d/Projects/Backend_CPP && exec bash\"",
    "icon": "🧪",
    "tabTitle": "单元测试"
}

// 代码审查
{
    "guid": "{10000003-0000-0000-0000-000000000003}",
    "name": "Claude - 代码审查",
    "commandline": "C:/Program Files/Git/bin/bash.exe -c \"export CLAUDE_WINDOW_NAME='代码审查' && cd /d/Projects/Backend_CPP && exec bash\"",
    "icon": "👀",
    "tabTitle": "代码审查"
}

// 性能优化
{
    "guid": "{10000004-0000-0000-0000-000000000004}",
    "name": "Claude - 性能优化",
    "commandline": "C:/Program Files/Git/bin/bash.exe -c \"export CLAUDE_WINDOW_NAME='性能优化' && cd /d/Projects/Backend_CPP && exec bash\"",
    "icon": "⚡",
    "tabTitle": "性能优化"
}

// 重构工作
{
    "guid": "{10000005-0000-0000-0000-000000000005}",
    "name": "Claude - 重构工作",
    "commandline": "C:/Program Files/Git/bin/bash.exe -c \"export CLAUDE_WINDOW_NAME='重构工作' && cd /d/Projects/Backend_CPP && exec bash\"",
    "icon": "🔧",
    "tabTitle": "重构工作"
}
```

### 步骤 3: 使用配置启动

1. 点击 Windows Terminal 的 `+` 按钮旁边的 `▼` 下拉菜单
2. 选择对应的 Profile（如 "Claude - 编译测试"）
3. 在打开的 Git Bash 中运行 `claude`

**预期效果**：
- Stop Hook 触发时，Toast 通知显示：`[编译测试] 需要输入 - Backend_CPP`
- Notification Hook 触发时，Toast 通知显示：`[编译测试] 通知 - Backend_CPP`

---

## 方案 2: Git Bash 启动脚本

### 适用场景
- 不想修改 Windows Terminal 配置
- 需要临时更改窗口名称

### 使用方法

在 Git Bash 中运行以下命令：

```bash
# 设置窗口名称
export CLAUDE_WINDOW_NAME="编译测试"

# 启动 Claude Code
claude
```

**简化方案**：创建快捷启动脚本

```bash
# 在项目根目录创建 start-claude-compile.sh
cat > start-claude-compile.sh << 'EOF'
#!/bin/bash
export CLAUDE_WINDOW_NAME="编译测试"
cd /d/Projects/Backend_CPP
claude
EOF

chmod +x start-claude-compile.sh

# 使用
./start-claude-compile.sh
```

创建多个脚本用于不同任务：
- `start-claude-compile.sh` → "编译测试"
- `start-claude-test.sh` → "单元测试"
- `start-claude-review.sh` → "代码审查"
- `start-claude-perf.sh` → "性能优化"
- `start-claude-refactor.sh` → "重构工作"

---

## 方案 3: PowerShell Wrapper（绕过环境变量传递问题）

### 适用场景
- Git Bash 环境变量传递不稳定
- 需要最可靠的方案

### Windows Terminal Profile 配置

```json
{
    "guid": "{20000001-0000-0000-0000-000000000001}",
    "name": "Claude - 编译测试 (PS Wrapper)",
    "commandline": "powershell.exe -NoExit -Command \"$env:CLAUDE_WINDOW_NAME='编译测试'; cd D:/Projects/Backend_CPP; bash -c 'claude'\"",
    "startingDirectory": "D:/Projects/Backend_CPP"
}
```

**工作原理**：
1. 在 PowerShell 中设置 `$env:CLAUDE_WINDOW_NAME`
2. 启动 Git Bash
3. 在 Git Bash 中运行 `claude`
4. PowerShell Hook 直接读取 PowerShell 环境变量

---

## 验证配置

### 验证步骤 1: 检查环境变量是否传递

在 Git Bash 中运行：

```bash
# 设置环境变量
export CLAUDE_WINDOW_NAME="测试窗口"

# 验证环境变量
echo $CLAUDE_WINDOW_NAME
# 预期输出: 测试窗口

# 验证 PowerShell 可以读取
powershell.exe -Command "Write-Output \$env:CLAUDE_WINDOW_NAME"
# 预期输出: 测试窗口
```

如果 PowerShell 无法读取，说明环境变量传递失败，需要使用**方案 3**。

### 验证步骤 2: 测试 Toast 通知

在配置好的 Git Bash 选项卡中：

```bash
# 设置窗口名称（如果使用方案 2）
export CLAUDE_WINDOW_NAME="编译测试"

# 启动 Claude Code
claude

# 触发 Stop Hook（等待 Claude 停止工作并请求输入）
# 观察 Toast 通知是否显示：[编译测试] 需要输入 - Backend_CPP
```

### 验证步骤 3: 手动触发 Toast（调试用）

创建测试脚本 `test-toast.ps1`：

```powershell
# 模拟 Stop Hook 环境
$env:CLAUDE_WINDOW_NAME = "编译测试"

# 导入模块
Import-Module "C:/Users/Xike/.claude/tools/terminal-notifier/lib/StateManager.psm1" -Force
Import-Module "C:/Users/Xike/.claude/tools/terminal-notifier/lib/ToastNotifier.psm1" -Force

# 测试窗口命名
$windowName = Get-WindowDisplayName
Write-Host "Window Name: $windowName"

# 发送 Toast
Send-StopToast -WindowName $windowName -ProjectName "Backend_CPP"
```

运行测试：

```bash
powershell.exe -ExecutionPolicy Bypass -File test-toast.ps1
```

---

## 常见问题

### Q1: Git Bash 的 export 命令设置的环境变量无法传递到 PowerShell？

**原因**：Git Bash 和 PowerShell 的环境变量可能不共享。

**解决方案**：
1. 使用**方案 3**（PowerShell Wrapper）
2. 或者在 Git Bash 中使用 Windows 系统级环境变量：
   ```bash
   # 设置系统级环境变量（重启终端生效）
   /c/Windows/System32/setx.exe CLAUDE_WINDOW_NAME "编译测试"
   ```

### Q2: 多个选项卡如何设置不同的窗口名称？

**答**：
- **推荐**：使用**方案 1**，为每个任务创建专用 Windows Terminal Profile
- **灵活**：使用**方案 2**，在每个选项卡中手动运行 `export` 命令

### Q3: 如何批量打开多个选项卡并自动配置？

**答**：创建 Windows Terminal 布局配置文件（`wt.exe` 命令行）：

```bash
# 在 PowerShell 中运行
wt.exe `
  new-tab --profile "Claude - 编译测试" `; `
  new-tab --profile "Claude - 单元测试" `; `
  new-tab --profile "Claude - 代码审查"
```

保存为快捷方式或脚本，一键启动多个任务窗口。

### Q4: Toast 通知显示的是项目名称而不是自定义名称？

**原因**：环境变量 `CLAUDE_WINDOW_NAME` 未正确设置。

**调试步骤**：
1. 在 Git Bash 中运行 `echo $CLAUDE_WINDOW_NAME`，确认变量存在
2. 运行 `powershell.exe -Command "Write-Output \$env:CLAUDE_WINDOW_NAME"`，确认 PowerShell 可以读取
3. 如果步骤 2 失败，使用**方案 3**

---

## 推荐工作流程

### 典型场景：同时进行 5 项任务

**Windows Terminal 布局**：

```
窗口 1（主开发窗口）
├── [编译测试] Git Bash → claude（处理编译错误）
├── [单元测试] Git Bash → claude（编写/修复测试）
└── [代码审查] Git Bash → claude（审查代码变更）

窗口 2（实验/优化窗口）
├── [性能优化] Git Bash → claude（性能分析）
└── [重构工作] Git Bash → claude（代码重构）
```

**Toast 通知效果**：
- 窗口 1 的编译测试选项卡触发 Stop Hook → Toast 显示：`[编译测试] 需要输入 - Backend_CPP`
- 窗口 2 的性能优化选项卡触发 Notification Hook → Toast 显示：`[性能优化] 通知 - Backend_CPP`

**你可以立即识别哪个任务需要你的注意！**

---

## 快速开始（3 分钟配置）

### 第 1 步：复制示例配置

打开 `C:/Users/Xike/.claude/tools/terminal-notifier/docs/windows-terminal-profiles.json`，复制配置到 Windows Terminal 的 `settings.json` 中的 `profiles.list` 数组。

### 第 2 步：修改 GUID 和路径

为每个 Profile 生成唯一 GUID（在线工具：https://www.guidgenerator.com/）

将 `/d/Projects/Backend_CPP` 改为你的实际项目路径。

### 第 3 步：保存并测试

1. 保存 `settings.json`
2. 点击 Windows Terminal 的下拉菜单，选择 "Claude - 编译测试"
3. 在打开的 Git Bash 中运行 `claude`
4. 等待 Stop Hook 触发，观察 Toast 通知

**预期结果**：Toast 显示 `[编译测试] 需要输入 - Backend_CPP`

---

## 文件位置

- Windows Terminal 配置：`%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`
- 示例配置：`C:/Users/Xike/.claude/tools/terminal-notifier/docs/windows-terminal-profiles.json`
- Toast 模块：`C:/Users/Xike/.claude/tools/terminal-notifier/lib/ToastNotifier.psm1`
- StateManager 模块：`C:/Users/Xike/.claude/tools/terminal-notifier/lib/StateManager.psm1`

---

## 总结

| 方案 | 配置复杂度 | 使用便捷度 | 可靠性 | 推荐场景 |
|------|----------|-----------|--------|---------|
| **方案 1: Windows Terminal Profiles** | 中（一次配置） | 高（一键启动） | 高 | 固定任务场景 |
| **方案 2: Git Bash 启动脚本** | 低 | 中（需手动运行） | 中 | 灵活/临时任务 |
| **方案 3: PowerShell Wrapper** | 中 | 高 | 最高 | 环境变量传递问题 |

**最佳实践**：
1. 使用**方案 1**为常用任务创建 5-10 个专用 Profile
2. 使用**方案 2**处理临时/一次性任务
3. 如果遇到环境变量传递问题，切换到**方案 3**
