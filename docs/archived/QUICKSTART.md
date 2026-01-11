# 快速参考

## 一句话说明

🔴 红色 = 需要你 | 🔵 蓝色 = 自动工作

## 常见场景

| 看到的 | 含义 | 你要做什么 |
|--------|------|-----------|
| 🔴🔴🔴 [?] Ready to Stop? | Claude 想停了 | 检查结果，确认是否完成 |
| 🔴🔴🔴 [!] Bash failed | 命令失败了 | 查看错误，决定重试/跳过/中止 |
| 🔴🔴🔴 [🔔] Notification | 有通知 | 点击查看 |
| 🔵 💭 Thinking... | 正在思考 | 等待或做其他事 |
| 🔵 ⚙️ Running: Bash | 正在执行 | 等待或做其他事 |
| ✅ Done | 完成了 | 查看结果 |

## 测试命令

```powershell
# 进入插件目录
cd .claude/plugins/terminal-notifier

# 运行测试
.\scripts\test-notifier.ps1

# 手动测试单个状态
.\scripts\notify.ps1 -EventType "needs_human" -Context "[?] Test"
```

## 调试模式

```powershell
$env:CLAUDE_NOTIFY_DEBUG = "true"
```

## 清理状态文件

```powershell
Remove-Item .claude/plugins/terminal-notifier/.states/* -Force
```

## 故障排除

**问题：红色不闪烁**
- Windows Terminal 可能不支持闪烁
- 降级方案：红色背景高对比度

**问题：Tab 背景色不变**
- 确保使用 Windows Terminal
- 或 VS Code 集成终端

**问题：状态文件堆积**
- 手动删除 `.states/` 目录下的文件
- 或等待自动清理（24 小时）
