# Toast 通知显示时间设置

**更新日期**: 2026-01-07

## 修改内容

已将 Toast 通知的显示时间调整为最长 30 秒。

## 技术实现

修改了 `lib/ToastNotifier.psm1` 中的 `Send-WindowsToast` 函数:

1. **添加 `LongDuration` 参数**: 默认为 `$true`,启用长持续时间模式
2. **设置 ExpirationTime**: 将通知在操作中心的保留时间设置为 30 秒
3. **系统显示时间**: Windows Toast 通知的实际显示时间由系统辅助功能设置控制,最长约 25-30 秒

## 使用方法

### 默认行为 (长持续时间)

```powershell
# 默认使用长持续时间 (~25-30 秒)
Send-WindowsToast -Title "任务完成" -Message "操作已成功完成"
```

### 禁用长持续时间

```powershell
# 使用短持续时间 (~5 秒)
Send-WindowsToast -Title "提示" -Message "这是一条提示信息" -LongDuration:$false
```

### 在 Hooks 中使用

```json
{
  "hook_type": "PreToolUse",
  "hook_name": "PreToolUse",
  "config": {
    "command": "Send-StopToast",
    "parameters": {
      "WindowName": "{{WindowName}}",
      "ProjectName": "{{ProjectName}}"
    }
  }
}
```

## Windows 系统设置

Toast 通知的显示时间还受 Windows 系统设置影响:

1. **Windows 10/11 辅助功能设置**:
   - 设置 → 辅助功能 → 显示 → 显示通知的时间
   - 可选: 5秒 (默认) / 修改为更长

2. **最长显示时间**: Windows Toast 通知最长显示约 25-30 秒

## 测试

运行测试脚本验证配置:

```powershell
powershell.exe -ExecutionPolicy Bypass -File C:\Users\Xike\.claude\tools\terminal-notifier\test-toast-duration.ps1
```

## 相关文件

- `lib/ToastNotifier.psm1` - Toast 通知核心模块
- `test-toast-duration.ps1` - 持续时间测试脚本

## 注意事项

1. 实际显示时间可能因 Windows 版本和系统设置而异
2. Windows 10/11 对 Toast 通知的最长显示时间有限制(约 25-30 秒)
3. `ExpirationTime` 主要控制通知在操作中心的保留时间,但也可能影响显示时间
4. 如需更精确控制,建议在 Windows 辅助功能设置中调整通知显示时间

## 故障排除

### 通知显示时间仍然很短

1. 检查 Windows 辅助功能设置中的通知显示时间
2. 确认 BurntToast 模块已正确安装
3. 查看 PowerShell 控制台是否有警告信息

### 通知未显示

1. 确认 Windows 通知权限已启用
2. 检查"专注助手"或"勿扰"模式是否开启
3. 验证 BurntToast 模块是否可用

## 来源

- [BurntToast GitHub 文档](https://github.com/Windos/BurntToast)
- [Windows Toast 通知文档](https://docs.microsoft.com/en-us/windows/apps/design/shell/tiles-and-notifications/adaptive-interactive-toasts)
