# 基础版 Hook 自定义窗口名称功能

## 更新说明

基础版 Hook 现已支持显示自定义窗口名称！

### 新增功能

- ✅ **自定义窗口标题**：在终端标题栏显示 `ccs` 命令设置的窗口名称
- ✅ **Toast 通知集成**：Toast 通知中也会显示自定义窗口名称
- ✅ **自动回退**：如果没有设置窗口名称，自动使用项目名称

### 功能对比（更新后）

| 功能 | 基础版 | 高级版 |
|------|--------|--------|
| 音效通知 | ✅ | ✅ |
| Toast 通知 | ✅ | ✅ |
| 自定义窗口标题 | ✅ **新增** | ✅ |
| 状态管理 | ❌ | ✅ |
| 持久化标题 | ❌ | ✅ |
| OSC 标签页颜色 | ❌ | ✅ |
| 依赖模块数 | 3 | 5 |
| 执行速度 | 快 (<200ms) | 中等 (<500ms) |

## 使用方法

### 1. 使用 ccs 命令启动 Claude Code

```bash
# 交互式启动（推荐）
ccs

# 指定窗口名称
ccs glm "编译测试"
ccs ccclub "代码审查"
```

### 2. 设置窗口名称

当使用 `ccs` 命令时，会提示输入窗口名称：

```
请输入窗口名称（用于 Toast 通知识别）：
常用名称示例：编译测试、单元测试、代码审查、性能优化、重构工作

窗口名称（直接回车使用默认名称): 编译测试

✓ 窗口名称: 编译测试
```

### 3. 效果展示

#### Stop Hook 触发时

**终端标题**：
```
[⚠️ 编译测试] 需要输入 - terminal-notifier
```

**Toast 通知**：
```
[编译测试] 需要输入 - terminal-notifier
Claude Code 正在等待您的响应
```

#### Notification Hook 触发时

**终端标题**（显示 5 秒后自动清除）：
```
[📢 编译测试] 通知 - terminal-notifier
```

**Toast 通知**：
```
[编译测试] 通知 - terminal-notifier
Claude Code 有新通知
```

## 实现原理

### 环境变量

`ccs` 命令会设置环境变量 `CLAUDE_WINDOW_NAME`：

```bash
export CLAUDE_WINDOW_NAME="编译测试"
```

### Hook 脚本

基础版 Hook 现在会：

1. 读取环境变量 `CLAUDE_WINDOW_NAME`
2. 调用 `Get-WindowDisplayName` 函数获取窗口名称
3. 在终端标题栏和 Toast 通知中使用这个名称

```powershell
# 获取自定义窗口名称
$windowName = ""
try {
    $windowName = Get-WindowDisplayName
}
catch {
    # 回退到项目名称
    $windowName = $projectName
}

# 显示在终端标题
if ($windowName -and $windowName -ne $projectName) {
    $title = "[⚠️ $windowName] 需要输入 - $projectName"
} else {
    $title = "[⚠️] 需要输入 - $projectName"
}
$Host.UI.RawUI.WindowTitle = $title

# Toast 通知也使用窗口名称
Send-StopToast -WindowName $windowName -ProjectName $projectName
```

### 窗口名称优先级

`Get-WindowDisplayName` 函数按以下优先级返回窗口名称：

1. **环境变量 `CLAUDE_WINDOW_NAME`**（最高优先级）
2. 项目名称
3. 会话 ID（前 8 位）
4. 默认值 "Claude Code"

## 测试

### 运行测试脚本

```powershell
# 测试自定义窗口名称功能
.\test-custom-window-name.ps1
```

### 测试输出

```
=== 测试基础版 Stop Hook（带自定义窗口名称）===

📝 设置环境变量 CLAUDE_WINDOW_NAME: 编译测试

🔔 Hook 输入：
{"stop_hook_active":false,"session_id":"...","cwd":"C:\\Users\\Xike\\test-project"}

⚡ 执行 Stop Hook...

=== 测试基础版 Notification Hook（带自定义窗口名称）===

🔔 Hook 输入：
{"cwd":"C:\\Users\\Xike\\test-project","session_id":"..."}

⚡ 执行 Notification Hook...

=== 测试完成 ===

预期效果：
  ✅ 终端标题显示: [⚠️ 编译测试] 需要输入 - test-project
  ✅ Toast 通知显示: [编译测试] 需要输入 - test-project
  ✅ 听到 2 次 Asterisk 音效
```

## 手动设置窗口名称

如果不使用 `ccs` 命令，也可以手动设置环境变量：

### Windows PowerShell

```powershell
$env:CLAUDE_WINDOW_NAME = "编译测试"
claude
```

### Bash

```bash
export CLAUDE_WINDOW_NAME="编译测试"
claude
```

### Git Bash

```bash
export CLAUDE_WINDOW_NAME="编译测试"
claude
```

## 多窗口管理

自定义窗口名称特别适合多窗口场景：

### 示例：多个 Claude Code 会话

```bash
# 终端 1：GLM 环境 + 编译测试
ccs glm "编译测试"

# 终端 2：CCClub 环境 + 代码审查
ccs ccclub "代码审查"

# 终端 3：GLM 环境 + 单元测试
ccs glm "单元测试"
```

**效果**：
- 每个终端的标题栏显示不同的窗口名称
- Toast 通知清楚显示是哪个会话需要关注
- 快速定位到正确的终端窗口

## 故障排除

### 问题 1：窗口名称没有显示

**检查**：
```powershell
# 检查环境变量是否设置
echo $env:CLAUDE_WINDOW_NAME
```

**解决**：
- 确保使用 `ccs` 命令启动
- 或手动设置环境变量

### 问题 2：Toast 通知中没有窗口名称

**原因**：Hook 脚本可能没有正确读取窗口名称

**检查**：
- 确认 Hook 配置指向 `-basic.ps1` 脚本
- 检查 `StateManager.psm1` 模块是否正常

### 问题 3：标题显示为项目名而不是自定义名称

**原因**：环境变量 `CLAUDE_WINDOW_NAME` 没有设置或为空

**解决**：
```powershell
# 重新设置环境变量
$env:CLAUDE_WINDOW_NAME = "你的窗口名称"
```

## 与高级版的区别

### 基础版

- ✅ 显示自定义窗口名称（一次性设置）
- ✅ 简单的标题栏显示
- ❌ 无持久化标题（标题会被覆盖）
- ❌ 无 OSC 标签页颜色
- ❌ 无状态文件

### 高级版

- ✅ 显示自定义窗口名称
- ✅ 持久化标题（后台线程持续刷新，防止被覆盖）
- ✅ OSC 标签页颜色（红色/黄色/绿色/蓝色）
- ✅ 状态文件管理（多窗口协调）
- ✅ 完整的状态管理功能

## 升级建议

### 何时使用基础版

- ✅ 单窗口使用
- ✅ 不需要状态追踪
- ✅ 性能敏感场景
- ✅ 快速原型开发

### 何时升级到高级版

- ✅ 多窗口协作（需要状态文件协调）
- ✅ 需要视觉提示（标签页颜色）
- ✅ 需要持久化标题（防止被覆盖）
- ✅ 生产环境监控

## 相关文档

- [docs/BASIC_VS_ADVANCED.md](BASIC_VS_ADVANCED.md) - 基础版 vs 高级版功能对比
- [scripts/user/README-CCS.md](../scripts/user/README-CCS.md) - CCS 命令使用说明
- [docs/window-naming-guide.md](window-naming-guide.md) - 窗口命名指南

---

**更新日期**：2025-01-09
**版本**：基础版 v1.1（新增自定义窗口名称功能）
