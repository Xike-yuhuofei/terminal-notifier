# Terminal Notifier Hook 双层架构实施总结

## 问题解决方案

### 原始问题

用户反馈："重启 Claude Code 无效，项目级的 Stop Hook 与用户级的 Stop Hook 是否冲突？"

### 根本原因

**配置冲突**：用户级配置优先级高于项目级配置，导致项目级配置被忽略。

```
~/.claude/settings.json (用户级)
    ↓ 优先级更高 ↓
.claude/settings.local.json (项目级) ← 被忽略
```

### 解决方案

✅ **修改用户级配置文件**，将 Stop 和 Notification Hook 从高级版切换到基础版。

## 已完成的修改

### 1. 用户级配置文件

**文件**：`C:\Users\Xike\.claude\settings.json`

**修改内容**：
- Stop Hook：`stop.ps1` → `stop-basic.ps1`
- Notification Hook：`notification.ps1` → `notification-basic.ps1`

**验证**：
```powershell
cat "C:/Users/Xike/.claude/settings.json" | grep "stop.*ps1"
# 输出：stop-basic.ps1 ✅
```

### 2. 创建的文件

#### 基础版 Hook 脚本
- `scripts/hooks/stop-basic.ps1` - 基础版 Stop Hook
- `scripts/hooks/notification-basic.ps1` - 基础版 Notification Hook

#### 配置文件
- `.claude/settings.local.json` - 项目级配置（被忽略，仅供参考）
- `.claude/hooks.basic.example.json` - 基础版配置示例
- `.claude/hooks.advanced.example.json` - 高级版配置示例

#### 测试脚本
- `test-basic-hooks.ps1` - 基础版测试脚本
- `test-advanced-hooks.ps1` - 高级版测试脚本

#### 快速切换脚本
- `switch-to-basic.ps1` - 快速切换到基础版
- `switch-to-advanced.ps1` - 快速切换到高级版

#### 文档
- `docs/BASIC_VS_ADVANCED.md` - 功能对比和使用指南
- `docs/HOOKS_CONFIGURATION_LEVELS.md` - 配置层级说明

## 当前配置状态

### 全局配置（生效）

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:/Users/Xike/.claude/tools/terminal-notifier/scripts/hooks/stop-basic.ps1\"",
            "timeout": 5000,
            "_comment": "基础版：仅音效 + Toast。切换到高级版请改为 stop.ps1"
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
            "timeout": 5000,
            "_comment": "基础版：仅音效 + Toast。切换到高级版请改为 notification.ps1"
          }
        ]
      }
    ]
  }
}
```

**版本**：基础版
**范围**：全局（所有项目）

## 使用指南

### 验证当前配置

#### 方法 1：查看配置文件
```powershell
cat "C:/Users/Xike/.claude/settings.json" | grep "stop.*ps1"
```

#### 方法 2：使用 Claude Code 命令
```
/hooks
```

#### 方法 3：运行测试脚本
```powershell
# 在插件根目录
.\test-basic-hooks.ps1
```

### 切换版本

#### 切换到基础版
```powershell
# 方法 1：使用快速切换脚本（推荐）
.\switch-to-basic.ps1

# 方法 2：手动编辑
# 编辑 C:\Users\Xike\.claude\settings.json
# 将 stop.ps1 改为 stop-basic.ps1
# 将 notification.ps1 改为 notification-basic.ps1
```

#### 切换到高级版
```powershell
# 方法 1：使用快速切换脚本（推荐）
.\switch-to-advanced.ps1

# 方法 2：手动编辑
# 编辑 C:\Users\Xike\.claude\settings.json
# 将 stop-basic.ps1 改为 stop.ps1
# 将 notification-basic.ps1 改为 notification.ps1
```

### 应用配置

**重要**：修改配置后必须重启 Claude Code！

```bash
# 退出 Claude Code
exit

# 重新启动
claude
```

## 功能对比

| 功能 | 基础版（当前） | 高级版 |
|------|----------------|--------|
| 音效通知 | ✅ | ✅ |
| Toast 通知 | ✅ | ✅ |
| 状态管理 | ❌ | ✅ |
| 持久化标题 | ❌ | ✅ |
| OSC 标签页颜色 | ❌ | ✅ |
| 依赖模块数 | 2 | 5 |
| 执行速度 | 快 (<200ms) | 中等 (<500ms) |

## 常见问题

### Q: 为什么项目级配置没有生效？

A: 用户级配置优先级更高，会覆盖项目级配置。需要修改用户级配置 `~/.claude/settings.json`。

### Q: 如何在不同项目使用不同版本？

A: 目前不支持。Hook 配置是全局的，所有项目使用相同版本。

### Q: 切换版本后需要重启吗？

A: 是的，必须重启 Claude Code 才能应用新配置。

### Q: 如何验证配置是否生效？

A: 使用 `/hooks` 命令查看已加载的 Hook 配置。

## 下一步

1. ✅ **重启 Claude Code** - 应用基础版配置
2. ✅ **验证配置** - 运行 `/hooks` 命令
3. ✅ **测试功能** - 运行 `.\test-basic-hooks.ps1`
4. ⚠️ **观察效果** - 确认音效和 Toast 正常工作
5. 📝 **按需切换** - 如需高级功能，运行 `.\switch-to-advanced.ps1`

## 相关文档

- [docs/BASIC_VS_ADVANCED.md](BASIC_VS_ADVANCED.md) - 基础版 vs 高级版功能对比
- [docs/HOOKS_CONFIGURATION_LEVELS.md](HOOKS_CONFIGURATION_LEVELS.md) - 配置层级详解
- [HOOKS_SETUP_GUIDE.md](../HOOKS_SETUP_GUIDE.md) - Hook 设置完整指南

## 技术支持

如遇问题，请检查：
1. 配置文件路径是否正确
2. 脚本文件是否存在
3. PowerShell 执行策略是否允许
4. Claude Code 是否已重启

---

**实施日期**：2025-01-09
**当前版本**：基础版
**配置文件**：`C:\Users\Xike\.claude\settings.json`
