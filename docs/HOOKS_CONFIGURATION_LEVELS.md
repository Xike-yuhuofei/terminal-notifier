# Hook 配置层级说明

## 问题：为什么项目级配置没有生效？

### 配置文件层级

Claude Code 有三个配置层级，优先级从高到低：

1. **用户级 `~/.claude/settings.json`** - 全局配置，优先级**最高**
2. **项目级 `.claude/settings.json`** - 项目配置，优先级中等
3. **项目级 `.claude/settings.local.json`** - 项目本地配置，优先级**最低**

### 关键规则

**用户级配置会覆盖项目级配置！**

即使你在项目目录下创建了 `.claude/settings.local.json`，如果用户级 `~/.claude/settings.json` 中也配置了相同的 Hook，用户级配置会优先生效。

### 当前情况

```
~/.claude/settings.json                    → 配置了高级版 Hook（全局生效）
    ↓ 覆盖 ↓
.claude/settings.local.json                → 配置了基础版 Hook（被忽略）
```

## 解决方案

### 方案 1：修改用户级配置（推荐）

直接修改 `~/.claude/settings.json`，全局使用基础版或高级版。

#### 使用基础版

编辑 `~/.claude/settings.json`，将脚本路径改为：

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

#### 使用高级版

将路径改为：

```json
"command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:/Users/Xike/.claude/tools/terminal-notifier/scripts/hooks/stop.ps1\""
```

和

```json
"command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:/Users/Xike/.claude/tools/terminal-notifier/scripts/hooks/notification.ps1\""
```

### 方案 2：移除用户级 Hook 配置

如果不想修改用户级配置，可以移除 `~/.claude/settings.json` 中的 Hook 配置，让项目级配置生效：

1. 编辑 `~/.claude/settings.json`
2. 删除整个 `"hooks"` 部分
3. 保存并重启 Claude Code

然后项目级的 `.claude/settings.local.json` 就会生效。

## 快速切换版本脚本

创建以下脚本快速切换版本：

### `switch-to-basic.ps1`

```powershell
# 切换到基础版
$settingsPath = "$env:USERPROFILE\.claude\settings.json"
$settings = Get-Content $settingsPath | ConvertFrom-Json

# 修改 Stop Hook
$settings.hooks.Stop[0].hooks[0].command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"C:/Users/Xike/.claude/tools/terminal-notifier/scripts/hooks/stop-basic.ps1`""

# 修改 Notification Hook
$settings.hooks.Notification[0].hooks[0].command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"C:/Users/Xike/.claude/tools/terminal-notifier/scripts/hooks/notification-basic.ps1`""

# 保存
$settings | ConvertTo-Json -Depth 32 | Set-Content $settingsPath

Write-Host "✅ 已切换到基础版 Hook" -ForegroundColor Green
Write-Host "请重启 Claude Code 以应用更改" -ForegroundColor Yellow
```

### `switch-to-advanced.ps1`

```powershell
# 切换到高级版
$settingsPath = "$env:USERPROFILE\.claude\settings.json"
$settings = Get-Content $settingsPath | ConvertFrom-Json

# 修改 Stop Hook
$settings.hooks.Stop[0].hooks[0].command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"C:/Users/Xike/.claude/tools/terminal-notifier/scripts/hooks/stop.ps1`""

# 修改 Notification Hook
$settings.hooks.Notification[0].hooks[0].command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"C:/Users/Xike/.claude/tools/terminal-notifier/scripts/hooks/notification.ps1`""

# 保存
$settings | ConvertTo-Json -Depth 32 | Set-Content $settingsPath

Write-Host "✅ 已切换到高级版 Hook" -ForegroundColor Green
Write-Host "请重启 Claude Code 以应用更改" -ForegroundColor Yellow
```

## 验证配置

### 方法 1：使用 /hooks 命令

在 Claude Code 中运行：

```
/hooks
```

查看已加载的 Hook 及其路径。

### 方法 2：查看配置文件

```powershell
# 查看用户级配置
cat "$env:USERPROFILE\.claude\settings.json" | Select-String -Pattern "stop.*ps1"
```

### 方法 3：运行测试脚本

```powershell
# 测试基础版
.\test-basic-hooks.ps1

# 测试高级版
.\test-advanced-hooks.ps1
```

## 常见问题

### Q: 为什么项目级配置被忽略了？

A: 用户级 `~/.claude/settings.json` 的优先级更高，会覆盖项目级配置。

### Q: 如何让项目级配置生效？

A: 移除用户级配置中的相应 Hook 配置，或者直接修改用户级配置。

### Q: 可以同时使用基础版和高级版吗？

A: 不可以。同一个 Hook 事件（如 Stop）只能有一个配置生效。

### Q: 如何在不同项目使用不同版本？

A: 需要移除用户级配置中的 Hook 配置，然后在每个项目中创建 `.claude/settings.json`（不是 `.local`）。

### Q: 修改配置后需要重启吗？

A: 是的，Hook 配置在 Claude Code 启动时加载，修改后必须重启。

## 最佳实践

1. **推荐使用用户级配置**：在 `~/.claude/settings.json` 中全局配置，所有项目统一使用基础版或高级版。

2. **避免配置冲突**：不要同时在用户级和项目级配置相同的 Hook。

3. **使用注释标记**：在配置文件中添加 `_comment` 字段说明当前使用的版本。

4. **版本切换脚本**：创建快速切换脚本，避免手动编辑配置文件。

5. **定期验证**：使用 `/hooks` 命令验证配置是否生效。

## 相关文档

- [docs/BASIC_VS_ADVANCED.md](BASIC_VS_ADVANCED.md) - 基础版 vs 高级版功能对比
- [HOOKS_SETUP_GUIDE.md](../HOOKS_SETUP_GUIDE.md) - Hook 设置完整指南
