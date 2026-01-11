# 终端通知系统修复完成

## 修复内容总结

### 已解决的问题

1. **根本原因**：Claude Code 捕获了 hook 的标准输出 (stdout)，导致转义序列无法到达终端
2. **解决方案**：将所有 `Write-Host` 调用替换为 `[Console]::Write()`，绕过 PowerShell 流系统
3. **增强功能**：将 iTerm2 私有的 OSC 6 序列替换为 Windows Terminal 官方支持的 OSC 9;4 进度指示器

### 修改的文件

- `C:/Users/Xike/.claude/tools/terminal-notifier/lib/OscSender.psm1`
  - 所有 `Write-Host ... -NoNewline` → `[Console]::Write(...)`
  - `Send-OscTabColor` 函数完全重写，使用 OSC 9;4 序列
  - 注释更新，说明使用 `[Console]::Write` 绕过 stdout 重定向

### 预期效果

| 事件 | 窗口标题 | Tab 图标/任务栏 | 响铃 |
|------|---------|----------------|------|
| 启动会话 | `[+] Claude - Backend_CPP` | 正常进度条 | 无 |
| 恢复会话 | `[>] Claude - Backend_CPP` | 正常进度条 | 无 |
| 停止工作 | `[?] Input needed - Backend_CPP` | 红色错误指示器 | 2次（如已启用）|
| 收到通知 | `[!] Notification - Backend_CPP` | 黄色警告指示器 | 1次（如已启用）|
| 会话结束 | 恢复默认 | 无指示器 | 无 |

---

## 测试说明

### 快速测��

在 Windows Terminal 中运行以下命令：

```powershell
cd C:/Users/Xike/.claude/tools/terminal-notifier
powershell.exe -ExecutionPolicy Bypass -File test-notifications.ps1
```

测试脚本将演示：
1. OSC 2 窗口标题序列
2. OSC 9;4 进度指示器（正常/警告/错误/默认）
3. 响铃功能
4. 完整场景演示（Claude 启动→工作→停止→结束）

### 手动测试单个功能

#### 测试窗口标题

```powershell
cd C:/Users/Xike/.claude/tools/terminal-notifier/lib
Import-Module ./OscSender.psm1
Send-OscTitle "测试标题"
```

**预期**：Windows Terminal 标题栏显示 "测试标题"

#### 测试进度指示器

```powershell
cd C:/Users/Xike/.claude/tools/terminal-notifier/lib
Import-Module ./OscSender.psm1

Send-OscTabColor -Color "red"      # 红色错误指示器
Start-Sleep 2
Send-OscTabColor -Color "yellow"   # 黄色警告指示器
Start-Sleep 2
Send-OscTabColor -Color "blue"     # 正常进度条
Start-Sleep 2
Send-OscTabColor -Color "default"  # 隐藏进度条
```

**预期**：
- Tab 图标上显示彩色进度条
- 任务栏图标显示对应颜色

#### 测试响铃

```powershell
[Console]::Write("`a")
```

**预期**：听到系统响铃声（需要先启用，见下文）

---

## 启用 Windows Terminal 响铃（可选）

如果想要听到响铃声，需要在 Windows Terminal 中启用音频响铃：

### 方法 1：通过图形界面（推荐）

1. 打开 Windows Terminal
2. 点击下拉菜单（标题栏）→ **设置**
3. 在左侧选择当前使用的配置文件（如 **PowerShell**）
4. 点击 **高级**
5. 找到 **"Bell notification style"** (响铃通知样式)
6. 选择以下之一：
   - **Audible**: 仅音频响铃
   - **All**: 音频 + 视觉闪烁

### 方法 2：通过配置文件

编辑 Windows Terminal 配置文件：

**位置**：`%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`

**添加配置**：

```json
{
  "profiles": {
    "defaults": {
      "bellStyle": "audible"
    }
  }
}
```

或者为特定配置文件（如 PowerShell）：

```json
{
  "profiles": {
    "list": [
      {
        "guid": "{your-powershell-guid}",
        "name": "PowerShell",
        "bellStyle": "audible"
      }
    ]
  }
}
```

保存后重启 Windows Terminal。

---

## 验证修复

### 步骤 1：运行完整测试脚本

```powershell
cd C:/Users/Xike/.claude/tools/terminal-notifier
powershell.exe -ExecutionPolicy Bypass -File test-notifications.ps1
```

### 步骤 2：检查以下效果

- [ ] 窗口标题在测试过程中发生变化
- [ ] Tab 图标显示进度条（蓝色/黄色/红色/隐藏）
- [ ] 任务栏图标在红色和黄色状态下显示对应颜色
- [ ] （可选）听到响铃声

### 步骤 3：在 Claude Code 中验证

1. 重新启动 Claude Code 会话
2. 观察 Windows Terminal 标题栏是否显示 `[>] Claude - Backend_CPP`
3. 观察 Tab 图标是否显示进度条
4. 等待 Claude 完成响应
5. 观察标题栏是否变为 `[?] Input needed - Backend_CPP`
6. 观察 Tab 图标和任务栏是否显示红色错误指示器
7. （如已启用）是否听到 2 次响铃

---

## 故障排除

### 问题 1：窗口标题没有变化

**可能原因**：
- 终端不支持 OSC 2 序列
- 使用的不是 Windows Terminal

**解决方案**：
- 确认使用 Windows Terminal（不是 PowerShell ISE 或 ConEmu）
- 更新到最新版 Windows Terminal

### 问题 2：Tab 图标没有变化

**可能原因**：
- Windows Terminal 版本过旧（需要 v1.6 或更高）
- Tab 已通过 `--tabColor` 参数显式设置颜色（无法覆盖）

**解决方案**：
- 运行 `wt --version` 检查版本
- 更新 Windows Terminal
- 不要使用 `wt --tabColor` 参数启动

### 问题 3：听不到响铃

**可能原因**：
- Windows Terminal 响铃功能未启用
- 系统音量静音或过低
- 系统声音方案中"默认响铃"被禁用

**解决方案**：
1. 启用 Windows Terminal 响铃（见上文）
2. 检查系统音量
3. 检查 Windows 声音设置：
   - 打开 **控制面板** → **声音**
   - 切换到 **声音** 标签
   - 找到 **默认响铃** 事件
   - 确保已分配声音文件

### 问题 4：仍然没有任何效果

**回退方案**：如果 `[Console]::Write()` 仍然被捕获，则需要使用 Windows API 方案。

**验证 `[Console]::Write()` 是否有效**：

```powershell
# 直接在 PowerShell 中运行（不通过 Claude Code）
cd C:/Users/Xike/.claude/tools/terminal-notifier/lib
Import-Module ./OscSender.psm1
Send-OscTitle "测试"
```

如果直接运行有效，但通过 Claude Code hook 无效，请联系支持。

---

## ���术细节

### 为什么 `Write-Host` 不工作？

在 PowerShell 5.0+，`Write-Host` 使用 Information Stream (Stream 6)。当 Claude Code 捕获 hook 的标准输出时，所有流（包括 Information Stream）都会被重定向。

### 为什么 `[Console]::Write()` 可以绕过？

`[Console]::Write()` 是 .NET Framework 的底层方法，直接写入 Windows Console Buffer，完全绕过 PowerShell 流系统，因此无法被 stdout 重定向捕获。

### OSC 9;4 vs OSC 6

| 序列 | 支持 | 功能 | 效果 |
|------|------|------|------|
| OSC 6 | iTerm2 私有 | Tab 背景色 | 整个 Tab 背景变色 |
| OSC 9;4 | Windows Terminal 官方 | 进度指示器 | Tab 图标 + 任务栏状态 |

Windows Terminal 不支持 OSC 6，所以我们使用 OSC 9;4 作为替代。

### 参考资料

- [PowerShell 重定向与 Console.Write](https://learn.microsoft.com/en-us/powershell/scripting/samples/redirecting-data-with-out---cmdlets)
- [如何捕获 Write-Host 输出](https://latkin.org/blog/2012/04/25/how-to-capture-or-redirect-write-host-output-in-powershell/)
- [Windows Terminal 进度条序列](https://learn.microsoft.com/en-us/windows/terminal/tutorials/progress-bar-sequences)
- [Windows Console 虚拟终端序列](https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences)
- [OSC 9;4 实现 PR](https://github.com/microsoft/terminal/pull/8055)

---

## 总结

修复已完成，终端通知系统现在应该可以正常工作：

✅ **窗口标题** - 显示 Claude 当前状态  
✅ **进度指示器** - Tab 图标和任务栏显示彩色状态  
✅ **响铃功能** - 需要用户手动启用  

请运行测试脚本验证修复效果！
