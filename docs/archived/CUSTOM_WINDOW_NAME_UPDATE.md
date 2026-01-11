# 基础版 Hook 自定义窗口名称功能 - 更新总结

## 更新内容

### 新增功能

✅ **基础版 Hook 现已支持显示自定义窗口名称！**

#### 修改的文件

1. **scripts/hooks/stop-basic.ps1**
   - 添加 `StateManager.psm1` 模块导入
   - 调用 `Get-WindowDisplayName` 获取自定义窗口名称
   - 在终端标题栏显示自定义窗口名称
   - Toast 通知中使用自定义窗口名称

2. **scripts/hooks/notification-basic.ps1**
   - 添加 `StateManager.psm1` 模块导入
   - 调用 `Get-WindowDisplayName` 获取自定义窗口名称
   - 在终端标题栏显示自定义窗口名称（5秒后自动清除）
   - Toast 通知中使用自定义窗口名称

3. **docs/BASIC_VS_ADVANCED.md**
   - 更新功能对比表，添加"自定义窗口标题"功能
   - 更新依赖模块数（2 → 3）

4. **.claude/hooks.basic.example.json**
   - 更新功能描述
   - 添加自定义窗口名称说明
   - 更新依赖模块数

### 新增的文件

1. **test-custom-window-name.ps1**
   - 测试自定义窗口名称功能
   - 模拟 `ccs` 命令设置的环境变量
   - 验证 Hook 输出

2. **docs/BASIC_VERSION_WITH_WINDOW_NAME.md**
   - 详细的功能说明文档
   - 使用方法
   - 实现原理
   - 故障排除指南

## 功能对比（更新后）

| 功能 | 基础版（更新后） | 高级版 |
|------|-----------------|--------|
| 音效通知 | ✅ | ✅ |
| Toast 通知 | ✅ | ✅ |
| 自定义窗口标题 | ✅ **新增** | ✅ |
| 状态管理 | ❌ | ✅ |
| 持久化标题 | ❌ | ✅ |
| OSC 标签页颜色 | ❌ | ✅ |
| 依赖模块数 | 3 | 5 |
| 执行速度 | 快 (<200ms) | 中等 (<500ms) |

## 使用方法

### 方法 1：使用 ccs 命令（推荐）

```bash
# 交互式启动
ccs

# 指定窗口名称
ccs glm "编译测试"
ccs ccclub "代码审查"
```

### 方法 2：手动设置环境变量

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

## 效果展示

### Stop Hook 触发时

**终端标题**：
```
[⚠️ 编译测试] 需要输入 - terminal-notifier
```

**Toast 通知**：
```
[编译测试] 需要输入 - terminal-notifier
Claude Code 正在等待您的响应
```

### Notification Hook 触发时

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

### Hook 脚本流程

```powershell
# 1. 导入 StateManager 模块
Import-Module (Join-Path $LibPath "StateManager.psm1") -Force

# 2. 获取自定义窗口名称
$windowName = ""
try {
    $windowName = Get-WindowDisplayName
}
catch {
    # 回退到项目名称
    $windowName = $projectName
}

# 3. 显示在终端标题
if ($windowName -and $windowName -ne $projectName) {
    $title = "[⚠️ $windowName] 需要输入 - $projectName"
} else {
    $title = "[⚠️] 需要输入 - $projectName"
}
$Host.UI.RawUI.WindowTitle = $title

# 4. Toast 通知也使用窗口名称
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
.\test-custom-window-name.ps1
```

### 预期输出

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

## 多窗口管理示例

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

- [docs/BASIC_VERSION_WITH_WINDOW_NAME.md](docs/BASIC_VERSION_WITH_WINDOW_NAME.md) - 详细功能说明
- [docs/BASIC_VS_ADVANCED.md](docs/BASIC_VS_ADVANCED.md) - 基础版 vs 高级版对比
- [scripts/user/README-CCS.md](scripts/user/README-CCS.md) - CCS 命令使用说明

## 注意事项

1. **必须使用 ccs 命令或手动设置环境变量**
   - 如果没有设置 `CLAUDE_WINDOW_NAME`，会自动使用项目名称
   - 不会影响 Hook 的正常工作

2. **基础版的标题不是持久的**
   - 标题可能被后续操作覆盖
   - 如需持久化标题，请使用高级版

3. **Notification Hook 的标题会自动清除**
   - 显示 5 秒后自动清除
   - 恢复为默认标题

---

**更新日期**：2025-01-09
**版本**：基础版 v1.1（新增自定义窗口名称功能）
**状态**：✅ 已测试，功能正常
