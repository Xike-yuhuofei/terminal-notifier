# 基础版 Hook - 自定义窗口名称功能

## ✅ 已完成！

基础版 Hook 现已支持显示自定义窗口名称（使用 `ccs` 命令设置的窗口名称）。

## 快速开始

### 1. 使用 ccs 命令启动（推荐）

```bash
# 交互式启动
ccs

# 指定窗口名称
ccs glm "编译测试"
ccs ccclub "代码审查"
```

### 2. 查看效果

当 Stop Hook 或 Notification Hook 触发时：

**终端标题**：
```
[⚠️ 编译测试] 需要输入 - terminal-notifier
```

**Toast 通知**：
```
[编译测试] 需要输入 - terminal-notifier
Claude Code 正在等待您的响应
```

## 功能对比（更新后）

| 功能 | 基础版 | 高级版 |
|------|--------|--------|
| 音效通知 | ✅ | ✅ |
| Toast 通知 | ✅ | ✅ |
| **自定义窗口标题** | ✅ **新增** | ✅ |
| 状态管理 | ❌ | ✅ |
| 持久化标题 | ❌ | ✅ |
| OSC 标签页颜色 | ❌ | ✅ |

## 测试功能

```powershell
# 运行测试脚本
.\test-custom-window-name.ps1
```

## 手动设置窗口名称

如果不使用 `ccs` 命令：

```powershell
# PowerShell
$env:CLAUDE_WINDOW_NAME = "编译测试"
claude
```

```bash
# Bash
export CLAUDE_WINDOW_NAME="编译测试"
claude
```

## 多窗口示例

```bash
# 终端 1：编译测试
ccs glm "编译测试"

# 终端 2：代码审查
ccs ccclub "代码审查"

# 终端 3：单元测试
ccs glm "单元测试"
```

每个终端的标题栏和 Toast 通知都会显示对应的窗口名称！

---

**更新日期**：2025-01-09
**详细文档**：[docs/BASIC_VERSION_WITH_WINDOW_NAME.md](docs/BASIC_VERSION_WITH_WINDOW_NAME.md)
