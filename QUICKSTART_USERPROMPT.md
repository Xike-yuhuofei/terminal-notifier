# UserPromptSubmit 持久化标题方案 - 快速开始

## 🚀 5 分钟快速配置

### 步骤 1：复制配置文件

```powershell
cd C:\Users\Xike\.claude\tools\terminal-notifier
Copy-Item .claude\hooks.user-prompt-persistence.json .claude\settings.local.json
```

### 步骤 2：调整路径（如果需要）

如果您的插件路径不同，编辑 `.claude/settings.local.json`，修改所有 `C:/Users/Xike/.claude/tools/terminal-notifier` 为您的实际路径。

### 步骤 3：重启 Claude Code

关闭并重新启动 Claude Code。

### 步骤 4：测试

在 Claude Code 中提交任意提示，等待完成，应该看到：
- ✅ 音效通知（1次 Bell）
- ✅ Windows Toast 通知
- ✅ 标题显示：`[⚠️ 窗口名] 需要输入 - 项目名`

提交新提示时，标题会自动恢复。

## 📚 详细文档

完整文档：[docs/USER_PROMPT_PERSISTENCE.md](docs/USER_PROMPT_PERSISTENCE.md)

## 🔧 测试脚本

```powershell
# 运行自动化测试
.\test-persistence-with-userprompt.ps1
```

## ⚙️ 配置选项

### 切换到基础版（无持久化）

```powershell
.\switch-to-basic.ps1
```

### 切换到高级版（完整功能）

```powershell
.\switch-to-advanced.ps1
```

### 手动配置 UserPromptSubmit 持久化

复制配置文件并编辑：

```powershell
Copy-Item .claude\hooks.user-prompt-persistence.json .claude\settings.local.json
notepad .claude\settings.local.json
```

## 🎯 工作原理

```
Stop 事件触发
    ↓
Stop Hook (子进程)
    ├─ 写入状态文件 ✅
    ├─ 播放音效 ✅
    └─ 发送 Toast ✅
    ↓
用户提交新提示
    ↓
UserPromptSubmit Hook (主进程) ✅
    ├─ 读取状态文件
    ├─ 检查是否过期
    └─ 重新设置标题 ✅（在主进程中生效）
```

## ⚠️ 重要提示

1. **用户手动重命名优先级最高**：如果您手动重命名了标签页，标题仍会被覆盖（这是 Windows Terminal 的设计）
2. **需要用户交互**：只有用户提交新提示时才会恢复标题
3. **自动过期清除**：Stop 标题5分钟后自动清除，Notification 标题5秒后自动清除

## 🐛 故障排查

### 标题没有显示

```powershell
# 检查状态文件
Get-Content .states\persistent-title.txt

# 检查 Hook 是否加载
# 在 Claude Code 中运行：/hooks

# 运行测试脚本
.\test-persistence-with-userprompt.ps1
```

### 手动清除标题

```powershell
Remove-Item .states\persistent-title.txt
```

## 📊 方案对比

| 功能 | 基础版 | 高级版 | UserPromptSubmit |
|------|-------|-------|-----------------|
| 音效通知 | ✅ | ✅ | ✅ |
| Toast 通知 | ✅ | ✅ | ✅ |
| 状态管理 | ❌ | ✅ | ❌ |
| OSC 标签色 | ❌ | ✅ | ❌ |
| 持久化标题 | ❌ | ⚠️ 有限 | ✅ 推荐 |
| 主进程设置 | ❌ | ❌ | ✅ |

**推荐**：
- **日常使用**：UserPromptSubmit 方案（本方案）
- **性能敏感**：基础版
- **需要状态追踪**：高级版
