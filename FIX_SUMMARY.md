# 修复总结：状态文件积累和 Stop Hook 配置错误

## 修复日期
2026-01-12

## 问题描述

### 问题 1：会话状态文件积累
- .states/ 目录积累了大量 notification-state-*.json 文件（之前有 143 个）
- 文件没有被及时清理

### 问题 2：Stop Hook 配置错误
系统尝试执行已删除的 Stop Hook 脚本：
- stop.ps1
- stop-basic.ps1

## 根本原因

### 问题 1 根因
1. **保留时间太长**：默认 24 小时保留期
2. **清理频率低**：只在 SessionStart 时清理
3. **没有会话结束清理**：SessionEnd 不清理旧文件
4. **没有定期清理**：活跃会话期间不清理

### 问题 2 根因
1. **项目级别配置覆盖**：terminal-notifier-prompt-hook/.claude/hooks.user-prompt-persistence.json 包含 Stop Hook 引用
2. **配置优先级**：项目级别配置覆盖全局配置
3. **引用已删除文件**：配置指向不存在的 stop-with-persistence.ps1

## 实施的修复

### 修复 1：优化状态文件清理

#### 1.1 减少保留时间
**文件**：`lib/StateManager.psm1:269`
```powershell
# 修改前
[int]$MaxAgeHours = 24

# 修改后
[int]$MaxAgeHours = 4
```

#### 1.2 更新 SessionStart 清理参数
**文件**：`scripts/hooks/session-start.ps1:52`
```powershell
# 修改前
Clear-OldStateFiles -MaxAgeHours 24

# 修改后
Clear-OldStateFiles -MaxAgeHours 4
```

#### 1.3 SessionEnd 添加清理
**文件**：`scripts/hooks/session-end.ps1:54`
```powershell
# 添加
# Clean up old state files from other sessions
Clear-OldStateFiles -MaxAgeHours 4
```

#### 1.4 UserPromptSubmit 添加定期清理
**文件**：`scripts/hooks/user-prompt-submit.ps1:34`
```powershell
# 添加
# Periodic cleanup (1 in 10 chance to reduce overhead)
$cleanupRandom = Get-Random -Minimum 1 -Maximum 11
if ($cleanupRandom -eq 1) {
    Import-Module (Join-Path $LibPath "StateManager.psm1") -Force -ErrorAction SilentlyContinue
    Clear-OldStateFiles -MaxAgeHours 4
}
```

### 修复 2：删除项目级别配置

删除了以下文件：
- `.claude/hooks.user-prompt-persistence.json` - 包含 Stop Hook 引用
- `.claude/hooks.advanced.example.json` - 示例配置
- `.claude/hooks.basic.example.json` - 示例配置

**原因**：
- 项目级别配置会覆盖全局配置
- 全局配置（~/.claude/settings.json）已正确配置
- 删除后系统使用全局配置，不再尝试执行已删除的 Stop Hook

## 修复效果

### 问题 1 修复后
- 状态文件保留时间从 24 小时减少到 4 小时
- 清理在三个时机触发：
  1. SessionStart（每次会话启动）
  2. SessionEnd（每次会话结束）
  3. UserPromptSubmit（定期，1/10 概率）
- 预期文件数量：4-6 个（取决于会话频率）

### 问题 2 修复后
- 不再出现 Stop Hook 错误消息
- 系统使用全局配置
- 只执行 4 个 Hook：SessionStart, Notification, SessionEnd, UserPromptSubmit

## 验证步骤

### 验证问题 1
1. 检查当前状态文件数量：
   ```bash
   ls -la "C:/Users/Xike/.claude/tools/terminal-notifier-prompt-hook/.states/"
   ```

2. 等待 4 小时后再次检查，旧文件应被清理

3. 多次启动/退出会话，文件数量应保持在 4-6 个

### 验证问题 2
1. 重启 Claude Code

2. 不应再看到 Stop Hook 错误消息

3. 检查全局配置：
   ```bash
   grep -i "stop" "C:/Users/Xike/.claude/settings.json"
   # 应该没有输出
   ```

## Git 提交

- Worktree 提交：5aa14af
- 主仓库合并：212895b

## 相关文件

### 修改的文件
1. lib/StateManager.psm1
2. scripts/hooks/session-start.ps1
3. scripts/hooks/session-end.ps1
4. scripts/hooks/user-prompt-submit.ps1

### 删除的文件
1. .claude/hooks.user-prompt-persistence.json
2. .claude/hooks.advanced.example.json
3. .claude/hooks.basic.example.json

## 注意事项

1. **重启 Claude Code**：修改生效需要重启
2. **4 小时保留期**：仍然足够调试，但会更积极地清理
3. **定期清理开销**：使用 1/10 概率采样，对性能影响最小
4. **全局配置优先**：确保没有项目级别配置覆盖
