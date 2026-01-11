# UserPromptSubmit 持久化标题方案

## 概述

此方案通过 **UserPromptSubmit Hook** 在用户每次提交提示时恢复持久化标题，从而在主 Shell 进程中设置标题，真正影响 Windows Terminal 显示。

## 问题背景

### 原有问题

1. **Hook 子进程限制**：Stop/Notification Hooks 运行在子进程中，无法修改父 Windows Terminal 进程的标题
2. **标题被覆盖**：即使 Hook 设置了标题，也会被其他进程（Git Bash、Claude Code 主进程）快速覆盖
3. **用户手动重命名优先级最高**：用户手动重命名的标题会覆盖所有程序化设置的标题

### 解决方案

使用 **UserPromptSubmit Hook** 在主 Shell 进程中重新设置标题：

- **Stop Hook**：写入持久化状态文件（不直接设置标题）
- **Notification Hook**：写入持久化状态文件 + 启动5秒清除任务
- **UserPromptSubmit Hook**：读取状态文件并重新设置标题（在主进程中）

## 工作原理

### 流程图

```
用户触发 Stop 事件
    ↓
Stop Hook (子进程)
    ├─ 设置标题（可能无效）
    ├─ 写入状态文件 ✅
    ├─ 播放音效 ✅
    └─ 发送 Toast ✅
    ↓
用户提交新提示
    ↓
UserPromptSubmit Hook (主进程) ✅
    ├─ 读取状态文件
    ├─ 检查是否过期（5分钟）
    ├─ 重新设置标题 ✅（在主进程中生效）
    └─ 清除过期标题
```

### 关键文件

1. **`scripts/hooks/stop-with-persistence.ps1`**
   - Stop Hook 脚本
   - 写入状态文件：`.states/persistent-title.txt`
   - 格式：`{"title":"...","hookType":"Stop","timestamp":"..."}`

2. **`scripts/hooks/notification-with-persistence.ps1`**
   - Notification Hook 脚本
   - 写入状态文件
   - 启动后台任务，5秒后自动清除

3. **`scripts/hooks/user-prompt-submit.ps1`**
   - UserPromptSubmit Hook 脚本
   - 读取状态文件
   - 检查标题是否过期（5分钟）
   - 在主 Shell 进程中重新设置标题

## 配置方法

### 步骤 1：复制配置文件

```powershell
# 在项目目录中
Copy-Item .claude/hooks.user-prompt-persistence.json .claude/settings.local.json
```

### 步骤 2：调整路径（如果需要）

如果您的插件路径不是 `C:/Users/Xike/.claude/tools/terminal-notifier`，请修改配置文件中的路径：

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"YOUR_PATH/scripts/hooks/stop-with-persistence.ps1\"",
            "timeout": 5000
          }
        ]
      }
    ],
    "Notification": [...],
    "UserPromptSubmit": [...]
  }
}
```

### 步骤 3：重启 Claude Code

关闭并重新启动 Claude Code 以加载新的 Hook 配置。

## 测试

### 自动测试

```powershell
# 运行自动测试脚本
.\test-persistence-with-userprompt.ps1
```

测试内容：
- ✅ 持久化状态文件创建和读取
- ✅ 标题在主 Shell 进程中设置
- ✅ 过期标题自动清除（5分钟）
- ✅ Notification 标题5秒后自动清除
- ✅ 手动清除状态文件

### 手动测试

1. **触发 Stop 事件**
   - 让 Claude 完成任务并停止
   - 检查是否听到音效和看到 Toast
   - 检查状态文件是否创建：`.states/persistent-title.txt`

2. **提交新提示**
   - 输入任意问题并提交
   - 观察标题栏是否显示：`[⚠️ 窗口名] 需要输入 - 项目名`
   - 标题应该在主进程中生效，不会被其他进程覆盖

3. **测试标题过期**
   - 等待 5 分钟
   - 提交新提示
   - 标题应该被自动清除

4. **测试 Notification**
   - 触发 Notification 事件
   - 观察标题栏是否显示：`[📢 窗口名] 新通知 - 项目名`
   - 等待 5 秒，标题应该自动清除

5. **测试手动重命名覆盖**
   - 手动重命名标签页
   - 触发 Stop 事件
   - 提交新提示
   - **预期结果**：手动重命名的标题保持不变（优先级最高）

## 优势与限制

### 优势 ✅

1. **真正在主进程中设置标题**：使用 UserPromptSubmit Hook，在主 Shell 进程中运行
2. **持久化效果好**：每次用户提交提示时都会恢复标题
3. **自动过期清除**：Stop 标题5分钟后自动清除，避免永久显示
4. **Notification 自动清除**：Notification 标题5秒后自动清除
5. **向后兼容**：不影响现有的基础版和高级版 Hook

### 限制 ⚠️

1. **用户手动重命名优先级最高**：如果用户手动重命名了标签页，标题仍会被覆盖（这是 Windows Terminal 的设计）
2. **需要用户交互**：只有用户提交新提示时才会恢复标题，不是实时的
3. **额外 Hook 开销**：每次提交提示都会触发 UserPromptSubmit Hook（约 10-20ms）

### 与其他方案对比

| 方案 | 标题设置位置 | 持久化效果 | 用户重命名覆盖 | 性能开销 |
|------|------------|----------|--------------|---------|
| **基础版** | Hook 子进程 | ❌ 无 | ✅ 会被覆盖 | 低 |
| **高级版** | Hook 子进程 + 后台线程 | ⚠️ 有限 | ✅ 会被覆盖 | 中 |
| **UserPromptSubmit** | 主 Shell 进程 | ✅ 好 | ✅ 会被覆盖 | 低 |
| **手动重命名** | Windows Terminal 内部 | ✅ 永久 | ❌ 不会被覆盖 | 无 |

## 故障排查

### 问题 1：标题没有显示

**检查项**：
```powershell
# 1. 检查状态文件是否存在
Get-Content .states/persistent-title.txt

# 2. 检查 Hook 是否正确配置
# 查看 .claude/settings.local.json 中的 UserPromptSubmit Hook

# 3. 检查 Hook 是否加载
# 在 Claude Code 中运行：/hooks
```

**解决方法**：
- 确保配置文件路径正确
- 重启 Claude Code
- 运行测试脚本验证

### 问题 2：标题没有自动清除

**检查项**：
```powershell
# 检查状态文件时间戳
$titleData = Get-Content .states/persistent-title.txt | ConvertFrom-Json
[DateTime]::Parse($titleData.timestamp)

# 手动删除状态文件
Remove-Item .states/persistent-title.txt
```

**解决方法**：
- Stop 标题会在5分钟后自动清除（下次提交提示时）
- Notification 标题会在5秒后自动清除（后台任务）
- 可以手动删除状态文件立即清除

### 问题 3：手动重命名后标题不显示

**这是正常行为** ✅

- Windows Terminal 的标题优先级：手动重命名 > 程序化设置
- 这是 Windows Terminal 的设计，不是 bug
- 其他通知方式（音效、Toast）仍然有效

## 性能分析

### Hook 执行时间

- **Stop Hook**：约 50-100ms（写入状态文件）
- **Notification Hook**：约 50-100ms（写入状态文件 + 启动后台任务）
- **UserPromptSubmit Hook**：约 10-20ms（读取和检查状态文件）

### 资源占用

- **状态文件**：约 200 bytes（JSON 文本）
- **后台任务**：仅在 Notification Hook 中启动，5秒后自动结束
- **CPU 占用**：可忽略不计

## 进阶配置

### 自定义过期时间

修改 `user-prompt-submit.ps1` 中的过期时间：

```powershell
# 默认5分钟，可以修改为其他值
if ($elapsed.TotalMinutes -lt 5) {  # 改为 10 表示10分钟
    # 标题未过期，重新设置
}
```

### 自定义 Notification 清除时间

修改 `notification-with-persistence.ps1` 中的清除时间：

```powershell
# 默认5秒，可以修改为其他值
Start-Sleep -Seconds 5  # 改为 10 表示10秒
```

### 禁用自动清除

**Stop 标题**：修改过期时间为 0 或非常大的数：

```powershell
if ($elapsed.TotalMinutes -lt 9999) {  # 永不过期
    # 标题未过期，重新设置
}
```

**Notification 标题**：注释掉后台清除任务：

```powershell
# Start-Job -ScriptBlock $clearScript ...
```

## 总结

UserPromptSubmit 持久化标题方案通过在用户每次提交提示时恢复标题，实现了在主 Shell 进程中设置标题的目标，显著提高了标题显示的稳定性和持久性。

**适用场景**：
- ✅ 需要持久化标题显示
- ✅ 标题被其他进程覆盖的问题
- ✅ 希望在主进程中设置标题

**不适用场景**：
- ❌ 用户手动重命名了标签页（仍然会被覆盖）
- ❌ 需要实时更新标题（只在用户提交提示时更新）

**推荐配置**：
- 对于大多数用户：使用此方案
- 对于性能敏感场景：使用基础版（无持久化）
- 对于需要状态追踪的场景：使用高级版（完整功能）
