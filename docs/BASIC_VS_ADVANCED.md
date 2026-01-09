# Terminal Notifier Hook 配置指南

## 概述

Terminal Notifier 提供两个版本的 Hook 脚本：

- **基础版**：音效 + Toast + 自定义窗口标题（轻量级，适合日常使用）
- **高级版**：完整功能，包含状态管理 + 持久化标题 + 音效 + Toast

## 功能对比

| 功能 | 基础版 | 高级版 |
|------|--------|--------|
| 音效通知 | ✅ | ✅ |
| Toast 通知 | ✅ | ✅ |
| 自定义窗口标题 | ✅ | ✅ |
| 状态管理 | ❌ | ✅ |
| 持久化标题 | ❌ | ✅ |
| OSC 标签页颜色 | ❌ | ✅ |
| 依赖模块数 | 3 | 5 |
| 执行速度 | 快 (<200ms) | 中等 (<500ms) |

## 使用场景推荐

| 使用场景 | 推荐版本 | 理由 |
|----------|----------|------|
| 快速原型开发 | 基础版 | 速度优先，减少干扰 |
| 生产环境监控 | 高级版 | 需要状态追踪和历史记录 |
| 多窗口协作 | 高级版 | 状态文件协调多窗口 |
| 单窗口日常使用 | 基础版 | 简单高效，够用即可 |
| 调试和故障排查 | 高级版 | 详细状态信息帮助诊断 |
| 性能敏感场景 | 基础版 | 更少的资源占用 |

## 配置方法

### 方法 1：直接复制配置文件（推荐）

#### 使用基础版

```powershell
# 在插件根目录执行
Copy-Item ".claude/hooks.basic.example.json" ".claude/settings.local.json"
```

#### 使用高级版

```powershell
# 在插件根目录执行
Copy-Item ".claude/hooks.advanced.example.json" ".claude/settings.local.json"
```

### 方法 2：手动编辑配置文件

编辑 `.claude/settings.local.json`，修改脚本路径：

#### 基础版路径

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:/Users/Xike/.claude/tools/terminal-notifier/scripts/hooks/stop-basic.ps1\"",
            "timeout": 5000
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:/Users/Xike/.claude/tools/terminal-notifier/scripts/hooks/notification-basic.ps1\"",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

#### 高级版路径

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:/Users/Xike/.claude/tools/terminal-notifier/scripts/hooks/stop.ps1\"",
            "timeout": 5000
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:/Users/Xike/.claude/tools/terminal-notifier/scripts/hooks/notification.ps1\"",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

### 应用配置

配置完成后，必须重启 Claude Code 才能生效：

```bash
# 退出 Claude Code
exit

# 重新启动
claude
```

### 验证配置

在 Claude Code 中使用 `/hooks` 命令查看已加载的 Hook：

```
/hooks
```

## 测试 Hook 功能

### 测试基础版

```powershell
# 在插件根目录执行
.\test-basic-hooks.ps1
```

**预期效果**：
- ✅ 听到 2 次 Asterisk 音效（Stop + Notification）
- ✅ 看到 2 个 Windows Toast 通知
- ❌ 无状态文件创建
- ❌ 无标题栏修改
- ❌ 无 OSC 标签色变化

### 测试高级版

```powershell
# 在插件根目录执行
.\test-advanced-hooks.ps1
```

**预期效果**：
- ✅ 听到 2 次 Asterisk 音效（Stop + Notification）
- ✅ 看到 2 个 Windows Toast 通知
- ✅ 标题变为 `[⚠️] 需要输入` 或 `[📢] 通知`
- ✅ 标签页背景色变为红色或黄色
- ✅ 状态文件已创建（检查 `.states/` 目录）

## 切换版本

### 从基础版切换到高级版

1. **使用配置文件（推荐）**
   ```powershell
   Copy-Item ".claude/hooks.advanced.example.json" ".claude/settings.local.json"
   ```

2. **或者手动编辑**
   - 编辑 `.claude/settings.local.json`
   - 将 `stop-basic.ps1` 改为 `stop.ps1`
   - 将 `notification-basic.ps1` 改为 `notification.ps1`

3. **重启 Claude Code**
   ```bash
   exit
   claude
   ```

### 从高级版切换到基础版

1. **使用配置文件（推荐）**
   ```powershell
   Copy-Item ".claude/hooks.basic.example.json" ".claude/settings.local.json"
   ```

2. **或者手动编辑**
   - 编辑 `.claude/settings.local.json`
   - 将 `stop.ps1` 改为 `stop-basic.ps1`
   - 将 `notification.ps1` 改为 `notification-basic.ps1`

3. **重启 Claude Code**
   ```bash
   exit
   claude
   ```

## 技术细节

### 基础版依赖模块

1. `lib/NotificationEnhancements.psm1` - 音效模块
   - `Invoke-TerminalBell` - 播放系统提示音

2. `lib/ToastNotifier.psm1` - Toast 模块
   - `Send-StopToast` - 发送 Stop 事件 Toast
   - `Send-NotificationToast` - 发送 Notification 事件 Toast

### 高级版依赖模块

1. `lib/NotificationEnhancements.psm1` - 音效模块
2. `lib/ToastNotifier.psm1` - Toast 模块
3. `lib/StateManager.psm1` - 状态管理模块
   - `Set-CurrentState` - 设置终端状态（红/蓝/黄/黑）
   - `Get-CurrentState` - 获取当前状态
4. `lib/PersistentTitle.psm1` - 持久化标题模块
   - `Show-TitleNotification` - 显示持久化标题
   - `Clear-TitleNotification` - 清除持久化标题
5. `lib/OscSender.psm1` - OSC 序列发送模块
   - `Send-OscTitle` - 发送 OSC 2 标题序列
   - `Send-OscTabColor` - 发送 OSC 9;4 标签色序列

### 性能对比

| 版本 | 启动时间 | 内存占用 | CPU 占用 |
|------|----------|----------|----------|
| 基础版 | <100ms | ~20MB | 低 |
| 高级版 | <500ms | ~50MB | 中 |

## 故障排查

### 问题：Hook 没有触发

1. 检查配置文件路径是否正确
2. 确认 Claude Code 已重启
3. 使用 `/hooks` 命令验证 Hook 是否加载

### 问题：音效没有播放

1. 检查系统音量设置
2. 确认 Windows 系统提示音已启用
3. 尝试手动运行测试脚本

### 问题：Toast 通知没有显示

1. 检查是否安装了 BurntToast 模块
   ```powershell
   Get-Module -ListAvailable BurntToast
   ```
2. 如果没有安装，安装 BurntToast：
   ```powershell
   Install-Module -Name BurntToast -Force
   ```
3. 检查 Windows 通知设置

### 问题：高级版状态没有更新

1. 检查 `.states/` 目录权限
2. 确认终端支持 OSC 序列
3. 尝试手动运行高级版测试脚本

## 常见问题

### Q: 默认使用哪个版本？

A: 默认使用基础版。如果需要完整功能，请手动切换到高级版。

### Q: 可以同时使用基础版和高级版吗？

A: 不建议。同时使用会导致功能冲突和性能问题。请根据需求选择其中一个版本。

### Q: 如何知道当前使用的是哪个版本？

A: 查看 `.claude/settings.local.json` 中的脚本路径：
- 包含 `-basic.ps1` → 基础版
- 不包含 `-basic.ps1` → 高级版

### Q: 切换版本会影响现有功能吗？

A: 不会。两个版本的脚本完全独立，切换版本只是改变配置，不会影响现有功能。

### Q: 基础版够用吗？

A: 对于大多数场景，基础版已经足够。如果您需要状态追踪、多窗口协调等高级功能，可以使用高级版。

## 相关文档

- [HOOKS_SETUP_GUIDE.md](../HOOKS_SETUP_GUIDE.md) - Hook 设置完整指南
- [README-PERSISTENT-TITLE.md](../README-PERSISTENT-TITLE.md) - 持久化标题功能说明
- [docs/PERSISTENT_TITLE_UI.md](PERSISTENT_TITLE_UI.md) - 持久化标题 UI 组件文档
