# 项目清理总结

## 清理日期
2026-01-11

## 清理内容

### 1. 清理 .states/ 目录
- 删除了 143 个旧的会话状态文件（notification-state-*.json）
- 这些文件是历史会话的状态记录，不再需要

### 2. 清理 scripts/hooks/ 目录
删除了过时的 Hook 脚本：
- `stop.ps1` - 旧版 Stop Hook
- `stop-basic.ps1` - 基础版 Stop Hook
- `stop-basic-with-persistence.ps1` - 带持久化的基础版 Stop Hook
- `stop-with-persistence.ps1` - 带持久化的 Stop Hook
- `notification.ps1` - 旧版 Notification Hook
- `notification-basic.ps1` - 基础版 Notification Hook

**保留的 Hook 脚本**（当前使用）：
- `notification-with-persistence.ps1` - 带持久化的 Notification Hook
- `session-start.ps1` - 会话启动 Hook
- `session-end.ps1` - 会话结束 Hook
- `user-prompt-submit.ps1` - 用户提示提交 Hook

### 3. 整理测试脚本
将主目录的所有测试脚本移至 `tests/archived/`：
- test-*.ps1（约 15 个测试脚本）
- switch-to-advanced.ps1
- switch-to-basic.ps1

### 4. 删除 Demo/ 目录
删除了整个 Demo/ 目录及其包含的多个演示项目：
- cc-notifier/
- CCNotify/
- claude-code-hooks-scv-sounds/
- claude-code-notification/
- claude-code-notifications/
- claude-code-notifier/
- ClaudeCodeSounds/
- claude-code-task-notifier/

### 5. 整理文档文件
将过时的文档移至 `docs/archived/`：
- CUSTOM_WINDOW_NAME_UPDATE.md
- QUICK_START_WINDOW_NAME.md
- QUICKSTART.md
- README-TESTING.md

**保留的主要文档**：
- README.md - 主文档
- README-PERSISTENT-TITLE.md - 持久化标题文档
- HOOKS_SETUP_GUIDE.md - Hook 设置指南
- QUICKSTART_USERPROMPT.md - UserPrompt 快速开始

### 6. 清理 .claude/ 目录
删除了示例配置文件：
- hooks.advanced.example.json
- hooks.basic.example.json
- hooks.user-prompt-persistence.json
- settings.local.json

### 7. 清理主目录旧脚本
删除了不再使用的脚本：
- notify.ps1
- notify-with-sound.ps1
- restart-daemon.ps1
- hooks.example.json

### 8. 整理 examples/ 目录
- 将 persistent-title-quickstart.ps1 移至 docs/
- 删除了空的 examples/ 目录

## 当前项目结构

```
terminal-notifier/
├── .claude/              # Claude Code 配置（已清理）
├── .states/              # 状态文件目录（已清空）
├── docs/                 # 文档目录
│   ├── archived/         # 归档的旧文档
│   └── ...              # 当前文档
├── lib/                  # 库模块
│   ├── NotificationEnhancements.psm1
│   ├── OscSender.psm1
│   ├── PersistentTitle.psm1
│   ├── StateManager.psm1
│   ├── TabTitleManager.psm1
│   └── ToastNotifier.psm1
├── scripts/              # 脚本目录
│   ├── hooks/           # Hook 脚本（仅保留当前使用的 4 个）
│   └── ...              # 其他工具脚本
├── tests/                # 测试目录
│   ├── archived/         # 归档的旧测试脚本
│   └── ...              # 当前测试脚本
├── README.md
├── README-PERSISTENT-TITLE.md
├── HOOKS_SETUP_GUIDE.md
├── QUICKSTART_USERPROMPT.md
├── TerminalNotifier.psd1
└── TerminalNotifier.psm1
```

## 清理效果

- 删除了大量过时和不相关的文件
- 项目结构更加清晰
- 保留了所有当前使用的核心功能
- 测试脚本和旧文档已归档，需要时可以查看
- 避免了文件混乱对后续开发的干扰

## 注意事项

- 所有删除的文件都已通过 Git 管理，如需恢复可以从 Git 历史中找回
- 归档的文件（tests/archived/ 和 docs/archived/）保留供参考
- 当前使用的 Hook 配置在 `~/.claude/settings.json` 中指向 `terminal-notifier-prompt-hook` 目录
