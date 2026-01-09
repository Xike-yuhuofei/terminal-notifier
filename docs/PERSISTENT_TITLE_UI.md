# 持久化标题UI组件使用指南

## 概述

这是一个极简的UI组件，通过**持久化终端窗口标题**来显示自定义通知，解决了Windows Toast通知不持久化的问题。

## 核心特性

✅ **持久化显示** - 每0.5秒自动刷新标题，防止被覆盖
✅ **颜色编码** - 支持红、黄、绿、蓝等状态颜色
✅ **自动清理** - 可配置自动清除时间
✅ **零依赖** - 纯PowerShell实现，无需额外工具
✅ **向后兼容** - 与现有Hook系统完全兼容

## 快速开始

### 1. 测试组件

```powershell
# 在PowerShell中运行测试脚本
.\test-persistent-title.ps1
```

### 2. 在Hook中使用

Hook已经自动集成，无需额外配置！

**Stop Hook效果：**
```
[⚠️ 编译测试] 需要输入
```
- 红色标签页
- 持久化显示（不自动清除）

**Notification Hook效果：**
```
[📢 单元测试] 通知
```
- 黄色标签页
- 5秒后自动清除

## API参考

### Show-TitleNotification（推荐）

显示标题通知的简化函数。

```powershell
Show-TitleNotification -Title "标题文本" -Type "Stop" -Duration 0
```

**参数：**
- `Title` (必需) - 要显示的标题文本
- `Type` - 通知类型：
  - `Stop` - 红色，表示需要用户输入
  - `Notification` - 黄色，表示一般通知
  - `Success` - 绿色，表示任务完成
- `AutoClear` - 是否自动清除（默认true）
- `Duration` - 持续时间（秒，默认：Stop=0永久，Notification=5，Success=10）

**示例：**

```powershell
# Stop事件：永久显示
Show-TitleNotification -Title "[⚠️ 编译测试] 需要输入" -Type "Stop" -AutoClear $false

# Notification事件：5秒后自动清除
Show-TitleNotification -Title "[📢 单元测试] 通知" -Type "Notification"

# Success事件：10秒后自动清除
Show-TitleNotification -Title "[✅ 性能优化] 完成" -Type "Success"

# 自定义持续时间
Show-TitleNotification -Title "[自定义] 我的任务" -Type "Notification" -Duration 15
```

### Set-PersistentTitle（高级）

底层函数，提供更精细的控制。

```powershell
Set-PersistentTitle -Title "标题" -State "red" -Duration 30
```

**参数：**
- `Title` (必需) - 标题文本
- `State` - 颜色状态：red, blue, green, yellow, default
- `Duration` - 持续时间（秒），0表示永久

### Clear-PersistentTitle

手动清除持久化标题。

```powershell
Clear-PersistentTitle
```

### Get-PersistentTitle

获取当前持久化标题。

```powershell
$title = Get-PersistentTitle
Write-Host "当前标题: $title"
```

## 工作原理

### 1. 后台刷新机制

组件启动后台线程，每0.5秒刷新一次标题：

```powershell
while ($keepRunning -and (Get-Date) -lt $endTime) {
    $Host.UI.RawUI.WindowTitle = $PersistentTitle
    Start-Sleep -Milliseconds 500
}
```

这确保了即使有其他操作尝试修改标题，也会被立即覆盖。

### 2. OSC序列支持

在支持的终端（Windows Terminal, VS Code）中，还会设置标签页颜色：

```powershell
# OSC 9;4 序列：设置Windows Terminal标签页进度指示器颜色
$esc = [char]27
[Console]::Write("$esc]9;4;$state;100`a")
```

状态映射：
- `red` (state=2) → 红色错误指示器
- `yellow` (state=4) → 黄色警告指示器
- `blue/green` (state=1) → 蓝色/绿色正常指示器
- `default` (state=0) → 隐藏指示器

### 3. 与现有Hook的集成

Hook文件会：
1. 读取`CLAUDE_WINDOW_NAME`环境变量（如果设置）
2. 调用`Show-TitleNotification`显示持久化标题
3. 同时保留原有的`Set-NotificationVisual`调用（向后兼容）

## 使用场景

### 场景1：多任务并行开发

**配置不同的窗口名称：**

```bash
# 窗口1：编译测试
export CLAUDE_WINDOW_NAME="编译测试"
claude

# 窗口2：单元测试
export CLAUDE_WINDOW_NAME="单元测试"
claude

# 窗口3：代码审查
export CLAUDE_WINDOW_NAME="代码审查"
claude
```

**效果：**
- 窗口1触发Stop → 标题显示 `[⚠️ 编译测试] 需要输入`
- 窗口2触发Notification → 标题显示 `[📢 单元测试] 通知`
- 窗口3触发Stop → 标题显示 `[⚠️ 代码审查] 需要输入`

### 场景2：长时间运行的监控任务

```powershell
# 在Hook中设置持久化标题
Show-TitleNotification -Title "[监控] 正在运行测试套件..." -Type "Notification" -Duration 0

# 任务完成后
Show-TitleNotification -Title "[✅ 监控] 测试套件完成" -Type "Success" -Duration 10
```

### 场景3：需要用户确认的关键操作

```powershell
# 显示持久化提示，直到用户确认
Show-TitleNotification -Title "[⚠️ 确认] 是否部署到生产环境？" -Type "Stop" -AutoClear $false

# 用户确认后
Clear-PersistentTitle
```

## 故障排除

### 问题1：标题没有持久化

**原因：**后台线程可能没有启动

**解决：**
```powershell
# 检查是否有活动的持久化标题
Get-PersistentTitle

# 手动清除并重新设置
Clear-PersistentTitle
Show-TitleNotification -Title "测试" -Type "Stop"
```

### 问题2：标签页颜色没有变化

**原因：**终端不支持OSC 9;4序列

**解决：**
- 确保使用Windows Terminal或VS Code集成终端
- 检查`$env:WT_SESSION`变量是否存在
- 标题功能仍然有效，只是颜色不显示

### 问题3：Stop Hook触发后标题一直显示

**原因：**这是预期行为，Stop事件默认不自动清除

**解决：**
```powershell
# 手动清除
Clear-PersistentTitle

# 或者在继续对话后，SessionEnd Hook会自动清除
```

### 问题4：标题显示乱码

**原因：**Emoji字符在某些终端中可能不显示

**解决：**
```powershell
# 修改Hook文件，使用ASCII字符
$displayTitle = "[WARNING] 需要输入"
```

## 性能考虑

### CPU使用率

- 后台线程每0.5秒执行一次
- 每次执行只设置标题（非常轻量）
- 预期CPU影响：< 0.1%

### 内存使用

- 每个持久化标题约占用1KB内存
- 自动清理后会释放内存

## 高级用法

### 1. 在自己的脚本中使用

```powershell
Import-Module "C:\Users\Xike\.claude\tools\terminal-notifier\lib\PersistentTitle.psm1"

# 显示构建进度
Set-PersistentTitle -Title "[...] 构建中 (0%)" -State "blue"

# 更新进度
for ($i = 0; $i -le 100; $i += 10) {
    Set-PersistentTitle -Title "[...] 构建中 ($i%)" -State "blue"
    Start-Sleep -Seconds 1
}

# 构建完成
Show-TitleNotification -Title "[✅] 构建完成" -Type "Success" -Duration 5
```

### 2. 与其他通知系统组合

```powershell
# 同时显示标题通知和Toast通知
Show-TitleNotification -Title "[重要] 任务完成" -Type "Success"

# 发送Toast通知（如果需要）
if (Get-Command Send-NotificationToast -ErrorAction SilentlyContinue) {
    Send-NotificationToast -WindowName "任务完成" -ProjectName "MyProject"
}
```

### 3. 多状态管理

```powershell
# 保存当前标题
$previousTitle = Get-PersistentTitle

# 显示新的通知
Show-TitleNotification -Title "[临时] 处理中..." -Type "Notification" -Duration 3

# 等待处理完成
Start-Sleep -Seconds 3

# 恢复之前的标题
if ($previousTitle) {
    Set-PersistentTitle -Title $previousTitle -State "blue" -Duration 0
}
```

## 对比其他方案

| 方案 | 持久化 | 可见性 | 依赖 | 性能 |
|------|--------|--------|------|------|
| **持久化标题** | ✅ 永久（直到清除） | ⭐⭐⭐⭐ 需要看窗口 | 零依赖 | ⭐⭐⭐⭐⭐ 极轻量 |
| Windows Toast | ❌ 不持久 | ⭐⭐⭐⭐⭐ 非常醒目 | BurntToast模块 | ⭐⭐⭐⭐ |
| 通知中心 | ✅ 持久化 | ⭐⭐⭐ 需要点开看 | WinRT API | ⭐⭐⭐ |
| GUI窗口 | ✅ 持久化 | ⭐⭐⭐⭐⭐ 最醒目 | WPF/WinForms | ⭐⭐ 需要进程 |

**推荐组合：**
- **主要：** 持久化标题（零依赖，总是可用）
- **增强：** Toast通知（可选，用于重要事件）

## 文件位置

- 模块文件：`lib/PersistentTitle.psm1`
- Stop Hook：`scripts/hooks/stop.ps1`
- Notification Hook：`scripts/hooks/notification.ps1`
- 测试脚本：`test-persistent-title.ps1`
- 本文档：`docs/PERSISTENT_TITLE_UI.md`

## 更新日志

### v1.0.0 (2025-01-08)
- ✅ 初始版本
- ✅ 支持Stop、Notification、Success三种类型
- ✅ 后台刷新机制，防止标题被覆盖
- ✅ OSC 9;4颜色支持
- ✅ 自动清理功能
- ✅ 与现有Hook系统集成

## 下一步

**可选增强功能：**

1. **可配置刷新间隔**
   ```powershell
   # 在PersistentTitle.psm1中添加参数
   [int]$RefreshIntervalMs = 500
   ```

2. **优先级系统**
   ```powershell
   # 高优先级通知可以覆盖低优先级
   Show-TitleNotification -Title "紧急" -Type "Stop" -Priority "High"
   ```

3. **标题队列**
   ```powershell
   # 多个通知排队显示
   Show-TitleNotification -Title "通知1" -Type "Notification" -Queue
   Show-TitleNotification -Title "通知2" -Type "Notification" -Queue
   ```

4. **历史记录**
   ```powershell
   # 查看最近的标题通知历史
   Get-TitleNotificationHistory
   ```

5. **声音提醒集成**
   ```powershell
   # 显示标题的同时播放声音
   Show-TitleNotification -Title "注意" -Type "Stop" -WithSound
   ```

## 总结

持久化标题UI组件是一个**极简但强大**的解决方案：
- ✅ 解决了Toast通知不持久化的问题
- ✅ 零依赖，纯PowerShell实现
- ✅ 性能开销极小
- ✅ 与现有系统完全兼容
- ✅ 可视化效果明显（标题+颜色）

**立即开始使用：**
```powershell
.\test-persistent-title.ps1
```
